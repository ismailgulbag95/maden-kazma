import 'package:flutter/material.dart';

abstract final class MinePalette {
  static const ink = Color(0xFF071B23);
  static const panel = Color(0xFF0C2632);
  static const panelRaised = Color(0xFF123543);
  static const rock = Color(0xFF3A3534);
  static const copper = Color(0xFFB86632);
  static const amber = Color(0xFFF0A52E);
  static const cream = Color(0xFFF4E8CC);
  static const muted = Color(0xFFA6B3B3);
  static const teal = Color(0xFF21C4B6);
  static const cyan = Color(0xFF42D7E5);
  static const violet = Color(0xFFAE62E8);
  static const danger = Color(0xFFE8755B);
  static const border = Color(0xFF42606A);

  static ThemeData get theme {
    final scheme = const ColorScheme.dark(
      primary: amber,
      onPrimary: ink,
      secondary: teal,
      onSecondary: ink,
      surface: panel,
      onSurface: cream,
      error: danger,
      onError: ink,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      cardColor: panel,
      dividerColor: border,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: cream,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
        titleLarge: TextStyle(color: cream, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: cream, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: cream, height: 1.3),
        bodyMedium: TextStyle(color: cream, height: 1.3),
        bodySmall: TextStyle(color: muted, height: 1.25),
        labelLarge: TextStyle(color: cream, fontWeight: FontWeight.w800),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ink,
          backgroundColor: amber,
          disabledForegroundColor: muted,
          disabledBackgroundColor: panelRaised,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: cream,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
