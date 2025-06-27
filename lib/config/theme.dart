import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preferences_provider.dart';

// Theme provider
final themeProvider = Provider<ThemeData>((ref) {
  final isDarkMode = ref.watch(isDarkModeProvider);
  return isDarkMode ? darkTheme : lightTheme;
});

// Light theme
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
  fontFamily: 'Poppins',
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black87,
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.black87,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(width: 2, color: Colors.deepPurple),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: Colors.white,
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
  dividerTheme: const DividerThemeData(
    space: 24,
    thickness: 1,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    elevation: 8,
    selectedItemColor: Colors.deepPurple,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),
  scaffoldBackgroundColor: Colors.grey[100],
);

// Dark theme
final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ),
  fontFamily: 'Poppins',
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(width: 2, color: Colors.deepPurpleAccent),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: Colors.grey[900],
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),
  chipTheme: ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  ),
  dividerTheme: const DividerThemeData(
    space: 24,
    thickness: 1,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    elevation: 8,
    selectedItemColor: Colors.deepPurpleAccent,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),
  scaffoldBackgroundColor: Colors.grey[900],
);

// Task priority colors
class TaskColors {
  static const Color highPriority = Color(0xFFE57373);
  static const Color mediumPriority = Color(0xFFFFB74D);
  static const Color lowPriority = Color(0xFF81C784);
  
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 0: // Low
        return lowPriority;
      case 1: // Medium
        return mediumPriority;
      case 2: // High
        return highPriority;
      default:
        return mediumPriority;
    }
  }
}

// Animation durations
class AnimationDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
}

// App spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
} 