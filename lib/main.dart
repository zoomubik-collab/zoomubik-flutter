import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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
  final _secureStorage = FlutterSecureStorage();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('Mensaje desde web: ${message.message}');
          if (message.message.startsWith('user_id:')) {
            final userId = message.message.replaceFirst('user_id:', '');
            if (userId != '0' && userId.isNotEmpty) {
              _saveFcmToken(userId);
            }
          }
          if (message.message.startsWith('credentials:')) {
            final data = message.message.replaceFirst('credentials:', '');
            final parts = data.split('|');
            if (parts.length == 2) {
              _saveCredentials(parts[0], parts[1]);
            }
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          print('Página cargada: $url');
          await _checkLoginStatus();
          _injectUserId();
          // Inyectar script para capturar credenciales del formulario de login
          await _injectLoginCapture();
        },
      ))
      ..loadRequest(Uri.parse('https://www.zoomubik.com'));
  }

  Future<void> _injectLoginCapture() async {
    try {
      await _controller.runJavaScript('''
        // Capturar submit del formulario de login de WordPress
        var loginForm = document.querySelector("#loginform, form.login, form[name='loginform']");
        if (loginForm && !loginForm.dataset.captured) {
          loginForm.dataset.captured = "true";
          loginForm.addEventListener("submit", function(e) {
            var username = document.querySelector("#user_login, input[name='log']");
            var password = document.querySelector("#user_pass, input[name='pwd']");
            if (username && password && typeof FlutterChannel !== "undefined") {
              FlutterChannel.postMessage("credentials:" + username.value + "|" + password.value);
            }
          });
        }
      ''');
    } catch (e) {
      print('Error inyectando captura de login: $e');
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    await _secureStorage.write(key: 'wp_username', value: username);
    await _secureStorage.write(key: 'wp_password', value: password);
    print('Credenciales guardadas para: $username');
  }

  Future<void> _checkLoginStatus() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"'
      );
      final userId = result.toString().replaceAll('"', '');

      if (userId == '0' || userId.isEmpty) {
        // No está logueado — intentar autologin
        await _tryAutoLogin();
      } else {
        _isLoggedIn = true;
        print('Usuario logueado: $userId');
      }
    } catch (e) {
      print('Error comprobando login: $e');
    }
  }

  Future<void> _tryAutoLogin() async {
    try {
      final username = await _secureStorage.read(key: 'wp_username');
      final password = await _secureStorage.read(key: 'wp_password');

      if (username == null || password == null) {
        print('No hay credenciales guardadas');
        return;
      }

      print('Intentando autologin para: $username');

      // Hacer login via WordPress REST API
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-json/jwt-auth/v1/token'),
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        print('Autologin exitoso');
        // Recargar la página actual
        _controller.reload();
      } else {
        // JWT no disponible, intentar login directo via formulario
        await _tryFormLogin(username, password);
      }
    } catch (e) {
      print('Error en autologin: $e');
      // Intentar login via formulario como fallback
      final username = await _secureStorage.read(key: 'wp_username');
      final password = await _secureStorage.read(key: 'wp_password');
      if (username != null && password != null) {
        await _tryFormLogin(username, password);
      }
    }
  }

  Future<void> _tryFormLogin(String username, String password) async {
    try {
      print('Intentando login via formulario');
      // Navegar a la página de login y rellenar el formulario
      await _controller.loadRequest(
        Uri.parse('https://www.zoomubik.com/wp-login.php')
      );

      await Future.delayed(Duration(seconds: 2));

      await _controller.runJavaScript('''
        var userField = document.querySelector("#user_login");
        var passField = document.querySelector("#user_pass");
        var submitBtn = document.querySelector("#wp-submit");
        if (userField && passField && submitBtn) {
          userField.value = "${username.replaceAll('"', '\\"')}";
          passField.value = "${password.replaceAll('"', '\\"')}";
          submitBtn.click();
        }
      ''');
    } catch (e) {
      print('Error en login via formulario: $e');
    }
  }

  Future<void> _injectUserId() async {
    await Future.delayed(Duration(seconds: 2));
    try {
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {'action': 'zm_get_user_id'},
      );
      print('Respuesta user_id: ${response.body}');
      final decoded = json.decode(response.body);
      final userId = decoded['data']['user_id'].toString();
      print('User ID obtenido: $userId');
      if (userId != '0' && userId.isNotEmpty) {
        await _saveFcmToken(userId);
      } else {
        final result = await _controller.runJavaScriptReturningResult(
          'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"'
        );
        final jsUserId = result.toString().replaceAll('"', '');
        print('User ID desde JS: $jsUserId');
        if (jsUserId != '0' && jsUserId.isNotEmpty) {
          await _saveFcmToken(jsUserId);
        }
      }
    } catch (e) {
      print('Error obteniendo user_id: $e');
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
          final response = await http.post(
            Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
            body: {'action': 'zm_get_user_id'},
          );
          final decoded = json.decode(response.body);
          final userId = decoded['data']['user_id'].toString();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wp_user_id', userId);

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
