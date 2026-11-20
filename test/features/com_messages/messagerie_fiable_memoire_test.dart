// PE-D1 MESSAGERIE-FIABLE, relecture adverse de la PR 657 (pilote, 20/11) :
// 1. aucun message deja affiche ne quitte l'ecran quand la relecture ne rend
//    que les 50 derniers (120 messages, une page remontee, des arrivees) ;
// 4. « Fichiers partages » lit les messages charges, dit quand la liste est
//    partielle et charge la suite ;
// 5 b. quitter la conversation pendant un reessai : ni erreur, ni brouillon
//    d'un texte deja parti.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/memoire_pages_fil.dart';
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';
import 'support_serveur_fiable.dart';

List<String> _idsAffiches(WidgetTester tester) => <String>[
  for (final MessageFil m
      in tester.widget<FilDiscussion>(find.byType(FilDiscussion)).messages)
    m.id,
];

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(listeDesMessages()).position;

void main() {
  EtatVeilleMessagesControleur veilleDe(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(FilDiscussion)))
          .read(etatVeilleMessagesProvider.notifier);

  group('1. aucun message ne quitte l\'ecran', () {
    Future<void> verifier(WidgetTester tester, ServeurFiable serveur) async {
      final List<String> attendus = <String>[
        for (final MessageCommunication m in serveur.messages) m.id,
      ];
      final List<String> vus = _idsAffiches(tester);
      expect(vus.toSet(), hasLength(vus.length), reason: 'aucun doublon');
      expect(vus, attendus, reason: 'tous, dans l\'ordre');
    }

    for (final bool plein in <bool>[true, false]) {
      testWidgets('120 messages, une page remontee, une arrivee puis dix '
          '(${plein ? 'telephone' : 'ordinateur'})', (
        WidgetTester tester,
      ) async {
        final ServeurFiable serveur = ServeurFiable(
          portDemo(RoleDemoCommunications.enseignant),
        );
        await serveur.preparer(anciens: 120);
        if (plein) {
          await monterFilPleinEcran(tester, port: serveur);
        } else {
          await monterMessages(
            tester,
            port: serveur,
            depart: cheminFilTest(ServeurFiable.filId),
          );
        }
        final ScrollPosition p = _position(tester);
        p.jumpTo(plein ? p.maxScrollExtent : 0);
        await tester.pumpAndSettle();
        expect(serveur.pagesLues, greaterThanOrEqualTo(1));
        final List<String> avant = _idsAffiches(tester);
        expect(avant.length, greaterThan(50));

        serveur.arrive('Une question fictive.');
        veilleDe(tester).relire();
        await tester.pumpAndSettle();
        // La relecture ne rend que les 50 derniers : le plus ancien de la
        // page precedente reste a l'ecran.
        expect(_idsAffiches(tester), <String>[...avant, 'arrive-1']);

        for (int i = 0; i < 10; i++) {
          serveur.arrive('Arrivee fictive $i.');
          veilleDe(tester).relire();
          await tester.pumpAndSettle();
        }
        // On remonte jusqu'au debut : les 131 messages, dans l'ordre.
        for (
          int i = 0;
          i < 8 && _idsAffiches(tester).length < serveur.messages.length;
          i++
        ) {
          final ScrollPosition q = _position(tester);
          q.jumpTo(plein ? q.maxScrollExtent : 0);
          await tester.pumpAndSettle();
        }
        await verifier(tester, serveur);
        expect(serveur.messages, hasLength(131));
        expect(tester.takeException(), isNull);
      });
    }

    test('la memoire seule : les messages sortis de la page sont gardes', () {
      final MemoirePagesFil memoire = MemoirePagesFil();
      FilMetier fil(int premier, int dernier, {bool plus = true}) => FilMetier(
        id: 'f',
        contexte: <ElementContexteFil>[
          ElementContexteFil(
            objet: ObjetLie(type: TypeObjetLie.classe, id: 'c', libelle: 'C'),
          ),
        ],
        participants: const <Participant>[],
        messages: <MessageCommunication>[
          for (int i = premier; i <= dernier; i++)
            MessageCommunication(
              id: 'm$i',
              auteur: const Participant(id: 'p', nomAffiche: 'P'),
              texte: 't$i',
              envoyeLe: DateTime.utc(2026, 11, 20).add(Duration(minutes: i)),
            ),
        ],
        plusAnciens: plus,
      );
      memoire.recevoir(fil(51, 100));
      memoire.recevoir(fil(52, 101));
      memoire.recevoir(fil(60, 109));
      expect(
        <String>[for (final m in memoire.messages) m.id],
        <String>[for (int i = 51; i <= 109; i++) 'm$i'],
      );
      expect(memoire.plusAnciens, isTrue);
      // Un autre fil : la memoire repart de zero.
      memoire.recevoir(
        FilMetier(
          id: 'autre',
          contexte: fil(1, 1).contexte,
          participants: const <Participant>[],
          messages: const <MessageCommunication>[],
        ),
      );
      expect(memoire.messages, isEmpty);
      memoire.dispose();
    });
  });

  List<String> nomsDuPanneau(WidgetTester tester) => <String>[
    for (final Element e
        in find
            .descendant(
              of: find.byType(PanneauContexteFil),
              matching: find.byType(CartePieceJointe),
            )
            .evaluate())
      (e.widget as CartePieceJointe).piece.nom,
  ];

  testWidgets('4. « Fichiers partages » : liste partielle dite, la suite se '
      'charge', (WidgetTester tester) async {
    final ServeurFiable serveur = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await serveur.preparer(anciens: 120, avecPiece: <int>{10, 110});
    await monterMessages(
      tester,
      port: serveur,
      depart: cheminFilTest(ServeurFiable.filId),
      taille: const Size(1700, 1000),
    );
    await ouvrirContexte(tester);
    final m = t.com.messages.panneau;
    expect(nomsDuPanneau(tester), <String>['document-110.pdf']);
    expect(find.byKey(PanneauContexteFil.cleFichiersPartiels), findsOneWidget);
    expect(find.text(m.fichiersPartiels), findsOneWidget);
    for (int i = 0; i < 3; i++) {
      final Finder lien = find.text(m.chargerPrecedents);
      if (lien.evaluate().isEmpty) break;
      await tester.ensureVisible(lien);
      await tester.tap(lien);
      await tester.pumpAndSettle();
    }
    expect(serveur.pagesLues, 2);
    expect(nomsDuPanneau(tester), <String>[
      'document-110.pdf',
      'document-10.pdf',
    ]);
    expect(find.byKey(PanneauContexteFil.cleFichiersPartiels), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('5 b. quitter pendant un reessai : ni erreur, ni brouillon d un '
      'texte deja parti', (WidgetTester tester) async {
    final ServeurFiable serveur = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await serveur.preparer(anciens: 3);
    serveur.issues.addAll(<IssueEnvoi>[IssueEnvoi.coupeApres]);
    final router = await monterMessages(
      tester,
      port: serveur,
      depart: cheminFilTest(ServeurFiable.filId),
    );
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Parti tot.');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.envoyerKey));
    await tester.pump();
    // Le premier essai est arrive, sa reponse s'est perdue : on quitte la
    // conversation avant le reessai.
    router.go(cheminListeTest);
    await tester.pumpAndSettle();
    expect(find.byType(FilDiscussion), findsNothing);
    // Le reessai part quand meme, sous la meme cle, et aboutit.
    await tester.pump(FilDiscussion.delaisReessaiParDefaut.first);
    await tester.pumpAndSettle();
    expect(serveur.clesRecues, hasLength(2));
    expect(serveur.clesRecues.toSet(), hasLength(1));
    expect(serveur.messages, hasLength(4));
    expect(tester.takeException(), isNull);
    // On revient : le message est la, une fois, et le champ est vide.
    router.go(cheminFilTest(ServeurFiable.filId));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.text('Parti tot.'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      isEmpty,
    );
    expect(find.byKey(FilDiscussion.cleBrouillonRestaure), findsNothing);
  });
}
