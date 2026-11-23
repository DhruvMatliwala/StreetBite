import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration options for the `streetbite-c4058` project.
///
/// Supply the Android API key at build time via:
/// `--dart-define=FIREBASE_API_KEY=your_key`
class DefaultFirebaseOptions {
  static const String _androidApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');

  static bool get isConfigured => _androidApiKey.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: '1:794338384277:android:48f180a3226a4270117e9c',
    messagingSenderId: '794338384277',
    projectId: 'streetbite-c4058',
    storageBucket: 'streetbite-c4058.firebasestorage.app',
  );
}
