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

    debugPrint('💉 Inyectando token FCM: ${_fcmToken!.substring(0, 20)}...');

    // Esperar a que la página cargue
    await Future.delayed(const Duration(seconds: 2));

    // Obtener user_id desde el WebView
    try {
      final userId = await _controller!.evaluateJavascript(source: """
        (function() {
          if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id) {
            return zmoriginal_ajax.current_user_id;
          }
          return 0;
        })();
      """);
      
      debugPrint('📝 User ID obtenido: $userId (tipo: ${userId.runtimeType})');
      
      if (userId != null && userId != 0 && userId != '0') {
        int parsedUserId = int.parse(userId.toString());
        debugPrint('✅ User ID válido: $parsedUserId');
        await _sendTokenViaHttp(parsedUserId, _fcmToken!);
      } else {
        debugPrint('⚠️ User ID no válido: $userId, esperando...');
        _monitorUserLogin();
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo user_id: $e');
      _monitorUserLogin();
    }
  }

  Future<void> _sendTokenViaHttp(int userId, String token) async {
    try {
      debugPrint('📤 Enviando token vía HTTP REST API...');
      debugPrint('   URL: https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token');
      debugPrint('   User ID: $userId');
      debugPrint('   Token: ${token.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': token,
        }),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📬 Respuesta HTTP: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ Token enviado correctamente');
      } else {
        debugPrint('❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error enviando token: $e');
      debugPrint('   Stack trace: ${e.toString()}');
    }
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
          var messages = [];
          messages.push('🔍 Monitoreando sesión...');
          messages.push('zmoriginal_ajax: ' + (typeof zmoriginal_ajax !== 'undefined' ? 'OK' : 'NO'));
          messages.push('fcm_token: ' + (window.fcm_token ? window.fcm_token.substring(0, 20) + '...' : 'NO'));
          messages.push('fcm_token_ready: ' + window.fcm_token_ready);
          
          if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
            messages.push('✅ Usuario logueado: ' + zmoriginal_ajax.current_user_id);
            
            if (!window.fcm_user_synced || window.fcm_user_synced != zmoriginal_ajax.current_user_id) {
              window.fcm_user_synced = zmoriginal_ajax.current_user_id;
              messages.push('🔄 Usuario detectado: ' + zmoriginal_ajax.current_user_id);
              
              if (window.fcm_token_ready && window.fcm_token) {
                messages.push('📤 Enviando token a: ' + zmoriginal_ajax.ajax_url);
                jQuery.post(
                  zmoriginal_ajax.ajax_url,
                  {
                    action: 'zmoriginal_save_fcm_token',
                    user_id: zmoriginal_ajax.current_user_id,
                    token: window.fcm_token,
                    nonce: zmoriginal_ajax.nonce
                  },
                  function(response) {
                    messages.push('✅ Respuesta servidor: ' + JSON.stringify(response));
                    sendLogsToServer(messages);
                  }
                ).fail(function(error) {
                  messages.push('❌ Error en AJAX: ' + JSON.stringify(error));
                  sendLogsToServer(messages);
                });
              } else {
                messages.push('⚠️ Token no listo: fcm_token_ready=' + window.fcm_token_ready);
                sendLogsToServer(messages);
              }
            } else {
              messages.push('ℹ️ Usuario ya sincronizado: ' + window.fcm_user_synced);
              sendLogsToServer(messages);
            }
          } else {
            messages.push('⚠️ Usuario no logueado');
            sendLogsToServer(messages);
          }
          
          // Enviar logs al servidor
          function sendLogsToServer(logs) {
            fetch('https://www.zoomubik.com/log-fcm.php', {
              method: 'POST',
              headers: {'Content-Type': 'application/json'},
              body: JSON.stringify({message: logs.join(' | ')})
            }).catch(function(e) {
              console.error('Error enviando logs:', e);
            });
          }
        })();
      """);
      _monitorUserLogin(); // Continuar monitoreando
    });
  }
}
