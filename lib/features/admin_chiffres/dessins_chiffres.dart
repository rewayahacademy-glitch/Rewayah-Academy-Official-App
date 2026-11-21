/// CHIFFRES-ACADEMIE : les dessins des cartes.
///
/// LEGERETE (directeur, 20/11/2026 : « mon PC est un Core i3 ») : chaque
/// dessin est un `CustomPainter` a plat (traits et aplats, ni flou, ni ombre,
/// ni degrade, ni image), sans aucune animation, isole par un
/// `RepaintBoundary` et repeint seulement quand sa donnee ou ses couleurs
/// changent (`shouldRepaint`).
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_spacing.dart';

/// Les couleurs d'un dessin, lues dans la palette par la page.
@immutable
class CouleursDessin {
  /// Cree le jeu de couleurs.
  const CouleursDessin({
    required this.plein,
    required this.doux,
    required this.piste,
    required this.second,
    required this.fond,
    required this.trait,
  });

  /// La couleur de la valeur.
  final Color plein;

  /// La meme famille, plus pale (les jours passes).
  final Color doux;

  /// Ce qui reste a remplir.
  final Color piste;

  /// La seconde part d'un partage.
  final Color second;

  /// Le fond de la carte (le coeur du curseur).
  final Color fond;

  /// Le contour du curseur.
  final Color trait;

  @override
  bool operator ==(Object other) =>
      other is CouleursDessin &&
      other.plein == plein &&
      other.doux == doux &&
      other.piste == piste &&
      other.second == second &&
      other.fond == fond &&
      other.trait == trait;

  @override
  int get hashCode => Object.hash(plein, doux, piste, second, fond, trait);
}

/// Pose un dessin : taille fixe, isole, decrit au lecteur d'ecran par
/// [libelle] (ou ignore quand le chiffre de la carte dit deja tout).
class Dessin extends StatelessWidget {
  /// Cree le cadre d'un dessin.
  const Dessin({
    required this.peintre,
    required this.taille,
    super.key,
    this.libelle,
  });

  /// Ce qui dessine.
  final CustomPainter peintre;

  /// La taille du dessin.
  final Size taille;

  /// Ce que le dessin dit, quand il dit plus que le chiffre.
  final String? libelle;

  @override
  Widget build(BuildContext context) {
    final Widget dessin = RepaintBoundary(
      child: CustomPaint(size: taille, painter: peintre),
    );
    final String? l = libelle;
    return l == null
        ? ExcludeSemantics(child: dessin)
        : Semantics(label: l, image: true, child: dessin);
  }
}

/// Le pas d'un point (son diametre plus l'espace).
const double pasPoint = AppSpacing.md;

/// Le nombre de points au-dela duquel la matrice ne se dessine plus : un
/// point vaut UNE unite, jamais une proportion.
const int pointsMax = 60;

/// La taille de la matrice de [n] points dans [largeur].
Size taillePoints(int n, double largeur) {
  final int parRangee = math.max(1, (largeur / pasPoint).floor());
  final int rangees = (n / parRangee).ceil();
  return Size(math.min(n, parRangee) * pasPoint, rangees * pasPoint);
}

/// Un point par unite : [n] points, rangee par rangee dans le sens de
/// lecture.
class PeintrePoints extends CustomPainter {
  /// Cree la matrice.
  const PeintrePoints({
    required this.n,
    required this.couleurs,
    required this.versLaGauche,
  });

  /// Le nombre de points.
  final int n;

  /// Les couleurs.
  final CouleursDessin couleurs;

  /// Vrai en arabe : la premiere colonne est a droite.
  final bool versLaGauche;

  @override
  void paint(Canvas canvas, Size size) {
    final int parRangee = math.max(1, (size.width / pasPoint).round());
    final Paint p = Paint()..color = couleurs.plein;
    const double rayon = pasPoint / 2 - AppSpacing.xs / 2;
    for (int i = 0; i < n; i++) {
      final int colonne = i % parRangee;
      final int rangee = i ~/ parRangee;
      final double x = colonne * pasPoint + pasPoint / 2;
      canvas.drawCircle(
        Offset(
          versLaGauche ? size.width - x : x,
          rangee * pasPoint + pasPoint / 2,
        ),
        rayon,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(PeintrePoints ancien) =>
      ancien.n != n ||
      ancien.couleurs != couleurs ||
      ancien.versLaGauche != versLaGauche;
}

/// Les colonnes des derniers jours : la derniere (aujourd'hui) en plein.
class PeintreColonnes extends CustomPainter {
  /// Cree les colonnes.
  const PeintreColonnes({
    required this.valeurs,
    required this.couleurs,
    required this.versLaGauche,
  });

  /// Une valeur par jour, du plus ancien a aujourd'hui.
  final List<int> valeurs;

  /// Les couleurs.
  final CouleursDessin couleurs;

  /// Vrai en arabe : le temps avance vers la gauche.
  final bool versLaGauche;

  @override
  void paint(Canvas canvas, Size size) {
    if (valeurs.isEmpty) return;
    final int max = valeurs.reduce(math.max);
    final double pas = size.width / valeurs.length;
    final double largeur = pas * 0.6;
    const double plancher = AppSpacing.xs;
    final Paint p = Paint();
    for (int i = 0; i < valeurs.length; i++) {
      final double h = max == 0
          ? plancher
          : math.max(plancher, size.height * valeurs[i] / max);
      final double x = i * pas + (pas - largeur) / 2;
      p.color = i == valeurs.length - 1 ? couleurs.plein : couleurs.doux;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            versLaGauche ? size.width - x - largeur : x,
            size.height - h,
            largeur,
            h,
          ),
          const Radius.circular(AppSpacing.xs),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(PeintreColonnes ancien) =>
      ancien.couleurs != couleurs ||
      ancien.versLaGauche != versLaGauche ||
      !_memes(ancien.valeurs, valeurs);

  static bool _memes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Un anneau : la part [part] (0 a 1) en plein sur sa piste.
class PeintreAnneau extends CustomPainter {
  /// Cree l'anneau.
  const PeintreAnneau({required this.part, required this.couleurs});

  /// La part remplie, de 0 a 1.
  final double part;

  /// Les couleurs.
  final CouleursDessin couleurs;

  static const double _epaisseur = AppSpacing.sm;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double rayon = (math.min(size.width, size.height) - _epaisseur) / 2;
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _epaisseur
      ..color = couleurs.piste;
    canvas.drawCircle(centre, rayon, p);
    if (part <= 0) return;
    p
      ..color = couleurs.plein
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon),
      -math.pi / 2,
      2 * math.pi * part.clamp(0, 1),
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(PeintreAnneau ancien) =>
      ancien.part != part || ancien.couleurs != couleurs;
}

/// Une jauge en arc graduee : des traits, pleins jusqu'a [part].
class PeintreArcGradue extends CustomPainter {
  /// Cree la jauge.
  const PeintreArcGradue({
    required this.part,
    required this.couleurs,
    required this.versLaGauche,
  });

  /// La part remplie, de 0 a 1.
  final double part;

  /// Les couleurs.
  final CouleursDessin couleurs;

  /// Vrai en arabe : la jauge se remplit de droite a gauche.
  final bool versLaGauche;

  static const int _traits = 31;

  @override
  void paint(Canvas canvas, Size size) {
    final double rayon = size.width / 2;
    final Offset centre = Offset(size.width / 2, rayon);
    final Paint p = Paint()
      ..strokeWidth = AppSpacing.xs - 1
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < _traits; i++) {
      final double t = i / (_traits - 1);
      final double angle = math.pi * (versLaGauche ? -t : 1 + t);
      final Offset d = Offset(math.cos(angle), math.sin(angle));
      p.color = t <= part && part > 0 ? couleurs.plein : couleurs.piste;
      canvas.drawLine(
        centre + d * (rayon - 1),
        centre + d * (rayon - AppSpacing.md),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(PeintreArcGradue ancien) =>
      ancien.part != part ||
      ancien.couleurs != couleurs ||
      ancien.versLaGauche != versLaGauche;
}

/// Une barre segmentee : [n] segments pleins sur [total].
class PeintreSegments extends CustomPainter {
  /// Cree la barre.
  const PeintreSegments({
    required this.n,
    required this.total,
    required this.couleurs,
    required this.versLaGauche,
  });

  /// Les segments pleins.
  final int n;

  /// Tous les segments.
  final int total;

  /// Les couleurs.
  final CouleursDessin couleurs;

  /// Vrai en arabe : le premier segment est a droite.
  final bool versLaGauche;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final double pas = size.width / total;
    final double largeur = pas * 0.6;
    final Paint p = Paint();
    for (int i = 0; i < total; i++) {
      final double x = i * pas + (pas - largeur) / 2;
      p.color = i < n ? couleurs.plein : couleurs.piste;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            versLaGauche ? size.width - x - largeur : x,
            0,
            largeur,
            size.height,
          ),
          Radius.circular(largeur / 2),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(PeintreSegments ancien) =>
      ancien.n != n ||
      ancien.total != total ||
      ancien.couleurs != couleurs ||
      ancien.versLaGauche != versLaGauche;
}

/// Un partage en deux parts a plat, avec un curseur a la frontiere.
class PeintrePartage extends CustomPainter {
  /// Cree la barre.
  const PeintrePartage({
    required this.part,
    required this.couleurs,
    required this.versLaGauche,
  });

  /// La premiere part, de 0 a 1.
  final double part;

  /// Les couleurs.
  final CouleursDessin couleurs;

  /// Vrai en arabe : la premiere part est a droite.
  final bool versLaGauche;

  @override
  void paint(Canvas canvas, Size size) {
    const double epaisseur = AppSpacing.sm;
    final double rayon = size.height / 2;
    final double y = size.height / 2;
    final double debut = rayon;
    final double fin = size.width - rayon;
    final double frontiere = debut + (fin - debut) * part.clamp(0, 1);
    double x(double v) => versLaGauche ? size.width - v : v;
    final Paint p = Paint()
      ..strokeWidth = epaisseur
      ..strokeCap = StrokeCap.round
      ..color = couleurs.second;
    canvas.drawLine(Offset(x(debut), y), Offset(x(fin), y), p);
    p.color = couleurs.plein;
    canvas.drawLine(Offset(x(debut), y), Offset(x(frontiere), y), p);
    canvas.drawCircle(
      Offset(x(frontiere), y),
      rayon,
      Paint()..color = couleurs.trait,
    );
    canvas.drawCircle(
      Offset(x(frontiere), y),
      rayon - (AppSpacing.xs - 1),
      Paint()..color = couleurs.fond,
    );
  }

  @override
  bool shouldRepaint(PeintrePartage ancien) =>
      ancien.part != part ||
      ancien.couleurs != couleurs ||
      ancien.versLaGauche != versLaGauche;
}
