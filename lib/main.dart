import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // iOS: desactiva debug en producción
  if (!kDebugMode) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(false);
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late InAppWebViewController _webViewController;
  final String _homeUrl = 'https://www.zoomubik.com';

  // ✅ Ajustes clave para sesión persistente en iOS
  final InAppWebViewSettings _settings = InAppWebViewSettings(
    // --- Sesión persistente iOS ---
    sharedCookiesEnabled: true,          // ← comparte cookies con el sistema iOS
    incognito: false,                     // ← nunca modo incógnito
    thirdPartyCookiesEnabled: true,       // ← WordPress necesita esto

    // --- Almacenamiento web ---
    databaseEnabled: true,
    domStorageEnabled: true,
    cacheEnabled: true,
    cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,

    // --- Comportamiento general ---
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    useHybridComposition: true,           // ← mejor rendimiento en Android
    allowsInlineMediaPlayback: true,

    // ← User-agent de Safari real: WordPress/UltimateMember lo requiere
    userAgent:
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
        'Mobile/15E148 Safari/604.1',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // observa ciclo de vida
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Cuando la app vuelve al primer plano, refresca si hace falta
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionAlive();
    }
  }

  // Comprueba si la cookie de WordPress sigue activa
  Future<void> _checkSessionAlive() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri(_homeUrl),
    );
    final isLoggedIn = cookies.any(
      (c) => c.name.startsWith('wordpress_logged_in'),
    );
    debugPrint(isLoggedIn ? '✅ Sesión activa' : '⚠️ Sin sesión');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(_homeUrl),
          ),
          initialSettings: _settings,
          onWebViewCreated: (controller) {
            _webViewController = controller;
            debugPrint('🌐 WebView creado');
          },
          onLoadStart: (controller, url) {
            debugPrint('⏳ Cargando: $url');
          },
          onLoadStop: (controller, url) async {
            debugPrint('✅ Página cargada: $url');
            await _checkSessionAlive();
          },
          onReceivedError: (controller, request, error) {
            debugPrint('❌ Error: ${error.description}');
          },
          // ✅ Evita que links externos rompan la navegación interna
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString() ?? '';
            if (!url.startsWith('https://www.zoomubik.com')) {
              // Aquí podrías abrir con url_launcher si quisieras
              debugPrint('🔗 URL externa bloqueada: $url');
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }
}
