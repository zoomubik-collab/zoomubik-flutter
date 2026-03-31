import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

// ─── Background handler (debe ser top-level) ────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.messageId}');
}

// ─── Entry point ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ZoomubikApp());
}

// ─── App ─────────────────────────────────────────────────────────────────────
class ZoomubikApp extends StatelessWidget {
  const ZoomubikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WebPage());
  }
}

// ─── WebPage ─────────────────────────────────────────────────────────────────
class WebPage extends StatefulWidget {
  const WebPage({super.key});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  InAppWebViewController? _controller;

  // Token en memoria + persistido en SharedPreferences
  String? _fcmToken;

  // Evita envíos duplicados por sesión
  int _lastSyncedUserId = 0;

  // Controla el loop de monitoreo
  bool _monitorActive = false;

  @override
  void initState() {
    super.initState();
    _restoreCookies();
    _initPushNotifications();
  }

  @override
  void dispose() {
    _monitorActive = false;
    super.dispose();
  }

  // ─── FCM Init ───────────────────────────────────────────────────────────────
  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Pedir permisos (iOS necesita esto antes de getToken)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 2. En iOS, obtener APNs token primero (Firebase lo necesita internamente)
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final apns = await messaging.getAPNSToken();
      debugPrint('[FCM] APNs token: $apns');
    }

    // 3. Cargar token guardado previamente (evita null en el primer onLoadStop)
    final prefs = await SharedPreferences.getInstance();
    _fcmToken = prefs.getString('fcm_token');
    debugPrint('[FCM] Token cargado de prefs: $_fcmToken');

    // 4. Obtener token fresco de FCM
    try {
      final token = await messaging.getToken();
      if (token != null && token != _fcmToken) {
        _fcmToken = token;
        await prefs.setString('fcm_token', token);
        debugPrint('[FCM] Token nuevo: $token');
      }
    } catch (e) {
      debugPrint('[FCM] Error getToken: $e');
    }

    // 5. Escuchar renovaciones de token
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token renovado: $newToken');
      _fcmToken = newToken;
      final p = await SharedPreferences.getInstance();
      await p.setString('fcm_token', newToken);
      _lastSyncedUserId = 0; // Fuerza reenvío con el nuevo token
      _trySendToken();
    });

    // 6. Notificaciones en foreground (mostrar snackbar o manejar navegación)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      // Recarga la página para mostrar el badge/mensaje nuevo
      _controller?.reload();
    });

    // 7. App abierta desde notificación (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App abierta desde notificación');
      _controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://zoomubik.com/mensajes')),
      );
    });

    // 8. Notificación que abrió la app desde terminated
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] App lanzada desde notificación terminada');
    }
  }

  // ─── Envío del token ────────────────────────────────────────────────────────

  /// Intenta obtener el user_id del JS y enviar el token.
  /// Se llama desde onLoadStop y desde el monitor.
  Future<void> _trySendToken() async {
    if (_fcmToken == null || _controller == null) return;

    // Reintentar hasta 6 veces (3 segundos en total) esperando que zmoriginal_ajax esté listo
    for (int i = 0; i < 6; i++) {
      if (!mounted) return;

      try {
        final result = await _controller!.evaluateJavascript(source: """
          (function() {
            if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
              return zmoriginal_ajax.current_user_id.toString();
            }
            return '0';
          })();
        """);

        final userId = int.tryParse(result?.toString().replaceAll('"', '') ?? '0') ?? 0;

        if (userId > 0 && userId != _lastSyncedUserId) {
          debugPrint('[FCM] Usuario detectado: $userId — enviando token...');
          final ok = await _sendTokenToWordPress(userId, _fcmToken!);
          if (ok) {
            _lastSyncedUserId = userId;
            debugPrint('[FCM] Token registrado para user $userId ✓');
          }
          return;
        }
      } catch (e) {
        debugPrint('[FCM] JS eval error (intento $i): $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('[FCM] Usuario no logueado o zmoriginal_ajax no disponible aún');
  }

  Future<bool> _sendTokenToWordPress(int userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'token': token}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('[FCM] HTTP response: ${response.statusCode} — ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[FCM] Error HTTP: $e');
      return false;
    }
  }

  // ─── Monitor de login ───────────────────────────────────────────────────────
  /// Revisa periódicamente si el usuario hace login después de cargar la página.
  /// Se detiene solo cuando detecta un usuario válido o cuando el widget se destruye.
  void _startLoginMonitor() {
    if (_monitorActive) return; // Ya está corriendo
    _monitorActive = true;
    _monitorLoop();
  }

  Future<void> _monitorLoop() async {
    while (_monitorActive && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_monitorActive) return;

      if (_fcmToken == null || _controller == null) continue;

      try {
        final result = await _controller!.evaluateJavascript(source: """
          (function() {
            if (typeof zmoriginal_ajax !== 'undefined' && zmoriginal_ajax.current_user_id > 0) {
              return zmoriginal_ajax.current_user_id.toString();
            }
            return '0';
          })();
        """);

        final userId = int.tryParse(result?.toString().replaceAll('"', '') ?? '0') ?? 0;

        if (userId > 0 && userId != _lastSyncedUserId) {
          debugPrint('[FCM] Monitor detectó login: user $userId');
          final ok = await _sendTokenToWordPress(userId, _fcmToken!);
          if (ok) {
            _lastSyncedUserId = userId;
            _monitorActive = false; // Token enviado, paramos el monitor
            debugPrint('[FCM] Monitor detenido — token registrado ✓');
          }
        }
      } catch (_) {}
    }
  }

  // ─── Cookies ────────────────────────────────────────────────────────────────
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

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://zoomubik.com')),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            cacheEnabled: true,
            userAgent:
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                'AppleWebKit/605.1.15 (KHTML, like Gecko) '
                'Version/17.0 Mobile/15E148 Safari/604.1',
          ),
          onWebViewCreated: (controller) {
            _controller = controller;

            // Handler para que la web pueda forzar un reenvío del token
            controller.addJavaScriptHandler(
              handlerName: 'requestFcmToken',
              callback: (_) {
                debugPrint('[FCM] Web solicitó token via JS handler');
                _lastSyncedUserId = 0; // Fuerza reenvío
                _trySendToken();
              },
            );
          },
          onLoadStop: (controller, url) async {
            debugPrint('[FCM] onLoadStop: $url');
            await _saveCookies();
            await _trySendToken();   // Intento inmediato
            _startLoginMonitor();    // Arranca monitor por si hace login después
          },
        ),
      ),
    );
  }
}
