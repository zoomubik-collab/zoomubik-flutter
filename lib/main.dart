import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ZoomubikApp());
}

class ZoomubikApp extends StatelessWidget {
  const ZoomubikApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WebPage());
  }
}

class WebPage extends StatefulWidget {
  const WebPage({super.key});
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  InAppWebViewController? _controller;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _restoreCookies();
    _initPushNotifications();
  }

  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 Permisos FCM: ${settings.authorizationStatus}');

    // Escuchar token cuando llegue por refresh
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token refrescado: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      _injectToken();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificación: ${message.notification?.title}');
    });

    // Reintentar hasta 10 veces con 3 segundos entre intentos
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final token = await messaging.getToken();
      debugPrint('🔁 Intento ${i + 1}/10: token=${token != null ? "OK" : "null"}');
      if (token != null) {
        _fcmToken = token;
        debugPrint('✅ FCM token obtenido en intento ${i + 1}: ${token.substring(0, 20)}...');
        break;
      }
    }

    if (_fcmToken == null) {
      debugPrint('❌ FCM token null después de 10 intentos (30 segundos)');
    }
  }

  Future<void> _injectToken() async {
    if (_controller == null || _fcmToken == null) {
      debugPrint('⚠️ _injectToken: controller=${_controller != null}, token=${_fcmToken != null}');
      return;
    }

    debugPrint('💉 Inyectando token FCM en WebView...');

    await _controller!.evaluateJavascript(source: """
      (function() {
        window.fcm_token = '${_fcmToken}';
        window.fcm_token_ready = true;
        console.log('✅ FCM Token inyectado: ' + window.fcm_token.substring(0, 20) + '...');

        var maxAttempts = 40;
        var attempts = 0;
        var interval = setInterval(function() {
          attempts++;
          if (typeof zmoriginal_ajax !== 'undefined' && typeof jQuery !== 'undefined') {
            clearInterval(interval);
            var userId = zmoriginal_ajax.current_user_id;
            var nonce = zmoriginal_ajax.nonce;

            console.log('✅ FCM: zmoriginal_ajax encontrado, userId=' + userId);

            if (!userId || userId == 0) {
              console.log('⚠️ FCM: userId=0, no se registra el token');
              return;
            }

            jQuery.post(
              zmoriginal_ajax.ajax_url,
              {
                action: 'zmoriginal_save_fcm_token',
                user_id: userId,
                token: window.fcm_token,
                nonce: nonce
              },
              function(response) {
                console.log('✅ FCM Token registrado en servidor');
              }
            ).fail(function(error) {
              console.error('❌ Error registrando FCM Token:', error);
            });
          } else if (attempts >= maxAttempts) {
            clearInterval(interval);
            console.error('❌ FCM TIMEOUT: zmoriginal_ajax no encontrado después de 20 segundos');
          }
        }, 500);
      })();
    """);
  }

  Future<void> _restoreCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('wp_cookies');
    if (saved == null) return;

    final List cookies = jsonDecode(saved);
    for (final c in cookies) {
      await CookieManager.instance().setCookie(
        url: WebUri('https://zoomubik.com'),
        name: c['name'],
        value: c['value'],
        domain: c['domain'] ?? '.zoomubik.com',
        isHttpOnly: c['isHttpOnly'] ?? false,
        isSecure: c['isSecure'] ?? false,
      );
    }
  }

  Future<void> _saveCookies() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri('https://zoomubik.com'),
    );
    if (cookies.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final data = cookies.map((c) => {
      'name': c.name,
      'value': c.value,
      'domain': c.domain,
      'isHttpOnly': c.isHttpOnly,
      'isSecure': c.isSecure,
    }).toList();
    await prefs.setString('wp_cookies', jsonEncode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://zoomubik.com')),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            cacheEnabled: true,
            userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            _setupJavaScriptChannels(controller);
          },
          onLoadStop: (controller, url) async {
            debugPrint('🌐 Página cargada: $url');
            await _saveCookies();
            await _injectToken();
            // Monitorear cambios de sesión
            _monitorUserLogin();
          },
        ),
      ),
    );
  }

  void _setupJavaScriptChannels(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'fcmTokenReady',
      callback: (args) {
        debugPrint('✅ JavaScript confirmó: FCM Token inyectado');
      },
    );
  }

  void _monitorUserLogin() {
    // Verificar cada 2 segundos si el usuario inició sesión
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _controller?.evaluateJavascript(source: """
        (function() {
          console.log('🔍 Monitoreando sesión...');
          console.log('zmoriginal_ajax: ' + (typeof zmoriginal_ajax !== 'undefined' ? 'OK' : 'NO'));
          console.log('fcm_token: ' + (window.fcm_token ? window.fcm_token.substring(0, 20) + '...' : 'NO'));
          console.log('fcm_token_ready: ' + window.fcm_token_ready);
          
          if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
            console.log('✅ Usuario logueado: ' + zmoriginal_ajax.current_user_id);
            
            if (!window.fcm_user_synced || window.fcm_user_synced != zmoriginal_ajax.current_user_id) {
              window.fcm_user_synced = zmoriginal_ajax.current_user_id;
              console.log('🔄 Usuario detectado: ' + zmoriginal_ajax.current_user_id + ', sincronizando token...');
              
              if (window.fcm_token_ready && window.fcm_token) {
                console.log('📤 Enviando token a: ' + zmoriginal_ajax.ajax_url);
                jQuery.post(
                  zmoriginal_ajax.ajax_url,
                  {
                    action: 'zmoriginal_save_fcm_token',
                    user_id: zmoriginal_ajax.current_user_id,
                    token: window.fcm_token,
                    nonce: zmoriginal_ajax.nonce
                  },
                  function(response) {
                    console.log('✅ Respuesta servidor: ' + JSON.stringify(response));
                  }
                ).fail(function(error) {
                  console.error('❌ Error en AJAX: ' + JSON.stringify(error));
                });
              } else {
                console.warn('⚠️ Token no listo: fcm_token_ready=' + window.fcm_token_ready + ', fcm_token=' + (window.fcm_token ? 'OK' : 'NO'));
              }
            } else {
              console.log('ℹ️ Usuario ya sincronizado: ' + window.fcm_user_synced);
            }
          } else {
            console.log('⚠️ Usuario no logueado o zmoriginal_ajax no disponible');
          }
        })();
      """);
      _monitorUserLogin(); // Continuar monitoreando
    });
  }
}
