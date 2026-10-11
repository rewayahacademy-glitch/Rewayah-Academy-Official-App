// Captures de recette ADM-CAHIER-LECTURE : la liste des cahiers d'une classe et
// le cahier en lecture seule (1440 et 390, clair et sombre). Saute sans
// CAPTURE_DIR. Donnees : le simulateur de test.
//
//   CAPTURE_DIR=docs/current/captures/ADM-CAHIER-LECTURE \
//     flutter test test/capture/adm_cahier_lecture_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/features/admin_groupes/cahiers_classe.dart';

import '../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart'
    show
        capturer,
        chargerPolicesDuDepot,
        fixerVueCapture,
        hoteCapture,
        sautSansCapture,
        stabiliser;

FauxPartagePedagogique _serveur() => FauxPartagePedagogique()
  ..rapports[('s1', 'e1')] = RapportSim()
  ..rapports[('s2', 'e1')] = RapportSim(autoPartage: false)
  ..rapports[('s1', 'e2')] = RapportSim()
  ..rapports[('s3', 'e3')] = RapportSim(confirme: false);

Future<void> _p(
  WidgetTester tester,
  String nom,
  Widget enfant,
  ThemeMode mode,
  Size taille,
  double densite, {
  PortPartagePedagogique? port,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: enfant,
            ),
          ),
        ),
      ),
      surcharges: <Override>[
        portPartagePedagogiqueProvider.overrideWithValue(port ?? _serveur()),
        sansPersonneConnectee(),
      ],
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : ADM-CAHIER-LECTURE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String m = mode == ThemeMode.light ? 'clair' : 'sombre';
      testWidgets('liste 1440 ($m)', (WidgetTester tester) async {
        await _p(
          tester,
          'web_liste_$m',
          const FeuilleCahiersClasse(classeId: 'c'),
          mode,
          const Size(1440, 900),
          1,
        );
      });
      testWidgets('cahier 1440 ($m)', (WidgetTester tester) async {
        await _p(
          tester,
          'web_cahier_$m',
          const FeuilleCahierAdmin(seanceId: 's1', eleveId: 'e1'),
          mode,
          const Size(1440, 1100),
          1,
        );
      });
      testWidgets('cahier mobile ($m)', (WidgetTester tester) async {
        await _p(
          tester,
          'mobile_cahier_$m',
          const FeuilleCahierAdmin(seanceId: 's1', eleveId: 'e1'),
          mode,
          const Size(390, 1200),
          2,
        );
      });
      testWidgets('production indisponible ($m)', (WidgetTester tester) async {
        await _p(
          tester,
          'web_indisponible_$m',
          const FeuilleCahiersClasse(classeId: 'c'),
          mode,
          const Size(1440, 500),
          1,
          port: const PartagePedagogiqueIndisponible(),
        );
      });
    }
  });
}
