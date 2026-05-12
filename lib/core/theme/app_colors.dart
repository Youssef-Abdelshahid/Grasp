import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool _dark = false;

  static void setDarkMode(bool value) {
    _dark = value;
  }

  static Color get primary => const Color(0xFF4F46E5);
  static Color get primaryLight =>
      _dark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
  static Color get primaryDark =>
      _dark ? const Color(0xFFA5B4FC) : const Color(0xFF3730A3);

  static Color get secondary => const Color(0xFF06B6D4);
  static Color get secondaryLight =>
      _dark ? const Color(0xFF164E63) : const Color(0xFFECFEFF);

  static Color get background =>
      _dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surface =>
      _dark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);

  static Color get textPrimary =>
      _dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      _dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  static Color get textMuted =>
      _dark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

  static Color get border =>
      _dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get divider =>
      _dark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9);

  static Color get success => const Color(0xFF10B981);
  static Color get successLight =>
      _dark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
  static Color get warning => const Color(0xFFF59E0B);
  static Color get warningLight =>
      _dark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
  static Color get error => const Color(0xFFEF4444);
  static Color get errorLight =>
      _dark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);

  static Color get sidebarBg =>
      _dark ? const Color(0xFF020617) : const Color(0xFF1E1B4B);
  static Color get sidebarText =>
      _dark ? const Color(0xFFE2E8F0) : const Color(0xFFE0E7FF);
  static Color get sidebarTextMuted =>
      _dark ? const Color(0xFF94A3B8) : const Color(0xFF818CF8);
  static Color get sidebarActive => const Color(0xFF4338CA);
  static Color get sidebarHover =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFF2D2A5E);

  static Color get cyan => const Color(0xFF06B6D4);
  static Color get cyanLight =>
      _dark ? const Color(0xFF164E63) : const Color(0xFFECFEFF);
  static Color get amber => const Color(0xFFF59E0B);
  static Color get amberLight =>
      _dark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
  static Color get rose => const Color(0xFFF43F5E);
  static Color get roseLight =>
      _dark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2);
  static Color get emerald => const Color(0xFF10B981);
  static Color get emeraldLight =>
      _dark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
  static Color get violet => const Color(0xFF8B5CF6);
  static Color get violetLight =>
      _dark ? const Color(0xFF2E1065) : const Color(0xFFF5F3FF);
  static Color get orange => const Color(0xFFF97316);
  static Color get orangeLight =>
      _dark ? const Color(0xFF431407) : const Color(0xFFFFF7ED);
}
