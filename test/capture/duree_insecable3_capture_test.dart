// DUREE-INSECABLE-3 : captures de la carte de seance `CarteSession`
// (Teaching Core) que DUREE-INSECABLE-2 n'avait pas : 390 et 1440 px, en
// clair et en sombre, LTR et RTL, texte x1 et x2 ; plus 320 px texte x2 en
// sombre. La duree prevue (« 45 min ») et le compte a rebours tiennent sur
// une ligne et gardent leur ordre.
//
// Defaut connu, hors de cette etape : en RTL, la ponctuation d'un libelle
// francais s'affiche inversee (reserve 4 de DUREE-INSECABLE-2).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import 'outil_capture.dart';

typedef _Cas = ({
  double largeur,
  double hauteur,
  double texte,
  Brightness luminosite,
});

const List<_Cas> _cas = <_Cas>[
  (largeur: 390, hauteur: 520, texte: 1, luminosite: Brightness.light),
  (largeur: 390, hauteur: 520, texte: 2, luminosite: Brightness.light),
  (largeur: 390, hauteur: 520, texte: 1, luminosite: Brightness.dark),
  (largeur: 390, hauteur: 520, texte: 2, luminosite: Brightness.dark),
  (largeur: 1440, hauteur: 420, texte: 1, luminosite: Brightness.light),
  (largeur: 1440, hauteur: 420, texte: 2, luminosite: Brightness.light),
  (largeur: 1440, hauteur: 420, texte: 1, luminosite: Brightness.dark),
  (largeur: 1440, hauteur: 420, texte: 2, luminosite: Brightness.dark),
  (largeur: 320, hauteur: 520, texte: 2, luminosite: Brightness.dark),
];

void main() {
  group('Capture : DUREE-INSECABLE-3, CarteSession', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Cas cas in _cas) {
      for (final TextDirection sens in TextDirection.values) {
        final String nom =
            'carte_session_${cas.largeur.toInt()}x${cas.texte.toInt()}_'
            '${cas.luminosite.name}_${sens.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, Size(cas.largeur, cas.hauteur), 1);
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: RepaintBoundary(
                  key: cadreCapture,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      cas.luminosite,
                    ),
                    locale: AppLocale.fr.flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    builder: (BuildContext c, Widget? app) => MediaQuery(
                      data: MediaQuery.of(c)
                          .copyWith(textScaler: TextScaler.linear(cas.texte)),
                      child: Directionality(textDirection: sens, child: app!),
                    ),
                    home: Scaffold(
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: CarteSession(
                          espace: DonneesAccessibiliteDemo.espaceAccueil(
                            MomentDemoAccessibilite.avant,
                          ),
                          onRejoindre: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await stabiliser(tester);
          expect(find.byType(CarteSession), findsOneWidget);
          expect(tester.takeException(), isNull);
          await capturer(tester, nom);
        });
      }
    }
  });
}
