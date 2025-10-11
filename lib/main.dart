import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'core/firebase/firebase_initializer.dart';
// Auth removed: start directly on main screen

Future<void> main() async {
  // Initialize database factory for web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.init();
  
  runApp(
    const ProviderScope(
      child: BajetimorApp(),
    ),
  );
}

class BajetimorApp extends ConsumerWidget {
  const BajetimorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Auth removed; no gating

    return MaterialApp(
      title: 'Baj3tim)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
