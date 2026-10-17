// Captures de preuve de COUPE-MOTS-4, dans docs/current/captures/COUPE-MOTS-4/.
// Sautees sans CAPTURE_DIR. CAPTURE_PREFIXE (« apres » par defaut, « avant »
// pour l'ancien code) prefixe chaque PNG.
//
//   CAPTURE_DIR=docs/current/captures/COUPE-MOTS-4 \
//     flutter test test/capture/coupe_mots_4_capture_test.dart
//
// (1) cartes de choix : compte rendu du Controleur, fiche eleve Interface ;
// (2) barre basse de l'Interface guidee (Controleur, enseignant) ;
// (3) identifiant de Comptes ; (4) « Pourquoi ce changement ? ».
// 320 px texte x2, francais (LTR) et arabe (RTL) ; 390 et 1440 pour la
// non-regression des cartes.
// Reprise (relecture adverse) : feuille des regles d'un eleve (« Plateforme
// : 60 min »), depot de la piece, compte rendu et inscription en Interface
// guidee, en clair et en sombre ; filtre `--plain-name reprise`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_demandes/demandes_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';

import '../features/coupe_mots_4/support_coupe_mots_4.dart';
import '../fixtures/tuteur/foyers.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
  missionId: 'mission-A',
);

class _Envoi implements EnvoiCompteRendu {
  @override
  Future<void> transmettreVisite(String seanceId) async {}

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) async {}

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) async {}
}

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    for (final (String id, String? prenom) in <(String, String?)>[
      ('TEACHER-AS-000001', 'Aicha'),
      ('TEACHER-AS-000002', null),
    ])
      CompteAdmin(
        profilId: id,
        identifiant: id,
        prenom: prenom,
        nom: prenom == null ? null : 'Sow',
        role: AppRole.teacher,
        etat: AccountStatus.pendingKyc,
        inscritLe: DateTime.now().subtract(const Duration(days: 7)),
        accesJusquAu: null,
        foyerId: null,
        piece: EtatPiece.aucune,
        contrats: 2,
        aEnseignant: false,
        enfantsDuFoyer: 0,
      ),
  ];
}

/// Ramene la premiere carte de choix en haut de la vue avant la capture.
Future<void> _versLesCartes(WidgetTester tester) async {
  final Finder cartes = find.byType(ChoiceCardGroup);
  if (cartes.evaluate().isNotEmpty) {
    await tester.ensureVisible(cartes.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Capture COUPE-MOTS-4', skip: sautSansCapture, () {
    preparerCoupeMots4();
    setUp(masquerRubanDebug);

    for (final AppLocale langue in languesCoupeMots4) {
      final String l = langue.name;

      for (final (double, double, double) vue in <(double, double, double)>[
        (320, 1600, 2),
        (390, 1200, 1),
        (1440, 900, 1),
      ]) {
        final String taille = '${vue.$1.toInt()}x${vue.$3.toInt()}';
        testWidgets('compte rendu $l $taille', (WidgetTester tester) async {
          await monterCoupeMots4(
            tester,
            () => CompteRenduControlePage(seanceId: _visite.seanceId),
            langue: langue,
            largeur: vue.$1,
            hauteur: vue.$2,
            echelle: vue.$3,
            surcharges: <Override>[
              visitesObserveesProvider.overrideWith(
                () => VisitesObservees(<String, CompteRenduEnSuspens>{
                  _visite.seanceId: _visite,
                }),
              ),
              envoiCompteRenduProvider.overrideWithValue(_Envoi()),
            ],
          );
          await tester.pumpAndSettle();
          await _versLesCartes(tester);
          debugPrint(
            'PNG ${await capturerVue(tester, '${_prefixe}_compte_rendu_${taille}_$l')}',
          );
        });
      }

      testWidgets('fiche eleve interface $l', (WidgetTester tester) async {
        await monterRouteCoupeMots4(
          tester,
          role: AppRole.guardian,
          depart: Routes.ficheEleveSousPage(FoyersFictifs.a1.id, 'interface'),
          langue: langue,
          hauteur: 1400,
          appairage: FauxServiceAppairage()
            ..elevesRendus = List<EleveDuFoyer>.of(FoyersFictifs.foyerA),
        );
        await _versLesCartes(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, '${_prefixe}_fiche_interface_320x2_$l')}',
        );
      });

      for (final AppRole role in <AppRole>[
        AppRole.controller,
        AppRole.teacher,
      ]) {
        testWidgets('barre guidee ${role.name} $l', (
          WidgetTester tester,
        ) async {
          await monterCoupeMots4(
            tester,
            () => NavShell(
              destinations: destinationsPour(
                role: role,
                mode: InterfaceMode.enfant,
              ),
              indexActif: 0,
              onAller: (String _) {},
              child: const Scaffold(body: SizedBox.expand()),
            ),
            langue: langue,
            interface: InterfaceMode.enfant,
            hauteur: 640,
          );
          debugPrint(
            'PNG ${await capturerVue(tester, '${_prefixe}_barre_guidee_${role.name}_320x2_$l')}',
          );
        });
      }

      testWidgets('comptes $l', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => const ComptesPage(),
          langue: langue,
          hauteur: 1400,
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(_Comptes()),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        );
        debugPrint(
          'PNG ${await capturerVue(tester, '${_prefixe}_comptes_320x2_$l')}',
        );
      });

      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nuance = theme == ThemeMode.dark ? '_sombre' : '';

        testWidgets('reprise feuille des regles $l$nuance', (
          WidgetTester tester,
        ) async {
          await monterCoupeMots4(
            tester,
            () => const Scaffold(
              body: FeuilleRegles(profilId: 'e1', prenom: 'Aissatou'),
            ),
            langue: langue,
            theme: theme,
            hauteur: 1400,
            surcharges: <Override>[
              serviceReglesProvider.overrideWithValue(
                FauxServiceRegles()
                  ..parProfil['e1'] = const <RegleProfil>[
                    RegleProfil(
                      cle: CleRegle.dureeSeance,
                      valeurEffective: 45,
                      valeurPlateforme: 60,
                    ),
                    RegleProfil(
                      cle: CleRegle.minimumPayable,
                      valeurEffective: 45,
                      valeurPlateforme: 45,
                    ),
                  ],
              ),
            ],
          );
          await tester.pumpAndSettle();
          debugPrint(
            'PNG ${await capturerVue(tester, '${_prefixe}_feuille_regles_320x2_$l$nuance')}',
          );
        });

        testWidgets('reprise depot de la piece guidee $l$nuance', (
          WidgetTester tester,
        ) async {
          await monterCoupeMots4(
            tester,
            () => const DepotPiecePage(),
            langue: langue,
            theme: theme,
            interface: InterfaceMode.enfant,
            hauteur: 2000,
            surcharges: <Override>[
              serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
              selecteurFichierProvider.overrideWithValue(
                FauxSelecteurFichier(null),
              ),
            ],
          );
          await tester.pumpAndSettle();
          debugPrint(
            'PNG ${await capturerVue(tester, '${_prefixe}_depot_piece_guidee_320x2_$l$nuance')}',
          );
        });
      }

      testWidgets('reprise compte rendu guidee $l', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => CompteRenduControlePage(seanceId: _visite.seanceId),
          langue: langue,
          interface: InterfaceMode.enfant,
          hauteur: 2400,
          surcharges: <Override>[
            visitesObserveesProvider.overrideWith(
              () => VisitesObservees(<String, CompteRenduEnSuspens>{
                _visite.seanceId: _visite,
              }),
            ),
            envoiCompteRenduProvider.overrideWithValue(_Envoi()),
          ],
        );
        await tester.pumpAndSettle();
        debugPrint(
          'PNG ${await capturerVue(tester, '${_prefixe}_compte_rendu_guidee_320x2_$l')}',
        );
      });

      testWidgets('reprise inscription usage guidee $l', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => const UsageEtape(),
          langue: langue,
          interface: InterfaceMode.enfant,
          hauteur: 1600,
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
            sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        );
        await tester.pumpAndSettle();
        debugPrint(
          'PNG ${await capturerVue(tester, '${_prefixe}_inscription_usage_guidee_320x2_$l')}',
        );
      });
    }
  });
}
