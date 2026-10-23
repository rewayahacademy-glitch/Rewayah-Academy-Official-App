// Les ecrans de presentation du parcours (CAND-01) : avant les questions, le
// candidat, qui ne connait pas encore l'academie, lit trois ecrans courts en
// tuiles (grille Bento sur grand ecran, pile sur telephone), chacune avec son
// icone.
//
// Seulement ce qui est decide : l'academie enseigne le Coran en ligne, en
// classes stables ; trois seances par semaine aux memes horaires ; la
// candidature passe par la Salle d'examen, l'entretien en visio, la
// verification ; le retrait libre, des donnees protegees, femmes et hommes
// separes, une remuneration expliquee en pourcentage. Aucun chiffre de
// clientele, aucun temoignage, aucune promesse que le produit ne tient pas, et
// jamais « gratuit » ni « ne coute rien » sans une decision qui le dise (MOTS 1).
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/pile_cartes.dart';

/// Une tuile d'information : une icone, un titre court, une phrase.
class TuileInformation {
  /// Cree une tuile.
  const TuileInformation(this.icone, this.titre, this.texte);

  final AppIcon icone;
  final String titre;
  final String texte;
}

/// Le contenu des trois ecrans : titre, introduction, tuiles.
({String titre, String intro, List<TuileInformation> tuiles}) _contenu(
  int rang,
) {
  final p = t.recrutement.parcours.presentation;
  switch (rang) {
    case 1:
      return (
        titre: p.p1.titre,
        intro: p.p1.intro,
        tuiles: <TuileInformation>[
          TuileInformation(
            AppIcons.coran,
            p.p1.academie.titre,
            p.p1.academie.texte,
          ),
          TuileInformation(
            AppIcons.succes,
            p.p1.liberte.titre,
            p.p1.liberte.texte,
          ),
          TuileInformation(
            AppIcons.verrou,
            p.p1.donnees.titre,
            p.p1.donnees.texte,
          ),
          TuileInformation(
            AppIcons.classes,
            p.p1.separation.titre,
            p.p1.separation.texte,
          ),
        ],
      );
    case 2:
      return (
        titre: p.p2.titre,
        intro: p.p2.intro,
        tuiles: <TuileInformation>[
          TuileInformation(
            AppIcons.classes,
            p.p2.classe.titre,
            p.p2.classe.texte,
          ),
          TuileInformation(
            AppIcons.horloge,
            p.p2.horaires.titre,
            p.p2.horaires.texte,
          ),
          TuileInformation(AppIcons.camera, p.p2.visio.titre, p.p2.visio.texte),
          TuileInformation(
            AppIcons.paiements,
            p.p2.remuneration.titre,
            p.p2.remuneration.texte,
          ),
        ],
      );
    default:
      return (
        titre: p.p3.titre,
        intro: p.p3.intro,
        tuiles: <TuileInformation>[
          TuileInformation(
            AppIcons.cahier,
            p.p3.examen.titre,
            p.p3.examen.texte,
          ),
          TuileInformation(
            AppIcons.camera,
            p.p3.entretien.titre,
            p.p3.entretien.texte,
          ),
          TuileInformation(
            AppIcons.dossiers,
            p.p3.verification.titre,
            p.p3.verification.texte,
          ),
        ],
      );
  }
}

/// Le titre d'un ecran de presentation.
String titrePresentation(int rang) => _contenu(rang).titre;

/// L'introduction d'un ecran de presentation.
String intro(int rang) => _contenu(rang).intro;

/// Les tuiles d'un ecran de presentation, en pile (telephone) ou en grille
/// Bento (tablette et bureau).
class TuilesPresentation extends StatelessWidget {
  /// Cree les tuiles de l'ecran [rang] (1 a 3).
  const TuilesPresentation({required this.rang, super.key});

  /// Le rang de l'ecran.
  final int rang;

  /// La cle de la zone des tuiles.
  static const Key zoneKey = ValueKey<String>('presentation-tuiles');

  @override
  Widget build(BuildContext context) =>
      TuilesInformation(tuiles: _contenu(rang).tuiles);
}

/// Des tuiles d'information (trois ou quatre), en pile sur telephone, en grille
/// Bento sur grand ecran : la premiere est la tuile principale, large. Sert aux
/// ecrans de presentation du questionnaire et a l'introduction de « Vos autres
/// talents ».
class TuilesInformation extends StatelessWidget {
  /// Cree la zone de tuiles.
  const TuilesInformation({required this.tuiles, super.key});

  /// Les tuiles, la principale d'abord.
  final List<TuileInformation> tuiles;

  /// La hauteur d'une ligne de la grille Bento de presentation.
  static const double _hauteurLigne = AppPage.hauteurChoix + AppSpacing.section;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: TuilesPresentation.zoneKey,
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth < GrilleBento.seuilQuatreColonnes) {
          // Telephone : une pile de tuiles, l'icone a cote du texte.
          return PileCartes(
            children: <Widget>[
              for (final TuileInformation u in tuiles)
                _TuileHorizontale(tuile: u),
            ],
          );
        }
        return GrilleBento(
          // Les tuiles d'une meme bande prennent la meme hauteur, jamais moins
          // que leurs lignes : la grille se lit comme une composition, sans
          // trou sous la grande tuile.
          hauteurMinimale: true,
          hauteurDeLigne: _hauteurLigne,
          tuiles: <TuileBento>[
            for (final (int i, TuileInformation u) in tuiles.indexed)
              TuileBento(
                etendue: i == 0 ? EtendueBento.large : EtendueBento.carree,
                etendueLarge: _etendueLarge(i, tuiles.length),
                child: _TuileVerticale(tuile: u, premiere: i == 0),
              ),
          ],
        );
      },
    );
  }

  /// Quatre colonnes, deux bandes : la premiere porte la tuile principale,
  /// large, et ses voisines, plus etroites ; la seconde, une tuile en pleine
  /// largeur. Des tailles toutes differentes, sans trou (BENTO-1).
  static EtendueBento _etendueLarge(int i, int n) {
    if (n == 3) {
      return switch (i) {
        0 => const EtendueBento(3, 1),
        1 => EtendueBento.carree,
        _ => const EtendueBento(4, 1),
      };
    }
    return switch (i) {
      0 => EtendueBento.large,
      1 || 2 => EtendueBento.carree,
      _ => const EtendueBento(4, 1),
    };
  }
}

/// Le disque de l'icone d'une tuile : la teinte douce de l'accent.
class _Disque extends StatelessWidget {
  const _Disque({required this.icone});

  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppColorPair paire = AppPalette.of(context).washAccent;
    return SizedBox.square(
      dimension: AppSpacing.titreEcran,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: paire.background,
        ),
        child: Center(
          child: ExcludeSemantics(
            child: Icon(
              icone.actif,
              size: AppSpacing.xxxl - AppSpacing.sm,
              color: paire.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}

class _Textes extends StatelessWidget {
  const _Textes({required this.tuile, this.premiere = false});

  final TuileInformation tuile;
  final bool premiere;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          tuile.titre,
          style:
              (premiere ? textes.titleLarge : textes.titleMedium) ??
              const TextStyle(),
        ),
        Ecart.vXs,
        TexteSansCoupure(
          tuile.texte,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

class _TuileHorizontale extends StatelessWidget {
  const _TuileHorizontale({required this.tuile});

  final TuileInformation tuile;

  @override
  Widget build(BuildContext context) => BentoTile(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Disque(icone: tuile.icone),
        Ecart.hLg,
        Expanded(child: _Textes(tuile: tuile)),
      ],
    ),
  );
}

class _TuileVerticale extends StatelessWidget {
  const _TuileVerticale({required this.tuile, required this.premiere});

  final TuileInformation tuile;
  final bool premiere;

  @override
  Widget build(BuildContext context) => BentoTile(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Disque(icone: tuile.icone),
        Ecart.vLg,
        _Textes(tuile: tuile, premiere: premiere),
      ],
    ),
  );
}
