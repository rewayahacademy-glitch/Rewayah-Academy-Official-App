// IMAGE-CANDIDAT : captures R3 (sautees sans CAPTURE_DIR). Le lien d'ouverture
// sous le texte d'un message de l'equipe, dans MA bulle (violet de marque) et
// dans une bulle recue, telephone 390 x 844, francais et arabe, clair et sombre.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';

import '../../capture/outil_capture.dart';

MessageFil _m(int n, {required bool deSoi}) => MessageFil(
  id: 'm$n',
  auteur: deSoi ? 'Vous' : 'Amina',
  texte: 'https://rewayahacademy.com/ar/',
  horodatage: '10:0$n',
  deSoi: deSoi,
  instant: DateTime.utc(2026, 11, 16, 10, n),
  complement: LienFleche(
    libelle: t.com.messages.liens.ouvrir(site: 'rewayahacademy.com'),
    onPress: () {},
    alignerEnDebut: true,
  ),
);

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final String nom =
            'lien-bulle-390-${langue.languageCode}-'
            '${lum == Brightness.dark ? 'sombre' : 'clair'}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(390, 844), 1);
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: MaterialApp(
                  locale: Locale(langue.languageCode),
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  darkTheme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.dark,
                  ),
                  themeMode: lum == Brightness.dark
                      ? ThemeMode.dark
                      : ThemeMode.light,
                  home: Scaffold(
                    body: SafeArea(
                      child: FilDiscussion(
                        pleinEcran: true,
                        messages: <MessageFil>[
                          _m(1, deSoi: false),
                          _m(2, deSoi: true),
                        ],
                        textes: textesFilCommunication(),
                        onEnvoyer: (String _) async {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await capturerVue(tester, 'IMAGE-CANDIDAT-LIEN/$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
