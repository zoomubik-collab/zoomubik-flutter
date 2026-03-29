import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
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
      await _registerTokenWithWordPress(token);
    }

    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('🔄 Token FCM renovado: ${newToken.substring(0, 20)}...');
      _registerTokenWithWordPress(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificación en primer plano: ${message.notification?.title}');
    });
  }

  Future<void> _registerTokenWithWordPress(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastToken = prefs.getString('fcm_token');

      if (lastToken == token) {
        debugPrint('ℹ️ Token FCM sin cambios, no es necesario re-registrar');
        return;
      }

      final saved = prefs.getString('wp_cookies');
      if (saved == null) {
        debugPrint('⏳ Sin cookies de sesión aún, se reintentará más tarde');
        return;
      }

      final List cookieList = jsonDecode(saved);
      if (cookieList.isEmpty) {
        debugPrint('⏳ Cookies vacías, se reintentará más tarde');
        return;
      }

      final cookieHeader = cookieList
          .map((c) => '${c['name']}=${c['value']}')
          .join('; ');

      debugPrint('📤 Registrando token FCM desde Dart...');

      // Paso 1: obtener user_id actual
      final userResponse = await http.post(
        Uri.parse('https://zoomubik.com/wp-admin/admin-ajax.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': cookieHeader,
          HttpHeaders.userAgentHeader: 'ZoomubikFlutter/1.0',
        },
        body: 'action=zm_get_current_user',
      );

      debugPrint('zm_get_current_user status: ${userResponse.statusCode}');
      debugPrint('zm_get_current_user body: ${userResponse.body}');

      final userData = jsonDecode(userResponse.body);
      if (userData['success'] != true) {
        debugPrint('❌ No se pudo obtener user_id');
        return;
      }

      final userId = userData['data']['user_id'];
      if (userId == null || userId == 0) {
        debugPrint('⏳ Usuario no logado aún (user_id=0), se reintentará');
        return;
      }

      debugPrint('👤 user_id obtenido: $userId');

      // Paso 2: registrar el token FCM
      final tokenResponse = await http.post(
        Uri.parse('https://zoomubik.com/wp-admin/admin-ajax.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': cookieHeader,
          HttpHeaders.userAgentHeader: 'ZoomubikFlutter/1.0',
        },
        body: 'action=zmoriginal_save_fcm_token&user_id=$userId&token=${Uri.encodeComponent(token)}',
      );

      debugPrint('save_fcm_token status: ${tokenResponse.statusCode}');
      debugPrint('save_fcm_token body: ${tokenResponse.body}');

      final tokenData = jsonDecode(tokenResponse.body);
      if (tokenData['success'] == true) {
        await prefs.setString('fcm_token', token);
        debugPrint('✅ Token FCM registrado correctamente para user_id: $userId');
      } else {
        debugPrint('❌ Error registrando token: ${tokenResponse.body}');
      }
    } catch (e) {
      debugPrint('❌ Excepción en _registerTokenWithWordPress: $e');
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

    // Intentar registrar el token ahora que tenemos cookies
    if (_fcmToken != null) {
      await _registerTokenWithWordPress(_fcmToken!);
    }
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
        },
      ),
    );
  }
}
