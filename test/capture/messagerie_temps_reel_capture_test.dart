// MESSAGERIE-TEMPS-REEL (14/11/2026) : captures R3 du lot. Donnees de test
// seulement. Jamais sans `CAPTURE_DIR`.
//   - le fil ouvert, un message arrive en direct (fr, ar ; 390 et 1440) ;
//   - l'avis « Vous avez recu un nouveau message » (fr, en, ar ; 390) ;
//   - l'acces aux Messages de la direction avec son nombre (fr, ar ; 390, 1440) ;
//   - l'entree du candidat quand le temps reel est tombe (K-59 ; fr, ar ; 390).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/communications/ma_candidature_fil.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_candidature.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../features/com_messages/support_messages.dart';
import '../support/demo/communications/demo_communications_page.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const String _dossier = 'messagerie-temps-reel';
const String _candidature = '7c500000-0000-4000-8000-000000000101';

Future<void> _langue(WidgetTester tester, AppLocale langue) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

/// Un port de demonstration qui recoit un message « d'ailleurs ».
class _PortVivant implements PortMessagesMetier {
  _PortVivant(this.demo);

  final PortMessagesMetier demo;
  final List<MessageCommunication> arrives = <MessageCommunication>[];

  @override
  Future<FilMetier?> fil(String filId) async {
    final FilMetier? f = await demo.fil(filId);
    if (f == null || arrives.isEmpty) return f;
    return FilMetier(
      id: f.id,
      contexte: f.contexte,
      participants: f.participants,
      messages: <MessageCommunication>[...f.messages, ...arrives],
      attention: f.attention,
      capacites: f.capacites,
    );
  }

  @override
  Future<List<ResumeFil>> fils() => demo.fils();

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) =>
      demo.filPourObjet(type, objetId);

  @override
  Future<FilMetier?> ouvrirConversation(ConversationPossible c) =>
      demo.ouvrirConversation(c);

  @override
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  ) => demo.conversationsPourObjet(type, objetId);

  @override
  Future<void> marquerLu(String filId) => demo.marquerLu(filId);

  @override
  Future<void> envoyer(String filId, String texte, String cle) =>
      demo.envoyer(filId, texte, cle);
}

void main() {
  group('Capture : messagerie en temps reel', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String s = '${taille.width.toInt()}x${taille.height.toInt()}';
        testWidgets('fil ouvert, message arrive en direct, ${langue.name} $s', (
          WidgetTester tester,
        ) async {
          final _PortVivant port = _PortVivant(
            portDemo(RoleDemoCommunications.enseignant),
          );
          await monterMessages(
            tester,
            port: port,
            depart: cheminFilTest('fil-adam'),
            taille: taille,
            langue: langue,
          );
          final FilMetier fil = (await port.demo.fil('fil-adam'))!;
          port.arrives.add(
            MessageCommunication(
              id: 'arrive-1',
              auteur: fil.participants.firstWhere((Participant p) => !p.estSoi),
              texte: langue == AppLocale.ar
                  ? 'رسالة وصلت الآن، دون إعادة فتح الصفحة.'
                  : 'Message arrive a l\'instant, sans rouvrir la page.',
              envoyeLe: maintenantTest,
            ),
          );
          ProviderScope.containerOf(tester.element(find.byType(FilDiscussion)))
              .read(etatVeilleMessagesProvider.notifier)
              .relire();
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/fil_direct_${langue.name}_$s')}',
          );
        });

        testWidgets('direction : acces aux Messages, ${langue.name} $s', (
          WidgetTester tester,
        ) async {
          await _langue(tester, langue);
          tester.view.physicalSize = taille;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hote(
              Directionality(
                textDirection: langue == AppLocale.ar
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: AdminShell(
                  domaines: domainesAdmin(voitDirection: true),
                  domaineActif: AdminDomaine.accueil,
                  onAller: (String _) {},
                  onCompte: () {},
                  messages: ClocheNotifications(
                    icone: AppIcons.discussion,
                    nonLues: 2,
                    onPress: () {},
                    libelleSemantique: t.com.messages.direct.iconeNonLus(
                      nombre: 2,
                    ),
                  ),
                  child: PageShell(
                    titre: t.nav.admin.accueil,
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/direction_acces_messages_${langue.name}_$s')}',
          );
        });
      }

      testWidgets('candidat : temps reel tombe (K-59), ${langue.name}', (
        WidgetTester tester,
      ) async {
        await _langue(tester, langue);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteRoutant(
            depart: Routes.attente,
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
            routes: <RouteBase>[
              GoRoute(
                path: Routes.attente,
                builder: (BuildContext _, GoRouterState _) => const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: EntreeMessagesCandidature(),
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
                        attention: const IndicateurAttention(nonLus: 1),
                      ),
                    ],
                  },
                ),
              ),
              capaciteEcrireOuverteTest,
              lireMaCandidatureIdProvider.overrideWithValue(
                () async => _candidature,
              ),
              baseLocaleEnMemoire(),
            ],
          ),
        );
        await stabiliser(tester);
        ProviderScope.containerOf(
          tester.element(find.byType(EntreeMessagesCandidature)),
        ).read(etatVeilleMessagesProvider.notifier).horsDirect();
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, '$_dossier/candidat_hors_direct_${langue.name}_390x844')}',
        );
      });
    }

    for (final AppLocale langue in AppLocale.values) {
      testWidgets('avis « nouveau message », ${langue.name} 390x844', (
        WidgetTester tester,
      ) async {
        await _langue(tester, langue);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hote(
            Directionality(
              textDirection: langue == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: const Scaffold(
                body: Column(
                  children: <Widget>[
                    BandeauAvisEphemere(),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        );
        ProviderScope.containerOf(
              tester.element(find.byType(BandeauAvisEphemere)),
            )
            .read(avisEphemereProvider.notifier)
            .dire(t.com.messages.direct.nouveau);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        debugPrint(
          'PNG ${await capturerVue(tester, '$_dossier/avis_nouveau_message_${langue.name}_390x844')}',
        );
        ProviderScope.containerOf(
          tester.element(find.byType(BandeauAvisEphemere)),
        ).read(avisEphemereProvider.notifier).effacer();
      });
    }
  });
}
