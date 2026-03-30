import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      // Intentar inyectar si el WebView ya está listo
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
    // DIAGNÓSTICO FORZADO — borrar después
    await _controller?.evaluateJavascript(
      source: "alert('_injectToken ejecutado\\ntoken: ${_fcmToken != null ? 'OK' : 'NULL'}');",
    );

    if (_controller == null || _fcmToken == null) {
      debugPrint('⚠️ _injectToken: controller=${_controller != null}, token=${_fcmToken != null}');
      return;
    }

    debugPrint('💉 Inyectando token FCM en WebView...');

    await _controller!.evaluateJavascript(source: """
      (function() {
        window.fcm_token = '${_fcmToken}';

        var hasAjax = typeof zmoriginal_ajax !== 'undefined';
        var hasJQuery = typeof jQuery !== 'undefined';
        alert('FCM diagnostico:\\nzmoriginal_ajax: ' + hasAjax + '\\njQuery: ' + hasJQuery + '\\nURL: ' + window.location.href);

        var maxAttempts = 20;
        var attempts = 0;
        var interval = setInterval(function() {
          attempts++;
          if (typeof zmoriginal_ajax !== 'undefined' && typeof jQuery !== 'undefined') {
            clearInterval(interval);
            var userId = zmoriginal_ajax.current_user_id;
            var nonce = zmoriginal_ajax.nonce;

            alert('FCM: zmoriginal_ajax encontrado\\nuserId: ' + userId + '\\nnonce: ' + (nonce ? nonce.substring(0,8) + '...' : 'null'));

            if (!userId || userId == 0) {
              alert('FCM: userId=0, no se registra el token');
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
                alert('FCM respuesta servidor: ' + JSON.stringify(response));
              }
            );
          } else if (attempts >= maxAttempts) {
            clearInterval(interval);
            alert('FCM TIMEOUT\\njQuery: ' + (typeof jQuery !== 'undefined') + '\\nzmoriginal_ajax: ' + (typeof zmoriginal_ajax !== 'undefined'));
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
          },
          onLoadStop: (controller, url) async {
            debugPrint('🌐 Página cargada: $url');
            await _saveCookies();
            await _injectToken();
          },
        ),
      ),
    );
  }
}
