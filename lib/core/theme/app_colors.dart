import 'package:flutter/material.dart';
import 'package:tiwee/core/consts.dart';

/// The two dark palettes the app ships with.
///
/// Both are dark on purpose — the design is dark-only, so this switches
/// contrast rather than inverting the app.
enum ThemePalette {
  /// The original purple-tinted dark theme.
  dark('Dark'),

  /// True black, which switches OLED pixels off entirely.
  amoled('AMOLED');

  const ThemePalette(this.label);

  final String label;

  static ThemePalette fromName(String? name) {
    return ThemePalette.values.firstWhere(
      (palette) => palette.name == name,
      orElse: () => ThemePalette.dark,
    );
  }
}

/// Surface colours, resolved from the active [ThemePalette].
///
/// A [ThemeExtension] rather than a provider so plain widgets can read it off
/// the context, and so switching palettes animates like any other theme change.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundEnd,
    required this.card,
  });

  factory AppColors.of(ThemePalette palette) =>
      palette == ThemePalette.amoled ? amoled : dark;

  static const AppColors dark = AppColors(
    background: kBlackBg,
    backgroundEnd: kWhiteBg,
    card: kGray,
  );

  static const AppColors amoled = AppColors(
    background: Color(0xff000000),
    backgroundEnd: Color(0xff0a0a0a),
    card: Color(0xff121212),
  );

  /// Page background, and the start of the menu/settings gradient.
  final Color background;

  /// The lighter end of that gradient.
  final Color backgroundEnd;

  /// Cards, tiles and sheets.
  final Color card;

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundEnd,
    Color? card,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      card: card ?? this.card,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      card: Color.lerp(card, other.card, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Surface colours for the active palette.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
