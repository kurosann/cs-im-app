import 'package:flutter/material.dart';

/// 语义色板：同一组 getter 根据当前主题返回浅色/深色值。
abstract final class AppColors {
  static bool _dark = false;

  static void useDark(bool value) => _dark = value;

  static bool get isDark => _dark;

  static Color get ink =>
      _dark ? const Color(0xFFF8FAFC) : const Color(0xFF020617);
  static Color get inkSoft =>
      _dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  static Color get slate700 =>
      _dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
  static Color get slate500 =>
      _dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get muted => const Color(0xFF94A3B8);
  static Color get page =>
      _dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
  static Color get chatBackground =>
      _dark ? const Color(0xFF020617) : const Color(0xFFEDEDED);
  static Color get surface =>
      _dark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  static Color get line =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get cardBorder =>
      _dark ? const Color(0x40CBD5E1) : const Color(0xB3E2E8F0);
  static Color get lavender =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get lavenderDeep =>
      _dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get aiTint =>
      _dark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF);
  static Color get danger => const Color(0xFFEF4444);
  static Color get red50 =>
      _dark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
  static Color get red600 =>
      _dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  static Color get blue50 =>
      _dark ? const Color(0xFF172554) : const Color(0xFFEFF6FF);
  static Color get blue600 =>
      _dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  static Color get emerald600 =>
      _dark ? const Color(0xFF34D399) : const Color(0xFF059669);
  static Color get emerald50 =>
      _dark ? const Color(0xFF052E2B) : const Color(0xFFECFDF5);
  static Color get pendingBg =>
      _dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
  static Color get pendingInk =>
      _dark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
  static Color get online =>
      _dark ? const Color(0xFF4ADE80) : const Color(0xFF22C55E);

  /// 主操作色（选中态 / 发送按钮 / 激活开关）
  static Color get accent =>
      _dark ? const Color(0xFFF8FAFC) : const Color(0xFF020617);
  static Color get onAccent =>
      _dark ? const Color(0xFF020617) : const Color(0xFFFFFFFF);

  /// 深色气泡 / 深色卡片
  static Color get solid =>
      _dark ? const Color(0xFF1E293B) : const Color(0xFF020617);
  static Color get onSolid => const Color(0xFFF8FAFC);

  /// 毛玻璃
  static Color get frost =>
      _dark ? const Color(0xB30F172A) : const Color(0xBFFFFFFF);
  static Color get frostBorder =>
      _dark ? const Color(0x33FFFFFF) : const Color(0xBFFFFFFF);
  static Color get frostShadow =>
      _dark ? const Color(0x66000000) : const Color(0x0F000000);
  static Color get navSurface =>
      _dark ? const Color(0xCC0F172A) : const Color(0xE6FFFFFF);
  static Color get cardShadow =>
      _dark ? const Color(0x4D000000) : const Color(0x0A000000);
}

const String appFontFamily = 'Inter';
const List<String> appFontFallback = <String>['NotoSansSC'];

ThemeData buildAppTheme(Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  final Color accent = dark ? const Color(0xFFF8FAFC) : const Color(0xFF020617);
  final Color page = dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
  final Color surface = dark
      ? const Color(0xFF0F172A)
      : const Color(0xFFFFFFFF);
  final Color onSurface = dark
      ? const Color(0xFFF8FAFC)
      : const Color(0xFF020617);
  final Color onSurfaceVariant = dark
      ? const Color(0xFFCBD5E1)
      : const Color(0xFF475569);
  final Color outlineVariant = dark
      ? const Color(0xFF1E293B)
      : const Color(0xFFE2E8F0);
  final Color container = dark
      ? const Color(0xFF1E293B)
      : const Color(0xFFF1F5F9);

  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: appFontFamily,
    fontFamilyFallback: appFontFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: dark ? const Color(0xFF020617) : const Color(0xFFFFFFFF),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLow: page,
      surfaceContainer: surface,
      surfaceContainerHigh: container,
      onSurfaceVariant: onSurfaceVariant,
      outlineVariant: outlineVariant,
    ),
    scaffoldBackgroundColor: page,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
    iconTheme: IconThemeData(color: onSurfaceVariant),
    dividerColor: outlineVariant,
  );
}
