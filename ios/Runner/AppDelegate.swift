import Flutter
import UIKit
import CoreLocation
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  var locationManager: CLLocationManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ 1. Configurar WKWebView globalmente
    if #available(iOS 11.0, *) {
      let config = WKWebViewConfiguration()
      
      // Usar dataStore persistente (no ephemeral)
      config.websiteDataStore = WKWebsiteDataStore.default()
      
      // Permitir multimedia
      config.allowsInlineMediaPlayback = true
      config.mediaTypesRequiringUserActionForPlayback = []
      
      // Habilitar almacenamiento
      config.preferences.javaScriptEnabled = true
      config.preferences.javaScriptCanOpenWindowsAutomatically = true
      
      // Cookies
      config.httpShouldUseCookies = true
      config.httpCookieAcceptPolicy = .always
      config.httpMaximumConnectionsPerHost = 10
      
      // Sincronizar cookies del sistema con WebView
      if let cookies = HTTPCookieStorage.shared.cookies {
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        config.httpShouldUseCookies = true
      }
    }

    // ✅ 2. Cookies persistentes a nivel de sistema
    HTTPCookieStorage.shared.cookieAcceptPolicy = .always

    // ✅ 3. Localización
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestWhenInUseAuthorization()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
