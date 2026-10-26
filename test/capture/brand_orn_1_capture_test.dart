// BRAND-ORN-1 : captures de la signature discrete de la marque, une par
// emplacement propose : demarrage, accueil de l'eleve, confirmation (fin de
// « recu »). Plus le cadre du Coran (MUSHAF-15L), deja decide, pour memoire.
// A 390 points, en clair et en sombre.
//
// Saute sans CAPTURE_DIR. Sortie de preuve :
// docs/current/captures/BRAND-ORN-1/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : BRAND-ORN-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      final String n = theme.name;

      testWidgets('1 demarrage $n', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            const EcranDemarrage(),
            themeMode: theme,
            surcharges: <Override>[
              sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            ],
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'ornement_1_demarrage_$n')}');
      });

      testWidgets('2 accueil eleve $n', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            AccueilElevePage(horloge: () => DateTime(2026, 9, 8, 17)),
            themeMode: theme,
            surcharges: <Override>[
              servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
              servicePriereProvider.overrideWithValue(FauxServicePriere()),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'ornement_2_accueil_$n')}');
      });

      testWidgets('3 confirmation $n', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            const PageShell(
              child: EcranResultat(
                icone: AppIcons.accueil,
                titre: 'Inscription confirmée',
                phrase: 'Nous vous écrivons dès que la classe est prête.',
                ton: TonEtat.succes,
                libelleAction: 'Retour à l\'accueil',
                onAction: _rien,
              ),
            ),
            themeMode: theme,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint(
          'PNG ${await capturer(tester, 'ornement_3_confirmation_$n')}',
        );
      });
    }
  });
}

void _rien() {}
