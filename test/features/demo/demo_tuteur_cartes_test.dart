// CARTES-PERSO-1b (revue adverse, deuxieme passe, MAJEUR) : dans la VRAIE
// demonstration tuteur (« Essayer la demonstration », P2-07), la page Classe
// du tuteur lit les cartes de demonstration, les memes que la demonstration
// enseignant, en lecture seule. Avant, son port n'etait pas surcharge et la
// page disait « Les cartes de la classe ne sont pas encore ouvertes ».
//
// Aucune injection manuelle des cartes : seules les surcharges annexes du
// test d'entree (stockage en memoire, horloge muette) sont ajoutees, et le
// parcours passe par l'entree, puis la carte de l'Accueil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/features/accueil_famille/carte_classe_seance.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/racine_demonstrable.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../../capture/outil_capture.dart' as capture;
import '../../router/support_routeur.dart';
import '../../support/harnais.dart' show FausseSourceSession;
import '../../teaching_core/a/faux/faux_groupes.dart' show PortHorlogeMuet;

List<Override> _communes() => <Override>[
  stockagePreferencesProvider.overrideWithValue(StockagePreferencesMemoire()),
  portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
];

Future<void> _jusquALaClasse(
  WidgetTester tester, {
  Size taille = const Size(390, 2600),
  ThemeMode? mode,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: capture.cadreCapture,
      child: RacineDemonstrable(
        environnement: 'staging',
        themeMode: mode,
        surchargesDemoAnnexes: _communes(),
        surchargesReelles: surchargesRouteur(FausseSourceSession()),
      ),
    ),
  );
  await stabiliser(tester);
  final Finder entree = find.byKey(
    const ValueKey<String>('entree-demonstration'),
  );
  await tester.ensureVisible(entree);
  await tester.tap(entree);
  await stabiliser(tester);
  // L'Accueil du tuteur fictif : la carte de la classe mene a la Classe.
  final Finder carte = find.byType(CarteClasseSeance).first;
  await tester.ensureVisible(carte);
  await stabiliser(tester);
  await tester.tap(carte);
  await stabiliser(tester);
  expect(find.byType(ClasseTuteurPage), findsOneWidget);
}

void main() {
  testWidgets('demonstration tuteur : la Classe montre les cartes de '
      'demonstration, en lecture seule', (WidgetTester tester) async {
    await _jusquALaClasse(tester);
    expect(find.byType(BlocCartesClasse), findsOneWidget);
    // Plus d'etat « pas encore ouvertes ».
    expect(find.text(t.classe.cartes.indisponibleTitre), findsNothing);
    final Finder cartes = find.byType(VueCarteClasse);
    final List<String> titres = <String>[
      for (final VueCarteClasse v in tester.widgetList<VueCarteClasse>(cartes))
        v.carte.titre,
    ];
    // Les memes cartes que la demonstration enseignant, dans son ordre.
    expect(titres, <String>[
      for (final c in cartesClasseDemo(DateTime.now())) c.titre,
    ]);
    // Capacite fausse : rien ne se presse, rien ne s'ajoute.
    for (final VueCarteClasse v in tester.widgetList<VueCarteClasse>(cartes)) {
      expect(v.onModifier, isNull, reason: v.carte.titre);
    }
    expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
    await tester.ensureVisible(cartes.first);
    await stabiliser(tester);
    await tester.tap(cartes.first, warnIfMissed: false);
    await stabiliser(tester);
    expect(find.byType(FeuilleCarteClasse), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('capture', skip: capture.sautSansCapture, () {
    setUpAll(capture.chargerPolicesDuDepot);
    testWidgets('demonstration tuteur, Classe 390 clair', (
      WidgetTester tester,
    ) async {
      await _jusquALaClasse(tester, mode: ThemeMode.light);
      await tester.ensureVisible(find.byType(BlocCartesClasse));
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capture.capturer(tester, 'demo_tuteur_classe_390_clair')}',
      );
    });
  });
}
