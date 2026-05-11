import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core black & white base
  static const Color pureBlack = Color(0xFF000000);
  static const Color deepBlack = Color(0xFF080808);
  static const Color carbonBlack = Color(0xFF0E0E0E);

  // Smoky grayscale (pure black & white)
  static const Color carbonGrayDark = Color(0xFF141414);
  static const Color carbonGray = Color(0xFF1A1A1A);
  static const Color carbonGrayLight = Color(0xFF222222);
  static const Color carbonGrayLighter = Color(0xFF2A2A2A);
  static const Color mediumGray = Color(0xFF1E1E1E);
  static const Color darkGray = Color(0xFF121212);

  // Grayscale accent (black & white theme)
  static const Color blueDark = Color(0xFF1A1A1A);
  static const Color bluePrimary = Color(0xFF525252);
  static const Color blueLight = Color(0xFF737373);
  static const Color blueBright = Color(0xFFE5E5E5);
  static const Color blueAccent = Color(0xFFA3A3A3);

  // Purple-blue gradient for buttons & accents (AQIA brand)
  static const Color purplePrimary = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF6D28D9);
  static const Color bluePink = Color(0xFFEC4899);
  static const Color gradientBlue = Color(0xFF3B82F6);
  static const Color primaryAccent = blueAccent;
  static const Color secondaryAccent = blueBright;
  static const Color primaryBlue = bluePrimary; // Alias for compatibility
  static const Color highlightGray = Color(0xFFE5E5E5);

  // Text colors
  static const Color whiteText = Color(0xFFFDFDFD);
  static const Color grayText = Color(0xFFA3A3A3);
  static const Color lightGrayText = Color(0xFFD4D4D4);

  // Background
  static const Color blackBackground = deepBlack;
  static const Color cardWhite = Color(0xFF111111);

  // Glassmorphism (black & white)
  static Color glassColor = Colors.white.withValues(alpha: 0.06);
  static Color glassBorder = Colors.white.withValues(alpha: 0.25);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.12);
  
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.poppinsTextTheme().apply(
      bodyColor: whiteText,
      displayColor: whiteText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: bluePrimary,
      scaffoldBackgroundColor: blackBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: bluePrimary,
        brightness: Brightness.dark,
        primary: bluePrimary,
        secondary: blueBright,
        background: blackBackground,
        surface: carbonGrayDark,
      ).copyWith(
        onPrimary: whiteText,
        onSecondary: pureBlack,
        onSurface: whiteText,
        onBackground: whiteText,
        tertiary: blueAccent,
        onTertiary: pureBlack,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: textTheme.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
        displaySmall: textTheme.displaySmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: textTheme.bodySmall?.copyWith(fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: carbonBlack,
        foregroundColor: whiteText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: whiteText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
          iconTheme: IconThemeData(
            color: whiteText,
          ),
        ),

        cardTheme: CardThemeData(
        color: cardWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: glassBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bluePrimary,
          foregroundColor: whiteText,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return bluePrimary.withValues(alpha: 0.3);
            }
            return bluePrimary;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bluePrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: whiteText),
        hintStyle: TextStyle(color: whiteText.withValues(alpha: 0.6)),
      ),
    );
  }
  
  // Glassmorphism decoration with gradient
  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    Color? color,
    bool useGradient = true,
  }) {
    if (useGradient) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? glassColor,
            glassHighlight,
            color ?? glassColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glassBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: color ?? glassColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glassBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
  
  // Elegant gradient decorations
  static BoxDecoration gradientDecoration({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<Color>? customColors,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: customColors ?? [
          carbonGrayDark,
          carbonBlack,
          blackBackground,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Button gradient decoration (purple to blue/pink)
  static BoxDecoration buttonGradientDecoration({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: [
          purplePrimary,
          gradientBlue,
          bluePink,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: purplePrimary.withValues(alpha: 0.4),
          blurRadius: 15,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // Subtle gradient for cards
  static BoxDecoration cardGradientDecoration({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: [
          carbonGray.withValues(alpha: 0.6),
          carbonGrayDark.withValues(alpha: 0.4),
          carbonBlack.withValues(alpha: 0.3),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: glassBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Animated shimmer effect decoration
  static BoxDecoration shimmerDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          carbonGrayDark,
          carbonGray,
          carbonGrayDark,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(16),
    );
  }
}

