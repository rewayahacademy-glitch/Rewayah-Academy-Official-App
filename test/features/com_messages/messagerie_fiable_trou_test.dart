// PE-D1 MESSAGERIE-FIABLE, relecture adverse 2 de la PR 657 (20/11/2026) :
// - jamais de fil troue : plus de 50 messages arrives entre deux relectures
//   (la nouvelle page ne recoupe plus l'ecran) sont comblés par les pages du
//   trou, ou l'ecran repart des plus recents avec la rangee du haut ;
// - une session finie ne se dit pas « conversation fermee » ;
// - la fin du fil (page vide, sans plus anciens) fait disparaitre la rangee
//   (les messages sont en ajout seul : declencheur com_messages_ajout_seul) ;
// - « Fichiers partages » garde les fichiers des pages chargees quand un
//   message arrive, et montre le nouveau.
// Donnees fictives seulement.

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/memoire_pages_fil.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../support/demo/communications/demo_communications_page.dart';
import '../../support/echec_bulle.dart';
import '../../support/hote_theme.dart';
import 'support_messages.dart';
import 'support_serveur_fiable.dart';

MessageCommunication _m(int i) => MessageCommunication(
  id: 'm$i',
  auteur: const Participant(id: 'p', nomAffiche: 'P'),
  texte: 't$i',
  envoyeLe: DateTime.utc(2026, 11, 20).add(Duration(minutes: i)),
);

FilMetier _fil(int premier, int dernier, {required bool plus}) => FilMetier(
  id: 'f',
  contexte: <ElementContexteFil>[
    ElementContexteFil(
      objet: ObjetLie(type: TypeObjetLie.classe, id: 'c', libelle: 'C'),
    ),
  ],
  participants: const <Participant>[],
  messages: <MessageCommunication>[
    for (int i = premier; i <= dernier; i++) _m(i),
  ],
  plusAnciens: plus,
);

/// Un serveur de [total] messages m1..m[total], lu par pages de 50.
LirePageAnterieure _pages(int Function() total, {List<String>? appels}) =>
    (String avantId) async {
      appels?.add(avantId);
      final int rang = int.parse(avantId.substring(1));
      final int debut = rang - 50 < 1 ? 1 : rang - 50;
      return PageMessagesFil(
        messages: <MessageCommunication>[
          for (int i = debut; i < rang && i <= total(); i++) _m(i),
        ],
        plusAnciens: debut > 1,
      );
    };

List<String> _ids(MemoirePagesFil m) => <String>[
  for (final MessageCommunication x in m.messages) x.id,
];

List<String> _de(int a, int b) => <String>[for (int i = a; i <= b; i++) 'm$i'];

List<String> _idsAffiches(WidgetTester tester) => <String>[
  for (final MessageFil m
      in tester.widget<FilDiscussion>(find.byType(FilDiscussion)).messages)
    m.id,
];

void _arrive(ServeurFiable s, String id, {List<PieceJointe>? pieces}) {
  s.messages.add(
    MessageCommunication(
      id: id,
      auteur: s.autre,
      texte: 'Texte $id',
      envoyeLe: maintenantTest.add(Duration(seconds: s.messages.length)),
      piecesJointes: pieces ?? const <PieceJointe>[],
    ),
  );
}

EtatVeilleMessagesControleur _veille(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FilDiscussion)))
        .read(etatVeilleMessagesProvider.notifier);

void main() {
  group('trou entre deux relectures (memoire)', () {
    test(
      'fil de 30, puis 60 arrivees : le trou est comble, rien ne manque',
      () async {
        int total = 30;
        final MemoirePagesFil m = MemoirePagesFil(lire: _pages(() => total));
        m.recevoir(_fil(1, 30, plus: false));
        total = 90;
        m.recevoir(_fil(41, 90, plus: true));
        // Pendant le comblement, l'ecran garde ce qu'il montrait : aucun trou.
        expect(_ids(m), _de(1, 30));
        await pumpEventQueue();
        expect(_ids(m), _de(1, 90));
        expect(m.plusAnciens, isFalse);
        expect(m.recalages, 0);
        m.dispose();
      },
    );

    test(
      'une page remontee, puis 60 arrivees : le trou du milieu est comble',
      () async {
        int total = 120;
        final MemoirePagesFil m = MemoirePagesFil(lire: _pages(() => total));
        m.recevoir(_fil(71, 120, plus: true));
        await m.chargerAnciens();
        expect(_ids(m), _de(21, 120));
        total = 180;
        m.recevoir(_fil(131, 180, plus: true));
        await pumpEventQueue();
        expect(_ids(m), _de(21, 180));
        expect(m.plusAnciens, isTrue, reason: 'm1..m20 restent a charger');
        expect(m.recalages, 0);
        m.dispose();
      },
    );

    test('trou plus grand que quatre pages : on repart des plus recents, la '
        'rangee du haut ramene la suite, sans trou', () async {
      int total = 50;
      final List<String> appels = <String>[];
      final MemoirePagesFil m = MemoirePagesFil(
        lire: _pages(() => total, appels: appels),
      );
      m.recevoir(_fil(1, 50, plus: false));
      total = 500;
      m.recevoir(_fil(451, 500, plus: true));
      await pumpEventQueue();
      expect(appels, hasLength(MemoirePagesFil.pagesComblement));
      expect(_ids(m), _de(251, 500), reason: 'contigu, sans trou');
      expect(m.plusAnciens, isTrue);
      expect(m.recalages, 1);
      // La suite se charge en remontant, jusqu'au debut.
      while (m.plusAnciens) {
        await m.chargerAnciens();
      }
      expect(_ids(m), _de(1, 500));
      m.dispose();
    });

    test('lecture du trou en echec : on repart des plus recents', () async {
      final MemoirePagesFil m = MemoirePagesFil(
        lire: (String _) async => throw const EnvoiCoupe('coupe'),
      );
      m.recevoir(_fil(1, 30, plus: false));
      m.recevoir(_fil(41, 90, plus: true));
      await pumpEventQueue();
      expect(_ids(m), _de(41, 90));
      expect(m.plusAnciens, isTrue);
      expect(m.recalages, 1);
      m.dispose();
    });

    test(
      'des arrivees pendant le comblement s\'ajoutent apres, sans trou',
      () async {
        int total = 30;
        final MemoirePagesFil m = MemoirePagesFil(lire: _pages(() => total));
        m.recevoir(_fil(1, 30, plus: false));
        total = 90;
        m.recevoir(_fil(41, 90, plus: true));
        total = 95;
        m.recevoir(_fil(46, 95, plus: true));
        await pumpEventQueue();
        expect(_ids(m), _de(1, 95));
        m.dispose();
      },
    );

    test('fin du fil : une page vide sans plus anciens retire la rangee '
        '(non-regression, messages en ajout seul)', () async {
      final MemoirePagesFil m = MemoirePagesFil(lire: _pages(() => 60));
      m.recevoir(_fil(11, 60, plus: true));
      await m.chargerAnciens();
      expect(_ids(m), _de(1, 60));
      expect(m.plusAnciens, isFalse);
      m.dispose();
    });
  });

  group('trou entre deux relectures (ecran)', () {
    testWidgets('telephone : fil de 30, 60 arrivees d\'un coup : jamais de '
        'trou a l\'ecran, les 90 dans l\'ordre', (WidgetTester tester) async {
      final ServeurFiable s = ServeurFiable(
        portDemo(RoleDemoCommunications.enseignant),
      );
      await s.preparer(anciens: 30);
      await monterFilPleinEcran(tester, port: s);
      final List<String> avant = _idsAffiches(tester);
      for (int i = 0; i < 60; i++) {
        _arrive(s, 'rafale-$i');
      }
      _veille(tester).relire();
      await tester.pump();
      final List<String> pendant = _idsAffiches(tester);
      final List<String> tous = <String>[for (final m in s.messages) m.id];
      expect(
        listEquals(pendant, avant) || listEquals(pendant, tous),
        isTrue,
        reason: 'jamais un fil troue, meme pendant le comblement : $pendant',
      );
      await tester.pumpAndSettle();
      expect(_idsAffiches(tester), <String>[for (final m in s.messages) m.id]);
      expect(find.byKey(FilDiscussion.clePlusAnciens), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone : 300 arrivees d\'un coup : la vue se cale sur les '
        'derniers messages, la rangee du haut est la et ramene tout', (
      WidgetTester tester,
    ) async {
      final ServeurFiable s = ServeurFiable(
        portDemo(RoleDemoCommunications.enseignant),
      );
      await s.preparer(anciens: 30);
      await monterFilPleinEcran(tester, port: s);
      // La personne lit plus haut dans le fil.
      final ScrollableState liste = tester.state<ScrollableState>(
        listeDesMessages(),
      );
      liste.position.jumpTo(liste.position.maxScrollExtent);
      await tester.pumpAndSettle();
      for (int i = 0; i < 300; i++) {
        _arrive(s, 'rafale-$i');
      }
      _veille(tester).relire();
      await tester.pump();
      await tester.pumpAndSettle();
      final List<String> vus = _idsAffiches(tester);
      final List<String> serveur = <String>[for (final m in s.messages) m.id];
      // Contigu jusqu'au dernier, sans trou.
      expect(
        vus,
        serveur.sublist(serveur.length - vus.length),
        reason:
            'n=${vus.length} premier=${vus.first} dernier=${vus.last} pages=${s.pagesLues}',
      );
      expect(vus.length, lessThan(serveur.length));
      expect(find.text('Texte rafale-299'), findsOneWidget);
      expect(
        tester.state<ScrollableState>(listeDesMessages()).position.pixels,
        0,
        reason: 'vue calee sur les derniers messages',
      );
      // On remonte : tout revient, dans l'ordre.
      for (
        int i = 0;
        i < 12 && _idsAffiches(tester).length < serveur.length;
        i++
      ) {
        final ScrollPosition q = tester
            .state<ScrollableState>(listeDesMessages())
            .position;
        q.jumpTo(q.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(
          find.byKey(FilDiscussion.clePlusAnciens),
          anyOf(findsOneWidget, findsNothing),
        );
      }
      expect(_idsAffiches(tester), serveur);
      expect(tester.takeException(), isNull);
    });
  });

  group('session finie', () {
    MessagesMetierSupabase adaptateur(bool session) => MessagesMetierSupabase(
      (String f, Map<String, dynamic> a) async =>
          throw const PostgrestException(
            message: 'permission denied for function com_envoyer_message',
            code: '42501',
          ),
      libelles: const LibellesCommunicationSlang(),
      sessionOuverte: () => session,
    );
    const String fil = '7c400000-0000-4000-8000-0000000000f9';

    test(
      '42501 sans session : se reconnecter, jamais « conversation fermee »',
      () async {
        await expectLater(
          adaptateur(false).envoyer(fil, 'Bonjour', 'cle-1'),
          throwsA(
            isA<EnvoiNonConfirme>().having(
              (EnvoiNonConfirme e) => e.cause,
              'cause',
              t.commun.etats.sessionExpiree.phrase,
            ),
          ),
        );
      },
    );

    test('contre-epreuve : 42501 avec session reste le refus connu', () async {
      await expectLater(
        adaptateur(true).envoyer(fil, 'Bonjour', 'cle-1'),
        throwsA(
          isA<EnvoiRefuse>().having(
            (EnvoiRefuse e) => e.phrase,
            'phrase',
            t.com.messages.fil.refusFerme,
          ),
        ),
      );
    });

    testWidgets('la bulle garde le texte, propose « Reessayer », dit la cause '
        'au lecteur d\'ecran, sans essai automatique', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      int appels = 0;
      await tester.pumpWidget(
        hoteTheme(
          FilDiscussion(
            messages: const <MessageFil>[],
            textes: textesFilCommunication(),
            onEnvoyerMessage: (String _, String _) async {
              appels++;
              throw EnvoiNonConfirme(t.commun.etats.sessionExpiree.phrase);
            },
          ),
          defilant: false,
        ),
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour');
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(appels, 1);
      expect(find.text('Bonjour'), findsOneWidget);
      expect(find.text(ligneEchec), findsOneWidget);
      expect(find.text(t.com.messages.fil.refusFerme), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(t.commun.etats.sessionExpiree.phrase)),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(FilDiscussion.cleLigneEchec));
      await tester.pumpAndSettle();
      expect(
        find.text(t.com.socle.composants.composer.reessayer),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    '« Fichiers partages » : apres deux pages chargees, un message '
    'avec un fichier arrive : l\'ancien fichier reste, le nouveau s\'ajoute',
    (WidgetTester tester) async {
      final ServeurFiable s = ServeurFiable(
        portDemo(RoleDemoCommunications.enseignant),
      );
      await s.preparer(anciens: 120, avecPiece: <int>{10, 110});
      await monterMessages(
        tester,
        port: s,
        depart: cheminFilTest(ServeurFiable.filId),
        taille: const Size(1700, 1000),
      );
      await ouvrirContexte(tester);
      final p = t.com.messages.panneau;
      for (int i = 0; i < 3; i++) {
        final Finder lien = find.text(p.chargerPrecedents);
        if (lien.evaluate().isEmpty) break;
        await tester.ensureVisible(lien);
        await tester.tap(lien);
        await tester.pumpAndSettle();
      }
      List<String> noms() => <String>[
        for (final Element e
            in find
                .descendant(
                  of: find.byType(PanneauContexteFil),
                  matching: find.byType(CartePieceJointe),
                )
                .evaluate())
          (e.widget as CartePieceJointe).piece.nom,
      ];
      expect(noms(), <String>['document-110.pdf', 'document-10.pdf']);
      for (int i = 0; i < 3; i++) {
        _arrive(
          s,
          'arrive-piece-$i',
          pieces: <PieceJointe>[
            if (i == 2)
              PieceJointe(
                reference: ReferencePieceJointe('piece-nouvelle'),
                nom: 'nouveau.pdf',
                nature: NaturePieceJointe.document,
                typeLisible: 'PDF',
              ),
          ],
        );
        _veille(tester).relire();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }
      expect(noms(), <String>[
        'nouveau.pdf',
        'document-110.pdf',
        'document-10.pdf',
      ]);
      expect(find.byKey(PanneauContexteFil.cleFichiersPartiels), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
