import 'package:flutter/material.dart';

class AppTheme {
  // Minimalist gray and black theme with accent colors
  static final ThemeData radioAppTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      brightness: Brightness.dark,
      primary: const Color(0xFF00D1FF),  // Bright blue accent
      onPrimary: Colors.white,
      secondary: const Color(0xFF00D1FF),  // Bright blue accent
      onSecondary: Colors.white,
      tertiary: const Color(0xFF9E9E9E),   // Gray accent
      error: const Color(0xFFFF2D55),      // Bright red for alerts
      surface: const Color(0xFF121212),    // Dark gray surface
      onSurface: Colors.white,
      background: const Color(0xFF000000), // Pure black background
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    
    // Card theme
    cardTheme: CardTheme(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.5),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D1FF),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00D1FF),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF00D1FF), width: 1),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00D1FF), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF2D55)),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF00D1FF),
        fontWeight: FontWeight.bold,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontWeight: FontWeight.normal,
      ),
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      toolbarHeight: 70,
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0A0A0A),
      selectedItemColor: Color(0xFF00D1FF),
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
      ),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      deleteIconColor: Colors.white70,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFFE0E0E0),
        letterSpacing: 0.15,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFFBDBDBD),
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    
    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
    ),
    
    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF00D1FF),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF303030),
      thickness: 1,
      space: 32,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00D1FF);
        }
        return const Color(0xFFBDBDBD);
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00D1FF).withOpacity(0.5);
        }
        return const Color(0xFF757575);
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00D1FF);
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.black),
      side: BorderSide(color: Colors.white.withOpacity(0.6)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // List tile theme
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF00D1FF),
      textColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      tileColor: Color(0xFF1E1E1E),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF00D1FF),
      inactiveTrackColor: const Color(0xFF757575),
      thumbColor: const Color(0xFF00D1FF),
      trackHeight: 4.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
    ),
  );
}
