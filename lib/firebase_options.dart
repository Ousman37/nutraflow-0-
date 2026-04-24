// ⚠️  FIREBASE SETUP REQUIRED
//
// Run the following command to generate real Firebase options:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Then replace this file with the generated firebase_options.dart.
// Until then, the app will throw a FirebaseException on startup.
//
// See: https://firebase.google.com/docs/flutter/setup

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── Replace each value below with your real Firebase project credentials ───

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDs1CPvtL3j5l4prb_9rTGwjFkJ4FE-tWk',
    appId: '1:157447885473:android:da84d82e5ac91d080856e0',
    messagingSenderId: '157447885473',
    projectId: 'nutraflow-199ae',
    storageBucket: 'nutraflow-199ae.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCl6svTYVW_IAG96G4vJc2SpGKSs4TvVDU',
    appId: '1:157447885473:ios:baf03c7ccfd910d70856e0',
    messagingSenderId: '157447885473',
    projectId: 'nutraflow-199ae',
    storageBucket: 'nutraflow-199ae.firebasestorage.app',
    iosClientId: '157447885473-mjtfmkfmri9nebaoh2d2nqifcs8tpg4f.apps.googleusercontent.com',
    iosBundleId: 'com.example.nutraflow',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.nutraflow',
  );
}