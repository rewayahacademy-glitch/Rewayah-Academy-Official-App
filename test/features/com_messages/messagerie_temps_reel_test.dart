// MESSAGERIE-TEMPS-REEL (14/11/2026, retour du directeur en production) : un
// message qui arrive pendant que le fil est ouvert s'y affiche sans geste ; un
// message envoye d'ici, revenu du serveur par la relecture, ne fait jamais
// deux bulles ; quand le temps reel tombe, la page le dit (K-59).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/bandeau_messages_hors_direct.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../support/demo/communications/com_messages_demo.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import '../../support/garde_interface.dart';
import 'support_messages.dart';

/// Le port de demonstration, avec des messages arrives « d'ailleurs » apres
/// l'ouverture du fil : ils s'ajoutent a chaque lecture du fil.
class _PortVivant implements PortMessagesMetier {
  _PortVivant(this.demo);

  final MessagesMetierDemo demo;
  final List<MessageCommunication> arrives = <MessageCommunication>[];
  int lecturesFil = 0;
  int lectures = 0;

  @override
  Future<FilMetier?> fil(String filId) async {
    lecturesFil++;
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
  Future<List<ResumeFil>> fils() {
    lectures++;
    return demo.fils();
  }

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
  // La veille de l'application n'est pas montee : le test ecrit l'etat
  // qu'elle ecrirait (signal recu, canal tombe).
  EtatVeilleMessagesControleur veilleDe(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(FilDiscussion)))
          .read(etatVeilleMessagesProvider.notifier);

  testWidgets('un message recu s\'affiche dans le fil ouvert, sans geste', (
    WidgetTester tester,
  ) async {
    final _PortVivant port = _PortVivant(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await monterMessages(tester, port: port, depart: cheminFilTest('fil-adam'));
    final FilMetier fil = (await port.demo.fil('fil-adam'))!;
    final Participant autre = fil.participants.firstWhere(
      (Participant p) => !p.estSoi,
    );
    expect(find.text('Message arrive en direct.'), findsNothing);
    port.arrives.add(
      MessageCommunication(
        id: 'arrive-1',
        auteur: autre,
        texte: 'Message arrive en direct.',
        envoyeLe: maintenantTest,
      ),
    );
    final int avant = port.lecturesFil;
    veilleDe(tester).relire();
    await tester.pumpAndSettle();
    expect(port.lecturesFil, greaterThan(avant));
    expect(find.text('Message arrive en direct.'), findsOneWidget);
    // Le fil reste monte (aucun squelette, aucun etat de chargement).
    expect(find.byType(FilDiscussion), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('son propre message revenu du serveur ne fait qu\'une bulle', (
    WidgetTester tester,
  ) async {
    final _PortVivant port = _PortVivant(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await monterMessages(tester, port: port, depart: cheminFilTest('fil-adam'));
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bien recu.');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.envoyerKey));
    await tester.pumpAndSettle();
    expect(find.text('Bien recu.'), findsOneWidget);
    // Le serveur signale la lecture de l'auteur : la page relit le fil, qui
    // porte desormais le message envoye.
    veilleDe(tester).relire();
    await tester.pumpAndSettle();
    expect(find.text('Bien recu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'temps reel tombe : la page le dit (K-59), un seul bouton plein',
    (WidgetTester tester) async {
      final _PortVivant port = _PortVivant(
        portDemo(RoleDemoCommunications.enseignant),
      );
      await monterMessages(
        tester,
        port: port,
        depart: cheminFilTest('fil-adam'),
        taille: const Size(320, 700),
        echelleTexte: 2,
      );
      expect(find.byKey(BandeauMessagesHorsDirect.cle), findsNothing);
      veilleDe(tester).horsDirect();
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauMessagesHorsDirect.cle), findsOneWidget);
      expect(find.text(t.com.messages.direct.horsDirect), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
