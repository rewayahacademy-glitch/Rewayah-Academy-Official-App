// Fiche « Fraicheur et notifications » (27/10/2026), lignes 17 et 18 : la
// remise a zero renouvelle la portee des providers de l'application reelle.
// Ce qu'un provider gardait en memoire pour la personne precedente n'existe
// plus ; la personne suivante lit une memoire neuve.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/session/deconnexion.dart';
import 'package:rewayah_academy/features/demo/racine_demonstrable.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart' show FausseSourceSession;

void main() {
  testWidgets('la remise a zero renouvelle la portee reelle', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RacineDemonstrable(
        environnement: 'production',
        surchargesReelles: surchargesRouteur(FausseSourceSession()),
      ),
    );
    await stabiliser(tester);

    ProviderContainer conteneur() =>
        ProviderScope.containerOf(tester.element(find.byType(RewayahApp)));

    final ProviderContainer avant = conteneur();
    avant.read(avisEphemereProvider.notifier).dire('memoire de la personne');
    await tester.pump();
    expect(avant.read(avisEphemereProvider), 'memoire de la personne');
    expect(find.text('memoire de la personne'), findsOneWidget);

    avant.read(remiseAZeroProvider)();
    await stabiliser(tester);

    final ProviderContainer apres = conteneur();
    expect(identical(avant, apres), isFalse);
    expect(apres.read(avisEphemereProvider), isNull);
    expect(find.text('memoire de la personne'), findsNothing);
    // La portee suivante sait encore se remettre a zero.
    apres.read(remiseAZeroProvider)();
    await stabiliser(tester);
    expect(identical(apres, conteneur()), isFalse);
  });

  testWidgets('hors de la racine reelle, la remise a zero ne fait rien', (
    WidgetTester tester,
  ) async {
    final ProviderContainer conteneur = ProviderContainer();
    addTearDown(conteneur.dispose);
    conteneur.read(remiseAZeroProvider)();
  });
}
