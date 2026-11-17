// ACCUEIL-INVITE (09/11/2026, lot correctif INVITATION-COMPTE) : l'accueil
// unique des personnes invitees, devant l'inscription. Rouge sans le lot :
// sur `main` 43c6709e, une personne invitee dans un foyer qui arrive sans
// profil tombe dans le questionnaire des familles.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/features/connexion/accueil_invite.dart';
import 'package:rewayah_academy/features/connexion/accueil_invite_supabase.dart';
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';

import '../../support/harnais.dart';

class _Port implements PortAccueilInvite {
  _Port(this.invitation, {this.issue = IssueReponseInvite.acceptee});

  InvitationAccueil? invitation;
  IssueReponseInvite issue;
  IssueReponseInvite issueRefus = IssueReponseInvite.refusee;
  Error? panneLecture;
  Error? panneInscription;
  int lectures = 0;
  final List<(String, String, Genre)> inscrits = <(String, String, Genre)>[];
  final List<String> cles = <String>[];
  int refus = 0;

  @override
  Future<InvitationAccueil?> lire() async {
    lectures++;
    final Error? panne = panneLecture;
    if (panne != null) throw panne;
    return invitation;
  }

  @override
  Future<IssueReponseInvite> accepter({
    required String prenom,
    required String nom,
    required Genre genre,
    required String cle,
  }) async {
    cles.add(cle);
    final Error? panne = panneInscription;
    if (panne != null) throw panne;
    inscrits.add((prenom, nom, genre));
    return issue;
  }

  @override
  Future<IssueReponseInvite> refuser({required String cle}) async {
    refus++;
    return issueRefus;
  }
}

class _Source implements SourceSession {
  int rafraichissements = 0;
  bool panne = false;

  @override
  Stream<SessionState> etats() => const Stream<SessionState>.empty();

  @override
  Future<void> rafraichir() async {
    rafraichissements++;
    if (panne) throw StateError('jeton');
  }
}

const InvitationAccueil _foyer = InvitationAccueil(
  role: RoleInvite.foyer,
  prenomInvitant: 'Prenom',
);

Future<void> _monter(WidgetTester tester, _Port port, {_Source? source}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.inscription,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.inscription,
          builder: (BuildContext _, GoRouterState _) =>
              const PorteAccueilInvite(enfant: Text('questionnaire')),
        ),
        GoRoute(
          path: Routes.racine,
          builder: (BuildContext _, GoRouterState _) => const Text('racine'),
        ),
      ],
      surcharges: <Override>[
        portAccueilInviteProvider.overrideWithValue(port),
        sourceSessionProvider.overrideWithValue(source ?? _Source()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _remplir(WidgetTester tester, {bool genre = true}) async {
  await tester.enterText(find.byKey(AccueilInvitePage.prenomKey), ' Amina ');
  await tester.enterText(find.byKey(AccueilInvitePage.nomKey), ' Essai ');
  if (genre) {
    await tester.tap(find.text(t.inscription.genreFemme));
  }
  await tester.pumpAndSettle();
}

Future<void> _appuyer(WidgetTester tester, Key cle) async {
  final Finder bouton = find.byKey(cle);
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

Future<void> _accepter(WidgetTester tester) =>
    _appuyer(tester, AccueilInvitePage.accepterKey);

Future<void> _continuer(WidgetTester tester) async {
  final Finder bouton = find.byKey(AccueilInvitePage.continuerKey);
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture : role et prenom ; sans invitation ou role inconnu, rien', () {
    final InvitationAccueil? foyer = InvitationAccueil.depuisJson(
      <String, Object?>{
        'etat': 'invite',
        'role': 'foyer',
        'prenom_invitant': ' Prenom ',
      },
    );
    expect(foyer?.role, RoleInvite.foyer);
    expect(foyer?.prenomInvitant, 'Prenom');
    expect(
      InvitationAccueil.depuisJson(<String, Object?>{
        'etat': 'invite',
        'role': 'enseignant',
      })?.role,
      RoleInvite.enseignant,
    );
    expect(
      InvitationAccueil.depuisJson(<String, Object?>{'etat': 'aucune'}),
      isNull,
    );
    expect(
      InvitationAccueil.depuisJson(<String, Object?>{
        'etat': 'invite',
        'role': 'admin',
      }),
      isNull,
    );
    expect(InvitationAccueil.depuisJson(null), isNull);
    expect(
      issueReponseInviteDepuis(<String, Object?>{'etat': 'acceptee'}),
      IssueReponseInvite.acceptee,
    );
    expect(
      issueReponseInviteDepuis(<String, Object?>{'etat': 'refusee'}),
      IssueReponseInvite.refusee,
    );
    expect(
      issueReponseInviteDepuis(<String, Object?>{'etat': 'perimee'}),
      IssueReponseInvite.perimee,
    );
    expect(issueReponseInviteDepuis('?'), IssueReponseInvite.nonAcceptable);
  });

  testWidgets('sans invitation : l inscription habituelle, sans accueil', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(null));
    expect(find.text('questionnaire'), findsOneWidget);
    expect(find.text(t.accueilInvite.titre), findsNothing);
  });

  testWidgets('invitee au foyer : l accueil dit le role et le foyer, jamais '
      'le questionnaire', (WidgetTester tester) async {
    await _monter(tester, _Port(_foyer));
    expect(find.text('questionnaire'), findsNothing);
    expect(find.text(t.accueilInvite.titre), findsWidgets);
    expect(find.text(t.accueilInvite.roles.foyer), findsOneWidget);
    expect(find.textContaining('Prenom'), findsOneWidget);
    expect(find.byKey(AccueilInvitePage.prenomKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invitee au foyer : « Accepter » cree le compte, la session est '
      'relue, puis le routeur decide', (WidgetTester tester) async {
    final _Port port = _Port(_foyer);
    final _Source source = _Source();
    await _monter(tester, port, source: source);
    await _remplir(tester);
    await _accepter(tester);
    expect(port.inscrits, <(String, String, Genre)>[
      ('Amina', 'Essai', Genre.femme),
    ]);
    expect(source.rafraichissements, 1);
    expect(find.text('racine'), findsOneWidget);
  });

  testWidgets('champs manquants : rien n est envoye, la phrase le dit', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(_foyer);
    await _monter(tester, port);
    await _remplir(tester, genre: false);
    await _accepter(tester);
    expect(port.inscrits, isEmpty);
    expect(find.text(t.accueilInvite.champsRequis), findsOneWidget);
  });

  testWidgets('invitation qui ne sert plus : la phrase le dit, on reste ici', (
    WidgetTester tester,
  ) async {
    final _Source source = _Source();
    await _monter(
      tester,
      _Port(_foyer, issue: IssueReponseInvite.perimee),
      source: source,
    );
    await _remplir(tester);
    await _accepter(tester);
    expect(find.text(t.adulte.acceptation.perimee), findsOneWidget);
    expect(source.rafraichissements, 0);
    expect(find.text('racine'), findsNothing);
  });

  testWidgets('panne a l envoi : l erreur se dit, rien n est dit cree', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(_foyer)..panneInscription = StateError('reseau');
    await _monter(tester, port);
    await _remplir(tester);
    await _accepter(tester);
    final a = t.adulte.acceptation;
    expect(
      find.text('${a.acceptationEchecTitre} ${a.echecPhrase}'),
      findsOneWidget,
    );
    expect(find.text('racine'), findsNothing);
    // Nouvelle tentative : la meme cle, jamais deux comptes.
    port.panneInscription = null;
    await _accepter(tester);
    expect(port.cles.toSet(), hasLength(1));
    expect(find.text('racine'), findsOneWidget);
  });

  testWidgets('« Refuser » : rien n est cree, la phrase le dit, puis '
      '« Continuer » ouvre l inscription habituelle', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(_foyer);
    await _monter(tester, port);
    await _appuyer(tester, AccueilInvitePage.refuserKey);
    expect(port.refus, 1);
    expect(port.inscrits, isEmpty);
    expect(find.text(t.adulte.acceptation.refuseeTitre), findsOneWidget);
    expect(find.byKey(AccueilInvitePage.prenomKey), findsNothing);
    await _continuer(tester);
    expect(find.text('questionnaire'), findsOneWidget);
  });

  testWidgets('session non relue : la phrase de l inscription le dit', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Port(_foyer), source: _Source()..panne = true);
    await _remplir(tester);
    await _accepter(tester);
    expect(find.text(t.inscription.erreurActualisation), findsOneWidget);
  });

  testWidgets('enseignant invite : « Continuer » ouvre son inscription '
      'habituelle', (WidgetTester tester) async {
    final _Port port = _Port(
      const InvitationAccueil(role: RoleInvite.enseignant),
    );
    await _monter(tester, port);
    expect(find.text(t.accueilInvite.roles.enseignant), findsOneWidget);
    expect(find.byKey(AccueilInvitePage.prenomKey), findsNothing);
    await _continuer(tester);
    expect(find.text('questionnaire'), findsOneWidget);
    expect(port.inscrits, isEmpty);
  });

  testWidgets('lecture en panne : l erreur et « Reessayer », jamais le '
      'questionnaire suppose', (WidgetTester tester) async {
    final _Port port = _Port(_foyer)..panneLecture = StateError('reseau');
    await _monter(tester, port);
    expect(find.text('questionnaire'), findsNothing);
    expect(find.text(t.accueilInvite.titre), findsNothing);
    final Finder reessayer = find.text(t.commun.reessayer);
    expect(reessayer, findsOneWidget);
    port.panneLecture = null;
    await tester.tap(reessayer);
    await tester.pumpAndSettle();
    expect(port.lectures, 2);
    expect(find.text(t.accueilInvite.roles.foyer), findsOneWidget);
  });

  testWidgets(
    'pendant la lecture : un squelette, ni accueil ni questionnaire',
    (WidgetTester tester) async {
      final Completer<InvitationAccueil?> attente =
          Completer<InvitationAccueil?>();
      final _PortLent port = _PortLent(attente.future);
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const PorteAccueilInvite(enfant: Text('questionnaire')),
          surcharges: <Override>[
            portAccueilInviteProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('questionnaire'), findsNothing);
      expect(find.text(t.accueilInvite.titre), findsNothing);
      attente.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('questionnaire'), findsOneWidget);
    },
  );

  group(
    'INVITATION-CODE-ACCUEIL : l\'inscription de l\'invite, quel que soit le chemin',
    () {
      setUp(oublierInvitationEnCours);
      tearDown(oublierInvitationEnCours);

      testWidgets('candidat sans profil : directement le depot de candidature, '
          'sans accueil ni « Pour qui »', (WidgetTester tester) async {
        await _monter(
          tester,
          _Port(const InvitationAccueil(role: RoleInvite.candidat)),
        );
        expect(find.text('questionnaire'), findsOneWidget);
        expect(find.byKey(AccueilInvitePage.continuerKey), findsNothing);
        final InvitationEnCours? marque = lireInvitationEnCours();
        expect(marque?.candidature, isTrue);
        // L'inscription ouvre alors le depot : l'ecran de l'invitation avec
        // `candidature=1`, comme le lien CAND-04.
        expect(marque?.route, contains('candidature=1'));
      });

      testWidgets('enseignant : « Continuer » retient le code du serveur', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          _Port(
            const InvitationAccueil(
              role: RoleInvite.enseignant,
              code: 'ABCD-EFGH-JKMN',
            ),
          ),
        );
        expect(lireInvitationEnCours(), isNull);
        await _appuyer(tester, AccueilInvitePage.continuerKey);
        expect(lireInvitationEnCours()?.code, 'ABCD-EFGH-JKMN');
        expect(
          lireInvitationEnCours()?.route,
          contains('code=ABCD-EFGH-JKMN'),
        );
      });
    },
  );
}

class _PortLent implements PortAccueilInvite {
  _PortLent(this._reponse);

  final Future<InvitationAccueil?> _reponse;

  @override
  Future<InvitationAccueil?> lire() => _reponse;

  @override
  Future<IssueReponseInvite> accepter({
    required String prenom,
    required String nom,
    required Genre genre,
    required String cle,
  }) async => IssueReponseInvite.nonAcceptable;

  @override
  Future<IssueReponseInvite> refuser({required String cle}) async =>
      IssueReponseInvite.nonAcceptable;
}
