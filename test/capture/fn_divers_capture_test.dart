// Lot 13 FN-DIVERS (06/11/2026) : captures de preuve, 390 x 844 et
// 1440 x 900, francais et arabe, clair. Jamais sans `CAPTURE_DIR`.
//
// - FN-111 : « Se connecter » ouverte par un lien demande sur un autre
//   appareil (`?code=` sans cle de verification) ;
// - FN-101 : un texte nomme `.pdf` refuse avant l'envoi ;
// - FN-102 : la signature du contrat au nom du compte, en lecture seule ;
// - FN-027 : la carte de la Journee pendant la seance, le temps restant.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/recrutement/port_signature_contrat.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/recrutement/signature_contrat_page.dart';

import '../support/demo/recrutement_demo.dart';
import '../support/harnais.dart';
import '../support/monter_recrutement.dart';
import 'outil_capture.dart';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: 't1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

Future<void> _vue(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _sens(TextDirection? sens, Widget enfant) =>
    sens == null ? enfant : Directionality(textDirection: sens, child: enfant);

Future<void> _photo(WidgetTester tester, String nom) async {
  await stabiliser(tester);
  debugPrint('PNG ${await capturerVue(tester, nom)}');
}

void main() {
  group('Capture : lot 13 FN-DIVERS', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String s = '${langue.languageCode}_${taille.width.toInt()}';
        final TextDirection? sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : null;

        testWidgets('FN-111 connexion $s', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _vue(tester, taille);
          await tester.pumpWidget(
            hote(
              _sens(
                sens,
                ConnexionPage(
                  urlRetour: Uri.parse(
                    'https://app.rewayahacademy.com/?code=8f1c2d3e-0000-4000-8000-000000000001#/connexion',
                  ),
                ),
              ),
              surcharges: <Override>[
                serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
                demoAuthActiveProvider.overrideWithValue(false),
                environnementConnexionProvider.overrideWithValue('production'),
              ],
            ),
          );
          await _photo(tester, 'fn111_connexion_lien_ailleurs_$s');
        });

        testWidgets('FN-101 piece $s', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _vue(tester, taille);
          await tester.pumpWidget(
            hoteRoutant(
              depart: Routes.attentePiece,
              direction: sens,
              routes: <RouteBase>[
                GoRoute(
                  path: Routes.attentePiece,
                  builder: (BuildContext _, GoRouterState _) =>
                      const DepotPiecePage(),
                ),
                temoin(Routes.attente),
              ],
              surcharges: <Override>[
                serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
                serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
                selecteurFichierProvider.overrideWithValue(
                  FauxSelecteurFichier(
                    PieceAEnvoyer(
                      octets: Uint8List.fromList(
                        'ceci est un texte, pas un PDF'.codeUnits,
                      ),
                      nomFichier: 'piece.pdf',
                      type: TypePiece.carteIdentite,
                    ),
                  ),
                ),
              ],
            ),
          );
          await stabiliser(tester);
          final Finder carte = find.text(t.kyc.carteIdentite);
          await tester.ensureVisible(carte);
          await stabiliser(tester);
          await tester.tap(carte);
          await stabiliser(tester);
          await tester.tap(find.text(t.kyc.choisirFichier));
          await _photo(tester, 'fn101_piece_refusee_$s');
        });

        testWidgets('FN-102 signature $s', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterRecrutement(
            tester,
            chemin: Routes.attenteContrat,
            autres: <String>[Routes.attente],
            ecran: (_) => const SignatureContratPage(),
            surcharges: <Override>[
              portSignatureContratProvider.overrideWithValue(
                SignatureContratDemo(),
              ),
              serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
            ],
            largeur: taille.width,
            hauteur: taille.height,
            direction: sens,
          );
          final Finder champ = find.byKey(
            const ValueKey<String>('signature-nom'),
          );
          await tester.ensureVisible(champ);
          await _photo(tester, 'fn102_signature_nom_du_compte_$s');
        });

        testWidgets('FN-027 journee $s', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _vue(tester, taille);
          await tester.pumpWidget(
            hote(
              _sens(sens, const JourneePage()),
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(
                  FausseSourceSession(_sessionEnseignant),
                ),
                serviceEnseignantProvider.overrideWithValue(
                  FauxServiceEnseignant()
                    ..seancesRendues = <SeanceEnseignant>[
                      seanceDeTest(
                        id: 'an-nour',
                        debut: DateTime(2026, 9, 28, 17, 30),
                        statut: StatutSeance.enCours,
                        nbParticipants: 4,
                        groupeId: 'g-an-nour',
                        groupeLibelle: 'An-Nour',
                      ),
                    ],
                ),
                serviceMatchingProvider.overrideWithValue(
                  FauxServiceMatching(),
                ),
                serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
                servicePriereProvider.overrideWithValue(FauxServicePriere()),
                servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
                servicePresenceProvider.overrideWithValue(
                  FauxServicePresence(),
                ),
                serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
                maintenantJourneeProvider.overrideWithValue(
                  () => DateTime(2026, 9, 28, 17, 40),
                ),
              ],
            ),
          );
          await _photo(tester, 'fn027_journee_temps_restant_$s');
        });
      }
    }
  });
}
