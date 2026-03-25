import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Error inicializando Firebase: $e');
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

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          _injectUserId();
        },
      ))
      ..loadRequest(Uri.parse('https://www.zoomubik.com'));
  }

  Future<void> _injectUserId() async {
    await Future.delayed(Duration(seconds: 3));

    try {
      final result = await _controller.runJavaScriptReturningResult(
        'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"'
      );
      final userId = result.toString().replaceAll('"', '');
      print('WordPress user_id: $userId');

      if (userId != '0' && userId.isNotEmpty) {
        await _saveFcmToken(userId);
      } else {
        print('Usuario no logueado o variable no disponible');
      }
    } catch (e) {
      print('Error inyectando user_id: $e');
    }
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $token');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token renovado: $newToken');
        try {
          final result = await _controller.runJavaScriptReturningResult(
            'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"'
          );
          final userId = result.toString().replaceAll('"', '');
          if (userId != '0') await _saveFcmToken(userId);
        } catch (e) {
          print('Error en onTokenRefresh: $e');
        }
      });
    } catch (e) {
      print('Error en Firebase Messaging: $e');
    }
  }

  Future<void> _saveFcmToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zmoriginal_save_fcm_token',
          'user_id': userId,
          'token': token,
        },
      );

      print('Token guardado en WordPress: ${response.statusCode}');
      print('Respuesta: ${response.body}');
    } catch (e) {
      print('Error guardando token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
