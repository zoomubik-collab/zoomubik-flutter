import Flutter
import UIKit
import CoreLocation
import WebKit
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  var locationManager: CLLocationManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ✅ Firebase — debe ser lo primero
    FirebaseApp.configure()

    // ✅ Cookies persistentes
    HTTPCookieStorage.shared.cookieAcceptPolicy = .always

    // ✅ WKWebsiteDataStore persistente
    if #available(iOS 11.0, *) {
      let dataStore = WKWebsiteDataStore.default()
      let config = WKWebViewConfiguration()
      config.websiteDataStore = dataStore
      config.allowsInlineMediaPlayback = true
      config.mediaTypesRequiringUserActionForPlayback = []
      let cookies = HTTPCookieStorage.shared.cookies ?? []
      for cookie in cookies {
        dataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
      }
    }

    // ✅ Localización
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestWhenInUseAuthorization()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ APNs — necesario para FCM en iOS
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
