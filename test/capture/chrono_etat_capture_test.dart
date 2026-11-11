// Captures de recette CHRONO-ETAT (directeur, 10 et 11/11/2026) : la capsule du
// chrono et la pilule d'etat unique de la salle, enseignant et eleve, a 390
// et 1440, clair et sombre, aux quatre etats (calme, bientot, depassement,
// fini), plus l'arabe. Horloge fixe : les PNG sont reproductibles.
// Saute sans CAPTURE_DIR. Nommage : chronoetat_<role>_<etat>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/media_salle.dart';
import 'package:rewayah_academy/features/salle_seance/pilule_etat_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
  depassementMax: const Duration(minutes: 15),
);

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 200), 3, '390'),
  (Size(1440, 200), 1, '1440'),
];

/// L'instant fige de chaque etat montre.
final Map<String, DateTime> _etats = <String, DateTime>{
  'calme': _t0.add(const Duration(minutes: 3, seconds: 16)),
  'bientot': _t0.add(const Duration(minutes: 56, seconds: 30)),
  'depassement': _t0.add(const Duration(minutes: 63, seconds: 12)),
  'fini': _t0.add(const Duration(minutes: 80)),
};

Widget _scene(VueSeance vue, {required bool enSalle}) => Builder(
  builder: (BuildContext context) => ColoredBox(
    // Le fond sombre de la salle, comme sous la pilule en seance.
    color: AppPalette.of(context).surfaceInverse.background,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: PorteeMediaSalle(
          presenceEnSalle: enSalle,
          child: Builder(
            builder: (BuildContext c) => PiluleEtatSalle(
              vue: vue,
              avecChrono: true,
              largeurMax: MediaQuery.sizeOf(c).width - 2 * AppSpacing.lg,
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('Capture : CHRONO-ETAT', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.enseignant,
      RoleSeance.eleve,
    ]) {
      for (final MapEntry<String, DateTime> etat in _etats.entries) {
        for (final (Size cadre, double densite, String largeur) in _cadres) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ]) {
            final String nom =
                'chronoetat_${role.name}_${etat.key}_${largeur}_${mode.name}';
            testWidgets(nom, (WidgetTester tester) async {
              fixerVueCapture(tester, cadre, densite);
              final VueSeance vue = DonneesSeanceDemo.vue(
                role,
                EtatDemoSalle.repos,
              ).copyWith(chrono: _bornes);
              await tester.pumpWidget(
                hoteCapture(
                  Scaffold(
                    body: _scene(vue, enSalle: role == RoleSeance.eleve),
                  ),
                  surcharges: <Override>[
                    horlogeChronoProvider.overrideWithValue(() => etat.value),
                    signalChronoProvider.overrideWithValue(() {}),
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

    testWidgets('chronoetat_eleve_calme_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      fixerVueCapture(tester, const Size(390, 200), 3);
      final VueSeance vue = DonneesSeanceDemo.vue(
        RoleSeance.eleve,
        EtatDemoSalle.repos,
      ).copyWith(chrono: _bornes);
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(body: _scene(vue, enSalle: true)),
          surcharges: <Override>[
            horlogeChronoProvider.overrideWithValue(() => _etats['calme']!),
            signalChronoProvider.overrideWithValue(() {}),
          ],
        ),
      );
      await stabiliser(tester);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'chronoetat_eleve_calme_390_light_ar')}',
      );
    });
  });
}
