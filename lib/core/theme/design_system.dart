import 'package:flutter/material.dart';

class DesignSystem {
  // Colors
  static const Color primaryPurple = Color(0xFF8E2DE2);
  static const Color primaryOrange = Color(0xFFF64f59);
  static const Color softWhite = Color(0xFFFFFBFF);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
  static const Color glassCardBackground = Color(0x1AFFFFFF);

  // Assets
  static const String logoPath = 'assets/images/image.png';

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x66FFFFFF), Color(0x1AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> gradientShadow = [
    BoxShadow(
      color: primaryPurple.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Border Radius
  static BorderRadius radius16 = BorderRadius.circular(16);
  static BorderRadius radius24 = BorderRadius.circular(24);
  static BorderRadius radiusInfinite = BorderRadius.circular(99);

  // Spacing
  static const double space8 = 8.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Themes
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: softWhite,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: primaryOrange,
      surface: Colors.white,
      onSurface: charcoal,
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: primaryOrange,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    useMaterial3: true,
  );

  // Dynamic Colors Helpers
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E1E1E)
      : Colors.white;

  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF121212)
      : softWhite;

  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2C)
      : Colors.white;

  static Color textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : charcoal;

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.grey[400]!
      : Colors.grey[600]!;

  static Color iconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : charcoal;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white12
      : Colors.grey[200]!;

  static Color outlineColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white24
      : Colors.grey[300]!;
}
