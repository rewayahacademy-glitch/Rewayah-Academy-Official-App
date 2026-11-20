// PE-D1 MESSAGERIE-FIABLE (parcours enseignant, plan section 4.1) : la vraie
// page Messages, sur un faux serveur qui garde ses messages, deduplique par cle
// d'envoi (comme `com_messages_idempotence`) et lit par pages de 50 (comme
// `com_lire_fil_page`).
//
// Prouve :
// - coupure de reseau : l'envoi est reessaye seul, sous la meme cle ; un seul
//   message, « Envoye » ;
// - confirmation tardive : le message est arrive mais aucune reponse ; apres
//   les essais, la bulle est « non confirmee », puis la relecture du fil la
//   remplace par le message confirme (jamais de copie en echec qui reste) ;
// - double envoi : la meme cle rejouee ne fait qu'un message ;
// - message retape au meme texte : deux messages, deux bulles, aucune en echec ;
// - refus du serveur : jamais reessaye, dit par sa vraie phrase, sans
//   « Reessayer » ni « connexion » ;
// - un fil de 300 messages se lit par pages en remontant, sans trou, sans
//   doublon, et la position de lecture ne saute pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/veille_messages.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/demo/communications/demo_communications_page.dart';
import '../../support/echec_bulle.dart';
import 'support_messages.dart';
import 'support_serveur_fiable.dart';

void main() {
  final m = t.com.messages;
  final c = t.com.socle.composants.composer;

  EtatVeilleMessagesControleur veilleDe(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(FilDiscussion)))
          .read(etatVeilleMessagesProvider.notifier);

  Finder bulles(String texte) => find.descendant(
    of: find.byType(FilDiscussion),
    matching: find.text(texte),
  );

  Future<ServeurFiable> monter(WidgetTester tester, {int anciens = 0}) async {
    final ServeurFiable serveur = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await serveur.preparer(anciens: anciens);
    await monterMessages(
      tester,
      port: serveur,
      depart: cheminFilTest(ServeurFiable.filId),
    );
    return serveur;
  }

  Future<void> ecrire(WidgetTester tester, String texte) async {
    await tester.enterText(find.byKey(FilDiscussion.champKey), texte);
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.envoyerKey));
    await tester.pump();
  }

  /// Laisse passer les trois attentes du reessai automatique (1 + 3 + 8 s).
  Future<void> passerLesEssais(WidgetTester tester) async {
    for (final Duration d in FilDiscussion.delaisReessaiParDefaut) {
      await tester.pump(d);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('coupure de reseau : reessai seul, meme cle, un seul message', (
    WidgetTester tester,
  ) async {
    final ServeurFiable serveur = await monter(tester);
    serveur.issues.addAll(<IssueEnvoi>[IssueEnvoi.coupe, IssueEnvoi.coupe]);
    await ecrire(tester, 'Bonjour, une question.');
    // Pendant les essais, la bulle reste « Envoi en cours », jamais en echec.
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsNothing);
    await passerLesEssais(tester);
    expect(serveur.clesRecues, hasLength(3));
    expect(serveur.clesRecues.toSet(), hasLength(1));
    expect(serveur.messages, hasLength(1));
    expect(bulles('Bonjour, une question.'), findsOneWidget);
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsNothing);
    expect(find.text(c.envoye), findsOneWidget);
  });

  testWidgets('confirmation tardive : la copie en echec est remplacee par le '
      'message confirme a la relecture', (WidgetTester tester) async {
    final ServeurFiable serveur = await monter(tester);
    serveur.issues.addAll(List<IssueEnvoi>.filled(4, IssueEnvoi.coupeApres));
    await ecrire(tester, 'Arrive sans reponse.');
    await passerLesEssais(tester);
    // Quatre appels, la meme cle : le serveur n'a qu'un message.
    expect(serveur.clesRecues, hasLength(4));
    expect(serveur.clesRecues.toSet(), hasLength(1));
    expect(serveur.messages, hasLength(1));
    // Aucune reponse : la bulle dit qu'elle n'est pas confirmee.
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsOneWidget);
    // La relecture du fil rend le message avec sa cle : la bulle en echec
    // s'efface, une seule bulle reste.
    veilleDe(tester).relire();
    await tester.pumpAndSettle();
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsNothing);
    expect(bulles('Arrive sans reponse.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('relecture pendant l envoi : une seule bulle, les essais '
      's arretent', (WidgetTester tester) async {
    final ServeurFiable serveur = await monter(tester);
    serveur.issues.addAll(List<IssueEnvoi>.filled(4, IssueEnvoi.coupeApres));
    await ecrire(tester, 'Vu par la relecture.');
    // Le message est enregistre au premier essai ; la relecture arrive avant
    // le deuxieme.
    veilleDe(tester).relire();
    await tester.pump();
    await tester.pump();
    await passerLesEssais(tester);
    expect(serveur.clesRecues, hasLength(1));
    expect(bulles('Vu par la relecture.'), findsOneWidget);
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsNothing);
  });

  testWidgets('message retape au meme texte apres un echec en fait parti : '
      'deux messages, deux bulles, aucune en echec', (
    WidgetTester tester,
  ) async {
    final ServeurFiable serveur = await monter(tester);
    serveur.issues.addAll(List<IssueEnvoi>.filled(4, IssueEnvoi.coupeApres));
    await ecrire(tester, 'Merci');
    await passerLesEssais(tester);
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsOneWidget);
    await ecrire(tester, 'Merci');
    await tester.pumpAndSettle();
    veilleDe(tester).relire();
    await tester.pumpAndSettle();
    expect(serveur.messages, hasLength(2));
    expect(bulles('Merci'), findsNWidgets(2));
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsNothing);
  });

  testWidgets('refus du serveur : jamais reessaye, sa vraie phrase, sans '
      '« Reessayer » ni « connexion »', (WidgetTester tester) async {
    final ServeurFiable serveur = await monter(tester);
    serveur.issues.add(IssueEnvoi.refus);
    await ecrire(tester, 'Refuse.');
    await passerLesEssais(tester);
    expect(serveur.clesRecues, hasLength(1));
    expect(serveur.messages, isEmpty);
    expect(find.text(m.fil.refusFerme), findsOneWidget);
    expect(
      find.textContaining(RegExp('connexion', caseSensitive: false)),
      findsNothing,
    );
    await tester.tap(find.byKey(FilDiscussion.cleLigneEchec));
    await tester.pumpAndSettle();
    expect(find.text(c.reessayer), findsNothing);
    expect(find.text(m.images.supprimerEchec), findsOneWidget);
  });

  testWidgets('echec reseau sur tous les essais : « Reessayer » rejoue la meme '
      'cle', (WidgetTester tester) async {
    final ServeurFiable serveur = await monter(tester);
    serveur.issues.addAll(List<IssueEnvoi>.filled(4, IssueEnvoi.coupe));
    await ecrire(tester, 'Plus tard.');
    await passerLesEssais(tester);
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsOneWidget);
    await choisirActionEchec(tester, c.reessayer);
    await tester.pumpAndSettle();
    expect(serveur.clesRecues, hasLength(5));
    expect(serveur.clesRecues.toSet(), hasLength(1));
    expect(serveur.messages, hasLength(1));
    expect(find.byKey(FilDiscussion.cleLigneEchec), findsNothing);
  });

  testWidgets('300 messages : lus par pages en remontant, sans trou ni '
      'doublon, la lecture ne saute pas', (WidgetTester tester) async {
    final ServeurFiable serveur = await monter(tester, anciens: 300);
    expect(serveur.lecturesFil, 1);
    expect(bulles('Message fictif 300'), findsOneWidget);
    expect(bulles('Message fictif 250'), findsNothing);
    final Finder liste = find.descendant(
      of: find.byKey(FilDiscussion.cleMessages),
      matching: find.byType(Scrollable),
    );
    // On remonte jusqu'au plus ancien message.
    for (int i = 0; i < 400; i++) {
      if (bulles('Message fictif 1').evaluate().isNotEmpty) break;
      final Finder repere = bulles(
        'Message fictif ${251 - 50 * serveur.pagesLues}',
      );
      final double? avant = repere.evaluate().isEmpty
          ? null
          : tester.getTopLeft(repere).dy;
      final int pagesAvant = serveur.pagesLues;
      await tester.drag(liste.first, const Offset(0, 300));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      if (serveur.pagesLues > pagesAvant &&
          avant != null &&
          repere.evaluate().isNotEmpty) {
        // Une page vient d'arriver au-dessus : le message lu reste a sa place.
        expect((tester.getTopLeft(repere).dy - avant).abs(), lessThan(320));
      }
    }
    await tester.pumpAndSettle();
    expect(bulles('Message fictif 1'), findsOneWidget);
    expect(serveur.pagesLues, 5);
    expect(find.byKey(FilDiscussion.clePlusAnciens), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
