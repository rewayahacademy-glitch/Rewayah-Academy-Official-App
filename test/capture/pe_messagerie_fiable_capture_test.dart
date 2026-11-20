// PE-D1 MESSAGERIE-FIABLE (20/11/2026) : captures du lot, a 390 de large, fil
// plein ecran (la page du telephone), fr et ar, clair et sombre. Donnees
// fictives seulement. Jamais sans `CAPTURE_DIR`
// (`CAPTURE_DIR=docs/current/captures/E2E`).
//   - un long fil (300 messages) qui charge sa page precedente en remontant ;
//   - la page precedente qui echoue : sa phrase et « Reessayer » ;
//   - un envoi coupe, en cours de reessai seul (« Envoi en cours ») ;
//   - un refus du serveur, dit par sa vraie phrase.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../features/com_messages/support_messages.dart';
import '../features/com_messages/support_serveur_fiable.dart';
import '../support/demo/communications/demo_communications_page.dart';
import 'outil_capture.dart';

const String _dossier = 'pe-messagerie-fiable';

Future<ServeurFiable> _monter(
  WidgetTester tester,
  AppLocale langue,
  Brightness luminosite, {
  int anciens = 300,
}) async {
  final ServeurFiable serveur = ServeurFiable(
    portDemo(RoleDemoCommunications.enseignant),
  );
  await serveur.preparer(anciens: anciens, langue: langue);
  await monterFilPleinEcran(
    tester,
    port: serveur,
    langue: langue,
    luminosite: luminosite,
  );
  return serveur;
}

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(listeDesMessages()).position;

Future<void> _ecrire(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(FilDiscussion.champKey), texte);
  await tester.pump();
  await tester.tap(find.byKey(FilDiscussion.envoyerKey));
  await tester.pump();
}

void main() {
  group('Capture : messagerie fiable', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final String s = '${langue.name}_${lum.name}_390';

        testWidgets('page precedente en chargement, $s', (
          WidgetTester tester,
        ) async {
          final ServeurFiable serveur = await _monter(tester, langue, lum);
          serveur.pageSuspendue = Completer<void>();
          final ScrollPosition p = _position(tester);
          p.jumpTo(p.maxScrollExtent);
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/anciens_chargement_$s')}',
          );
          serveur.pageSuspendue!.complete();
          await tester.pumpAndSettle();
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/anciens_charges_$s')}',
          );
        });

        testWidgets('page precedente en echec, $s', (
          WidgetTester tester,
        ) async {
          final ServeurFiable serveur = await _monter(tester, langue, lum)
            ..pageEnEchec = true;
          final ScrollPosition p = _position(tester);
          p.jumpTo(p.maxScrollExtent);
          await stabiliser(tester);
          expect(serveur.pagesLues, 1);
          p.jumpTo(p.maxScrollExtent);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/anciens_echec_$s')}',
          );
        });

        testWidgets('envoi coupe, reessai en cours, $s', (
          WidgetTester tester,
        ) async {
          final ServeurFiable serveur = await _monter(
            tester,
            langue,
            lum,
            anciens: 6,
          );
          serveur.issues.addAll(<IssueEnvoi>[IssueEnvoi.coupe]);
          await _ecrire(
            tester,
            langue == AppLocale.ar
                ? 'السلام عليكم، لدي سؤال عن الحصة.'
                : 'Bonjour, une question sur la séance.',
          );
          await tester.pump(const Duration(milliseconds: 300));
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/envoi_reessai_$s')}',
          );
          await tester.pump(FilDiscussion.delaisReessaiParDefaut.first);
          await tester.pumpAndSettle();
          expect(serveur.messages.length, 7);
          debugPrint(
            'PNG ${await capturerVue(tester, '$_dossier/envoi_confirme_$s')}',
          );
        });

        testWidgets('refus du serveur, sa vraie phrase, $s', (
          WidgetTester tester,
        ) async {
          final ServeurFiable serveur = await _monter(
            tester,
            langue,
            lum,
            anciens: 6,
          );
          serveur.issues.add(IssueEnvoi.refus);
          await _ecrire(
            tester,
            langue == AppLocale.ar ? 'رسالة مرفوضة.' : 'Message refusé.',
          );
          await stabiliser(tester);
          expect(find.text(t.com.messages.fil.refusFerme), findsOneWidget);
          debugPrint('PNG ${await capturerVue(tester, '$_dossier/refus_$s')}');
        });
      }
    }
  });
}
