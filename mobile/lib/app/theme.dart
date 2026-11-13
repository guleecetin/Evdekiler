import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const basil = Color(0xFF3A7D44);
  static const basilDark = Color(0xFF2A5E33);
  static const tomato = Color(0xFFE76F51);
  static const cream = Color(0xFFFAF7F2);
  static const ink = Color(0xFF222222);
  static const muted = Color(0xFF717171);
  static const line = Color(0xFFEBEBEB);
}

ThemeData buildLightTheme() {
  final font = GoogleFonts.plusJakartaSans().fontFamily;
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
    surface: Colors.white,
  );
  final rounded = BorderRadius.circular(14);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: font,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: rounded),
      enabledBorder: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: rounded,
        borderSide: const BorderSide(color: AppColors.ink, width: 2),
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
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.basil
              : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: font,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.basil
              : AppColors.muted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
