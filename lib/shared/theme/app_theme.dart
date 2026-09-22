import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/soft_surface.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(seedColor: studyAccent).copyWith(
      primary: studyAccent,
      onPrimary: Colors.white,
      surface: const Color(0xFFF6F3F2),
      onSurface: studyInk,
      secondary: const Color(0xFF796088),
      outline: const Color(0xFFA19B9F),
    );
    final button = FilledButton.styleFrom(
      minimumSize: const Size(48, 50),
      backgroundColor: studyInk,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: const StadiumBorder(),
      elevation: 0,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFE8E7E6),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      }),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFE8E7E6),
        surfaceTintColor: Colors.transparent,
        foregroundColor: studyInk,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: studyInk,
            fontSize: 23,
            fontWeight: FontWeight.w600,
            letterSpacing: -.6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xE6F7F5F4),
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? studyAccent
                : studyMuted,
            size: 23)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0x99FFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xEEFFFFFF), width: 1.3)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x45FFFFFF),
        selectedColor: Colors.white,
        side: const BorderSide(color: Color(0xFFCFCCCE)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: const TextStyle(
            color: studyInk, fontSize: 13, fontWeight: FontWeight.w500),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
        shape: WidgetStateProperty.all(const StadiumBorder()),
        backgroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0x30FFFFFF)),
        foregroundColor: WidgetStateProperty.all(studyInk),
        side:
            WidgetStateProperty.all(const BorderSide(color: Color(0xFFCFCCCE))),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(style: button),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 50),
              foregroundColor: studyInk,
              shape: const StadiumBorder())),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xBCFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Colors.white)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Colors.white)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: studyAccent, width: 1.5)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: studyAccent),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
