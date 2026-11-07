// MESSAGES-CANDIDAT (07/11/2026, CAND-Q06) : le fil « candidature » cote client.
//   - l'entree du portail du candidat (identifiant de SA candidature lu, puis
//     l'entree des Messages metier existante), ses etats ;
//   - les messages non lus d'une candidature, dans la liste de la direction ;
//   - un envoi refuse pour la limite du jour se dit, sans « Reessayer » ; un
//     echec ordinaire garde « Reessayer » (contre-epreuve) ;
//   - l'adaptateur : SQLSTATE 53400 devient ce refus, tout autre echec reste ;
//   - l'objet « candidature » est lu, nomme sans nom de salle ;
//   - les adresses : `/attente` mene aux messages du candidat.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/ma_candidature_fil.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/admin_candidatures/messages_non_lus.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_candidature.dart';
import 'package:rewayah_academy/features/com_messages/entree_messages_contexte.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../support/harnais.dart';
import '../../support/hote_theme.dart';
import 'support_messages.dart';

const String _candidature = '7c400000-0000-4000-8000-000000000101';

ConversationPossible _avecAdministration({
  String? filId,
  IndicateurAttention attention = IndicateurAttention.aucun,
}) => ConversationPossible(
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
  filId: filId,
  attention: attention,
);

Future<GoRouter> _monterPortail(
  WidgetTester tester, {
  required FauxMessagesMetier port,
  required Future<String?> Function() lireId,
  bool horsLigne = false,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.attente,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.attente,
        builder: (BuildContext _, GoRouterState _) => const Scaffold(
          body: SingleChildScrollView(child: EntreeMessagesCandidature()),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'messages/:filId',
            builder: (BuildContext _, GoRouterState etat) =>
                Scaffold(body: Text('fil-${etat.pathParameters['filId']}')),
          ),
        ],
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        portMessagesMetierProvider.overrideWithValue(port),
        capaciteEcrireOuverteTest,
        lireMaCandidatureIdProvider.overrideWithValue(lireId),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

FauxMessagesMetier _portAvec(List<ConversationPossible> conversations) =>
    FauxMessagesMetier(
      conversations: <String, List<ConversationPossible>>{
        cleObjet(TypeObjetLie.candidature, _candidature): conversations,
      },
    );

void main() {
  group('le portail du candidat', () {
    testWidgets('le fil existe : « Ecrire a l\'Administration », les non lus, '
        'et il ouvre le fil sous /attente', (WidgetTester tester) async {
      final GoRouter routeur = await _monterPortail(
        tester,
        port: _portAvec(<ConversationPossible>[
          _avecAdministration(
            filId: 'fil-cand',
            attention: const IndicateurAttention(nonLus: 2),
          ),
        ]),
        lireId: () async => _candidature,
      );
      expect(find.text(t.com.messages.entree.titreCandidature), findsOneWidget);
      expect(
        find.text(t.com.messages.entree.ecrireAdministration),
        findsOneWidget,
      );
      expect(find.byType(BadgeNonLu), findsOneWidget);
      // Jamais un nom de salle.
      expect(find.textContaining('Salle'), findsNothing);
      await tester.tap(find.text(t.com.messages.entree.ecrireAdministration));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), '${Routes.attenteMessages}/fil-cand');
      expect(find.text('fil-fil-cand'), findsOneWidget);
    });

    testWidgets('aucune candidature : rien n\'est rendu', (
      WidgetTester tester,
    ) async {
      await _monterPortail(
        tester,
        port: _portAvec(const <ConversationPossible>[]),
        lireId: () async => null,
      );
      expect(find.byType(EntreeMessagesContexte), findsNothing);
      expect(find.text(t.com.messages.entree.titreCandidature), findsNothing);
    });

    testWidgets('capacite indisponible : rien n\'est rendu, rien a reessayer', (
      WidgetTester tester,
    ) async {
      await _monterPortail(
        tester,
        port: _portAvec(const <ConversationPossible>[]),
        lireId: () async =>
            throw const CapaciteIndisponible('MESSAGES-CANDIDAT'),
      );
      expect(find.byType(VueEtatCommunication), findsNothing);
      expect(find.byType(EntreeMessagesContexte), findsNothing);
    });

    testWidgets('lecture en echec : « Reessayer » relit l\'identifiant', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await _monterPortail(
        tester,
        port: _portAvec(<ConversationPossible>[_avecAdministration()]),
        lireId: () async {
          lectures++;
          if (lectures == 1) throw StateError('panne');
          return _candidature;
        },
      );
      expect(find.byType(VueEtatCommunication), findsOneWidget);
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(lectures, 2);
      expect(
        find.text(t.com.messages.entree.ecrireAdministration),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : l\'etat hors ligne, pas une erreur', (
      WidgetTester tester,
    ) async {
      await _monterPortail(
        tester,
        port: _portAvec(const <ConversationPossible>[]),
        lireId: () async => throw StateError('hors ligne'),
        horsLigne: true,
      );
      final VueEtatCommunication vue = tester.widget<VueEtatCommunication>(
        find.byType(VueEtatCommunication),
      );
      expect(vue.etat, EtatCommunication.horsLigne);
    });
  });

  group('la liste de la direction', () {
    ResumeFil resume(String id, TypeObjetLie type, int nonLus) => ResumeFil(
      id: 'fil-$id',
      objet: ObjetLie(type: type, id: id, libelle: 'objet'),
      interlocuteurs: const <Participant>[],
      attention: IndicateurAttention(nonLus: nonLus),
    );

    Future<void> monter(
      WidgetTester tester,
      PortMessagesMetier port,
      String id,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            portMessagesMetierProvider.overrideWithValue(port),
          ],
          child: hoteTheme(MarqueMessagesNonLus(candidatureId: id)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('une candidature qui a des messages non lus porte la marque', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        FauxMessagesMetier(
          resumesEnPlus: <ResumeFil>[
            resume(_candidature, TypeObjetLie.candidature, 3),
          ],
        ),
        _candidature,
      );
      expect(find.byType(BadgeNonLu), findsOneWidget);
    });

    testWidgets(
      'sans non lu, ou pour un autre objet, ou sans messagerie : rien',
      (WidgetTester tester) async {
        await monter(
          tester,
          FauxMessagesMetier(
            resumesEnPlus: <ResumeFil>[
              resume(_candidature, TypeObjetLie.classe, 5),
              resume('autre', TypeObjetLie.candidature, 4),
            ],
          ),
          _candidature,
        );
        expect(find.byType(BadgeNonLu), findsNothing);
        await monter(
          tester,
          FauxMessagesMetier(
            erreurListe: const CapaciteIndisponible('COM-BR-01'),
          ),
          _candidature,
        );
        expect(find.byType(BadgeNonLu), findsNothing);
      },
    );
  });

  group('l\'envoi refuse pour la limite du jour', () {
    Future<void> monter(
      WidgetTester tester,
      Future<void> Function(String) envoi,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          FilDiscussion(
            messages: const <MessageFil>[],
            textes: textesFilCommunication(),
            onEnvoyer: envoi,
          ),
          defilant: false,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
    }

    testWidgets('la cause est dite, le texte garde, sans « Reessayer »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        (String _) async =>
            throw EnvoiRefuse(t.com.messages.candidature.plafond),
      );
      expect(find.text(t.com.messages.candidature.plafond), findsOneWidget);
      expect(
        find.text(t.com.socle.composants.composer.reessayer),
        findsNothing,
      );
      expect(
        find.text(t.com.socle.composants.composer.nonConfirme),
        findsNothing,
      );
    });

    testWidgets('contre-epreuve : un echec ordinaire garde « Reessayer »', (
      WidgetTester tester,
    ) async {
      await monter(tester, (String _) async => throw StateError('panne'));
      expect(
        find.text(t.com.socle.composants.composer.nonConfirme),
        findsOneWidget,
      );
      expect(
        find.text(t.com.socle.composants.composer.reessayer),
        findsOneWidget,
      );
      expect(find.text(t.com.messages.candidature.plafond), findsNothing);
    });
  });

  group('l\'adaptateur', () {
    MessagesMetierSupabase adaptateur(AppelRpc appel) => MessagesMetierSupabase(
      appel,
      libelles: const LibellesCommunicationSlang(),
    );
    const String fil = '7c400000-0000-4000-8000-0000000000f9';

    test('SQLSTATE 53400 devient le refus de la limite du jour', () async {
      final MessagesMetierSupabase p = adaptateur(
        (String f, Map<String, dynamic> a) async =>
            throw const PostgrestException(
              message: 'COM-CAND plafond',
              code: '53400',
            ),
      );
      await expectLater(
        p.envoyer(fil, 'Bonjour', 'cle-1'),
        throwsA(
          isA<EnvoiRefuse>().having(
            (EnvoiRefuse e) => e.phrase,
            'phrase',
            t.com.messages.candidature.plafond,
          ),
        ),
      );
    });

    test('tout autre refus reste un echec ordinaire', () async {
      final MessagesMetierSupabase p = adaptateur(
        (String f, Map<String, dynamic> a) async =>
            throw const PostgrestException(message: 'refus', code: '42501'),
      );
      await expectLater(
        p.envoyer(fil, 'Bonjour', 'cle-1'),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('l\'objet « candidature » est lu, nomme sans nom de salle', () {
      final ObjetLie o = objetLieJson(<String, dynamic>{
        'type': 'candidature',
        'id': _candidature,
      }, const LibellesCommunicationSlang());
      expect(o.type, TypeObjetLie.candidature);
      expect(o.libelle, t.com.messages.types.candidature);
      expect(o.libelle, isNot(contains('Salle')));
      expect(
        estFilMetier(
          ResumeFil(id: 'f', objet: o, interlocuteurs: const <Participant>[]),
        ),
        isTrue,
      );
    });

    test('la lecture de l\'identifiant : uuid, ou rien', () async {
      expect(
        await lireMaCandidatureIdSupabase(
          (String f, Map<String, dynamic> a) async => _candidature,
        )(),
        _candidature,
      );
      expect(
        await lireMaCandidatureIdSupabase(
          (String f, Map<String, dynamic> a) async => null,
        )(),
        isNull,
      );
      await expectLater(
        lireMaCandidatureIdSupabase(
          (String f, Map<String, dynamic> a) async =>
              throw const PostgrestException(message: 'x', code: '42501'),
        )(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  test('sous /attente, la liste des messages est celle du candidat', () {
    expect(cheminMessagesDepuis(Routes.attente), Routes.attenteMessages);
    expect(
      cheminMessagesDepuis(Routes.attenteCandidature),
      Routes.attenteMessages,
    );
    expect(
      cheminMessagesDepuis('/enseignant/classes'),
      Routes.enseignantMessages,
    );
  });
}
