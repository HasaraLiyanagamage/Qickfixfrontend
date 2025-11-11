import 'package:flutter/material.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentRed = Color(0xFFF44336);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Service Colors
  static const Color plumbing = Color(0xFF2196F3);
  static const Color electrical = Color(0xFFFFC107);
  static const Color carpentry = Color(0xFF795548);
  static const Color painting = Color(0xFF9C27B0);
  static const Color acRepair = Color(0xFF00BCD4);
  static const Color cleaning = Color(0xFF4CAF50);
  
  // Neutral Colors - Light Theme
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFE0E0E0);
  
  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkDivider = Color(0xFF3A3A3A);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadows
  static List<BoxShadow> cardShadow(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (color ?? (isDark ? Colors.black : Colors.grey))
            .withValues(alpha: isDark ? 0.3 : 0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  static List<BoxShadow> elevatedShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentOrange,
      surface: lightSurface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightText,
      onError: Colors.white,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightText),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightText),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightText),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightText),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightText),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightText),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: lightText),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: lightText),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: lightTextSecondary),
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentOrange,
      surface: darkSurface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkText,
      onError: Colors.white,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkText),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: darkText),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: darkText),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: darkTextSecondary),
    ),
  );
  
  // Helper Methods
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : lightTextSecondary;
  }
}
