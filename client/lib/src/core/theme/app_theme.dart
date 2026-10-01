import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF); // Main purple color
  static const Color accentColor = Color(0xFF00D9F5); // Cyan accent
  static const Color backgroundColor = Color(0xFF161630);
  static const Color surfaceColor = Color(0xFF1A1A3A);
  static const Color cardColor = Color(0xFF222268);

  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Colors.white70;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      modalBackgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      titleTextStyle: const TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 16,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: cardColor,
      headerForegroundColor: textPrimaryColor,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return textSecondaryColor;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return primaryColor;
      }),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return textSecondaryColor;
      }),
      weekdayStyle: const TextStyle(color: textSecondaryColor),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return primaryColor.withValues(alpha: 0.2);
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: surfaceColor,
      hourMinuteTextColor: textPrimaryColor,
      dialHandColor: primaryColor,
      dialBackgroundColor: cardColor,
      dialTextColor: textPrimaryColor,
      entryModeIconColor: textSecondaryColor,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: textSecondaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return textSecondaryColor;
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cardColor,
        foregroundColor: textPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textSecondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimaryColor,
        side: BorderSide(color: textSecondaryColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      labelStyle: const TextStyle(color: textSecondaryColor),
      hintStyle: const TextStyle(color: textSecondaryColor),
      prefixIconColor: textSecondaryColor,
      suffixIconColor: textSecondaryColor,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textPrimaryColor),
      headlineMedium: TextStyle(color: textPrimaryColor),
      headlineSmall: TextStyle(color: textPrimaryColor),
      titleLarge: TextStyle(color: textPrimaryColor),
      titleMedium: TextStyle(color: textPrimaryColor),
      titleSmall: TextStyle(color: textPrimaryColor),
      bodyLarge: TextStyle(color: textPrimaryColor),
      bodyMedium: TextStyle(color: textPrimaryColor),
      bodySmall: TextStyle(color: textSecondaryColor),
    ),
    iconTheme: const IconThemeData(
      color: textSecondaryColor,
    ),
    dividerTheme: DividerThemeData(
      color: textSecondaryColor.withValues(alpha: 0.1),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardColor,
      contentTextStyle: const TextStyle(color: textPrimaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
