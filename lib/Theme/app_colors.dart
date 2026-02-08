import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Background
  static const Color background = Colors.black;

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textHint = Colors.white54;

  // Sticky note type colors (Chips)
  static const Color textChip = Color(0xFFD8DD56);    // Yellow
  static const Color photoChip = Color(0xFF7C74F5);   // Purple
  static const Color videoChip = Color(0xFFF5AA74);   // Orange

  // Button colors
  static const Color saveButton = Color(0xFFA4F291);  // Green

  // Opacity levels
  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.5;
}