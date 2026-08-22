import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'derma_theme_mode';
  ThemeMode mode = ThemeMode.light;

  bool get isDark => mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    AppColors.apply(dark: isDark);
    notifyListeners();
  }

  Future<void> toggle() async {
    mode = isDark ? ThemeMode.light : ThemeMode.dark;
    AppColors.apply(dark: isDark);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: Color(0xFF2DD4BF),
            secondary: Color(0xFF5EEAD4),
            surface: Color(0xFF151C2C),
            error: Color(0xFFF87171),
            onPrimary: Color(0xFF042F2E),
            onSurface: Color(0xFFF1F5F9),
            onSurfaceVariant: Color(0xFF94A3B8),
          )
        : const ColorScheme.light(
            primary: Color(0xFF0F766E),
            secondary: Color(0xFF0D9488),
            surface: Color(0xFFFFFFFF),
            error: Color(0xFFB42318),
            onPrimary: Colors.white,
            onSurface: Color(0xFF0B1220),
            onSurfaceVariant: Color(0xFF475569),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0B1220) : const Color(0xFFE2E8F0),
      fontFamily: GoogleFonts.dmSans().fontFamily,
      cardColor: dark ? const Color(0xFF1C2538) : Colors.white,
      dividerColor: dark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: dark ? const Color(0xFF151C2C) : Colors.white,
        foregroundColor: scheme.onSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: dark ? const Color(0xFF0B1220) : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF151C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF151C2C) : Colors.white,
        modalBackgroundColor: dark ? const Color(0xFF151C2C) : Colors.white,
      ),
    );
  }
}
