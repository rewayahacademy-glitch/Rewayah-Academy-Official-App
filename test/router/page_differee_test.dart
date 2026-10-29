// Lot ouverture rapide (29/10/2026) : un ecran differe montre la zone vide
// pendant le chargement de son morceau, puis l'ecran ; « Reessayer » apres un
// echec ; la phrase du chargement prolonge apres 8 s ; un morceau deja charge
// se construit des la premiere image.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/page_differee.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';

import '../support/hote_theme.dart';

const Key _ecran = ValueKey<String>('ecran-differe');

Widget _page(String cle, Future<void> Function() charger) => hoteTheme(
  PageDifferee(
    cle: cle,
    charger: charger,
    construire: () => const SizedBox(key: _ecran),
  ),
  defilant: false,
);

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

  testWidgets('echec : la phrase et Reessayer, qui relance', (
    WidgetTester tester,
  ) async {
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
    expect(_etat(NatureEtat.horsLigne), findsOneWidget);
    await tester.tap(find.text(t.commun.etats.actions.reessayer));
    await tester.pump();
    await tester.pump();
    expect(appels, 2);
    expect(find.byKey(_ecran), findsOneWidget);
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
