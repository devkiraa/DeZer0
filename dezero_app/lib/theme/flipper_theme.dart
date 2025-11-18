import 'package:flutter/material.dart';

/// Flipper Zero inspired color scheme
class FlipperColors {
  // Primary Orange (Flipper's signature color)
  static const Color primary = Color(0xFFFF8C00);
  static const Color primaryDark = Color(0xFFFF6600);
  static const Color primaryLight = Color(0xFFFFAA33);
  
  // Background colors (Dark mode)
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFF8C00);
  static const Color textSecondary = Color(0xFFFFFFFF);
  static const Color textTertiary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF666666);
  
  // Status colors
  static const Color success = Color(0xFF00FF00);
  static const Color error = Color(0xFFFF0000);
  static const Color warning = Color(0xFFFFFF00);
  static const Color info = Color(0xFF00FFFF);
  
  // UI elements
  static const Color border = Color(0xFF333333);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color shadow = Color(0x40000000);
  
  // Grid/Matrix style
  static const Color gridDot = Color(0xFF333333);
  static const Color gridLine = Color(0xFF1A1A1A);
}

/// Flipper Zero inspired theme
class FlipperTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: FlipperColors.primary,
        secondary: FlipperColors.primaryLight,
        surface: FlipperColors.surface,
        error: FlipperColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: FlipperColors.textSecondary,
        onError: Colors.black,
      ),
      
      scaffoldBackgroundColor: FlipperColors.background,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: FlipperColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: FlipperColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
        iconTheme: IconThemeData(color: FlipperColors.primary),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FlipperColors.surface,
        selectedItemColor: FlipperColors.primary,
        unselectedItemColor: FlipperColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: FlipperColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: FlipperColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FlipperColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FlipperColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FlipperColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FlipperColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(
          color: FlipperColors.textTertiary,
          fontFamily: 'monospace',
        ),
        hintStyle: const TextStyle(
          color: FlipperColors.textDisabled,
          fontFamily: 'monospace',
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FlipperColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
      
      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FlipperColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FlipperColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
      
      // List Tile
      listTileTheme: const ListTileThemeData(
        tileColor: FlipperColors.surface,
        textColor: FlipperColors.textSecondary,
        iconColor: FlipperColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: FlipperColors.divider,
        thickness: 1,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: FlipperColors.primary,
        size: 24,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: FlipperColors.primary,
          fontFamily: 'monospace',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: FlipperColors.primary,
          fontFamily: 'monospace',
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: FlipperColors.primary,
          fontFamily: 'monospace',
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textPrimary,
          fontFamily: 'monospace',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FlipperColors.textTertiary,
          fontFamily: 'monospace',
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: FlipperColors.textTertiary,
          fontFamily: 'monospace',
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FlipperColors.textTertiary,
          fontFamily: 'monospace',
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: FlipperColors.textDisabled,
          fontFamily: 'monospace',
        ),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FlipperColors.primary,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FlipperColors.surface,
        contentTextStyle: const TextStyle(
          color: FlipperColors.textSecondary,
          fontFamily: 'monospace',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: FlipperColors.primary, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Flipper-style decorations and widgets
class FlipperDecorations {
  /// Creates a bordered container with Flipper style
  static BoxDecoration container({
    Color? color,
    bool highlighted = false,
  }) {
    return BoxDecoration(
      color: color ?? FlipperColors.surface,
      border: Border.all(
        color: highlighted ? FlipperColors.primary : FlipperColors.border,
        width: highlighted ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  /// Creates a glowing effect for active elements
  static BoxDecoration glowingBorder() {
    return BoxDecoration(
      border: Border.all(color: FlipperColors.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: FlipperColors.primary.withOpacity(0.5),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }
  
  /// Monospace text style
  static const TextStyle monoText = TextStyle(
    fontFamily: 'monospace',
    color: FlipperColors.textSecondary,
  );
  
  /// Orange monospace text style
  static const TextStyle monoTextOrange = TextStyle(
    fontFamily: 'monospace',
    color: FlipperColors.primary,
    fontWeight: FontWeight.bold,
  );
}
