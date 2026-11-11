// GOUTTE D'HUILE : relier deux silhouettes quelconques par un cou. Le calcul
// est celui de la barre (`pontMetaballe`) ; ici, la geometrie des silhouettes.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/liaison_liquide.dart';

void main() {
  group('deux disques', () {
    test('proches : un cou, entre les deux', () {
      final Path cou = pontEntreSilhouettes(
        SilhouetteLiquide.disque(const Offset(0, 0), 20),
        SilhouetteLiquide.disque(const Offset(60, 0), 20),
      );
      final Rect b = cou.getBounds();
      expect(b.isEmpty, isFalse);
      expect(b.left, greaterThanOrEqualTo(-20));
      expect(b.right, lessThanOrEqualTo(80));
    });

    test('loin : aucun cou', () {
      final Path cou = pontEntreSilhouettes(
        SilhouetteLiquide.disque(const Offset(0, 0), 20),
        SilhouetteLiquide.disque(const Offset(400, 0), 20),
      );
      expect(cou.getBounds().isEmpty, isTrue);
    });

    test('plus le cou est fin, moins il est haut', () {
      double hauteur(double v) => pontEntreSilhouettes(
        SilhouetteLiquide.disque(const Offset(0, 0), 20),
        SilhouetteLiquide.disque(const Offset(50, 0), 20),
        v: v,
      ).getBounds().height;
      expect(hauteur(0.05), lessThan(hauteur(0.5)));
    });

    test('ecart : negatif quand ils se chevauchent, positif sinon', () {
      expect(
        ecartEntreSilhouettes(
          SilhouetteLiquide.disque(const Offset(0, 0), 20),
          SilhouetteLiquide.disque(const Offset(30, 0), 20),
        ),
        lessThan(0),
      );
      expect(
        ecartEntreSilhouettes(
          SilhouetteLiquide.disque(const Offset(0, 0), 20),
          SilhouetteLiquide.disque(const Offset(70, 0), 20),
        ),
        30,
      );
    });
  });

  group('un cercle et un rectangle arrondi', () {
    const Rect carte = Rect.fromLTWH(0, 100, 300, 120);

    test('le cou s accroche au bord haut, a l aplomb du cercle', () {
      final Path cou = pontEntreSilhouettes(
        SilhouetteLiquide.disque(const Offset(60, 30), 28),
        SilhouetteLiquide.rectangle(carte, 16),
        portee: 6,
      );
      final Rect b = cou.getBounds();
      expect(b.isEmpty, isFalse);
      // Entre le cercle (bas a 58) et le bord haut de la carte (100).
      expect(b.top, greaterThanOrEqualTo(30 - 28));
      expect(b.bottom, lessThanOrEqualTo(100 + 16 * 2));
      // A l'aplomb du cercle, pas au bout de la carte.
      expect(b.center.dx, closeTo(60, 40));
    });

    test('l accroche d un rectangle reste dans son rectangle', () {
      final ({Offset centre, double rayon}) a = SilhouetteLiquide.rectangle(
        carte,
        16,
      ).ancre(const Offset(-500, -500));
      expect(a.centre, const Offset(16, 116));
      final ({Offset centre, double rayon}) b = SilhouetteLiquide.rectangle(
        carte,
        16,
      ).ancre(const Offset(150, 0));
      expect(b.centre, const Offset(150, 116));
    });

    test('un rayon trop grand est borne a la moitie du petit cote', () {
      expect(SilhouetteLiquide.rectangle(carte, 500).rayon, 60);
    });

    test('le rectangle contenant le cercle : aucun cou', () {
      final Path cou = pontEntreSilhouettes(
        SilhouetteLiquide.disque(const Offset(150, 160), 10),
        SilhouetteLiquide.rectangle(carte, 16),
      );
      expect(cou.getBounds().isEmpty, isTrue);
    });
  });
}
