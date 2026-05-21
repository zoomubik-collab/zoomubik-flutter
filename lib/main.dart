import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:shared_preferences/shared_preferences.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:share_plus/share_plus.dart";
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
  'almeria': 'Almería', 'cadiz': 'Cádiz', 'cordoba': 'Córdoba',
  'granada': 'Granada', 'huelva': 'Huelva', 'jaen': 'Jaén',
  'malaga': 'Málaga', 'sevilla': 'Sevilla', 'huesca': 'Huesca',
  'teruel': 'Teruel', 'zaragoza': 'Zaragoza', 'asturias': 'Asturias',
  'baleares': 'Baleares', 'barcelona': 'Barcelona', 'girona': 'Girona',
  'lleida': 'Lleida', 'tarragona': 'Tarragona', 'cuenca': 'Cuenca',
  'guadalajara': 'Guadalajara', 'toledo': 'Toledo', 'ciudad-real': 'Ciudad Real',
  'albacete': 'Albacete', 'badajoz': 'Badajoz', 'caceres': 'Cáceres',
  'corunha': 'A Coruña', 'lugo': 'Lugo', 'ourense': 'Ourense',
  'pontevedra': 'Pontevedra', 'madrid': 'Madrid', 'murcia': 'Murcia',
  'navarra': 'Navarra', 'alava': 'Álava', 'guipuzcoa': 'Guipúzcoa',
  'vizcaya': 'Vizcaya', 'la-rioja': 'La Rioja', 'segovia': 'Segovia',
  'soria': 'Soria', 'valladolid': 'Valladolid', 'avila': 'Ávila',
  'burgos': 'Burgos', 'leon': 'León', 'palencia': 'Palencia',
  'salamanca': 'Salamanca', 'zamora': 'Zamora', 'alicante': 'Alicante',
  'castellon': 'Castellón', 'valencia': 'Valencia', 'ceuta': 'Ceuta',
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

// ==================== TABS ====================

const List<String> kTabUrls = [
  'https://zoomubik.com/',
  'https://zoomubik.com/mis-favoritos/',
  'https://zoomubik.com/?abrir_publicar=1',
  'https://zoomubik.com/mensajes-privados/',
  'https://zoomubik.com/account/',
];

int _tabFromUrl(String url) {
  if (url.contains('/mis-favoritos')) return 1;
  if (url.contains('abrir_publicar')) return 2;
  if (url.contains('/mensajes-privados')) return 3;
  if (url.contains('/account') || url.contains('/mis-anuncios') || url.contains('/mi-avatar')) return 4;
  return 0;
}

// ==================== PÁGINA PRINCIPAL ====================

class WebPage extends StatefulWidget {
  const WebPage({super.key});
  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;
  String? _fcmToken;
  int _lastUserId = 0;
  bool _isLoading = true;
  String _currentUrl = "https://zoomubik.com";
  int _selectedTab = 0;

  bool _monitorActive = false;
  String _provinciaSeleccionada = 'madrid';
  bool _navigatedFromDrawer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: const Color(0xFF3BA1DA)),
      onRefresh: () async => await _controller?.reload(),
    );
    _restoreCookies();
    _initPushNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller != null) {
      _controller!.evaluateJavascript(source: """
        (function() {
          if (typeof document.body === 'undefined' || document.body === null) { location.reload(); return; }
          document.dispatchEvent(new Event('zm_app_resumed'));
        })();
      """).catchError((_) => _controller?.reload());
      _hideAppBanners(_controller!);
      _checkAndSendToken();
    }
  }

  void _navegarACategoria(String categoriaSlug) {
    final url = 'https://zoomubik.com/$categoriaSlug/$_provinciaSeleccionada/';
    _navigatedFromDrawer = true;
    Navigator.of(context).pop();
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _navigateTo(String url) {
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  // ==================== TAB BAR ====================

  void _onTabTapped(int index) {
    if (index == 4) { _showCuentaSheet(); return; }
    setState(() => _selectedTab = index);
    _navigateTo(kTabUrls[index]);
  }

  void _showCuentaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _cuentaTile(icon: Icons.manage_accounts_rounded, label: 'Mi cuenta', onTap: () {
              Navigator.pop(context); setState(() => _selectedTab = 4); _navigateTo('https://zoomubik.com/account/');
            }),
            _cuentaTile(icon: Icons.list_alt_rounded, label: 'Mis anuncios', onTap: () {
              Navigator.pop(context); setState(() => _selectedTab = 4); _navigateTo('https://zoomubik.com/mis-anuncios/');
            }),
            _cuentaTile(icon: Icons.photo_camera_rounded, label: 'Mi foto', onTap: () {
              Navigator.pop(context); setState(() => _selectedTab = 4); _navigateTo('https://zoomubik.com/mi-avatar/');
            }),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _cuentaTile(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _controller?.evaluateJavascript(source: """
                  (function() {
                    var link = document.querySelector('a[href*="action=logout"], a[href*="cerrar"], .logout-link');
                    if (link) link.click();
                  })();
                """);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _cuentaTile({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF15418A)),
      title: Text(label, style: TextStyle(color: color ?? const Color(0xFF15418A), fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: color ?? const Color(0xFF3BA1DA)),
      onTap: onTap,
    );
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

  void _showInAppNotificationBanner({required String title, required String body, required VoidCallback onTap}) {
    final ctx = context;
    final overlay = Overlay.of(ctx);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 10, left: 16, right: 16,
        child: Material(
          elevation: 8, borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () { onTap(); entry.remove(); },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3BA1DA), width: 1.5),
              ),
              child: Row(children: [
                const Text('🏠', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15418A))),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
                IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.grey), onPressed: () => entry.remove()),
              ]),
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
      if (userId == 0 && _lastUserId > 0) {
        await _removeTokenFromServer(_lastUserId, _fcmToken!);
        await FirebaseMessaging.instance.deleteToken();
        _fcmToken = null;
        _lastUserId = 0;
        return;
      }
      if (userId > 0 && userId != _lastUserId) {
        _fcmToken ??= await FirebaseMessaging.instance.getToken();
        if (_fcmToken == null) return;
        _lastUserId = userId;
        await _sendTokenViaHttp(userId, _fcmToken!);
      }
    } catch (e) {}
  }

  Future<void> _removeTokenFromServer(int userId, String token) async {
    try {
      await http.post(
        Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/remove-fcm-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "token": token}),
      ).timeout(const Duration(seconds: 10));
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
    final data = cookies.map((c) => {"name": c.name, "value": c.value, "domain": c.domain, "isHttpOnly": c.isHttpOnly, "isSecure": c.isSecure}).toList();
    await prefs.setString("wp_cookies", jsonEncode(data));
  }

  Future<void> _hideAppBanners(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: """
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          .app-promotion-content, .app-promotion-banner,
          .cky-consent-container, .cky-consent-bar { display: none !important; }
          #header-registro-btn { display: none !important; }
          .header-search-wrap { padding-right: 52px !important; }
          .mobile-footer-sticky { display: none !important; }
          .footer-principal, .footer-nav-app, .bottom-nav-bar,
          [class*="bottom-tab"], [class*="nav-footer"] { display: none !important; }
        `;
        document.head.appendChild(style);
      })();
    """);
  }

  void _monitorUserChanges() {
    if (_monitorActive) return;
    _monitorActive = true;
    _monitorLoop();
  }

  void _monitorLoop() {
    Future.delayed(const Duration(seconds: 60), () {
      if (!mounted) { _monitorActive = false; return; }
      _checkAndSendToken();
      _monitorLoop();
    });
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildDrawerContent(context),
      endDrawerEnableOpenDragGesture: false,
      onEndDrawerChanged: (isOpen) {
        if (!isOpen && _controller != null) {
          if (_navigatedFromDrawer) { _navigatedFromDrawer = false; } else { _controller!.reload(); }
        }
      },
      bottomNavigationBar: _buildBottomNav(),
      body: Column(
        children: [
          SizedBox(height: topInset),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("https://zoomubik.com")),
                  pullToRefreshController: _pullToRefreshController,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true, domStorageEnabled: true, databaseEnabled: true,
                    cacheEnabled: true, useHybridComposition: true, hardwareAcceleration: true,
                    userAgent: "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 ZoomubikApp/1.0",
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onLoadStop: (controller, url) async {
                    _pullToRefreshController?.endRefreshing();
                    if (url != null) {
                      setState(() { _currentUrl = url.toString(); _isLoading = false; _selectedTab = _tabFromUrl(url.toString()); });
                    }
                    await _saveCookies();
                    await _hideAppBanners(controller);
                    await Future.delayed(const Duration(seconds: 2));
                    await _checkAndSendToken();
                    _monitorUserChanges();
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) {
                    if (url != null) {
                      setState(() { _currentUrl = url.toString(); _selectedTab = _tabFromUrl(url.toString()); });
                    }
                  },
                ),

                if (!_isLoading)
                  Positioned(
                    top: 8, right: 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95), shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
                          border: Border.all(color: const Color(0xFF3BA1DA).withOpacity(0.4), width: 1),
                        ),
                        child: const Icon(Icons.menu_rounded, size: 21, color: Color(0xFF15418A)),
                      ),
                    ),
                  ),

                if (_isLoading)
                  AnimatedOpacity(
                    opacity: _isLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      color: Colors.white,
                      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Image.asset('assets/logo.png', width: 160),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(color: Color(0xFF3BA1DA)),
                      ])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAV ====================

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF15418A),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      elevation: 12,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
        const BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favoritos'),
        BottomNavigationBarItem(
          icon: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: Color(0xFF15418A), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
          label: 'Publicar',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Mensajes'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Cuenta'),
      ],
    );
  }

  // ==================== DRAWER CONTENT ====================

  Widget _buildDrawerContent(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.82,
      child: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: const Color(0xFF15418A),
                child: Row(children: [
                  Image.asset('assets/logo.png', height: 30),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, color: Colors.white, size: 22)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PROVINCIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3BA1DA), letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3BA1DA).withOpacity(0.4)), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, value: _provinciaSeleccionada,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF15418A)),
                        style: const TextStyle(color: Color(0xFF15418A), fontSize: 15, fontWeight: FontWeight.w500),
                        items: kProvincias.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (val) { if (val != null) setState(() => _provinciaSeleccionada = val); },
                      ),
                    ),
                  ),
                ]),
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
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3BA1DA), letterSpacing: 1.2)),
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
