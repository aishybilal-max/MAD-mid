import 'package:flutter/material.dart';

/// Palette from the swan-lake reference.
class C {
  static const deepGreen = Color(0xFF4F6656);
  static const seaGreen = Color(0xFF73AFA3);
  static const leaf = Color(0xFF538666);
  static const sky = Color(0xFF7BBFD8);
  static const ocean = Color(0xFF298DB5);
  static const navy = Color(0xFF1A3E6C);
  static const night = Color(0xFF0B1B30);
}

TextStyle celestial(double size, {Color? color, bool bold = false, double spacing = 1}) =>
    TextStyle(
      fontFamily: 'Celestial',
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      letterSpacing: spacing,
    );

Color categoryColor(String c) {
  switch (c) {
    case 'Academic':
      return C.ocean;
    case 'Work':
      return C.navy;
    case 'Health':
      return C.leaf;
    case 'Errands':
      return C.seaGreen;
    default:
      return C.sky;
  }
}

IconData categoryIcon(String c) {
  switch (c) {
    case 'Academic':
      return Icons.school_rounded;
    case 'Work':
      return Icons.work_rounded;
    case 'Health':
      return Icons.favorite_rounded;
    case 'Errands':
      return Icons.shopping_bag_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme(
    brightness: b,
    primary: dark ? C.sky : C.ocean,
    onPrimary: dark ? C.night : Colors.white,
    secondary: C.seaGreen,
    onSecondary: dark ? C.night : Colors.white,
    error: const Color(0xFFD9627A),
    onError: Colors.white,
    surface: dark ? const Color(0xFF12294A) : Colors.white,
    onSurface: dark ? const Color(0xFFE6F3F8) : C.navy,
  );
  final base = ThemeData(brightness: b, colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? C.night : const Color(0xFFEAF4F8),
    textTheme: base.textTheme.apply(
      fontFamily: 'Quicksand',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.75),
      labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? C.navy : C.deepGreen,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Quicksand'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
