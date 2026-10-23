// EN-6 : ENS-05A, la photo publique professionnelle (doc 04 section 24).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../../capture/outil_capture.dart';

class _ChoixTemoin implements ChoixPhotoPublique {
  const _ChoixTemoin();

  @override
  Future<PhotoChoisie?> choisir() async => const PhotoChoisie();
}

Future<void> _monterDemo(WidgetTester tester, EcranDemoEnseignant ecran) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hoteCapture(CoquilleEnseignantDemo(ecran: ecran)));
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  testWidgets('les textes du doc 04 section 24 sont dits', (
    WidgetTester tester,
  ) async {
    await _monterDemo(tester, EcranDemoEnseignant.profil);
    await _toucher(tester, find.text(t.enseignant.photo.choisir).first);

    expect(find.text(t.enseignant.photo.titre), findsOneWidget);
    expect(find.text(t.enseignant.photo.aide), findsOneWidget);
    expect(find.text(t.enseignant.photo.notice), findsOneWidget);
    expect(find.byKey(EditeurPhotoPublique.choisirKey), findsOneWidget);
  });

  testWidgets('l apercu vient avant « Utiliser cette photo », puis le succes', (
    WidgetTester tester,
  ) async {
    await _monterDemo(tester, EcranDemoEnseignant.profil);
    await _toucher(tester, find.text(t.enseignant.photo.choisir).first);
    await _toucher(tester, find.byKey(EditeurPhotoPublique.choisirKey));

    expect(find.byKey(EditeurPhotoPublique.apercuKey), findsOneWidget);
    expect(find.text(t.enseignant.photo.autre), findsOneWidget);
    expect(find.text(t.enseignant.photo.succes), findsNothing);

    await tester.tap(find.byKey(EditeurPhotoPublique.utiliserKey));
    await tester.pump();
    // Pas de succes avant la reponse.
    expect(find.text(t.enseignant.photo.succes), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await stabiliser(tester);
    expect(find.text(t.enseignant.photo.succes), findsOneWidget);
    expect(find.text(t.enseignant.photo.remplacer), findsOneWidget);
  });

  testWidgets('sans branchement serveur, l envoi echoue et le dit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const Scaffold(body: EditeurPhotoPublique(prenom: 'Ibrahim')),
        surcharges: <Override>[
          choixPhotoPubliqueProvider.overrideWithValue(const _ChoixTemoin()),
          horsLigneProvider.overrideWith((_) => Stream<bool>.value(false)),
        ],
      ),
    );
    await stabiliser(tester);
    await _toucher(tester, find.byKey(EditeurPhotoPublique.choisirKey));
    await _toucher(tester, find.byKey(EditeurPhotoPublique.utiliserKey));

    expect(find.text(t.enseignant.photo.echec), findsOneWidget);
    expect(find.text(t.enseignant.photo.succes), findsNothing);
  });

  testWidgets('hors ligne : « Utiliser » n est pas rendu, jamais grise, la '
      'phrase dit quand envoyer (BOUTONS-GRISES-1)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const Scaffold(body: EditeurPhotoPublique(prenom: 'Ibrahim')),
        surcharges: <Override>[
          choixPhotoPubliqueProvider.overrideWithValue(const _ChoixTemoin()),
          horsLigneProvider.overrideWith((_) => Stream<bool>.value(true)),
        ],
      ),
    );
    await stabiliser(tester);
    await _toucher(tester, find.byKey(EditeurPhotoPublique.choisirKey));

    expect(find.byKey(EditeurPhotoPublique.apercuKey), findsOneWidget);
    expect(find.byKey(EditeurPhotoPublique.utiliserKey), findsNothing);
    expect(find.text(t.enseignant.photo.horsLigne), findsOneWidget);
    // Choisir une autre photo reste possible : elle se prepare sans reseau.
    expect(find.text(t.enseignant.photo.autre), findsOneWidget);
  });

  testWidgets('ENS-01 en demonstration : la photo manque, puis est faite', (
    WidgetTester tester,
  ) async {
    await _monterDemo(tester, EcranDemoEnseignant.premiersPas);

    expect(find.byType(BienvenueEnseignantPage), findsOneWidget);
    expect(
      find.text(t.enseignant.bienvenue.compteur(fait: 3, total: 4)),
      findsOneWidget,
    );
    await _toucher(tester, find.text(t.enseignant.bienvenue.ctaPhoto));
    await _toucher(tester, find.byKey(EditeurPhotoPublique.choisirKey));
    await tester.tap(find.byKey(EditeurPhotoPublique.utiliserKey));
    await tester.pump(const Duration(seconds: 1));
    await stabiliser(tester);

    // Doc §10.1 : une tâche confirmée n'est plus affichée ; les quatre
    // étant faites, la carte « À compléter » disparaît.
    expect(find.text(t.enseignant.bienvenue.ctaPhoto), findsNothing);
    expect(
      find.text(t.enseignant.bienvenue.compteur(fait: 3, total: 4)),
      findsNothing,
    );
  });
}
