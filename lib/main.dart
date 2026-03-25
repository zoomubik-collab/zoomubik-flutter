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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Cargar credenciales guardadas
    final savedEmail = await _secureStorage.read(key: 'wp_email');
    final savedPassword = await _secureStorage.read(key: 'wp_password');
    
    print('📱 Email guardado: ${savedEmail != null ? 'Sí' : 'No'}');
    print('📱 Password guardado: ${savedPassword != null ? 'Sí' : 'No'}');

    // Inicializar WebView primero
    _initWebView();

    // Inicializar Firebase Messaging
    await _initFirebaseMessaging();

    // Si hay credenciales guardadas, hacer login automático
    if (savedEmail != null && savedPassword != null) {
      await Future.delayed(Duration(seconds: 2));
      await _autoLogin(savedEmail, savedPassword);
    }

    // Marcar como inicializado
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _autoLogin(String email, String password) async {
    try {
      print('🔄 Intentando login automático...');
      
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zm_flutter_login',
          'email': email,
          'password': password,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final userId = data['data']['user_id'].toString();
          
          print('✅ Login automático exitoso: $userId');
          
          // Guardar user_id
          _currentUserId = userId;
          await _secureStorage.write(key: 'wp_user_id', value: userId);
          
          // Recargar página
          await _controller.reload();
          
          // Obtener token FCM
          await _saveFcmToken(userId);
        } else {
          print('❌ Login falló: ${data['data']}');
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en login automático: $e');
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15')
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print('💬 Mensaje desde web: ${message.message}');
          if (message.message.startsWith('user_id:')) {
            final userId = message.message.replaceFirst('user_id:', '');
            if (userId != '0' && userId.isNotEmpty) {
              _handleUserLogin(userId);
            }
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          print('✅ Página cargada: $url');
          await Future.delayed(Duration(seconds: 1));
          _injectUserId();
        },
      ))
      ..loadRequest(Uri.parse('https://www.zoomubik.com'));
  }

  Future<void> _handleUserLogin(String userId) async {
    _currentUserId = userId;
    // Guardar en almacenamiento seguro
    await _secureStorage.write(key: 'wp_user_id', value: userId);
    print('✅ User ID guardado: $userId');
    
    // Intentar obtener email y password del formulario de login
    try {
      final email = await _controller.runJavaScriptReturningResult(
        'document.querySelector("input[type=email]")?.value || document.querySelector("input[name=user_login]")?.value || ""'
      );
      final password = await _controller.runJavaScriptReturningResult(
        'document.querySelector("input[type=password]")?.value || ""'
      );
      
      if (email != null && email.toString().isNotEmpty && password != null && password.toString().isNotEmpty) {
        await _secureStorage.write(key: 'wp_email', value: email.toString());
        await _secureStorage.write(key: 'wp_password', value: password.toString());
        print('✅ Credenciales guardadas');
      }
    } catch (e) {
      print('⚠️ No se pudieron guardar credenciales: $e');
    }
    
    // Guardar token FCM con el nuevo user_id
    await _saveFcmToken(userId);
  }

  Future<void> _injectUserId() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"'
      );
      final userId = result.toString().replaceAll('"', '');
      print('🔍 User ID desde JS: $userId');

      if (userId != '0' && userId.isNotEmpty) {
        await _handleUserLogin(userId);
      }
    } catch (e) {
      print('⚠️ Error obteniendo user_id: $e');
    }
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      // Solicitar permisos
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Obtener token inicial
      String? token = await FirebaseMessaging.instance.getToken();
      print('🔑 FCM Token: $token');
      if (token != null && _currentUserId != null) {
        await _saveFcmToken(_currentUserId!);
      }

      // Escuchar renovación de token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token renovado: $newToken');
        if (_currentUserId != null) {
          await _saveFcmToken(_currentUserId!);
        }
      });

      // Notificaciones cuando la app está en foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Notificación en foreground: ${message.notification?.title}');
        _showNotificationDialog(message);
      });

      // Cuando el usuario toca la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('👆 Notificación tocada: ${message.notification?.title}');
        _handleNotificationTap(message);
      });
    } catch (e) {
      print('❌ Error en Firebase Messaging: $e');
    }
  }

  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notificación'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNotificationTap(message);
            },
            child: Text('Ver'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('🎯 Manejando notificación: ${message.data}');
    // Aquí puedes navegar a la sección de mensajes si es necesario
    if (message.data['type'] == 'message') {
      _controller.runJavaScript(
        'window.location.hash = "#mensajes-privados";'
      );
    }
  }

  Future<void> _saveFcmToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('⚠️ Token es null');
        return;
      }

      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zmoriginal_save_fcm_token',
          'user_id': userId,
          'token': token,
        },
      ).timeout(Duration(seconds: 10));

      print('✅ Token guardado en WordPress: ${response.statusCode}');
      print('📝 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // Guardar token localmente como backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token_$userId', token);
      }
    } catch (e) {
      print('❌ Error guardando token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando Zoomubik...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
