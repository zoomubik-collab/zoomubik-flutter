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
    apiKey: 'AIzaSyBuLEtOYr4afoPh8U9t9_My4kx3HrKG-nw',
    appId: '1:257703384863:android:b7f5deacfaa4e9f8f7822a',
    messagingSenderId: '257703384863',
    projectId: 'zoomubik-37561',
    storageBucket: 'zoomubik-37561.firebasestorage.app',
  );
}
