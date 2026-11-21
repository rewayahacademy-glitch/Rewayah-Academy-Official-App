// Praxis en volume : la tête lilas et les yeux du Praxis d'origine (vivant.dart, inchangés),
// une toque construite en trois dimensions (calotte, plateau, cordon, pompon en pendule),
// des mains, des pieds et une bouche. Il marche avec du poids : ses pieds se posent au sol
// et n'y glissent pas ; tout le reste suit au ressort.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'gestes_praxis.dart';
import 'lumiere_entree.dart';
import 'outils_entree.dart';

/// Comment la porte éclaire Praxis à cet instant.
class Eclairage {
  const Eclairage({required this.couleur, required this.dir, this.contre = 0.6, this.brume = 0, this.surex = 0, this.niveau = 1});
  final Color couleur; // la couleur de la lumière
  final Offset dir; // vers la porte, à l'écran (unitaire)
  final double contre; // force du liseré de contre-jour
  final double brume; // perspective atmosphérique (0 près, 1 loin)
  final double surex; // surexposition : 1 = silhouette de lumière
  final double niveau; // lumière générale de la scène (1 normale, 0 éteinte)
}

/// Un pied : posé à un endroit du sol, ou en l'air entre deux endroits.
class Pied {
  Pied(this.cote);
  final double cote; // -1 à gauche de l'écran, +1 à droite
  double a = 0, x = 0; // posé : le long du chemin (logarithme de la profondeur), en travers (largeurs)
  double a0 = 0, x0 = 0, a1 = 0, x1 = 0, t = 1, duree = 0.2, hauteur = 1;
  bool get enLair => t < 1;
  double get leve => enLair ? math.sin(math.pi * t) * hauteur : 0;
  double get _e => lisse(t);
  double get posA => enLair ? a0 + (a1 - a0) * _e : a;
  double get posX => enLair ? x0 + (x1 - x0) * _e : x;
}

/// L'état du corps de Praxis. Les unités sont celles du dessin d'origine (boîte de 200).
class Corps {
  // ───── Le chemin : q vaut 0 à la porte, 1 au premier plan (logarithme de la profondeur) ─────
  double q = -0.08, vq = 0, qCible = -0.08, vMax = 0.25;
  final R lat = R(0, k: 9, c: 6.1); // écart en travers de la route, en largeurs de Praxis
  double lnZ = 2.3, hc = 1.4; // donnés par la scène : profondeur de la route, hauteur de la caméra
  final Pied pg = Pied(-1), pd = Pied(1);
  static const double ecart = 0.125;
  int pietine = 0;
  bool enMarche = false;
  // ───── Orientation et posture ─────
  final R tourne = R(0, k: 42, c: 10.5); // 0 de face, 1 de dos
  double cote = -1; // de quel côté il se tourne
  final R assis = R(0, k: 60, c: 12);
  final R gx = R(0, k: 240, c: 22), gy = R(0, k: 240, c: 22);
  final R penche = R(0, k: 120, c: 10), roulis = R(0, k: 150, c: 14), tangage = R(0, k: 90, c: 9);
  final R ecrase = R(0, k: 320, c: 10), etire = R(0, k: 160, c: 12), bob = R(0, k: 900, c: 44);
  final R hoche = R(0, k: 300, c: 16), secoue = R(0, k: 260, c: 14);
  // ───── La toque ─────
  final R chapeau = R(0, k: 240, c: 9), toqueRoulis = R(0, k: 110, c: 6.5);
  double pend = 0, pendV = 0; // le pompon : un pendule amorti
  double _ax = 0, _ay = 0, _vxAvant = 0, _vyAvant = 0, _pxAvant = 0, _pyAvant = 0;
  // ───── Le visage. Les yeux gardent le dessin d'origine ; ils s'ouvrent ou se resserrent un peu. ─────
  final R ouvert = R(1, k: 320, c: 24), taille = R(1, k: 300, c: 16), pupille = R(0, k: 260, c: 20);
  final R sourcil = R(0, k: 300, c: 15), sourcilPente = R(0, k: 220, c: 16), sourcilVu = R(0, k: 200, c: 20);
  final R sourire = R(0.3, k: 220, c: 16), ouvre = R(0, k: 520, c: 26), large = R(1, k: 220, c: 16), rond = R(0, k: 260, c: 18);
  final R rouge = R(0, k: 60, c: 14);
  // ───── Mains : position autour du centre du corps (x, y, profondeur) ─────
  final R mgx = R(-92, k: 150, c: 14), mgy = R(54, k: 150, c: 14), mgz = R(14, k: 150, c: 16);
  final R mdx = R(92, k: 150, c: 14), mdy = R(54, k: 150, c: 14), mdz = R(14, k: 150, c: 16);
  final R objet = R(0, k: 120, c: 14);
  // ───── Apparition (mode « animations réduites » : fondu) ─────
  final R fondu = R(1, k: 60, c: 15);
  double y = 0, vy = 0; // saut, en unités
  double clin = 0, _prochainClin = 1.8, temps = 0, tGeste = 0;
  double _microX = 0, _microY = 0, _prochainMicro = 2.6, regardX = 0, regardY = 0;
  bool parle = false, reduit = false;
  Geste geste = Geste.aucun;
  Expr expr = Expr.neutre;

  /// Où il pointe ([Geste.pointe]), donné par la scène : (0, 1), vers le bas, le geste d'origine
  /// (formulaire sous lui) ; sinon un vecteur unité vers le côté du formulaire (droite ou gauche).
  Offset vise = const Offset(0, 1);

  /// L'allonge de la main qui montre de côté, du centre du corps au centre de la main.
  double allonge = 112;
  final math.Random _h = math.Random(7);

  late final List<R> _tous = <R>[
    lat, tourne, assis, gx, gy, penche, roulis, tangage, ecrase, etire, bob, hoche, secoue, chapeau, toqueRoulis, ouvert, taille, pupille,
    sourcil, sourcilPente, sourcilVu, sourire, ouvre, large, rond, rouge, mgx, mgy, mgz, mdx, mdy, mdz, objet, fondu,
  ];

  // ───── Ce que la scène lit ─────
  /// Dans la porte, il est une silhouette de lumière ; il prend ses couleurs en s'éloignant d'elle.
  double get surex => 1 - lisse2(0.0, 0.34, q);
  double get opacite => reduit ? cl(fondu.x) : lisse2(-0.07, 0.02, q) * cl(fondu.x);
  double get dos => 0.5 - 0.5 * math.cos(tourne.x * math.pi);
  double get lacet => tourne.x * math.pi * cote + gx.x * 0.07 + secoue.x * 0.34;
  double get tangageVu => gy.x * 0.05 + tangage.x * 0.07 + hoche.x * 0.10;
  bool get arrive => (qCible - q).abs() < 0.004 && vq.abs() < 0.02 && (lat.cible - lat.x).abs() < 0.02 && lat.v.abs() < 0.05;
  double get hauteurCorps => y + bob.x + assis.x * 24;

  void regarder(double x, double y) {
    regardX = cl(x, -1, 1);
    regardY = cl(y, -1, 1);
  }

  void allerA(double cible, {double? travers, double? vitesse}) {
    qCible = cible;
    if (travers != null) lat.cible = travers;
    if (vitesse != null) vMax = vitesse;
    if (reduit) {
      q = cible;
      vq = 0;
      lat.x = lat.cible;
      lat.v = 0;
      _reposerPieds();
    }
  }

  void placer(double position, {double travers = 0}) {
    q = qCible = position;
    vq = 0;
    lat.x = lat.cible = travers;
    lat.v = 0;
    _reposerPieds();
  }

  void _reposerPieds() {
    for (final Pied f in <Pied>[pg, pd]) {
      f.a = q * lnZ;
      f.x = lat.x + f.cote * ecart;
      f.t = 1;
    }
  }

  void sauter(double force) {
    if (reduit) return;
    vy = -force;
  }

  /// Avant de partir : il se ramasse.
  void anticipe() {
    if (reduit) return;
    ecrase.v += 1.7;
    tangage.v -= 4;
  }

  /// Un sursaut : petit saut, la toque se soulève.
  void sursaut() {
    sauter(250);
    chapeau.v -= 330;
    pendV += 7;
    ecrase.v -= 2.4;
  }

  void poser(Expr e) {
    expr = e;
    // ou : ouverture des yeux (1 = le dessin d'origine) ; ta : taille ; pu : la pupille monte ;
    // sc, sp : sourcils (hauteur, pente) ; sv : sourcils visibles ; so, bo, la, ro : bouche.
    double ou = 1, ta = 1, pu = 0, sc = 0, sp = 0, sv = 0, so = 0.3, bo = 0, la = 1, ro = 0, rg = 0;
    switch (e) {
      case Expr.neutre:
        so = 0.3;
      case Expr.sourire:
        so = 0.9;
        la = 1.1;
        pu = 0.25;
      case Expr.joie:
        ou = 0.9;
        pu = 0.6;
        so = 1;
        bo = 0.6;
        la = 1.2;
        rg = 0.6;
        sc = 0.5;
        sv = 0.5;
      case Expr.etonne:
        ou = 1.06;
        ta = 1.05;
        sc = 1;
        sv = 0.9;
        so = 0;
        bo = 0.7;
        ro = 1;
      case Expr.reflexion:
        ou = 0.94;
        sc = 0.3;
        sp = -0.55;
        sv = 0.8;
        so = -0.05;
        la = 0.7;
      case Expr.desole:
        ou = 0.92;
        sc = 0.2;
        sp = 0.9;
        sv = 0.9;
        so = -0.55;
        la = 0.85;
      case Expr.attente:
        ou = 0.92;
        so = 0.1;
        la = 0.75;
      case Expr.paisible:
        ou = 0.08;
        so = 0.7;
      case Expr.gene:
        ou = 0.95;
        sp = 0.5;
        sc = 0.4;
        sv = 0.7;
        so = 0.5;
        la = 0.8;
        rg = 1;
      case Expr.concentre:
        ou = 0.9;
        sp = -0.35;
        sv = 0.6;
        so = 0.15;
        la = 0.6;
      case Expr.baille:
        ou = 0.08;
        sc = 0.6;
        sv = 0.6;
        so = 0;
        bo = 1.1;
        ro = 0.9;
    }
    ouvert.cible = ou;
    // Les yeux gardent la taille du dessin d'origine dans toutes les expressions.
    taille.cible = 1;
    assert(ta > 0);
    pupille.cible = pu;
    sourcil.cible = sc;
    sourcilPente.cible = sp;
    sourcilVu.cible = sv;
    sourire.cible = so;
    ouvre.cible = bo;
    large.cible = la;
    rond.cible = ro;
    rouge.cible = rg;
    pendV += 2.5;
  }

  /// Il montre le formulaire : la main pointe vers lui ([vise]) et les pupilles le regardent.
  void montrer() {
    faire(Geste.pointe);
    regarder(vise.dx * 0.9, vise.dy * 0.9);
  }

  void faire(Geste g) {
    geste = g;
    tGeste = 0;
    objet.cible = (g == Geste.balaie || g == Geste.range || g == Geste.cle || g == Geste.montre) ? 1 : 0;
    if (g == Geste.joie) sauter(320);
    etire.cible = g == Geste.etire ? 1 : 0;
    if (g == Geste.surPlace) pietine = 8;
    if (g == Geste.chapeau && !reduit) chapeau.v -= 210;
  }

  /// Où vont les mains pour le geste en cours : (x, y, profondeur), gauche puis droite.
  (double, double, double, double, double, double) _mains() {
    final double t = tGeste, a = reduit ? 0.3 : 1;
    final double souffle = math.sin(temps * 2.1) * 2.5;
    double gx_ = -92, gy_ = 54 + souffle, gz_ = 14, dx_ = 92, dy_ = 54 + souffle, dz_ = 14;
    switch (geste) {
      case Geste.aucun || Geste.hoche || Geste.non || Geste.surPlace:
        break;
      case Geste.salut:
        if (t < 2.3) {
          dx_ = 86 + math.sin(t * 9.5) * 15 * a;
          dy_ = -60;
          dz_ = 20;
        }
      case Geste.joie:
        final double sec = math.sin(t * 15) * 5 * a;
        gx_ = -84 + sec;
        gy_ = -76;
        dx_ = 84 - sec;
        dy_ = -76;
      case Geste.montre:
        gx_ = -44;
        gy_ = 66;
        gz_ = 60;
      case Geste.etire:
        gx_ = -58;
        gy_ = -124 - math.sin(t * 2) * 6 * a;
        dx_ = 58;
        dy_ = gy_;
      case Geste.balaie:
        final double x = math.sin(t * 4.2) * 34 * a;
        gx_ = -34 + x;
        gy_ = 62;
        gz_ = 60;
        dx_ = -8 + x;
        dy_ = 90;
        dz_ = 60;
      case Geste.range:
        final double lev = t < 1.0 ? lisse(t) : (t < 1.8 ? 1 : 1 - lisse((t - 1.8) / 0.8));
        gx_ = -34;
        gy_ = 76 - 30 * lev;
        gz_ = 60;
        dx_ = 34;
        dy_ = gy_;
        dz_ = 60;
      case Geste.souffle:
        gx_ = -34;
        gy_ = 70;
        gz_ = 60;
        dx_ = 34;
        dy_ = 70;
        dz_ = 60;
      case Geste.presque:
        dx_ = 62;
        dy_ = 6;
        dz_ = 50;
      case Geste.suivre:
        final double k = math.sin(t * 6).abs();
        dx_ = 86 - k * 22 * a;
        dy_ = -16 - k * 6 * a;
        dz_ = 30;
      case Geste.cherche:
        dx_ = 40;
        dy_ = -34 + math.sin(t * 1.6) * 2;
        dz_ = 70;
      case Geste.pied:
        gx_ = -84;
        gy_ = 32;
        dx_ = 84;
        dy_ = 32;
      case Geste.pause:
        dx_ = 60;
        dy_ = -18;
        dz_ = 90;
      case Geste.reflexion:
        dx_ = 26;
        dy_ = 84;
        dz_ = 70;
        gx_ = -60;
        gy_ = 72;
      case Geste.porte:
        dx_ = 74;
        dy_ = -92;
        dz_ = -6;
      case Geste.cle:
        dx_ = 18;
        dy_ = 60;
        dz_ = 80;
      case Geste.desole:
        final double h = t < 1.2 ? math.sin(t * 5.2).abs() * 10 * a : 0;
        gx_ = -104;
        gy_ = 30 - h;
        dx_ = 104;
        dy_ = 30 - h;
      case Geste.allume:
        dx_ = t < 0.45 ? 58 : 80;
        dy_ = t < 0.45 ? -40 : -100;
      case Geste.pointe:
        if (vise.dx == 0) {
          dx_ = 38;
          dy_ = 100 + math.sin(t * 7).abs() * 5 * a;
          dz_ = 90;
        } else {
          // Le formulaire est à côté : la main de ce côté se tend vers lui, hors du corps.
          final double portee = allonge + math.sin(t * 7).abs() * 5 * a;
          if (vise.dx > 0) {
            dx_ = vise.dx * portee;
            dy_ = vise.dy * portee;
            dz_ = 24;
          } else {
            gx_ = vise.dx * portee;
            gy_ = vise.dy * portee;
            gz_ = 24;
          }
        }
      case Geste.gene:
        dx_ = 68;
        dy_ = -58 + math.sin(t * 8) * 3 * a;
        dz_ = -30;
      case Geste.un:
        dx_ = 82;
        dy_ = -40;
        dz_ = 40;
      case Geste.envoie:
        if (t < 0.32) {
          dx_ = 30;
          dy_ = 50;
          dz_ = 70;
        } else if (t < 1.5) {
          dx_ = 52;
          dy_ = -112;
          dz_ = 0;
        }
      case Geste.coeur:
        dx_ = 44;
        dy_ = 76;
        dz_ = 80;
      case Geste.applaudit:
        final double k = math.sin(t * 13).abs() * 15 * a;
        gx_ = -19 - k;
        gy_ = 86;
        gz_ = 80;
        dx_ = 19 + k;
        dy_ = 86;
        dz_ = 80;
      case Geste.baille:
        dx_ = 12;
        dy_ = 62;
        dz_ = 90;
      case Geste.genoux:
        gx_ = -66;
        gy_ = 70;
        gz_ = 50;
        dx_ = 66;
        dy_ = 70;
        dz_ = 50;
      case Geste.chapeau:
        dx_ = 76;
        dy_ = -100 - (t < 0.9 ? math.sin(t / 0.9 * math.pi) * 12 * a : 0);
        dz_ = 10;
      case Geste.compte:
        final double k = (t * 2.2) % 1;
        dx_ = 52 + (t * 2.2).floor() % 3 * 20;
        dy_ = 74 + math.sin(k * math.pi) * 10 * a;
        dz_ = 80;
      case Geste.respire:
        final double k = math.pow(math.sin(t * 1.1), 2).toDouble();
        gx_ = -74;
        gy_ = 44 - 54 * k * a;
        gz_ = 40;
        dx_ = 74;
        dy_ = gy_;
        dz_ = 40;
    }
    return (gx_, gy_, gz_, dx_, dy_, dz_);
  }

  void pas(double dt) {
    temps += dt;
    tGeste += dt;
    // 1. Le déplacement : vitesse bornée, départ et arrêt progressifs.
    final double vAvant = vq;
    if (!reduit) {
      final double vCible = cl((qCible - q) * 3.4, -vMax, vMax);
      vq += (vCible - vq) * math.min(1, dt * 6.5);
      q += vq * dt;
      if ((qCible - q).abs() < 0.002 && vq.abs() < 0.012) {
        q = qCible;
        vq = 0;
      }
    }
    final double acc = (vq - vAvant) / dt;
    tangage.cible = cl(acc * 0.5, -1, 1) * (1 - 2 * dos);
    _pieds(dt);
    // 2. Les mains suivent le geste, et se balancent à l'opposé des pieds quand il marche.
    final (double a1, double a2, double a3, double b1, double b2, double b3) = _mains();
    final double A = q * lnZ;
    final double og = (pd.posA - A) * 150, od = (pg.posA - A) * 150; // main gauche avec le pied droit
    final bool libre = geste == Geste.aucun || geste == Geste.surPlace || geste == Geste.hoche;
    mgx.cible = a1;
    mgy.cible = a2 + (libre ? og * 0.5 - pd.leve * 4 : 0);
    mgz.cible = a3 + (libre ? og : 0);
    mdx.cible = b1;
    mdy.cible = b2 + (libre ? od * 0.5 - pg.leve * 4 : 0);
    mdz.cible = b3 + (libre ? od : 0);
    // 3. Le regard : la cible demandée, plus de petits écarts d'attente.
    _prochainMicro -= dt;
    if (_prochainMicro <= 0) {
      final bool ecart_ = _microX == 0 && _microY == 0 && !reduit;
      _microX = ecart_ ? (_h.nextDouble() - 0.5) * 0.5 : 0;
      _microY = ecart_ ? (_h.nextDouble() - 0.5) * 0.3 : 0;
      _prochainMicro = ecart_ ? 0.5 + _h.nextDouble() * 0.9 : 2.4 + _h.nextDouble() * 3.6;
    }
    gx.cible = cl(regardX + _microX, -1, 1);
    gy.cible = cl(regardY + _microY, -1, 1);
    // 4. Gestes qui touchent la tête et le corps.
    double pencheCible = 0;
    hoche.cible = 0;
    secoue.cible = 0;
    switch (geste) {
      case Geste.hoche:
        hoche.cible = tGeste < 1.3 && !reduit ? math.max(0, math.sin(tGeste * 11)) : 0;
      case Geste.non:
        secoue.cible = tGeste < 1.5 && !reduit ? math.sin(tGeste * 10) * (1 - tGeste / 1.5) : 0;
      case Geste.cherche:
        pencheCible = reduit ? 0 : math.sin(tGeste * 1.6) * 0.06;
        regarder(math.sin(tGeste * 1.6) * 0.9, -0.7);
      case Geste.suivre:
        hoche.cible = !reduit ? math.sin(tGeste * 6).abs() * 0.4 : 0;
      case Geste.reflexion:
        pencheCible = 0.07;
      case Geste.desole || Geste.gene:
        pencheCible = -0.06;
      case Geste.montre:
        pencheCible = -0.05;
      case Geste.compte:
        hoche.cible = !reduit ? math.sin(((tGeste * 2.2) % 1) * math.pi) * 0.5 : 0;
      default:
        break;
    }
    penche.cible = pencheCible;
    // Attente : le poids passe lentement d'un pied sur l'autre.
    final double repos = enMarche ? 0 : math.sin(temps * 0.9) * 0.012 + math.sin(temps * 0.37 + 1) * 0.008;
    roulis.cible = (pg.enLair ? 0.05 : (pd.enLair ? -0.05 : 0)) * (reduit ? 0 : 1) + (reduit ? 0 : repos);
    bob.cible = reduit ? 0 : -6.5 * math.max(pg.leve, pd.leve);
    toqueRoulis.cible = -roulis.v * 0.035 - lat.v * 0.05;
    for (final R r in _tous) {
      r.pas(dt);
    }
    // 5. Saut et retombée : on s'écrase en touchant le sol.
    if (y < 0 || vy != 0) {
      vy += 2100 * dt;
      y += vy * dt;
      if (y >= 0) {
        y = 0;
        ecrase.v += vy * 0.0042;
        chapeau.v += vy * 0.4;
        vy = vy > 170 ? -vy * 0.26 : 0;
      }
    }
    // 6. Clignements irréguliers, parfois doubles.
    _prochainClin -= dt;
    if (_prochainClin <= 0) {
      clin = 1;
      _prochainClin = _h.nextDouble() < 0.18 ? 0.26 : 1.6 + _h.nextDouble() * 4.2;
    }
    if (clin > 0) clin = math.max(0, clin - dt * 7.5);
    // 7. La bouche bat pendant qu'il parle.
    if (parle) {
      ouvre.cible = 0.22 + 0.55 * (0.5 + 0.5 * math.sin(temps * 17 + math.sin(temps * 5.3) * 2)).abs();
      rond.cible = 0.15 + 0.2 * math.sin(temps * 6).abs();
    }
    // 8. Le pompon : pendule amorti, entraîné par les accélérations du coin où il est attaché.
    final double px_ = lat.x * 200 + math.cos(lacet + 0.6) * 70, py_ = hauteurCorps + chapeau.x;
    final double vx_ = (px_ - _pxAvant) / dt, vy_ = (py_ - _pyAvant) / dt;
    _ax += (cl((vx_ - _vxAvant) / dt, -6000, 6000) - _ax) * math.min(1, dt * 40);
    _ay += (cl((vy_ - _vyAvant) / dt, -6000, 6000) - _ay) * math.min(1, dt * 40);
    _pxAvant = px_;
    _pyAvant = py_;
    _vxAvant = vx_;
    _vyAvant = vy_;
    final double accP = -78 * math.sin(pend) - 3.4 * pendV - 0.017 * _ax * math.cos(pend) + 0.008 * _ay * math.sin(pend + 0.4);
    pendV += (reduit ? 0 : accP) * dt;
    pend = cl(pend + pendV * dt, -1.0, 1.0);
    if (reduit) {
      pend *= 0.9;
      pendV = 0;
    }
  }

  /// Les pieds : chacun reste où il s'est posé tant que le corps ne l'a pas dépassé d'un demi-pas ;
  /// alors il se lève, passe et se repose en avant. Jamais deux pieds en l'air.
  void _pieds(double dt) {
    final double A = q * lnZ, X = lat.x, vA = vq * lnZ, vX = lat.v;
    final double vit = math.sqrt(vA * vA + vX * vX * 0.5);
    final bool bouge = vit > 0.05;
    enMarche = bouge;
    final double S = 0.20 + 0.05 * (vA.abs() - 0.5);
    for (final Pied f in <Pied>[pg, pd]) {
      if (f.enLair) {
        f.t += dt / f.duree;
        if (f.t >= 1) {
          f.t = 1;
          f.a = f.a1;
          f.x = f.x1;
          // Le contact : le corps encaisse, la toque et le pompon suivent avec retard.
          ecrase.v += 0.85 * f.hauteur;
          chapeau.v += 38 * f.hauteur;
        }
      }
    }
    if (reduit) {
      _reposerPieds();
      return;
    }
    if (assis.cible > 0.5 || pg.enLair || pd.enLair) return;
    Pied? choix;
    double pire = 0;
    for (final Pied f in <Pied>[pg, pd]) {
      final double da = A - f.a, dx = X + f.cote * ecart - f.x;
      final double err = math.sqrt(da * da / (S * S) + dx * dx / (0.17 * 0.17));
      final bool devant = bouge && (da * vA + dx * vX * 0.5) < 0;
      if (!devant && err > (bouge ? 0.5 : 0.10) && err > pire) {
        pire = err;
        choix = f;
      }
    }
    double haut = bouge ? 1 : 0.6;
    if (choix == null && pietine > 0) {
      choix = pietine.isEven ? pg : pd;
      pietine--;
      haut = 0.85;
    }
    if (choix == null) return;
    final Pied f = choix;
    f.a0 = f.a;
    f.x0 = f.x;
    f.t = 0;
    f.hauteur = haut;
    f.duree = bouge ? cl(0.42 * S / math.max(0.2, vit), 0.13, 0.25) : 0.19;
    f.a1 = A + vA * f.duree + (vA.abs() > 0.05 ? vA.sign * S * 0.5 * math.min(1, vA.abs() / 0.3) : 0);
    f.x1 = X + f.cote * ecart + vX * f.duree + (vX.abs() > 0.08 ? vX.sign * 0.07 : 0);
  }

  // ───── Géométrie partagée avec la scène (unités du dessin, sol à y = 206) ─────
  static const double rayon = 86;
  static const Offset centre = Offset(100, 108);

  /// Un pied à l'écran, dans la boîte du dessin : (x, y, échelle, levée).
  (double, double, double, double) piedVu(Pied f) {
    // L'écart en profondeur est resserré à l'écran : le pied reste près du corps.
    final double dA = (f.posA - q * lnZ) * 0.38, e = math.exp(dA);
    double x = 100 + (f.posX - lat.x) * 200 * e;
    double yy = 199 + hc * 200 * (e - 1);
    double sc = e;
    final double s = cl(assis.x);
    if (s > 0.001) {
      // Assis : les pieds partent devant lui, semelles vers nous.
      x += (100 + f.cote * 34 - x) * s;
      yy += (213 - yy) * s;
      sc += (1.16 - sc) * s;
    }
    final double tape = geste == Geste.pied && f.cote > 0 && !reduit ? math.max(0, math.sin(tGeste * 6.5)) * 0.6 : 0;
    return (x, yy, sc, f.leve + tape);
  }

  /// Projette un point du visage (posé sur la sphère au repos) après rotation de la tête.
  (double, double, double, double) surTete(double x0, double y0) {
    final double z0 = math.sqrt(math.max(1, rayon * rayon - x0 * x0 - y0 * y0));
    final double p = tangageVu, th = lacet;
    final double cp = math.cos(p), sp = math.sin(p), ct = math.cos(th), st = math.sin(th);
    final double y1 = y0 * cp + z0 * sp, z1 = z0 * cp - y0 * sp;
    final double x2 = x0 * ct + z1 * st, z2 = -x0 * st + z1 * ct;
    return (x2, y1, z2, cl(z2 / math.max(8, z1), 0, 1.06));
  }

  /// Le point de la bouche, dans la boîte du dessin.
  Offset get bouche {
    final (double x, double yy, _, _) = surTete(3, 58);
    return Offset(100 + x, 108 + yy + hauteurCorps);
  }
}

// ───────────────────────── Le peintre ─────────────────────────
final Map<int, ui.Shader> _degrades = <int, ui.Shader>{};
ui.Shader _memo(int cle, ui.Shader Function() f) {
  if (_degrades.length > 160) _degrades.clear();
  return _degrades[cle] ??= f();
}

/// Le volume d'une boule (repère unité) : éclairée de face par une ambiance douce venue d'en
/// haut, plus sombre vers le bas. La valeur seule change : lilas vers encre.
ui.Shader _volume(Color clair, Color base, Color mi, Color ombre) => _memo(
    Object.hash(1, clair, base, mi, ombre),
    () => ui.Gradient.radial(const Offset(-0.24, -0.40), 1.78, <Color>[clair, melange(clair, base, 0.6), base, melange(base, mi, 0.6), mi, ombre],
        <double>[0, 0.2, 0.40, 0.58, 0.76, 1]));

/// Le contre-jour (repère unité) : un seul dégradé décentré à l'opposé de la porte. Du côté de
/// la porte, une bande d'ombre propre puis un liseré de lumière ; rien de l'autre côté.
ui.Shader _contreJour(Offset dir, Color lumiere, Color ombre, double force, double epais) {
  final int ang = (math.atan2(dir.dy, dir.dx) * 60).round();
  return _memo(Object.hash(2, ang, lumiere, ombre, (force * 40).round(), (epais * 100).round()), () {
    const double d = 0.10;
    final double a = ang / 60;
    final Offset c = Offset(-math.cos(a) * d, -math.sin(a) * d);
    const int n = 22;
    final double t0 = 0.74, debut = 1 - epais;
    final List<Color> cs = <Color>[lumiere.withValues(alpha: 0), ombre.withValues(alpha: 0)];
    final List<double> ss = <double>[0, t0];
    for (int i = 1; i <= n; i++) {
      final double t = t0 + (1 - t0) * i / n;
      final double bande = math.sin(math.pi * cl((t - t0) / (debut + 0.03 - t0))) * 0.34 * math.min(1, force);
      final double lis = math.pow(lisse2(debut, 1.0, t), 1.25) * cl(force);
      final double al = bande * (1 - lis) + lis;
      final Color teinte = al < 0.001 ? ombre : Color.lerp(ombre, lumiere, cl(lis / al))!;
      cs.add(teinte.withValues(alpha: cl(al)));
      ss.add(t);
    }
    return ui.Gradient.radial(c, 1 + d, cs, ss);
  });
}

final Paint _p = Paint();
final Paint _p2 = Paint();

/// Peint Praxis, pieds en [pied], large de [largeur], éclairé par [ec].
void peindrePraxis(Canvas c, Corps s, Offset pied, double largeur, Eclairage ec) {
  final double op = s.opacite;
  if (op < 0.01 || largeur < 1.5) return;
  final double u = largeur / 200;
  final bool couche = op < 0.99;
  if (couche) {
    c.saveLayer(Rect.fromCenter(center: pied + Offset(0, -largeur * 0.55), width: largeur * 2.8, height: largeur * 2.6), Paint()..color = T.noir.withValues(alpha: op));
  }
  c.save();
  c.translate(pied.dx, pied.dy);
  c.scale(u);
  c.translate(-100, -206);

  // Les couleurs : lilas et encre, fondues vers la lumière avec la distance et dans la porte.
  final double dos = s.dos, niv = cl(ec.niveau);
  Color m(Color x) => melange(melange(x, ec.couleur, ec.brume * 0.5), ec.couleur, ec.surex);
  final double eteint = (1 - niv) * 0.16 + dos * 0.10;
  final Color lilas = melange(T.lilas, T.nuit, eteint);
  final Color cClair = m(melange(lilas, T.blanc, 0.34 * (1 - dos * 0.7) * (0.4 + 0.6 * niv)));
  final Color cBase = m(lilas);
  final Color cMi = m(melange(lilas, T.nuit, 0.10 + dos * 0.05));
  final Color cOmbre = m(melange(lilas, T.nuit, 0.24 + dos * 0.08));
  final Color nuit = m(T.nuit), blanc = m(T.blanc);
  final Color cLum = ec.couleur;
  final double force = ec.contre * (0.25 + 0.75 * niv) * (1 - ec.surex * 0.5);
  final Paint noir = Paint()..color = nuit;
  final Paint trait = Paint()
    ..color = nuit
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Une boule : volume, puis contre-jour.
  void boule(Offset o, double rx, double ry, {double f = 1, bool encre = false, double epais = 0.085}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(rx, ry);
    _p
      ..shader = encre ? _volume(m(melange(T.nuit, T.lilas, 0.22)), nuit, nuit, nuit) : _volume(cClair, cBase, cMi, cOmbre)
      ..color = T.noir;
    c.drawCircle(Offset.zero, 1, _p);
    if (force * f > 0.02) {
      _p2
        ..shader = _contreJour(ec.dir, cLum, encre ? nuit : cOmbre, force * f * (encre ? 0.8 : 1), epais)
        ..color = T.noir;
      c.drawCircle(Offset.zero, 1, _p2);
    }
    c.restore();
  }

  final double haut = s.hauteurCorps;
  final double th = s.lacet;
  final double ct = math.cos(th), st = math.sin(th);
  const Offset ctr = Corps.centre;
  const double rT = Corps.rayon;

  // ───── La toque, en trois dimensions ─────
  // Repère de la tête : x à droite, y en haut, z vers nous. La caméra regarde de haut (plongée).
  final double elev = 0.27 + s.tangageVu * 0.6;
  final double ce = math.cos(elev), se = math.sin(elev);
  (double, double, double) vue(double x, double y, double z) {
    final double x1 = x * ct + z * st, z1 = -x * st + z * ct;
    return (x1, y * ce - z1 * se, y * se + z1 * ce);
  }

  // L'axe de la toque : un peu penchée sur le côté et en arrière, avec son propre retard.
  final double inc = -0.10 + s.toqueRoulis.x;
  final double an = math.sqrt(inc * inc + 1 + 0.05 * 0.05);
  final double axx = inc / an, axy = 1 / an, axz = -0.05 / an;
  final double un_ = math.sqrt(axx * axx + axy * axy);
  final double ux = axy / un_, uy = -axx / un_; // u : perpendiculaire à l'axe, dans le plan de face
  final double wx = -axz * uy, wy = axz * ux, wz = axx * uy - axy * ux; // w = axe × u
  final double sensW = wz < 0 ? -1 : 1;
  final double leve = math.min(0, s.chapeau.x) * 0.9; // la toque ne descend jamais dans le visage
  Offset ecran(double x, double y, double z) {
    final (double a, double b, _) = vue(x, y, z);
    return Offset(ctr.dx + a, ctr.dy - b + leve);
  }

  const double h0 = rT * 0.54; // hauteur du bord de la calotte sur l'axe
  final double rc = math.sqrt(rT * rT - h0 * h0);
  const int nb = 44;
  final List<double> bx = List<double>.filled(nb, 0), by = List<double>.filled(nb, 0), bz = List<double>.filled(nb, 0);
  for (int i = 0; i < nb; i++) {
    final double t = i / nb * 2 * math.pi, cu = math.cos(t) * rc, cw = math.sin(t) * rc * sensW;
    final (double a, double b, double d) = vue(axx * h0 + ux * cu + wx * cw, axy * h0 + uy * cu + wy * cw, axz * h0 + wz * cw);
    bx[i] = a;
    by[i] = -b;
    bz[i] = d;
  }
  // Le plateau carré, posé sur la calotte.
  const double hp = rT + 1, demi = 68, psi = 0.20;
  final List<Offset> coins = <Offset>[];
  final List<double> coinsZ = <double>[];
  for (int k = 0; k < 4; k++) {
    final double t = psi + k * math.pi / 2, cu = math.cos(t) * demi, cw = math.sin(t) * demi * sensW;
    final double x = axx * hp + ux * cu + wx * cw, yy = axy * hp + uy * cu + wy * cw, z = axz * hp + wz * cw;
    coins.add(ecran(x, yy, z));
    coinsZ.add(vue(x, yy, z).$3);
  }
  final Offset sommet = ecran(axx * hp, axy * hp, axz * hp);
  final Offset epaisseur = ecran(axx * (hp - 6), axy * (hp - 6), axz * (hp - 6)) - sommet;
  // Le pompon pend du coin de droite (au repos), comme sur le dessin d'origine.
  final Offset attache = coins[0];
  final bool pomponDerriere = coinsZ[0] < -8;
  void pompon() {
    c.save();
    c.translate(attache.dx, attache.dy);
    c.rotate(s.pend);
    c.drawLine(Offset.zero, const Offset(0, 29), trait);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, 27, 12, 19), const Radius.circular(2.5)), noir);
    if (force > 0.05) {
      // Le contre-jour dessine le cordon et le haut du pompon : il se lit même devant la calotte.
      final Paint fil = Paint()
        ..color = cLum.withValues(alpha: 0.62 * cl(force))
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(-2.6, 4), const Offset(-2.6, 26), fil);
      c.drawLine(const Offset(-5, 27.6), const Offset(5, 27.6), fil);
    }
    c.restore();
  }

  // ───── Les mains : elles tournent avec le corps ; celles de derrière passent avant lui ─────
  final Offset cc = Offset(100, 108 + haut);
  (Offset, double) mainVue(double x, double y, double z) {
    final double x1 = x * ct + z * st, z1 = -x * st + z * ct;
    return (cc + Offset(x1, y), z1);
  }

  final (Offset mg, double zg) = mainVue(s.mgx.x, s.mgy.x, s.mgz.x);
  final (Offset md, double zd) = mainVue(s.mdx.x, s.mdy.x, s.mdz.x);
  void main_(Offset o, double z) {
    final double r = 19 * (1 + cl(z, -60, 100) / 520);
    // Ombre de contact de la main sur le corps.
    if (z > 0 && (o - cc).distance < rT + 8) Atelier.poser(c, o + const Offset(2, 5), r * 1.25, r * 1.2, m(T.nuit), 0.20 * (1 - ec.surex));
    boule(o, r, r, epais: 0.16);
  }

  // ───── Derrière le corps ─────
  if (pomponDerriere) pompon();
  if (zg < -4) main_(mg, zg);
  if (zd < -4) main_(md, zd);

  // ───── Les pieds ─────
  for (final Pied f in <Pied>[s.pg, s.pd]) {
    final (double x, double yy, double sc, double lev) = s.piedVu(f);
    final double as_ = cl(s.assis.x);
    c.save();
    c.translate(x, yy - lev * 14 * sc + math.min(0, s.y) * 0.85);
    c.rotate(f.cote * 0.10 * lev);
    boule(Offset.zero, (19.5 - as_ * 3) * sc, (8.8 + as_ * 7.5 + lev * 1.2) * sc, encre: true, epais: 0.2);
    c.restore();
  }

  // ───── Le corps : écrasé au contact, étiré au geste, qui roule d'un pied sur l'autre ─────
  final double e = s.ecrase.x.clamp(-0.3, 0.3) + cl(s.assis.x) * 0.075;
  final double respire = 1 + math.sin(s.temps * 2.1) * 0.012 + (s.geste == Geste.respire ? math.pow(math.sin(s.tGeste * 1.1), 2) * 0.04 : 0);
  c.save();
  c.translate(100, 194 + haut);
  c.rotate(s.penche.x + s.roulis.x);
  c.scale((1 + e) * (s.geste == Geste.souffle ? 1.03 : 1), (1 - e) * respire * (1 + s.etire.x * 0.07));
  c.translate(-100, -194);
  boule(ctr, rT, rT);

  final Path disque = Path()..addOval(Rect.fromCircle(center: ctr, radius: rT));
  c.save();
  c.clipPath(disque);
  // Les joues.
  if (s.rouge.x > 0.02) {
    for (final double x0 in <double>[-40, 46]) {
      final (double x, double yy, double z, double fx) = s.surTete(x0, 46);
      if (z > 6) Atelier.poser(c, ctr + Offset(x, yy), 17 * fx, 10, m(T.corail), 0.34 * cl(s.rouge.x));
    }
  }
  // Les yeux : le dessin d'origine, trait pour trait (ovale d'encre 26 × 36, pupille blanche de
  // rayon 6, mêmes centres). Ils clignent en se fermant le long de leur propre forme.
  final double clin = s.clin > 0 ? math.sin(cl(s.clin) * math.pi) : 0;
  // Directeur, 20/11/2026 : les yeux sont la signature de Praxis. Jamais plus
  // grands que le dessin d'origine ; ils ne font que cligner.
  final double ouv = math.max(0.085, cl(s.ouvert.x, 0, 1.0) * (1 - clin * 0.93));
  for (int i = 0; i < 2; i++) {
    final (double x, double yy, double z, double fx) = s.surTete(i == 0 ? -16 : 22, 20);
    if (z < 3) continue;
    // Sourcils : discrets, seulement quand l'expression les appelle.
    // Directeur, 20/11/2026 : seuls les membres et la bouche s'ajoutent ;
    // aucun sourcil autour des yeux.
    final double sv = cl(s.sourcilVu.x) * 0.0;
    if (sv > 0.03) {
      c.save();
      c.translate(ctr.dx + x, ctr.dy + yy - 30 - s.sourcil.x * 6);
      c.scale(fx, 1);
      c.rotate((i == 0 ? -1 : 1) * s.sourcilPente.x * 0.30);
      c.drawLine(const Offset(-8, 0), const Offset(8, 0), Paint()
        ..color = nuit.withValues(alpha: sv)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round);
      c.restore();
    }
    c.save();
    c.translate(ctr.dx + x, ctr.dy + yy);
    c.scale(fx * s.taille.x, s.taille.x);
    c.save();
    c.scale(1, ouv);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 26, height: 36), noir);
    c.restore();
    final double vuP = lisse2(0.42, 0.62, ouv);
    if (vuP > 0.01) {
      c.drawCircle(Offset(s.gx.x * 5.5, (s.gy.x * 5.5 - s.pupille.x * 4.5) * ouv), 6 * math.min(1, 0.55 + 0.45 * vuP), Paint()..color = blanc.withValues(alpha: vuP));
    }
    c.restore();
  }
  // La bouche : fermée en trait, ouverte en forme pleine, ronde quand il s'étonne.
  final (double bxm, double bym, double bzm, double bfx) = s.surTete(3, 58);
  if (bzm > 3) {
    c.save();
    c.translate(ctr.dx + bxm, ctr.dy + bym);
    c.scale(bfx, 1);
    final double ro = cl(s.rond.x), ou = cl(s.ouvre.x, 0, 1.2);
    final double w = (28 * s.large.x) * (1 - ro) + (12 + 10 * ou) * ro;
    final double sm = s.sourire.x * 7 * (1 - ro);
    if (ou < 0.06) {
      c.drawPath(Path()..moveTo(-w / 2, -sm * 0.6)..quadraticBezierTo(0, sm * 1.5, w / 2, -sm * 0.6), trait);
    } else {
      final double h = 20 * ou;
      final double coin = -sm * 0.6;
      final Path bouche = Path()
        ..moveTo(-w / 2, coin)
        ..cubicTo(-w / 2 * (0.6 + 0.4 * ro), coin - h * (0.15 + 0.45 * ro), w / 2 * (0.6 + 0.4 * ro), coin - h * (0.15 + 0.45 * ro), w / 2, coin)
        ..cubicTo(w / 2 * (0.9 + 0.1 * ro), coin + sm + h * (0.9 + 0.1 * ro), -w / 2 * (0.9 + 0.1 * ro), coin + sm + h * (0.9 + 0.1 * ro), -w / 2, coin)
        ..close();
      c.drawPath(bouche, noir);
      c.save();
      c.clipPath(bouche);
      c.drawOval(Rect.fromCenter(center: Offset(0, coin + sm * 0.7 + h * 0.85), width: w * 0.62, height: h * 0.7), Paint()..color = m(T.corail));
      c.restore();
    }
    c.restore();
  }

  // La calotte : elle épouse le haut du crâne. Son bord avant est le demi-cercle visible du
  // bord ; le reste suit la silhouette de la tête. Elle s'arrête au-dessus des yeux.
  final Path calotte = Path();
  int entree = -1, sortie = -1;
  for (int i = 0; i < nb; i++) {
    final int j = (i + 1) % nb;
    if (bz[i] < 0 && bz[j] >= 0) entree = i;
    if (bz[i] >= 0 && bz[j] < 0) sortie = i;
  }
  final Offset axeVu = ecran(axx * 100, axy * 100, axz * 100) - ctr - Offset(0, leve);
  if (entree < 0 || sortie < 0) {
    calotte.addPolygon(<Offset>[for (int i = 0; i < nb; i++) ctr + Offset(bx[i], by[i] + leve)], true);
  } else {
    Offset croise(int i) {
      final int j = (i + 1) % nb;
      final double t = bz[i] / (bz[i] - bz[j]);
      return Offset(bx[i] + (bx[j] - bx[i]) * t, by[i] + (by[j] - by[i]) * t);
    }

    final Offset pa = croise(entree), pb = croise(sortie);
    calotte.moveTo(ctr.dx + pa.dx, ctr.dy + pa.dy + leve);
    for (int i = (entree + 1) % nb;; i = (i + 1) % nb) {
      calotte.lineTo(ctr.dx + bx[i], ctr.dy + by[i] + leve);
      if (i == sortie) break;
    }
    calotte.lineTo(ctr.dx + pb.dx, ctr.dy + pb.dy + leve);
    // Retour par la silhouette, du côté où pointe l'axe de la toque.
    final double angB = math.atan2(pb.dy, pb.dx), angA = math.atan2(pa.dy, pa.dx), angT = math.atan2(axeVu.dy, axeVu.dx);
    double mod(double v) => (v % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final double d1 = mod(angA - angB), dT = mod(angT - angB);
    calotte.arcTo(Rect.fromCircle(center: ctr + Offset(0, leve), radius: rT + 1.5), angB, dT < d1 ? d1 : d1 - 2 * math.pi, false);
    calotte.close();
  }
  // L'ombre propre sous la toque, sur le front : un seul dégradé, calé sur l'ellipse du bord.
  if (ec.surex < 0.9) {
    final Offset cb = ecran(axx * h0, axy * h0, axz * h0);
    final double petit = rc * math.max(0.12, vue(axx, axy, axz).$3.abs());
    c.save();
    c.translate(cb.dx, cb.dy);
    c.rotate(math.atan2(axeVu.dx, -axeVu.dy));
    c.clipRect(Rect.fromLTRB(-rc * 1.3, 0, rc * 1.3, petit * 1.8));
    c.scale(rc * 1.36, petit * 1.36);
    _p
      ..shader = _memo(Object.hash(3, nuit), () {
        const int n = 24;
        return ui.Gradient.radial(Offset.zero, 1, <Color>[for (int i = 0; i <= n; i++) nuit.withValues(alpha: 0.42 * math.exp(-math.pow((i / n - 0.735) / 0.085, 2)))],
            <double>[for (int i = 0; i <= n; i++) i / n]);
      })
      ..color = T.noir.withValues(alpha: 1 - ec.surex);
    c.drawCircle(Offset.zero, 1, _p);
    c.restore();
  }
  c.drawPath(calotte, noir);
  // Le contre-jour passe aussi sur la calotte : son bord prend la lumière de la porte.
  if (force > 0.02) {
    c.save();
    c.clipPath(calotte);
    c.translate(ctr.dx, ctr.dy);
    c.scale(rT + 1.5);
    _p2
      ..shader = _contreJour(ec.dir, cLum, nuit, force * 1.25, 0.10)
      ..color = T.noir;
    c.drawCircle(Offset.zero, 1, _p2);
    c.restore();
  }
  c.restore(); // fin du masque du disque

  // Le plateau : la tranche d'abord (encre), puis le dessus (lilas), plus clair vers la porte.
  final Path dessous = Path()..addPolygon(<Offset>[for (final Offset o in coins) o + epaisseur], true);
  final Path dessus = Path()..addPolygon(coins, true);
  c.drawPath(dessous, noir);
  c.drawPath(dessous, trait);
  int loin = 0, pres = 0;
  for (int k = 1; k < 4; k++) {
    if (coinsZ[k] < coinsZ[loin]) loin = k;
    if (coinsZ[k] > coinsZ[pres]) pres = k;
  }
  c.drawPath(
      dessus,
      Paint()
        ..shader = ui.Gradient.linear(coins[loin], coins[pres], <Color>[melange(cBase, cLum, 0.55 * cl(force) * (1 - dos * 0.5)), cBase, melange(cBase, cMi, 0.7)], <double>[0, 0.55, 1]));
  c.drawPath(dessus, trait);
  // Les deux arêtes du fond, tournées vers la porte, prennent la lumière.
  if (force > 0.05) {
    final Paint arete = Paint()
      ..color = cLum.withValues(alpha: 0.9 * cl(force))
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset.lerp(coins[loin], coins[(loin + 1) % 4], 0.06)! + const Offset(0, -2.6), Offset.lerp(coins[loin], coins[(loin + 1) % 4], 0.94)! + const Offset(0, -2.6), arete);
    c.drawLine(Offset.lerp(coins[loin], coins[(loin + 3) % 4], 0.06)! + const Offset(0, -2.6), Offset.lerp(coins[loin], coins[(loin + 3) % 4], 0.94)! + const Offset(0, -2.6), arete);
  }
  c.drawLine(sommet, Offset.lerp(sommet, attache, 0.94)!, trait);
  c.drawCircle(sommet, 4.2, noir);
  if (!pomponDerriere) pompon();
  c.restore(); // fin du corps

  // ───── Accessoires, tenus par les mains ─────
  final double ob = cl(s.objet.x);
  if (ob > 0.02) {
    switch (s.geste) {
      case Geste.balaie:
        final Offset bas = Offset(md.dx - 30, 204);
        c.drawLine(mg + const Offset(-10, -44), bas, trait..strokeWidth = 5);
        trait.strokeWidth = 4;
        final Path brosse = Path()
          ..moveTo(bas.dx - 8, bas.dy - 16)
          ..lineTo(bas.dx + 10, bas.dy - 12)
          ..lineTo(bas.dx + 16, bas.dy + 2)
          ..lineTo(bas.dx - 26, bas.dy + 2)
          ..close();
        c.drawPath(brosse, Paint()..color = m(Teinte.violet).withValues(alpha: ob));
        c.drawPath(brosse, trait);
      case Geste.range:
        final Rect dalle = Rect.fromCenter(center: (mg + md) / 2 + const Offset(0, -6), width: 70 * ob, height: 22 * ob);
        c.drawRSuperellipse(RSuperellipse.fromRectAndRadius(dalle, const Radius.circular(7)), Paint()..color = m(melange(T.lilas, T.blanc, 0.75)));
        c.drawRSuperellipse(RSuperellipse.fromRectAndRadius(dalle, const Radius.circular(7)), trait);
      case Geste.cle:
        c.save();
        c.translate(md.dx, md.dy - 6);
        c.rotate(s.reduit ? 0 : math.sin(math.max(0, s.tGeste - 0.5) * 3.2) * 0.9);
        c.scale(ob);
        c.drawCircle(const Offset(0, -22), 9, trait);
        c.drawLine(const Offset(0, -13), const Offset(0, 12), trait);
        c.drawLine(const Offset(0, 6), const Offset(7, 6), trait);
        c.restore();
      default:
        break;
    }
  }
  if (zg >= -4) main_(mg, zg);
  if (zd >= -4) main_(md, zd);
  // Détails de geste.
  void doigt(Offset o, Offset vers) {
    final Offset b = o + vers;
    c.drawLine(o + vers * 0.3, b, Paint()
      ..color = cBase
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round);
    Atelier.poser(c, b, 5, 5, cLum, 0.5 * cl(force));
  }

  switch (s.geste) {
    case Geste.presque:
      doigt(md + const Offset(-7, -4), const Offset(-3, -20));
      doigt(md + const Offset(7, -4), const Offset(3, -20));
    case Geste.un:
      doigt(md, const Offset(0, -28));
    case Geste.pointe:
      if (s.vise.dx == 0) {
        doigt(md, const Offset(-4, 26));
      } else {
        doigt(s.vise.dx > 0 ? md : mg, s.vise * 27);
      }
    case Geste.compte:
      doigt(md, const Offset(2, 24));
    case Geste.porte:
      doigt(md, const Offset(-6, -26));
    case Geste.montre:
      // La montre, au poignet gauche : un cadran lavande, deux aiguilles.
      final Offset o = mg + const Offset(2, 3);
      c.drawCircle(o, 10.5 * ob, Paint()..color = m(melange(T.lilas, T.blanc, 0.7)));
      c.drawCircle(o, 10.5 * ob, trait..strokeWidth = 3);
      c.drawLine(o, o + Offset(0, -6 * ob), trait..strokeWidth = 2.4);
      c.drawLine(o, o + Offset(4.5 * ob, 2 * ob), trait);
      trait.strokeWidth = 4;
    case Geste.allume:
      if (s.tGeste > 0.45 && s.tGeste < 1.5 && !s.reduit) {
        final double k = (s.tGeste - 0.45) / 1.05;
        Atelier.poser(c, md + const Offset(0, -10), 20 + 60 * k, 20 + 60 * k, cLum, 0.9 * (1 - k));
      }
    case Geste.souffle:
      if (!s.reduit) {
        for (int i = 0; i < 3; i++) {
          final double k = (s.tGeste * 0.7 + i / 3) % 1;
          Atelier.poser(c, Offset(103 + k * 34 * (i - 1), 160 + haut - k * 170), 9 * (1 - k) + 3, 9 * (1 - k) + 3, cLum, 0.8 * math.sin(k * math.pi));
        }
      }
    default:
      break;
  }
  // Dans la porte : la surexposition déborde sa silhouette.
  if (ec.surex > 0.03) {
    Atelier.poser(c, Offset(100, 108 + haut), 190, 190, cLum, 0.75 * ec.surex);
  }
  c.restore();
  if (couche) c.restore();
}
