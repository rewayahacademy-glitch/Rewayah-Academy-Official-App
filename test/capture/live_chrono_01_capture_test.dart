// Captures de recette LIVE-CHRONO-01 : l'en-tete de la salle de classe avec son
// chrono discret, enseignant et eleve, a 390 et 1440, clair et sombre, plus
// l'etat « Temps prevu ecoule ». Horloge fixe : les PNG sont reproductibles.
// Saute sans CAPTURE_DIR. Nommage : livechrono01_<role>_<etat>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
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
);

final DateTime _t0 = DateTime.utc(2026, 10, 12, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 45)),
);

const List<(Size, double, String, EdgeInsets)> _cadres =
    <(Size, double, String, EdgeInsets)>[
      (Size(390, 844), 3, '390', EdgeInsets.only(top: 47, bottom: 34)),
      (Size(1440, 900), 1, '1440', EdgeInsets.zero),
    ];

/// L'instant fige de chaque etat montre.
final Map<String, DateTime> _etats = <String, DateTime>{
  'encours': _t0.add(const Duration(minutes: 12, seconds: 34)),
  'prevuecoule': _t0.add(const Duration(minutes: 50)),
};

void main() {
  group('Capture : LIVE-CHRONO-01', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.enseignant,
      RoleSeance.eleve,
    ]) {
      for (final MapEntry<String, DateTime> etat in _etats.entries) {
        for (final (Size cadre, double densite, String largeur, EdgeInsets zone)
            in _cadres) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            final String nom =
                'livechrono01_${role.name}_${etat.key}_${largeur}_${mode.name}';
            testWidgets(nom, (WidgetTester tester) async {
              fixerVueCapture(tester, cadre, densite, zoneSure: zone);
              final VueSeance vue = DonneesSeanceDemo.vue(
                role,
                EtatDemoSalle.repos,
              ).copyWith(chrono: _bornes);
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
                    horlogeChronoProvider.overrideWithValue(() => etat.value),
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
    }
  });
}
