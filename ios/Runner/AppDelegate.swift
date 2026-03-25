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
    
    // Configurar cookies para persistencia
    let cookieStorage = HTTPCookieStorage.shared
    cookieStorage.cookieAcceptPolicy = .always
    
    // Configurar WKWebsiteDataStore para persistencia de cookies
    if #available(iOS 11.0, *) {
      let dataStore = WKWebsiteDataStore.default()
      // Las cookies se guardan automáticamente en el dataStore por defecto
      // No necesitamos configurar propiedades adicionales
    }
    
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestWhenInUseAuthorization()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
