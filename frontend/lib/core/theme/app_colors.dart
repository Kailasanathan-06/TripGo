import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const royalBlue = Color(0xFF1769E8);
  static const deepBlue = Color(0xFF173B78);
  static const darkNavy = Color(0xFF0B1F45);
  static const electricBlue = Color(0xFF3B82F6);
  static const cyan = Color(0xFF20C7D9);
  static const lightBlue = Color(0xFFEEF5FF);
  static const background = Color(0xFFF5F7FC);
  static const white = Color(0xFFFFFFFF);

  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const textPrimary = Color(0xFF0B1F45);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [royalBlue, electricBlue],
  );

  static const navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, darkNavy],
  );

  static const cyanGradient = LinearGradient(
    colors: [cyan, royalBlue],
  );
}