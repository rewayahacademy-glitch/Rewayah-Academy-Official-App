// FORM-L9 (recensement FORM-AUTO-1, E1) : la position de reprise du cahier de
// transmission se CHOISIT (sourate puis verset), elle ne se tape plus. Le
// clavier ne revient que si la liste des sourates est illisible. La phrase
// envoyee (`positionReprise`) reste « Sourate N, verset M ».
//
// Les 114 sourates viennent de la migration `0013_corpus_coranique.sql` (la
// donnee du depot), jamais d'une liste recopiee ici.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/features/cahier/selecteur_reprise.dart';

import '../../capture/outil_capture.dart';
import '../../support/cahier_sourates.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  late List<SourateVM> sourates;
  setUpAll(() => sourates = souratesDeLaMigration());

  test('la migration rend 114 sourates et 6236 versets', () {
    expect(sourates, hasLength(114));
    expect(
      sourates.fold<int>(0, (int s, SourateVM v) => s + v.nombreVersets),
      6236,
    );
  });

  test('la phrase envoyee ne change pas', () {
    expect(
      const PositionReprise(sourate: 18, verset: 10).texte,
      t.enseignant.cahier.repriseProposee(sourate: '18', verset: '10'),
    );
  });

  testWidgets('la reprise proposee se lit dans un champ a choisir, sans '
      'clavier', (WidgetTester tester) async {
    await monterCahier(tester, CorpusSourates(sourates));

    final Finder champ = find.byKey(ChampReprise.champKey);
    expect(champ, findsOneWidget);
    expect(tester.widget(champ), isNot(isA<TextField>()));
    // La proposition du brouillon de demonstration : sourate 78, verset 12.
    expect(
      find.text(
        t.enseignant.cahier.repriseProposee(sourate: '78', verset: '12'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('choisir Al-Kahf puis le verset 10 ecrit la reprise', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates));
    await _toucher(tester, find.byKey(ChampReprise.champKey));

    // La sourate proposee est deja retenue, et son verset aussi.
    expect(find.byKey(FeuilleReprise.sourateKey(78)), findsOneWidget);
    expect(find.byKey(FeuilleReprise.versetKey(40)), findsOneWidget);
    expect(find.byKey(FeuilleReprise.versetKey(41)), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, t.enseignant.cahier.repriseRecherche),
      'kahf',
    );
    await stabiliser(tester);
    await _toucher(tester, find.byKey(FeuilleReprise.sourateKey(18)));
    // Changer de sourate relache le verset : il faut le choisir.
    await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));
    expect(find.text(t.enseignant.cahier.repriseIncomplete), findsOneWidget);
    expect(find.byKey(FeuilleReprise.versetKey(110)), findsOneWidget);

    await _toucher(tester, find.byKey(FeuilleReprise.versetKey(10)));
    await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));

    expect(find.byType(FeuilleReprise), findsNothing);
    expect(
      find.text(
        t.enseignant.cahier.repriseProposee(sourate: '18', verset: '10'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recherche par numero, et aucune sourate : etat dit', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates));
    await _toucher(tester, find.byKey(ChampReprise.champKey));
    final Finder recherche = find.widgetWithText(
      TextField,
      t.enseignant.cahier.repriseRecherche,
    );
    await tester.enterText(recherche, '112');
    await stabiliser(tester);
    expect(find.byKey(FeuilleReprise.sourateKey(112)), findsOneWidget);

    await tester.enterText(recherche, 'zzz');
    await stabiliser(tester);
    expect(find.text(t.enseignant.cahier.repriseAucune), findsOneWidget);
  });

  testWidgets('liste illisible : le champ redevient une saisie, et le dit', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates, echoue: true));
    final Finder champ = find.byKey(ChampReprise.champKey);
    expect(tester.widget(champ), isA<TextField>());
    expect(
      find.byKey(const ValueKey<String>('cahier-reprise-sans-liste')),
      findsOneWidget,
    );
  });
}
