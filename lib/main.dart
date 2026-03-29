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
    print('🔥 FCM recibido: $token'); // <-- +++ DEBUG PRINCIPAL
    if (token != null) {
      _fcmToken = token;
      _injectToken();
    }

    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('🔄 FCM refrescado: $newToken'); // <-- +++ DEBUG REFRESH
      _injectToken();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notificación recibida: ${message.notification?.title} - ${message.notification?.body}');
    });
  }

  Future<void> _injectToken() async {
    if (_controller == null || _fcmToken == null) {
      print("❌ _injectToken: WebView o FCM token aún no disponibles");
      return;
    }
    print("🚀 injectToken lanzado con $_fcmToken"); // <-- +++ DEBUG FUNDAMENTAL

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
                  // También puedes notificar en la interfaz temporalmente
                  if(window && window.document) {
                    var debugDiv = document.createElement('div');
                    debugDiv.style = "position:fixed;top:10px;left:10px;background:#dff0d8;color:#333;padding:6px;border:1px solid #51a351;z-index:10000;font-size:16px;";
                    debugDiv.textContent = "✅ Token FCM registrado.";
                    document.body.appendChild(debugDiv);
                    setTimeout(()=>{debugDiv.remove();}, 4000);
                  }
                }
              );
              return; // Éxito, detener reintentos
            }
          }
          if (attempts < maxAttempts) {
            setTimeout(tryRegisterFCMToken, 1000); // Reintenta en 1 segundo
          } else {
            // Notifica error en la web visualmente
            if(window && window.document) {
              var errorDiv = document.createElement('div');
              errorDiv.style = "position:fixed;top:10px;left:10px;background:#ffe0e0;color:#b94a48;padding:6px;border:1px solid #df5c5c;z-index:10000;font-size:16px;";
              errorDiv.textContent = "❌ Falló el registro del token FCM.";
              document.body.appendChild(errorDiv);
              setTimeout(()=>{errorDiv.remove();}, 6000);
            }
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
          print("➡️ onLoadStop en $url");
          await _saveCookies();
          await _injectToken();
        },
      ),
    );
  }
}
