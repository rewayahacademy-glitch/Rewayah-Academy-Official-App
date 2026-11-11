// Lot SUPPORTS-ETAGERE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : la
// couverture d'un support, comme un livre pose sur une etagere.
//
// Un seul composant pour tout support (le Coran, le livre des lettres, une
// fiche) : la salle, la Bibliotheque et plus tard « Ma classe » le posent tel
// quel. Le Coran a sa couverture propre, sobre : double cadre, ornement plus
// grand, aucune image de mushaf reel (aucune n'est fournie, aucune n'est
// inventee).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tc_bibliotheque/couverture_ressource.dart';
import '../tc_bibliotheque/library_resource.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'brand_logo.dart' show FondLogo;
import 'ornement_marque.dart';

/// La couverture d'un support : un livre, avec son dos, son cadre et une
/// etiquette qui porte l'ornement de la marque et le titre.
///
/// **Aucune couleur n'est posee ici** : la teinte vient des paires du theme
/// ([teinteDe] : `surfaceQuran` pour le Coran, la palette administree
/// `teintesIdentite` pour les autres), l'etiquette est `surfaceRaised`, donc
/// lisible dans les deux themes. Le cadre et le dos reprennent l'encre de la
/// teinte, attenuee.
///
/// Le titre ecrit sur la couverture se reduit pour tenir (texte agrandi a
/// 200 %, 320 points) ; il est aussi lu en entier par le lecteur d'ecran :
/// la couverture se lit d'un coup d'oeil, elle ne se dechiffre pas.
class CouvertureSupport extends StatelessWidget {
  /// Cree une couverture.
  const CouvertureSupport({
    required this.titre,
    required this.couverture,
    this.mention,
    super.key,
  });

  /// Le titre ecrit sur la couverture.
  final String titre;

  /// La teinte et le type, calcules une fois pour toutes
  /// ([CouvertureRessource]) : la meme ressource a toujours la meme
  /// couverture.
  final CouvertureRessource couverture;

  /// Une mention courte sous le titre (« A valider »), ou `null`.
  final String? mention;

  /// Le rapport largeur sur hauteur : celui d'un livre, jamais un carre.
  static const double rapport = 3 / 4;

  /// La part de l'encre reprise par le cadre et le dos.
  static const double opaciteFilet = 0.32;

  /// La paire d'une teinte de couverture. L'index 0 est celui du Coran
  /// (`surfaceQuran`, employee nulle part ailleurs) ; les autres viennent de
  /// `AppPalette.teintesIdentite` (decision D-18).
  static AppColorPair teinteDe(AppPalette palette, int index) =>
      index == 0 ? palette.surfaceQuran : palette.teinteCouverture(index - 1);

  /// Vrai pour la couverture du Coran.
  bool get coran => couverture.type == TypeRessource.quran;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair teinte = teinteDe(palette, couverture.indexTeinte);
    final Color filet = teinte.onBackground.withValues(alpha: opaciteFilet);
    final String? mention = this.mention;

    return Semantics(
      label: mention == null ? titre : '$titre, $mention',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: rapport,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) {
            final double largeur = contraintes.maxWidth;
            // Le dos du livre : une bande au debut de la ligne (a droite en
            // arabe), un douzieme de la largeur.
            final double dos = largeur / 12;
            final double marge = largeur / 18;
            return DecoratedBox(
              decoration: teinte.decoration(borderRadius: AppRadius.arrondiXs),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    width: dos,
                    child: ColoredBox(color: filet),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      dos + marge,
                      marge,
                      marge,
                      marge,
                    ),
                    child: _Cadre(
                      couleur: filet,
                      doubleFilet: coran,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(marge / 2),
                          child: _Etiquette(
                            titre: titre,
                            mention: mention,
                            coran: coran,
                            palette: palette,
                            textes: textes,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Le cadre de la couverture : un filet, deux pour le Coran.
class _Cadre extends StatelessWidget {
  const _Cadre({
    required this.couleur,
    required this.doubleFilet,
    required this.child,
  });

  final Color couleur;
  final bool doubleFilet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderSide trait = BorderSide(color: couleur);
    final Widget simple = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(trait),
        borderRadius: AppRadius.arrondiXs,
      ),
      child: child,
    );
    if (!doubleFilet) return simple;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(trait),
        borderRadius: AppRadius.arrondiXs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: simple,
      ),
    );
  }
}

/// L'etiquette : l'ornement de la marque, le titre, la mention.
class _Etiquette extends StatelessWidget {
  const _Etiquette({
    required this.titre,
    required this.mention,
    required this.coran,
    required this.palette,
    required this.textes,
  });

  final String titre;
  final String? mention;
  final bool coran;
  final AppPalette palette;
  final TextTheme textes;

  /// La largeur du mot le plus long du titre, au style de l'etiquette.
  double _motLePlusLong(BuildContext context) {
    final TextStyle style = textes.titleSmall ?? const TextStyle();
    double largeur = 0;
    for (final String mot in titre.split(RegExp(r'\s+'))) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      largeur = math.max(largeur, peintre.width.ceilToDouble());
      peintre.dispose();
    }
    return largeur;
  }

  @override
  Widget build(BuildContext context) {
    final AppColorPair etiquette = palette.surfaceRaised;
    final String? mention = this.mention;
    return DecoratedBox(
      decoration: etiquette.decoration(borderRadius: AppRadius.arrondiXs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        // Le titre passe a la ligne dans toute la largeur de l'etiquette ; il
        // ne se reduit que si la hauteur manque (texte agrandi, 320 points) :
        // jamais de debordement.
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              // Jamais un mot coupe : l'etiquette prend au moins la largeur
              // du mot le plus long, puis le tout se reduit pour tenir.
              width: math.max(c.maxWidth, _motLePlusLong(context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // README du logo : l'ornement est un motif decoratif ; violet
                  // sur fond clair, blanc sur fond sombre.
                  OrnementMarque(
                    taille: coran ? TailleOrnement.moyen : TailleOrnement.petit,
                    fond: palette.estSombre ? FondLogo.violet : FondLogo.page,
                  ),
                  Ecart.vSm,
                  Text(
                    titre,
                    textAlign: TextAlign.center,
                    style: etiquette.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                  if (mention != null) ...<Widget>[
                    Ecart.vSm,
                    DecoratedBox(
                      decoration: palette.washWarning.decoration(
                        borderRadius: AppRadius.arrondiFull,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          mention,
                          style: palette.washWarning.applyTo(
                            textes.labelSmall ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
