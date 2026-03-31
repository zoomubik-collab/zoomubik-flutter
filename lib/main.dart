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

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Obtener tokens
    final apns = await messaging.getAPNSToken();
    final fcm = await messaging.getToken();
    
    if (apns != null) {
      _fcmToken = fcm;
    }

    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _sendTokenWhenUserLogged();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Notificación en foreground
    });
  }

  Future<void> _sendTokenWhenUserLogged() async {
    if (_fcmToken == null || _controller == null) return;
    
    // Intentar obtener el user_id, máximo 5 intentos
    for (int i = 0; i < 5; i++) {
      try {
        final result = await _controller!.evaluateJavascript(source: """
          (function() {
            if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
              return zmoriginal_ajax.current_user_id.toString();
            }
            return '0';
          })();
        """);
        
        final userId = int.tryParse(result?.toString() ?? '0') ?? 0;
        if (userId > 0) {
          await _sendTokenViaHttp(userId, _fcmToken!);
          return;
        }
      } catch (e) {
        // Continuar intentando
      }
      
      // Esperar 500ms antes de reintentar
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _sendTokenViaHttp(int userId, String token) async {
    try {
      await http.post(
        Uri.parse('https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'token': token}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Error silencioso
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
            await _sendTokenWhenUserLogged();
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
        // Cuando el usuario cambia, enviar el token (sin await)
        _sendTokenWhenUserLogged();
      },
    );
  }

  void _monitorUserLogin() {
    // Verificar cada 2 segundos si el usuario inició sesión
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _controller?.evaluateJavascript(source: """
        (function() {
          if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
            if (!window.fcm_user_synced || window.fcm_user_synced != zmoriginal_ajax.current_user_id) {
              window.fcm_user_synced = zmoriginal_ajax.current_user_id;
              // Notificar a Flutter que el usuario cambió
              if (typeof fcmTokenReady !== 'undefined') {
                fcmTokenReady({user_id: zmoriginal_ajax.current_user_id});
              }
            }
          }
        })();
      """);
      _monitorUserLogin(); // Continuar monitoreando
    });
  }
}
