// BE-SUIVANT (lot BE-1b, 16/11/2026) : captures du dossier dans sa file,
// 360 et 1366, francais et arabe. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/navigation_dossier.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/admin_candidature/suivant_dossier_test.dart';
import '../features/com_messages/support_messages.dart';
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  Future<void> prise(
    WidgetTester tester,
    String nom, {
    required double largeur,
    String ouvert = 'c2',
    bool decision = false,
    AppLocale langue = AppLocale.fr,
  }) async {
    masquerRubanDebug();
    await tester.runAsync(() => LocaleSettings.setLocale(langue));
    await monterFileTest(
      tester,
      portFileTest(),
      ouvert: ouvert,
      largeur: largeur,
      direction: langue == AppLocale.ar ? TextDirection.rtl : null,
      surcharges: <Override>[
        portMessagesMetierProvider.overrideWithValue(
          FauxMessagesMetier(
            conversations: <String, List<ConversationPossible>>{
              cleObjet(TypeObjetLie.candidature, ouvert): <ConversationPossible>[
                ConversationPossible(
                  interlocuteur: const Participant(
                    id: 'cand',
                    nomAffiche: 'Amina Diallo',
                  ),
                  objet: ObjetLie(
                    type: TypeObjetLie.candidature,
                    id: ouvert,
                    libelle: 'Candidature',
                  ),
                  filId: 'f1',
                  attention: const IndicateurAttention(nonLus: 2),
                ),
              ],
            },
          ),
        ),
        capaciteEcrireOuverteTest,
      ],
    );
    tester.view.physicalSize = Size(largeur, largeur < 600 ? 900 : 800);
    await tester.pump(const Duration(milliseconds: 300));
    if (decision) {
      await accepterFileTest(tester);
    }
    // Les images embarquees (drapeau) se decodent hors du temps simule.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await capturerVue(tester, 'BE-SUIVANT/$nom');
  }

  group('BE-SUIVANT : captures', skip: sautSansCapture, () {
    testWidgets('360 francais', (WidgetTester t) async {
      await prise(t, 'suivant_360_fr', largeur: 360);
    });
    testWidgets('360 passage', (WidgetTester t) async {
      await prise(t, 'suivant_360_passage_fr', largeur: 360, decision: true);
      expect(find.byKey(PassageAuSuivant.cleEnCours), findsOneWidget);
    });
    testWidgets('360 fin de file', (WidgetTester t) async {
      await prise(
        t,
        'suivant_360_fin_fr',
        largeur: 360,
        ouvert: 'c3',
        decision: true,
      );
    });
    testWidgets('1366 francais', (WidgetTester t) async {
      await prise(t, 'suivant_1366_fr', largeur: 1366);
    });
    testWidgets('360 arabe', (WidgetTester t) async {
      await prise(t, 'suivant_360_ar', largeur: 360, langue: AppLocale.ar);
    });
    testWidgets('1366 arabe', (WidgetTester t) async {
      await prise(t, 'suivant_1366_ar', largeur: 1366, langue: AppLocale.ar);
    });
  });
}
