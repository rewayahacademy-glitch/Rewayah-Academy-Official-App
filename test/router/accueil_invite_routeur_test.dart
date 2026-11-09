// ACCUEIL-INVITE (09/11/2026) : sur le VRAI routeur, une session sans profil
// dont l'adresse est invitee dans un foyer voit l'accueil, pas le
// questionnaire des familles ; sans invitation, l'inscription habituelle.
// Rouge sans le lot : `/inscription` montrait directement l'inscription.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/connexion/accueil_invite.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../support/harnais.dart';
import 'support_routeur.dart';

class _Port implements PortAccueilInvite {
  const _Port(this.invitation);

  final InvitationAccueil? invitation;

  @override
  Future<InvitationAccueil?> lire() async => invitation;

  @override
  Future<IssueReponseInvite> accepter({
    required String prenom,
    required String nom,
    required Genre genre,
    required String cle,
  }) async => IssueReponseInvite.acceptee;

  @override
  Future<IssueReponseInvite> refuser({required String cle}) async =>
      IssueReponseInvite.refusee;
}

const SessionState _sansProfil = SessionState(
  resolue: true,
  profileId: 'p1',
  lectureProfil: LectureProfil.absente,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('invitee au foyer, sans profil : l accueil, pas le '
      'questionnaire', (WidgetTester tester) async {
    await monterRouteur(
      tester,
      Routes.inscription,
      source: FausseSourceSession(_sansProfil),
      surcharges: <Override>[
        portAccueilInviteProvider.overrideWithValue(
          const _Port(InvitationAccueil(role: RoleInvite.foyer)),
        ),
      ],
    );
    await stabiliser(tester);
    expect(find.byType(AccueilInvitePage), findsOneWidget);
    expect(find.byType(InscriptionPage), findsNothing);
  });

  testWidgets('sans invitation : l inscription habituelle', (
    WidgetTester tester,
  ) async {
    await monterRouteur(
      tester,
      Routes.inscription,
      source: FausseSourceSession(_sansProfil),
      surcharges: <Override>[
        portAccueilInviteProvider.overrideWithValue(const _Port(null)),
      ],
    );
    await stabiliser(tester);
    expect(find.byType(AccueilInvitePage), findsNothing);
    expect(find.byType(InscriptionPage), findsOneWidget);
  });
}
