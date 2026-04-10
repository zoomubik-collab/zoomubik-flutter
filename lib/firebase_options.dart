import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJ_fqr5QJi8QOGAhnRaIEK0SoE15TjHts',
    appId: '1:733963653129:ios:7895ec5098bb6c7eb068d8',
    messagingSenderId: '733963653129',
    projectId: 'ios-app-42b04',
    storageBucket: 'ios-app-42b04.firebasestorage.app',
    iosBundleId: 'com.zoomubik.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgrn-56m-lGRbx8Rzg3WuMVJKy5sds3Aw',
    appId: '1:733963653129:android:f7e204a5afb1bb97b068d8',
    messagingSenderId: '733963653129',
    projectId: 'ios-app-42b04',
    storageBucket: 'ios-app-42b04.firebasestorage.app',
  );
}
