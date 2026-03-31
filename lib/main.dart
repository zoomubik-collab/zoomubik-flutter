import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Manejo de mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Mensaje en background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FCMHomePage(),
    );
  }
}

class FCMHomePage extends StatefulWidget {
  const FCMHomePage({super.key});

  @override
  State<FCMHomePage> createState() => _FCMHomePageState();
}

class _FCMHomePageState extends State<FCMHomePage> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Pedir permisos (iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permisos: ${settings.authorizationStatus}');

    // Obtener token FCM
    String? token = await messaging.getToken();
    setState(() => _fcmToken = token);
    print('FCM Token: $token');

    // Obtener token APNs (solo iOS)
    String? apnsToken = await messaging.getAPNSToken();
    print('APNs Token (iOS): $apnsToken');

    // Escuchar refresh de token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      setState(() => _fcmToken = newToken);
      print('Nuevo FCM Token: $newToken');
    });

    // Escuchar mensajes foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje foreground: ${message.notification?.title} - ${message.notification?.body}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FCM Test')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Token FCM obtenido:'),
              const SizedBox(height: 10),
              SelectableText(_fcmToken ?? 'Esperando token...'),
            ],
          ),
        ),
      ),
    );
  }
}
