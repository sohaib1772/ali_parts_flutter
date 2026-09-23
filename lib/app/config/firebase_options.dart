import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXVbYjp0QOCz3iHGTgyYIXUD0WUKQTLC4',
    appId: '1:794940821827:android:ac35a0449a0905b2309ff6',
    messagingSenderId: '794940821827',
    projectId: 'maktab-ali',
    storageBucket: 'maktab-ali.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBKAavddICiGCokyjPsBs1RDgvPVW-Zi3Q',
    appId: '1:794940821827:ios:4c96fefb8acfa2e3309ff6',
    messagingSenderId: '794940821827',
    projectId: 'maktab-ali',
    storageBucket: 'maktab-ali.firebasestorage.app',
    iosBundleId: 'com.mkteb.ali.chevrolet',
  );
}
