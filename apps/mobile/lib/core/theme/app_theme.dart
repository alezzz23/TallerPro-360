import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF005F73);
  static const Color secondary = Color(0xFF0A9396);
  static const Color accent = Color(0xFFEE9B00);

  // Semantic order status colors
  static const Color statusPending = Color(0xFF005F73);     // RECEPCION
  static const Color statusInProgress = Color(0xFFEE9B00);  // DIAGNOSTICO, REPARACION, QC
  static const Color statusReady = Color(0xFF2DC653);        // ENTREGA, CERRADA
  static const Color statusRejected = Color(0xFFAE2012);     // RECHAZADA
  static const Color statusApproval = Color(0xFFD98E04);     // APROBACION

  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF212529);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF2F5F7),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  /// Returns the semantic color for a given order status string.
  static Color statusColor(String status) => switch (status) {
    'RECEPCION' => AppColors.statusPending,
    'DIAGNOSTICO' || 'REPARACION' || 'QC' => AppColors.statusInProgress,
    'APROBACION' => AppColors.statusApproval,
    'ENTREGA' || 'CERRADA' => AppColors.statusReady,
    _ => Colors.grey,
  };
}
