// Captures du lot POINT-DE-SEANCE (R3) : la page du point de fin de seance
// (enseignant) et l'historique des seances (tuteur), en francais et en arabe,
// a 390 et 1440, en clair et en sombre.
//
//   CAPTURE_DIR=docs/current/captures/E2E/point-de-seance \
//     flutter test --no-pub test/capture/point_de_seance_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/point_seance/port_point_seance.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/historique/support_historique.dart';
import '../features/point_seance/faux_point_seance.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart';
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

List<Override> _avec(FauxPointSeance faux) => <Override>[
  portPointSeanceProvider.overrideWithValue(faux),
  horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(false)),
];

void main() {
  group('Capture POINT-DE-SEANCE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      final TextDirection sens = langue == AppLocale.ar
          ? TextDirection.rtl
          : TextDirection.ltr;
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nomTheme = theme == ThemeMode.light ? 'clair' : 'sombre';
        for (final double largeur in <double>[390, 1440]) {
          final String fin = '${langue.name}-${largeur.toInt()}-$nomTheme';
          testWidgets('enseignant point $fin', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            await monterRouteur(
              tester,
              Routes.pointSeancePour('s1'),
              source: FausseSourceSession(sessionActive(AppRole.teacher)),
              taille: Size(largeur, largeur < 600 ? 1500 : 1100),
              themeMode: theme,
              direction: sens,
              surcharges: _avec(FauxPointSeance(point: pointAFaireBrut())),
            );
            await tester.pump(const Duration(milliseconds: 600));
            // Un toucher pour l'eleve tire, un pour « A renforcer ».
            await tester.tap(
              find.descendant(
                of: find.byKey(const ValueKey<String>('point-seance-choix-e1')),
                matching: find.text(t.pointSeance.acquis),
              ),
            );
            await tester.tap(
              find.descendant(
                of: find.byKey(const ValueKey<String>('point-seance-choix-e2')),
                matching: find.text(t.pointSeance.aRenforcer),
              ),
            );
            await tester.pump(const Duration(milliseconds: 600));
            debugPrint(
              'PNG ${await capturerVue(tester, 'enseignant-point-$fin')}',
            );
          });
          testWidgets('tuteur historique $fin', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            tester.view.physicalSize = Size(largeur, 1700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await monterHistorique(
              tester,
              depart: Routes.tuteurSuivi,
              taille: null,
              mode: theme,
              autres: _avec(FauxPointSeance(historiqueRendu: historiqueBrut())),
            );
            await tester.pump(const Duration(milliseconds: 600));
            debugPrint(
              'PNG ${await capturerVue(tester, 'tuteur-historique-$fin')}',
            );
          });
        }
      }
    }
    testWidgets('enseignant point envoye', (WidgetTester tester) async {
      await monterRouteur(
        tester,
        Routes.pointSeancePour('s1'),
        source: FausseSourceSession(sessionActive(AppRole.teacher)),
        taille: const Size(390, 1500),
        surcharges: _avec(
          FauxPointSeance(point: pointAFaireBrut(envoye: true)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      debugPrint(
        'PNG ${await capturerVue(tester, 'enseignant-point-envoye-fr-390-clair')}',
      );
    });
  });
}
