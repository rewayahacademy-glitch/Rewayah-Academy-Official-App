// Captures de recette DISPO-1 (disponibilites de l'enseignant par plages :
// liste « Lundi | de 17 h | a 23 h » et feuille « Ajouter une plage » /
// « Modifier la plage »). Vraie page `CreneauxPage`, ouverte par de vrais
// gestes, service en memoire (aucun serveur), vraies polices.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// dispo1_<etat>_<largeur>_x<echelle>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

const String _monId = 't1';

List<Creneau> _plage(int jour, int de, int a) => <Creneau>[
  for (int h = de; h < a; h++)
    Creneau(jour: jour, heure: h, fuseau: 'Europe/Paris'),
];

List<Override> _surcharges() => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: _monId,
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  servicePlanningProvider.overrideWithValue(
    FauxServicePlanning()
      ..creneaux[_monId] = <Creneau>[
        ..._plage(1, 17, 23),
        ..._plage(3, 9, 12),
        ..._plage(3, 18, 21),
        ..._plage(4, 9, 11),
        ..._plage(6, 8, 12),
        ..._plage(7, 8, 12),
      ]
      ..affectationsRendues = <Affectation>[
        Affectation(
          id: 'a1',
          enseignantId: _monId,
          enseignantPrenom: 'Omar',
          enseignantIdentifiant: 'TEACH-OS-000001',
          eleveId: 'e1',
          elevePrenom: 'Yasmine',
          creneau: const Creneau(jour: 4, heure: 9, fuseau: 'Europe/Paris'),
          depuis: DateTime(2026, 9),
        ),
      ],
  ),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

const List<(Size, double, double, String)> _cadres =
    <(Size, double, double, String)>[
      (Size(320, 1400), 2, 2, '320_x2'),
      (Size(390, 844), 2, 1, '390_x1'),
      (Size(1440, 900), 1, 1, '1440_x1'),
    ];

void main() {
  group('Capture : DISPO-1 plages', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, double echelle, String nom)
          in _cadres) {
        final String suffixe = '${nom}_${mode.name}';

        Future<void> monter(WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              const CreneauxPage(),
              themeMode: mode,
              echelleTexte: echelle,
              surcharges: _surcharges(),
            ),
          );
          await stabiliser(tester);
        }

        testWidgets('liste $suffixe', (WidgetTester tester) async {
          await monter(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'dispo1_liste_$suffixe')}');
        });

        testWidgets('ajout $suffixe', (WidgetTester tester) async {
          await monter(tester);
          final Finder ajouter = find.text(t.enseignant.creneaux.ajouterPlage);
          await tester.ensureVisible(ajouter);
          await stabiliser(tester);
          await tester.tap(ajouter);
          await stabiliser(tester);
          await tester.tap(find.text('Lundi').last);
          await stabiliser(tester);
          await tester.tap(find.text('Mardi').last);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'dispo1_ajout_$suffixe')}');
        });

        testWidgets('modifier $suffixe', (WidgetTester tester) async {
          await monter(tester);
          final Finder jeudi = find.text('Jeudi');
          await tester.ensureVisible(jeudi);
          await stabiliser(tester);
          await tester.tap(jeudi);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'dispo1_modifier_$suffixe')}');
        });
      }
    }
  });
}
