// FLUIDITE-2 (DECISION-FLUIDITE-2026-11-07 §1 ; choix du pilote et du
// garde-cap, 07/11) : ouvrir un fil le marque lu D'AVANCE. Le badge tombe
// avant la reponse de `com_marquer_lu` ; un echec le remet, sans message ;
// rouvrir le fil relance la lecture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/demo/communications/com_messages_demo.dart';
import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';

/// Le port de demonstration, dont la lecture est tenue par le test.
class _LectureTenue extends MessagesMetierDemo {
  _LectureTenue()
    : super(role: RoleDemoCommunications.tuteur, maintenant: maintenantTest);

  /// La reponse de la prochaine lecture ; nulle : reponse immediate.
  Completer<void>? attente;

  /// Vrai : la prochaine lecture echoue.
  bool echec = false;

  final List<String> lectures = <String>[];

  @override
  Future<void> marquerLu(String filId) async {
    lectures.add(filId);
    final Completer<void>? a = attente;
    if (a != null) await a.future;
    if (echec) throw StateError('reseau');
    await super.marquerLu(filId);
  }
}

Finder _badgeDe(String id) => find.descendant(
  of: find.ancestor(
    of: find.byKey(ListeFils.cleLigne(id)),
    matching: find.byType(MergeSemantics),
  ),
  matching: find.byType(BadgeNonLu),
);

Finder _badgesListe() => find.descendant(
  of: find.byKey(EspaceTravailAdaptatif.cleListe),
  matching: find.byType(BadgeNonLu),
);

void main() {
  group('FLUIDITE-2 : un fil ouvert est marque lu d avance', () {
    testWidgets('le badge tombe AVANT la reponse du serveur', (
      WidgetTester tester,
    ) async {
      final _LectureTenue port = _LectureTenue()..attente = Completer<void>();
      await monterMessages(tester, port: port);
      // Deux fils attendent : celui d'Adam et le dossier.
      expect(_badgesListe(), findsNWidgets(2));
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
      await tester.pumpAndSettle();
      // Le serveur n'a pas encore repondu : le badge est deja tombe.
      expect(port.lectures, <String>['fil-adam']);
      expect(_badgeDe('fil-adam'), findsNothing);
      expect(_badgesListe(), findsOneWidget);
      port.attente!.complete();
      await tester.pumpAndSettle();
      expect(_badgeDe('fil-adam'), findsNothing);
      expect(_badgesListe(), findsOneWidget);
    });

    testWidgets('echec : le badge revient, sans message ; rouvrir relance', (
      WidgetTester tester,
    ) async {
      final _LectureTenue port = _LectureTenue()
        ..attente = Completer<void>()
        ..echec = true;
      final GoRouter routeur = await monterMessages(tester, port: port);
      expect(_badgesListe(), findsNWidgets(2));
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
      await tester.pumpAndSettle();
      expect(_badgeDe('fil-adam'), findsNothing);
      expect(_badgesListe(), findsOneWidget);
      port.attente!.complete();
      await tester.pumpAndSettle();
      // Le serveur a refuse : rien n'est affirme, le badge est de retour.
      expect(_badgesListe(), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      // Rouvrir le fil relance la lecture, qui aboutit cette fois.
      port
        ..attente = null
        ..echec = false;
      routeur.go(cheminListeTest);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
      await tester.pumpAndSettle();
      expect(port.lectures, <String>['fil-adam', 'fil-adam']);
      expect(_badgeDe('fil-adam'), findsNothing);
      expect(_badgesListe(), findsOneWidget);
    });
  });

  // Captures R3 (donnees de demonstration ; jamais sans CAPTURE_DIR) : le fil
  // ouvert, badge deja tombe avant la reponse ; puis le badge revenu apres un
  // refus. Francais et arabe, 390 et 1440.
  group('Captures FLUIDITE-2 (messages)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        for (final bool refus in <bool>[false, true]) {
          final String nom =
              'messages_${refus ? 'refus' : 'avant_reponse'}_'
              '${langue.languageCode}_'
              '${taille.width.toInt()}x${taille.height.toInt()}';
          testWidgets(nom, (WidgetTester tester) async {
            final _LectureTenue port = _LectureTenue()
              ..attente = Completer<void>()
              ..echec = refus;
            final GoRouter routeur = await monterMessages(
              tester,
              port: port,
              taille: taille,
              langue: langue,
            );
            await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
            await tester.pumpAndSettle();
            if (refus) {
              port.attente!.complete();
              await tester.pumpAndSettle();
              // Au telephone, la liste montre le badge revenu.
              if (taille.width < 600) {
                routeur.go(cheminListeTest);
                await tester.pumpAndSettle();
              }
            }
            debugPrint('PNG ${await capturerVue(tester, nom)}');
            if (!refus) {
              port.attente!.complete();
              await tester.pumpAndSettle();
            }
          });
        }
      }
    }
  });
}
