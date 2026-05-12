import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AQIA app theme — matches the website's clean SaaS design language.
/// White/light base, blue accent (#2563EB), neutral grays.
class AppTheme {
  // ── Brand accent ──────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFF2563EB); // blue-600
  static const Color accentHover   = Color(0xFF1D4ED8); // blue-700
  static const Color accentLight   = Color(0xFFEFF6FF); // blue-50
  static const Color accentBorder  = Color(0xFFBFDBFE); // blue-200

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF16A34A);
  static const Color successLight  = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color danger        = Color(0xFFDC2626);
  static const Color dangerLight   = Color(0xFFFEF2F2);
  static const Color dangerBorder  = Color(0xFFFECACA);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color warningLight  = Color(0xFFFFFBEB);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color pageBg        = Color(0xFFF8FAFC); // slate-50
  static const Color surface       = Color(0xFFFFFFFF); // white
  static const Color surfaceHover  = Color(0xFFF1F5F9); // slate-100

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border        = Color(0xFFE2E8F0); // slate-200
  static const Color borderFocus   = Color(0xFF93C5FD); // blue-300

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted     = Color(0xFF94A3B8); // slate-400

  // ── Legacy aliases (used in widgets that haven't been updated yet) ────────
  static const Color purplePrimary   = accent;
  static const Color purpleDark      = accentHover;
  static const Color gradientBlue    = accent;
  static const Color bluePink        = Color(0xFFEC4899);
  static const Color blueAccent      = Color(0xFF64748B);
  static const Color whiteText       = textPrimary;
  static const Color grayText        = textMuted;
  static const Color lightGrayText   = textSecondary;
  static const Color blackBackground = pageBg;
  static const Color carbonBlack     = surface;
  static const Color carbonGrayDark  = Color(0xFFF8FAFC);
  static const Color carbonGray      = Color(0xFFF1F5F9);
  static const Color carbonGrayLight = Color(0xFFE2E8F0);
  static Color glassBorder           = border;
  static Color glassColor            = surface;
  static Color glassHighlight        = accentLight;

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accent,
      scaffoldBackgroundColor: pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: accentLight,
        surface: surface,
      ).copyWith(
        onPrimary: Colors.white,
        onSurface: textPrimary,
        error: danger,
      ),
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: base.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall:  base.displaySmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium:base.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge:    base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium:   base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge:     base.bodyLarge?.copyWith(fontSize: 16, color: textPrimary),
        bodyMedium:    base.bodyMedium?.copyWith(fontSize: 14, color: textSecondary),
        bodySmall:     base.bodySmall?.copyWith(fontSize: 12, color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        shape: const Border(bottom: BorderSide(color: border)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        shadowColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return accent.withValues(alpha: 0.4);
            if (states.contains(WidgetState.hovered)) return accentHover;
            return accent;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Keep darkTheme as alias for lightTheme — we now use light theme everywhere
  static ThemeData get darkTheme => lightTheme;

  // ── Reusable decorations ──────────────────────────────────────────────────

  /// Standard card decoration — white, border, subtle shadow.
  static BoxDecoration cardDecoration({double radius = 12}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: shadowSm,
      );

  /// Accent-filled button gradient (kept for backward compat with existing widgets).
  static BoxDecoration buttonGradientDecoration({
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) =>
      BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      );

  /// Glass decoration — now just a clean white card.
  static BoxDecoration glassDecoration({
    double borderRadius = 12,
    Color? color,
    bool useGradient = false,
  }) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: shadowSm,
      );

  static BoxDecoration gradientDecoration({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<Color>? customColors,
  }) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: shadowSm,
      );

  static BoxDecoration cardGradientDecoration({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) =>
      cardDecoration();

  static BoxDecoration shimmerDecoration() => BoxDecoration(
        color: surfaceHover,
        borderRadius: BorderRadius.circular(12),
      );
}
