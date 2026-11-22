// R3 du lot ONBOARDING-PRAXIS (directeur, 22/11/2026) : les ecrans cles du
// questionnaire avec Praxis, a 390 et 1440, en clair, pour les poser a cote de
// la maquette validee (docs/current/maquettes/onboarding-praxis/prototype.html).
// Donnees de test ; jamais sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md) :
//   CAPTURE_DIR=docs/current/captures/E2E/onboarding-praxis \
//     flutter test test/capture/onboarding_praxis_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart'
    show serviceAuthProvider;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart'
    show sourceSessionProvider;
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/onboarding_donnees.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

/// Une famille : Yasmine (9 ans, debutante) et Bilal (12 ans, a memorise des
/// sourates), tout repondu.
const QuestionnaireInscription _famille = QuestionnaireInscription(
  commence: true,
  apprendre: true,
  pourQui: PourQui.plusieurs,
  apprenants: <ApprenantQuestionnaire>[
    ApprenantQuestionnaire(
      prenom: 'Yasmine',
      age: 9,
      genre: Genre.femme,
      niveau: NiveauDeclare.debutLettres,
      objectif: ObjectifOnboarding.priere,
    ),
    ApprenantQuestionnaire(
      prenom: 'Bilal',
      age: 12,
      genre: Genre.homme,
      niveau: NiveauDeclare.memorisationPartielle,
      quantite: QuantiteMemorisee.quelquesSourates,
      sourates: <String>['fatiha', 'nas', 'falaq'],
      objectif: ObjectifOnboarding.memoriser,
    ),
  ],
  langue: 'francais',
  langueSecours: 'poular',
  source: SourceConnaissance.mosquee,
);

void main() {
  group('Captures ONBOARDING-PRAXIS', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    const List<(String, String, bool)> ecrans = <(String, String, bool)>[
      ('01_accueil', 'accueil', false),
      ('02_garde', 'garde', false),
      ('03_enseigner', 'enseigner', false),
      ('04_pour_qui', 'pourQui', false),
      ('05_prenom', 'prenom-1', true),
      ('06_age', 'age-1', true),
      ('07_famille', 'famille', true),
      ('08_niveau', 'niveau-1', true),
      ('09_lecture', 'lecture-1', true),
      ('10_memorise', 'memorise-1', true),
      ('11_detail', 'detail-1', true),
      ('12_objectif', 'objectif-1', true),
      ('13_depart', 'depart', true),
      ('14_langue', 'langue', true),
      ('15_langue_secours', 'langueSecours', true),
      ('16_chemin', 'chemin', true),
      ('17_recap', 'recap', true),
      ('18_acces', codeEtapeAcces, true),
    ];
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final (String nom, String code, bool repondu) in ecrans) {
        final String fichier = '${nom}_${taille.width.toInt()}';
        testWidgets(fichier, (WidgetTester tester) async {
          effacerMemoireAppareil(clefQuestionnaire);
          ecrireMemoireAppareil(
            clefQuestionnaire,
            (repondu
                    ? _famille
                    : const QuestionnaireInscription(
                        commence: true,
                        apprendre: true,
                      ))
                .versTexte(),
          );
          addTearDown(() => effacerMemoireAppareil(clefQuestionnaire));
          tester.view.physicalSize = taille;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hoteRoutant(
              depart: '${Routes.commencer}?etape=$code',
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(FausseSourceSession()),
                serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
              ],
              routes: <RouteBase>[
                GoRoute(
                  path: Routes.commencer,
                  builder: (BuildContext _, GoRouterState etat) =>
                      QuestionnairePage(
                        code: etat.uri.queryParameters['etape'],
                      ),
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          debugPrint('PNG ${await capturerVue(tester, fichier)}');
        });
      }
    }
  });
}
