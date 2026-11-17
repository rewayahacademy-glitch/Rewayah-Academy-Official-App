// POSTULER-ICI-RETOUR (16/11/2026) : capture de l'ecran ou la personne reprend
// quand la marque « candidature=1 » revient dans l'adresse de retour du lien de
// connexion (porte sans code fermee : la phrase et le champ du code), 360,
// francais et arabe. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/recrutement/invitation_candidat_page.dart';

import '../fixtures/candidature/faux_inscription_candidat.dart';
import '../support/demo/recrutement_demo.dart';
import '../support/monter_recrutement.dart';
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('POSTULER-ICI-RETOUR : captures', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('360 $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await monterRecrutement(
          tester,
          chemin: Routes.inscriptionInvitation,
          depart: '${Routes.inscriptionInvitation}?candidature=1',
          autres: <String>[
            Routes.inscriptionIdentite,
            Routes.inscriptionUsage,
            Routes.connexion,
          ],
          ecran: (state) => InvitationCandidatPage(
            codeInitial: state.uri.queryParameters['code'],
            candidature: state.uri.queryParameters['candidature'] == '1',
          ),
          surcharges: <Override>[
            portVerificationInvitationProvider.overrideWithValue(
              InvitationsDemo(),
            ),
            portInscriptionCandidatProvider.overrideWithValue(
              FauxInscriptionCandidat(cleOuverte: false),
            ),
          ],
          largeur: 360,
          hauteur: 800,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await capturerVue(tester, 'POSTULER-ICI-RETOUR/retour_${nom}_360');
      });
    }
  });
}
