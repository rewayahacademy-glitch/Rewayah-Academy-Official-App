// ACCUEIL-CANDIDAT (directeur, 20/11/2026) : Praxis, sur l'accueil du
// candidat, est eveille quand il a quelque chose a dire, ne s'endort jamais
// devant le candidat, et reste immobile, yeux ouverts, sous « Reduire les
// effets ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/vivant/praxis_vivant.dart';
import 'package:rewayah_academy/features/candidature/praxis_candidat.dart';

import '../../support/harnais.dart';

Widget _hote({required String sujet, bool reduits = false}) => hote(
  EffetsReduits(
    actifs: reduits,
    child: Center(child: AvatarPraxisCandidat(sujet: sujet)),
  ),
);

EtatPraxisVivant _etat(WidgetTester tester) =>
    tester.state<EtatPraxisVivant>(find.byType(PraxisVivant));

void main() {
  testWidgets('eveille a l arrivee, puis pose yeux ouverts ; jamais endormi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(sujet: 'Il reste 2 elements.'));
    await tester.pump();
    expect(find.byKey(AvatarPraxisCandidat.cleVivant), findsOneWidget);
    expect(_etat(tester).enMouvement, isTrue);
    // Au-dela du moment eveille : pose, immobile, pas endormi.
    for (int i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(AvatarPraxisCandidat.clePose), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_etat(tester).endormi, isFalse);
    expect(_etat(tester).enMouvement, isFalse);
    // Bien apres le delai du sommeil du dessin : toujours pas endormi.
    await tester.pump(const Duration(seconds: 40));
    expect(_etat(tester).endormi, isFalse);
  });

  testWidgets('une information nouvelle le reveille', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(sujet: 'Il reste 2 elements.'));
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
    expect(find.byKey(AvatarPraxisCandidat.clePose), findsOneWidget);
    await tester.pumpWidget(_hote(sujet: 'Votre piece n a pas ete acceptee.'));
    await tester.pump();
    expect(find.byKey(AvatarPraxisCandidat.cleVivant), findsOneWidget);
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();
  });

  testWidgets('effets reduits : immobile d emblee, yeux ouverts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _hote(sujet: 'Il reste 2 elements.', reduits: true),
    );
    await tester.pump();
    expect(find.byKey(AvatarPraxisCandidat.clePose), findsOneWidget);
    expect(_etat(tester).enMouvement, isFalse);
    expect(_etat(tester).endormi, isFalse);
    await tester.pump(const Duration(seconds: 13));
  });
}
