import 'package:flutter/material.dart';

final _theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6B46C1), // Custom purple
    primary: const Color(0xFF6B46C1),
    secondary: const Color(0xFF26A69A), // Teal accent
    surface: Colors.white,
    background: const Color(0xFFF5F7FA), // Light gray background
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Color(0xFF333333)),
    bodyMedium: const TextStyle(color: Color(0xFF333333)),
    titleLarge: const TextStyle(color: Color(0xFF333333)),
    titleMedium: const TextStyle(color: Color(0xFF333333)),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Color(0xFF6B46C1),
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black26,
  ),
  cardTheme: CardTheme(
    elevation: 6,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF6B46C1),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

ThemeData get theme => _theme;
