// P2-07 : entree « Essayer la demonstration » et repere permanent.
//
// Le parcours : Bienvenue -> entree -> Accueil, Foyer, Historique, Compte du
// tuteur fictif, repere « Demonstration » sur chaque page. En production,
// l'entree n'existe pas. Les captures (390x844, 1440x900, clair et sombre)
// sont sautees sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/features/demo/racine_demonstrable.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../capture/outil_capture.dart' as capture;
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../../teaching_core/a/faux/faux_groupes.dart' show PortHorlogeMuet;

/// Ce que ni la demonstration ni l'application ne doivent lire d'un disque
/// ou d'une horloge reelle sous test.
List<Override> _communes() => <Override>[
  stockagePreferencesProvider.overrideWithValue(StockagePreferencesMemoire()),
  portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
];

Future<void> _monter(
  WidgetTester tester, {
  required String environnement,
  Size taille = const Size(390, 844),
  ThemeMode? mode,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: capture.cadreCapture,
      child: RacineDemonstrable(
        environnement: environnement,
        themeMode: mode,
        surchargesDemoAnnexes: _communes(),
        surchargesReelles: surchargesRouteur(FausseSourceSession()),
      ),
    ),
  );
  await stabiliser(tester);
}

Future<void> _allerA(WidgetTester tester, String libelle) async {
  await tester.tap(find.text(libelle).last);
  await stabiliser(tester);
}

void _repereVisible() {
  expect(
    find.byWidgetPredicate(
      (Widget w) => w is Banner && w.message == libelleRepereDemonstration,
    ),
    findsOneWidget,
  );
}

void main() {
  testWidgets('hors production : entree, puis les quatre pages du tuteur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, environnement: 'staging');
    final Finder entree = find.byKey(
      const ValueKey<String>('entree-demonstration'),
    );
    expect(entree, findsOneWidget);
    expect(find.text(libelleEntreeDemonstration), findsOneWidget);
    expect(find.byType(Banner), findsNothing);
    await tester.ensureVisible(entree);
    await tester.tap(entree);
    await stabiliser(tester);

    expect(entree, findsNothing);
    _repereVisible();
    for (final String page in <String>[
      t.nav.tuteur.foyer,
      t.nav.tuteur.historique,
      t.nav.tuteur.compte,
      t.nav.tuteur.accueil,
    ]) {
      await _allerA(tester, page);
      _repereVisible();
      expect(tester.takeException(), isNull, reason: page);
    }
  });

  testWidgets('en production : aucune entree, aucune bascule', (
    WidgetTester tester,
  ) async {
    await _monter(tester, environnement: 'production');
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text(libelleEntreeDemonstration), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('entree-demonstration')),
      findsNothing,
    );
    expect(find.byType(Banner), findsNothing);
  });

  testWidgets('sans lanceur (application ordinaire) : l entree ne rend rien', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hote(const EntreeDemonstration()));
    expect(find.text(libelleEntreeDemonstration), findsNothing);
  });

  group('captures de la demonstration', skip: capture.sautSansCapture, () {
    setUpAll(() async {
      await capture.chargerPolicesDuDepot();
    });

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe =
            '${taille.width.toInt()}x${taille.height.toInt()}_${mode.name}';
        testWidgets('parcours $suffixe', (WidgetTester tester) async {
          await _monter(
            tester,
            environnement: 'staging',
            taille: taille,
            mode: mode,
          );
          final Finder entree = find.byKey(
            const ValueKey<String>('entree-demonstration'),
          );
          await tester.ensureVisible(entree);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capture.capturer(tester, 'demo_entree_$suffixe')}',
          );
          await tester.tap(entree);
          await stabiliser(tester);
          for (final (String nom, String libelle) in <(String, String)>[
            ('accueil', t.nav.tuteur.accueil),
            ('foyer', t.nav.tuteur.foyer),
            ('historique', t.nav.tuteur.historique),
            ('compte', t.nav.tuteur.compte),
          ]) {
            await _allerA(tester, libelle);
            debugPrint(
              'PNG ${await capture.capturer(tester, 'demo_${nom}_$suffixe')}',
            );
          }
        });
      }
    }
  });
}
