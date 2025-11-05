import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get lightTheme => ThemeData(
    colorSchemeSeed: const Color(0xFF1976D2), // Blue
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFE3F2FD), // Light blue
    brightness: Brightness.light,
  );
  
  ThemeData get darkTheme => ThemeData(
    colorSchemeSeed: const Color(0xFF1976D2), // Blue
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
    brightness: Brightness.dark,
  );
  
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
  
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
