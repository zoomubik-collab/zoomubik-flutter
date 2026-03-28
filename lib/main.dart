import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
      await _registerTokenInWordPress(token);
    }
 
    messaging.onTokenRefresh.listen(_registerTokenInWordPress);
 
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificación recibida en primer plano: ${message.notification?.title}');
    });
  }
 
  Future<void> _registerTokenInWordPress(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final lastToken = prefs.getString('fcm_token');
    if (lastToken == token) return;
 
    // Obtener el user_id de las cookies guardadas
    final saved = prefs.getString('wp_cookies');
    if (saved == null) return;
 
    try {
      final response = await http.post(
        Uri.parse('https://zoomubik.com/wp-json/zoomubik/v1/push/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        await prefs.setString('fcm_token', token);
        debugPrint('✅ Token FCM registrado correctamente');
      }
    } catch (e) {
      debugPrint('❌ Error registrando token FCM: $e');
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
        },
      ),
    );
  }
}
