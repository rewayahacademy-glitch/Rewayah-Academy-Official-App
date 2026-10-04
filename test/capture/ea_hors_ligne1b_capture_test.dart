// EA-HORS-LIGNE-1b : captures de preuve du bandeau hors ligne partage
// (« Pas de reseau. Ce qui est deja affiche reste consultable. »), de l'etat
// d'erreur des demandes admin (qui ne reemploie plus le bandeau), et du
// cahier enseignant hors ligne avec un depot en file.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Chaque capture verifie aussi qu'aucun mot n'est coupe ni tronque.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/features/admin_demandes/demandes_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

Demande _demande() => Demande(
  id: 'req1',
  sorte: SorteDemande.regle,
  sujetId: 'e1',
  sujetPrenom: 'Aissatou',
  sujetIdentifiant: 'STUDENT-AD-000001',
  motif: 'Elle décroche après quarante minutes.',
  roleDemandeur: AppRole.guardian,
  cleRegle: CleRegle.dureeSeance,
  valeurDemandee: 30,
  creeeLe: DateTime(2026, 9, 6, 9),
);

List<Override> _demandes({required bool horsLigne, bool panne = false}) =>
    <Override>[
      serviceAdminProvider.overrideWithValue(
        panne
            ? (FauxServiceAdmin()..erreurFile = StateError('panne'))
            : (FauxServiceAdmin()..file = <Demande>[_demande()]),
      ),
      serviceReglesProvider.overrideWithValue(
        FauxServiceRegles()
          ..parProfil['e1'] = <RegleProfil>[
            const RegleProfil(
              cle: CleRegle.dureeSeance,
              valeurEffective: 45,
              valeurPlateforme: 45,
            ),
          ],
      ),
      serviceReseauProvider.overrideWithValue(
        FauxServiceReseau(horsLigneRendu: horsLigne),
      ),
    ];

Widget _sens(Widget ecran, TextDirection sens) =>
    Directionality(textDirection: sens, child: ecran);

void main() {
  group('Capture : EA-HORS-LIGNE-1b', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Le bandeau, pose par PageShell sur un ecran charge (la file des
    // demandes) : 320 a 100 % et 200 %, 390 clair et sombre, 1440, RTL.
    for (final (String, Size, ThemeMode, double, TextDirection) cas
        in <(String, Size, ThemeMode, double, TextDirection)>[
          (
            'bandeau_320_clair',
            const Size(320, 700),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            'bandeau_320x2_clair',
            const Size(320, 900),
            ThemeMode.light,
            2,
            TextDirection.ltr,
          ),
          (
            'bandeau_390_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            'bandeau_390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            1,
            TextDirection.ltr,
          ),
          (
            'bandeau_1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            'bandeau_390_rtl_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.rtl,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            _sens(const DemandesPage(), cas.$5),
            surcharges: _demandes(horsLigne: true),
            themeMode: cas.$3,
            echelleTexte: cas.$4,
          ),
        );
        await stabiliser(tester);
        expect(find.text(t.reseau.horsLigne), findsOneWidget);
        verifierAucunMotCoupe(tester, find.byType(OfflineBanner));
        debugPrint('PNG ${await capturer(tester, 'ea_hl1b_${cas.$1}')}');
      });
    }

    // L'etat d'erreur des demandes, en ligne : un message propre, sans
    // « Pas de reseau » ni « consultable ».
    for (final (String, Size, double) cas in <(String, Size, double)>[
      ('erreur_demandes_320x2_clair', const Size(320, 900), 2),
      ('erreur_demandes_390_clair', const Size(390, 844), 1),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            const DemandesPage(),
            surcharges: _demandes(horsLigne: false, panne: true),
            echelleTexte: cas.$3,
          ),
        );
        await stabiliser(tester);
        expect(find.text(t.admin.demandes.erreurFile), findsOneWidget);
        expect(find.textContaining(t.reseau.horsLigne), findsNothing);
        verifierAucunMotCoupe(tester, find.byType(EmptyState));
        debugPrint('PNG ${await capturer(tester, 'ea_hl1b_${cas.$1}')}');
      });
    }

    // Le cahier enseignant hors ligne, un depot en file : le bandeau et le
    // marqueur « En attente d'envoi » ne se contredisent pas.
    for (final (String, Size, ThemeMode, double) cas
        in <(String, Size, ThemeMode, double)>[
          (
            'cahier_en_file_390_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
          ),
          (
            'cahier_en_file_390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            1,
          ),
          (
            'cahier_en_file_320x2_clair',
            const Size(320, 1100),
            ThemeMode.light,
            2,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            const CoquilleEnseignantDemo(
              ecran: EcranDemoEnseignant.cahier,
              etat: EtatDemoEnseignant.horsLigne,
            ),
            // La file locale en memoire : la base drift reelle demande un
            // dossier temporaire que `flutter test` n'a pas.
            surcharges: <Override>[
              depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
            ],
            themeMode: cas.$3,
            echelleTexte: cas.$4,
          ),
        );
        await stabiliser(tester);
        final Finder valider = find.byKey(
          const ValueKey<String>('cahier-valider'),
        );
        await tester.ensureVisible(valider);
        await stabiliser(tester);
        await tester.tap(valider);
        await stabiliser(tester);
        // La soumission de demonstration repond apres 600 ms.
        await tester.pump(const Duration(milliseconds: 700));
        await stabiliser(tester);
        expect(find.text(t.reseau.horsLigne), findsOneWidget);
        expect(find.text(t.enseignant.cahier.enFileTitre), findsOneWidget);
        verifierAucunMotCoupe(tester, find.byType(OfflineBanner));
        debugPrint('PNG ${await capturer(tester, 'ea_hl1b_${cas.$1}')}');
      });
    }
  });
}
