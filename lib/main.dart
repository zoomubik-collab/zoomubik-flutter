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
  bool _webViewReady = false;

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

    final token = await messaging.getToken();
    if (token != null) {
      _fcmToken = token;
      debugPrint('✅ Token FCM obtenido: ${token.substring(0, 20)}...');
      await _injectTokenIntoWebView(token);
    }

    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('🔄 Token FCM renovado: ${newToken.substring(0, 20)}...');
      _injectTokenIntoWebView(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificación en primer plano: ${message.notification?.title}');
    });
  }

  Future<void> _injectTokenIntoWebView(String token) async {
    if (_controller == null || !_webViewReady) {
      debugPrint('⏳ WebView no listo aún, token se inyectará en onLoadStop');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastToken = prefs.getString('fcm_token');

    if (lastToken == token) {
      debugPrint('ℹ️ Token FCM sin cambios, no es necesario re-registrar');
      return;
    }

    debugPrint('📤 Inyectando token FCM en WebView...');

    await _controller!.evaluateJavascript(source: """
      (function() {
        var fcmToken = '$token';

        fetch('https://zoomubik.com/wp-admin/admin-ajax.php', {
          method: 'POST',
          credentials: 'include',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'action=zm_get_current_user'
        })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          console.log('FCM: zm_get_current_user = ' + JSON.stringify(data));
          var userId = data && data.success ? data.data.user_id : 0;
          if (!userId || userId == 0) {
            console.log('FCM: usuario no logado, no se registra token');
            return null;
          }
          console.log('FCM: registrando token para user_id = ' + userId);
          return fetch('https://zoomubik.com/wp-admin/admin-ajax.php', {
            method: 'POST',
            credentials: 'include',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=zmoriginal_save_fcm_token&user_id=' + userId + '&token=' + encodeURIComponent(fcmToken)
          });
        })
        .then(function(r) { return r ? r.json() : null; })
        .then(function(data) {
          if (data) console.log('FCM token registrado:', JSON.stringify(data));
        })
        .catch(function(err) {
          console.log('FCM ERROR:', err.toString());
        });
      })();
    """);

    await prefs.setString('fcm_token', token);
    debugPrint('✅ Token FCM inyectado correctamente');
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
          _webViewReady = true;
          await _saveCookies();
          if (_fcmToken != null) {
            await _injectTokenIntoWebView(_fcmToken!);
          }
        },
      ),
    );
  }
}
