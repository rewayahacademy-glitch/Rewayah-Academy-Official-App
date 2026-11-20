// ACCUEIL-CANDIDAT (PE-B4, 20/11/2026) : la page d'attente (`/attente`) ne
// delegue a l'accueil a trois onglets QUE le candidat enseignant. Ce test
// capture ce que voient les autres : une famille, un eleve adulte, un
// enseignant d'avant les candidatures, un candidat au compte suspendu.
//
// Preuve « avant | apres » : la meme commande, lancee sur `main` puis sur la
// branche, doit rendre des images identiques, octet pour octet
// (`docs/current/captures/E2E/pe-accueil-candidat/attente-avant` et
// `attente-apres`). Jamais sans `CAPTURE_DIR`.
//
// CAPTURE_DIR=... flutter test --no-pub
//   test/features/candidature/attente_inchangee_capture_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/dossier/apprenants_demande.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

/// Le sous-dossier de sortie : `ATTENTE_DOSSIER` (« avant » sur main), ou
/// « apres » par defaut.
final String _dossier =
    Platform.environment['ATTENTE_DOSSIER'] ??
    'pe-accueil-candidat/attente-apres';

EtatDossier _etat({
  AppRole role = AppRole.guardian,
  AccountStatus statut = AccountStatus.pendingKyc,
  bool accords = true,
  bool piece = false,
  UsageTitulaire? usage,
  CandidatureDossier candidature = CandidatureDossier.aucune,
}) => EtatDossier(
  profilExiste: true,
  role: role,
  statutCompte: statut,
  accuseSigne: accords,
  contratSigne: accords,
  codeConduiteSigne: true,
  pieceDeposee: piece,
  usage: usage,
  candidature: candidature,
);

Future<void> _monter(
  WidgetTester tester,
  EtatDossier etat,
  Size taille, {
  List<ApprenantDemande> apprenants = const <ApprenantDemande>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attente,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) => const AttentePage(),
        ),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(
          FauxServiceDossier()..etatRendu = etat,
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        lectureApprenantsDemandeProvider.overrideWithValue(
          () async => apprenants,
        ),
        lectureDemandeFamilleProvider.overrideWithValue(() async => null),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('captures : la page d attente hors candidat enseignant', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    final Map<String, (EtatDossier, List<ApprenantDemande>)> cas =
        <String, (EtatDossier, List<ApprenantDemande>)>{
          // Une famille dont la demande est en cours : sa demande est une
          // candidature cote serveur (type famille), jamais une salle.
          'famille-demande-en-cours': (
            _etat(
              usage: UsageTitulaire.famille,
              candidature: const CandidatureDossier(
                existe: true,
                etape: EtapeCandidature.recue,
              ),
            ),
            const <ApprenantDemande>[
              (prenom: 'Yasmine', age: 9, titulaire: false),
              (prenom: 'Fatou', age: null, titulaire: true),
            ],
          ),
          // Une famille qui a encore ses accords a lire.
          'famille-accords-a-lire': (
            _etat(accords: false, usage: UsageTitulaire.famille),
            const <ApprenantDemande>[],
          ),
          // Un eleve adulte (« Moi uniquement ») en attente.
          'eleve-adulte-en-attente': (
            _etat(
              usage: UsageTitulaire.moi,
              candidature: const CandidatureDossier(
                existe: true,
                etape: EtapeCandidature.prequalification,
              ),
            ),
            const <ApprenantDemande>[
              (prenom: 'Idriss', age: null, titulaire: true),
            ],
          ),
          // Un enseignant d'avant les candidatures : dossier incomplet.
          'enseignant-sans-candidature': (
            _etat(role: AppRole.teacher, accords: false),
            const <ApprenantDemande>[],
          ),
          // Un candidat enseignant dont le compte est suspendu : la page
          // d'avant, jamais l'accueil a trois onglets.
          'candidat-compte-suspendu': (
            _etat(
              role: AppRole.teacher,
              statut: AccountStatus.disabled,
              piece: true,
              candidature: const CandidatureDossier(
                existe: true,
                etape: EtapeCandidature.prequalification,
                etat: EtatCandidature.enExamen,
                version: 4,
              ),
            ),
            const <ApprenantDemande>[],
          ),
        };

    for (final MapEntry<String, (EtatDossier, List<ApprenantDemande>)> c
        in cas.entries) {
      for (final (Size taille, String s) in <(Size, String)>[
        (const Size(390, 844), '390'),
        (const Size(1440, 900), '1440'),
      ]) {
        testWidgets('${c.key} $s', (WidgetTester tester) async {
          await _monter(tester, c.value.$1, taille, apprenants: c.value.$2);
          await capturerVue(tester, '$_dossier/${c.key}-$s');
        });
      }
    }
  }, skip: sautSansCapture);
}
