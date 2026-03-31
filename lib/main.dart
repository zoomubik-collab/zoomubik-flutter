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
  print('📩 Notificación en background: ${message.data}');
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

    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    print('📢 Permisos notificaciones: $settings');

    // Obtener token FCM
    _fcmToken = await messaging.getToken();
    print('💠 Token FCM obtenido: $_fcmToken');

    // Escuchar cambios de token
    messaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token FCM actualizado: $newToken');
      _fcmToken = newToken;
      _sendTokenWhenUserLogged(force: true);
    });

    // Escuchar notificaciones en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notificación en foreground: ${message.data}');
    });

    // Intentar enviar token si ya hay usuario
    _sendTokenWhenUserLogged(force: true);
  }

  Future<void> _sendTokenWhenUserLogged({bool force = false}) async {
    if (_fcmToken == null || _controller == null) {
      print('❌ Token o controller no disponibles.');
      return;
    }

    // Intentar obtener user_id de la web hasta 10 veces si es necesario
    for (int i = 0; i < 10; i++) {
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
          print('✅ Usuario detectado: $userId, enviando token...');
          await _sendTokenViaHttp(userId, _fcmToken!, force: force);
          return;
        } else {
          print('⏳ Usuario no logueado aún, intento ${i + 1}');
        }
      } catch (e) {
        print('⚠ Error obteniendo user_id: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('❌ No se pudo detectar usuario logueado.');
  }

  Future<void> _sendTokenViaHttp(int userId, String token, bool force) async {
    try {
      print('🌐 Enviando token FCM $token para user $userId');
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'token': token, 'force': force}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Token enviado correctamente.');
      } else {
        print('❌ Error enviando token, status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Excepción enviando token FCM: $e');
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
    final cookies = await CookieManager.instance().getCookies(url: WebUri('https://zoomubik.com'));
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
            userAgent:
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            _setupJavaScriptChannels(controller);
          },
          onLoadStop: (controller, url) async {
            print('🌐 Página cargada: $url');
            await _saveCookies();
            _sendTokenWhenUserLogged(force: true);
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
        print('🔔 JS notificó cambio de usuario');
        _sendTokenWhenUserLogged(force: true);
      },
    );
  }

  void _monitorUserLogin() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _controller?.evaluateJavascript(source: """
        (function() {
          if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
            if (!window.fcm_user_synced || window.fcm_user_synced != zmoriginal_ajax.current_user_id) {
              window.fcm_user_synced = zmoriginal_ajax.current_user_id;
              if (typeof fcmTokenReady !== 'undefined') {
                fcmTokenReady({user_id: zmoriginal_ajax.current_user_id});
              }
            }
          }
        })();
      """);
      _monitorUserLogin();
    });
  }
}
