import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Notificación en background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }

  runApp(ZoomubikApp());
}

class ZoomubikApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoomubik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;
  final _secureStorage = FlutterSecureStorage();

  String? _currentUserId;
  bool _isInitialized = false;
  bool _loginProcesado = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // 🔹 INIT GENERAL
  Future<void> _initializeApp() async {
    _currentUserId = await _secureStorage.read(key: 'wp_user_id');
    final sessionToken = await _secureStorage.read(key: 'zm_session_token');

    print('📱 User ID: $_currentUserId');
    print('🔐 Token: ${sessionToken != null ? 'Sí' : 'No'}');

    await _initFirebaseMessaging();
    _initWebView();

    // 🔥 Restaurar sesión si existe
    if (_currentUserId != null && sessionToken != null) {
      await Future.delayed(const Duration(seconds: 2));
      await _restoreSession(_currentUserId!, sessionToken);
    }

    setState(() => _isInitialized = true);
  }

  // 🔹 RESTORE SESSION
  Future<void> _restoreSession(String userId, String token) async {
    try {
      print('🔄 Restaurando sesión...');

      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zm_restore_session',
          'user_id': userId,
          'token': token,
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        print('✅ Sesión restaurada');

        _controller.loadRequest(
          Uri.parse('https://www.zoomubik.com'),
        );
      } else {
        print('❌ Token inválido');
      }
    } catch (e) {
      print('❌ Error restaurando sesión: $e');
    }
  }

  // 🔹 WEBVIEW
  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('💬 ${message.message}');

          if (message.message.startsWith('user_id:')) {
            final userId = message.message.replaceFirst('user_id:', '');

            if (userId != '0' && userId.isNotEmpty) {
              _handleUserLogin(userId);
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            print('🌐 $url');

            await Future.delayed(const Duration(seconds: 1));
            _injectUserId();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.zoomubik.com'));
  }

  // 🔹 LOGIN DETECTADO
  Future<void> _handleUserLogin(String userId) async {
    if (_loginProcesado) return;
    _loginProcesado = true;

    _currentUserId = userId;

    await _secureStorage.write(key: 'wp_user_id', value: userId);
    print('✅ Usuario guardado: $userId');

    // 🔐 Obtener token sesión
    try {
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zm_get_session_token',
          'user_id': userId,
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await _secureStorage.write(
          key: 'zm_session_token',
          value: data['data']['token'],
        );

        print('🔐 Token guardado');
      }
    } catch (e) {
      print('⚠️ Error token: $e');
    }

    await _saveFcmToken(userId);
  }

  // 🔹 OBTENER USER ID DESDE WEB
  Future<void> _injectUserId() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"',
      );

      final userId = result.toString().replaceAll('"', '');

      if (userId != '0' && userId.isNotEmpty) {
        await _handleUserLogin(userId);
      }
    } catch (e) {
      print('⚠️ Error user_id: $e');
    }
  }

  // 🔹 FIREBASE
  Future<void> _initFirebaseMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission();

      String? token = await FirebaseMessaging.instance.getToken();
      print('🔑 FCM: $token');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (_currentUserId != null) {
          await _saveFcmToken(_currentUserId!);
        }
      });

      FirebaseMessaging.onMessage.listen((message) {
        print('📬 ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _controller.runJavaScript(
          'window.location.hash = "#mensajes-privados";',
        );
      });
    } catch (e) {
      print('❌ Firebase error: $e');
    }
  }

  // 🔹 GUARDAR FCM EN WORDPRESS
  Future<void> _saveFcmToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zm_save_fcm',
          'fcm': token,
        },
      );

      print('✅ FCM guardado');
    } catch (e) {
      print('❌ Error FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
