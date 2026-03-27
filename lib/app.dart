import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(const ZoomubikApp());
}

class ZoomubikApp extends StatelessWidget {
  const ZoomubikApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoomubik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late InAppWebViewController _webViewController;
  final String _homeUrl = 'https://zoomubik.com';
  bool _isLoading = true;
  String? _errorMessage;

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
    debugPrint('🚀 App iniciada');
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
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(_homeUrl),
      );
      final isLoggedIn = cookies.any(
        (c) => c.name.startsWith('wordpress_logged_in'),
      );
      debugPrint(isLoggedIn ? '✅ Sesión activa' : '❌ Sin sesión');
    } catch (e) {
      debugPrint('⚠️ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zoomubik'), elevation: 0),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_homeUrl)),
            initialSettings: _settings,
            onWebViewCreated: (controller) {
              _webViewController = controller;
              debugPrint('✅ WebView creado');
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              debugPrint('📥 Cargando: $url');
            },
            onLoadStop: (controller, url) async {
              setState(() => _isLoading = false);
              debugPrint('✅ Cargado: $url');
              await _checkSessionAlive();
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
              debugPrint('❌ Error: ${error.description}');
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                _isLoading = false;
                _errorMessage = message;
              });
              debugPrint('❌ Error: $message');
            },
            onConsoleMessage: (controller, msg) {
              debugPrint('🖥️ ${msg.message}');
            },
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url?.toString() ?? '';
              if (url.startsWith('https://zoomubik.com') ||
                  url.startsWith('https://www.zoomubik.com') ||
                  url.startsWith('about:') ||
                  url.startsWith('blob:')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Cargando...', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null && !_isLoading)
            Container(
              color: Colors.white.withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_errorMessage!, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _errorMessage = null);
                        _webViewController.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
