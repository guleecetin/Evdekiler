import 'package:flutter/material.dart';

class AppColors {
  static const basil = Color(0xFF3A7D44); // fesleğen yeşili
  static const tomato = Color(0xFFE76F51); // domates
  static const cream = Color(0xFFFAF7F2); // krem arka plan
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.basil,
    tertiary: AppColors.tomato,
    surface: AppColors.cream,
  );

  final roundedBorder = BorderRadius.circular(16);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,

    // Giriş kutuları
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: roundedBorder,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: roundedBorder,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: roundedBorder,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),

    // Ana butonlar
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: roundedBorder),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
