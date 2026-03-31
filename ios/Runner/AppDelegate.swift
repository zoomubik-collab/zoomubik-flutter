import Flutter
import UIKit
import CoreLocation
import WebKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {

  var locationManager: CLLocationManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1. Firebase — debe ser lo primero
    FirebaseApp.configure()

    // 2. Notificaciones foreground
    UNUserNotificationCenter.current().delegate = self

    // 3. Cookies persistentes
    HTTPCookieStorage.shared.cookieAcceptPolicy = .always

    // 4. WKWebsiteDataStore persistente
    let dataStore = WKWebsiteDataStore.default()
    let config = WKWebViewConfiguration()
    config.websiteDataStore = dataStore
    config.allowsInlineMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []
    let cookies = HTTPCookieStorage.shared.cookies ?? []
    for cookie in cookies {
      dataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
    }

    // 5. Localización
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.requestWhenInUseAuthorization()

    // 6. Registrar plugins Flutter
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // APNs → FCM
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Mostrar notificación con la app en foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // Tap en notificación
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
