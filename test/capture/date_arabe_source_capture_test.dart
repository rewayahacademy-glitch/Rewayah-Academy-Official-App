// Captures R3 de DATE-ARABE-SOURCE : le planning de la direction en arabe,
// APRES la correction (la date de l'en-tete et des jours dans l'ordre de
// lecture, l'heure « 5:00 » et non « 5 h »). Meme scene que H5 (donnees
// synthetiques, profil a +05:30, appareil en UTC). AVANT : les captures
// arabes de H5-SEMAINE-PROFIL. 390 et 1440, clair et sombre.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/date-arabe-source \
//   flutter test test/capture/date_arabe_source_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/admin_planning/planning_page.dart';

import '../features/admin_planning/session_direction.dart';
import 'outil_capture.dart';

final MonHorloge _kolkata = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T12:00:00Z',
  'moi': <String, Object?>{
    'fuseau': 'Asia/Kolkata',
    'decalage_secondes': 19800,
  },
});

/// Rend les seances synthetiques de la semaine du lundi 16/11/2026.
class _PlanningSynthetique implements PortPlanningDirection {
  static final List<SeancePlanning> _toutes = <SeancePlanning>[
    SeancePlanning(
      id: 's-dim',
      classe: 'Classe A1',
      debut: DateTime.utc(2026, 11, 15, 23, 30),
      dureeMinutes: 45,
      statut: StatutSeance.planifiee,
      enseignant: 'Enseignant test',
    ),
    SeancePlanning(
      id: 's-mer',
      classe: 'Classe B2',
      debut: DateTime.utc(2026, 11, 18, 12, 30),
      dureeMinutes: 60,
      statut: StatutSeance.planifiee,
    ),
    SeancePlanning(
      id: 's-avant',
      classe: 'Classe C3',
      debut: DateTime.utc(2026, 11, 13, 12, 30),
      dureeMinutes: 45,
      statut: StatutSeance.planifiee,
      enseignant: 'Enseignant test',
    ),
  ];

  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async =>
      _toutes.where((SeancePlanning s) => s.id != 's-avant').toList();
}

void main() {
  group(
    'Capture : DATE-ARABE-SOURCE, planning en arabe',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);
      tearDown(() => poserMonHorlogePourTest(null));

      final List<(String, double, AppLocale, MonHorloge)> cas =
          <(String, double, AppLocale, MonHorloge)>[
            for (final double l in const <double>[
              390,
              1440,
            ]) ...<(String, double, AppLocale, MonHorloge)>[
              ('planning-arabe-${l.toInt()}-clair', l, AppLocale.ar, _kolkata),
              ('planning-arabe-${l.toInt()}-sombre', l, AppLocale.ar, _kolkata),
            ],
          ];

      for (final (String nom, double l, AppLocale langue, MonHorloge h)
          in cas) {
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
          poserMonHorlogePourTest(h);
          fixerVueCapture(tester, Size(l, l < 600 ? 844 : 900), 1);
          await tester.pumpWidget(
            hoteCapture(
              PlanningPage(semaineInitiale: DateTime.utc(2026, 11, 18, 12)),
              surcharges: <Override>[
                portPlanningDirectionProvider.overrideWithValue(
                  _PlanningSynthetique(),
                ),
                monHorlogeProvider.overrideWith((Ref _) async => h),
                horsLigneProvider.overrideWith(
                  (Ref _) => Stream<bool>.value(false),
                ),
                sessionProvider.overrideWith(SessionPlanning.new),
              ],
              themeMode: nom.endsWith('-sombre')
                  ? ThemeMode.dark
                  : ThemeMode.light,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          await capturerVue(tester, nom);
        });
      }
    },
  );
}
