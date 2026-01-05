import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }
}

// App Colors
const Color figmaBrown1 = Color(0xFF8B4513); // Brown color
const Color figmaBrown2 = Color(0xFFD2691E); // Light brown
const Color figmaCard = Color(0xFFF5F5DC); // Beige card color
