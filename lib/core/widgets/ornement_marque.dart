import 'package:flutter/material.dart';

import '../marque/dessin_ornement.dart';
import '../marque/ornement_traces.g.dart';
import '../marque/peinture_ornement.dart';
import '../theme/app_spacing.dart';
import 'brand_logo.dart';

/// La taille d'un ornement : une hauteur de l'echelle d'espacement, jamais une
/// valeur libre (`docs/current/BRAND-ORN-1.md`, section 3).
enum TailleOrnement {
  /// 16 : dans un etat vide, entre deux elements serres.
  petit(AppSpacing.lg),

  /// 24 : un separateur de section, un en-tete.
  moyen(AppSpacing.xxl),

  /// 32 : au plus, hors cadre de page.
  grand(AppSpacing.xxxl);

  const TailleOrnement(this.hauteur);

  /// La hauteur du dessin.
  final double hauteur;
}

/// Le dessin de l'ornement.
enum VarianteOrnement {
  /// `ornement-plein.svg`.
  plein,

  /// `ornement-contour.svg`.
  contour;

  /// Le dessin genere.
  DessinOrnement get dessin => switch (this) {
    VarianteOrnement.plein => ornementPlein,
    VarianteOrnement.contour => ornementContour,
  };
}

/// L'ornement de la marque, signature discrete (BRAND-ORN-1).
///
/// **Seul point d'entree de l'ornement dans un ecran**, comme [BrandLogo] pour
/// le logo : le dessin est celui des SVG du directeur, recopie mot pour mot
/// dans `ornement_traces.g.dart` par `tool/generer_ornement.dart` et peint par
/// un `CustomPainter` dans son propre `RepaintBoundary`. Aucun asset charge.
///
/// Il est **decoratif** : retire de l'arbre semantique, jamais cliquable,
/// jamais derriere un texte. La couleur vient du fond qui le porte
/// ([FondLogo], la meme regle que le logo : violet de marque sur la page,
/// blanc sur une bande violette, encre a l'impression).
class OrnementMarque extends StatelessWidget {
  /// Cree un ornement.
  const OrnementMarque({
    this.taille = TailleOrnement.petit,
    this.variante = VarianteOrnement.plein,
    this.fond = FondLogo.page,
    this.opacite = 1,
    super.key,
  });

  /// La signature discrete d'un ecran : petite, a [opaciteSignature]. Elle
  /// ancre la marque sans encombrer ; jamais sur un ecran de travail.
  const OrnementMarque.signature({this.fond = FondLogo.page, super.key})
    : taille = TailleOrnement.petit,
      variante = VarianteOrnement.plein,
      opacite = opaciteSignature;

  /// L'opacite de la signature : un repere, pas un motif. Une valeur unique,
  /// fixee ici, jamais choisie ecran par ecran.
  static const double opaciteSignature = 0.4;

  /// L'opacite du dessin, entre 0 et 1 : une seule couleur, en une seule passe
  /// (aucun recouvrement).
  final double opacite;

  /// La hauteur du dessin.
  final TailleOrnement taille;

  /// Plein ou contour.
  final VarianteOrnement variante;

  /// Le fond qui porte l'ornement, d'ou sa couleur.
  final FondLogo fond;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PeintreOrnement(
          dessin: variante.dessin,
          hauteur: taille.hauteur,
          couleur: BrandLogo.couleur(fond).withValues(alpha: opacite),
        ),
        size: Size(taille.hauteur * variante.dessin.proportion, taille.hauteur),
      ),
    ),
  );
}

class _PeintreOrnement extends CustomPainter {
  _PeintreOrnement({
    required this.dessin,
    required this.hauteur,
    required this.couleur,
  });

  final DessinOrnement dessin;
  final double hauteur;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) => peindreOrnement(
    canvas,
    dessin,
    size.center(Offset.zero),
    hauteur,
    Paint()
      ..color = couleur
      ..isAntiAlias = true,
  );

  @override
  bool shouldRepaint(_PeintreOrnement ancien) =>
      ancien.dessin != dessin ||
      ancien.hauteur != hauteur ||
      ancien.couleur != couleur;
}
