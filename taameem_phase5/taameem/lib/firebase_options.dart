// Generated manually from android/app/google-services.json
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) return android;
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwsTo00fJ90LVU4c-hAJvMjy1Nry2jeig',
    appId: '1:279973020282:android:d7ff6df5fe89429e0af1c3',
    messagingSenderId: '279973020282',
    projectId: 'taameem-3f949',
    storageBucket: 'taameem-3f949.firebasestorage.app',
  );
}

