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
    required this.teintesIdentite,
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
    teintesIdentite: _teintesIdentiteClaires,
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
    teintesIdentite: _teintesIdentiteSombres,
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

  /// La table administree de teintes d'identite (decision D-18, plan
  /// d'integration Teaching Core section 9.2).
  ///
  /// 32 paires, verifiees contraste (>= 4.5:1 AA, clair et sombre) et
  /// distinguabilite sous protanopie/deuteranopie/tritanopie (script de
  /// generation dans l'historique d'integration). Aucune ne reutilise une
  /// teinte porteuse de sens (accent, succes, avertissement, alerte, Coran) :
  /// ces identites sont decoratives, jamais le seul identifiant (invariant
  /// `J7` -- toujours posees a cote d'un nom, jamais a sa place).
  ///
  /// Quatre paliers de luminosite x huit teintes. La distinguabilite reelle
  /// sous daltonisme reste modeste au-dela d'une douzaine de teintes (la
  /// simulation compresse fortement l'axe rouge-vert) : c'est mesure, pas
  /// suppose, et c'est pour cela que la couleur ne porte jamais seule le
  /// sens ici. Ne pas indexer directement : passer par [teinteGroupe] ou
  /// [teinteCouverture].
  final List<AppColorPair> teintesIdentite;

  /// La teinte d'identite d'un groupe, par index stable (decision D-18).
  AppColorPair teinteGroupe(int index) =>
      teintesIdentite[index % teintesIdentite.length];

  /// La teinte d'identite d'une couverture de ressource calculee (decision
  /// D-18). Meme table que [teinteGroupe] : deux demandeurs, un seul lot.
  AppColorPair teinteCouverture(int index) =>
      teintesIdentite[index % teintesIdentite.length];

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
    List<AppColorPair>? teintesIdentite,
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
    teintesIdentite: teintesIdentite ?? this.teintesIdentite,
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
      teintesIdentite: <AppColorPair>[
        for (int i = 0; i < teintesIdentite.length; i++)
          AppColorPair.lerp(teintesIdentite[i], other.teintesIdentite[i], t),
      ],
    );
  }
}

/// 32 teintes d'identite, theme clair. Voir [AppPalette.teintesIdentite].
const List<AppColorPair> _teintesIdentiteClaires = <AppColorPair>[
  AppColorPair(background: Color(0xFFEB7070), onBackground: Color(0xFF5B1313)),
  AppColorPair(background: Color(0xFF7070EB), onBackground: Color(0xFF0C0C3B)),
  AppColorPair(background: Color(0xFFE7CEF8), onBackground: Color(0xFF8729C7)),
  AppColorPair(background: Color(0xFFA9EB70), onBackground: Color(0xFF3C6915)),
  AppColorPair(background: Color(0xFFD98FEF), onBackground: Color(0xFF65197C)),
  AppColorPair(background: Color(0xFF70EBC2), onBackground: Color(0xFF15684C)),
  AppColorPair(background: Color(0xFFDDF4AF), onBackground: Color(0xFF547217)),
  AppColorPair(background: Color(0xFFEF8FC2), onBackground: Color(0xFF78194C)),
  AppColorPair(background: Color(0xFFEFB38F), onBackground: Color(0xFF7A3C19)),
  AppColorPair(background: Color(0xFFAFF4EA), onBackground: Color(0xFF177367)),
  AppColorPair(background: Color(0xFFEB70C6), onBackground: Color(0xFF5E1348)),
  AppColorPair(background: Color(0xFFE1AFF4), onBackground: Color(0xFF7B209C)),
  AppColorPair(background: Color(0xFFD270EB), onBackground: Color(0xFF4E135D)),
  AppColorPair(background: Color(0xFFEB9570), onBackground: Color(0xFF672E15)),
  AppColorPair(background: Color(0xFFF8F8CE), onBackground: Color(0xFF737318)),
  AppColorPair(background: Color(0xFF93EF8F), onBackground: Color(0xFF196D16)),
  AppColorPair(background: Color(0xFFF4C1AF), onBackground: Color(0xFF903C1D)),
  AppColorPair(background: Color(0xFFF8D9CE), onBackground: Color(0xFFA44422)),
  AppColorPair(background: Color(0xFFF4AFDF), onBackground: Color(0xFF911E6E)),
  AppColorPair(background: Color(0xFFEB70A9), onBackground: Color(0xFF5D1336)),
  AppColorPair(background: Color(0xFFCEE9F8), onBackground: Color(0xFF1F6B97)),
  AppColorPair(background: Color(0xFFEF9F8F), onBackground: Color(0xFF7B2A19)),
  AppColorPair(background: Color(0xFF8F8FEF), onBackground: Color(0xFF1D1D8C)),
  AppColorPair(background: Color(0xFFEF8FDF), onBackground: Color(0xFF771867)),
  AppColorPair(background: Color(0xFFAFF4B8), onBackground: Color(0xFF187424)),
  AppColorPair(background: Color(0xFF8FA9EF), onBackground: Color(0xFF1C3888)),
  AppColorPair(background: Color(0xFFCEF8EA), onBackground: Color(0xFF197A5A)),
  AppColorPair(background: Color(0xFFF8CECE), onBackground: Color(0xFFB32525)),
  AppColorPair(background: Color(0xFFF4B6AF), onBackground: Color(0xFF952A1E)),
  AppColorPair(background: Color(0xFFF8CEED), onBackground: Color(0xFFA92385)),
  AppColorPair(background: Color(0xFFAFBFF4), onBackground: Color(0xFF2444AE)),
  AppColorPair(background: Color(0xFFCEF8CF), onBackground: Color(0xFF197B1D)),
];

/// 32 teintes d'identite, theme sombre. Meme ordre, meme teinte que
/// [_teintesIdentiteClaires] a chaque index. Voir [AppPalette.teintesIdentite].
const List<AppColorPair> _teintesIdentiteSombres = <AppColorPair>[
  AppColorPair(background: Color(0xFF2D1515), onBackground: Color(0xFFCC6666)),
  AppColorPair(background: Color(0xFF15152D), onBackground: Color(0xFF7878D2)),
  AppColorPair(background: Color(0xFF55336C), onBackground: Color(0xFFC6A0DF)),
  AppColorPair(background: Color(0xFF202D15), onBackground: Color(0xFF67A035)),
  AppColorPair(background: Color(0xFF3A1F42), onBackground: Color(0xFFBC76D1)),
  AppColorPair(background: Color(0xFF152D25), onBackground: Color(0xFF36A27E)),
  AppColorPair(background: Color(0xFF475729), onBackground: Color(0xFFB2D174)),
  AppColorPair(background: Color(0xFF421F32), onBackground: Color(0xFFD174A6)),
  AppColorPair(background: Color(0xFF422C1F), onBackground: Color(0xFFCC8A65)),
  AppColorPair(background: Color(0xFF295751), onBackground: Color(0xFF77D2C6)),
  AppColorPair(background: Color(0xFF2D1526), onBackground: Color(0xFFCA60AA)),
  AppColorPair(background: Color(0xFF4A2957), onBackground: Color(0xFFC48BD8)),
  AppColorPair(background: Color(0xFF28152D), onBackground: Color(0xFFB764CB)),
  AppColorPair(background: Color(0xFF2D1C15), onBackground: Color(0xFFC57350)),
  AppColorPair(background: Color(0xFF6C6C33), onBackground: Color(0xFFEDEDC8)),
  AppColorPair(background: Color(0xFF20421F), onBackground: Color(0xFF43BD3F)),
  AppColorPair(background: Color(0xFF573529), onBackground: Color(0xFFD79B86)),
  AppColorPair(background: Color(0xFF6C4233), onBackground: Color(0xFFE1B4A4)),
  AppColorPair(background: Color(0xFF572949), onBackground: Color(0xFFD88AC1)),
  AppColorPair(background: Color(0xFF2D1520), onBackground: Color(0xFFCB6293)),
  AppColorPair(background: Color(0xFF33576C), onBackground: Color(0xFFA8CDE2)),
  AppColorPair(background: Color(0xFF42251F), onBackground: Color(0xFFCF8070)),
  AppColorPair(background: Color(0xFF1F1F42), onBackground: Color(0xFF8282D5)),
  AppColorPair(background: Color(0xFF421F3C), onBackground: Color(0xFFD072C0)),
  AppColorPair(background: Color(0xFF29572F), onBackground: Color(0xFF7AD386)),
  AppColorPair(background: Color(0xFF1F2842), onBackground: Color(0xFF778FD2)),
  AppColorPair(background: Color(0xFF336C59), onBackground: Color(0xFFBBE8D9)),
  AppColorPair(background: Color(0xFF6C3333), onBackground: Color(0xFFE0A2A2)),
  AppColorPair(background: Color(0xFF572D29), onBackground: Color(0xFFD8918A)),
  AppColorPair(background: Color(0xFF6C335C), onBackground: Color(0xFFE0A3D0)),
  AppColorPair(background: Color(0xFF293457), onBackground: Color(0xFF8A9DD8)),
  AppColorPair(background: Color(0xFF336C34), onBackground: Color(0xFFB8E7BA)),
];
