// Lot ouverture rapide (29/10/2026) : un ecran differe montre la zone vide
// pendant le chargement de son morceau, puis l'ecran ; la phrase du
// chargement prolonge apres 8 s ; un morceau deja charge se construit des la
// premiere image.
//
// Lot RECHARGE-1 (03/11/2026) : un echec ne se dit « hors ligne » que hors
// ligne ; en ligne, « Reessayer » puis « Recharger » ; un morceau d'une autre
// version (deploiement) : « Recharger » d'emblee ; le retour du reseau relance
// seul l'ecran.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/page_differee.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';

import '../support/hote_theme.dart';

const Key _ecran = ValueKey<String>('ecran-differe');

Widget _page(
  String cle,
  Future<void> Function() charger, {
  VoidCallback? recharger,
  Stream<bool>? reseau,
}) => hoteTheme(
  PageDifferee(
    cle: cle,
    charger: charger,
    construire: () => const SizedBox(key: _ecran),
    recharger: recharger ?? () {},
  ),
  defilant: false,
  surcharges: <Override>[
    if (reseau != null) horsLigneProvider.overrideWith((Ref _) => reseau),
  ],
);

/// Le refus de dart2js quand le fichier recu n'est pas le bon (deploiement).
const String _refusDart2js =
    'DeferredLoadException: Loading main.dart.js_38.part.js failed: '
    'Success callback invoked but parts main.dart.js_38.part.js not loaded.';

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

void main() {
  testWidgets('zone vide pendant le chargement, puis l ecran', (
    WidgetTester tester,
  ) async {
    final Completer<void> chargement = Completer<void>();
    await tester.pumpWidget(_page('essai-a', () => chargement.future));
    expect(find.byKey(_ecran), findsNothing);
    expect(find.byType(EtatSysteme), findsNothing);
    chargement.complete();
    await tester.pump();
    expect(find.byKey(_ecran), findsOneWidget);
    expect(PageDifferee.estCharge('essai-a'), isTrue);
  });

  testWidgets('deja charge : l ecran des la premiere image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_page('essai-b', () async {}));
    await tester.pump();
    var appels = 0;
    await tester.pumpWidget(
      _page('essai-b', () async {
        appels++;
      }),
    );
    expect(find.byKey(_ecran), findsOneWidget);
    expect(appels, 0);
  });

  testWidgets('en ligne, un echec ne dit jamais hors ligne : Reessayer '
      'relance', (WidgetTester tester) async {
    var appels = 0;
    await tester.pumpWidget(
      _page('essai-c', () async {
        appels++;
        if (appels == 1) {
          throw StateError('reseau coupe');
        }
      }),
    );
    await tester.pump();
    expect(_etat(NatureEtat.horsLigne), findsNothing);
    expect(find.text(t.commun.etats.recharge1.ouvertureTitre), findsOneWidget);
    await tester.tap(find.text(t.commun.etats.actions.reessayer));
    await tester.pump();
    await tester.pump();
    expect(appels, 2);
    expect(find.byKey(_ecran), findsOneWidget);
  });

  testWidgets('en ligne, un second echec : Recharger, qui recharge la page', (
    WidgetTester tester,
  ) async {
    var rechargements = 0;
    await tester.pumpWidget(
      _page(
        'essai-e',
        () async => throw StateError('interrompu'),
        recharger: () => rechargements++,
      ),
    );
    await tester.pump();
    await tester.tap(find.text(t.commun.etats.actions.reessayer));
    await tester.pump();
    await tester.pump();
    expect(find.text(t.commun.etats.recharge1.repetePhrase), findsOneWidget);
    await tester.tap(find.text(t.miseAJour.recharger));
    expect(rechargements, 1);
  });

  testWidgets('apres un deploiement : nouvelle version et Recharger, '
      'jamais hors ligne', (WidgetTester tester) async {
    var rechargements = 0;
    var appels = 0;
    await tester.pumpWidget(
      _page('essai-f', () async {
        appels++;
        throw Exception(_refusDart2js);
      }, recharger: () => rechargements++),
    );
    await tester.pump();
    expect(_etat(NatureEtat.horsLigne), findsNothing);
    expect(find.text(t.miseAJour.prete), findsOneWidget);
    expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    await tester.tap(find.text(t.miseAJour.recharger));
    expect(rechargements, 1);
    expect(appels, 1, reason: 'Reessayer rejouerait le meme refus');
  });

  testWidgets('hors ligne : hors ligne, puis l ecran revient seul au retour '
      'du reseau', (WidgetTester tester) async {
    final StreamController<bool> reseau = StreamController<bool>();
    addTearDown(reseau.close);
    var appels = 0;
    await tester.pumpWidget(
      _page('essai-g', () async {
        appels++;
        if (appels == 1) {
          throw StateError('reseau coupe');
        }
      }, reseau: reseau.stream),
    );
    reseau.add(true);
    await tester.pump();
    await tester.pump();
    expect(_etat(NatureEtat.horsLigne), findsOneWidget);
    reseau.add(false);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(appels, 2);
    expect(find.byKey(_ecran), findsOneWidget);
  });

  group('classerEchecMorceau', () {
    test('hors ligne prime', () {
      expect(
        classerEchecMorceau(
          Exception(_refusDart2js),
          horsLigne: true,
          echecsEnLigne: 0,
        ),
        EchecMorceau.horsLigne,
      );
    });
    test('« not loaded » : une autre version', () {
      expect(
        classerEchecMorceau(
          Exception(_refusDart2js),
          horsLigne: false,
          echecsEnLigne: 1,
        ),
        EchecMorceau.versionChangee,
      );
    });
    test('en ligne : ouverture, puis repete', () {
      final Object coupure = StateError('js-failure-wrapper');
      expect(
        classerEchecMorceau(coupure, horsLigne: false, echecsEnLigne: 1),
        EchecMorceau.ouverture,
      );
      expect(
        classerEchecMorceau(coupure, horsLigne: false, echecsEnLigne: 2),
        EchecMorceau.repete,
      );
    });
  });

  testWidgets('chargement long : la phrase du chargement prolonge', (
    WidgetTester tester,
  ) async {
    final Completer<void> chargement = Completer<void>();
    await tester.pumpWidget(_page('essai-d', () => chargement.future));
    await tester.pump(AppDelais.chargementProlonge);
    await tester.pump();
    expect(_etat(NatureEtat.chargementProlonge), findsOneWidget);
    chargement.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_ecran), findsOneWidget);
  });
}
