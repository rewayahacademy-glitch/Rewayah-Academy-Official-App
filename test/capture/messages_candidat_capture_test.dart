// MESSAGES-CANDIDAT : captures de l'entree des messages dans le portail du
// candidat (le fil, un message non lu) et de l'envoi refuse pour la limite du
// jour, en francais et en arabe, 390 x 844 et 1440 x 900, clair. Donnees de
// test seulement. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/ma_candidature_fil.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_candidature.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/com_messages/support_messages.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const String _candidature = '7c400000-0000-4000-8000-000000000101';

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  Widget Function() page, {
  required bool arabe,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attente,
      direction: arabe ? TextDirection.rtl : null,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) => Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: page(),
            ),
          ),
        ),
      ],
      surcharges: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portMessagesMetierProvider.overrideWithValue(
          FauxMessagesMetier(
            conversations: <String, List<ConversationPossible>>{
              cleObjet(
                TypeObjetLie.candidature,
                _candidature,
              ): <ConversationPossible>[
                ConversationPossible(
                  interlocuteur: const Participant(
                    id: 'administration',
                    nomAffiche: 'Administration',
                    fonction: 'administration',
                  ),
                  nature: NatureInterlocuteur.administration,
                  objet: ObjetLie(
                    type: TypeObjetLie.candidature,
                    id: _candidature,
                    libelle: 'Candidature',
                  ),
                  filId: 'fil-cand',
                  attention: const IndicateurAttention(nonLus: 2),
                ),
              ],
            },
          ),
        ),
        capaciteEcrireOuverteTest,
        lireMaCandidatureIdProvider.overrideWithValue(() async => _candidature),
        baseLocaleEnMemoire(),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : messages du candidat', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final bool arabe in <bool>[false, true]) {
      final String langue = arabe ? 'ar' : 'fr';
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String s = '${taille.width.toInt()}x${taille.height.toInt()}';

        testWidgets('entree du portail, $langue $s', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(
            () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
          );
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
          await _monter(
            tester,
            taille,
            () => const EntreeMessagesCandidature(),
            arabe: arabe,
          );
          debugPrint(
            'PNG ${await capturerVue(tester, 'portail_entree_${langue}_$s')}',
          );
        });
      }

      testWidgets('envoi refuse (limite du jour), $langue 390x844', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(
          () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
        );
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        await _monter(
          tester,
          const Size(390, 844),
          () => SizedBox(
            height: 600,
            child: FilDiscussion(
              messages: const <MessageFil>[],
              textes: textesFilCommunication(),
              onEnvoyer: (String _) async =>
                  throw EnvoiRefuse(t.com.messages.candidature.plafond),
            ),
          ),
          arabe: arabe,
        );
        await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
        await tester.pump();
        await tester.tap(find.byKey(FilDiscussion.envoyerKey));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'plafond_${langue}_390x844')}',
        );
      });
    }
  });
}
