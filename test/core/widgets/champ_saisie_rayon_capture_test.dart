// MESSAGERIE-COULEURS : captures R3 (sautees sans CAPTURE_DIR). Le champ
// d'ecriture a 1 et 4 lignes, ordinateur sombre 1440 x 900 et telephone clair
// 390 x 844, clair et sombre dans les deux tailles, francais et arabe.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../capture/outil_capture.dart';

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (Size taille, Brightness lum) in <(Size, Brightness)>[
      (const Size(1440, 900), Brightness.dark),
      (const Size(1440, 900), Brightness.light),
      (const Size(390, 844), Brightness.light),
      (const Size(390, 844), Brightness.dark),
    ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final int lignes in <int>[1, 4]) {
          final String nom =
              'champ-${taille.width.toInt()}-${langue.languageCode}-'
              '${lum == Brightness.dark ? 'sombre' : 'clair'}-$lignes-lignes';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            await tester.pumpWidget(
              ProviderScope(
                child: TranslationProvider(
                  child: MaterialApp(
                    locale: Locale(langue.languageCode),
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
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
                          messages: const <MessageFil>[],
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
            final bool ar = langue == AppLocale.ar;
            await tester.enterText(
              find.byKey(FilDiscussion.champKey),
              List<String>.generate(
                lignes,
                (int i) => ar
                    ? 'السطر ${i + 1} من الرسالة'
                    : 'Ligne ${i + 1} du message',
              ).join('\n'),
            );
            await tester.pumpAndSettle();
            await capturerVue(tester, 'MESSAGERIE-COULEURS-CHAMP/$nom');
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
