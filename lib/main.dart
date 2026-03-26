import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  late InAppWebViewController _webViewController;
  final _secureStorage = FlutterSecureStorage();
  String? _currentUserId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Cargar user_id y token guardados
    _currentUserId = await _secureStorage.read(key: 'wp_user_id');
    final sessionToken = await _secureStorage.read(key: 'zm_session_token');
    
    print('📱 User ID cargado: $_currentUserId');
    print('🔐 Token de sesión cargado: ${sessionToken != null ? 'Sí' : 'No'}');

    // Inicializar Firebase Messaging
    await _initFirebaseMessaging();

    // Si hay token guardado, restaurar sesión
    if (_currentUserId != null && sessionToken != null) {
      await _restoreSession(_currentUserId!, sessionToken);
    }

    // Marcar como inicializado
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
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
    if (message.data['type'] == 'message') {
      _webViewController.evaluateJavascript(
        source: 'window.location.hash = "#mensajes-privados";'
      );
    }
  }

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
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Sesión restaurada correctamente');
          // Recargar página para que se aplique la sesión
          await _webViewController.reload();
        } else {
          print('❌ Error restaurando sesión: ${data['data']}');
        }
      }
    } catch (e) {
      print('❌ Error en restauración de sesión: $e');
    }
  }

  Future<void> _handleUserLogin(String userId) async {
    _currentUserId = userId;
    // Guardar en almacenamiento seguro
    await _secureStorage.write(key: 'wp_user_id', value: userId);
    print('✅ User ID guardado: $userId');
    
    // Obtener token de sesión del servidor
    try {
      final response = await http.post(
        Uri.parse('https://www.zoomubik.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'zm_get_session_token',
          'user_id': userId,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final token = data['data']['token'];
          await _secureStorage.write(key: 'zm_session_token', value: token);
          print('🔐 Token de sesión guardado');
        }
      }
    } catch (e) {
      print('⚠️ Error obteniendo token de sesión: $e');
    }
    
    // Guardar token FCM con el nuevo user_id
    await _saveFcmToken(userId);
  }

  Future<void> _injectUserId() async {
    try {
      final result = await _webViewController.evaluateJavascript(
        source: 'typeof zoomubik_user_id !== "undefined" ? zoomubik_user_id.toString() : "0"'
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
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://www.zoomubik.com'),
          ),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            useHybridComposition: true,
            // Configurar cookies y almacenamiento
            databaseEnabled: true,
            domStorageEnabled: true,
            cacheEnabled: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            
            // Agregar JavaScript channel para comunicación
            _webViewController.addJavaScriptHandler(
              handlerName: 'FlutterChannel',
              callback: (args) {
                print('💬 Mensaje desde web: $args');
                if (args.isNotEmpty) {
                  final message = args[0].toString();
                  if (message.startsWith('user_id:')) {
                    final userId = message.replaceFirst('user_id:', '');
                    if (userId != '0' && userId.isNotEmpty) {
                      _handleUserLogin(userId);
                    }
                  }
                }
              },
            );
          },
          onPageFinished: (controller, url) async {
            print('✅ Página cargada: $url');
            await Future.delayed(Duration(seconds: 1));
            await _injectUserId();
          },
          onLoadStop: (controller, url) async {
            print('✅ Página completamente cargada: $url');
          },
        ),
      ),
    );
  }
}
