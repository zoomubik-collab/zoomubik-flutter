import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:geolocator/geolocator.dart";
import "dart:collection";
import "dart:convert";
import "dart:math" as math;
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

// Coordenadas (lat, lng) del centro de cada provincia
const Map<String, List<double>> kProvinciaCoords = {
  'almeria':       [36.8381, -2.4597],
  'cadiz':         [36.5298, -6.2924],
  'cordoba':       [37.8882, -4.7794],
  'granada':       [37.1773, -3.5986],
  'huelva':        [37.2614, -6.9447],
  'jaen':          [37.7796, -3.7849],
  'malaga':        [36.7213, -4.4214],
  'sevilla':       [37.3891, -5.9845],
  'huesca':        [42.1401, -0.4087],
  'teruel':        [40.3457, -1.1065],
  'zaragoza':      [41.6488, -0.8891],
  'asturias':      [43.3614, -5.8593],
  'baleares':      [39.5696, 2.6502],
  'barcelona':     [41.3851, 2.1734],
  'girona':        [41.9794, 2.8214],
  'lleida':        [41.6176, 0.6200],
  'tarragona':     [41.1189, 1.2445],
  'cuenca':        [40.0704, -2.1374],
  'guadalajara':   [40.6333, -3.1669],
  'toledo':        [39.8628, -4.0273],
  'ciudad-real':   [38.9848, -3.9274],
  'albacete':      [38.9943, -1.8585],
  'badajoz':       [38.8794, -6.9707],
  'caceres':       [39.4753, -6.3725],
  'corunha':       [43.3623, -8.4115],
  'lugo':          [43.0097, -7.5567],
  'ourense':       [42.3401, -7.8645],
  'pontevedra':    [42.4310, -8.6444],
  'madrid':        [40.4168, -3.7038],
  'murcia':        [37.9922, -1.1307],
  'navarra':       [42.8125, -1.6458],
  'alava':         [42.8467, -2.6716],
  'guipuzcoa':     [43.3183, -1.9812],
  'vizcaya':       [43.2630, -2.9350],
  'la-rioja':      [42.4627, -2.4451],
  'segovia':       [40.9429, -4.1088],
  'soria':         [41.7665, -2.4790],
  'valladolid':    [41.6523, -4.7245],
  'avila':         [40.6566, -4.6817],
  'burgos':        [42.3439, -3.6970],
  'leon':          [42.5987, -5.5671],
  'palencia':      [42.0095, -4.5288],
  'salamanca':     [40.9701, -5.6635],
  'zamora':        [41.5036, -5.7448],
  'alicante':      [38.3452, -0.4810],
  'castellon':     [39.9864, -0.0513],
  'valencia':      [39.4699, -0.3763],
  'ceuta':         [35.8894, -5.3213],
  'melilla':       [35.2923, -2.9381],
};

// Calcula distancia Haversine entre dos puntos
double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
      math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

// Encuentra la provincia más cercana a unas coordenadas
String _findNearestProvincia(double lat, double lng) {
  String nearest = 'madrid';
  double minDist = double.infinity;
  kProvinciaCoords.forEach((slug, coords) {
    final d = _distanceKm(lat, lng, coords[0], coords[1]);
    if (d < minDist) {
      minDist = d;
      nearest = slug;
    }
  });
  return nearest;
}

// Categorías unificadas: una sola lista donde cada categoría tiene
// dos posibles destinos (buscador y/o propietario)
class CategoriaUnificada {
  final String label;
  final String emoji;
  final String? buscadorSlug;
  final String? propietarioSlug;
  const CategoriaUnificada({
    required this.label,
    required this.emoji,
    this.buscadorSlug,
    this.propietarioSlug,
  });
}

const List<CategoriaUnificada> kCategorias = [
  CategoriaUnificada(
    label: 'Vivienda en alquiler', emoji: '🏠',
    buscadorSlug: 'desean-alquilar-vivienda',
    propietarioSlug: 'alquilo-vivienda',
  ),
  CategoriaUnificada(
    label: 'Vivienda en venta', emoji: '🏡',
    buscadorSlug: 'desean-comprar-vivienda',
    propietarioSlug: 'vendo-vivienda',
  ),
  CategoriaUnificada(
    label: 'Habitación en alquiler', emoji: '🛏️',
    buscadorSlug: 'desean-alquilar-habitacion',
    propietarioSlug: 'alquilo-habitacion',
  ),
  CategoriaUnificada(
    label: 'Vacacional', emoji: '🏖️',
    buscadorSlug: 'desean-alquiler-vacacional',
    propietarioSlug: 'alquilo-vacacional',
  ),
  CategoriaUnificada(
    label: 'Garaje en alquiler', emoji: '🚗',
    buscadorSlug: 'desean-alquilar-plaza-de-garaje',
    propietarioSlug: 'alquilo-garaje',
  ),
  CategoriaUnificada(
    label: 'Garaje en venta', emoji: '🅿️',
    buscadorSlug: 'desean-comprar-plaza-de-garaje',
    propietarioSlug: 'vendo-garaje',
  ),
  CategoriaUnificada(
    label: 'Compartir garaje', emoji: '🔑',
    buscadorSlug: 'desean-compartir-garaje',
    propietarioSlug: 'comparto-garaje',
  ),
];

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
  Categoria(slug: 'desean-alquiler-vacacional',      label: 'Alquiler vacacional',      emoji: '🏖️'),
  Categoria(slug: 'desean-alquilar-plaza-de-garaje', label: 'Alquilar plaza de garaje', emoji: '🚗'),
  Categoria(slug: 'desean-comprar-plaza-de-garaje',  label: 'Comprar plaza de garaje',  emoji: '🅿️'),
  Categoria(slug: 'desean-compartir-garaje',         label: 'Compartir garaje',         emoji: '🔑'),
];

const List<Categoria> kPropietarios = [
  Categoria(slug: 'alquilo-vivienda',    label: 'Alquilo vivienda',    emoji: '🏠'),
  Categoria(slug: 'vendo-vivienda',      label: 'Vendo vivienda',      emoji: '🏡'),
  Categoria(slug: 'alquilo-habitacion',  label: 'Alquilo habitación',  emoji: '🛏️'),
  Categoria(slug: 'alquilo-vacacional',  label: 'Alquiler vacacional', emoji: '🏖️'),
  Categoria(slug: 'alquilo-garaje',      label: 'Alquilo garaje',      emoji: '🚗'),
  Categoria(slug: 'vendo-garaje',        label: 'Vendo garaje',        emoji: '🅿️'),
  Categoria(slug: 'comparto-garaje',     label: 'Comparto garaje',     emoji: '🔑'),
];

// ==================== TABS ====================

int _tabFromUrl(String url) {
  if (url.contains('/mis-favoritos')) return 1;
  if (url.contains('abrir_publicar')) return 2;
  if (url.contains('/mensajes-privados')) return 3;
  if (url.contains('/account') || url.contains('/mis-anuncios') || url.contains('/mi-avatar')) return 4;
  return 0;
}

// CSS inyectado al inicio para evitar parpadeo del footer web
const String kHideWebFooterCSS = """
  .mobile-footer-sticky { display: none !important; visibility: hidden !important; }
  body #ast-scroll-top.ast-scroll-top { bottom: 8px !important; right: 12px !important; }
""";

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
  String? _avatarUrl;
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
    _loadOrDetectProvincia();
    _restoreCookies();
    _initPushNotifications();
  }

  Future<void> _loadOrDetectProvincia() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('provincia_seleccionada');
    if (saved != null && kProvincias.containsKey(saved)) {
      setState(() => _provinciaSeleccionada = saved);
      return;
    }
    // Primera vez: intentar detectar ubicación
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 8));
      final detected = _findNearestProvincia(position.latitude, position.longitude);
      await prefs.setString('provincia_seleccionada', detected);
      if (mounted) setState(() => _provinciaSeleccionada = detected);
    } catch (e) {
      // Si falla, queda Madrid por defecto
    }
  }

  Future<void> _saveProvincia(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('provincia_seleccionada', slug);
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

  void _navegarAPublicarProvincia() {
    final url = 'https://zoomubik.com/provincias/$_provinciaSeleccionada/';
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    setState(() => _selectedTab = 2);
  }

  void _navigateTo(String url) {
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  // ==================== TAB BAR ====================

  void _onTabTapped(int index) {
    // Si no está logueado, todos los tabs (menos Inicio) requieren login
    if (_lastUserId == 0 && index != 0) {
      _triggerLoginModal();
      return;
    }
    if (index == 2) {
      // Publicar: llamar a la función JS abrirModalProvincias(), o navegar si no existe
      _controller?.evaluateJavascript(source: """
        (function() {
          if (typeof abrirModalProvincias === 'function') {
            abrirModalProvincias();
          } else {
            window.location.href = 'https://zoomubik.com/?abrir_publicar=1';
          }
        })();
      """);
      return;
    }
    if (index == 4) {
      _showCuentaSheet();
      return;
    }
    setState(() => _selectedTab = index);
    final urls = [
      'https://zoomubik.com/',
      'https://zoomubik.com/mis-favoritos/',
      '',
      'https://zoomubik.com/mensajes-privados/',
      'https://zoomubik.com/account/',
    ];
    _navigateTo(urls[index]);
  }

  void _triggerLoginModal() {
    _controller?.evaluateJavascript(source: """
      (function() {
        // Llamar a la función global de login si existe
        if (typeof window.abrirGlobalLoginModal === 'function') {
          window.abrirGlobalLoginModal();
          return;
        }
        // Fallback: click en el botón de login
        var btn = document.querySelector('#cuenta-menu-login-btn, .cuenta-menu-btn-login');
        if (btn) { btn.click(); return; }
        // Último recurso: navegar a account
        window.location.href = 'https://zoomubik.com/account/';
      })();
    """);
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
              icon: Icons.logout_rounded, label: 'Cerrar sesión', color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _navigateTo('https://zoomubik.com/logout/');
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
      if (url.isNotEmpty && _controller != null) _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
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
        _fcmToken = null; _lastUserId = 0;
        if (mounted) setState(() => _avatarUrl = null);
        return;
      }
      if (userId > 0 && userId != _lastUserId) {
        _fcmToken ??= await FirebaseMessaging.instance.getToken();
        if (_fcmToken == null) return;
        _lastUserId = userId;
        await _sendTokenViaHttp(userId, _fcmToken!);
        await _fetchUserAvatar(userId);
      }
    } catch (e) {}
  }

  Future<void> _fetchUserAvatar(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/user-avatar?user_id=$userId"),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['avatar_url'] as String?;
        if (url != null && url.isNotEmpty && mounted) {
          setState(() => _avatarUrl = url);
        }
      }
    } catch (e) {}
  }

  Future<void> _removeTokenFromServer(int userId, String token) async {
    try {
      await http.post(Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/remove-fcm-token"),
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
      await http.post(Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/save-fcm-token"),
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
          .mobile-footer-sticky { display: none !important; visibility: hidden !important; }
          #ast-scroll-top, body #ast-scroll-top.ast-scroll-top { bottom: 8px !important; right: 12px !important; }
        `;
        document.head.appendChild(style);
        var sticky = document.querySelector('.mobile-footer-sticky');
        if (sticky) { sticky.style.display = 'none'; sticky.style.visibility = 'hidden'; }
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
                  // Inyección CSS al inicio para evitar parpadeo del footer web
                  initialUserScripts: UnmodifiableListView([
                    UserScript(
                      source: """
                        (function() {
                          var style = document.createElement('style');
                          style.innerHTML = '$kHideWebFooterCSS';
                          var head = document.head || document.documentElement;
                          head.appendChild(style);
                        })();
                      """,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    ),
                  ]),
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

                // Botón hamburguesa
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

                // Splash
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navItem(index: 0, icon: Icons.home_rounded, label: 'Inicio'),
              _navItem(index: 1, icon: Icons.favorite_rounded, label: 'Favoritos'),
              _navItemPublicar(),
              _navItem(index: 3, icon: Icons.chat_bubble_outline_rounded, label: 'Mensajes'),
              _navItem(index: 4, icon: Icons.person_outline_rounded, label: 'Cuenta'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required int index, required IconData icon, required String label}) {
    final bool selected = _selectedTab == index;
    // Caso especial: tab Cuenta con avatar si está logueado
    if (index == 4 && _avatarUrl != null && _lastUserId > 0) {
      return Expanded(
        child: GestureDetector(
          onTap: () => _onTabTapped(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? const Color(0xFF15418A) : Colors.grey.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    _avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: selected ? const Color(0xFF15418A) : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? const Color(0xFF15418A) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? const Color(0xFF15418A) : Colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? const Color(0xFF15418A) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemPublicar() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3BA1DA), Color(0xFF15418A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF15418A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 3),
            const Text(
              'Publicar',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF15418A)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DRAWER CONTENT ====================

  // Colores por categoría (mismos que los marcadores del mapa)
  Color _categoryColor(String slug) {
    if (slug.contains('vacacional')) return const Color(0xFFFF6B9D); // rosa coral
    if (slug.contains('compartir-piso') || slug.contains('habitacion')) return const Color(0xFFAA00FF); // morado
    if (slug.contains('comprar-vivienda') || slug.contains('vendo-vivienda')) return const Color(0xFFFF6D00); // naranja
    if (slug.contains('vivienda')) return const Color(0xFF00C853); // verde
    if (slug.contains('compartir-garaje') || slug.contains('comparto-garaje')) return const Color(0xFFF50057); // rosa
    if (slug.contains('comprar-plaza') || slug.contains('vendo-garaje')) return const Color(0xFF00BCD4); // cyan
    if (slug.contains('garaje')) return const Color(0xFFFFD600); // amarillo
    return const Color(0xFF3BA1DA);
  }

  Widget _buildDrawerContent(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Drawer(
        backgroundColor: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF15418A), Color(0xFF3BA1DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/logo.png', height: 32),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Selector de provincia
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF3BA1DA)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _provinciaSeleccionada,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF15418A)),
                          style: const TextStyle(color: Color(0xFF15418A), fontSize: 15, fontWeight: FontWeight.w600),
                          items: kProvincias.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _provinciaSeleccionada = val);
                              _saveProvincia(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de categorías unificada
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _seccionTitulo('Categorías', Icons.apps_rounded, const Color(0xFF3BA1DA)),
                    const SizedBox(height: 8),
                    ...kCategorias.map((cat) => _categoriaUnificadaCard(cat)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionTitulo(String titulo, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15418A),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriaUnificadaCard(CategoriaUnificada cat) {
    // Color basado en el slug del buscador (que siempre existe)
    final color = _categoryColor(cat.buscadorSlug ?? cat.propietarioSlug ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSelectorTipo(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cat.label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF15418A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectorTipo(CategoriaUnificada cat) {
    final color = _categoryColor(cat.buscadorSlug ?? cat.propietarioSlug ?? '');

    // Si solo hay una opción, navegar directamente sin modal
    if (cat.buscadorSlug != null && cat.propietarioSlug == null) {
      _navegarACategoria(cat.buscadorSlug!);
      return;
    }
    if (cat.propietarioSlug != null && cat.buscadorSlug == null) {
      _navegarACategoria(cat.propietarioSlug!);
      return;
    }

    // Modal con las dos opciones
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título con emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      cat.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15418A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '¿Qué quieres ver?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Opción 1: Buscadores
              _opcionSelectorTipo(
                icon: Icons.search_rounded,
                title: 'Personas que buscan',
                subtitle: 'Quieren encontrar ${cat.label.toLowerCase()}',
                color: const Color(0xFF3BA1DA),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _navegarACategoria(cat.buscadorSlug!);
                },
              ),
              const SizedBox(height: 10),

              // Opción 2: Propietarios
              _opcionSelectorTipo(
                icon: Icons.home_work_rounded,
                title: 'Propietarios que ofrecen',
                subtitle: 'Ya tienen ${cat.label.toLowerCase()} disponible',
                color: const Color(0xFFFF6D00),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _navegarACategoria(cat.propietarioSlug!);
                },
              ),

              // Separador
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '¿Y si quieres publicar?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                ],
              ),
              const SizedBox(height: 14),

              // Botón Publicar en esta categoría
              _botonPublicarCategoria(
                cat: cat,
                onTap: () {
                  if (cat.propietarioSlug == null) return;
                  if (_lastUserId == 0) {
                    Navigator.pop(sheetContext);
                    Future.delayed(const Duration(milliseconds: 150), _triggerLoginModal);
                    return;
                  }
                  Navigator.pop(sheetContext);
                  _navegarAPublicarProvincia();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonPublicarCategoria({
    required CategoriaUnificada cat,
    required VoidCallback onTap,
  }) {
    final disabled = cat.propietarioSlug == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: disabled ? Colors.grey[200] : null,
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF3BA1DA), Color(0xFF15418A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF15418A).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(disabled ? 0.4 : 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: disabled ? Colors.grey[500] : Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disabled ? 'No disponible' : 'Publicar mi anuncio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: disabled ? Colors.grey[600] : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: disabled
                            ? Colors.grey[500]
                            : Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: disabled ? Colors.grey[500] : Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcionSelectorTipo({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15418A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
