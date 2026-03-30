import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebViewFCM(),
    );
  }
}

class WebViewFCM extends StatefulWidget {
  @override
  State<WebViewFCM> createState() => _WebViewFCMState();
}

class _WebViewFCMState extends State<WebViewFCM> {
  InAppWebViewController? _controller;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    print('🔔 Iniciando setup de Firebase Messaging');
    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      print('🔔 Solicitando permisos iOS...');
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    }

    final token = await messaging.getToken();
    if (token != null) {
      print('🔥 Token FCM obtenido: $token');
      _fcmToken = token;
      _injectToken();
    } else {
      print('❌ No se pudo obtener token FCM');
    }

    // Vuelve a intentar si cambia token
    messaging.onTokenRefresh.listen((newToken) {
      print('🔁 Token FCM refrescado: $newToken');
      _fcmToken = newToken;
      _injectToken();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Notificación recibida en primer plano: ${message.notification?.title}');
    });
  }

  Future<void> _injectToken() async {
    print('🚀 Inyectando token: $_fcmToken');
    if (_controller == null || _fcmToken == null) {
      print('❗ WebView no lista o token FCM nulo');
      return;
    }

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
                  console.log('✅ FCM token registrado:', response);
                  if(window && window.document) {
                    var debugDiv = document.createElement('div');
                    debugDiv.style = "position:fixed;top:0;left:0;background:#dff0d8;color:#333;padding:8px;border:2px solid #51a351;z-index:10000;font-size:16px;";
                    debugDiv.textContent = "✅ Token FCM registrado.";
                    document.body.appendChild(debugDiv);
                    setTimeout(()=>{debugDiv.remove();},3000);
                  }
                }
              );
              return;
            }
          }
          if (attempts < maxAttempts) {
            setTimeout(tryRegisterFCMToken, 1000);
          } else {
            if(window && window.document) {
              var errorDiv = document.createElement('div');
              errorDiv.style = "position:fixed;top:0;left:0;background:#ffd8d8;color:#b94a48;padding:8px;border:2px solid #d9534f;z-index:10000;font-size:16px;";
              errorDiv.textContent = "❌ Fallo al registrar el token FCM.";
              document.body.appendChild(errorDiv);
              setTimeout(()=>{errorDiv.remove();},4000);
            }
            console.log('❌ FCM: No se pudo registrar el token tras varios intentos.');
          }
        }
        tryRegisterFCMToken();
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://zoomubik.com')),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) ...',
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          if (_fcmToken != null) _injectToken();
        },
        onLoadStop: (controller, url) {
          print('🌍 onLoadStop $url');
          if (_fcmToken != null) _injectToken();
        },
      ),
    );
  }
}
