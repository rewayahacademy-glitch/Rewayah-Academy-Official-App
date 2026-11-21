// ENTREE-PRAXIS, corrections du 20/11/2026 a l'ordinateur (directeur) : le
// logo n'est plus deforme par un angle ; Praxis montre le formulaire la ou il
// est vraiment (dessous au telephone, a cote a l'ordinateur, a gauche en
// arabe) ; sa main s'arrete avant la carte.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/vivant/entree/gestes_praxis.dart';
import 'package:rewayah_academy/core/vivant/entree/scene_entree.dart';

const Size _ecran = Size(1440, 900);

Rect _carte({required bool rtl}) =>
    Rect.fromLTWH(rtl ? 48 : _ecran.width - 448 - 48, 0, 448, _ecran.height);

Theatre _theatre({required bool rtl}) {
  final Rect carte = _carte(rtl: rtl);
  final Theatre th = Theatre()
    ..geo = Geo(_ecran, CadreScene.large, rtl, _ecran.height, carte, cam: 1)
    // Le champ de l'adresse, dans la carte.
    ..cible = Offset(carte.center.dx, 354);
  th.px
    ..lnZ = th.geo.lnZ
    ..hc = th.geo.hc
    ..placer(1)
    ..faire(Geste.pointe);
  for (int i = 0; i < 120; i++) {
    th.avancer(1 / 60);
  }
  return th;
}

void main() {
  test('a l ordinateur, la porte du logo est de face : aucun angle', () {
    for (final bool rtl in <bool>[false, true]) {
      final Geo g = Geo(
        _ecran,
        CadreScene.large,
        rtl,
        _ecran.height,
        _carte(rtl: rtl),
      );
      expect(Geo.troisQuarts, isFalse);
      expect(g.deBiais, isFalse);
      expect(g.rotationPorte, isNull);
      // Le disque reste rond : un point du symbole garde sa place.
      const Offset p = Offset(100, 300);
      expect(g.ecran(p), g.logo.topLeft + p * g.k);
    }
  });

  test('au telephone, le formulaire est dessous : il pointe vers le bas', () {
    final Theatre th = Theatre()
      ..geo = Geo(const Size(390, 844), CadreScene.tel, false, 440, Rect.zero)
      ..cible = const Offset(195, 620);
    th.px
      ..placer(1)
      ..faire(Geste.pointe);
    th.avancer(1 / 60);
    expect(th.px.vise, const Offset(0, 1));
  });

  test('a l ordinateur, il pointe vers le champ, du cote de la carte', () {
    final Theatre fr = _theatre(rtl: false);
    final Theatre ar = _theatre(rtl: true);
    expect(fr.px.vise.dx, greaterThan(0.7));
    expect(ar.px.vise.dx, lessThan(-0.7));
    // Le champ est plus haut que lui : la main monte, sans depasser 0,72 rad.
    for (final Theatre th in <Theatre>[fr, ar]) {
      expect(th.px.vise.dy, lessThan(0));
      expect(th.px.vise.dy, greaterThan(-0.67));
      expect(th.px.vise.distance, moreOrLessEquals(1, epsilon: 1e-9));
    }
    // En francais la main droite se tend ; en arabe, la gauche (miroir).
    expect(fr.px.mdx.x, greaterThan(92));
    expect(ar.px.mgx.x, lessThan(-92));
  });

  test('la main et son doigt s arretent avant la carte', () {
    for (final bool rtl in <bool>[false, true]) {
      final Theatre th = _theatre(rtl: rtl);
      final Rect carte = _carte(rtl: rtl);
      final double u = th.largeurPraxis / 200;
      // Le bout du doigt : la main, son rebond (5), le doigt (27) et sa
      // demi-epaisseur (5,5).
      final double bout = (th.px.allonge + 5 + 27) * th.px.vise.dx.abs() + 5.5;
      final double x = th.centrePraxis.dx + th.px.vise.dx.sign * bout * u;
      if (rtl) {
        expect(x, greaterThan(carte.right));
      } else {
        expect(x, lessThan(carte.left));
      }
    }
  });
}
