import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error Firebase');
  }
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
  final String _homeUrl = 'https://zoomubik.com';

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    sharedCookiesEnabled: true,
    thirdPartyCookiesEnabled: true,
    incognito: false,
    cacheEnabled: true,
    cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
    useShouldOverrideUrlLoading: true,
    useOnLoadResource: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionAlive();
    }
  }

  Future<void> _checkSessionAlive() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri(_homeUrl),
    );
    final isLoggedIn = cookies.any(
      (c) => c.name.startsWith('wordpress_logged_in'),
    );
    debugPrint(isLoggedIn ? 'Sesion activa' : 'Sin sesion');
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
          },
          onLoadStart: (controller, url) {
            debugPrint('Cargando: $url');
          },
          onLoadStop: (controller, url) async {
            debugPrint('Cargado: $url');
            await _checkSessionAlive();
          },
          onReceivedError: (controller, request, error) {
            debugPrint('Error webview: ${error.description} - URL: ${request.url}');
          },
          onLoadError: (controller, url, code, message) {
            debugPrint('onLoadError: $message - código: $code - URL: $url');
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('CONSOLA: ${consoleMessage.message}');
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString() ?? '';
            if (url.startsWith('https://zoomubik.com') ||
                url.startsWith('https://www.zoomubik.com') ||
                url.startsWith('about:') ||
                url.startsWith('blob:')) {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
        ),
      ),
    );
  }
}
