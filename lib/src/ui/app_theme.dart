part of '../../main.dart';

/// 用户可选的主题模式：跟随系统、强制浅色、强制深色。
enum AppThemeMode { system, light, dark }

ThemeMode _toMaterialThemeMode(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

/// 一套语义令牌，浅色与深色各一份。通过 [ThemeExtension] 挂到 [ThemeData]，
/// 用 [tokens] 读取。所有玻璃基元与文本/图标色都从这里取色，深色模式即自然成立。
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brightness,
    required this.ink,
    required this.mutedInk,
    required this.accent,
    required this.mint,
    required this.accentSoft,
    required this.line,
    required this.surface,
    required this.glassRim,
    required this.glassShadow,
    required this.glassFill,
    required this.glassFillAlpha,
    required this.backdropGradient,
    required this.backdropVeil,
    required this.backdropVeilAlpha,
    required this.sheetFill,
    required this.sheetBorder,
    required this.elevatedShadow,
  });

  final Brightness brightness;

  /// 正文墨色（浅色为近黑，深色为近白）。
  final Color ink;
  final Color mutedInk;
  final Color accent;
  final Color mint;
  final Color accentSoft;
  final Color line;
  final Color surface;

  /// 玻璃基元的边缘、阴影与填充底色。
  final Color glassRim;
  final Color glassShadow;
  final Color glassFill;
  final double glassFillAlpha;

  /// 环境背景的渐变与遮罩。
  final List<Color> backdropGradient;
  final Color backdropVeil;
  final double backdropVeilAlpha;

  /// 底部浮层（sheet）的填充与顶边高光。
  final Color sheetFill;
  final Color sheetBorder;
  final Color elevatedShadow;

  static const light = AppTokens(
    brightness: Brightness.light,
    ink: Color(0xFF0C1014),
    mutedInk: Color(0xFF4A5568),
    accent: Color(0xFF0062FF),
    mint: Color(0xFF3B82F6),
    accentSoft: Color(0xFFDEEAFF),
    line: Color(0x1A0C1014),
    surface: Color(0xFFF1F3F7),
    glassRim: Color(0xA6FFFFFF),
    glassShadow: Color(0xFF14281E),
    glassFill: Color(0xFFFFFFFF),
    glassFillAlpha: 0.62,
    backdropGradient: [
      Color(0xFFEAEEF4),
      Color(0xFFDDE4EE),
      Color(0xFFEFF1F4),
    ],
    backdropVeil: Color(0xFFF2F5FA),
    backdropVeilAlpha: 0.6,
    sheetFill: Color(0xFFFFFFFF),
    sheetBorder: Color(0xFFFFFFFF),
    elevatedShadow: Color(0xFF14281E),
  );

  static const dark = AppTokens(
    brightness: Brightness.dark,
    ink: Color(0xFFECEFF4),
    mutedInk: Color(0xFF8A94A6),
    accent: Color(0xFF4D8FFF),
    mint: Color(0xFF6FA8FF),
    accentSoft: Color(0xFF1B2A44),
    line: Color(0x2EFFFFFF),
    surface: Color(0xFF0E1116),
    glassRim: Color(0x33FFFFFF),
    glassShadow: Color(0xFF000000),
    glassFill: Color(0xFF1C1F26),
    glassFillAlpha: 0.5,
    backdropGradient: [
      Color(0xFF0B0E13),
      Color(0xFF10141B),
      Color(0xFF0E1217),
    ],
    backdropVeil: Color(0xFF0E1116),
    backdropVeilAlpha: 0.66,
    sheetFill: Color(0xFF1C1F26),
    sheetBorder: Color(0x59FFFFFF),
    elevatedShadow: Color(0xFF000000),
  );

  @override
  AppTokens copyWith({Color? ink}) =>
      AppTokens(brightness: brightness, ink: ink ?? this.ink, mutedInk: mutedInk, accent: accent, mint: mint, accentSoft: accentSoft, line: line, surface: surface, glassRim: glassRim, glassShadow: glassShadow, glassFill: glassFill, glassFillAlpha: glassFillAlpha, backdropGradient: backdropGradient, backdropVeil: backdropVeil, backdropVeilAlpha: backdropVeilAlpha, sheetFill: sheetFill, sheetBorder: sheetBorder, elevatedShadow: elevatedShadow);

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      line: Color.lerp(line, other.line, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      glassRim: Color.lerp(glassRim, other.glassRim, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillAlpha: lerpDouble(glassFillAlpha, other.glassFillAlpha, t)!,
      backdropGradient: [
        Color.lerp(backdropGradient[0], other.backdropGradient[0], t)!,
        Color.lerp(backdropGradient[1], other.backdropGradient[1], t)!,
        Color.lerp(backdropGradient[2], other.backdropGradient[2], t)!,
      ],
      backdropVeil: Color.lerp(backdropVeil, other.backdropVeil, t)!,
      backdropVeilAlpha: lerpDouble(backdropVeilAlpha, other.backdropVeilAlpha, t)!,
      sheetFill: Color.lerp(sheetFill, other.sheetFill, t)!,
      sheetBorder: Color.lerp(sheetBorder, other.sheetBorder, t)!,
      elevatedShadow: Color.lerp(elevatedShadow, other.elevatedShadow, t)!,
    );
  }
}

/// 当前主题令牌。玻璃基元与页面都用它取色，深色模式即自然成立。
AppTokens tokens(BuildContext context) =>
    Theme.of(context).extension<AppTokens>() ?? AppTokens.light;

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

/// 浅色 [ThemeData]。文本色取自 [AppTokens.light]，让 `Theme.of(context).textTheme`
/// 在浅色下直接可用；深色另建一份。
ThemeData buildAppTheme(Brightness brightness) {
  final t = brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: t.accent,
    brightness: brightness,
    surface: t.surface,
  );
  final ink = t.ink;
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'SF Pro Display',
    fontFamilyFallback: const ['PingFang SC', 'Helvetica Neue', 'Arial'],
    scaffoldBackgroundColor: Colors.transparent,
    dividerColor: t.line,
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    extensions: [t],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      titleTextStyle: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800),
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: t.glassFill.withValues(alpha: t.glassFillAlpha),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: t.glassRim, width: 0.8),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: t.glassRim),
      ),
      backgroundColor: t.glassFill.withValues(alpha: t.glassFillAlpha),
      selectedColor: t.accentSoft,
      labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700),
      checkmarkColor: t.accent,
      iconTheme: IconThemeData(color: t.accent, size: 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: t.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    ),
    textTheme: Typography.blackMountainView.copyWith(
      bodyLarge: TextStyle(color: ink),
      bodyMedium: TextStyle(color: ink),
      bodySmall: TextStyle(color: t.mutedInk),
      titleLarge: TextStyle(color: ink),
      titleMedium: TextStyle(color: ink),
      titleSmall: TextStyle(color: ink),
      labelLarge: TextStyle(color: ink),
      labelMedium: TextStyle(color: t.mutedInk),
      labelSmall: TextStyle(color: t.mutedInk),
    ),
  );
}
