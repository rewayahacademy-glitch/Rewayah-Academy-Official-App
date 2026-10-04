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
import '../../core/widgets/menu_actions.dart';
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
          child: _HauteurMinimale(
            actif: !ajuste,
            minimum: _hauteurInterieure(context, forme: forme),
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
                if (ajuste)
                  Flexible(child: enfant)
                else
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
      ),
    );
    if (!ajuste) return cadre;
    return Align(alignment: AlignmentDirectional.topCenter, child: cadre);
  }

  /// La hauteur sous laquelle le panneau ne se tasse pas : sa tete (poignee,
  /// titre ou croix, mesure du titre tel qu'il est rendu, une seule ligne)
  /// plus une rangee de contenu a l'echelle courante du texte. La salle
  /// reduit d'abord le support visible au-dessus de la feuille pour la lui
  /// laisser ([supportVisiblePour]) ; s'il manque encore de la place, le
  /// panneau defile au lieu d'etre rogne.
  static double hauteurMinimale(
    BuildContext context, {
    required FormePanneau forme,
  }) {
    final bool feuille = forme == FormePanneau.feuille;
    // Marge haute du cadre, puis l'interieur.
    return (feuille ? AppSpacing.sm : AppSpacing.md) +
        _hauteurInterieure(context, forme: forme);
  }

  /// [hauteurMinimale] sans la marge haute du cadre : poignee (feuille),
  /// titre ou croix, ecart, une rangee de contenu.
  static double _hauteurInterieure(
    BuildContext context, {
    required FormePanneau forme,
  }) {
    final bool feuille = forme == FormePanneau.feuille;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: DefaultTextStyle.of(context).style
            .merge(Theme.of(context).textTheme.titleLarge),
      ),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    final double ligne = p.height;
    p.dispose();
    return (feuille ? AppBottomSheet.hauteurPoignee + AppSpacing.sm : 0) +
        (ligne > AppSpacing.titreEcran ? ligne : AppSpacing.titreEcran) +
        AppSpacing.sm +
        echelle.scale(AppSpacing.respiration);
  }
}

/// Le support laisse visible au-dessus de la feuille du telephone dans une
/// hauteur [disponible] : [supportVisibleSousFeuille], reduit (jusqu'a zero)
/// pour que la feuille garde sa [PanneauSeance.hauteurMinimale].
double supportVisiblePour(BuildContext context, double disponible) {
  if (!disponible.isFinite) return supportVisibleSousFeuille;
  final double reste =
      disponible -
      PanneauSeance.hauteurMinimale(context, forme: FormePanneau.feuille);
  if (reste >= supportVisibleSousFeuille) return supportVisibleSousFeuille;
  return reste > 0 ? reste : 0;
}

/// Quand la place laissee au panneau est plus basse que [minimum] (feuille
/// ecrasee sous un en-tete de salle haut, 320 px a 200 %), le panneau garde
/// sa hauteur minimale et DEFILE : son contenu reste joignable (la liste
/// defile a l'interieur, le panneau entier autour), rien n'est rogne. Avec
/// assez de place, rien ne change.
class _HauteurMinimale extends StatelessWidget {
  const _HauteurMinimale({
    required this.actif,
    required this.minimum,
    required this.child,
  });

  final bool actif;
  final double minimum;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!actif) return child;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) =>
          !c.maxHeight.isFinite || c.maxHeight >= minimum
          ? child
          : SingleChildScrollView(
              key: const ValueKey<String>('panneau-seance-defile'),
              child: SizedBox(height: minimum, child: child),
            ),
    );
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
  Widget build(BuildContext context) => MenuActions(
    key: const ValueKey<String>('menu-panneau-seance'),
    tooltip: t.salle.seance.optionsPanneau(titre: titre),
    points: true,
    actions: <EntreeAction>[
      EntreeAction(libelle: t.salle.seance.fermerPanneau, onChoix: onFermer),
    ],
  );
}
