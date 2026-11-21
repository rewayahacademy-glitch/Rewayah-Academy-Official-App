// La scène de Praxis : la porte du logo, seule source de lumière ; la route en perspective ;
// les mots qui naissent à sa bouche ; la lumière qui ouvre l'application.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../marque/logo_traces.g.dart';
import '../../marque/trace_svg.dart';
import 'gestes_praxis.dart';
import 'lumiere_entree.dart';
import 'outils_entree.dart';
import 'praxis_reference.dart';

/// Le symbole du logo, lu une fois depuis les traces du SVG livré.
final List<Path> symbole = <Path>[
  for (final String d in logoSymbole.traces) _chemin(d),
];
Path _chemin(String d) {
  final Path p = Path();
  for (final CommandeTrace c in lireTraceSvg(d)) {
    final List<double> k = c.coordonnees;
    switch (c.nature) {
      case NatureCommande.deplacer:
        p.moveTo(k[0], k[1]);
      case NatureCommande.ligne:
        p.lineTo(k[0], k[1]);
      case NatureCommande.cubique:
        p.cubicTo(k[0], k[1], k[2], k[3], k[4], k[5]);
      case NatureCommande.quadratique:
        p.quadraticBezierTo(k[0], k[1], k[2], k[3]);
      case NatureCommande.fermer:
        p.close();
    }
  }
  return p;
}

/// Les repères de la porte, en unités du symbole : son axe, les bords extérieur et intérieur de
/// l'arche blanche, et le sol (le bas du symbole).
const double symboleLargeur = 716, symboleHauteur = 707;
const double _axePorte = 358, _demiExt = 182, _demiInt = 148;

/// La naissance du cintre de l'arche, et le bord avant du tableau de la porte : l'arche blanche
/// du logo se lit en volume, une face plate (de 182 à 164) puis un tableau qui s'enfonce jusqu'au
/// plan de la porte (148 quand l'œil est dans l'axe).
const double _cintre = 368.4, _demiFace = 164;

/// Une arche debout : deux jambes jusqu'au sol, un cintre en plein cintre.
Path _arche(double demi, double sol) => Path()
  ..moveTo(_axePorte - demi, sol)
  ..lineTo(_axePorte - demi, _cintre)
  ..arcToPoint(Offset(_axePorte + demi, _cintre), radius: Radius.circular(demi))
  ..lineTo(_axePorte + demi, sol)
  ..close();

/// L'ouverture découpée dans le disque (de 176 à 540), jusqu'au sol, et le bord avant du tableau.
final Path _ouvertureDisque = _arche(_demiExt + 1, symboleHauteur + 0.5), _ouvertureTableau = _arche(_demiFace, symboleHauteur + 0.5);

/// La face de l'arche : la bande plate entre le disque et le tableau.
final Path _faceArche = Path.combine(PathOperation.difference, _ouvertureDisque, _arche(_demiFace - 1, symboleHauteur + 2));

/// La porte du logo vue depuis l'œil de la route, en unités du symbole.
///
/// La route donne l'horizon et le point de fuite ([Geo.fuite]) : sa ligne médiane, la marche de
/// Praxis et son ombre y vont, et ses rangées de dalles se resserrent sur cet horizon. La porte est
/// debout au bout de la route, face à elle : sa face avant (le disque, l'arche) reste de face,
/// et tout ce qui est en profondeur glisse vers ce point. Le tableau de l'arche s'enfonce jusqu'au
/// plan de la porte ([fond]) ; le battant pivote sur ses gonds, à gauche, vers l'intérieur.
/// Quand l'œil est dans l'axe, à la hauteur du dessin, on retrouve le symbole livré : arche de
/// 148, battant de 210 à 353, jour de 353 à 405.
class VuePorte {
  VuePorte(this.oeil, double ouverture) {
    centre = versFond(const Offset(_axePorte, _cintre));
    rayon = _demiFace * fond;
    sol = versFond(const Offset(_axePorte, symboleHauteur)).dy;
    gond = centre.dx - rayon;
    haut = centre.dy - 37.86;
    montant = centre + const Offset(47.34, 6.23);
    // Le battant : large de 198, à 257 de l'œil. S'il cache tout le jour (œil du côté opposé
    // aux gonds), il s'ouvre davantage : la porte reste la source de la lumière.
    double a = ouverture, e, x;
    while (true) {
      e = _recul / (_recul + _battant * math.sin(a));
      x = oeil.dx + (gond + _battant * math.cos(a) - oeil.dx) * e;
      if (montant.dx - x >= 24 || a >= 1.5) break;
      a += 0.03;
    }
    x = cl(x, gond + 6, montant.dx - 6);
    libreHaut = Offset(x, oeil.dy + (haut - oeil.dy) * e);
    libreBas = Offset(x, oeil.dy + (sol - oeil.dy) * e);
    lueur = Offset((x + montant.dx) / 2, centre.dy + 175);
  }

  /// La profondeur du plan de la porte : ce que mesure, vu de l'œil, une longueur du plan avant.
  static const double fond = _demiInt / _demiFace;

  /// L'ouverture du battant du symbole livré, en radians, sa largeur et son recul à l'œil.
  static const double entrouverte = math.pi / 4;
  static const double _battant = 198, _recul = 257;

  final Offset oeil;
  late final Offset centre, montant, libreHaut, libreBas, lueur;
  late final double rayon, sol, gond, haut;

  /// Un point du plan avant, reculé jusqu'au plan de la porte : il glisse vers le point de fuite.
  Offset versFond(Offset p) => oeil + (p - oeil) * fond;

  /// Le tableau (les deux murs et la voûte) et le fond, sans le seuil : le sol reste la route.
  Path get murs {
    final Offset g = versFond(const Offset(_axePorte - _demiFace, symboleHauteur)), d = versFond(const Offset(_axePorte + _demiFace, symboleHauteur));
    return Path()
      ..moveTo(_axePorte - _demiFace, symboleHauteur + 0.5)
      ..lineTo(_axePorte - _demiFace, _cintre)
      ..arcToPoint(const Offset(_axePorte + _demiFace, _cintre), radius: const Radius.circular(_demiFace))
      ..lineTo(_axePorte + _demiFace, symboleHauteur + 0.5)
      ..lineTo(d.dx, d.dy)
      ..lineTo(g.dx, g.dy)
      ..close();
  }

  /// Le seuil : la route qui entre sous l'arche, du plan avant au plan de la porte.
  List<Offset> get seuil => <Offset>[
        const Offset(_axePorte - _demiFace, symboleHauteur),
        const Offset(_axePorte + _demiFace, symboleHauteur),
        versFond(const Offset(_axePorte + _demiFace, symboleHauteur)),
        versFond(const Offset(_axePorte - _demiFace, symboleHauteur)),
      ];

  /// La porte elle-même, dans son plan : une arche posée sur le sol.
  Path get porte => Path()
    ..moveTo(centre.dx - rayon, sol)
    ..lineTo(centre.dx - rayon, centre.dy)
    ..arcToPoint(Offset(centre.dx + rayon, centre.dy), radius: Radius.circular(rayon))
    ..lineTo(centre.dx + rayon, sol)
    ..close();

  /// Le jour : ce que le battant entrouvert laisse voir de la lumière.
  Path get jour {
    final Offset coin = Offset.lerp(Offset(gond, haut), libreHaut, 0.174)!;
    return Path()..addPolygon(<Offset>[montant, coin, libreHaut, libreBas, Offset(gond, sol), Offset(montant.dx, sol)], true);
  }
}

enum CadreScene { tel, telPlein, large, largePlein }

/// La géométrie de la scène. La caméra est au-dessus de Praxis et regarde la route vers la
/// porte : tout point du sol à la profondeur z se projette à `horizon + H / z`, les largeurs
/// en `1 / z`. Les bords de la route convergent donc vers la porte, et les dalles se resserrent.
class Geo {
  Geo(this.taille, this.cadre, this.rtl, this.hautScene, this.carte, {this.cam = 0}) {
    final double w = taille.width, h = taille.height;
    double cx = w / 2, top, lw0;
    switch (cadre) {
      case CadreScene.tel:
        champ = Rect.fromLTWH(0, 0, w, hautScene);
        // De haut en bas : le logo, une ligne pour ses mots, Praxis, le bord du formulaire.
        final double libre = hautScene - 122;
        lw0 = math.min(w * 0.40, libre * 0.43);
        top = 46;
        tProche = math.min(w * 0.47, libre / 1.86);
        yProche = hautScene - 46;
        xProche = w / 2;
        demiLargeur = 1.08;
      case CadreScene.telPlein:
        champ = Offset.zero & taille;
        lw0 = math.min(w * 0.52, h * 0.25);
        top = math.max(64, h * 0.115);
        tProche = math.min(w * 0.50, h * 0.235);
        yProche = math.min(h * 0.735, h - 232);
        xProche = w / 2;
        demiLargeur = 1.0;
      case CadreScene.large:
        champ = Offset.zero & taille;
        final double zone = rtl ? w - carte.right : carte.left, x0 = rtl ? carte.right : 0;
        cx = x0 + zone * (rtl ? 0.60 : 0.40);
        lw0 = math.min(zone * 0.42, h * 0.36);
        top = h * 0.075;
        tProche = h * 0.33;
        yProche = h * 0.905;
        // Il s'arrête à côté de la carte, assez loin pour que la main qui montre le champ tienne
        // entre lui et elle sans la toucher.
        xProche = rtl ? carte.right + tProche * 0.68 : carte.left - tProche * 0.68;
        demiLargeur = 1.0;
      case CadreScene.largePlein:
        champ = Offset.zero & taille;
        lw0 = h * 0.33;
        top = h * 0.06;
        tProche = h * 0.25;
        yProche = h * 0.72;
        xProche = w / 2;
        demiLargeur = 1.0;
    }
    // La caméra accompagne l'approche : elle plonge un peu (le lointain monte), avance un peu
    // (le lointain grossit) et glisse de côté. Quelques pour cent, pas davantage.
    final double monte = champ.height * 0.032 * cam;
    lw = lw0 * (1 + 0.035 * cam);
    k = lw / symboleLargeur;
    final double bas = top + symboleHauteur * (lw0 / symboleLargeur) - monte;
    final double glisse = (cx - xProche) * 0.02 * cam + (cadre == CadreScene.tel || cadre == CadreScene.telPlein ? 0 : 0);
    logo = Rect.fromLTWH(cx + glisse - lw * _axePorte / symboleLargeur, bas - symboleHauteur * k, lw, symboleHauteur * k);
    porte = Offset(logo.left + _axePorte * k, logo.bottom);
    Z = cl(tProche / (lw0 * 0.122), 6, 14);
    lnZ = math.log(Z);
    horizon = (porte.dy - yProche / Z) / (1 - 1 / Z);
    H = yProche - horizon;
    // Le point de fuite de la route : là où sa ligne médiane rejoint l'horizon (profondeur infinie).
    fuite = Offset(porte.dx - (xProche - porte.dx) / (Z - 1), horizon);
    // Variante « trois quarts » : l'œil est devant le premier plan (là où Praxis s'arrête) et
    // regarde droit devant lui ; la route part en biais, et le plan de la porte, qui lui est
    // perpendiculaire, tourne d'autant. Ses horizontales fuient vers le second point de fuite,
    // sur le même horizon (les deux points de fuite sont à angle droit pour cet œil).
    final double biais = xProche - fuite.dx;
    if (troisQuarts && grand && biais.abs() > 1) {
      final double focale = champ.height * 0.72, angle = math.atan(biais / focale);
      _cos = math.cos(angle);
      _fuite2 = xProche + focale * focale / biais;
      _fuit = _cos / (_fuite2 - porte.dx);
    } else {
      _cos = 1;
      _fuite2 = double.infinity;
      _fuit = 0;
    }
    lueur = ecran(vue(VuePorte.entrouverte).lueur);
  }
  final Size taille;
  final CadreScene cadre;
  final bool rtl;
  final double hautScene, cam;
  final Rect carte;
  late final Rect champ, logo;
  late final double tProche, yProche, xProche, k, lw, Z, lnZ, horizon, H, demiLargeur;
  late final Offset porte, lueur, fuite;
  late final double _cos, _fuit, _fuite2;

  /// Paramètre interne du peintre : faux (A, retenu), la porte fait face à l'image et les traverses
  /// de la route restent horizontales ; vrai (B), la porte est vue de trois quarts quand la route
  /// part en biais, et les traverses fuient avec elle. Directeur, 20/11/2026, sur la variante B en
  /// production : « le logo a été déformé à cause de la perspective, donc supprime cet effet
  /// d'angle ». Le disque du logo reste rond : B ne s'essaie plus que par
  /// `--dart-define=PORTE_TROIS_QUARTS=true`.
  static const bool troisQuarts = bool.fromEnvironment('PORTE_TROIS_QUARTS');

  /// Vrai quand la porte est vue de trois quarts (route en biais, variante B).
  bool get deBiais => _fuit != 0;

  /// Un point de la traverse qui passe par [c], à l'écart [t] (mesuré de face) : la traverse
  /// fuit vers le second point de fuite, sur l'horizon, comme les horizontales de la porte.
  Offset _surTraverse(Offset c, double t) {
    if (_fuit == 0) return Offset(c.dx + t, c.dy);
    final double w = 1 + t * _cos / (_fuite2 - c.dx);
    return Offset(c.dx + t * _cos / w, horizon + (c.dy - horizon) / w);
  }

  /// Le plan de la porte, tourné autour de son axe vertical : les verticales restent verticales,
  /// les horizontales fuient sur l'horizon de la route. Sans biais, rien ne bouge.
  Offset tourner(Offset p) {
    final double w = 1 + (p.dx - porte.dx) * _fuit;
    return Offset(porte.dx + (p.dx - porte.dx) * _cos / w, horizon + (p.dy - horizon) / w);
  }

  /// La même rotation, pour la toile ; nul quand la porte est de face.
  Matrix4? get rotationPorte {
    if (_fuit == 0) return null;
    final double x0 = porte.dx;
    return Matrix4.identity()
      ..setEntry(0, 0, x0 * _fuit + _cos)
      ..setEntry(0, 3, x0 * (1 - _fuit * x0 - _cos))
      ..setEntry(1, 0, horizon * _fuit)
      ..setEntry(1, 3, -horizon * _fuit * x0)
      ..setEntry(3, 0, _fuit)
      ..setEntry(3, 3, 1 - _fuit * x0);
  }

  /// Un point du symbole (unités du logo) à l'écran.
  Offset ecran(Offset p) => tourner(logo.topLeft + p * k);

  /// Un pied de l'arche au sol (bord extérieur, ou intérieur) : là où part la bordure de la route.
  Offset pied(double cote, {bool interieur = false}) => tourner(Offset(porte.dx + cote * (interieur ? _demiInt : _demiExt) * k, porte.dy));

  /// La porte du logo vue depuis l'œil de la route, le battant ouvert de [ouverture] radians.
  /// L'œil est le point de fuite, ramené dans le plan de la porte.
  VuePorte vue(double ouverture) {
    final double t = fuite.dx - porte.dx;
    return VuePorte((Offset(porte.dx + t / (_cos - t * _fuit), horizon) - logo.topLeft) / k, ouverture);
  }

  bool get plein => cadre == CadreScene.telPlein || cadre == CadreScene.largePlein;
  bool get grand => cadre == CadreScene.large || cadre == CadreScene.largePlein;
  double get hc => H / tProche;

  /// La profondeur à la position q du chemin (0 à la porte, 1 au premier plan).
  double z(double q) => math.exp(lnZ * (1 - q));

  /// Un point du sol : profondeur z, écart en travers (en largeurs de Praxis).
  Offset solZ(double z, [double travers = 0]) {
    final double e = 1 / z, u = (e - 1 / Z) / (1 - 1 / Z);
    final Offset c = Offset(porte.dx + (xProche - porte.dx) * u, horizon + H * e);
    return travers == 0 ? c : _surTraverse(c, travers * tProche * e);
  }

  Offset sol(double q, [double travers = 0]) => solZ(z(q), travers);

  /// La demi-largeur de la route à l'écran, à la profondeur z. À la porte, elle vaut exactement
  /// celle de l'arche blanche du logo (bord extérieur, ou intérieur) : les deux pieds de l'arche
  /// se prolongent en bordures de la route, d'un seul trait. Au premier plan, la route garde sa
  /// largeur. Entre les deux et au-delà, la bordure est une droite : elle ne s'arrête jamais.
  double demiRoute(double z, {bool interieur = false}) {
    final double u = (1 / z - 1 / Z) / (1 - 1 / Z);
    final double loin = (interieur ? _demiInt : _demiExt) * k, pres = tProche * demiLargeur * (interieur ? 0.92 : 1);
    return loin + (pres - loin) * u;
  }

  /// Un point de la route : f vaut -1 et 1 sur les bords (extérieurs, ou intérieurs).
  /// Chaque bord est la droite qui joint le pied de l'arche au premier plan ; de biais, la
  /// traverse qui passe par la ligne médiane fuit vers le second point de fuite et coupe ce bord.
  Offset route(double z, double f, {bool interieur = false}) {
    final Offset c = solZ(z);
    if (f == 0) return c;
    final double cote = f.sign;
    if (_fuit == 0) return Offset(c.dx + f * demiRoute(z, interieur: interieur), c.dy);
    final Offset p = pied(cote, interieur: interieur), b = Offset(xProche + cote * tProche * demiLargeur * (interieur ? 0.92 : 1), yProche) - p;
    final Offset d = Offset(_fuite2 - c.dx, horizon - c.dy);
    final double det = d.dx * b.dy - d.dy * b.dx;
    if (det.abs() < 1e-9) return c;
    final double r = ((p.dx - c.dx) * b.dy - (p.dy - c.dy) * b.dx) / det;
    return c + d * (r * f.abs());
  }
  double largeur(double q) => tProche / z(q);
}

/// Un mot qui sort de la bouche de Praxis : dessiné une fois dans une image, puis déplacé.
class MotVol {
  MotVol(this.image, this.taille, this.fin, this.debut);
  final ui.Image image;
  final Size taille;
  final Offset fin; // centre du mot posé
  final double debut;
  final R t = R(0, k: 150, c: 15.5), s = R(0, k: 14, c: 6.2);
  Offset naissance = Offset.zero;
  bool ne = false, part = false;
}

class Parole {
  Parole(this.mots, this.depart, this.fini);
  final List<MotVol> mots;
  final double depart;
  final Completer<void> fini;
  double age = 0;
}

/// Une étincelle qui part de sa main vers la porte.
class Etincelle {
  Etincelle(this.de);
  final Offset de;
  double t = 0;
}

class Annule implements Exception {}

class _Attente {
  _Attente(this.fait, this.g);
  final bool Function() fait;
  final int g;
  final Completer<void> fin = Completer<void>();
}

/// Le théâtre : une seule horloge pour Praxis, la porte, la route et les mots. Elle avance du
/// temps réellement écoulé, par sous-pas fixes : quand les images tombent, l'animation garde
/// sa vitesse.
class Theatre extends ChangeNotifier {
  final Corps px = Corps();
  Geo geo = Geo(const Size(390, 844), CadreScene.telPlein, false, 844, Rect.zero);
  final R eclat = R(0.25, k: 12, c: 5.6), inonde = R(0, k: 5, c: 4.7), clavier = R(0, k: 170, c: 22), cam = R(0, k: 7, c: 5.2);
  final List<R> dalles = List<R>.generate(24, (_) => R(0, k: 120, c: 9));
  final List<Etincelle> etincelles = <Etincelle>[];
  double progres = -1; // -1 : pas de progression
  bool reduit = false;
  Parole? parole;
  int gen = 0;
  double temps = 0, _reste = 0;
  static const double sousPas = 1 / 120;

  /// La lumière de la porte : son niveau, avec une respiration lente et continue.
  double get lum => math.max(0, eclat.x) * (reduit ? 1 : 1 + 0.045 * math.sin(temps * 1.25) + 0.022 * math.sin(temps * 0.83 + 1.7));

  /// L'ouverture du battant : il pivote sur ses gonds avec la lumière (presque clos quand la
  /// porte s'éteint, un peu plus ouvert quand elle éclate). Sans la respiration : il ne bat pas.
  double get ouverture => VuePorte.entrouverte + 0.30 * cl(eclat.x - 1, -0.75, 0.42);

  /// Avance du temps réel écoulé depuis la dernière image, par sous-pas de 1/120 s.
  /// Le rattrapage est borné : après un long gel, on ne rejoue pas plus d'un quart de seconde.
  void avancer(double dtReel) {
    _reste += math.min(dtReel, 0.25);
    int n = 0;
    while (_reste >= sousPas && n < 40) {
      _pas(sousPas);
      _reste -= sousPas;
      n++;
    }
    _servir();
    notifyListeners();
  }

  void _pas(double dt) {
    temps += dt;
    px
      ..lnZ = geo.lnZ
      ..hc = geo.hc
      ..reduit = reduit;
    _viser();
    px.pas(dt);
    cam.cible = reduit ? 1 : cl(px.q);
    for (final R r in <R>[eclat, inonde, clavier, cam, ...dalles]) {
      r.pas(dt);
    }
    // Les rangées de dalles s'allument de Praxis vers la porte.
    final int n = rangees;
    for (int i = 0; i < dalles.length; i++) {
      dalles[i].cible = progres >= 0 && i < n && progres > seuilRangee(i) ? 1 : 0;
    }
    for (final Etincelle e in etincelles) {
      e.t += dt / 0.95;
    }
    if (etincelles.isNotEmpty && etincelles.first.t >= 1) {
      etincelles.removeAt(0);
      eclat.v += 2.2;
    }
    _parler(dt);
  }

  // ───── Les dalles : rangées d'égale profondeur réelle ─────
  static const double zDepart = 0.56, zPas = 0.5;
  int get rangees => math.min(dalles.length, ((geo.Z - zDepart) / zPas).floor());

  /// À quelle progression la rangée i s'allume : à mi-chemin entre la distance à l'écran et la
  /// distance réelle, pour que la lumière avance régulièrement à l'œil.
  double seuilRangee(int i) {
    final double zc = zDepart + (i + 0.5) * zPas;
    if (zc <= 1.15) return 0.01;
    final double ecran = (1 - 1 / zc) / (1 - 1 / geo.Z), reel = (zc - 1) / (geo.Z - 1);
    return cl(0.55 * ecran + 0.45 * reel - 0.04, 0.02, 0.985);
  }

  // ───── Praxis à l'écran ─────
  Offset get piedPraxis => geo.sol(px.q, px.lat.x);
  double get largeurPraxis => geo.largeur(px.q);
  Offset versEcran(Offset unite) => piedPraxis + (unite - const Offset(100, 206)) * (largeurPraxis / 200);
  Offset get bouchePraxis => versEcran(px.bouche);
  Offset get centrePraxis => versEcran(Offset(100, 108 + px.hauteurCorps));

  /// Ce que Praxis montre quand il pointe : le champ de l'adresse (ou, sans champ, la carte du
  /// formulaire), dans le repère de la scène. L'écran le donne ; nul : il montre vers le bas.
  Offset? cible;

  /// Règle son geste sur [cible] : la direction, de son corps vers elle, et l'allonge de la main.
  /// Formulaire sous lui (téléphone) : droit vers le bas, le geste d'origine. Formulaire à côté
  /// (ordinateur) : la main de ce côté se lève vers le champ, le doigt dans l'axe du champ ; elle
  /// monte au plus à 0,72 radian (au-delà, elle entrerait dans la toque) et s'arrête avant la
  /// carte, qu'elle ne touche pas.
  void _viser() {
    px
      ..vise = const Offset(0, 1)
      ..allonge = 112;
    final Offset? c = cible;
    if (c == null) return;
    final Offset centre = centrePraxis, d = c - centre;
    if (d.dy >= d.dx.abs() || d.dx.abs() < 1) return;
    final double a = cl(math.atan2(d.dy, d.dx.abs()), -0.72, 0.6);
    px.vise = Offset(d.dx.sign * math.cos(a), math.sin(a));
    if (geo.cadre != CadreScene.large) return;
    // La place libre jusqu'à la carte, en unités du dessin ; le doigt (27), son rebond (5) et sa
    // lueur (12) y tiennent.
    final double libre = ((d.dx > 0 ? geo.carte.left - centre.dx : centre.dx - geo.carte.right) - 8) / (largeurPraxis / 200);
    px.allonge = cl((libre - 12) / math.cos(a) - 32, 96, 128);
  }

  Eclairage get eclairage {
    final Offset d = geo.lueur - centrePraxis;
    final double dist = d.distance, l = lum;
    return Eclairage(
      couleur: Teinte.coeur,
      dir: dist < largeurPraxis * 0.4 ? const Offset(0, -1) : d / dist,
      contre: cl(0.9 + 0.3 * (1 - px.q), 0, 1.2) * cl(l, 0, 1.25),
      brume: lisse2(0.8, 0.0, px.q),
      surex: reduit ? 0 : px.surex,
      niveau: cl(l),
    );
  }

  // ───── Les mots ─────
  /// Le style des mots, donne par l'ecran (la typographie du theme) ; le
  /// theatre n'en regle que le corps, l'interligne et l'encre.
  TextStyle styleBase = const TextStyle();

  /// Vrai quand Praxis parle arabe : ses mots se lisent de droite a gauche.
  bool arabe = false;

  TextStyle styleMots(double corps) => arabe
      ? styleBase.copyWith(fontSize: corps * 1.06, color: T.encre, height: 1.42)
      : styleBase.copyWith(fontSize: corps, color: T.encre, height: 1.2, fontFeatures: const <ui.FontFeature>[ui.FontFeature.disable('liga')]);

  Future<void> dire(String texte, {double? tenir}) {
    _finir();
    if (texte.isEmpty) return Future<void>.value();
    final TextDirection dir = arabe ? TextDirection.rtl : TextDirection.ltr;
    final Geo g = geo;
    final double w = g.taille.width;
    // La ligne se pose au-dessus de sa tête, dans la place libre.
    double gauche = 16, droite = w - 16;
    if (g.cadre == CadreScene.large) {
      if (g.rtl) {
        gauche = g.carte.right + 24;
      } else {
        droite = g.carte.left - 24;
      }
    }
    final double mw = math.min(droite - gauche, g.grand ? 520 : 400);
    double corps = g.grand ? 27 : 21;
    TextPainter mise(double c, int lignes) =>
        TextPainter(text: TextSpan(text: texte, style: styleMots(c)), textDirection: dir, textAlign: TextAlign.center, maxLines: lignes, textWidthBasis: TextWidthBasis.longestLine)..layout(maxWidth: mw);
    TextPainter tout = mise(corps, 1);
    if (tout.didExceedMaxLines) {
      corps *= 0.9;
      tout = mise(corps, 2);
    }
    final TextStyle st = styleMots(corps);
    final Offset pied = piedPraxis;
    final double l = largeurPraxis;
    final double tete = pied.dy - l * (1.06 - 0.08 * cl(px.assis.x)) - 10;
    final double cx = cl(pied.dx, gauche + tout.width / 2, math.max(gauche + tout.width / 2, droite - tout.width / 2));
    final double haut = math.max(g.champ.top + (g.grand ? 14 : 48), tete - tout.height);
    final Offset origine = Offset(cx - tout.width / 2, haut);
    final List<MotVol> mots = <MotVol>[];
    double t = 0.16;
    const double marge = 6, ech = 3;
    for (final RegExpMatch m in RegExp(r'[^ ]+').allMatches(texte)) {
      final List<TextBox> b = tout.getBoxesForSelection(TextSelection(baseOffset: m.start, extentOffset: m.end));
      if (b.isEmpty) continue;
      Rect r = b.first.toRect();
      for (final TextBox x in b.skip(1)) {
        r = r.expandToInclude(x.toRect());
      }
      final String mot = m.group(0)!;
      final TextPainter tp = TextPainter(text: TextSpan(text: mot, style: st), textDirection: dir)..layout();
      final TextPainter halo = TextPainter(
          text: TextSpan(
              text: mot,
              style: st.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 5.5
                    ..strokeJoin = StrokeJoin.round
                    ..color = T.fond.withValues(alpha: 0.86))),
          textDirection: dir)
        ..layout();
      final Size taille = Size(tp.width + marge * 2, tp.height + marge * 2);
      final ui.PictureRecorder rec = ui.PictureRecorder();
      final Canvas c = Canvas(rec)..scale(ech);
      halo.paint(c, const Offset(marge, marge));
      tp.paint(c, const Offset(marge, marge));
      final ui.Picture pic = rec.endRecording();
      final ui.Image image = pic.toImageSync((taille.width * ech).ceil(), (taille.height * ech).ceil());
      pic.dispose();
      tp.dispose();
      halo.dispose();
      mots.add(MotVol(image, taille, origine + r.center, t));
      t += 0.11 + 0.013 * mot.length;
    }
    tout.dispose();
    final double dernier = mots.isEmpty ? 0 : mots.last.debut;
    final double garde = tenir ?? math.max(2.0, 0.9 + 0.34 * mots.length);
    final Parole pa = Parole(mots, dernier + 0.5 + garde, Completer<void>());
    parole = pa;
    px.parle = !reduit;
    return pa.fini.future;
  }

  void _parler(double dt) {
    final Parole? pa = parole;
    if (pa == null) return;
    pa.age += dt;
    for (int i = 0; i < pa.mots.length; i++) {
      final MotVol m = pa.mots[i];
      // Sous « Réduire les effets », la phrase est posée entière, d'emblée.
      if (!m.ne && (reduit || pa.age >= m.debut)) {
        m.ne = true;
        m.naissance = bouchePraxis;
        m.t.cible = 1;
        if (reduit) {
          m.t.x = 1;
          m.t.v = 0;
        }
      }
      if (!m.part && pa.age >= pa.depart + i * 0.07) {
        m.part = true;
        m.s.cible = 1;
      }
      m.t.pas(dt);
      m.s.pas(dt);
    }
    final bool parle = pa.mots.isNotEmpty && pa.age < pa.mots.last.debut + 0.28;
    if (px.parle && !parle) {
      px.parle = false;
      px.poser(px.expr);
    }
    if (pa.age >= pa.depart + 0.35 && !pa.fini.isCompleted) pa.fini.complete();
    if (pa.mots.every((MotVol m) => m.s.x > 0.985)) _finir();
  }

  void _finir() {
    final Parole? pa = parole;
    if (pa == null) return;
    for (final MotVol m in pa.mots) {
      m.image.dispose();
    }
    if (!pa.fini.isCompleted) pa.fini.complete();
    parole = null;
    if (px.parle) {
      px.parle = false;
      px.poser(px.expr);
    }
  }

  /// Les mots en cours s'envolent tout de suite.
  void taire() {
    final Parole? pa = parole;
    if (pa == null) return;
    for (final MotVol m in pa.mots) {
      m.ne = true;
      if (m.naissance == Offset.zero) m.naissance = m.fin;
      m.part = true;
      m.s.cible = 1;
      m.s.k = 40;
      m.s.c = 11;
    }
    if (!pa.fini.isCompleted) pa.fini.complete();
    if (px.parle) {
      px.parle = false;
      px.poser(px.expr);
    }
  }

  void etincelle() {
    if (reduit) return;
    etincelles.add(Etincelle(versEcran(Offset(100 + px.mdx.x, 108 + px.mdy.x + px.hauteurCorps))));
  }

  // ───── Le temps des scènes : il suit l'horloge du théâtre ─────
  //
  // ENTREE-PRAXIS : aucune minuterie. Une attente est servie par l'horloge du
  // theatre, a chaque image ([avancer]) ; une scene remplacee ([gen] change)
  // ou un theatre ferme ([fermer]) la termine par [Annule].
  final List<_Attente> _attentes = <_Attente>[];

  Future<void> _quand(bool Function() fait, int g) {
    if (g != gen) return Future<void>.error(Annule());
    final _Attente a = _Attente(fait, g);
    _attentes.add(a);
    return a.fin.future;
  }

  void _servir() {
    if (_attentes.isEmpty) return;
    for (final _Attente a in List<_Attente>.of(_attentes)) {
      if (a.g != gen) {
        _attentes.remove(a);
        a.fin.completeError(Annule());
      } else if (a.fait()) {
        _attentes.remove(a);
        a.fin.complete();
      }
    }
  }

  /// Vrai tant qu'une scene attend l'horloge.
  bool get attend => _attentes.isNotEmpty;

  /// Ferme le theatre : toute scene en cours s'arrete.
  void fermer() {
    gen++;
    _finir();
    _servir();
  }

  Future<void> attendre(int ms, int g) {
    final double fin = temps + ms / 1000;
    return _quand(() => temps >= fin, g);
  }

  Future<void> jusqua(bool Function() fait, int g, {int max = 12000}) {
    final double fin = temps + max / 1000;
    return _quand(() => fait() || temps >= fin, g);
  }

  Future<void> parler(String texte, int g, {double? tenir}) async {
    await dire(texte, tenir: tenir);
    if (g != gen) throw Annule();
  }

  bool get present => px.q > 0.2 && inonde.cible == 0 && px.fondu.cible > 0.5;

  /// Remise à zéro : Praxis est derrière la lumière, la porte attend.
  void initial() {
    gen++;
    _finir();
    etincelles.clear();
    px
      ..lnZ = geo.lnZ
      ..hc = geo.hc
      ..reduit = reduit
      ..placer(-0.08)
      ..vMax = 0.25
      ..pietine = 0
      ..y = 0
      ..vy = 0
      ..faire(Geste.aucun)
      ..poser(Expr.neutre)
      ..regarder(0, 0);
    px.tourne.x = px.tourne.cible = 0;
    px.tourne.v = 0;
    px.assis.x = px.assis.cible = 0;
    px.fondu.x = reduit ? 0 : 1;
    px.fondu.cible = reduit ? 0 : 1;
    inonde.x = inonde.cible = 0;
    inonde.v = 0;
    eclat.x = 0.25;
    eclat.cible = 0.25;
    cam.x = cam.cible = reduit ? 1 : 0;
    progres = -1;
    for (final R d in dalles) {
      d.x = d.cible = 0;
      d.v = 0;
    }
  }

  /// La lumière monte, Praxis sort de la porte et suit la route jusqu'à nous.
  Future<void> arriver(int g, {bool vite = false, double jusque = 1, double travers = 0}) async {
    eclat.cible = 1.16;
    if (reduit) {
      px.placer(jusque, travers: travers);
      px.fondu.cible = 1;
      px.poser(Expr.sourire);
      eclat.cible = 1;
      await attendre(500, g);
      return;
    }
    await attendre(vite ? 260 : 620, g);
    px.poser(Expr.sourire);
    px.regarder(0, 0.15);
    px.allerA(jusque, travers: travers, vitesse: vite ? 0.44 : 0.25);
    await jusqua(() => px.q > 0.45, g);
    eclat.cible = 1;
    await jusqua(() => px.arrive, g);
    px.regarder(0, 0);
  }

  /// Il se retourne, remonte la route, devient silhouette de lumière ; l'iris s'ouvre.
  Future<void> repartir(int g, {VoidCallback? ouvert}) async {
    if (reduit) {
      taire();
      px.fondu.cible = 0;
      await attendre(450, g);
      inonde.k = 30;
      inonde.c = 11;
      inonde.cible = 1;
      await attendre(700, g);
      ouvert?.call();
      return;
    }
    px.faire(Geste.aucun);
    px.regarder(0, 0);
    px.cote = geo.rtl ? 1 : -1;
    px.assis.cible = 0;
    px.tourne.cible = 1;
    px.pietine = 3;
    await attendre(640, g);
    taire();
    px.anticipe();
    await attendre(170, g);
    px.allerA(-0.09, travers: 0, vitesse: 0.36);
    await jusqua(() => px.q < 0.34, g);
    eclat.cible = 1.42;
    await jusqua(() => px.q < 0.03, g);
    inonde.k = 2.4;
    inonde.c = 3.2;
    inonde.cible = 1;
    await jusqua(() => inonde.x > 0.975, g, max: 7000);
    ouvert?.call();
  }
}

// ───────────────────────── Les peintres ─────────────────────────
final Paint _trait = Paint();
final Paint _plein = Paint();

/// Vingt poussières lentes dans le faisceau : (angle, distance, phase, taille).
final List<List<double>> _poussieres = () {
  final math.Random h = math.Random(21);
  return List<List<double>>.generate(20, (int i) => <double>[(h.nextDouble() - 0.5) * 1.5, 0.14 + h.nextDouble() * 0.9, h.nextDouble() * 6.28, 0.7 + h.nextDouble() * 0.8]);
}();

void _peindrePoussieres(Canvas c, Theatre th, int de, int a, double force) {
  final ui.Image? grainP = Atelier.poussiere;
  if (grainP == null || force < 0.01) return;
  final Geo g = th.geo;
  final Offset o = g.lueur + Offset(0, g.lw * 0.1);
  final double t = th.reduit ? 0 : th.temps;
  final List<RSTransform> tr = <RSTransform>[];
  final List<Rect> src = <Rect>[];
  final List<Color> cs = <Color>[];
  for (int i = de; i < a; i++) {
    final List<double> p = _poussieres[i];
    final double ang = p[0] + 0.06 * math.sin(t * 0.19 + p[2]), d = p[1] + 0.035 * math.sin(t * 0.13 + p[2] * 2);
    final Offset pos = o + Offset(math.sin(ang) * d * g.H * 0.95 + 5 * math.sin(t * 0.31 + p[2] * 3), math.cos(ang) * d * g.H * 0.92 - 7 * math.sin(t * 0.23 + p[2]));
    final double al = force * (0.5 + 0.5 * math.sin(t * 0.45 + p[2] * 3)) * math.exp(-d * d / 0.7) * math.exp(-p[0] * p[0] / 0.5);
    final double r = (1.3 + 2.6 * d) * p[3] * (g.grand ? 1.5 : 1) * (i >= 14 ? 1.7 : 1);
    tr.add(RSTransform.fromComponents(rotation: 0, scale: r / 16, anchorX: 16, anchorY: 16, translateX: pos.dx, translateY: pos.dy));
    src.add(const Rect.fromLTWH(0, 0, 32, 32));
    cs.add(Teinte.coeur.withValues(alpha: cl(al * (i >= 14 ? 0.5 : 1))));
  }
  c.drawAtlas(grainP, tr, src, cs, BlendMode.modulate, null, Paint()..filterQuality = FilterQuality.medium);
}

/// Le décor : ciel, route, dalles, lumière de la porte sur l'espace, ombre de Praxis, logo.
class DecorPeintre extends CustomPainter {
  DecorPeintre(this.th) : super(repaint: th);
  final Theatre th;
  @override
  void paint(Canvas c, Size taille) {
    final Geo g = th.geo;
    final Rect ch = g.champ;
    final double hz = g.horizon, H = g.H, lum = th.lum, lv = cl(lum);
    c.save();
    c.clipRect(ch);
    // 1. Le ciel et le sol : un seul dégradé, calé sur l'horizon (aucune couture).
    c.save();
    c.translate(0, hz);
    c.scale(1, H);
    _plein
      ..shader = Atelier.memo(
          'fond',
          () => ui.Gradient.linear(const Offset(0, -0.9), const Offset(0, 1.5), <Color>[
                Teinte.cielHaut,
                melange(Teinte.cielHaut, Teinte.cielHorizon, 0.5),
                Teinte.cielHorizon,
                melange(Teinte.cielHorizon, Teinte.solProche, 0.55),
                Teinte.solProche,
              ], <double>[0, 0.2, 0.375, 0.5, 1]))
      ..color = T.noir;
    c.drawRect(Rect.fromLTRB(ch.left, (ch.top - hz) / H - 0.1, ch.right, (ch.bottom - hz) / H + 0.1), _plein);
    c.restore();
    // 2. L'aura derrière le logo : un seul dégradé, gaussien.
    Atelier.etaler(c, Atelier.aura, g.lueur, g.lw * 1.75, g.lw * 1.75, cl(0.10 + 0.9 * lum));
    // 3. La route : deux bords droits qui convergent vers la porte ; elle se fond dans la lumière au loin.
    // De biais, les traverses penchent : la route se prolonge plus bas pour couvrir tout le champ.
    final double zNear = math.max(g.deBiais ? 0.1 : 0.2, H / (ch.bottom + 60 - hz) * (g.deBiais ? 0.45 : 1));
    final VuePorte vue = g.vue(th.ouverture);
    final Path route = Path()
      ..addPolygon(<Offset>[g.pied(-1), g.pied(1), g.route(zNear, 1), g.route(zNear, -1)], true)
      // Sous l'arche : le seuil, la route qui continue jusqu'au plan de la porte, vers le point de fuite.
      ..addPolygon(<Offset>[for (final Offset p in vue.seuil) g.ecran(p) + Offset(0, p.dy == symboleHauteur ? 0.5 : -0.5)], true);
    c.save();
    c.translate(0, hz);
    c.scale(1, H);
    _plein.shader = Atelier.memo('route${g.Z.toStringAsFixed(1)}', () {
      final double e = 1 / g.Z;
      return ui.Gradient.linear(Offset.zero, const Offset(0, 1), <Color>[
        Teinte.route.withValues(alpha: 0.45),
        Teinte.route.withValues(alpha: 0.6),
        Teinte.route.withValues(alpha: 0.85),
        Teinte.route,
      ], <double>[e, e + 0.06, e + 0.2, e + 0.45]);
    });
    c.drawPath(route.transform((Matrix4.identity()..scaleByDouble(1, 1 / H, 1, 1)..translateByDouble(0, -hz, 0, 1)).storage), _plein);
    c.restore();
    // 4. Les dalles : rangées d'égale profondeur réelle, en appareil décalé.
    final int n = th.rangees;
    final Color dalle = Teinte.dalle, brume = melange(Teinte.cielHorizon, Teinte.coeur, 0.5);
    for (int i = n - 1; i >= 0; i--) {
      final double za = Theatre.zDepart + i * Theatre.zPas, zb = za + Theatre.zPas * 0.93;
      final double ya = hz + H / za, yb = hz + H / zb;
      if (yb > ch.bottom + (g.deBiais ? ch.height * 0.5 : 2) || ya - yb < 0.6) continue;
      final double loin = lisse2(1.5, g.Z, (za + zb) / 2);
      final double lit = cl(th.dalles[i].x, 0, 1.25);
      final Color base = melange(dalle, brume, loin * 0.85).withValues(alpha: 1 - 0.7 * loin * loin);
      final List<double> coupes = i.isEven ? const <double>[-1, 0, 1] : const <double>[-1, -0.5, 0.5, 1];
      const double joint = 0.035;
      if (lit > 0.01) {
        final Offset m = g.solZ((za + zb) / 2);
        Atelier.poser(c, m, g.demiRoute((za + zb) / 2, interieur: true) * 1.22, (ya - yb) * 1.15 + 5, Teinte.lueurDalle, (T.s ? 0.55 : 0.75) * math.min(1, lit));
      }
      for (int j = 0; j < coupes.length - 1; j++) {
        final double f0 = coupes[j] * 0.97 + (j == 0 ? 0 : joint), f1 = coupes[j + 1] * 0.97 - (j == coupes.length - 2 ? 0 : joint);
        final Offset p0 = g.route(za, f0, interieur: true), p1 = g.route(za, f1, interieur: true), p2 = g.route(zb, f1, interieur: true), p3 = g.route(zb, f0, interieur: true);
        final Path forme = Path()..addPolygon(<Offset>[p0, p1, p2, p3], true);
        _plein
          ..shader = null
          ..color = lit > 0.01 ? Color.lerp(base, Teinte.dalleAllumee, math.min(1, lit))! : base;
        c.drawPath(forme, _plein);
        // L'arête tournée vers la porte accroche la lumière.
        final double ar = (0.55 * (1 - loin) + 0.25) * lv * (T.s ? 0.32 : 1);
        if (ya - yb > 2.5 && ar > 0.02) {
          _trait
            ..color = Teinte.coeur.withValues(alpha: cl(ar))
            ..strokeWidth = math.max(0.7, 1.6 / za)
            ..style = PaintingStyle.stroke;
          c.drawLine(p3, p2, _trait);
        }
        if (lit > 0.01) {
          _trait
            ..color = Teinte.lueurDalle.withValues(alpha: (T.s ? 0.5 : 0.8) * math.min(1, lit))
            ..strokeWidth = math.max(0.7, 1.6 / za)
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round;
          c.drawPath(forme, _trait);
        }
      }
    }
    // 5. La nappe de lumière au sol, puis son reflet sur les dalles, devant la porte.
    // Elle tombe dans l'axe de la route : la nappe est couchée le long de sa ligne médiane.
    final double ry = H * 0.66, penche = (g.xProche - g.porte.dx) / (g.yProche - g.porte.dy);
    void dansLAxe(VoidCallback peindre) {
      c.save();
      c.translate(g.porte.dx, g.porte.dy);
      c.skew(penche, 0);
      c.translate(-g.porte.dx, -g.porte.dy);
      peindre();
      c.restore();
    }

    dansLAxe(() => Atelier.etaler(c, Atelier.nappe, g.porte + Offset(0, ry * 0.9), g.lw * 2.0, ry, cl(lum * (T.s ? 0.9 : 1))));
    c.save();
    c.clipPath(route);
    final double ry2 = H * 0.46;
    dansLAxe(() => Atelier.etaler(c, Atelier.nappe, g.porte + Offset(0, ry2 * 0.9), g.lw * 0.34, ry2, cl(lum * 0.7)));
    c.restore();
    // 6. L'ombre de Praxis : portée (vers nous, à l'opposé de la porte) et de contact.
    _ombres(c, g, lum);
    // 7. La porte, debout au bout de la route et vue du même œil : le disque de face, la face
    // de l'arche, son tableau qui fuit vers le point de fuite, la porte au fond, le battant sur
    // ses gonds, et la lumière dans le jour.
    final Color jourCoeur = melange(Teinte.cielHorizon, Teinte.coeur, cl(0.2 + 0.8 * lum));
    final Color jourBord = melange(jourCoeur, Teinte.logo, 0.14);
    c.save();
    final Matrix4? rotation = g.rotationPorte;
    if (rotation != null) c.transform(rotation.storage);
    c.translate(g.logo.left, g.logo.top);
    c.scale(g.k);
    final ui.Shader jour = ui.Gradient.radial(vue.lueur, 380, <Color>[jourCoeur, jourCoeur, jourBord], const <double>[0, 0.34, 1]);
    c.save();
    c.clipPath(_ouvertureDisque);
    // La face de l'arche, plate, dans le plan du disque (elle passe d'une unité sous le tableau :
    // aucune couture) ; puis, sur le seuil, le pied des bordures qui filent jusqu'à la porte.
    _plein
      ..shader = null
      ..color = jourBord;
    c.drawPath(_faceArche, _plein);
    for (final double cote in const <double>[-1, 1]) {
      final Offset a = Offset(_axePorte + cote * _demiInt, symboleHauteur + 0.5), b = Offset(_axePorte + cote * _demiFace, symboleHauteur + 0.5);
      c.drawPath(Path()..addPolygon(<Offset>[a, b, vue.versFond(b), vue.versFond(a)], true), _plein);
    }
    // Le tableau : les murs et la voûte, éclairés par la porte.
    c.clipPath(_ouvertureTableau);
    c.clipPath(vue.murs);
    _plein
      ..color = T.noir
      ..shader = jour;
    c.drawPaint(_plein);
    // La porte, au fond ; puis le jour que laisse le battant.
    c.clipPath(vue.porte);
    _plein
      ..shader = null
      ..color = Teinte.logo;
    c.drawPaint(_plein);
    _plein
      ..color = T.noir
      ..shader = jour;
    c.drawPath(vue.jour, _plein);
    c.restore();
    _plein
      ..shader = null
      ..color = Teinte.logo;
    c.drawPath(symbole[1], _plein);
    c.restore();
    // Les deux pieds de l'arche touchent le sol, et les bordures de la route partent de là : une
    // seule ligne, du fond du tableau jusqu'au bord de l'écran.
    for (final double cote in const <double>[-1, 1]) {
      final Path bordure = Path()..addPolygon(<Offset>[g.pied(cote), g.route(zNear, cote), g.route(zNear, cote, interieur: true), g.pied(cote, interieur: true)], true);
      _plein
        ..shader = null
        ..color = jourBord;
      c.drawPath(bordure, _plein);
    }
    Atelier.etaler(c, Atelier.bloom, g.lueur, g.lw * 0.46, g.lw * 0.56, cl(lum * 0.82));
    // 8. Les rais, très discrets, qui sortent de l'ouverture ; les poussières dans le faisceau.
    final ui.Image? rais = Atelier.rais;
    if (rais != null && lum > 0.02) {
      final double cote = H * 1.25;
      final Offset o = g.lueur + Offset(0, g.lw * 0.12);
      for (int i = 0; i < 2; i++) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate((th.reduit ? 0 : math.sin(th.temps * (i == 0 ? 0.23 : 0.17) + i * 2) * 0.035) + (g.xProche - g.porte.dx) / g.H * -0.35);
        if (i == 1) c.scale(-1, 1);
        c.drawImageRect(
            rais,
            const Rect.fromLTWH(0, 0, 256, 256),
            Rect.fromLTWH(-cote / 2, 0, cote, cote),
            Paint()
              ..filterQuality = FilterQuality.medium
              ..colorFilter = ColorFilter.mode(Teinte.coeur, BlendMode.srcIn)
              ..color = T.noir.withValues(alpha: cl((T.s ? 0.075 : 0.20) * lum * (i == 0 ? 1 : 0.7))));
        c.restore();
      }
    }
    _peindrePoussieres(c, th, 0, 20, cl(lum) * (T.s ? 0.55 : 0.95));
    // 9. Quand la porte faiblit, toute la scène s'assombrit ; puis vignettage et grain.
    if (lv < 0.98) {
      _plein
        ..shader = null
        ..color = (T.s ? T.noir : melange(T.nuit, Teinte.violet, 0.3)).withValues(alpha: (T.s ? 0.42 : 0.30) * (1 - lv));
      c.drawRect(ch, _plein);
    }
    Atelier.etaler(c, Atelier.vignette, ch.center, ch.width * 0.80, ch.height * 0.74, 1, cadre: const Rect.fromLTRB(-2, -2, 2, 2));
    final ui.Shader? grain = Atelier.grainTuile;
    if (grain != null) {
      _plein
        ..shader = grain
        ..color = T.noir.withValues(alpha: T.s ? 0.05 : 0.032);
      c.drawRect(ch, _plein);
      _plein.shader = null;
    }
    c.restore();
  }

  void _ombres(Canvas c, Geo g, double lum) {
    final Corps px = th.px;
    final double op = px.opacite * (1 - px.surex);
    if (op < 0.02) return;
    final double zb = g.z(px.q), l = g.tProche / zb, u = l / 200;
    final Offset pied = g.solZ(zb, px.lat.x);
    final double force = Teinte.ombreForce * op;
    final double saut = cl(-px.y / 200 * 2.4);
    // Portée : la porte est derrière lui, l'ombre vient vers nous, dans l'axe porte → Praxis.
    // Directeur, 20/11/2026 : « vu que Praxis a la lumière sur le dos, l'ombre doit changer de
    // grandeur et d'intensité : plus il s'éloigne de la porte, moins l'ombre est grande, car il
    // s'éloigne de la source de la lumière. » Sa longueur à l'écran et sa force décroissent donc
    // d'un seul trait avec le chemin parcouru (q : 0 à la porte, 1 au premier plan), jusqu'à une
    // ombre courte et légère à l'arrivée. L'ancienne longueur, mesurée en profondeur réelle,
    // croissait avec la distance à la porte : arrivé au premier plan, l'ombre passait devant
    // l'œil, s'élargissait sans fin à l'écran et, la route partant en biais, filait sous la carte
    // du formulaire.
    final ui.Shader? tex = Atelier.ombreTexture;
    final double loin = 1 - cl(px.q);
    // Elle naît quand il sort de la lumière de la porte, sans attendre qu'il ait pris ses couleurs.
    // Sa force va de celle d'une ombre franche (0,85), près de la porte, à la force ordinaire des
    // ombres du thème, à l'arrivée.
    final double forceP = (Teinte.ombreForce + (0.85 - Teinte.ombreForce) * loin) * px.opacite * lisse2(0, 0.14, px.q);
    final double portee = cl(0.12 + 0.88 * lum) * (1 - 0.35 * saut);
    if (tex != null && forceP * portee > 0.01) {
      final double z0 = zb * 1.035;
      // La longueur, à l'écran, en largeurs du Praxis du premier plan ; puis la profondeur du bout.
      final double longueur = z0 - 1 / (1 / zb + g.tProche * (0.26 + 1.1 * loin) / g.H);
      // À l'ordinateur, aucun bord de l'ombre ne passe du côté de la carte du formulaire.
      final double? borne = g.cadre == CadreScene.large ? (g.rtl ? g.carte.right + 8 : g.carte.left - 8) : null;
      const int n = 16;
      final Float32List pos = Float32List((n + 1) * 4), uv = Float32List((n + 1) * 4);
      final Int32List cs = Int32List((n + 1) * 2);
      final int teinte = Teinte.ombre.withValues(alpha: cl(forceP * portee)).toARGB32();
      int k = 0;
      for (int i = 0; i <= n; i++) {
        final double t = i / n;
        final double z = z0 - t * longueur;
        // Les deux bords de l'ombre suivent la traverse, comme les dalles ; elle s'évase davantage
        // près de la porte.
        final double demi = 0.43 * (1 + (0.2 + 0.5 * loin) * t);
        final Offset o1 = g.solZ(z, px.lat.x - demi), o2 = g.solZ(z, px.lat.x + demi);
        double dansLaZone(double x) => borne == null ? x : (g.rtl ? math.max(x, borne) : math.min(x, borne));
        pos[k * 4] = dansLaZone(o1.dx);
        pos[k * 4 + 1] = o1.dy;
        pos[k * 4 + 2] = dansLaZone(o2.dx);
        pos[k * 4 + 3] = o2.dy;
        uv[k * 4] = 0;
        uv[k * 4 + 1] = t * Atelier.ombreH;
        uv[k * 4 + 2] = Atelier.ombreL.toDouble();
        uv[k * 4 + 3] = t * Atelier.ombreH;
        cs[k * 2] = teinte;
        cs[k * 2 + 1] = teinte;
        k++;
      }
      if (k >= 2) {
        final ui.Vertices v = ui.Vertices.raw(ui.VertexMode.triangleStrip, Float32List.sublistView(pos, 0, k * 4),
            textureCoordinates: Float32List.sublistView(uv, 0, k * 4), colors: Int32List.sublistView(cs, 0, k * 2));
        c.drawVertices(v, BlendMode.modulate, Paint()..shader = tex);
        v.dispose();
      }
    }
    // Contact : sombre et net sous le corps et sous chaque pied posé ; plus pâle quand le pied se lève.
    final double as_ = cl(px.assis.x);
    Atelier.poser(c, pied + Offset(0, l * (0.012 + 0.03 * as_)), l * (0.47 + 0.05 * as_) * (1 - 0.3 * saut), l * (0.075 + 0.02 * as_), Teinte.ombre, force * (0.85 + 0.25 * as_) * (1 - 0.6 * saut));
    for (final Pied f in <Pied>[px.pg, px.pd]) {
      final (double x, double yy, double sc, double lev) = px.piedVu(f);
      final Offset o = pied + Offset((x - 100) * u, (yy - 206 + 8 * sc) * u);
      Atelier.poser(c, o, 22 * sc * u * (1 + 0.5 * lev), 6.5 * sc * u * (1 + 0.3 * lev), Teinte.ombre, force * 1.5 * (1 - 0.78 * cl(lev)) * (1 - 0.6 * saut));
    }
  }

  @override
  bool shouldRepaint(DecorPeintre o) => true;
}

/// Le premier plan : Praxis, les poussières proches, les mots, puis l'iris de lumière.
class ScenePeintre extends CustomPainter {
  ScenePeintre(this.th) : super(repaint: th);
  final Theatre th;
  @override
  void paint(Canvas c, Size taille) {
    final Geo g = th.geo;
    final Corps px = th.px;
    peindrePraxis(c, px, th.piedPraxis, th.largeurPraxis, th.eclairage);
    // Les étincelles : de sa main vers la porte.
    for (final Etincelle e in th.etincelles) {
      final double t = lisse(e.t);
      for (int i = 0; i < 4; i++) {
        final double tt = cl(t - i * 0.05);
        final Offset p = Offset.lerp(e.de, g.lueur, tt)! + Offset(math.sin(tt * math.pi) * 26 * (g.rtl ? -1 : 1), -math.sin(tt * math.pi) * 30);
        final double r = (9 - i * 1.6) * (1 - 0.55 * tt);
        Atelier.poser(c, p, r, r, Teinte.coeur, (1 - i * 0.22) * math.sin(cl(e.t * 1.1) * math.pi).clamp(0.0, 1.0) * 0.95 + 0.05);
        if (i == 0) Atelier.poser(c, p, r * 2.4, r * 2.4, Teinte.loin, 0.45);
      }
    }
    // Les mots : nés à sa bouche, posés en une ligne, puis envolés vers la porte.
    final Parole? pa = th.parole;
    if (pa != null) {
      for (final MotVol m in pa.mots) {
        if (!m.ne) continue;
        final double t = m.t.x, e = cl(m.s.x);
        Offset pos;
        double sc, o;
        if (th.reduit) {
          pos = m.fin;
          sc = 1;
          o = cl(t) * (1 - e);
        } else {
          final double tt = cl(t, 0, 1.2);
          pos = Offset.lerp(m.naissance, m.fin, tt)! + Offset(0, -math.sin(math.pi * cl(tt)) * 14);
          sc = 0.12 + 0.88 * tt;
          o = cl(tt * 4);
          pos += (g.lueur - m.fin) * (e * e * 0.78) + Offset(0, -22 * math.sin(e * math.pi));
          sc *= 1 - 0.62 * e;
          o *= 1 - e * e * e;
        }
        if (o < 0.01) continue;
        final Size s = m.taille * sc;
        _plein
          ..shader = null
          ..filterQuality = FilterQuality.medium
          ..color = T.noir.withValues(alpha: o);
        c.drawImageRect(m.image, Rect.fromLTWH(0, 0, m.image.width.toDouble(), m.image.height.toDouble()), Rect.fromCenter(center: pos, width: s.width, height: s.height), _plein);
      }
    }
    // La lumière qui ouvre l'application : un iris à bord très doux, sans flash.
    final double f = cl(th.inonde.x);
    if (f > 0.001) {
      if (th.reduit) {
        c.drawRect(Offset.zero & taille, Paint()..color = T.fond.withValues(alpha: f));
      } else {
        final double diag = math.sqrt(taille.width * taille.width + taille.height * taille.height);
        final double r = diag * (0.16 + 2.1 * f);
        Atelier.etaler(c, Atelier.iris, g.lueur, r, r, lisse2(0, 0.22, f), cadre: const Rect.fromLTRB(-1, -1, 1, 1));
        final double fin = lisse2(0.80, 1.0, f);
        if (fin > 0.001) c.drawRect(Offset.zero & taille, Paint()..color = Teinte.irisFin.withValues(alpha: fin));
      }
    }
  }

  @override
  bool shouldRepaint(ScenePeintre o) => true;
}
