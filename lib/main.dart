import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/home_screen.dart';
import 'state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // SQLite in the browser (Chrome) needs the web database factory
  if (kIsWeb) databaseFactory = databaseFactoryFfiWebNoWebWorker;
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const SeasideApp(),
    ),
  );
}

class SeasideApp extends StatelessWidget {
  const SeasideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'Seaside Tasks',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
