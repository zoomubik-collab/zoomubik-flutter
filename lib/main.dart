import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:vibration/vibration.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:geolocator/geolocator.dart";
import "dart:collection";
import "dart:convert";
import "dart:io" show Platform, InternetAddress, SocketException;
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
  await FirebaseAnalytics.instance.logAppOpen(); // activa GA4 (flujos app de ios-app-42b04)
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
  if (url.contains('/notificaciones')) return 5;
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
  int _zeroStrikes = 0;
  String? _avatarUrl;
  int _unreadCount = 0;
  int _notifCount = 0;
  bool _isLoading = true;
  String _currentUrl = "https://zoomubik.com";
  int _selectedTab = 0;

  bool _monitorActive = false;
  bool _isOffline = false;
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
    _initPushNotifications();
  }

  Future<void> _loadOrDetectProvincia() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('provincia_seleccionada');
    final manual = prefs.getBool('provincia_manual') ?? false;

    // Si el usuario eligió la provincia A MANO, respetamos su elección y no detectamos.
    if (manual && saved != null && kProvincias.containsKey(saved)) {
      setState(() => _provinciaSeleccionada = saved);
      return;
    }

    // Mostramos de momento la guardada (o Madrid por defecto) para no quedar en blanco
    // mientras se intenta detectar.
    if (saved != null && kProvincias.containsKey(saved)) {
      setState(() => _provinciaSeleccionada = saved);
    }

    // Intentamos detectar la ubicación SIEMPRE que NO sea elección manual,
    // para corregir provincias antiguas o por defecto (ej. quedarse en "madrid").
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
      // NO marcamos 'provincia_manual': sigue siendo detección automática.
      if (mounted) setState(() => _provinciaSeleccionada = detected);
    } catch (e) {
      // Si falla, se queda la guardada o Madrid por defecto.
    }
  }

  Future<void> _saveProvincia(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('provincia_seleccionada', slug);
    // El usuario la eligió a mano: a partir de ahora respetamos su elección
    // y la detección automática deja de sobreescribirla.
    await prefs.setBool('provincia_manual', true);
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
    _navigatedFromDrawer = true;
    Navigator.of(context).pop();
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    setState(() => _selectedTab = 2);
  }

  void _navigateTo(String url) {
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  // ==================== TAB BAR ====================

  Future<void> _onTabTapped(int index) async {
    // Tabs que requieren login (todos menos Inicio y Publicar).
    if (_lastUserId == 0 && index != 0 && index != 2) {
      // Reconfirmar antes de bloquear: la comprobación de fondo pudo no haber corrido aún
      // o haber fallado por red. Solo bloqueamos si el servidor confirma que NO hay sesión.
      final uid = await _getUserIdViaAjax();
      if (uid != null && uid > 0) {
        _lastUserId = uid;
        _zeroStrikes = 0;
        _fetchUserAvatar(uid);
        if (mounted) setState(() {});
        // Hay sesión: seguimos sin bloquear.
      } else if (uid == 0) {
        _triggerLoginModal();
        return;
      }
      // uid == null (no se pudo comprobar): dejamos pasar; la web mostrará login si hiciera falta.
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

  void _triggerLoginModal() async {
    // Antes de abrir el login, limpiar las cookies de sesión "a medias" que el
    // WebView de Android puede dejar corruptas (causa del "usuario o contraseña
    // incorrecta" al re-loguearse). Así el login parte de un estado limpio.
    try {
      await CookieManager.instance().deleteCookies(url: WebUri("https://zoomubik.com"));
      await CookieManager.instance().deleteCookies(url: WebUri("https://www.zoomubik.com"));
    } catch (_) {}
    _controller?.evaluateJavascript(source: """
      (function() {
        // Modal global del header (el correcto: Google + Apple + email)
        if (typeof window.abrirGlobalLoginModal === 'function') {
          window.abrirGlobalLoginModal();
          return;
        }
        if (typeof window.openLoginModal === 'function') {
          window.openLoginModal();
          return;
        }
        // Fallback 1: modal del footer
        var modal = document.getElementById('footer-login-modal');
        if (modal) {
          modal.style.display = 'flex';
          return;
        }
        // Fallback 2: click en el botón aunque esté oculto
        var btn = document.querySelector('#cuenta-menu-login-btn, .cuenta-menu-btn-login');
        if (btn) { btn.click(); return; }
        // Último recurso: navegar
        window.location.href = 'https://zoomubik.com/account/';
      })();
    """);
  }

  void _showCuentaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 18),
              // Cabecera con avatar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF3BA1DA), Color(0xFF15418A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty) ? const Icon(Icons.person_rounded, color: Color(0xFF15418A), size: 30) : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi cuenta', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF15418A))),
                        SizedBox(height: 2),
                        Text('Gestiona tu perfil y anuncios', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _cuentaOpcion(icon: Icons.manage_accounts_rounded, color: const Color(0xFF3BA1DA), title: 'Mi cuenta', subtitle: 'Datos y ajustes', onTap: () {
                      Navigator.pop(context); setState(() => _selectedTab = 4); _navigateTo('https://zoomubik.com/account/');
                    }),
                    _cuentaOpcion(icon: Icons.list_alt_rounded, color: const Color(0xFF15418A), title: 'Mis anuncios', subtitle: 'Gestiona tus publicaciones', onTap: () {
                      Navigator.pop(context); setState(() => _selectedTab = 4); _navigateTo('https://zoomubik.com/mis-anuncios/');
                    }),
                    _cuentaOpcion(icon: Icons.photo_camera_rounded, color: const Color(0xFF7C5CFF), title: 'Mi foto', subtitle: 'Cambia tu avatar', onTap: () {
                      Navigator.pop(context); setState(() => _selectedTab = 4); _navigateTo('https://zoomubik.com/mi-avatar/');
                    }),
                    _cuentaOpcion(icon: Icons.notifications_none_rounded, color: const Color(0xFFFF9500), title: 'Notificaciones', subtitle: 'Tus avisos', badge: _notifCount, onTap: () {
                      Navigator.pop(context); setState(() { _selectedTab = 5; _notifCount = 0; }); _navigateTo('https://zoomubik.com/notificaciones/');
                    }),
                    const SizedBox(height: 6),
                    _cuentaOpcion(icon: Icons.logout_rounded, color: const Color(0xFFFF3B30), title: 'Cerrar sesión', danger: true, onTap: () {
                      Navigator.pop(context);
                      _cerrarSesionInmediato();
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuentaOpcion({required IconData icon, required Color color, required String title, String? subtitle, required VoidCallback onTap, bool danger = false, int badge = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: danger ? const Color(0xFFFF3B30) : const Color(0xFF1A2942))),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ),
                if (badge > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(12)),
                    child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                Icon(Icons.chevron_right_rounded, color: danger ? const Color(0xFFFF3B30) : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
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
      if ((type == 'nuevo_anuncio' || type == 'nuevo_mensaje') && url.isNotEmpty && _controller != null) {
        _showInAppNotificationBanner(
          title: message.notification?.title ?? (type == 'nuevo_mensaje' ? 'Nuevo mensaje' : '¡Nuevo anuncio!'),
          body:  message.notification?.body  ?? '',
          onTap: () => _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url))),
        );
      }
      // Refrescar contador si llega un mensaje
      if (type == 'nuevo_mensaje' && _lastUserId > 0) {
        _fetchUnreadCount(_lastUserId);
      }
      if (_lastUserId > 0) {
        _fetchNotifCount(_lastUserId);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final url = message.data['url'] ?? '';
      if (url.isNotEmpty && _controller != null) _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    });

    // El destino de una notificación que abrió la app se gestiona en onWebViewCreated
    // (carga directa, sin pasar por Inicio ni saltos).
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

  // Logout MANUAL e inmediato: limpia el estado al instante (sin esperar al timer)
  // y navega a la página de logout para cerrar la sesión en el servidor.
  Future<void> _cerrarSesionInmediato() async {
    final oldId = _lastUserId;
    _lastUserId = 0;
    _zeroStrikes = 0;
    if (mounted) setState(() { _avatarUrl = null; _unreadCount = 0; _notifCount = 0; });
    if (_fcmToken != null && oldId > 0) {
      _removeTokenFromServer(oldId, _fcmToken!);
      try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
      _fcmToken = null;
    }
    _navigateTo('https://zoomubik.com/logout/');
  }

  // Comprueba si hay conexión real a internet (no solo WiFi conectado).
  Future<bool> _hayConexion() async {
    try {
      final result = await InternetAddress.lookup('zoomubik.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkAndSendToken() async {
    // No comprobar mientras la página está cargando: el JS fetch devuelve 0
    // durante transiciones de página y acumula falsos strikes de logout.
    if (_isLoading) return;
    try {
      final userId = await _getUserIdViaAjax();

      // Comprobación no concluyente (timeout/red): mantener el estado actual, NO desloguear.
      if (userId == null) return;

      // Logout: solo si el servidor confirma 0, y exigiendo varias veces seguidas
      // para no echar al usuario por un fallo puntual.
      if (userId == 0) {
        if (_lastUserId > 0) {
          _zeroStrikes++;
          // Al primer cero, intentar RESTAURAR las cookies guardadas: puede que el
          // WebView las haya limpiado (Android libera memoria) y la sesión siga viva
          // en el servidor. Si se recupera, no desloguea.
          if (_zeroStrikes == 1) {
            await _restoreCookies();
            return;
          }
          if (_zeroStrikes < 5) return;  // 5 ceros × 5s = 25s de confirmación antes de desloguear
          final oldId = _lastUserId;
          _lastUserId = 0;
          _zeroStrikes = 0;
          if (mounted) setState(() { _avatarUrl = null; _unreadCount = 0; _notifCount = 0; });
          // Recargar la página tras detectar logout para que el modal de login
          // tenga un nonce fresco y no dé "usuario o contraseña incorrecta".
          _controller?.reload();
          if (_fcmToken != null) {
            await _removeTokenFromServer(oldId, _fcmToken!);
            await FirebaseMessaging.instance.deleteToken();
            _fcmToken = null;
          }
        }
        return;
      }

      // userId > 0 → logueado: reseteamos el contador de ceros.
      _zeroStrikes = 0;

      // Login nuevo o cambio de usuario → avatar y contadores YA, sin esperar al token
      if (userId != _lastUserId) {
        _lastUserId = userId;
        _fetchUserAvatar(userId);   // sin await: aparece en cuanto responde
      }
      if (_lastUserId > 0) {
        _fetchUnreadCount(_lastUserId);
        _fetchNotifCount(_lastUserId);
      }

      // El token FCM se gestiona en segundo plano, sin bloquear nada visual
      if (_lastUserId > 0) {
        _fcmToken ??= await FirebaseMessaging.instance.getToken();
        if (_fcmToken != null) { _sendTokenViaHttp(_lastUserId, _fcmToken!); }
      }
    } catch (e) {}
  }

  Future<void> _fetchUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/unread-count?user_id=$userId"),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['unread_count'] as int? ?? 0;
        if (mounted && count != _unreadCount) {
          setState(() => _unreadCount = count);
        }
      }
    } catch (e) {}
  }

  Future<void> _fetchNotifCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("https://www.zoomubik.com/wp-json/zoomubik/v1/notif-unread-count?user_id=$userId"),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['notif_unread'] as int? ?? 0;
        if (mounted && count != _notifCount) {
          setState(() => _notifCount = count);
        }
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

  // Devuelve: >0 logueado, 0 confirmado deslogueado, null = no se pudo comprobar.
  // Usa fetch() DESDE el WebView con credentials:'include' para que el navegador
  // envie TODAS las cookies (incluidas httpOnly) sin depender del CookieManager.
  Future<int?> _getUserIdViaAjax() async {
    if (_controller != null) {
      try {
        final result = await _controller!.evaluateJavascript(source:
          "(async function() {"
          "  try {"
          "    const r = await fetch('/wp-admin/admin-ajax.php', {"
          "      method: 'POST', credentials: 'include',"
          "      headers: {'Content-Type': 'application/x-www-form-urlencoded'},"
          "      body: 'action=get_current_user_id'"
          "    });"
          "    const d = await r.json();"
          "    return d && d.data ? (parseInt(d.data.user_id) || 0) : 0;"
          "  } catch(e) { return null; }"
          "})()"
        ).timeout(const Duration(seconds: 10));
        if (result != null) {
          final uid = result is int ? result : int.tryParse(result.toString());
          if (uid != null) return uid;
        }
      } catch (_) {}
    }
    // Fallback HTTP desde Dart (puede tardar en sincronizarse en Android)
    try {
      final cookies = await CookieManager.instance().getCookies(url: WebUri("https://zoomubik.com"));
      final cookieHeader = cookies.map((c) => "${c.name}=${c.value}").join("; ");
      if (cookieHeader.isEmpty) return null;
      final response = await http.post(
        Uri.parse("https://zoomubik.com/wp-admin/admin-ajax.php"),
        headers: {"Content-Type": "application/x-www-form-urlencoded", "Cookie": cookieHeader},
        body: {"action": "get_current_user_id"},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final uid = data["data"]?["user_id"];
      if (uid is int) return uid;
      if (uid is String) return int.tryParse(uid) ?? 0;
      return 0;
    } catch (e) {
      return null;
    }
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
        expiresDate: c["expiresDate"],
      );
    }
  }

  Future<void> _saveCookies() async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri("https://zoomubik.com"));
    if (cookies.isEmpty) return;
    // Solo guardamos si hay sesión iniciada, para no machacar las cookies buenas con unas de "deslogueado".
    final loggedIn = cookies.any((c) => c.name.startsWith("wordpress_logged_in"));
    if (!loggedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final data = cookies.map((c) => {
      "name": c.name, "value": c.value, "domain": c.domain,
      "isHttpOnly": c.isHttpOnly, "isSecure": c.isSecure,
      "expiresDate": c.expiresDate,
    }).toList();
    await prefs.setString("wp_cookies", jsonEncode(data));
  }

  Future<void> _hideAppBanners(InAppWebViewController controller) async {
    // En Android ocultamos el botón de Sign in with Apple (no disponible en Android)
    final appleHide = Platform.isAndroid
        ? "a[href*='appleid.apple.com'] { display: none !important; }"
        : "";

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
          $appleHide
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
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) { _monitorActive = false; return; }
      _checkAndSendToken();
      // Guardar cookies periódicamente: mantiene el respaldo en disco siempre fresco,
      // para que _restoreCookies() pueda recuperar la sesión si el WebView las limpia.
      if (_lastUserId > 0) _saveCookies();
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
                  initialUrlRequest: URLRequest(url: WebUri("about:blank")),
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
                    // Cookies de sesión en Android: necesario para que la cookie de login
                    // (incluida la que se crea por AJAX) se acepte y persista en el WebView.
                    thirdPartyCookiesEnabled: true,
                    // Cookies de sesión en iOS: el WebView usa el almacén compartido en
                    // tiempo real (login y avatar instantáneos, sin el retardo del método antiguo).
                    sharedCookiesEnabled: true,
                  ),
                  onWebViewCreated: (controller) async {
                    _controller = controller;
                    // Canal haptico: el mapa (JS) llama a
                    // window.flutter_inappwebview.callHandler('haptic', ms)
                    controller.addJavaScriptHandler(
                      handlerName: 'haptic',
                      callback: (args) {
                        int ms = 16;
                        if (args.isNotEmpty) {
                          final v = args[0];
                          if (v is int) {
                            ms = v;
                          } else if (v is double) {
                            ms = v.round();
                          } else if (v is String) {
                            ms = int.tryParse(v) ?? 16;
                          }
                        }
                        if (Platform.isIOS) {
                          // iOS: Taptic Engine (fino). Suave al caer, medio en directo.
                          if (ms >= 25) {
                            HapticFeedback.mediumImpact();
                          } else {
                            HapticFeedback.lightImpact();
                          }
                        } else {
                          // Android: control directo del motor por ms (suenan todos)
                          Vibration.vibrate(duration: ms < 8 ? 8 : ms);
                        }
                      },
                    );
                    await _restoreCookies();
                    // Si la app se abrió tocando una notificación, ir directo a su destino
                    // (evita cargar Inicio y saltar después a la notificación).
                    String startUrl = "https://zoomubik.com";
                    try {
                      final initial = await FirebaseMessaging.instance.getInitialMessage();
                      final nurl = initial?.data['url'] ?? '';
                      if (nurl is String && nurl.isNotEmpty) startUrl = nurl;
                    } catch (_) {}
                    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(startUrl)));
                  },
                  onLoadStart: (controller, url) async {
                    if (url != null && url.toString() == "about:blank") return;
                    if (mounted) setState(() => _isLoading = true);
                    // Comprobar conectividad real: si no hay internet, mostrar pantalla offline
                    // (el WebView no da error si la página está cacheada).
                    final hayInternet = await _hayConexion();
                    if (!hayInternet && mounted) {
                      setState(() { _isOffline = true; _isLoading = false; });
                      _pullToRefreshController?.endRefreshing();
                      return;
                    }
                    // Seguridad: si por lo que sea no llega onLoadStop, ocultamos la rueda a los 15s.
                    Future.delayed(const Duration(seconds: 15), () {
                      if (mounted && _isLoading) setState(() => _isLoading = false);
                    });
                  },
                  onLoadStop: (controller, url) async {
                    if (url != null && url.toString() == "about:blank") return;
                    _pullToRefreshController?.endRefreshing();
                    if (url != null) {
                      setState(() { _currentUrl = url.toString(); _isLoading = false; _isOffline = false; _selectedTab = _tabFromUrl(url.toString()); });
                    }
                    await _saveCookies();
                    await _hideAppBanners(controller);
                    await Future.delayed(const Duration(milliseconds: 400));
                    await _checkAndSendToken();
                    _monitorUserChanges();
                  },
                  onReceivedError: (controller, request, error) {
                    // Mostrar pantalla offline en cualquier error de red.
                    // Ignoramos solo los errores explícitamente de sub-recursos (isForMainFrame == false).
                    // Si isForMainFrame es null (desconocido), también mostramos la pantalla.
                    if (request.isForMainFrame == false) return;
                    if (mounted) {
                      setState(() { _isOffline = true; _isLoading = false; });
                      _pullToRefreshController?.endRefreshing();
                    }
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) {
                    if (url != null) {
                      setState(() { _currentUrl = url.toString(); _selectedTab = _tabFromUrl(url.toString()); });
                    }
                  },
                ),

                // ── PANTALLA SIN INTERNET ──────────────────────────────────
                if (_isOffline)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo.png', width: 90, height: 90),
                            const SizedBox(height: 32),
                            Icon(Icons.wifi_off_rounded,
                              size: 72,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Sin conexión a internet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15418A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Comprueba tu conexión y vuelve a intentarlo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 36),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() { _isOffline = false; _isLoading = true; });
                                _controller?.reload();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Reintentar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3BA1DA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Rueda de carga moderna (solo el círculo, sobre la web)
                if (_isLoading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: _ModernSpinner(),
                      ),
                    ),
                  ),

                // Botón hamburguesa
                if (!_isLoading)
                  Positioned(
                    top: 8, right: 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3BA1DA), Color(0xFF15418A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF15418A).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.menu_rounded, size: 24, color: Colors.white),
                      ),
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

  // Badge rojo reutilizable para el contador
  Widget _countBadge(int count) {
    return Positioned(
      top: -6,
      right: -10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.1),
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
              Stack(
                clipBehavior: Clip.none,
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
                  if (_notifCount > 0) _countBadge(_notifCount),
                ],
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

    // Tab Mensajes con badge
    final bool isMensajes = index == 3;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected ? const Color(0xFF15418A) : Colors.grey,
                ),
                if (isMensajes && _unreadCount > 0) _countBadge(_unreadCount),
                if (index == 4 && _notifCount > 0) _countBadge(_notifCount),
              ],
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

              // Acciones rápidas: Publicar (siempre) + Iniciar sesión (si no logueado)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigatedFromDrawer = true;
                          Navigator.of(context).pop();
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _controller?.evaluateJavascript(source: "if(typeof abrirModalProvincias==='function'){abrirModalProvincias();}else{window.location.href='https://zoomubik.com/?abrir_publicar=1';}");
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Publicar anuncio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15418A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (_lastUserId == 0) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _navigatedFromDrawer = true;
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 300), _triggerLoginModal);
                          },
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Iniciar sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF15418A),
                            side: const BorderSide(color: Color(0xFF15418A), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
              const SizedBox(height: 24),

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
              const SizedBox(height: 8),
              Text(
                '¿Qué quieres ver?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 14),

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
              const SizedBox(height: 28),
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
              const SizedBox(height: 18),

              // Botón Publicar
              _opcionSelectorTipo(
                icon: Icons.add_rounded,
                title: 'Publicar mi anuncio',
                subtitle: cat.label,
                color: const Color(0xFF15418A),
                onTap: () {
                  if (cat.propietarioSlug == null) return;
                  Navigator.pop(sheetContext);
                  if (_lastUserId == 0) {
                    _navigatedFromDrawer = true;
                    Navigator.of(context).pop();
                    Future.delayed(const Duration(milliseconds: 350), _triggerLoginModal);
                    return;
                  }
                  _navegarAPublicarProvincia();
                },
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

// ── Spinner moderno: arco con degradado y cola que se desvanece ──────────────
class _ModernSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  const _ModernSpinner({this.size = 46, this.strokeWidth = 4});

  @override
  State<_ModernSpinner> createState() => _ModernSpinnerState();
}

class _ModernSpinnerState extends State<_ModernSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _c,
        child: CustomPaint(
          painter: _SpinnerPainter(strokeWidth: widget.strokeWidth),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double strokeWidth;
  _SpinnerPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    const gradient = SweepGradient(
      colors: [
        Color(0xFF3BA1DA), // azul claro
        Color(0xFF15418A), // azul oscuro
        Color(0xFF3BA1DA), // azul claro
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Arco de ~300° (deja un hueco que crea el efecto de giro)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.0,
      5.2359877, // ~300 grados en radianes
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) => false;
}
