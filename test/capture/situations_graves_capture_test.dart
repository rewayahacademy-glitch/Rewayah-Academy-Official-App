// Captures de recette SITUATIONS-GRAVES (directeur, 11/11/2026) : captures de
// TEST (salle de demonstration, pas l'application reelle). La feuille « micro
// bloque » avec la vraie cause, et les annonces de tete (micro pris,
// enseignant parti, pause) posees sur la salle de l'eleve. 390 et 1440, clair
// et sombre, plus l'arabe. Saute sans CAPTURE_DIR.
// Nommage : situations_<cas>_<largeur>_<mode>[_ar].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart' show TonEtat;
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/annonce_geste.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 3, '390'),
  (Size(1440, 900), 1, '1440'),
];

ActionsSeance _actions() => ActionsSeance(
  onRetour: () {},
  onQuitter: () {},
  onMicro: () {},
  onCamera: () {},
  onContinuerSansMicro: () {},
);

Widget _salle(VueSeance vue, {AnnonceGeste? annonce}) => CoucheAnnonceGeste(
  annonce: annonce,
  child: SalleSeance(vue: vue, actions: _actions()),
);

Map<String, AnnonceGeste> _annonces() => <String, AnnonceGeste>{
  'micro_pris': annonceMicroBloque(CauseMicroBloque.occupe),
  'enseignant_parti': AnnonceGeste(
    titre: t.salle.situations.enseignantPartiTitre,
    message: t.salle.situations.enseignantParti,
  ),
  'pause': annoncePause(),
};

Future<void> _feuille(
  WidgetTester tester,
  String nom,
  Size cadre,
  double densite,
  ThemeMode mode,
) async {
  fixerVueCapture(tester, cadre, densite);
  await tester.pumpWidget(
    hoteCapture(
      _salle(
        DonneesSeanceDemo.vue(
          RoleSeance.eleve,
          EtatDemoSalle.microBloque,
        ).copyWith(causeMicro: CauseMicroBloque.refuse),
      ),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  await tester.tap(find.byKey(const ValueKey<String>('bouton-micro')));
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : SITUATIONS-GRAVES', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur) in _cadres) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suffixe = '${largeur}_${mode.name}';
        testWidgets('situations_micro_refuse_feuille_$suffixe', (
          WidgetTester tester,
        ) async {
          await _feuille(
            tester,
            'situations_micro_refuse_feuille_$suffixe',
            cadre,
            densite,
            mode,
          );
        });
        for (final String cas in _annonces().keys) {
          testWidgets('situations_${cas}_$suffixe', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, cadre, densite);
            await tester.pumpWidget(
              hoteCapture(
                _salle(
                  DonneesSeanceDemo.vue(RoleSeance.eleve, EtatDemoSalle.repos),
                  annonce: _annonces()[cas],
                ),
                themeMode: mode,
              ),
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'situations_${cas}_$suffixe')}',
            );
          });
        }
      }
    }

    testWidgets('situations_micro_refuse_feuille_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _feuille(
        tester,
        'situations_micro_refuse_feuille_390_light_ar',
        const Size(390, 844),
        3,
        ThemeMode.light,
      );
    });

    testWidgets('situations_enseignant_parti_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(
          _salle(
            DonneesSeanceDemo.vue(RoleSeance.eleve, EtatDemoSalle.repos),
            annonce: AnnonceGeste(
              titre: t.salle.situations.enseignantPartiTitre,
              message: t.salle.situations.enseignantParti,
              ton: TonEtat.accent,
            ),
          ),
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'situations_enseignant_parti_390_light_ar')}',
      );
    });
  });
}
