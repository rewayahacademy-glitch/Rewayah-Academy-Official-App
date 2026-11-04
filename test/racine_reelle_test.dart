// Lot DEMO-PROD (04/11/2026) : la racine que `main.dart` passe a `runApp` en
// production. Elle porte la remise a zero (fiche du 27/10/2026, lignes 17 et
// 18) et aucun lanceur de demonstration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/session/deconnexion.dart';
import 'package:rewayah_academy/racine_reelle.dart';

import 'router/support_routeur.dart';
import 'support/demo/racine_demonstrable.dart';
import 'support/harnais.dart' show FausseSourceSession;

void main() {
  testWidgets(
    'la racine reelle se remet a zero, sans lanceur de demonstration',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RacineReelle(surcharges: surchargesRouteur(FausseSourceSession())),
      );
      await stabiliser(tester);

      ProviderContainer conteneur() =>
          ProviderScope.containerOf(tester.element(find.byType(RewayahApp)));

      final ProviderContainer avant = conteneur();
      expect(avant.read(lanceurDemoProvider), isNull);
      expect(find.byType(RacineDemonstrable), findsNothing);
      avant.read(avisEphemereProvider.notifier).dire('memoire de la personne');
      await tester.pump();
      expect(find.text('memoire de la personne'), findsOneWidget);

      avant.read(remiseAZeroProvider)();
      await stabiliser(tester);

      final ProviderContainer apres = conteneur();
      expect(identical(avant, apres), isFalse);
      expect(apres.read(avisEphemereProvider), isNull);
      expect(find.text('memoire de la personne'), findsNothing);
    },
  );
}
