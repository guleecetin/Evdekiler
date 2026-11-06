import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const basil = Color(0xFF3A7D44);
  static const basilDark = Color(0xFF2A5E33);
  static const tomato = Color(0xFFE76F51);
  static const cream = Color(0xFFFAF7F2);
  static const ink = Color(0xFF1F2A22);
}

ThemeData buildLightTheme() {
  // google_fonts'tan sadece yazı tipinin adını alıyoruz (paketler arası tip çakışmasını önler)
  final font = GoogleFonts.plusJakartaSans().fontFamily;
  // Kullandığımız kalınlıkları da yükle, yoksa kalın yazılar ince görünür
  for (final weight in [
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]) {
    GoogleFonts.plusJakartaSans(fontWeight: weight);
  }

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.basil,
    primary: AppColors.basil,
    tertiary: AppColors.tomato,
    surface: AppColors.cream,
  );
  final rounded = BorderRadius.circular(16);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: font,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: rounded),
        textStyle: TextStyle(
          fontFamily: font,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: font, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
