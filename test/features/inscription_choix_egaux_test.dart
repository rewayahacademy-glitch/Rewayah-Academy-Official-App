// Admission, lot B (directeur, 29/10/2026, apres une eleve adulte perdue a
// l'onboarding le 28/10) : le premier ecran pose deux grands choix egaux,
// cote a cote, « Je m'inscris pour moi » et « J'inscris mon enfant ». Mesure
// avec les polices du depot, a 390 et 1440 points ; a 320 en texte x2, les
// cartes s'empilent plutot que de couper un mot.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/harnais.dart';

Future<(Rect, Rect)> _titres(
  WidgetTester tester,
  Size taille, {
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: taille,
        textScaler: TextScaler.linear(echelle),
      ),
      child: hote(const UsageEtape()),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return (
    tester.getRect(find.text(t.inscription.usage.moiTitre)),
    tester.getRect(find.text(t.inscription.usage.familleTitre)),
  );
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
    testWidgets('${taille.width.toInt()} : deux choix cote a cote, en haut', (
      WidgetTester tester,
    ) async {
      final (Rect moi, Rect enfant) = await _titres(tester, taille);
      // Meme rangee : les deux titres se chevauchent en hauteur (le contenu
      // de chaque carte, de meme hauteur, est centre).
      expect(moi.top, lessThan(enfant.bottom), reason: 'meme rangee');
      expect(enfant.top, lessThan(moi.bottom), reason: 'meme rangee');
      expect(moi.right, lessThan(enfant.left), reason: '« pour moi » d abord');
      expect(moi.top, lessThan(taille.height / 2), reason: 'en haut');
    });
  }

  testWidgets('320, texte x2 : empilees, sans mot coupe', (
    WidgetTester tester,
  ) async {
    final (Rect moi, Rect enfant) = await _titres(
      tester,
      const Size(320, 640),
      echelle: 2,
    );
    expect(enfant.top, greaterThan(moi.bottom));
  });
}
