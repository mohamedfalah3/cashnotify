// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDO8ceWLzbsPvY0x312P3gHN737MDJtI2c',
    appId: '1:522042836464:web:e219d1d14cbe753c100935',
    messagingSenderId: '522042836464',
    projectId: 'cashnotification-8ff9d',
    authDomain: 'cashnotification-8ff9d.firebaseapp.com',
    storageBucket: 'cashnotification-8ff9d.firebasestorage.app',
    measurementId: 'G-1ZXG6XCFNB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZjKuqOXqwRokghrMCA3ptJraXAYn_Zas',
    appId: '1:522042836464:android:1d9ab701668b04fc100935',
    messagingSenderId: '522042836464',
    projectId: 'cashnotification-8ff9d',
    storageBucket: 'cashnotification-8ff9d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCQFLJYzzUxpywi_voSJnVrefZRnM1HXjk',
    appId: '1:522042836464:ios:9e72212e8fa651ab100935',
    messagingSenderId: '522042836464',
    projectId: 'cashnotification-8ff9d',
    storageBucket: 'cashnotification-8ff9d.firebasestorage.app',
    iosBundleId: 'com.example.cashnotify',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCQFLJYzzUxpywi_voSJnVrefZRnM1HXjk',
    appId: '1:522042836464:ios:9e72212e8fa651ab100935',
    messagingSenderId: '522042836464',
    projectId: 'cashnotification-8ff9d',
    storageBucket: 'cashnotification-8ff9d.firebasestorage.app',
    iosBundleId: 'com.example.cashnotify',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDO8ceWLzbsPvY0x312P3gHN737MDJtI2c',
    appId: '1:522042836464:web:c17bd49ff8828f25100935',
    messagingSenderId: '522042836464',
    projectId: 'cashnotification-8ff9d',
    authDomain: 'cashnotification-8ff9d.firebaseapp.com',
    storageBucket: 'cashnotification-8ff9d.firebasestorage.app',
    measurementId: 'G-7RVP7081B7',
  );
}
