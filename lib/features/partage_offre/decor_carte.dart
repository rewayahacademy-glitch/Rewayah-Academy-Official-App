// Le decor de la carte a partager (CAND-06) : le filigrane du symbole contour et
// la scene du portail. Deux calques peints, sans un mot de texte.
//
// **Direction du directeur (22/10/2026)** : un fond violet profond ; le symbole
// contour officiel tres agrandi, coupe par les bords, en blanc a tres faible
// opacite ; et, subtilement, le portail, pour dire l'eleve qui entre dans la
// lumiere du Coran et du savoir (l'un des sens du symbole : l'arche est le livre,
// la porte ouverte est l'acces au centre coranique, `M-21`). La porte et son
// cadre en arche sont une **illustration**, dessinee ici ; le symbole, lui, vient
// du fichier officiel et n'est jamais redessine (`peindreContour`).
//
// **La lumiere et les tenebres (directeur, 23/10/2026)** : « une sorte de degrade
// qui montre la dissipation de la lumiere de l'immensite des tenebres ». La scene
// est une porte debout sur une ligne de sol, le seuil. Son ouverture est la source
// de la scene et sa zone la plus claire : un **blanc pur** au coeur (l'eclat) qui
// retombe vers la teinte de la variante sur ses bords, avec un **halo** qui
// deborde sur son cadre et sur le mur, large et doux. Le **faisceau** qu'elle
// pose au sol part exactement du seuil (sa base est l'ouverture) et ses deux bords
// sont des droites qui s'ecartent vers le lecteur ; la lumiere y est tres vive au
// seuil, un peu plus claire au centre qu'aux bords, et s'eteint le long du
// faisceau jusqu'a disparaitre. Tout le reste est dans les **tenebres** : un
// violet presque noir, de la teinte de la variante, qui s'epaissit vers les bords
// et les coins, avec un peu de lumiere ambiante autour de la porte seulement.
//
// **Les deux variantes ont la meme lumiere** : la meme geometrie, la meme densite
// des tenebres, et la **meme luminance** a chaque endroit de la scene, a quelques
// pour cent pres ; seule la teinte change (`AppPaletteCarte` : le fond, les
// tenebres et les deux tons de la lumiere des femmes sont calibres pour cela, et
// un test mesure l'ecart sur les pixels). Le sol n'a aucun motif : le symbole
// contour, decor du mur, s'eteint en arrivant au seuil (`FiligraneCarte`).
//
// **Exception datee au « aucun degrade » du cahier des charges visuel** : elle ne
// vaut que pour la lumiere et l'obscurite de cette scene (les tenebres, la lueur,
// le halo, le faisceau, et le fondu du symbole dans l'ombre). Le logo, le symbole
// contour (le filigrane, partout ou il est visible), le cadre en arche de la
// porte, la branche fleurie, la plaque du QR et le fond de la carte restent des
// aplats, sans degrade : le cadre est un trait d'une couleur et d'une opacite
// fixes, sur lequel la lumiere de la porte deborde. Les couleurs restent des
// jetons (`AppPaletteCarte`) : la lumiere ne fait que les melanger, par
// transparence.
//
// **Le symbole et la porte sont sur le meme axe** : l'arche interieure du
// symbole (sa propre porte) est centree sur la porte de la scene, qui est donc
// une porte dans la porte. En arabe la scene est en miroir et la porte passe a
// gauche : le symbole la suit, il se deplace, il ne se retourne jamais. Rien
// d'autre ne les relie : le symbole reste un filigrane, la porte un dessin.
//
// La variante des femmes y ajoute, tres discrete, une fine branche fleurie dans
// la penombre, au bord du faisceau, sans jamais le couper
// (`branche_fleurie.dart`) : des traits et des aplats, **jamais un personnage**
// ni aucune figure humaine (directeur, 23/10/2026).
//
// Le filigrane n'est **jamais retourne** : ni miroir ni rotation, en francais,
// en anglais comme en arabe (`peindreContour`). La scene, elle, se met en
// miroir en arabe, comme le texte : la porte passe du cote du debut de ligne, la
// lumiere se repand dans le sens de la lecture. Les textes, eux, ne sont jamais
// retournes.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/marque/contour_traces.g.dart';
import '../../core/marque/peinture_contour.dart';
import '../../core/partage_offre/personnalisation_carte.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import 'branche_fleurie.dart';

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
  /// deux sens de lecture, et assez haut pour que le sommet de l'arche de son
  /// milieu reste sous le haut du cadre de la porte : cette arche se perd derriere
  /// la porte et son halo, sans jamais laisser un filet au-dessus d'elle.
  static const double centreY = 0.54;

  /// La hauteur du fondu du symbole, en points : il est entier jusqu'a cette
  /// hauteur au-dessus du seuil de la porte, puis s'eteint et n'est plus la au
  /// seuil. Le symbole est un decor du mur ; le sol, lui, n'en a pas (directeur,
  /// 23/10/2026 : « une lumiere qui chasse l'ombre » sur un sol sans motif).
  static const double hauteurFondu = 80;

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
    final double seuil = GeometrieScene.seuilSur(size.height);
    const double fondu = FiligraneCarte.hauteurFondu;
    final Color trait = couleurs.filigrane.asBorderSide().color;
    canvas
      ..save()
      // Le symbole deborde : le canevas le coupe.
      ..clipRect(Offset.zero & size)
      // Le symbole est sur le mur : il s'eteint dans l'ombre en arrivant au
      // seuil, et le sol (le faisceau, les tenebres du bas) n'en porte aucun.
      ..saveLayer(Offset.zero & size, Paint());
    peindreContour(
      canvas,
      symboleContour,
      origine,
      largeur,
      trait.withValues(alpha: AppPaletteCarte.opaciteFiligrane),
    );
    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(0, seuil - fondu),
            Offset(0, seuil),
            <Color>[trait, trait.withValues(alpha: 0)],
          ),
      )
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_PeintreFiligrane ancien) =>
      ancien.couleurs != couleurs || ancien.sens != sens;
}

/// Les formes de la scene du portail, dans le repere de la carte entiere (360 x
/// 640 points a l'export ; en arabe la scene est mise en miroir au dessin).
///
/// **La lumiere et les tenebres (directeur, 23/10/2026)** : la porte est debout
/// sur une ligne de sol, le seuil ; le faisceau qu'elle pose au sol **part
/// exactement du seuil** (sa base est l'ouverture de la porte) et ses deux bords
/// sont des **droites** qui s'ecartent vers le lecteur : vers le bas et vers le
/// cote oppose a la porte. Aucune courbe, aucune bande plate. La lumiere est la
/// plus vive au seuil et s'eteint le long du faisceau ; tout le reste de la
/// carte est dans les tenebres, de plus en plus profondes vers les bords et les
/// coins. Les deux variantes ont **exactement cette geometrie** : seule la
/// teinte change (`AppPaletteCarte`).
///
/// Exposee pour que les tests mesurent ce qu'on voit.
class GeometrieScene {
  /// Calcule la scene pour une carte de [taille].
  factory GeometrieScene(Size taille) {
    final double w = taille.width;
    final double h = taille.height;
    final Rect porte = Rect.fromLTRB(
      droitePorteSur(w) - largeurPorteSur(w),
      hautPorteSur(h),
      droitePorteSur(w),
      seuilSur(h),
    );
    final Offset seuilGauche = Offset(porte.left, porte.bottom);
    final Offset seuilDroite = Offset(porte.right, porte.bottom);
    final Offset centreSeuil = Offset(porte.center.dx, porte.bottom);
    // Les deux bords du faisceau : des demi-droites qui partent des deux coins
    // du seuil vers le bas et vers la gauche, a deux angles differents. Le bord
    // haut est le plus plat (il part du coin le plus eloigne de la porte), le
    // bord bas le plus raide : ils s'ecartent.
    final Offset dirHaut = Offset(
      -math.cos(angleBordHaut),
      math.sin(angleBordHaut),
    );
    final Offset dirBas = Offset(
      -math.cos(angleBordBas),
      math.sin(angleBordBas),
    );
    final Offset somme = dirHaut + dirBas;
    final Offset axe = somme / somme.distance;
    final double longueur = longueurFaisceauSur(w);
    // Le bout du faisceau : la droite perpendiculaire a l'axe, a [longueur] du
    // centre du seuil. La lumiere y est eteinte : le bout ne se voit pas.
    Offset auBout(Offset depart, Offset direction) {
      final double t =
          (longueur - _scalaire(depart - centreSeuil, axe)) /
          _scalaire(direction, axe);
      return depart + direction * t;
    }

    final Offset boutBas = auBout(seuilDroite, dirBas);
    final Offset boutHaut = auBout(seuilGauche, dirHaut);
    final Path faisceau = Path()
      ..moveTo(seuilGauche.dx, seuilGauche.dy)
      ..lineTo(seuilDroite.dx, seuilDroite.dy)
      ..lineTo(boutBas.dx, boutBas.dy)
      ..lineTo(boutHaut.dx, boutHaut.dy)
      ..close();
    return GeometrieScene._(
      taille: taille,
      porte: porte,
      faisceauPath: faisceau,
      sommetsFaisceau: <Offset>[seuilGauche, seuilDroite, boutBas, boutHaut],
      axe: axe,
      centreSeuil: centreSeuil,
      longueur: longueur,
    );
  }

  const GeometrieScene._({
    required this.taille,
    required this.porte,
    required this.faisceauPath,
    required this.sommetsFaisceau,
    required this.axe,
    required this.centreSeuil,
    required this.longueur,
  });

  /// La carte.
  final Size taille;

  /// L'ouverture de la porte : une arche (un rectangle a sommet en demi-cercle).
  final Rect porte;

  /// Le faisceau au sol : un quadrilatere a quatre cotes droits, du seuil au
  /// bout de la lumiere.
  final Path faisceauPath;

  /// Les quatre sommets du faisceau, dans l'ordre du trace : le coin du seuil le
  /// plus eloigne de la porte (a gauche), le coin du seuil du cote de la porte
  /// (a droite), le bout du bord bas, le bout du bord haut. Les deux premiers
  /// sont les coins de l'ouverture de la porte : le faisceau part d'elle.
  final List<Offset> sommetsFaisceau;

  /// La direction du faisceau, un vecteur unitaire : celle de la lumiere qui
  /// s'eloigne de la porte, vers le bas et vers le cote oppose a la porte.
  final Offset axe;

  /// Le milieu du seuil : ou la lumiere est la plus vive, et d'ou elle part.
  final Offset centreSeuil;

  /// La longueur de la lumiere le long de [axe], du centre du seuil a l'endroit
  /// ou elle est eteinte.
  final double longueur;

  /// Le seuil de la porte : la ligne de sol sur laquelle elle est debout.
  double get seuil => porte.bottom;

  /// Le centre de l'ouverture : le centre du halo.
  Offset get centrePorte => porte.center;

  /// Le point ou la lumiere du faisceau est eteinte.
  Offset get finFaisceau => centreSeuil + axe * longueur;

  /// Le coin du seuil le plus eloigne de la porte : d'ou part le bord haut.
  Offset get coinHaut => sommetsFaisceau[0];

  /// Le coin du seuil du cote de la porte : d'ou part le bord bas.
  Offset get coinBas => sommetsFaisceau[1];

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

  /// Le centre des tenebres : le milieu de la carte, un peu du cote de la porte.
  /// Les bords et les coins en sont les plus eloignes.
  Offset get centreTenebres =>
      Offset(0.62 * taille.width, 0.42 * taille.height);

  /// Le rayon des tenebres, en largeurs de carte : a ce rayon, de ce centre, la
  /// carte est dans les tenebres.
  double get rayonTenebres => 0.92 * taille.width;

  /// L'etirement vertical des tenebres : une carte haute s'assombrit plus
  /// lentement vers le haut et le bas qu'vers les cotes.
  static const double etirementTenebres = 1.3;

  /// Le rayon de la lueur du mur autour de la porte.
  double get rayonLueur => 0.46 * taille.width;

  /// L'etirement vertical de la lueur : la porte est haute.
  static const double etirementLueur = 1.3;

  /// L'angle du bord haut du faisceau sous l'horizontale, en radians : 11 degres.
  static const double angleBordHaut = 11 * math.pi / 180;

  /// L'angle du bord bas du faisceau sous l'horizontale, en radians : 40
  /// degres. Il est plus raide que le bord haut : le faisceau s'elargit.
  static const double angleBordBas = 40 * math.pi / 180;

  /// La normale de l'axe, un vecteur unitaire : le travers du faisceau.
  Offset get normale => Offset(-axe.dy, axe.dx);

  /// Le travers du faisceau, mesure sur [normale] depuis le centre du seuil : du
  /// bord le plus bas au bord le plus haut, a l'endroit ou le faisceau est le
  /// plus large (son bout).
  (double, double) get traversFaisceau {
    double mini = double.infinity;
    double maxi = -double.infinity;
    for (final Offset s in sommetsFaisceau) {
      final double t = _scalaire(s - centreSeuil, normale);
      mini = math.min(mini, t);
      maxi = math.max(maxi, t);
    }
    return (mini, maxi);
  }

  /// L'opacite de la lumiere du faisceau, a la part [t] de sa longueur (0 au
  /// seuil, 1 au bout) : la lecture de [opacitesFaisceau] entre deux arrets.
  static double eclairement(double t) {
    final double x = t.clamp(0.0, 1.0);
    for (int i = 1; i < arretsFaisceau.length; i++) {
      if (x <= arretsFaisceau[i]) {
        final double a = arretsFaisceau[i - 1];
        final double k = (x - a) / (arretsFaisceau[i] - a);
        return opacitesFaisceau[i - 1] +
            (opacitesFaisceau[i] - opacitesFaisceau[i - 1]) * k;
      }
    }
    return opacitesFaisceau.last;
  }

  /// La part de lumiere gardee sur les bords du faisceau : au centre il est a
  /// 1, sur chaque bord a cette part (un peu plus clair au centre qu'aux bords).
  static const double partDesBords = 0.72;

  /// La longueur de la lumiere, pour une carte large de [largeur] : presque
  /// toute la largeur, pour qu'elle s'eteigne avant le bord oppose a la porte.
  static double longueurFaisceauSur(double largeur) => 0.92 * largeur;

  /// Le haut de la porte, pour une carte haute de [hauteur].
  static double hautPorteSur(double hauteur) => 0.29 * hauteur;

  /// Le seuil de la porte, pour une carte haute de [hauteur].
  static double seuilSur(double hauteur) => 0.5025 * hauteur;

  /// Les arrets du degrade du faisceau, de 0 (le seuil) a 1 (le bout).
  static const List<double> arretsFaisceau = <double>[0, 0.1, 0.3, 0.6, 1];

  /// L'opacite de la lumiere a chaque arret : tres vive au seuil (un peu moins
  /// que l'eclat de la porte, qui reste la zone la plus claire), nulle au bout.
  static const List<double> opacitesFaisceau = <double>[
    0.9,
    0.78,
    0.58,
    0.32,
    0,
  ];

  /// Les voiles du halo, du plus large au plus serre : le flou (l'ecart type, en
  /// points) et l'opacite de la teinte de la porte. Peints **sur le cadre** et sur
  /// le mur : la lumiere deborde de l'ouverture au lieu de rester dans son cadre.
  static const List<(double, double)> voilesHalo = <(double, double)>[
    (44, 0.7),
    (18, 0.9),
    (8, 1),
  ];

  /// L'ecart entre la porte et son cadre.
  static const double ecartCadre = 6;

  /// La largeur de la porte, pour une carte large de [largeur].
  static double largeurPorteSur(double largeur) => largeur * 52 / 360;

  /// Le bord droit de la porte : son cadre tombe sur la marge du texte, tout
  /// s'aligne.
  static double droitePorteSur(double largeur) =>
      largeur - AppSpacing.xxl - ecartCadre;

  /// L'axe de la porte, pour une carte large de [largeur] : celui du symbole.
  static double axePorte(double largeur) =>
      droitePorteSur(largeur) - largeurPorteSur(largeur) / 2;

  /// L'epaisseur du trait du cadre.
  static const double epaisseurCadre = 2;

  /// L'opacite du trait du cadre : un aplat de la couleur de la marque, a une
  /// opacite fixe (jamais un degrade), sur lequel la lumiere de la porte
  /// deborde : plus il est opaque, plus il se detache du halo comme un liseré
  /// net ; a cette valeur, il en est le contour, sans creux entre lui et
  /// l'ouverture.
  static const double opaciteCadre = 0.4;

  /// La branche fleurie de la variante des femmes (`branche_fleurie.dart`) : un
  /// ornement en trait, dans la penombre au bord du faisceau, sans jamais le
  /// couper. Aucun personnage.
  ///
  /// Elle est posee **le long du bord haut du faisceau**, du cote des tenebres,
  /// a [ecartBranche] points de lui, et entre par le bord de la carte oppose a la
  /// porte : sa tige est parallele au bord, ses fleurs montent vers les tenebres.
  BrancheFleurie get branche {
    final Offset coin = coinHaut;
    // Le bord haut, vers le bas et vers la gauche : l'unite de sa direction.
    final Offset sens = Offset(
      -math.cos(angleBordHaut),
      math.sin(angleBordHaut),
    );
    // Le point du bord haut qui est un peu au-dela du bord de la carte.
    const double debord = 14;
    final double t = (coin.dx + debord) / math.cos(angleBordHaut);
    final Offset surLeBord = coin + sens * t;
    // Le cote des tenebres : la normale du bord qui monte.
    final Offset haut = Offset(
      -math.sin(angleBordHaut),
      -math.cos(angleBordHaut),
    );
    return BrancheFleurie(
      depart: surLeBord + haut * ecartBranche,
      angle: -angleBordHaut,
    );
  }

  /// L'ecart entre la tige de la branche et le bord haut du faisceau : assez
  /// pour que ses feuilles du bas ne touchent jamais la lumiere.
  static const double ecartBranche = 17;

  static double _scalaire(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

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

/// La scene du portail, sur toute la carte : les tenebres qui montent des bords
/// et des coins, une porte en arche, claire, debout sur son seuil, son halo sur
/// le mur, et le faisceau de lumiere qui en part et s'eteint vers le lecteur ;
/// pour la variante des femmes, une fine branche fleurie dans la penombre au
/// bord du faisceau.
class ScenePortail extends StatelessWidget {
  /// Cree la scene.
  const ScenePortail({
    required this.couleurs,
    required this.variante,
    super.key,
  });

  /// Les couleurs de la variante.
  final AppPaletteCarte couleurs;

  /// La variante : la branche fleurie n'existe que pour les femmes.
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

  /// Un degrade radial elliptique : le cercle de [rayon] autour de [centre],
  /// etire de [etirement] vers le haut et le bas.
  static ui.Shader _radial(
    Offset centre,
    double rayon,
    double etirement,
    List<Color> couleurs,
    List<double> arrets,
  ) {
    final Float64List m = Float64List(16)
      ..[0] = 1
      ..[5] = etirement
      ..[10] = 1
      ..[12] = 0
      ..[13] = centre.dy * (1 - etirement)
      ..[15] = 1;
    return ui.Gradient.radial(
      centre,
      rayon,
      couleurs,
      arrets,
      TileMode.clamp,
      m,
    );
  }

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
    _peindreTenebres(canvas, size, g);
    _peindreLueur(canvas, g);
    // Le cadre est peint avant le halo : la lumiere de la porte deborde sur lui
    // comme sur le mur, au lieu de rester enfermee dedans.
    canvas.drawPath(
      g.cadrePath,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = GeometrieScene.epaisseurCadre
        ..color = couleurs.coeur.background.withValues(
          alpha: GeometrieScene.opaciteCadre,
        ),
    );
    _peindreHalo(canvas, g);
    _peindreFaisceau(canvas, g);
    if (variante == VarianteCarte.femmes) {
      _peindreBranche(canvas, g.branche);
    }
    canvas.drawPath(
      g.portePath,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          g.centrePorte,
          g.porte.height / 2,
          <Color>[couleurs.eclat.background, couleurs.porte.background],
          const <double>[0.35, 1],
        ),
    );
    canvas.restore();
  }

  /// Les tenebres : le violet presque noir de la variante, transparent au
  /// centre, de plus en plus dense vers les bords et les coins.
  void _peindreTenebres(Canvas canvas, Size size, GeometrieScene g) {
    final Color t = couleurs.tenebres.background;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = _radial(
          g.centreTenebres,
          g.rayonTenebres,
          GeometrieScene.etirementTenebres,
          <Color>[
            t.withValues(alpha: 0),
            t.withValues(alpha: 0.18),
            t.withValues(alpha: 0.62),
            t.withValues(alpha: 0.9),
            t.withValues(alpha: 0.97),
          ],
          const <double>[0, 0.3, 0.55, 0.8, 1],
        ),
    );
  }

  /// La lueur du mur : un peu de lumiere ambiante, seulement autour de la porte.
  void _peindreLueur(Canvas canvas, GeometrieScene g) {
    final Color l = couleurs.chemin.background;
    canvas.drawCircle(
      g.centrePorte,
      g.rayonLueur * GeometrieScene.etirementLueur,
      Paint()
        ..shader = _radial(
          g.centrePorte,
          g.rayonLueur,
          GeometrieScene.etirementLueur,
          <Color>[
            l.withValues(alpha: 0.62),
            l.withValues(alpha: 0.28),
            l.withValues(alpha: 0.08),
            l.withValues(alpha: 0),
          ],
          const <double>[0, 0.3, 0.65, 1],
        ),
    );
  }

  /// Le halo : la lumiere de la porte qui deborde sur son cadre et sur le mur
  /// autour d'elle. Trois voiles de la teinte de la porte, du plus large et doux
  /// (une lueur sur le mur) au plus serre et vif (un lisere clair tout contre
  /// l'ouverture) : de l'ouverture vers le mur, la lumiere ne fait que baisser.
  void _peindreHalo(Canvas canvas, GeometrieScene g) {
    final Color c = couleurs.porte.background;
    for (final (double, double) voile in GeometrieScene.voilesHalo) {
      canvas.drawPath(
        g.portePath,
        Paint()
          ..isAntiAlias = true
          ..color = c.withValues(alpha: voile.$2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, voile.$1),
      );
    }
  }

  /// Le faisceau : un degrade lineaire le long de l'axe, tres vif au seuil, qui
  /// s'eteint jusqu'a disparaitre dans l'obscurite ; un peu plus clair au centre
  /// qu'aux bords, par un second degrade, en travers (`BlendMode.dstIn`).
  void _peindreFaisceau(Canvas canvas, GeometrieScene g) {
    final List<Color> teintes = <Color>[
      couleurs.porte.background,
      couleurs.porte.background,
      couleurs.coeur.background,
      couleurs.chemin.background,
      couleurs.chemin.background,
    ];
    final (double, double) travers = g.traversFaisceau;
    final Rect bornes = g.faisceauPath.getBounds().inflate(2);
    canvas
      ..saveLayer(bornes, Paint())
      ..drawPath(
        g.faisceauPath,
        Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(g.centreSeuil, g.finFaisceau, <Color>[
            for (int i = 0; i < teintes.length; i++)
              teintes[i].withValues(alpha: GeometrieScene.opacitesFaisceau[i]),
          ], GeometrieScene.arretsFaisceau),
      );
    final Color opaque = couleurs.porte.background;
    canvas
      ..drawRect(
        bornes,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            g.centreSeuil + g.normale * travers.$1,
            g.centreSeuil + g.normale * travers.$2,
            <Color>[
              opaque.withValues(alpha: GeometrieScene.partDesBords),
              opaque,
              opaque.withValues(alpha: GeometrieScene.partDesBords),
            ],
            const <double>[0, 0.5, 1],
          ),
      )
      ..restore();
  }

  /// La branche fleurie : un fil, des feuilles et des fleurs, tous de la couleur
  /// de la lumiere qui s'attenue, a faible opacite dans la penombre, puis le
  /// trou central des fleurs. Des traits et des aplats : aucun degrade.
  void _peindreBranche(Canvas canvas, BrancheFleurie b) {
    final Color ton = couleurs.coeur.background.withValues(
      alpha: BrancheFleurie.opacite,
    );
    final Paint remplissage = Paint()
      ..isAntiAlias = true
      ..color = ton;
    canvas
      ..saveLayer(null, Paint())
      ..drawPath(
        b.tiges,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = BrancheFleurie.epaisseurTige
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ton,
      )
      ..drawPath(b.feuilles, remplissage)
      ..drawPath(b.boutonsPath, remplissage)
      ..drawPath(b.petales, remplissage)
      ..drawPath(
        b.centres,
        Paint()
          ..isAntiAlias = true
          ..blendMode = BlendMode.clear,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_PeintreScene ancien) =>
      ancien.couleurs != couleurs ||
      ancien.variante != variante ||
      ancien.sens != sens;
}
