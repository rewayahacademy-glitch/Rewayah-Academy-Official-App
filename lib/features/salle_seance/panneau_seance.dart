// Le panneau ouvert a cote du support (enseignant) : Eleves ou Supports.
//
// Trois formes, selon le gabarit (plan de code T5, I-8) :
// - desktop : colonne a gauche du support, entre le rail et le support,
//   jamais par-dessus ;
// - web etroit : volet a gauche, par-dessus le support, avec la croix ;
// - telephone : feuille du bas (grammaire d'`AppBottomSheet` : poignee,
//   arrondi de feuille, filet et ombre de niveau 3) avec la croix, le haut du
//   support restant visible au-dessus.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/pressable.dart';

/// La largeur du volet en web etroit (image CLV-07 : ≈ 313 a 640 de large).
const double largeurPanneauSeance = AppSpacing.respiration * 5;

/// La largeur de la colonne en desktop : la fiche y tient ses valeurs sur
/// une ligne et ses actions avec de la marge (image CLV-07 desktop).
const double largeurColonneSeance = AppSpacing.respiration * 6 - AppSpacing.sm;

/// La largeur de la colonne droite en desktop (Eleves, Supports, outils).
const double largeurColonneDroiteSeance =
    AppSpacing.respiration * 5 - AppSpacing.lg;

/// La hauteur de support laissee visible au-dessus de la feuille du
/// telephone : le haut de la diapositive et la vignette entiere (image).
const double supportVisibleSousFeuille =
    AppSpacing.respiration * 2 + AppSpacing.xxl;

/// La forme du panneau.
enum FormePanneau {
  /// Desktop : colonne, a cote du support.
  colonne,

  /// Web etroit : volet gauche par-dessus le support.
  volet,

  /// Telephone : feuille du bas.
  feuille;

  /// La forme d'un gabarit.
  static FormePanneau pour(Gabarit gabarit) => switch (gabarit) {
    Gabarit.desktop => FormePanneau.colonne,
    Gabarit.tablette => FormePanneau.volet,
    Gabarit.mobile => FormePanneau.feuille,
  };
}

/// Le cadre d'un panneau : [titre], croix de fermeture, [enfant] qui defile.
class PanneauSeance extends StatelessWidget {
  const PanneauSeance({
    required this.titre,
    required this.onFermer,
    this.enfant = const SizedBox.shrink(),
    this.forme = FormePanneau.colonne,
    super.key,
  });

  final String titre;
  final VoidCallback? onFermer;

  /// Le contenu, deja defilant (une liste) ou court.
  final Widget enfant;
  final FormePanneau forme;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool feuille = forme == FormePanneau.feuille;
    final BoxDecoration decoration = feuille
        ? AppElevation.avecFilet(
            surface: palette.surfaceRaised,
            filet: palette.borderHairline,
            ombre: palette.ombre,
            arrondi: AppRadius.arrondiFeuille,
            ombres: AppElevation.niveau3(palette.ombre),
          )
        : palette.surfaceRaised
              .decoration(
                borderRadius: AppRadius.arrondiLg,
                side: palette.borderHairline.asBorderSide(),
              )
              .copyWith(
                boxShadow: forme == FormePanneau.volet
                    ? AppElevation.niveau3(palette.ombre)
                    : AppElevation.niveau1(palette.ombre),
              );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: titre,
      child: DecoratedBox(
        key: ValueKey<String>('panneau-seance-${forme.name}'),
        decoration: decoration,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            forme == FormePanneau.colonne ? AppSpacing.xs : AppSpacing.sm,
            feuille ? AppSpacing.sm : AppSpacing.md,
            forme == FormePanneau.colonne ? AppSpacing.xs : AppSpacing.sm,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (feuille) ...<Widget>[
                Center(
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: AppBottomSheet.largeurPoignee,
                      height: AppBottomSheet.hauteurPoignee,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.borderResting.asBorderSide().color,
                          borderRadius: AppRadius.arrondiFull,
                        ),
                      ),
                    ),
                  ),
                ),
                Ecart.vSm,
              ],
              _EnTete(titre: titre, onFermer: onFermer),
              Ecart.vSm,
              Expanded(child: enfant),
              // Web etroit : le chevron de bas de volet (image CLV-07-08-10).
              if (forme == FormePanneau.volet)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
                      child: Icon(AppIcons.suiteEnBas.repos),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.titre, required this.onFermer});

  final String titre;
  final VoidCallback? onFermer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? fermer = onFermer;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette.inkStrong.applyTo(
                  Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
                ),
              ),
            ),
          ),
          if (fermer != null)
            Pressable(
              onPress: fermer,
              libelleSemantique: t.salle.seance.fermerPanneau,
              arrondiFocus: AppRadius.arrondiFull,
              child: SizedBox.square(
                dimension: AppSpacing.titreEcran,
                child: Center(
                  child: IconTheme(
                    data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(AppIcons.fermer.repos),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
