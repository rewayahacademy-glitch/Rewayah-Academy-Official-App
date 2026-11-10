// Captures d'ACCUEIL-INVITE (09/11/2026, lot correctif INVITATION-COMPTE) :
// l'accueil unique des personnes invitees, devant l'inscription. Trois etats :
// la personne invitee dans un foyer (nom et genre a donner), l'enseignant
// invite, la lecture en panne. 390x844 et 1440x900, francais et arabe.
// Donnees fictives.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/connexion/accueil_invite.dart';

import 'outil_capture.dart';

class _Port implements PortAccueilInvite {
  const _Port(this.invitation, {this.panne = false});

  final InvitationAccueil? invitation;
  final bool panne;

  @override
  Future<InvitationAccueil?> lire() async {
    if (panne) throw StateError('reseau');
    return invitation;
  }

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

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('ACCUEIL-INVITE : captures', skip: sautSansCapture, () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final String etat in <String>['foyer', 'enseignant', 'panne']) {
          final String nom =
              'ai_${taille.width.toInt()}_${langue.languageCode}_$etat';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, 1);
            addTearDown(tester.view.reset);
            final _Port port = switch (etat) {
              'foyer' => const _Port(
                InvitationAccueil(
                  role: RoleInvite.foyer,
                  prenomInvitant: 'Prenom',
                ),
              ),
              'enseignant' => const _Port(
                InvitationAccueil(role: RoleInvite.enseignant),
              ),
              _ => const _Port(null, panne: true),
            };
            await tester.pumpWidget(
              hoteCapture(
                const PorteAccueilInvite(enfant: Text('inscription')),
                surcharges: <Override>[
                  portAccueilInviteProvider.overrideWithValue(port),
                ],
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('inscription'), findsNothing);
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturerVue(tester, 'accueil-invite/$nom')}',
            );
          });
        }
      }
    }
  });
}
