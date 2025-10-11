import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseInitializer {
  static bool _initialized = false;
  static bool get initialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      if (kIsWeb) {
        final options = DefaultFirebaseOptions.currentPlatform;
        if (_hasValidOptions(options)) {
          await Firebase.initializeApp(options: options);
          _initialized = true;
        }
      } else {
        // Prefer native resource-based initialization on mobile/desktop.
        await Firebase.initializeApp();
        _initialized = true;
      }
    } catch (_) {
      // Fallback: try code-based options if native init failed on non-web
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        if (_hasValidOptions(options)) {
          await Firebase.initializeApp(options: options);
          _initialized = true;
        }
      } catch (_) {
        // Skip initialization if options are invalid or Firebase not configured yet
      }
    }
  }

  // Options provided via DefaultFirebaseOptions

  static bool _hasValidOptions(FirebaseOptions options) {
    return options.apiKey.isNotEmpty &&
        options.appId.isNotEmpty &&
        options.projectId.isNotEmpty &&
        options.messagingSenderId.isNotEmpty;
  }
}