// INVITATION-ENSEIGNANT-REPARE (14/11/2026) : un enseignant invite ne pouvait
// pas creer son compte. Ce que l'ecran doit faire, cas par cas (K-59 : ce qui
// manque, la cause en mots simples, quoi faire) :
//
//   - le code d'invitation a une place : « J'ai un code d'invitation » ouvre un
//     champ ; un code deja pris (lien, ou retenu sur l'appareil) se dit ;
//   - le code part a la fonction `invitation-compte` AVANT le lien de connexion ;
//   - un 500 du serveur a l'envoi ne dit jamais « lien deja servi » ;
//   - une creation de compte refusee pour une invitation le dit ;
//   - l'ecran d'un lien en echec dit la vraie cause.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/invitation_compte.dart';
import 'package:rewayah_academy/features/connexion/recuperation_page.dart';
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import '../../support/harnais.dart';

class _Visiteur extends SessionControleur {
  @override
  SessionState build() => const SessionState.deconnecte();
}

class _FauxPort implements PortInvitationCompte {
  _FauxPort(this.journal);
  final List<String> journal;

  @override
  Future<void> ouvrir(InvitationDansAdresse invitation, String courriel) async {
    journal.add('compte:${invitation.type.valeur}:${invitation.code}');
  }

  @override
  Future<EtatInvitationPourMoi> pourMoi(String code) async =>
      EtatInvitationPourMoi.plusValable;
}

class _Auth extends FauxServiceAuth {
  _Auth(this.journal, {this.erreur});
  final List<String> journal;
  final AuthApiException? erreur;

  @override
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle}) {
    journal.add('lien');
    if (erreur != null) throw erreur!;
    return super.envoyerLienCourriel(courriel, jetonControle: jetonControle);
  }
}

final Uri _avecCode = Uri.parse(
  'https://app.rewayahacademy.com/#/connexion?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
);
final Uri _sansCode = Uri.parse(
  'https://app.rewayahacademy.com/#/connexion?mode=creer',
);

Future<void> _monter(
  WidgetTester tester,
  Uri adresse,
  List<String> journal, {
  AuthApiException? erreur,
  Size taille = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(oublierInvitationEnCours);
  await tester.pumpWidget(
    hote(
      ConnexionPage(urlRetour: adresse, mode: ModeConnexion.creation),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(_Auth(journal, erreur: erreur)),
        portInvitationCompteProvider.overrideWithValue(_FauxPort(journal)),
        demoAuthActiveProvider.overrideWithValue(false),
        environnementConnexionProvider.overrideWithValue('production'),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _envoyer(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('connexion-courriel')),
    'prof@example.test',
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
}

Finder _clef(String c) => find.byKey(ValueKey<String>(c));

void main() {
  setUp(oublierInvitationEnCours);

  group('le code d\'invitation a une place', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('code dans l\'adresse : la ligne le dit, pas de lien '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        await _monter(tester, _avecCode, <String>[], taille: taille);
        expect(
          find.text(t.connexion.codeInvitationReconnu(code: 'ABCD-EFGH-JKMN')),
          findsOneWidget,
        );
        expect(_clef('connexion-code-lien'), findsNothing);
      });

      testWidgets('sans code : « J\'ai un code d\'invitation » ouvre le champ '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        await _monter(tester, _sansCode, <String>[], taille: taille);
        expect(find.text(t.connexion.avoirCodeInvitation), findsOneWidget);
        expect(_clef('connexion-code-invitation'), findsNothing);
        await tester.tap(_clef('connexion-code-lien'));
        await tester.pumpAndSettle();
        expect(_clef('connexion-code-invitation'), findsOneWidget);
        expect(_clef('connexion-code-lien'), findsNothing);
      });
    }

    testWidgets('code saisi : il part a invitation-compte avant le lien', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      await _monter(tester, _sansCode, journal);
      await tester.tap(_clef('connexion-code-lien'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _clef('connexion-code-invitation'),
        'ABCD-EFGH-JKMN',
      );
      await _envoyer(tester);
      expect(journal, <String>['compte:equipe:ABCD-EFGH-JKMN', 'lien']);
      // Retenu sur l'appareil, comme celui du lien.
      expect(lireInvitationEnCours()?.code, 'ABCD-EFGH-JKMN');
    });

    testWidgets('code d\'un lien ouvert plus tot : repris sans rien saisir', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      retenirInvitationEnCours(code: 'ABCD-EFGH-JKMN');
      await _monter(tester, _sansCode, journal);
      expect(
        find.text(t.connexion.codeInvitationReconnu(code: 'ABCD-EFGH-JKMN')),
        findsOneWidget,
      );
      await _envoyer(tester);
      expect(journal, <String>['compte:equipe:ABCD-EFGH-JKMN', 'lien']);
    });

    testWidgets('sans aucun code : aucune demande de compte', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      await _monter(tester, _sansCode, journal);
      await _envoyer(tester);
      expect(journal, <String>['lien']);
    });

    testWidgets('code d\'invitation conserve apres un lien en echec', (
      WidgetTester tester,
    ) async {
      // Le lien demande depuis l'invitation pose la marque ; ouvrir ensuite
      // l'ecran de recuperation (nouveau lien) ne l'efface pas.
      await _monter(tester, _avecCode, <String>[]);
      expect(lireInvitationEnCours()?.code, 'ABCD-EFGH-JKMN');
      retenirInvitationDepuisAdresse(
        Uri.parse('https://app.rewayahacademy.com/#/connexion'),
      );
      expect(lireInvitationEnCours()?.code, 'ABCD-EFGH-JKMN');
    });
  });

  group('un echec d\'envoi dit sa vraie cause', () {
    test('500 du serveur : issue « serveur », jamais « erreur »', () {
      expect(
        issueEchecEnvoi(
          const AuthApiException(
            'unexpected_failure',
            statusCode: '500',
            code: 'unexpected_failure',
          ),
        ),
        IssueEnvoiLien.serveur,
      );
      expect(
        issueEchecEnvoi(const AuthApiException('x', statusCode: '503')),
        IssueEnvoiLien.serveur,
      );
      expect(
        issueEchecEnvoi(const AuthApiException('x', statusCode: '400')),
        IssueEnvoiLien.erreur,
      );
    });

    testWidgets('500 a l\'envoi : « le lien n\'a pas pu partir », ni '
        '« deja servi »', (WidgetTester tester) async {
      await _monter(
        tester,
        _avecCode,
        <String>[],
        erreur: const AuthApiException(
          'error finding user',
          statusCode: '500',
          code: 'unexpected_failure',
        ),
      );
      await _envoyer(tester);
      expect(find.text(t.connexion.erreurServeur), findsOneWidget);
      expect(find.textContaining('déjà servi'), findsNothing);
      expect(find.textContaining('expiré'), findsNothing);
    });

    testWidgets('invitation d\'equipe dont le compte n\'est pas cree : la '
        'phrase le dit et dit quoi faire', (WidgetTester tester) async {
      await _monter(
        tester,
        _avecCode,
        <String>[],
        erreur: const AuthApiException(
          'Signups not allowed for this instance',
          statusCode: '422',
          code: 'signup_disabled',
        ),
      );
      await _envoyer(tester);
      expect(
        find.text(t.connexion.invitationCreationImpossible),
        findsOneWidget,
      );
    });
  });

  testWidgets('« User is banned » a l\'envoi : la phrase du compte supprime, '
      'et le champ du code est ouvert dessous', (WidgetTester tester) async {
    await _monter(
      tester,
      _sansCode,
      <String>[],
      erreur: const AuthApiException(
        'User is banned',
        statusCode: '403',
        code: 'user_banned',
      ),
    );
    await _envoyer(tester);
    expect(find.text(t.connexion.erreurCompteSupprime), findsOneWidget);
    expect(_clef('connexion-code-invitation'), findsOneWidget);
  });

  testWidgets(
    'arrivee avec invitation=1 sans code : le champ est deja ouvert',
    (WidgetTester tester) async {
      await _monter(
        tester,
        Uri.parse(
          'https://app.rewayahacademy.com/#/connexion?mode=creer&invitation=1',
        ),
        <String>[],
      );
      expect(_clef('connexion-code-invitation'), findsOneWidget);
    },
  );

  group('l\'ecran d\'un lien en echec dit la vraie cause', () {
    Future<void> monter(WidgetTester tester, String adresse) async {
      await tester.pumpWidget(
        hote(
          PageIntrouvable(adresse: Uri.parse(adresse)),
          surcharges: <Override>[sessionProvider.overrideWith(_Visiteur.new)],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('otp_expired : « deja servi ou expire »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        'https://app.rewayahacademy.com/?error=access_denied&error_code=otp_expired#/x',
      );
      expect(find.text(t.i1.lien.dejaServiTitre), findsOneWidget);
    });

    testWidgets('autre refus : jamais « deja servi », une phrase qui dit quoi '
        'faire', (WidgetTester tester) async {
      await monter(
        tester,
        'https://app.rewayahacademy.com/?error=server_error&error_code=unexpected_failure#/x',
      );
      expect(find.text(t.i1.lien.dejaServiTitre), findsNothing);
      expect(find.text(t.i1.lien.refuseTitre), findsOneWidget);
      expect(find.text(t.i1.lien.refuseDetail), findsOneWidget);
    });

    test('user_banned (callback ou verify) : motif « compte supprime »', () {
      for (final String adresse in <String>[
        'https://app.rewayahacademy.com/?error=access_denied&error_code=user_banned&error_description=User+is+banned',
        'https://app.rewayahacademy.com/#error=access_denied&error_description=403%3A+User+is+banned',
      ]) {
        expect(
          motifDepuisUrlRetour(Uri.parse(adresse)),
          MotifRecuperation.compteSupprime,
          reason: adresse,
        );
      }
    });

    testWidgets('compte supprime : la cause, quoi faire, et le lien du code', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        'https://app.rewayahacademy.com/?error=access_denied&error_code=user_banned#/x',
      );
      expect(
        find.text(t.connexion.recuperation.compteSupprimeTitre),
        findsOneWidget,
      );
      expect(
        find.text(t.connexion.recuperation.compteSupprimeDetail),
        findsOneWidget,
      );
      expect(find.text(t.connexion.avoirCodeInvitation), findsOneWidget);
      expect(find.text(t.i1.lien.dejaServiTitre), findsNothing);
    });

    testWidgets('lien ouvert dans un autre navigateur : on le dit', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        'https://app.rewayahacademy.com/?error=invalid_request&error_code=flow_state_not_found#/x',
      );
      expect(find.text(t.i1.lien.dejaServiTitre), findsNothing);
      expect(find.text(t.i1.lien.autreNavigateurTitre), findsOneWidget);
      expect(find.text(t.i1.lien.autreNavigateurDetail), findsOneWidget);
    });
  });
}
