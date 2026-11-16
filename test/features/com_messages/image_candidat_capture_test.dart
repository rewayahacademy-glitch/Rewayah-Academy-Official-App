// IMAGE-CANDIDAT : captures R3 (sautees sans CAPTURE_DIR). Le fil du dossier d'un
// candidat, telephone 390 x 844, francais et arabe : le message « [image] » sans
// image (depot refuse) n'est plus ecrit.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/barre_conversation.dart';

import '../../capture/outil_capture.dart';

MessageFil _m(int n, String texte, {bool deSoi = false}) => MessageFil(
  id: 'm$n',
  auteur: deSoi ? 'Vous' : 'Khadija',
  texte: texte,
  horodatage: '10:0$n',
  deSoi: deSoi,
  instant: DateTime.utc(2026, 11, 16, 10, n),
);

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      final String nom = 'dossier-candidat-390-${langue.languageCode}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 1);
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() async {
          LocaleSettings.setLocaleSync(AppLocale.fr);
        });
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                locale: Locale(langue.languageCode),
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                home: Scaffold(
                  body: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const BarreConversation.libre(
                          titre: 'Khadija',
                          ligne: 'Candidate enseignante',
                        ),
                        Expanded(
                          child: FilDiscussion(
                            pleinEcran: true,
                            messages: <MessageFil>[
                              _m(1, 'Bonjour, voici ma question.'),
                              _m(2, '[image]'),
                              _m(
                                3,
                                'Bonjour, nous vous répondons.',
                                deSoi: true,
                              ),
                            ],
                            textes: textesFilCommunication(),
                            onEnvoyer: (String _) async {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capturerVue(tester, 'IMAGE-CANDIDAT/$nom');
      });
    }
  }, skip: sautSansCapture);
}
