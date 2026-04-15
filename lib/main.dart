import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:shared_preferences/shared_preferences.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "firebase_options.dart";

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ZoomubikApp());
}

class ZoomubikApp extends StatelessWidget {
  const ZoomubikApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WebPage());
  }
}

// ==================== DATOS DE CATEGORÍAS Y PROVINCIAS ====================

const Map<String, String> kProvincias = {
  'almeria': 'Almería',
  'cadiz': 'Cádiz',
  'cordoba': 'Córdoba',
  'granada': 'Granada',
  'huelva': 'Huelva',
  'jaen': 'Jaén',
  'malaga': 'Málaga',
  'sevilla': 'Sevilla',
  'huesca': 'Huesca',
  'teruel': 'Teruel',
  'zaragoza': 'Zaragoza',
  'asturias': 'Asturias',
  'baleares': 'Baleares',
  'barcelona': 'Barcelona',
  'girona': 'Girona',
  'lleida': 'Lleida',
  'tarragona': 'Tarragona',
  'cuenca': 'Cuenca',
  'guadalajara': 'Guadalajara',
  'toledo': 'Toledo',
  'ciudad-real': 'Ciudad Real',
  'albacete': 'Albacete',
  'badajoz': 'Badajoz',
  'caceres': 'Cáceres',
  'corunha': 'A Coruña',
  'lugo': 'Lugo',
  'ourense': 'Ourense',
  'pontevedra': 'Pontevedra',
  'madrid': 'Madrid',
  'murcia': 'Murcia',
  'navarra': 'Navarra',
  'alava': 'Álava',
  'guipuzcoa': 'Guipúzcoa',
  'vizcaya': 'Vizcaya',
  'la-rioja': 'La Rioja',
  'segovia': 'Segovia',
  'soria': 'Soria',
  'valladolid': 'Valladolid',
  'avila': 'Ávila',
  'burgos': 'Burgos',
  'leon': 'León',
  'palencia': 'Palencia',
  'salamanca': 'Salamanca',
  'zamora': 'Zamora',
  'alicante': 'Alicante',
  'castellon': 'Castellón',
  'valencia': 'Valencia',
  'ceuta': 'Ceuta',
  'melilla': 'Melilla',
};

class Categoria {
  final String slug;
  final String label;
  final String emoji;
  const Categoria({required this.slug, required this.label, required this.emoji});
}

const List<Categoria> kBuscadores = [
  Categoria(slug: 'desean-alquilar-vivienda',        label: 'Alquilar vivienda',        emoji: '🏠'),
  Categoria(slug: 'desean-comprar-vivienda',          label: 'Comprar vivienda',          emoji: '🏡'),
  Categoria(slug: 'desean-compartir-piso',            label: 'Compartir piso',            emoji: '🤝'),
  Categoria(slug: 'desean-alquilar-habitacion',       label: 'Alquilar habitación',       emoji: '🛏️'),
  Categoria(slug: 'desean-alquilar-plaza-de-garaje',  label: 'Alquilar plaza de garaje',  emoji: '🚗'),
  Categoria(slug: 'desean-comprar-plaza-de-garaje',   label: 'Comprar plaza de garaje',   emoji: '🅿️'),
  Categoria(slug: 'desean-compartir-garaje',          label: 'Compartir garaje',          emoji: '🔑'),
];

const List<Categoria> kPropietarios = [
  Categoria(slug: 'alquilo-vivienda',    label: 'Alquilo vivienda',    emoji: '🏠'),
  Categoria(slug: 'vendo-vivienda',      label: 'Vendo vivienda',      emoji: '🏡'),
  Categoria(slug: 'alquilo-habitacion',  label: 'Alquilo habitación',  emoji: '🛏️'),
  Categoria(slug: 'alquilo-garaje',      label: 'Alquilo garaje',      emoji: '🚗'),
  Categoria(slug: 'vendo-garaje',        label: 'Vendo garaje',        emoji: '🅿️'),
  Categoria(slug: 'comparto-garaje',     label: 'Comparto garaje',     emoji: '🔑'),
];

// ==================== PÁGINA PRINCIPAL ====================

class WebPage extends StatefulWidget {
  const WebPage({super.key});
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;
  String? _fcmToken;
  int _lastUserId = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String _currentUrl = "https://zoomubik.com";

  // Provincia seleccionada en el drawer
  String _provinciaSeleccionada = 'madrid';

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: const Color(0xFF3BA1DA),
      ),
      onRefresh: () async {
        await _controller?.reload();
      },
    );
    _restoreCookies();
    _initPushNotifications();
  }

  void _navegarACategoria(String categoriaSlug) {
    final url =
        'https://zoomubik.com/$categoriaSlug/$_provinciaSeleccionada/';
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    Navigator.of(context).pop(); // cerrar drawer
  }

  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcm = await messaging.getToken();
    if (fcm != null) {
      _fcmToken = fcm;
    }

    messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _checkAndSendToken();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'] ?? '';
      final url  = message.data['url']  ?? '';
      if (type == 'nuevo_anuncio' && url.isNotEmpty && _controller != null) {
        _showInAppNotificationBanner(
          title: message.notification?.title ?? '¡Nuevo anuncio!',
          body:  message.notification?.body  ?? '',
          onTap: () => _controller!.loadUrl(
            urlRequest: URLRequest(url: WebUri(url)),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final url = message.data['url'] ?? '';
      if (url.isNotEmpty && _controller != null) {
        _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final url = initialMessage.data['url'] ?? '';
      if (url.isNotEmpty) {
        Future.delayed(const Duration(seconds: 3), () {
          _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
        });
      }
    }
  }

  void _showInAppNotificationBanner({
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    final context = _scaffoldKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              onTap();
              entry.remove();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3BA1DA), width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF15418A))),
                        const SizedBox(height: 2),
                        Text(body,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => entry.remove(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _checkAndSendToken() async {
    if (_fcmToken == null) {
      _fcmToken = await FirebaseMessaging.instance.getToken();
    }
    if (_fcmToken == null) return;

    try {
      final userId = await _getUserIdViaAjax();
      if (userId > 0 && userId != _lastUserId) {
        _lastUserId = userId;
        await _sendTokenViaHttp(userId, _fcmToken!);
      }
    } catch (e) {
      // Error silencioso
    }
  }

  Future<int> _getUserIdViaAjax() async {
    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.post(
        Uri.parse("https://www.zoomubik.com/wp-admin/admin-ajax.php"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Cookie": cookieHeader,
        },
        body: {"action": "get_current_user_id"},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"]?["user_id"] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String> _getCookieHeader() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri("https://zoomubik.com"),
    );
    return cookies.map((c) => "${c.name}=${c.value}").join("; ");
  }

  Future<void> _sendTokenViaHttp(int userId, String token) async {
    try {
      await http.post(
        Uri.parse(
            "https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "token": token}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _restoreCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("wp_cookies");
    if (saved == null) return;

    final List cookies = jsonDecode(saved);
    for (final c in cookies) {
      await CookieManager.instance().setCookie(
        url: WebUri("https://zoomubik.com"),
        name: c["name"],
        value: c["value"],
        domain: c["domain"] ?? ".zoomubik.com",
        isHttpOnly: c["isHttpOnly"] ?? false,
        isSecure: c["isSecure"] ?? false,
      );
    }
  }

  Future<void> _saveCookies() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri("https://zoomubik.com"),
    );
    if (cookies.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final data = cookies
        .map((c) => {
              "name": c.name,
              "value": c.value,
              "domain": c.domain,
              "isHttpOnly": c.isHttpOnly,
              "isSecure": c.isSecure,
            })
        .toList();
    await prefs.setString("wp_cookies", jsonEncode(data));
  }

  Future<void> _hideAppBanners(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: """
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          .app-promotion-content,
          .app-promotion-banner,
          .cky-consent-container,
          .cky-consent-bar {
            display: none !important;
          }
        `;
        document.head.appendChild(style);
      })();
    """);
  }

  void _monitorUserChanges() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _checkAndSendToken();
      _monitorUserChanges();
    });
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildDrawer(context),
      body: Column(
        children: [
          SizedBox(height: topInset),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest:
                      URLRequest(url: WebUri("https://zoomubik.com")),
                  pullToRefreshController: _pullToRefreshController,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    cacheEnabled: true,
                    useHybridComposition: true,
                    hardwareAcceleration: true,
                    userAgent:
                        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 ZoomubikApp/1.0",
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStop: (controller, url) async {
                    _pullToRefreshController?.endRefreshing();
                    if (url != null) {
                      setState(() {
                        _currentUrl = url.toString();
                        _isLoading = false;
                      });
                    }
                    await _saveCookies();
                    await _hideAppBanners(controller);
                    await Future.delayed(const Duration(seconds: 2));
                    await _checkAndSendToken();
                    _monitorUserChanges();
                  },
                ),

                // Botón hamburguesa flotante (esquina superior derecha)
                if (!_isLoading)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _scaffoldKey.currentState?.openEndDrawer(),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF3BA1DA).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            size: 22,
                            color: Color(0xFF15418A),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Splash screen
                if (_isLoading)
                  AnimatedOpacity(
                    opacity: _isLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 160,
                            ),
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(
                              color: Color(0xFF3BA1DA),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }

  // ==================== DRAWER ====================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF15418A),
              ),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', height: 32),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Selector de provincia
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROVINCIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3BA1DA),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3BA1DA).withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _provinciaSeleccionada,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF15418A)),
                        style: const TextStyle(
                          color: Color(0xFF15418A),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        items: kProvincias.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _provinciaSeleccionada = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Lista de categorías scrollable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _buildSeccionTitulo('🔍  BUSCAN'),
                  ...kBuscadores.map((cat) => _buildCategoriaTile(cat)),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSeccionTitulo('🏠  OFRECEN'),
                  ...kPropietarios.map((cat) => _buildCategoriaTile(cat)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3BA1DA),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCategoriaTile(Categoria cat) {
    return ListTile(
      dense: true,
      leading: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        cat.label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF15418A),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          size: 18, color: Color(0xFF3BA1DA)),
      onTap: () => _navegarACategoria(cat.slug),
    );
  }
}
