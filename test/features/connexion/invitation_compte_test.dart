// INVITATION-COMPTE (07/11/2026, garde-cap) : les inscriptions sont fermees au
// niveau de l'instance Auth ; le lien d'une invitation (foyer, enseignant ou
// comptable, candidat) fait d'abord creer le compte de l'adresse invitee par
// le serveur, puis le lien de connexion part. Lien ouvert par un autre
// compte : rien n'est consomme, la page le dit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/invitation_compte.dart';
import 'package:rewayah_academy/features/connexion/invitation_foyer_ouverte.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import '../../support/harnais.dart';

class _FauxInvitationCompte implements PortInvitationCompte {
  _FauxInvitationCompte(
    this.journal, {
    this.etat = EtatInvitationPourMoi.autreAdresse,
  });

  final List<String> journal;
  final EtatInvitationPourMoi etat;

  @override
  Future<void> ouvrir(InvitationDansAdresse invitation, String courriel) async {
    journal.add(
      'compte:${invitation.type.valeur}:${invitation.code}:$courriel',
    );
  }

  @override
  Future<EtatInvitationPourMoi> pourMoi(String code) async {
    journal.add('pourMoi:$code');
    return etat;
  }
}

class _AuthJournal extends FauxServiceAuth {
  _AuthJournal(this.journal, {this.inscriptionFermee = false});

  final List<String> journal;

  /// L'instance refuse l'inscription (compte non cree).
  final bool inscriptionFermee;

  @override
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle}) {
    journal.add('lien:${courriel.trim()}');
    if (inscriptionFermee) {
      throw const AuthApiException(
        'Signups not allowed for this instance',
        statusCode: '422',
        code: 'signup_disabled',
      );
    }
    return super.envoyerLienCourriel(courriel, jetonControle: jetonControle);
  }
}

Future<void> _envoyer(
  WidgetTester tester,
  Uri adresse,
  List<String> journal, {
  bool inscriptionFermee = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    hote(
      ConnexionPage(urlRetour: adresse, mode: ModeConnexion.creation),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(
          _AuthJournal(journal, inscriptionFermee: inscriptionFermee),
        ),
        portInvitationCompteProvider.overrideWithValue(
          _FauxInvitationCompte(journal),
        ),
        demoAuthActiveProvider.overrideWithValue(false),
        environnementConnexionProvider.overrideWithValue('production'),
      ],
    ),
  );
  await tester.pumpAndSettle();
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
}

SessionState _tuteur() => const SessionState(
  resolue: true,
  profileId: 'p1',
  householdId: 'h1',
  role: AppRole.guardian,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

void main() {
  group('invitationDansAdresse', () {
    test(
      'foyer, enseignant ou comptable, candidat : le type suit le repere',
      () {
        expect(
          invitationDansAdresse(
            Uri.parse('/c?mode=creer&foyer=1&code=ABCD-EFGH-JKMN'),
          )?.type,
          TypeInvitationCompte.foyer,
        );
        expect(
          invitationDansAdresse(
            Uri.parse('/c?mode=creer&invitation=1&code=ABCD-EFGH-JKMN'),
          )?.type,
          TypeInvitationCompte.equipe,
        );
        expect(
          invitationDansAdresse(
            Uri.parse('/c?mode=creer&candidature=1&code=ABCD-EFGH-JKMN'),
          )?.type,
          TypeInvitationCompte.candidat,
        );
      },
    );

    test('le lien de l e-mail : les parametres sont dans le fragment', () {
      final InvitationDansAdresse? lue = invitationDansAdresse(
        Uri.parse(
          'https://app.rewayahacademy.com/#/connexion?mode=creer&foyer=1&code=ABCD-EFGH-JKMN',
        ),
      );
      expect(lue?.type, TypeInvitationCompte.foyer);
      expect(lue?.code, 'ABCD-EFGH-JKMN');
    });

    test('sans code, sans mode creer ou sans repere : rien', () {
      expect(invitationDansAdresse(Uri.parse('/c?mode=creer&foyer=1')), isNull);
      expect(invitationDansAdresse(Uri.parse('/c?foyer=1&code=ABCD')), isNull);
      expect(
        invitationDansAdresse(Uri.parse('/c?mode=creer&code=ABCD')),
        isNull,
      );
    });
  });

  group('connexion sur invitation', () {
    testWidgets('le compte de l adresse invitee est demande AVANT le lien', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      await _envoyer(
        tester,
        Uri.parse(
          'https://app.rewayahacademy.com/?mode=creer&foyer=1&code=ABCD-EFGH-JKMN#/connexion',
        ),
        journal,
      );
      expect(journal, <String>[
        'compte:foyer:ABCD-EFGH-JKMN:ami@example.test',
        'lien:ami@example.test',
      ]);
    });

    testWidgets('le candidat et l enseignant passent par la meme porte', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      await _envoyer(
        tester,
        Uri.parse(
          'https://app.rewayahacademy.com/?mode=creer&candidature=1&code=ABCD-EFGH-JKMN#/connexion',
        ),
        journal,
      );
      expect(journal.first, 'compte:candidat:ABCD-EFGH-JKMN:ami@example.test');
    });

    testWidgets('compte non cree au lien d un foyer : demander un renvoi a la '
        'personne qui invite', (WidgetTester tester) async {
      await _envoyer(
        tester,
        Uri.parse(
          'https://app.rewayahacademy.com/#/connexion?mode=creer&foyer=1&code=ABCD-EFGH-JKMN',
        ),
        <String>[],
        inscriptionFermee: true,
      );
      expect(
        find.text(t.connexion.invitationFoyer.creationImpossible),
        findsOneWidget,
      );
      expect(find.text(t.connexion.inscriptionFermee), findsNothing);
    });

    testWidgets('sans invitation, inscriptions fermees : la phrase d avant', (
      WidgetTester tester,
    ) async {
      await _envoyer(
        tester,
        Uri.parse('https://app.rewayahacademy.com/#/connexion?mode=creer'),
        <String>[],
        inscriptionFermee: true,
      );
      expect(find.text(t.connexion.inscriptionFermee), findsOneWidget);
      expect(
        find.text(t.connexion.invitationFoyer.creationImpossible),
        findsNothing,
      );
    });

    testWidgets('sans invitation : le lien seul, comme avant', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      await _envoyer(
        tester,
        Uri.parse('https://app.rewayahacademy.com/?mode=creer#/connexion'),
        journal,
      );
      expect(journal, <String>['lien:ami@example.test']);
    });
  });

  group('lien ouvert par un compte deja connecte', () {
    final DateTime maintenant = DateTime.utc(2026, 11, 7, 10);

    test(
      'la connexion avec un code de foyer mene a sa page, sans rien consommer',
      () {
        expect(
          deciderRedirection(
            session: _tuteur(),
            cheminDemande: Routes.connexion,
            cheminComplet: '/connexion?mode=creer&foyer=1&code=ABCD-EFGH-JKMN',
            maintenant: maintenant,
          ),
          '${Routes.invitationFoyer}?code=ABCD-EFGH-JKMN',
        );
        expect(
          deciderRedirection(
            session: _tuteur(),
            cheminDemande: Routes.invitationFoyer,
            cheminComplet: '${Routes.invitationFoyer}?code=ABCD-EFGH-JKMN',
            maintenant: maintenant,
          ),
          isNull,
        );
      },
    );

    test('sans code de foyer : la racine, comme avant', () {
      expect(
        deciderRedirection(
          session: _tuteur(),
          cheminDemande: Routes.connexion,
          cheminComplet:
              '/connexion?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
          maintenant: maintenant,
        ),
        Routes.racinePour(AppRole.guardian),
      );
    });

    testWidgets('autre adresse : la phrase du pilote et « Se deconnecter »', (
      WidgetTester tester,
    ) async {
      final List<String> journal = <String>[];
      await tester.pumpWidget(
        hote(
          const InvitationFoyerOuvertePage(code: 'ABCD-EFGH-JKMN'),
          surcharges: <Override>[
            portInvitationCompteProvider.overrideWithValue(
              _FauxInvitationCompte(journal),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(InvitationFoyerOuvertePage.autreAdresseKey),
        findsOneWidget,
      );
      expect(
        find.text(t.connexion.invitationFoyer.autreAdresse),
        findsOneWidget,
      );
      expect(find.text(t.compte.deconnexion), findsOneWidget);
      expect(journal, <String>['pourMoi:ABCD-EFGH-JKMN']);
    });

    testWidgets('plus valable : la phrase dit quoi faire', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const InvitationFoyerOuvertePage(code: 'ABCD-EFGH-JKMN'),
          surcharges: <Override>[
            portInvitationCompteProvider.overrideWithValue(
              _FauxInvitationCompte(
                <String>[],
                etat: EtatInvitationPourMoi.plusValable,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(InvitationFoyerOuvertePage.plusValableKey),
        findsOneWidget,
      );
      expect(
        find.text(t.connexion.invitationFoyer.plusValablePhrase),
        findsOneWidget,
      );
    });
  });
}
