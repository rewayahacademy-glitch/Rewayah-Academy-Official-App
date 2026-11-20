// L'atelier de lumière : une seule source (la porte), des dégradés à profil gaussien préparés
// une fois dans un repère unité, et quatre petites textures calculées au démarrage (grain,
// rais, grain de poussière, ombre portée). Aucune teinte hors de la palette : blanc, lilas,
// lavande, violet, encre.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'outils_entree.dart';

double cl(double v, [double a = 0, double b = 1]) => v < a ? a : (v > b ? b : v);
double lisse(double v) {
  final double x = cl(v);
  return x * x * (3 - 2 * x);
}

double lisse2(double a, double b, double v) => lisse((v - a) / (b - a));
Color melange(Color a, Color b, double t) => Color.lerp(a, b, cl(t))!;

/// Les teintes de la scène, toutes dérivées de la palette `T`.
abstract final class Teinte {
  static Color get violet => T.violet; // le violet du logo
  static Color get lavande => T.lavande; // l'accent sur fond sombre

  /// Le cœur de la lumière : blanc en clair, blanc lavande en sombre.
  static Color get coeur => T.s ? melange(T.lilas, T.blanc, 0.62) : T.blanc;
  static Color get douce => T.s ? T.lilas : melange(T.blanc, T.lilas, 0.30);
  static Color get loin => T.s ? lavande : T.lilas;
  static Color get cielHaut => T.s ? T.fond : melange(melange(T.fond, T.pale, 0.8), T.lilas, 0.16);
  static Color get cielHorizon => T.s ? melange(T.fond, T.pale, 0.72) : melange(T.pale, T.lilas, 0.55);
  static Color get solProche => T.s ? melange(T.fond, T.surface2, 0.7) : melange(T.pale, T.lilas, 0.36);
  static Color get route => T.s ? melange(T.fond, T.surface2, 0.35) : melange(T.filet, T.lilas, 0.62);
  static Color get dalle => T.s ? T.surface : melange(T.pale, T.lilas, 0.16);
  static Color get dalleAllumee => T.s ? melange(T.lilas, T.blanc, 0.55) : T.blanc;
  static Color get lueurDalle => T.s ? lavande : T.lilas;
  static Color get ombre => T.s ? T.noir : melange(T.nuit, violet, 0.30);
  static double get ombreForce => T.s ? 0.55 : 0.30;
  static Color get logo => T.s ? lavande : violet;

  /// Ce que devient l'écran quand l'iris a tout rempli : le fond de l'application en clair ;
  /// en sombre, une lavande retenue, jamais un éclat blanc.
  static Color get irisFin => T.s ? melange(T.pale, lavande, 0.42) : T.fond;
}

/// Les dégradés et les textures, préparés une fois.
abstract final class Atelier {
  static ui.Image? grain, rais, poussiere, ombre;
  static final ValueNotifier<int> pret = ValueNotifier<int>(0);
  static final Map<String, ui.Shader> _memo = <String, ui.Shader>{};

  static ui.Shader memo(String nom, ui.Shader Function() f) => _memo['$nom|${T.s}'] ??= f();

  /// Un halo sans anneaux : un seul dégradé radial, trente paliers posés sur une gaussienne
  /// ramenée à zéro au bord. [rampe] donne la teinte du cœur au bord, [a0] l'opacité au cœur,
  /// [plateau] la part du rayon qui reste pleine avant la décroissance.
  static ui.Gradient halo(List<Color> rampe, {double a0 = 1, double sigma = 0.45, double plateau = 0, int n = 30, Offset? foyer}) {
    final double g1 = math.exp(-1 / (sigma * sigma));
    final List<Color> c = <Color>[];
    final List<double> s = <double>[];
    for (int i = 0; i <= n; i++) {
      final double t = i / n;
      final double r = plateau >= 1 ? 0 : cl((t - plateau) / (1 - plateau));
      final double g = (math.exp(-(r * r) / (sigma * sigma)) - g1) / (1 - g1);
      final double p = t * (rampe.length - 1);
      final int k = math.min(rampe.length - 2, p.floor());
      final Color teinte = rampe.length == 1 ? rampe[0] : Color.lerp(rampe[k], rampe[k + 1], p - k)!;
      c.add(teinte.withValues(alpha: cl(a0 * g) * teinte.a));
      s.add(t);
    }
    return ui.Gradient.radial(Offset.zero, 1, c, s, TileMode.clamp, null, foyer, 0);
  }

  // ───── Les dégradés de la porte (repère unité : rayon 1) ─────
  /// L'aura derrière le logo.
  static ui.Shader get aura => memo('aura', () => halo(<Color>[Teinte.coeur, Teinte.douce, Teinte.loin], a0: T.s ? 0.92 : 0.98, sigma: 0.46));

  /// La surexposition devant l'ouverture.
  static ui.Shader get bloom => memo('bloom', () => halo(<Color>[Teinte.coeur, Teinte.coeur, Teinte.douce], a0: 1, sigma: 0.40));

  /// La nappe de lumière au sol : cercles issus d'un foyer posé au pied de la porte, serrés
  /// près d'elle, de plus en plus larges vers nous.
  static ui.Shader get nappe =>
      memo('nappe', () => halo(<Color>[Teinte.coeur, Teinte.douce, Teinte.loin], a0: T.s ? 0.62 : 0.95, sigma: 0.40, foyer: const Offset(0, -0.9)));

  /// Une goutte blanche à bord gaussien : teintée et étirée à l'emploi (ombres de contact, lueurs).
  static ui.Shader get goutte => memo('goutte', () => halo(<Color>[T.blanc], sigma: 0.5));

  /// Le vignettage : rien au centre, un voile aux bords.
  static ui.Shader get vignette => memo('vignette', () {
        final Color v = T.s ? T.noir : melange(Teinte.violet, T.nuit, 0.35);
        const int n = 24;
        return ui.Gradient.radial(Offset.zero, 1, <Color>[for (int i = 0; i <= n; i++) v.withValues(alpha: (T.s ? 0.46 : 0.15) * math.pow(lisse2(0.42, 1.0, i / n), 1.6))],
            <double>[for (int i = 0; i <= n; i++) i / n]);
      });

  /// L'iris final : plein au centre, bord gaussien large.
  static ui.Shader get iris => memo('iris', () => halo(T.s ? <Color>[Teinte.douce, melange(Teinte.lavande, T.lilas, 0.4), Teinte.irisFin, Teinte.irisFin, Teinte.lavande] : <Color>[Teinte.coeur, Teinte.coeur, T.fond, T.fond, Teinte.loin], sigma: 0.55, plateau: 0.52));

  /// Le grain, carrelé sur toute la scène.
  static ui.Shader? get grainTuile {
    final ui.Image? g = grain;
    if (g == null) return null;
    return _memo['grain'] ??= ui.ImageShader(g, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);
  }

  static ui.Shader? get ombreTexture {
    final ui.Image? o = ombre;
    if (o == null) return null;
    return _memo['ombre'] ??= ui.ImageShader(o, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage, filterQuality: FilterQuality.medium);
  }

  // ───── Les textures, calculées une fois ─────
  static Future<ui.Image> _image(int w, int h, Uint8List rgba) {
    final Completer<ui.Image> c = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  static const int raisCote = 256, ombreL = 64, ombreH = 128;

  static Future<void> preparer() async {
    final math.Random h = math.Random(3);
    // Grain : blanc ou noir, opacité aléatoire à loi triangulaire. Posé à 3 % environ.
    const int g = 128;
    final Uint8List pg = Uint8List(g * g * 4);
    for (int i = 0; i < g * g; i++) {
      final double n = h.nextDouble() - h.nextDouble();
      final int a = (n.abs() * 255).round();
      final int v = n > 0 ? a : 0;
      pg[i * 4] = v;
      pg[i * 4 + 1] = v;
      pg[i * 4 + 2] = v;
      pg[i * 4 + 3] = a;
    }
    // Rais : un éventail doux sous la porte (placée en haut, au milieu), lobes gaussiens.
    const int r = raisCote;
    final Uint8List pr = Uint8List(r * r * 4);
    const List<double> angles = <double>[-0.98, -0.63, -0.37, -0.13, 0.11, 0.34, 0.6, 0.9];
    const List<double> ouv = <double>[0.10, 0.075, 0.12, 0.065, 0.085, 0.11, 0.075, 0.10];
    const List<double> poids = <double>[0.45, 0.8, 0.6, 1, 0.9, 0.7, 0.85, 0.4];
    for (int y = 0; y < r; y++) {
      for (int x = 0; x < r; x++) {
        final double dx = x + 0.5 - r / 2, dy = y + 0.5;
        final double ang = math.atan2(dx, dy), ray = math.sqrt(dx * dx + dy * dy) / r;
        double l = 0.30 * math.exp(-(ang * ang) / 0.75);
        for (int i = 0; i < angles.length; i++) {
          final double d = (ang - angles[i]) / ouv[i];
          l += poids[i] * math.exp(-d * d);
        }
        final double rad = lisse2(0.0, 0.10, ray) * math.exp(-(ray * ray) / 0.30) * lisse2(1.0, 0.72, ray);
        final int a = (cl(l * rad / 1.3) * 255).round();
        final int i4 = (y * r + x) * 4;
        pr[i4] = a;
        pr[i4 + 1] = a;
        pr[i4 + 2] = a;
        pr[i4 + 3] = a;
      }
    }
    // Grain de poussière : un point flou.
    const int p = 32;
    final Uint8List pp = Uint8List(p * p * 4);
    for (int y = 0; y < p; y++) {
      for (int x = 0; x < p; x++) {
        final double dx = (x + 0.5) / p * 2 - 1, dy = (y + 0.5) / p * 2 - 1;
        final double d2 = dx * dx + dy * dy;
        final int a = (cl((math.exp(-d2 / 0.16) - math.exp(-1 / 0.16)) * lisse2(1.0, 0.8, math.sqrt(d2))) * 255).round();
        final int i4 = (y * p + x) * 4;
        pp[i4] = a;
        pp[i4 + 1] = a;
        pp[i4 + 2] = a;
        pp[i4 + 3] = a;
      }
    }
    // Ombre portée : nette et pleine au contact (haut), de plus en plus floue et pâle au loin (bas).
    final Uint8List po = Uint8List(ombreL * ombreH * 4);
    for (int y = 0; y < ombreH; y++) {
      for (int x = 0; x < ombreL; x++) {
        final double uu = ((x + 0.5) / ombreL * 2 - 1).abs(), v = (y + 0.5) / ombreH;
        final double flou = 0.16 + 0.84 * math.pow(v, 0.8);
        final double bord = 1 - lisse2(math.max(0, 0.92 - flou), 0.98, uu);
        final double long = math.pow(1 - v, 1.25) * lisse2(0, 0.045, v);
        final int a = (cl(bord * long) * 255).round();
        final int i4 = (y * ombreL + x) * 4;
        po[i4] = a;
        po[i4 + 1] = a;
        po[i4 + 2] = a;
        po[i4 + 3] = a;
      }
    }
    grain = await _image(g, g, pg);
    rais = await _image(r, r, pr);
    poussiere = await _image(p, p, pp);
    ombre = await _image(ombreL, ombreH, po);
    pret.value++;
  }

  /// Pose une goutte gaussienne teintée : centre, demi-axes, couleur, opacité.
  static final Paint _pg = Paint();
  static void poser(Canvas c, Offset o, double rx, double ry, Color couleur, double alpha, {double angle = 0}) {
    if (alpha < 0.004 || rx < 0.3 || ry < 0.3) return;
    c.save();
    c.translate(o.dx, o.dy);
    if (angle != 0) c.rotate(angle);
    c.scale(rx, ry);
    _pg
      ..shader = goutte
      ..colorFilter = ColorFilter.mode(couleur.withValues(alpha: 1), BlendMode.srcIn)
      ..color = T.noir.withValues(alpha: cl(alpha));
    c.drawRect(const Rect.fromLTRB(-1, -1, 1, 1), _pg);
    c.restore();
  }

  /// Pose un dégradé unité préparé, étiré aux demi-axes donnés.
  static final Paint _pu = Paint();
  static void etaler(Canvas c, ui.Shader s, Offset o, double rx, double ry, double alpha, {Rect cadre = const Rect.fromLTRB(-1, -1, 1, 1)}) {
    if (alpha < 0.004) return;
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(rx, ry);
    _pu
      ..shader = s
      ..color = T.noir.withValues(alpha: cl(alpha));
    c.drawRect(cadre, _pu);
    c.restore();
  }
}
