// Captures de recette LIVE-PAUSE-01 : la ligne du chrono avec la pause
// (« Pause dans N min », en cours, prise), le bloc de reglage de la fiche de la
// classe, a 390 et 1440, clair et sombre. Horloge fixe. Saute sans CAPTURE_DIR.
// Nommage : livepause01_<ecran>_<etat>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/pause_seance_demonstration.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart'
    show horsLigneProvider;
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/fiche_groupe/bloc_pause_classe.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import 'outil_capture.dart';

void _rien() {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onPause: _rien,
);

final DateTime _t0 = DateTime.utc(2026, 10, 12, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
);

const List<(Size, double, String, EdgeInsets)> _cadres =
    <(Size, double, String, EdgeInsets)>[
      (Size(390, 844), 3, '390', EdgeInsets.only(top: 47, bottom: 34)),
      (Size(1440, 900), 1, '1440', EdgeInsets.zero),
    ];

/// Chaque etat : (instant fige, pause).
final Map<String, (DateTime, PauseSeance)> _etats =
    <String, (DateTime, PauseSeance)>{
      'dans': (
        _t0.add(const Duration(minutes: 15, seconds: 20)),
        PauseSeance(
          statut: StatutPause.programmee,
          dureePrevueMinutes: 10,
          debutPrevuUtc: _t0.add(const Duration(minutes: 20)),
          peutPiloter: true,
        ),
      ),
      'encours': (
        _t0.add(const Duration(minutes: 24)),
        PauseSeance(
          statut: StatutPause.enCours,
          dureePrevueMinutes: 10,
          debutPrevuUtc: _t0.add(const Duration(minutes: 20)),
          debutUtc: _t0.add(const Duration(minutes: 20)),
          peutPiloter: true,
        ),
      ),
      'prise': (
        _t0.add(const Duration(minutes: 40)),
        PauseSeance(
          statut: StatutPause.prise,
          dureePrevueMinutes: 10,
          debutPrevuUtc: _t0.add(const Duration(minutes: 20)),
          debutUtc: _t0.add(const Duration(minutes: 20)),
          finUtc: _t0.add(const Duration(minutes: 30)),
          peutPiloter: true,
        ),
      ),
    };

void main() {
  group('Capture : LIVE-PAUSE-01', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final MapEntry<String, (DateTime, PauseSeance)> etat
        in _etats.entries) {
      for (final (Size cadre, double densite, String largeur, EdgeInsets zone)
          in _cadres) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String nom =
              'livepause01_chrono_${etat.key}_${largeur}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, cadre, densite, zoneSure: zone);
            final VueSeance vue = DonneesSeanceDemo.vue(
              RoleSeance.enseignant,
              EtatDemoSalle.repos,
            ).copyWith(chrono: _bornes, pause: etat.value.$2);
            await tester.pumpWidget(
              hoteCapture(
                Scaffold(
                  body: SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ChromeSeance(vue: vue, actions: _actions),
                    ),
                  ),
                ),
                surcharges: <Override>[
                  horlogeChronoProvider.overrideWithValue(() => etat.value.$1),
                ],
                themeMode: mode,
              ),
            );
            await stabiliser(tester);
            await tester.pump(const Duration(milliseconds: 1400));
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
      }
    }

    for (final (Size cadre, double densite, String largeur, EdgeInsets zone)
        in _cadres) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = 'livepause01_fiche_reglage_${largeur}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cadre, densite, zoneSure: zone);
          await tester.pumpWidget(
            hoteCapture(
              const Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: BlocPauseClasse(groupeId: 'g1'),
                  ),
                ),
              ),
              surcharges: <Override>[
                portPauseSeanceProvider.overrideWithValue(
                  PauseSeanceDemonstration(),
                ),
                horsLigneProvider.overrideWith(
                  (Ref _) => Stream<bool>.value(false),
                ),
              ],
              themeMode: mode,
            ),
          );
          await stabiliser(tester);
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}
