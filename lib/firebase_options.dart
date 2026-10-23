import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('This platform is not set up for Firebase yet.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4HPq0fakEJp7OJqxZwQdIKaBwvAy_ax0',
    appId: '1:344758339126:web:9152f259938ec165b37a97',
    messagingSenderId: '344758339126',
    projectId: 'careercompass-ff981',
    authDomain: 'careercompass-ff981.firebaseapp.com',
    storageBucket: 'careercompass-ff981.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3Q4KiN5YD3m5Zx4nyc25JFnq_xhXTAyE',
    appId: '1:344758339126:android:fe9d28620bee10a5b37a97',
    messagingSenderId: '344758339126',
    projectId: 'careercompass-ff981',
    storageBucket: 'careercompass-ff981.firebasestorage.app',
  );
}