import 'package:flutter/material.dart';

import 'app_color_pair.dart';

/// Semantic pairs from REFONTE_CONTEXT section 6. Existing names remain stable.
/// surfaceRaised is the historical card surface; surfaceOverlay is the raised
/// dialog/menu surface. The Quran pair is deliberately unchanged.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surfaceRaised,
    required this.surfaceCanvas,
    required this.surfaceSunken,
    required this.surfacePrimary,
    required this.surfaceSuccess,
    required this.surfaceWarning,
    required this.surfaceAlert,
    required this.surfaceInverse,
    required this.washAccent,
    required this.washSuccess,
    required this.washWarning,
    required this.washAlert,
    required this.washFamily,
    required this.surfaceQuran,
    required this.borderHairline,
    required this.borderResting,
    required this.borderStrong,
    required this.inkFaint,
    required this.inkMuted,
    required this.inkStrong,
    required this.inkAccent,
    required this.inkSuccess,
    required this.inkWarning,
    required this.inkAlert,
    required this.ombre,
    AppColorPair? surfaceOverlay,
  }) : surfaceOverlay = surfaceOverlay ?? surfaceRaised;

  factory AppPalette.claire() => const AppPalette(
    surfaceRaised: AppColorPair(
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF211E28),
    ),
    surfaceCanvas: AppColorPair(
      background: Color(0xFFF8F7FA),
      onBackground: Color(0xFF211E28),
    ),
    surfaceSunken: AppColorPair(
      background: Color(0xFFF0EDF4),
      onBackground: Color(0xFF211E28),
    ),
    surfaceOverlay: AppColorPair(
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF211E28),
    ),
    surfacePrimary: AppColorPair(
      background: Color(0xFF8652E6),
      onBackground: Color(0xFFFFFFFF),
    ),
    surfaceSuccess: AppColorPair(
      background: Color(0xFF70EE9C),
      onBackground: Color(0xFF1C1D21),
    ),
    surfaceWarning: AppColorPair(
      background: Color(0xFFFFB703),
      onBackground: Color(0xFF1C1D21),
    ),
    surfaceAlert: AppColorPair(
      background: Color(0xFFB01B3C),
      onBackground: Color(0xFFFFFFFF),
    ),
    surfaceInverse: AppColorPair(
      background: Color(0xFF211E28),
      onBackground: Color(0xFFF5F2FA),
    ),
    washAccent: AppColorPair(
      background: Color(0xFFEEE6FA),
      onBackground: Color(0xFF4E2983),
    ),
    washSuccess: AppColorPair(
      background: Color(0xFFE4F4EB),
      onBackground: Color(0xFF175D3A),
    ),
    washWarning: AppColorPair(
      background: Color(0xFFFFF2CE),
      onBackground: Color(0xFF755200),
    ),
    washAlert: AppColorPair(
      background: Color(0xFFFCE8ED),
      onBackground: Color(0xFF921734),
    ),
    washFamily: AppColorPair(
      background: Color(0xFFF0EDF4),
      onBackground: Color(0xFF211E28),
    ),
    surfaceQuran: AppColorPair(
      background: Color(0xFFF3EAD9),
      onBackground: Color(0xFF1C1D21),
    ),
    borderHairline: AppInkColor(Color(0xFFE3DEE9)),
    borderResting: AppInkColor(Color(0xFF84798F)),
    borderStrong: AppInkColor(Color(0xFF84798F)),
    inkFaint: AppInkColor(Color(0xFF84798F)),
    inkMuted: AppInkColor(Color(0xFF655E70)),
    inkStrong: AppInkColor(Color(0xFF211E28)),
    inkAccent: AppInkColor(Color(0xFF5B36B0)),
    inkSuccess: AppInkColor(Color(0xFF175D3A)),
    inkWarning: AppInkColor(Color(0xFF755200)),
    inkAlert: AppInkColor(Color(0xFF921734)),
    ombre: AppShadowColor(Color(0xFF211E28)),
  );

  factory AppPalette.sombre() => const AppPalette(
    surfaceRaised: AppColorPair(
      background: Color(0xFF1A181F),
      onBackground: Color(0xFFF5F2FA),
    ),
    surfaceCanvas: AppColorPair(
      background: Color(0xFF111014),
      onBackground: Color(0xFFF5F2FA),
    ),
    surfaceSunken: AppColorPair(
      background: Color(0xFF24212B),
      onBackground: Color(0xFFF5F2FA),
    ),
    surfaceOverlay: AppColorPair(
      background: Color(0xFF2C2834),
      onBackground: Color(0xFFF5F2FA),
    ),
    surfacePrimary: AppColorPair(
      background: Color(0xFFC9AEFF),
      onBackground: Color(0xFF25113F),
    ),
    surfaceSuccess: AppColorPair(
      background: Color(0xFF70EE9C),
      onBackground: Color(0xFF1C1D21),
    ),
    surfaceWarning: AppColorPair(
      background: Color(0xFFFFB703),
      onBackground: Color(0xFF1C1D21),
    ),
    surfaceAlert: AppColorPair(
      background: Color(0xFFFFB1BD),
      onBackground: Color(0xFF570D22),
    ),
    surfaceInverse: AppColorPair(
      background: Color(0xFFF5F2FA),
      onBackground: Color(0xFF211E28),
    ),
    washAccent: AppColorPair(
      background: Color(0xFF332643),
      onBackground: Color(0xFFE8D8FF),
    ),
    washSuccess: AppColorPair(
      background: Color(0xFF173B2B),
      onBackground: Color(0xFF9DDEB5),
    ),
    washWarning: AppColorPair(
      background: Color(0xFF44361A),
      onBackground: Color(0xFFF4D480),
    ),
    washAlert: AppColorPair(
      background: Color(0xFF4A2030),
      onBackground: Color(0xFFFFD9E0),
    ),
    washFamily: AppColorPair(
      background: Color(0xFF24212B),
      onBackground: Color(0xFFF5F2FA),
    ),
    surfaceQuran: AppColorPair(
      background: Color(0xFF2E2417),
      onBackground: Color(0xFFF5F1E9),
    ),
    borderHairline: AppInkColor(Color(0xFF3A3443)),
    borderResting: AppInkColor(Color(0xFF95899F)),
    borderStrong: AppInkColor(Color(0xFF95899F)),
    inkFaint: AppInkColor(Color(0xFF95899F)),
    inkMuted: AppInkColor(Color(0xFFBAB3C5)),
    inkStrong: AppInkColor(Color(0xFFF5F2FA)),
    inkAccent: AppInkColor(Color(0xFFC9AEFF)),
    inkSuccess: AppInkColor(Color(0xFF9DDEB5)),
    inkWarning: AppInkColor(Color(0xFFF4D480)),
    inkAlert: AppInkColor(Color(0xFFFFD9E0)),
    ombre: AppShadowColor(Color(0xFF211E28)),
  );

  final AppColorPair surfaceRaised;
  final AppColorPair surfaceCanvas;
  final AppColorPair surfaceSunken;
  final AppColorPair surfaceOverlay;
  final AppColorPair surfacePrimary;
  final AppColorPair surfaceSuccess;
  final AppColorPair surfaceWarning;
  final AppColorPair surfaceAlert;
  final AppColorPair surfaceInverse;
  final AppColorPair washAccent;
  final AppColorPair washSuccess;
  final AppColorPair washWarning;
  final AppColorPair washAlert;
  final AppColorPair washFamily;
  final AppColorPair surfaceQuran;
  final AppInkColor borderHairline;
  final AppInkColor borderResting;
  final AppInkColor borderStrong;
  final AppInkColor inkFaint;
  final AppInkColor inkMuted;
  final AppInkColor inkStrong;
  final AppInkColor inkAccent;
  final AppInkColor inkSuccess;
  final AppInkColor inkWarning;
  final AppInkColor inkAlert;
  final AppShadowColor ombre;

  bool get estSombre => surfaceCanvas.background.computeLuminance() < 0.5;
  AppInkColor get contourCarte => AppInkColor(
    (estSombre ? const Color(0xFFFFFFFF) : const Color(0xFF211E28)).withValues(
      alpha: 0.08,
    ),
  );
  Color get voile =>
      const Color(0xFF000000).withValues(alpha: estSombre ? 0.56 : 0.32);
  AppShadowColor get ombreDialogue => const AppShadowColor(Color(0xFF000000));
  Color calqueInteraction({bool presse = false}) =>
      inkAccent.asBorderSide().color.withValues(alpha: presse ? 0.10 : 0.04);
  AppInkColor encreSecondaireSur(AppColorPair surface) => inkMuted;
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    AppColorPair? surfaceRaised,
    AppColorPair? surfaceCanvas,
    AppColorPair? surfaceSunken,
    AppColorPair? surfaceOverlay,
    AppColorPair? surfacePrimary,
    AppColorPair? surfaceSuccess,
    AppColorPair? surfaceWarning,
    AppColorPair? surfaceAlert,
    AppColorPair? surfaceInverse,
    AppColorPair? washAccent,
    AppColorPair? washSuccess,
    AppColorPair? washWarning,
    AppColorPair? washAlert,
    AppColorPair? washFamily,
    AppColorPair? surfaceQuran,
    AppInkColor? borderHairline,
    AppInkColor? borderResting,
    AppInkColor? borderStrong,
    AppInkColor? inkFaint,
    AppInkColor? inkMuted,
    AppInkColor? inkStrong,
    AppInkColor? inkAccent,
    AppInkColor? inkSuccess,
    AppInkColor? inkWarning,
    AppInkColor? inkAlert,
    AppShadowColor? ombre,
  }) => AppPalette(
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
    surfacePrimary: surfacePrimary ?? this.surfacePrimary,
    surfaceSuccess: surfaceSuccess ?? this.surfaceSuccess,
    surfaceWarning: surfaceWarning ?? this.surfaceWarning,
    surfaceAlert: surfaceAlert ?? this.surfaceAlert,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    washAccent: washAccent ?? this.washAccent,
    washSuccess: washSuccess ?? this.washSuccess,
    washWarning: washWarning ?? this.washWarning,
    washAlert: washAlert ?? this.washAlert,
    washFamily: washFamily ?? this.washFamily,
    surfaceQuran: surfaceQuran ?? this.surfaceQuran,
    borderHairline: borderHairline ?? this.borderHairline,
    borderResting: borderResting ?? this.borderResting,
    borderStrong: borderStrong ?? this.borderStrong,
    inkFaint: inkFaint ?? this.inkFaint,
    inkMuted: inkMuted ?? this.inkMuted,
    inkStrong: inkStrong ?? this.inkStrong,
    inkAccent: inkAccent ?? this.inkAccent,
    inkSuccess: inkSuccess ?? this.inkSuccess,
    inkWarning: inkWarning ?? this.inkWarning,
    inkAlert: inkAlert ?? this.inkAlert,
    ombre: ombre ?? this.ombre,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surfaceRaised: AppColorPair.lerp(surfaceRaised, other.surfaceRaised, t),
      surfaceCanvas: AppColorPair.lerp(surfaceCanvas, other.surfaceCanvas, t),
      surfaceSunken: AppColorPair.lerp(surfaceSunken, other.surfaceSunken, t),
      surfaceOverlay: AppColorPair.lerp(
        surfaceOverlay,
        other.surfaceOverlay,
        t,
      ),
      surfacePrimary: AppColorPair.lerp(
        surfacePrimary,
        other.surfacePrimary,
        t,
      ),
      surfaceSuccess: AppColorPair.lerp(
        surfaceSuccess,
        other.surfaceSuccess,
        t,
      ),
      surfaceWarning: AppColorPair.lerp(
        surfaceWarning,
        other.surfaceWarning,
        t,
      ),
      surfaceAlert: AppColorPair.lerp(surfaceAlert, other.surfaceAlert, t),
      surfaceInverse: AppColorPair.lerp(
        surfaceInverse,
        other.surfaceInverse,
        t,
      ),
      washAccent: AppColorPair.lerp(washAccent, other.washAccent, t),
      washSuccess: AppColorPair.lerp(washSuccess, other.washSuccess, t),
      washWarning: AppColorPair.lerp(washWarning, other.washWarning, t),
      washAlert: AppColorPair.lerp(washAlert, other.washAlert, t),
      washFamily: AppColorPair.lerp(washFamily, other.washFamily, t),
      surfaceQuran: AppColorPair.lerp(surfaceQuran, other.surfaceQuran, t),
      borderHairline: AppInkColor.lerp(borderHairline, other.borderHairline, t),
      borderResting: AppInkColor.lerp(borderResting, other.borderResting, t),
      borderStrong: AppInkColor.lerp(borderStrong, other.borderStrong, t),
      inkFaint: AppInkColor.lerp(inkFaint, other.inkFaint, t),
      inkMuted: AppInkColor.lerp(inkMuted, other.inkMuted, t),
      inkStrong: AppInkColor.lerp(inkStrong, other.inkStrong, t),
      inkAccent: AppInkColor.lerp(inkAccent, other.inkAccent, t),
      inkSuccess: AppInkColor.lerp(inkSuccess, other.inkSuccess, t),
      inkWarning: AppInkColor.lerp(inkWarning, other.inkWarning, t),
      inkAlert: AppInkColor.lerp(inkAlert, other.inkAlert, t),
      ombre: AppShadowColor.lerp(ombre, other.ombre, t),
    );
  }
}
