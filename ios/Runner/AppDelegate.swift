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
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurar cookies y sesión para WebView
    let cookieStorage = HTTPCookieStorage.shared
    cookieStorage.cookieAcceptPolicy = .always
    
    // Configurar WKWebsiteDataStore para persistencia
    if #available(iOS 11.0, *) {
      let dataStore = WKWebsiteDataStore.default()
      dataStore.httpShouldSetCookies = true
      dataStore.httpCookieAcceptPolicy = .always
      dataStore.httpShouldUseCookies = true
    }
    
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestWhenInUseAuthorization()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
