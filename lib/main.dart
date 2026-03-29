import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      _fcmToken = token;
      // Intentar registrar el token ahora por si ya está logueado
      _injectToken();
    }

    // Si cambia el token (por cambio de instalación/dispositivo), vuelve a registrar
    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _injectToken();
    });

    // Puedes mostrar mensajes en primer plano con flutter_local_notifications si lo deseas
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificación recibida: ${message.notification?.title} - ${message.notification?.body}');
    });
  }

  Future<void> _injectToken() async {
    if (_controller == null || _fcmToken == null) return;

    // Intentará cada segundo hasta encontrar que el usuario está bien logueado
    await _controller!.evaluateJavascript(source: """
      (function() {
        window.fcm_token = '${_fcmToken}';
        var maxAttempts = 20;
        var attempts = 0;
        function tryRegisterFCMToken() {
          attempts++;
          if (typeof zmoriginal_ajax !== 'undefined' && typeof jQuery !== 'undefined') {
            var userId = zmoriginal_ajax.current_user_id;
            var nonce = zmoriginal_ajax.nonce;
            if (userId && userId > 0 && nonce) {
              jQuery.post(
                zmoriginal_ajax.ajax_url,
                {
                  action: 'zmoriginal_save_fcm_token',
                  user_id: userId,
                  token: window.fcm_token,
                  nonce: nonce
                },
                function(response) {
                  console.log('✅ FCM token registrado:', JSON.stringify(response));
                }
              );
              return; // Éxito, detener reintentos
            }
          }
          if (attempts < maxAttempts) {
            setTimeout(tryRegisterFCMToken, 1000); // Reintenta en 1 segundo
          } else {
            console.log('❌ FCM: No se pudo registrar el token tras varios intentos.');
          }
        }
        tryRegisterFCMToken();
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
      body: InAppWebView(
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
          await _saveCookies();
          await _injectToken();
        },
      ),
    );
  }
}
