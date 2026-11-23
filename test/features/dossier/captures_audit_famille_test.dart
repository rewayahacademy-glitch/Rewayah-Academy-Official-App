// AUDIT-FAMILLE (22/11/2026) : la page d'attente d'une famille (refusee avec sa
// raison et la voie « ecrire a la direction » ; a completer) et la connexion
// avec la ligne d'aide, 390 et 1440, francais et arabe, clair et sombre.
// Donnees de test seulement. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/capacites/support_public.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/dossier/apprenants_demande.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';
import '../../support/monter_recrutement.dart';

const CanalSupport _aide = CanalSupport(
  nature: NatureCanalSupport.courriel,
  adresse: 'support@rewayahacademy.com',
);

const EtatDossier _famille = EtatDossier(
  profilExiste: true,
  role: AppRole.guardian,
  statutCompte: AccountStatus.pendingKyc,
  accuseSigne: true,
  contratSigne: true,
  codeConduiteSigne: true,
  pieceDeposee: false,
  usage: UsageTitulaire.famille,
);

void main() {
  group('Capture : AUDIT-FAMILLE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (
          String nom,
          AppLocale locale,
          TextDirection sens,
          double largeur,
          double hauteur,
          ThemeMode theme,
          IssueDemandeFamille issue,
        )
        in <
          (
            String,
            AppLocale,
            TextDirection,
            double,
            double,
            ThemeMode,
            IssueDemandeFamille,
          )
        >[
          (
            'attente_refusee_fr_390_clair',
            AppLocale.fr,
            TextDirection.ltr,
            390,
            1400,
            ThemeMode.light,
            IssueDemandeFamille.refusee,
          ),
          (
            'attente_refusee_fr_1440_sombre',
            AppLocale.fr,
            TextDirection.ltr,
            1440,
            900,
            ThemeMode.dark,
            IssueDemandeFamille.refusee,
          ),
          (
            'attente_refusee_ar_390_clair',
            AppLocale.ar,
            TextDirection.rtl,
            390,
            1400,
            ThemeMode.light,
            IssueDemandeFamille.refusee,
          ),
          (
            'attente_a_completer_fr_1440_clair',
            AppLocale.fr,
            TextDirection.ltr,
            1440,
            900,
            ThemeMode.light,
            IssueDemandeFamille.aCompleter,
          ),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = _famille;
        await monterRecrutement(
          tester,
          chemin: '/attente',
          ecran: (_) => const AttentePage(),
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
            sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            baseLocaleEnMemoire(),
            lectureApprenantsDemandeProvider.overrideWithValue(
              () async => const <ApprenantDemande>[
                (prenom: 'Yasmine', age: 9, titulaire: false),
              ],
            ),
            lectureDemandeFamilleProvider.overrideWithValue(
              () async => (
                issue: issue,
                precisions: issue == IssueDemandeFamille.aCompleter
                    ? 'Quel est le niveau exact de Yasmine ?'
                    : null,
                motif: issue == IssueDemandeFamille.refusee
                    ? 'refus_niveau'
                    : null,
              ),
            ),
            lectureCanalSupportPublicProvider.overrideWithValue(
              () async => _aide,
            ),
          ],
          largeur: largeur,
          hauteur: hauteur,
          direction: sens,
          themeMode: theme,
        );
        await laisser(tester);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }

    for (final (String nom, double largeur, double hauteur, AppLocale locale)
        in <(String, double, double, AppLocale)>[
          ('connexion_aide_fr_390', 390, 1500, AppLocale.fr),
          ('connexion_aide_fr_1440', 1440, 900, AppLocale.fr),
          ('connexion_aide_ar_390', 390, 1500, AppLocale.ar),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await monterRecrutement(
          tester,
          chemin: '/connexion',
          ecran: (_) => const ConnexionPage(),
          surcharges: <Override>[
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
            demoAuthActiveProvider.overrideWithValue(false),
            lectureCanalSupportPublicProvider.overrideWithValue(
              () async => _aide,
            ),
          ],
          largeur: largeur,
          hauteur: hauteur,
          direction: locale == AppLocale.ar ? TextDirection.rtl : null,
        );
        await laisser(tester);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
