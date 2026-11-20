// PE-D1 MESSAGERIE-FIABLE : le chargement par pages d'un long fil, au
// telephone (fil plein ecran, liste inversee) et sur ordinateur (fil a cote de
// la liste, liste dans le sens de lecture). Une page qui arrive au-dessus ne
// deplace pas le message lu ; la rangee « Chargement des messages precedents »
// se voit pendant la lecture ; un echec se dit, avec « Reessayer ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';
import 'support_serveur_fiable.dart';

Finder _bulle(String texte) =>
    find.descendant(of: find.byType(FilDiscussion), matching: find.text(texte));

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(listeDesMessages()).position;

/// Monte la lecture vers le haut, attend la page, et verifie que [repere]
/// n'a pas bouge.
Future<void> _remonterEtVerifier(
  WidgetTester tester,
  ServeurFiable serveur, {
  required bool inverse,
  required String repere,
}) async {
  serveur.pageSuspendue = Completer<void>();
  final ScrollPosition p = _position(tester);
  p.jumpTo(inverse ? p.maxScrollExtent : 0);
  await tester.pump();
  await tester.pump();
  // La page est demandee : la rangee de chargement est la, en haut.
  expect(find.byKey(FilDiscussion.clePlusAnciens), findsOneWidget);
  expect(
    find.bySemanticsLabel(t.com.messages.fil.anciensChargement),
    findsOneWidget,
  );
  final double avant = tester.getTopLeft(_bulle(repere)).dy;
  serveur.pageSuspendue!.complete();
  serveur.pageSuspendue = null;
  for (int i = 0; i < 6; i++) {
    await tester.pump();
  }
  final double apres = tester.getTopLeft(_bulle(repere)).dy;
  expect(
    (apres - avant).abs(),
    lessThanOrEqualTo(1),
    reason: 'le message lu ne saute pas ($avant -> $apres)',
  );
}

void main() {
  testWidgets('telephone, fil plein ecran : 300 messages, la lecture ne saute '
      'pas quand une page arrive', (WidgetTester tester) async {
    final ServeurFiable serveur = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await serveur.preparer(anciens: 300);
    await monterFilPleinEcran(tester, port: serveur);
    expect(_bulle('Message fictif 300'), findsOneWidget);
    await _remonterEtVerifier(
      tester,
      serveur,
      inverse: true,
      repere: 'Message fictif 251',
    );
    expect(serveur.pagesLues, 1);
    expect(_bulle('Message fictif 250'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinateur, fil a cote de la liste : la lecture ne saute pas', (
    WidgetTester tester,
  ) async {
    final ServeurFiable serveur = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    );
    await serveur.preparer(anciens: 300);
    await monterMessages(
      tester,
      port: serveur,
      depart: cheminFilTest(ServeurFiable.filId),
    );
    await _remonterEtVerifier(
      tester,
      serveur,
      inverse: false,
      repere: 'Message fictif 251',
    );
    expect(serveur.pagesLues, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une page qui echoue : sa phrase et « Reessayer », sans boucle', (
    WidgetTester tester,
  ) async {
    final ServeurFiable serveur = ServeurFiable(
      portDemo(RoleDemoCommunications.enseignant),
    )..pageEnEchec = true;
    await serveur.preparer(anciens: 120);
    await monterFilPleinEcran(tester, port: serveur);
    final ScrollPosition p = _position(tester);
    p.jumpTo(p.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text(t.com.messages.fil.anciensEchec), findsOneWidget);
    // La rangee de l'echec est dans la liste : remonter tout en haut la
    // montre en entier, phrase comprise.
    p.jumpTo(p.maxScrollExtent);
    await tester.pumpAndSettle();
    // La phrase se lit en entier, sous la barre, dans la liste.
    expect(
      tester.getRect(find.text(t.com.messages.fil.anciensEchec)).top,
      greaterThanOrEqualTo(tester.getRect(listeDesMessages()).top),
    );
    // Aucun nouvel essai seul : un echec ne relance pas la lecture en boucle.
    p.jumpTo(p.maxScrollExtent - 1);
    await tester.pumpAndSettle();
    expect(serveur.pagesLues, 1);
    serveur.pageEnEchec = false;
    await tester.tap(
      find.descendant(
        of: find.byKey(FilDiscussion.clePlusAnciens),
        matching: find.text(t.com.socle.composants.composer.reessayer),
      ),
    );
    await tester.pumpAndSettle();
    expect(serveur.pagesLues, greaterThanOrEqualTo(2));
    expect(_bulle('Message fictif 70'), findsOneWidget);
    expect(find.text(t.com.messages.fil.anciensEchec), findsNothing);
  });
}
