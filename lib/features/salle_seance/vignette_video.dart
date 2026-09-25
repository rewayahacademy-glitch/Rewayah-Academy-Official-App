// La vignette video de l'enseignante (CLV-04, 05, 06).
//
// Ratio fixe, jamais etiree (AspectRatio + contenu en `cover`). En capture,
// un aplat aux jetons remplace la photo (plan de code section 3).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'vue_seance.dart';

/// Les mesures de la vignette, par gabarit.
abstract final class MesuresVignette {
  /// Le ratio largeur / hauteur, identique a toutes les largeurs (≈ 1,1:1).
  static const double ratio = 1.1;

  /// Telephone et web etroit : ≈ 136 x 124.
  static const double largeurEtroite = 136;

  /// Desktop : ≈ 208 x 190.
  static const double largeurLarge = 208;

  /// Interface guidee, telephone : ≈ 160 x 145 (S CLV-05).
  static const double largeurGuideeMobile = 160;

  /// Interface guidee, web etroit : ≈ 240 x 218 (image CLV-04-05-06 web
  /// etroit : ≈ 41 % de la largeur du support ; S CLV-05 : 160 a 300).
  static const double largeurGuideeTablette = 240;

  /// Interface guidee, desktop : ≈ 300 x 273, dans sa colonne (Q8).
  static const double largeurGuideeLarge = 300;

  /// Le retrait depuis le coin du support.
  static const double retrait = AppSpacing.md;

  /// La largeur pour un gabarit ; [guidee] : les mesures de l'Interface
  /// guidee ([VueSeance.vignetteAgrandie]).
  static double largeur(Gabarit gabarit, {bool guidee = false}) {
    if (guidee) {
      return switch (gabarit) {
        Gabarit.mobile => largeurGuideeMobile,
        Gabarit.tablette => largeurGuideeTablette,
        Gabarit.desktop => largeurGuideeLarge,
      };
    }
    return gabarit == Gabarit.desktop ? largeurLarge : largeurEtroite;
  }

  /// La hauteur qui suit du ratio.
  static double hauteur(Gabarit gabarit, {bool guidee = false}) =>
      largeur(gabarit, guidee: guidee) / ratio;
}

/// La video de l'enseignante en petite vignette.
///
/// Etiquette du nom en bas a gauche ; barres de signal seulement pour
/// l'enseignant ([VueSeance.voitSignalVideo]).
class VignetteVideo extends StatelessWidget {
  const VignetteVideo({required this.vue, required this.largeur, super.key});

  final VueSeance vue;
  final double largeur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    return Semantics(
      image: true,
      label: t.salle.seance.videoDe(nom: vue.nomEnseignant),
      excludeSemantics: true,
      child: SizedBox(
        key: const ValueKey<String>('vignette-video'),
        width: largeur,
        child: AspectRatio(
          aspectRatio: MesuresVignette.ratio,
          child: DecoratedBox(
            decoration: palette.surfaceInverse.decoration(
              borderRadius: AppRadius.arrondiMd,
              side: palette.borderHairline.asBorderSide(width: 2),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.arrondiMd,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // L'aplat qui tient lieu d'image : la silhouette sur un
                  // fond d'accent, cadree en `cover`, jamais deformee.
                  DecoratedBox(
                    decoration: palette.surfaceActionDouce.decoration(),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: IconTheme(
                          data: IconThemeData(
                            color: palette.surfaceActionDouce.onBackground,
                            size: AppSpacing.titreEcran,
                          ),
                          child: Icon(AppIcons.avatarSansPhoto.actif),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: DecoratedBox(
                            decoration: palette.surfaceInverse.decoration(
                              borderRadius: AppRadius.arrondiXs,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                vue.nomEnseignant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: palette.surfaceInverse.applyTo(
                                  theme.textTheme.labelSmall ??
                                      const TextStyle(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (vue.voitSignalVideo) ...<Widget>[
                          const Spacer(),
                          _Signal(
                            key: const ValueKey<String>('signal-video'),
                            barres: vue.signalEnseignant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trois barres de signal (enseignant seulement).
class _Signal extends StatelessWidget {
  const _Signal({required this.barres, super.key});

  final int barres;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _ecartBarres),
            child: SizedBox(
              width: AppSpacing.xs,
              height: AppSpacing.xs * (i + 2),
              child: DecoratedBox(
                decoration:
                    (i < barres
                            ? palette.pointsStatut.succes
                            : palette.pointsStatut.neutre)
                        .pastille()
                        .copyWith(
                          shape: BoxShape.rectangle,
                          borderRadius: AppRadius.arrondiXs,
                        ),
              ),
            ),
          ),
      ],
    );
  }
}

/// L'ecart entre deux barres de signal : un demi-palier.
const double _ecartBarres = AppSpacing.xs / 2;
