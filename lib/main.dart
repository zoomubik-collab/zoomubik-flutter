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

// ==================== DATOS ====================

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
  Categoria(slug: 'desean-alquilar-vivienda',       label: 'Alquilar vivienda',       emoji: '🏠'),
  Categoria(slug: 'desean-comprar-vivienda',         label: 'Comprar vivienda',         emoji: '🏡'),
  Categoria(slug: 'desean-compartir-piso',           label: 'Compartir piso',           emoji: '🤝'),
  Categoria(slug: 'desean-alquilar-habitacion',      label: 'Alquilar habitación',      emoji: '🛏️'),
  Categoria(slug: 'desean-alquilar-plaza-de-garaje', label: 'Alquilar plaza de garaje', emoji: '🚗'),
  Categoria(slug: 'desean-comprar-plaza-de-garaje',  label: 'Comprar plaza de garaje',  emoji: '🅿️'),
  Categoria(slug: 'desean-compartir-garaje',         label: 'Compartir garaje',         emoji: '🔑'),
];

const List<Categoria> kPropietarios = [
  Categoria(slug: 'alquilo-vivienda',   label: 'Alquilo vivienda',   emoji: '🏠'),
  Categoria(slug: 'vendo-vivienda',     label: 'Vendo vivienda',     emoji: '🏡'),
  Categoria(slug: 'alquilo-habitacion', label: 'Alquilo habitación', emoji: '🛏️'),
  Categoria(slug: 'alquilo-garaje',     label: 'Alquilo garaje',     emoji: '🚗'),
  Categoria(slug: 'vendo-garaje',       label: 'Vendo garaje',       emoji: '🅿️'),
  Categoria(slug: 'comparto-garaje',    label: 'Comparto garaje',    emoji: '🔑'),
];

// ==================== PÁGINA PRINCIPAL ====================

class WebPage extends StatefulWidget {
  const WebPage({super.key});
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> with SingleTickerProviderStateMixin {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;
  String? _fcmToken;
  int _lastUserId = 0;
  bool _isLoading = true;
  String _currentUrl = "https://zoomubik.com";

  // Drawer manual
  bool _drawerOpen = false;
  String _provinciaSeleccionada = 'madrid';
  late AnimationController _drawerAnimController;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _backdropFade;

  @override
  void initState() {
    super.initState();

    _drawerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _drawerAnimController, curve: Curves.easeOut));
    _backdropFade = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _drawerAnimController, curve: Curves.easeOut),
    );

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: const Color(0xFF3BA1DA)),
      onRefresh: () async => await _controller?.reload(),
    );
    _restoreCookies();
    _initPushNotifications();
  }

  @override
  void dispose() {
    _drawerAnimController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerAnimController.forward();
  }

  // FIX: closeDrawer espera a que la animación termine antes de setState
  // y devuelve un Future para que _navegarACategoria pueda esperar
  Future<void> _closeDrawer() async {
    await _drawerAnimController.reverse();
    if (mounted) setState(() => _drawerOpen = false);
  }

  // FIX: primero cierra, luego navega — sin delay fijo
  void _navegarACategoria(String categoriaSlug) async {
    final url = 'https://zoomubik.com/$categoriaSlug/$_provinciaSeleccionada/';
    await _closeDrawer();
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  // ==================== PUSH ====================

  Future<void> _initPushNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final fcm = await messaging.getToken();
    if (fcm != null) _fcmToken = fcm;
    messaging.onTokenRefresh.listen((t) { _fcmToken = t; _checkAndSendToken(); });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'] ?? '';
      final url  = message.data['url']  ?? '';
      if (type == 'nuevo_anuncio' && url.isNotEmpty && _controller != null) {
        _showInAppNotificationBanner(
          title: message.notification?.title ?? '¡Nuevo anuncio!',
          body:  message.notification?.body  ?? '',
          onTap: () => _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url))),
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
    final ctx = context;
    final overlay = Overlay.of(ctx);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () { onTap(); entry.remove(); },
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
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15418A))),
                        const SizedBox(height: 2),
                        Text(body, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
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
    Future.delayed(const Duration(seconds: 5), () { if (entry.mounted) entry.remove(); });
  }

  Future<void> _checkAndSendToken() async {
    if (_fcmToken == null) _fcmToken = await FirebaseMessaging.instance.getToken();
    if (_fcmToken == null) return;
    try {
      final userId = await _getUserIdViaAjax();
      if (userId > 0 && userId != _lastUserId) {
        _lastUserId = userId;
        await _sendTokenViaHttp(userId, _fcmToken!);
      }
    } catch (e) {}
  }

  Future<int> _getUserIdViaAjax() async {
    try {
      final cookieHeader = await _getCookieHeader();
      final response = await http.post(
        Uri.parse("https://www.zoomubik.com/wp-admin/admin-ajax.php"),
        headers: {"Content-Type": "application/x-www-form-urlencoded", "Cookie": cookieHeader},
        body: {"action": "get_current_user_id"},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"]?["user_id"] ?? 0;
      }
      return 0;
    } catch (e) { return 0; }
  }

  Future<String> _getCookieHeader() async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri("https://zoomubik.com"));
    return cookies.map((c) => "${c.name}=${c.value}").join("; ");
  }

  Future<void> _sendTokenViaHttp(int userId, String token) async {
    try {
      await http.post(
        Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "token": token}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {}
  }

  Future<void> _restoreCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("wp_cookies");
    if (saved == null) return;
    final List cookies = jsonDecode(saved);
    for (final c in cookies) {
      await CookieManager.instance().setCookie(
        url: WebUri("https://zoomubik.com"),
        name: c["name"], value: c["value"],
        domain: c["domain"] ?? ".zoomubik.com",
        isHttpOnly: c["isHttpOnly"] ?? false,
        isSecure: c["isSecure"] ?? false,
      );
    }
  }

  Future<void> _saveCookies() async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri("https://zoomubik.com"));
    if (cookies.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final data = cookies.map((c) => {
      "name": c.name, "value": c.value, "domain": c.domain,
      "isHttpOnly": c.isHttpOnly, "isSecure": c.isSecure,
    }).toList();
    await prefs.setString("wp_cookies", jsonEncode(data));
  }

  Future<void> _hideAppBanners(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: """
      (function() {
        var style = document.createElement('style');
        style.innerHTML = '.app-promotion-content,.app-promotion-banner,.cky-consent-container,.cky-consent-bar{display:none!important}';
        document.head.appendChild(style);
      })();
    """);
  }

  // FIX: monitor cada 60 segundos en lugar de 5 para no saturar el servidor
  void _monitorUserChanges() {
    Future.delayed(const Duration(seconds: 60), () {
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: topInset),
          Expanded(
            child: Stack(
              children: [
                // WebView
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("https://zoomubik.com")),
                  pullToRefreshController: _pullToRefreshController,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    cacheEnabled: true,
                    useHybridComposition: true,
                    hardwareAcceleration: true,
                    userAgent: "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 ZoomubikApp/1.0",
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
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

                // Botón hamburguesa — solo intercepta su área exacta
                if (!_isLoading)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openDrawer,
                      child: Container(
                        width: 40,
                        height: 40,
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
                        child: const Icon(Icons.menu_rounded, size: 21, color: Color(0xFF15418A)),
                      ),
                    ),
                  ),

                // FIX: backdrop solo existe cuando _drawerOpen es true
                // y usa AbsorbPointer para garantizar que se destruye limpiamente
                if (_drawerOpen) ...[
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: GestureDetector(
                        onTap: _closeDrawer,
                        child: FadeTransition(
                          opacity: _backdropFade,
                          child: Container(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: MediaQuery.of(context).size.width * 0.82,
                    child: SlideTransition(
                      position: _drawerSlide,
                      child: _buildDrawerContent(context),
                    ),
                  ),
                ],

                // Splash
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
                            Image.asset('assets/logo.png', width: 160),
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(color: Color(0xFF3BA1DA)),
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

  // ==================== DRAWER CONTENT ====================

  Widget _buildDrawerContent(BuildContext context) {
    return Material(
      elevation: 16,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFF15418A),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', height: 30),
                  const Spacer(),
                  GestureDetector(
                    onTap: _closeDrawer,
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROVINCIA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3BA1DA), letterSpacing: 1.2),
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
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF15418A)),
                        style: const TextStyle(color: Color(0xFF15418A), fontSize: 15, fontWeight: FontWeight.w500),
                        items: kProvincias.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _provinciaSeleccionada = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _seccionTitulo('🔍  BUSCAN'),
                  ...kBuscadores.map((cat) => _categoriaTile(cat)),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _seccionTitulo('🏠  OFRECEN'),
                  ...kPropietarios.map((cat) => _categoriaTile(cat)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3BA1DA), letterSpacing: 1.2),
      ),
    );
  }

  Widget _categoriaTile(Categoria cat) {
    return ListTile(
      dense: true,
      leading: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(cat.label, style: const TextStyle(fontSize: 14, color: Color(0xFF15418A), fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF3BA1DA)),
      onTap: () => _navegarACategoria(cat.slug),
    );
  }
}
