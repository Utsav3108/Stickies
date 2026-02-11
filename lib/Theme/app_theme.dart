// lib/theme/app_theme.dart
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Headers
  static TextStyle headerStyle(double size) => GoogleFonts.caveat(
    fontSize: size,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Body text
  static TextStyle bodyStyle(
      { double size = 16, Color color = Colors.black87, FontWeight weight = FontWeight.w800})
  => GoogleFonts.comicNeue(
    fontSize: size,
    color: color,
    fontWeight: FontWeight.w800,
  );

  // UI elements
  static TextStyle uiStyle(double size) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}