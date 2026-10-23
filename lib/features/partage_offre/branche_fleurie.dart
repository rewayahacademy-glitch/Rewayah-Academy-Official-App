// La branche fleurie de la carte des femmes (CAND-06) : un ornement feminin tres
// discret, sans aucun personnage.
//
// **Direction du directeur (23/10/2026)** : la carte des femmes ne porte aucune
// figure humaine ; « juste des elements feminins comme des fleurs discretes ou un
// ornement feminin (tout discret) ». C'est donc une fine branche, tracee en
// trait : une tige courbe, deux brins plus courts, des feuilles en amande et
// trois petites fleurs a cinq petales, avec deux boutons.
//
// **Dans la penombre, au bord du faisceau (directeur, 23/10/2026, la lumiere et
// les tenebres)** : la branche longe le bord haut du faisceau de lumiere, du cote
// des tenebres, a quelques points de lui, et entre par le bord de la carte
// oppose a la porte. Elle ne coupe jamais la lumiere : chaque point de son
// dessin est hors du faisceau, et jamais sous un texte, le QR ou le logo. Elle
// est tracee dans son propre repere (la tige le long de l'axe x, les brins vers
// les y negatifs) puis posee par [BrancheFleurie.new] sur une ligne, avec un
// angle : la geometrie de la scene la pose parallele au bord du faisceau.
//
// **Ton sur ton, en second regard** : tout est de la couleur de la lumiere qui
// s'attenue (`AppPaletteCarte.coeur`) a faible opacite ([opacite]), donc a faible
// contraste dans la penombre ; le centre des fleurs est troue. **Aucun degrade**
// : des traits et des aplats. Une illustration, comme la porte : le symbole
// officiel n'est pas touche (`M-28`, les ornements servent de decor sur les
// supports de reseaux sociaux).
library;

import 'dart:math' as math;
import 'dart:ui';

/// Une courbe de Bezier cubique : la tige, un brin.
class _Cubique {
  const _Cubique(this.p0, this.p1, this.p2, this.p3);

  final Offset p0;
  final Offset p1;
  final Offset p2;
  final Offset p3;

  /// Le point de la courbe au parametre [t], de 0 (le debut) a 1 (la fin).
  Offset en(double t) {
    final double u = 1 - t;
    return p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
  }

  /// La direction de la courbe en [t] (un angle, en radians).
  double angleEn(double t) {
    final double u = 1 - t;
    final Offset d =
        (p1 - p0) * (3 * u * u) +
        (p2 - p1) * (6 * u * t) +
        (p3 - p2) * (3 * t * t);
    return d.direction;
  }

  /// La courbe comme un trace : de [p0] a [p3].
  void ajouteA(Path chemin) {
    chemin
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
  }
}

/// Une fleur a cinq petales : son [centre], son [rayon] (du centre a la pointe
/// d'un petale) et l'angle [angle] du premier petale.
class FleurDeBranche {
  /// Cree la fleur.
  const FleurDeBranche(this.centre, this.rayon, this.angle);

  /// Le centre de la fleur.
  final Offset centre;

  /// Le rayon : du centre a la pointe d'un petale.
  final double rayon;

  /// L'angle du premier petale (radians) : chaque fleur est tournee un peu
  /// autrement, pour que la branche ne soit pas une frise.
  final double angle;

  /// Le rayon du trou central : le chemin y apparait, sans autre couleur.
  double get rayonCentre => 0.2 * rayon;

  /// Un point dans le petale numero [i] (de 0 a 4), a 65 pour cent de son
  /// rayon : la ou le petale est sans doute plein.
  Offset pointDePetale(int i) =>
      centre + Offset.fromDirection(angle + i * 2 * math.pi / 5, 0.65 * rayon);

  /// Les cinq petales, en un seul trace : cinq gouttes, la pointe vers
  /// l'exterieur.
  Path get petales {
    final Path p = Path();
    for (int i = 0; i < 5; i++) {
      final double a = angle + i * 2 * math.pi / 5;
      final Offset dir = Offset.fromDirection(a);
      final Offset nor = Offset.fromDirection(a + math.pi / 2);
      final Offset pointe = centre + dir * rayon;
      p
        ..moveTo(centre.dx, centre.dy)
        ..cubicTo(
          (centre + dir * 0.3 * rayon + nor * 0.5 * rayon).dx,
          (centre + dir * 0.3 * rayon + nor * 0.5 * rayon).dy,
          (centre + dir * 0.9 * rayon + nor * 0.46 * rayon).dx,
          (centre + dir * 0.9 * rayon + nor * 0.46 * rayon).dy,
          pointe.dx,
          pointe.dy,
        )
        ..cubicTo(
          (centre + dir * 0.9 * rayon - nor * 0.46 * rayon).dx,
          (centre + dir * 0.9 * rayon - nor * 0.46 * rayon).dy,
          (centre + dir * 0.3 * rayon - nor * 0.5 * rayon).dx,
          (centre + dir * 0.3 * rayon - nor * 0.5 * rayon).dy,
          centre.dx,
          centre.dy,
        )
        ..close();
    }
    return p;
  }
}

/// Un bouton de fleur : une petite goutte pleine au bout d'un pedoncule, dans le
/// sens du pedoncule.
class Bouton {
  /// Cree le bouton, centre en [centre], long de deux fois [rayon], pointe vers
  /// [angle] (radians).
  const Bouton(this.centre, this.rayon, this.angle);

  /// Le centre du bouton.
  final Offset centre;

  /// La demi-longueur du bouton.
  final double rayon;

  /// La direction du pedoncule, au bout duquel il est pose.
  final double angle;

  /// Le bouton : une amande ronde, pointe dans la direction du pedoncule.
  Path get forme {
    final Offset dir = Offset.fromDirection(angle);
    final Offset nor = Offset.fromDirection(angle + math.pi / 2);
    final Offset base = centre - dir * rayon;
    final Offset pointe = centre + dir * rayon;
    final Offset c1 = centre + nor * 1.4 * rayon;
    final Offset c2 = centre - nor * 1.4 * rayon;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, pointe.dx, pointe.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
      ..close();
  }
}

/// La branche fleurie, dans le repere de la carte : le trait des tiges, les
/// feuilles, les fleurs et les boutons.
class BrancheFleurie {
  /// Dessine la branche, posee sur la ligne qui part de [depart] avec l'angle
  /// [angle] (radians, dans le repere de la carte : 0 pour une ligne qui va vers
  /// la droite, negatif pour une ligne qui monte), a l'echelle [echelle].
  ///
  /// Le dessin est pense dans son propre repere (x le long de la tige, 130
  /// points de long a l'echelle 1 ; y negatif vers les fleurs) puis tourne et
  /// pose : il suit la ligne, quelle que soit sa pente.
  factory BrancheFleurie({
    required Offset depart,
    required double angle,
    double echelle = 1,
  }) {
    final double s = echelle;
    final double cosA = math.cos(angle);
    final double sinA = math.sin(angle);
    Offset d(double x, double y) =>
        Offset((x * cosA - y * sinA) * s, (x * sinA + y * cosA) * s);
    Offset p(double x, double y) => depart + d(x, y);

    // La tige : elle entre par le bord de la carte et se poursuit en deux
    // courbes tres douces, presque droites, le long de la ligne.
    final _Cubique tige1 = _Cubique(p(0, 0), p(26, -3), p(52, 3), p(78, -1));
    final _Cubique tige2 = _Cubique(
      tige1.p3,
      tige1.p3 + (tige1.p3 - tige1.p2),
      p(110, -5),
      p(130, -3),
    );
    // Deux brins qui montent, un peu a droite, comme une branche en fleurs.
    final Offset depart1 = tige1.en(0.4);
    final _Cubique brin1 = _Cubique(
      depart1,
      depart1 + d(3, -13),
      depart1 + d(8, -25),
      depart1 + d(15, -38),
    );
    final Offset depart2 = tige2.en(0.2);
    final _Cubique brin2 = _Cubique(
      depart2,
      depart2 + d(4, -11),
      depart2 + d(11, -19),
      depart2 + d(17, -27),
    );
    // Deux pedoncules courts, chacun finit par un bouton.
    final Offset departB1 = tige1.en(0.72);
    final _Cubique pedoncule1 = _Cubique(
      departB1,
      departB1 + d(-1, -4),
      departB1 + d(-3, -7),
      departB1 + d(-5, -10),
    );
    final Offset departB2 = brin1.en(0.62);
    final _Cubique pedoncule2 = _Cubique(
      departB2,
      departB2 + d(-2, -2),
      departB2 + d(-4, -4),
      departB2 + d(-7, -5),
    );

    final Path tiges = Path();
    for (final _Cubique c in <_Cubique>[
      tige1,
      tige2,
      brin1,
      brin2,
      pedoncule1,
      pedoncule2,
    ]) {
      c.ajouteA(tiges);
    }

    // Les feuilles : des amandes, posees de part et d'autre, la pointe en avant.
    final Path feuilles = Path();
    void feuille(_Cubique c, double t, double cote, double longueur) {
      final double l = longueur * s;
      final double largeur = 0.42 * l;
      final Offset base = c.en(t);
      final double a = c.angleEn(t) + cote * 0.85;
      final Offset dir = Offset.fromDirection(a);
      final Offset nor = Offset.fromDirection(a + math.pi / 2);
      final Offset pointe = base + dir * l;
      final Offset c1 = base + dir * (0.5 * l) + nor * largeur;
      final Offset c2 = base + dir * (0.5 * l) - nor * largeur;
      feuilles
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(c1.dx, c1.dy, pointe.dx, pointe.dy)
        ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
        ..close();
    }

    feuille(tige1, 0.14, -1, 10);
    feuille(tige1, 0.3, 1, 9);
    feuille(tige1, 0.58, -1, 10);
    feuille(tige1, 0.86, 1, 9);
    feuille(tige2, 0.42, -1, 9);
    feuille(tige2, 0.78, 1, 8);
    feuille(brin1, 0.3, -1, 8);
    feuille(brin1, 0.52, 1, 8);
    feuille(brin2, 0.48, -1, 7);
    feuille(brin2, 0.7, 1, 7);

    return BrancheFleurie._(
      tiges: tiges,
      feuilles: feuilles,
      fleurs: <FleurDeBranche>[
        FleurDeBranche(brin1.p3, 5.6 * s, -1.9 + angle),
        FleurDeBranche(brin2.p3, 4.7 * s, -1.2 + angle),
        FleurDeBranche(tige2.p3, 5.2 * s, -2.4 + angle),
      ],
      boutons: <Bouton>[
        Bouton(pedoncule1.p3, 2.6 * s, pedoncule1.angleEn(1)),
        Bouton(pedoncule2.p3, 2.4 * s, pedoncule2.angleEn(1)),
      ],
    );
  }

  const BrancheFleurie._({
    required this.tiges,
    required this.feuilles,
    required this.fleurs,
    required this.boutons,
  });

  /// L'opacite de la branche : celle d'un ton sur ton dans la penombre, au
  /// second regard.
  static const double opacite = 0.46;

  /// Le trait des tiges et des brins (a tracer, jamais a remplir).
  final Path tiges;

  /// Les feuilles en amande (a remplir).
  final Path feuilles;

  /// Les trois fleurs.
  final List<FleurDeBranche> fleurs;

  /// Les deux boutons, pleins.
  final List<Bouton> boutons;

  /// L'epaisseur du trait des tiges, en points : un fil.
  static const double epaisseurTige = 1.3;

  /// Tous les petales des fleurs, en un seul trace.
  Path get petales {
    final Path p = Path();
    for (final FleurDeBranche f in fleurs) {
      p.addPath(f.petales, Offset.zero);
    }
    return p;
  }

  /// Les boutons, en un seul trace.
  Path get boutonsPath {
    final Path p = Path();
    for (final Bouton b in boutons) {
      p.addPath(b.forme, Offset.zero);
    }
    return p;
  }

  /// Les trous centraux des fleurs, en un seul trace : la couleur du chemin y
  /// reparait.
  Path get centres {
    final Path p = Path();
    for (final FleurDeBranche f in fleurs) {
      p.addOval(Rect.fromCircle(center: f.centre, radius: f.rayonCentre));
    }
    return p;
  }

  /// Le plus petit rectangle qui contient la branche, trait compris.
  Rect get bornes {
    Rect r = tiges.getBounds().inflate(epaisseurTige / 2);
    r = r.expandToInclude(feuilles.getBounds());
    r = r.expandToInclude(petales.getBounds());
    return r.expandToInclude(boutonsPath.getBounds());
  }

  /// Des points regulierement espaces le long du trait des tiges, pour
  /// verifier ou la branche passe.
  List<Offset> pointsDesTiges({double pas = 3}) {
    final List<Offset> points = <Offset>[];
    for (final PathMetric m in tiges.computeMetrics()) {
      for (double d = 0; d <= m.length; d += pas) {
        points.add(m.getTangentForOffset(d)!.position);
      }
    }
    return points;
  }

  /// Des points regulierement espaces sur le contour de chaque feuille, pour
  /// verifier ou elles passent.
  List<Offset> pointsDesFeuilles({double pas = 2}) {
    final List<Offset> points = <Offset>[];
    for (final PathMetric m in feuilles.computeMetrics()) {
      for (double d = 0; d <= m.length; d += pas) {
        points.add(m.getTangentForOffset(d)!.position);
      }
    }
    return points;
  }
}
