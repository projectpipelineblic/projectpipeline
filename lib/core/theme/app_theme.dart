import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';

class AppTheme {
  static OutlineInputBorder _border([Color color = AppPallete.borderGray]) => OutlineInputBorder(
    borderSide: BorderSide(color: color),
    borderRadius: BorderRadius.circular(12),
  );

  static final lightModeTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppPallete.white,
    primaryColor: AppPallete.primary,
    colorScheme: const ColorScheme.light(
      primary: AppPallete.primary,
      secondary: AppPallete.secondary,
      surface: AppPallete.white,
      background: AppPallete.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.primary,
      foregroundColor: AppPallete.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppPallete.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppPallete.secondary,
      iconColor: AppPallete.secondary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppPallete.borderGray,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPallete.lightGray,
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(AppPallete.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: AppPallete.textGray),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPallete.primary,
        foregroundColor: AppPallete.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPallete.primary,
      ),
    ),
    dialogBackgroundColor: AppPallete.white,
  );

  static final darkModeTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: AppPallete.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppPallete.primary,
      secondary: AppPallete.white,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.primary,
      foregroundColor: AppPallete.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Color(0xFFE5E7EB),
      iconColor: Color(0xFFE5E7EB),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF404040),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: AppPallete.primary,
      unselectedItemColor: Color(0xFF9CA3AF),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: _border(const Color(0xFF404040)),
      enabledBorder: _border(const Color(0xFF404040)),
      focusedBorder: _border(AppPallete.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPallete.primary,
        foregroundColor: AppPallete.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPallete.primary,
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFE5E7EB),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
      bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
      titleLarge: TextStyle(color: Color(0xFFE5E7EB)),
      titleMedium: TextStyle(color: Color(0xFFE5E7EB)),
      titleSmall: TextStyle(color: Color(0xFFE5E7EB)),
    ),
    dialogBackgroundColor: const Color(0xFF1E1E1E),
  );
}
