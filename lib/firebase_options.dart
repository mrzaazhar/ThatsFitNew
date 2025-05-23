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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAi8jo85WeVuYzEQ3lrD8SuG7XHFFP2Wfs',
    appId: '1:1022696522166:web:b701a0274a32d3e628c117',
    messagingSenderId: '1022696522166',
    projectId: 'testdua-ea416',
    authDomain: 'testdua-ea416.firebaseapp.com',
    storageBucket: 'testdua-ea416.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKxwTbtRMWLv9QwJJbiV1EaK8FsY3_m-8',
    appId: '1:1022696522166:android:b0374667c2ad549128c117',
    messagingSenderId: '1022696522166',
    projectId: 'testdua-ea416',
    storageBucket: 'testdua-ea416.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAi8jo85WeVuYzEQ3lrD8SuG7XHFFP2Wfs',
    appId: '1:1022696522166:web:1fe730967fb96b3028c117',
    messagingSenderId: '1022696522166',
    projectId: 'testdua-ea416',
    authDomain: 'testdua-ea416.firebaseapp.com',
    storageBucket: 'testdua-ea416.firebasestorage.app',
  );
}
