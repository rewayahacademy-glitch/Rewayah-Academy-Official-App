// PE-A2 (20/11/2026) : le lien d'invitation d'un candidat enseignant ouvre
// une page qui le reconnait. Ce que le test prouve :
//
// - `invitation=1&code=...` et `candidature=1` sont des arrivees de candidat ;
//   le lien d'un foyer, l'adresse sans repere, non ;
// - la page dit en haut « Votre candidature d'enseignant » et quoi faire, et
//   n'offre qu'une action (ni « J'ai deja un compte », ni questionnaire) ;
// - le type envoye au serveur ne change pas (`equipe` reste `equipe`) ;
// - l'adresse n'est pas preremplie : le serveur ne la rend pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/invitation_compte.dart';
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

class _Port implements PortInvitationCompte {
  final List<String> journal = <String>[];

  @override
  Future<void> ouvrir(InvitationDansAdresse invitation, String courriel) async {
    journal.add('compte:${invitation.type.valeur}:${invitation.code}');
  }

  @override
  Future<EtatInvitationPourMoi> pourMoi(String code) async =>
      EtatInvitationPourMoi.plusValable;
}

Future<_Port> _monter(WidgetTester tester, String adresse) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  final _Port port = _Port();
  await tester.pumpWidget(
    hote(
      ConnexionPage(urlRetour: Uri.parse(adresse)),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        portInvitationCompteProvider.overrideWithValue(port),
        demoAuthActiveProvider.overrideWithValue(false),
        environnementConnexionProvider.overrideWithValue('production'),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return port;
}

const String _app = 'https://app.rewayahacademy.com/#/connexion';

void main() {
  tearDown(oublierInvitationEnCours);

  group('arriveeCandidatDansAdresse', () {
    test('invitation personnelle et lien du candidat : oui', () {
      expect(
        arriveeCandidatDansAdresse(
          Uri.parse('$_app?mode=creer&invitation=1&code=ABCD-EFGH-JKMN'),
        ),
        isTrue,
      );
      expect(
        arriveeCandidatDansAdresse(
          Uri.parse('$_app?mode=creer&candidature=1&code=ABCD-EFGH-JKMN'),
        ),
        isTrue,
      );
      expect(
        arriveeCandidatDansAdresse(Uri.parse('$_app?mode=creer&candidature=1')),
        isTrue,
      );
    });

    test('foyer, sans repere, sans mode creer : non', () {
      expect(
        arriveeCandidatDansAdresse(
          Uri.parse('$_app?mode=creer&foyer=1&code=ABCD-EFGH-JKMN'),
        ),
        isFalse,
      );
      expect(
        arriveeCandidatDansAdresse(Uri.parse('$_app?mode=creer')),
        isFalse,
      );
      expect(
        arriveeCandidatDansAdresse(Uri.parse('$_app?candidature=1')),
        isFalse,
      );
      // Le champ du code ouvert depuis la recuperation : pas un candidat.
      expect(
        arriveeCandidatDansAdresse(Uri.parse('$_app?mode=creer&invitation=1')),
        isFalse,
      );
    });
  });

  group('la page du lien', () {
    testWidgets('invitation personnelle : la page le dit, une seule action', (
      WidgetTester tester,
    ) async {
      final _Port port = await _monter(
        tester,
        '$_app?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
      );
      expect(find.text(t.connexion.candidat.titre), findsOneWidget);
      expect(find.text(t.connexion.candidat.phrase), findsOneWidget);
      expect(find.text(t.connexion.titre), findsNothing);
      // Ni « J'ai deja un compte » / « Creer un compte », ni Google comme
      // second bouton plein.
      expect(
        find.byKey(const ValueKey<String>('connexion-mode')),
        findsNothing,
      );
      verifierUnSeulBoutonPlein(tester);
      // Le code est reconnu ; l'adresse n'est pas inventee.
      expect(
        find.byKey(const ValueKey<String>('connexion-code-reconnu')),
        findsOneWidget,
      );
      final EditableText champ = tester.widget<EditableText>(
        find
            .descendant(
              of: find.byKey(const ValueKey<String>('connexion-courriel')),
              matching: find.byType(EditableText),
            )
            .first,
      );
      expect(champ.controller.text, isEmpty);
      // Le type envoye au serveur ne change pas.
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        'ami@example.test',
      );
      await tester.pump();
      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.connexion.envoyerLienCreation,
      );
      await tester.ensureVisible(bouton);
      await tester.pumpAndSettle();
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(port.journal, <String>['compte:equipe:ABCD-EFGH-JKMN']);
    });

    testWidgets('lien du candidat sans code : meme page', (
      WidgetTester tester,
    ) async {
      await _monter(tester, '$_app?mode=creer&candidature=1');
      expect(find.text(t.connexion.candidat.titre), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('connexion-mode')),
        findsNothing,
      );
    });

    testWidgets('lien d un foyer : la page ordinaire', (
      WidgetTester tester,
    ) async {
      await _monter(tester, '$_app?mode=creer&foyer=1&code=ABCD-EFGH-JKMN');
      expect(find.text(t.connexion.candidat.titre), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('connexion-mode')),
        findsOneWidget,
      );
    });

    testWidgets('en arabe, de droite a gauche, rien ne deborde', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      await _monter(
        tester,
        '$_app?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
      );
      expect(tester.takeException(), isNull);
      expect(find.text(t.connexion.candidat.titre), findsOneWidget);
    });
  });

  // Preuve visuelle (R3) : `CAPTURE_DIR=docs/current/captures/E2E`.
  group('captures de l arrivee', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('lien du candidat $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        await _monter(
          tester,
          '$_app?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
        );
        await capturerVue(tester, 'pe-entree/arrivee-lien_${nom}_390');
      });
    }
  });
}
