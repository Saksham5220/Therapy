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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAHNS83JwkgCAGhNgaZFG7Nc7_4CoabUx0',
    appId: '1:1028235389386:android:affd956f96d01e8a94c733',
    messagingSenderId: '1028235389386',
    projectId: 'therapy-f16ea',
    databaseURL: 'https://therapy-f16ea-default-rtdb.firebaseio.com',
    storageBucket: 'therapy-f16ea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArTuVwFfNAtutXpmC5vnrEJCOP3wEdBuA',
    appId: '1:1028235389386:ios:9c952529aaa3f8c294c733',
    messagingSenderId: '1028235389386',
    projectId: 'therapy-f16ea',
    databaseURL: 'https://therapy-f16ea-default-rtdb.firebaseio.com',
    storageBucket: 'therapy-f16ea.firebasestorage.app',
    iosClientId: '1028235389386-k9jav601t1pku5s1h4fs2oek7cgj1hvj.apps.googleusercontent.com',
    iosBundleId: 'com.sam.therapyai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyARlzjgirNAsWZNEwN1G28d8hLnkQybGIM',
    appId: '1:1028235389386:web:730c3458c32fc51694c733',
    messagingSenderId: '1028235389386',
    projectId: 'therapy-f16ea',
    authDomain: 'therapy-f16ea.firebaseapp.com',
    databaseURL: 'https://therapy-f16ea-default-rtdb.firebaseio.com',
    storageBucket: 'therapy-f16ea.firebasestorage.app',
    measurementId: 'G-042MWVBTPD',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArTuVwFfNAtutXpmC5vnrEJCOP3wEdBuA',
    appId: '1:1028235389386:ios:61505552208b58c294c733',
    messagingSenderId: '1028235389386',
    projectId: 'therapy-f16ea',
    databaseURL: 'https://therapy-f16ea-default-rtdb.firebaseio.com',
    storageBucket: 'therapy-f16ea.firebasestorage.app',
    iosClientId: '1028235389386-uevpev8t7oq428hs1uhgvikp27k6h1om.apps.googleusercontent.com',
    iosBundleId: 'com.example.therapyAi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyARlzjgirNAsWZNEwN1G28d8hLnkQybGIM',
    appId: '1:1028235389386:web:7a58dd5db826410494c733',
    messagingSenderId: '1028235389386',
    projectId: 'therapy-f16ea',
    authDomain: 'therapy-f16ea.firebaseapp.com',
    databaseURL: 'https://therapy-f16ea-default-rtdb.firebaseio.com',
    storageBucket: 'therapy-f16ea.firebasestorage.app',
    measurementId: 'G-8YYBE6F3CP',
  );

}