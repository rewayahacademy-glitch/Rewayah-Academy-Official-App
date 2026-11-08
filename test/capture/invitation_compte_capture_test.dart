// INVITATION-SECOND-ADULTE et INVITATION-COMPTE (pilote et garde-cap,
// 07/11/2026). FR et AR, 390 et 1440 : l'invitation envoyee du titulaire
// (echeance, renvois restants, « Renvoyer l'invitation »), puis apres le
// renvoi ; le lien d'une invitation de foyer ouvert par un autre compte.
// Prefixe des PNG : `invitation_compte_`. Saute sans CAPTURE_DIR.
//
// Ce ne sont pas les captures du robot de la pile locale (R3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/connexion/invitation_compte.dart';
import 'package:rewayah_academy/features/connexion/invitation_foyer_ouverte.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/invitation_envoyee.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

class _Renvoi implements PortInvitationEnvoyee {
  @override
  Future<InvitationEnAttente?> lire() async => null;

  @override
  Future<ResultatRenvoi> renvoyer(String cle) async => const RenvoiFait(2);
}

class _AutreAdresse implements PortInvitationCompte {
  @override
  Future<void> ouvrir(
    InvitationDansAdresse invitation,
    String courriel,
  ) async {}

  @override
  Future<EtatInvitationPourMoi> pourMoi(String code) async =>
      EtatInvitationPourMoi.autreAdresse;
}

void main() {
  group('Capture : INVITATION-COMPTE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String suffixe = '${taille.width.toInt()}_${langue.languageCode}';
        final List<Override> reseau = <Override>[
          serviceReseauProvider.overrideWithValue(
            FauxServiceReseau(horsLigneRendu: false),
          ),
        ];

        testWidgets('invitation_compte_envoyee_$suffixe', (
          WidgetTester tester,
        ) async {
          LocaleSettings.setLocaleSync(langue);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              InvitationEnvoyeePage(
                invitation: const InvitationEnvoyee(
                  courriel: 'amina@example.com',
                ),
                attente: InvitationEnAttente(
                  courriel: 'amina@example.com',
                  expireLe: DateTime(2026, 11, 14, 10),
                  renvoisRestants: 3,
                ),
                onRetour: () {},
                onAnnulee: () {},
              ),
              surcharges: <Override>[
                ...reseau,
                portInvitationEnvoyeeProvider.overrideWithValue(_Renvoi()),
              ],
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'invitation_compte_1_envoyee_$suffixe')}',
          );
          final Finder renvoyer = find.byKey(InvitationEnvoyeePage.renvoyerKey);
          await tester.ensureVisible(renvoyer);
          await tester.tap(renvoyer);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'invitation_compte_2_renvoyee_$suffixe')}',
          );
        });

        testWidgets('invitation_compte_autre_adresse_$suffixe', (
          WidgetTester tester,
        ) async {
          LocaleSettings.setLocaleSync(langue);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const InvitationFoyerOuvertePage(code: 'ABCD-EFGH-JKMN'),
              surcharges: <Override>[
                ...reseau,
                portInvitationCompteProvider.overrideWithValue(_AutreAdresse()),
              ],
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'invitation_compte_3_autre_adresse_$suffixe')}',
          );
        });
      }
    }
  });
}
