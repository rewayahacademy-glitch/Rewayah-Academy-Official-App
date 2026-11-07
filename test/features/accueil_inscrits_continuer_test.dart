// INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : option (c) du garde-cap pour
// la page « Continuer » de l'accueil des familles deja inscrites
// (`/tuteur/inscription-reprise`) : l'action se voit sans defiler sur un
// telephone de 390 x 844, meme avec un long mot de la direction et cinq profils
// eleves a ajouter. Donnees inventees.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/import_inscriptions/port_reclamation_preinscription.dart';
import 'package:rewayah_academy/features/accueil_inscrits/accueil_inscrits_page.dart';

import '../support/garde_interface.dart';
import '../support/harnais.dart';

/// Le mot de patience, rempli comme le serveur le remplit (prenoms inventes).
const String _motLong =
    'Mariam, vous nous aviez demande, il y a longtemps deja, de vous '
    'inscrire, vous et Yasmine, Adam, Sara, Ilyes et Nour. Nous vous avions '
    'demande d attendre, et vous avez attendu, avec une patience et une '
    'confiance qui nous ont profondement touches. Vous faites partie des '
    'toutes premieres familles de la nouvelle Rewayah Academy. Bienvenue chez '
    'vous. La direction';

ReclamationPreinscription _famille() => ReclamationPreinscription(
  connue: true,
  motAccueil: _motLong,
  personnes: <PersonneImportee>[
    const PersonneImportee(
      id: 'p-tuteur',
      prenom: 'Mariam',
      nature: NaturePersonneImportee.tuteur,
    ),
    for (final String p in <String>['Yasmine', 'Adam', 'Sara', 'Ilyes', 'Nour'])
      PersonneImportee(
        id: 'p-$p',
        prenom: p,
        nature: NaturePersonneImportee.eleve,
      ),
  ],
);

Future<int> _monter(WidgetTester tester, Size taille, double texte) async {
  tester.view
    ..physicalSize = taille
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  int continuer = 0;
  await tester.pumpWidget(
    hote(
      VueAccueilInscrits(
        reclamation: _famille(),
        onAjouter: (PersonneImportee _) {},
        onContinuer: () => continuer++,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return continuer;
}

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('390 x 844 : « Continuer » se voit sans defiler, avant le mot '
      'et la liste', (WidgetTester tester) async {
    await _monter(tester, const Size(390, 844), 1);
    final Finder action = find.byKey(AccueilInscritsPage.continuerKey);
    final Rect r = tester.getRect(action);
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(844), reason: 'y=${r.top}-${r.bottom}');
    expect(action.hitTestable(), findsOneWidget);
    // Le mot et la liste viennent sous l'action : rien n'est retire.
    expect(
      tester.getRect(find.byKey(VueAccueilInscrits.motKey)).top,
      greaterThan(r.bottom),
    );
    expect(find.byKey(VueAccueilInscrits.eleveKey('p-Nour')), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('390 x 844 : un toucher sur « Continuer », sans defiler, '
      'continue', (WidgetTester tester) async {
    int appels = 0;
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        VueAccueilInscrits(
          reclamation: _famille(),
          onAjouter: (PersonneImportee _) {},
          onContinuer: () => appels++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccueilInscritsPage.continuerKey));
    await tester.pump();
    expect(appels, 1);
  });

  testWidgets('320 x 640, texte x2 : « Continuer » se voit encore sans '
      'defiler', (WidgetTester tester) async {
    await _monter(tester, const Size(320, 640), 2);
    final Rect r = tester.getRect(find.byKey(AccueilInscritsPage.continuerKey));
    expect(r.bottom, lessThanOrEqualTo(640), reason: 'y=${r.top}-${r.bottom}');
    expect(tester.takeException(), isNull);
  });
}
