// Captures R3 d'ANTI-CRASH : un element dont l'affichage echoue, au milieu
// d'un ecran par ailleurs normal, donne la carte « Cet element n'a pas pu
// s'afficher » avec « Reessayer » (et non un rectangle gris). Donnees
// synthetiques. 390 et 1440, clair, sombre, arabe.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/ANTI-CRASH \
//   flutter test test/capture/anti_crash_capture_test.dart

import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/observabilite/garde_erreurs.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import 'outil_capture.dart';

class _Explosif extends StatelessWidget {
  const _Explosif();

  @override
  Widget build(BuildContext context) =>
      throw StateError('donnee inattendue (capture)');
}

void main() {
  group('Capture : ANTI-CRASH, carte d erreur', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    final List<(String, double, ThemeMode, AppLocale)> cas =
        <(String, double, ThemeMode, AppLocale)>[
          for (final double l in const <double>[
            390,
            1440,
          ]) ...<(String, double, ThemeMode, AppLocale)>[
            ('carte-${l.toInt()}-clair', l, ThemeMode.light, AppLocale.fr),
            ('carte-${l.toInt()}-sombre', l, ThemeMode.dark, AppLocale.fr),
            ('carte-${l.toInt()}-arabe', l, ThemeMode.light, AppLocale.ar),
          ],
        ];

    for (final (String nom, double l, ThemeMode mode, AppLocale langue)
        in cas) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        final ErrorWidgetBuilder builder = ErrorWidget.builder;
        final FlutterExceptionHandler? onError = FlutterError.onError;
        reinitialiserGardeErreurs();
        installerGardeErreurs();
        try {
          fixerVueCapture(tester, Size(l, l < 600 ? 844 : 900), 1);
          await tester.pumpWidget(
            hoteCapture(
              const PageShell(
                titre: 'Planning',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Les seances de la semaine.'),
                    _Explosif(),
                    Text('La suite de l ecran reste visible.'),
                  ],
                ),
              ),
              themeMode: mode,
            ),
          );
          await stabiliser(tester);
          tester.takeException();
          expect(find.byKey(CarteErreurElement.carteKey), findsOneWidget);
          await capturerVue(tester, nom);
        } finally {
          ErrorWidget.builder = builder;
          FlutterError.onError = onError;
          reinitialiserGardeErreurs();
        }
      });
    }
  });
}
