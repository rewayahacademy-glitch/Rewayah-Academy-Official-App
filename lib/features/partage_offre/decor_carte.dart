// Le decor de la carte a partager (CAND-06) : le filigrane du symbole contour et
// la scene du portail. Deux calques peints, sans un mot de texte.
//
// **Direction du directeur (22/10/2026)** : un fond violet profond uni ; le
// symbole contour officiel tres agrandi, coupe par les bords, en blanc a tres
// faible opacite ; et, subtilement, le portail, pour dire l'eleve qui entre dans
// la lumiere du Coran et du savoir (l'un des sens du symbole : l'arche est le
// livre, la porte ouverte est l'acces au centre coranique, `M-21`). Aucun
// degrade : la lumiere est un aplat clair, le chemin qui en sort un aplat plus
// clair que le fond, et un second aplat, plus clair encore, ou la lumiere est la
// plus vive : pres de la porte, dans un cercle dont elle est le centre. La porte
// et son cadre en arche sont une **illustration**, dessinee ici ; le symbole,
// lui, vient du fichier officiel et n'est jamais redessine (`peindreContour`).
//
// **Le symbole et la porte sont sur le meme axe** : l'arche interieure du
// symbole (sa propre porte) est centree sur la porte de la scene, qui est donc
// une porte dans la porte. En arabe la scene est en miroir et la porte passe a
// gauche : le symbole la suit, il se deplace, il ne se retourne jamais. Rien
// d'autre ne les relie : le symbole reste un filigrane, la porte un dessin.
//
// La variante des femmes y ajoute une silhouette de femme voilee, de dos, sans
// visage, qui marche vers la porte, et quelques fleurs ton sur ton : des aplats,
// pas un personnage detaille.
//
// Le filigrane n'est **jamais retourne** : ni miroir ni rotation, en francais,
// en anglais comme en arabe (`peindreContour`). La scene, elle, se met en
// miroir en arabe, comme le texte : la porte passe du cote du debut de ligne, la
// personne marche dans le sens de la lecture.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/marque/contour_traces.g.dart';
import '../../core/marque/peinture_contour.dart';
import '../../core/partage_offre/personnalisation_carte.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Le filigrane : le symbole contour du directeur, agrandi a 1,85 fois la
/// largeur de la carte et coupe par ses bords, en blanc a 7 pour cent.
///
/// Il suit la porte : son axe est celui de la porte de la scene, du cote ou la
/// scene la met (a droite en francais, a gauche en arabe). **Il ne fait que se
/// deplacer** : jamais retourne, ni miroir ni rotation (`peindreContour`).
class FiligraneCarte extends StatelessWidget {
  /// Cree le filigrane.
  const FiligraneCarte({required this.couleurs, super.key});

  /// Les couleurs de la variante.
  final AppPaletteCarte couleurs;

  /// La largeur du symbole, en part de la largeur de la carte : de 1,6 a 2 fois
  /// (directeur, 22/10/2026).
  static const double facteurLargeur = 1.85;

  /// Le centre du symbole, en part de la hauteur de la carte : assez bas pour
  /// que son grand cercle passe hors de la zone de protection du logo, dans les
  /// deux sens de lecture, et assez haut pour que l'arche de son milieu passe
  /// au-dessus de la porte, avec du jeu.
  static const double centreY = 0.54;

  /// Le centre du symbole, en part de la largeur de la carte : l'axe de son
  /// arche interieure est celui de la porte de la scene (`GeometrieScene`), qui
  /// est a droite en [TextDirection.ltr] et a gauche en [TextDirection.rtl]. Le
  /// symbole deborde de la carte : la moitie des arches seulement se voit.
  static double centreX(Size taille, {TextDirection sens = TextDirection.ltr}) {
    final double axe = GeometrieScene.axePorte(taille.width);
    return (sens == TextDirection.rtl ? taille.width - axe : axe) /
        taille.width;
  }

  /// Le coin haut gauche du symbole et sa largeur, pour une carte de [taille].
  static (Offset, double) geometrie(
    Size taille, {
    TextDirection sens = TextDirection.ltr,
  }) {
    final double largeur = taille.width * facteurLargeur;
    final double hauteur = largeur / symboleContour.proportion;
    return (
      Offset(
        taille.width * centreX(taille, sens: sens) - largeur / 2,
        taille.height * centreY - hauteur / 2,
      ),
      largeur,
    );
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _PeintreFiligrane(couleurs, Directionality.of(context)),
      size: Size.infinite,
    ),
  );
}

class _PeintreFiligrane extends CustomPainter {
  const _PeintreFiligrane(this.couleurs, this.sens);

  final AppPaletteCarte couleurs;
  final TextDirection sens;

  @override
  void paint(Canvas canvas, Size size) {
    final (Offset origine, double largeur) = FiligraneCarte.geometrie(
      size,
      sens: sens,
    );
    canvas
      ..save()
      // Le symbole deborde : le canevas le coupe.
      ..clipRect(Offset.zero & size);
    peindreContour(
      canvas,
      symboleContour,
      origine,
      largeur,
      couleurs.filigrane.asBorderSide().color.withValues(
        alpha: AppPaletteCarte.opaciteFiligrane,
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreFiligrane ancien) =>
      ancien.couleurs != couleurs || ancien.sens != sens;
}

/// Les formes de la scene du portail, dans le repere de sa bande (le sens de la
/// lecture est de gauche a droite ; l'arabe met la scene en miroir au dessin).
///
/// Exposee pour que les tests mesurent ce qu'on voit : la porte est petite et
/// entouree de vide, le chemin s'elargit vers le bas et vers le lecteur, la
/// lumiere est la plus vive pres de la porte, la silhouette marche dans la
/// lumiere, sur le chemin.
class GeometrieScene {
  /// Calcule la scene pour une bande de [taille].
  factory GeometrieScene(Size taille) {
    final double w = taille.width;
    final double h = taille.height;
    final double largeurPorte = largeurPorteSur(w);
    final double droite = droitePorteSur(w);
    final double haut = 0.125 * h;
    final double base = haut + 0.38 * h;
    final Rect porte = Rect.fromLTRB(droite - largeurPorte, haut, droite, base);
    final double bordGauche = -0.03 * w;
    final double bas = 0.92 * h;
    // Le chemin part du seuil de la porte. Son bord haut descend a peine vers la
    // gauche ; son bord bas part en diagonale puis s'aplatit vers le bas de la
    // bande : une courbe, comme le chemin qui s'elargit vers le lecteur. Il
    // sort de la carte par le bord oppose a la porte.
    final Path chemin = Path()
      ..moveTo(porte.left, base)
      ..lineTo(bordGauche, base + 0.1 * h)
      ..lineTo(bordGauche, bas)
      ..cubicTo(
        0.4 * w,
        bas,
        porte.right - 0.2 * w,
        base + 0.45 * (bas - base),
        porte.right,
        base,
      )
      ..close();
    // La lumiere la plus vive : le chemin dans un cercle dont le seuil est le
    // centre. Le second aplat, plus clair, vient du premier ; il s'arrete la ou
    // la lumiere s'eteint.
    final Offset seuilCentre = Offset(porte.center.dx, base);
    final Path coeur = Path.combine(
      PathOperation.intersect,
      chemin,
      Path()..addOval(Rect.fromCircle(center: seuilCentre, radius: 0.52 * w)),
    );
    return GeometrieScene._(
      taille: taille,
      porte: porte,
      cheminPath: chemin,
      coeurPath: coeur,
      pieds: Offset(0.44 * w, bas - 0.13 * h),
      hauteurSilhouette: 0.2 * h,
    );
  }

  const GeometrieScene._({
    required this.taille,
    required this.porte,
    required this.cheminPath,
    required this.coeurPath,
    required this.pieds,
    required this.hauteurSilhouette,
  });

  /// La bande.
  final Size taille;

  /// La porte : une arche (un rectangle a sommet en demi-cercle).
  final Rect porte;

  /// Le premier aplat : le chemin de lumiere, du seuil au bord de la carte.
  final Path cheminPath;

  /// Le second aplat, plus clair : la lumiere la plus vive, pres de la porte. Il
  /// est pris dans le premier : un cercle dont le seuil est le centre.
  final Path coeurPath;

  /// Le point ou la silhouette pose les pieds.
  final Offset pieds;

  /// La hauteur de la silhouette (variante des femmes).
  final double hauteurSilhouette;

  /// Le seuil de la porte : la ligne ou le chemin commence.
  double get seuil => porte.bottom;

  /// La porte, comme un [Path] : un demi-cercle au-dessus d'un rectangle.
  Path get portePath => _arche(porte);

  /// Le cadre de la porte : la meme arche, plus large de [ecartCadre] de chaque
  /// cote et au-dessus, posee sur le meme seuil, tracee d'un trait fin
  /// ([epaisseurCadre]).
  Path get cadrePath => _arche(
    Rect.fromLTRB(
      porte.left - ecartCadre,
      porte.top - ecartCadre,
      porte.right + ecartCadre,
      porte.bottom,
    ),
  );

  /// L'ecart entre la porte et son cadre.
  static const double ecartCadre = 6;

  /// La largeur de la porte, pour une carte large de [largeur].
  static double largeurPorteSur(double largeur) => largeur * 46 / 360;

  /// Le bord droit de la porte : son cadre tombe sur la marge du texte, tout
  /// s'aligne.
  static double droitePorteSur(double largeur) =>
      largeur - AppSpacing.xxl - ecartCadre;

  /// L'axe de la porte, pour une carte large de [largeur] : celui du symbole.
  static double axePorte(double largeur) =>
      droitePorteSur(largeur) - largeurPorteSur(largeur) / 2;

  /// L'epaisseur du trait du cadre.
  static const double epaisseurCadre = 2;

  /// La silhouette d'une femme voilee, de dos, sans visage : la tete et le voile
  /// en une seule forme, le voile qui s'epanouit sur les epaules, l'abaya qui
  /// s'evase jusqu'au sol, un ourlet de voile que le vent ecarte dans son dos.
  /// Dessinee pour une hauteur de 100 (les pieds en 0) puis mise a l'echelle de
  /// [hauteurSilhouette].
  Path get silhouettePath {
    final double s = hauteurSilhouette / 100;
    // Un leger penchant vers l'avant : elle marche.
    final Matrix4 echelle = Matrix4.diagonal3Values(s, s, 1)
      ..setEntry(0, 1, -0.05);
    final Path p = Path()
      // La tete, sous le voile.
      ..moveTo(0, -99)
      ..cubicTo(6.5, -99, 10.5, -94.5, 10.5, -88)
      ..cubicTo(10.5, -83.5, 10, -80, 12, -77.5)
      // Le voile qui s'epanouit sur l'epaule, jusqu'a son ourlet.
      ..cubicTo(17, -75.5, 20, -70, 20.5, -62)
      ..cubicTo(21, -54, 21, -48, 20.5, -43)
      // L'abaya dessous, plus etroite, puis qui s'evase jusqu'au sol.
      ..cubicTo(18.5, -43, 17.5, -42, 17.5, -38)
      ..cubicTo(17.5, -28, 19, -18, 22, -9)
      ..cubicTo(23.5, -5, 25, -2, 26.5, 0)
      ..lineTo(-25.5, 0)
      ..cubicTo(-24, -3, -22.5, -7, -21, -12)
      ..cubicTo(-19.5, -20, -19.5, -30, -19.5, -38)
      // L'ourlet du voile, que le vent ecarte un peu dans le dos.
      ..cubicTo(-21, -40, -23, -42, -23.5, -45)
      ..cubicTo(-23.5, -52, -22, -60, -20, -65)
      // L'autre epaule, puis le voile qui remonte a la tete.
      ..cubicTo(-16.5, -71, -13, -75, -11.5, -77.5)
      ..cubicTo(-10, -80, -10.5, -83.5, -10.5, -88)
      ..cubicTo(-10.5, -94.5, -6.5, -99, 0, -99)
      ..close();
    return p.transform(echelle.storage).shift(pieds);
  }

  /// Les fleurs de la variante des femmes : le centre de la fleur et son rayon.
  /// Elles sont ton sur ton, dans la couleur du coeur, sur la partie du chemin
  /// que la lumiere vive n'atteint pas : la lumiere en a laisse derriere elle.
  List<(Offset, double)> get fleurs {
    final double w = taille.width;
    final double h = taille.height;
    return <(Offset, double)>[
      (Offset(0.17 * w, 0.67 * h), 0.03 * h),
      (Offset(0.3 * w, 0.72 * h), 0.022 * h),
      (Offset(0.04 * w, 0.74 * h), 0.016 * h),
    ];
  }

  /// Une fleur de [rayon], centree en [centre] : cinq petales ronds autour d'un
  /// coeur. Un aplat, comme la silhouette.
  static Path fleur(Offset centre, double rayon) {
    final Path p = Path();
    for (int i = 0; i < 5; i++) {
      final double angle = -math.pi / 2 + i * 2 * math.pi / 5;
      p.addOval(
        Rect.fromCircle(
          center: centre + Offset.fromDirection(angle, rayon * 0.55),
          radius: rayon * 0.5,
        ),
      );
    }
    return p;
  }

  static Path _arche(Rect r) {
    final double rayon = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + rayon)
      ..arcTo(
        Rect.fromLTWH(r.left, r.top, r.width, r.width),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(r.right, r.bottom);
  }
}

/// La scene du portail : une porte en arche, claire, petite, avec du vide
/// autour et un cadre en arche d'un trait fin ; un chemin de lumiere qui en sort
/// et s'elargit vers le lecteur ; pour la variante des femmes, une silhouette qui
/// marche vers la lumiere et quelques fleurs ton sur ton.
class ScenePortail extends StatelessWidget {
  /// Cree la scene.
  const ScenePortail({
    required this.couleurs,
    required this.variante,
    super.key,
  });

  /// Les couleurs de la variante.
  final AppPaletteCarte couleurs;

  /// La variante : la silhouette n'existe que pour les femmes.
  final VarianteCarte variante;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _PeintreScene(couleurs, variante, Directionality.of(context)),
      size: Size.infinite,
    ),
  );
}

class _PeintreScene extends CustomPainter {
  const _PeintreScene(this.couleurs, this.variante, this.sens);

  final AppPaletteCarte couleurs;
  final VarianteCarte variante;
  final TextDirection sens;

  @override
  void paint(Canvas canvas, Size size) {
    final GeometrieScene g = GeometrieScene(size);
    canvas.save();
    if (sens == TextDirection.rtl) {
      // La scene se lit dans le sens du texte : la porte passe du cote du debut
      // de ligne. Seule la scene est en miroir, jamais le filigrane ni le logo.
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final Paint aplat = Paint()..isAntiAlias = true;
    canvas.drawPath(g.cheminPath, aplat..color = couleurs.chemin.background);
    if (variante == VarianteCarte.femmes) {
      aplat.color = couleurs.coeur.background;
      for (final (Offset, double) f in g.fleurs) {
        canvas.drawPath(GeometrieScene.fleur(f.$1, f.$2), aplat);
      }
    }
    canvas
      ..drawPath(g.coeurPath, aplat..color = couleurs.coeur.background)
      ..drawPath(
        g.cadrePath,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = GeometrieScene.epaisseurCadre
          ..color = couleurs.coeur.background,
      )
      ..drawPath(g.portePath, aplat..color = couleurs.porte.background);
    if (variante == VarianteCarte.femmes) {
      canvas.drawPath(
        g.silhouettePath,
        aplat..color = couleurs.silhouette.background,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreScene ancien) =>
      ancien.couleurs != couleurs ||
      ancien.variante != variante ||
      ancien.sens != sens;
}
