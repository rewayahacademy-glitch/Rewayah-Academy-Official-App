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

/// La largeur de la colonne en desktop (image CLV-07 : ≈ 328 a 1440 de large,
/// le support gardant son titre sur deux lignes).
const double largeurColonneSeance = AppSpacing.respiration * 5 + AppSpacing.sm;

/// La colonne Supports en desktop (image CLV-08 : ≈ 328 a 1440 de large,
/// comme la colonne Eleves ; le titre du support garde ses deux lignes).
const double largeurColonneSupportsSeance = largeurColonneSeance;

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
    this.enMenu = false,
    this.ajusteAuContenu = false,
    super.key,
  });

  final String titre;
  final VoidCallback? onFermer;

  /// Image CLV-07 desktop : un menu « … » (Fermer le panneau) a la place de
  /// la croix. Colonne seulement.
  final bool enMenu;

  /// Image CLV-07 desktop : la colonne s'arrete apres la liste au lieu de
  /// descendre jusqu'en bas. L'[enfant] doit alors se mesurer (liste
  /// `shrinkWrap`). Colonne seulement.
  final bool ajusteAuContenu;

  /// Le contenu, deja defilant (une liste) ou court.
  final Widget enfant;
  final FormePanneau forme;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool feuille = forme == FormePanneau.feuille;
    final bool colonne = forme == FormePanneau.colonne;
    final bool ajuste = colonne && ajusteAuContenu;
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
    final Widget cadre = Semantics(
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
            mainAxisSize: ajuste ? MainAxisSize.min : MainAxisSize.max,
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
              _EnTete(
                titre: titre,
                onFermer: onFermer,
                enMenu: colonne && enMenu,
              ),
              Ecart.vSm,
              if (ajuste) Flexible(child: enfant) else Expanded(child: enfant),
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
    if (!ajuste) return cadre;
    return Align(alignment: AlignmentDirectional.topCenter, child: cadre);
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.titre,
    required this.onFermer,
    required this.enMenu,
  });

  final String titre;
  final VoidCallback? onFermer;
  final bool enMenu;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? fermer = onFermer;
    if (enMenu && fermer != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            Expanded(child: _Titre(titre: titre)),
            _MenuPanneau(titre: titre, onFermer: fermer),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: _Titre(titre: titre)),
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

class _Titre extends StatelessWidget {
  const _Titre({required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      titre,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppPalette.of(context).inkStrong
          .applyTo(Theme.of(context).textTheme.titleLarge ?? const TextStyle()),
    ),
  );
}

/// Le menu « … » de la colonne desktop (image CLV-07) : une seule entree,
/// « Fermer le panneau ».
class _MenuPanneau extends StatelessWidget {
  const _MenuPanneau({required this.titre, required this.onFermer});

  final String titre;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color? encre = palette.inkStrong
        .asIconTheme(size: AppSpacing.xs)
        .color;
    Widget point() => SizedBox.square(
      dimension: AppSpacing.xs,
      child: DecoratedBox(
        decoration: BoxDecoration(color: encre, shape: BoxShape.circle),
      ),
    );
    return PopupMenuButton<int>(
      key: const ValueKey<String>('menu-panneau-seance'),
      tooltip: t.salle.seance.optionsPanneau(titre: titre),
      position: PopupMenuPosition.under,
      onSelected: (int _) => onFermer(),
      itemBuilder: (BuildContext _) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(value: 0, child: Text(t.salle.seance.fermerPanneau)),
      ],
      child: SizedBox.square(
        dimension: AppSpacing.titreEcran,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: <Widget>[point(), point(), point()],
          ),
        ),
      ),
    );
  }
}
