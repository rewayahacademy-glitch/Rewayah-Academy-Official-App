// BOUTONS-GRISES-1 : les phrases nouvelles (ce qui manque, dit a l'appui
// d'un bouton jamais grise) ne coupent aucun mot a 320 px, texte x2, en
// francais et en arabe. La garde tourne toujours ; les PNG ne s'ecrivent
// qu'avec CAPTURE_DIR :
//
//   CAPTURE_DIR=docs/current/captures/BOUTONS-GRISES-1 \
//     flutter test test/capture/boutons_grises1_capture_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import '../features/coupe_mots_4/support_coupe_mots_4.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../teaching_core/a/support/hote_tc_a.dart';
import 'outil_capture.dart';

class _SansNiveau implements ServiceProgramme {
  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    VersionProgramme(
      id: 'v1',
      statut: StatutVersionProgramme.brouillon,
      numeroVersion: 1,
      creeParIdentifiant: 'adm',
      creeParPrenom: null,
      creeParNom: null,
      publieeAt: null,
      nombreNiveaux: 0,
      createdAt: DateTime(2026, 10, 10),
    ),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      const <NiveauProgramme>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _capturer(WidgetTester tester, String nom) async {
  if (dossierCapture != null) {
    debugPrint('PNG ${await capturerVue(tester, nom)}');
  }
}

void main() {
  preparerCoupeMots4();
  setUp(masquerRubanDebug);

  for (final AppLocale langue in languesCoupeMots4) {
    final String l = langue.name;

    testWidgets('depot : sans type puis sans photo, 320 x2 $l', (
      WidgetTester tester,
    ) async {
      await monterCoupeMots4(
        tester,
        () => const DepotPiecePage(),
        langue: langue,
        hauteur: 1600,
        surcharges: <Override>[
          serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
          selecteurFichierProvider.overrideWithValue(
            FauxSelecteurFichier(null),
          ),
        ],
      );
      await tester.tap(find.text(t.kyc.envoyer));
      await stabiliser(tester);
      expect(find.text(t.kyc.manqueType), findsOneWidget);
      verifierEcranSansMotCoupe(tester);
      await _capturer(tester, 'depot_manque_type_320x2_$l');

      await tester.ensureVisible(find.text(t.kyc.carteIdentite));
      await tester.tap(find.text(t.kyc.carteIdentite));
      await stabiliser(tester);
      await tester.tap(find.text(t.kyc.envoyer));
      await stabiliser(tester);
      expect(find.text(t.kyc.manquePhoto), findsOneWidget);
      verifierEcranSansMotCoupe(tester);
      await _capturer(tester, 'depot_manque_photo_320x2_$l');
    });

    testWidgets('programmes : version sans niveau, 320 x2 $l', (
      WidgetTester tester,
    ) async {
      await monterCoupeMots4(
        tester,
        () => const ProgrammesPage(),
        langue: langue,
        hauteur: 1600,
        surcharges: <Override>[
          serviceProgrammeProvider.overrideWithValue(_SansNiveau()),
        ],
      );
      await stabiliser(tester);
      final Finder publier = find.text(t.admin.programmes.publierVersion);
      await tester.ensureVisible(publier);
      await tester.tap(publier);
      await stabiliser(tester);
      expect(find.text(t.admin.programmes.publierSansNiveau), findsOneWidget);
      verifierEcranSansMotCoupe(tester);
      await _capturer(tester, 'programmes_sans_niveau_320x2_$l');
    });

    testWidgets('mes classes : Rejoindre en attente du reseau, 320 x2 $l', (
      WidgetTester tester,
    ) async {
      await monterCoupeMots4(
        tester,
        () => MesGroupesPage(onRejoindre: (_) {}),
        langue: langue,
        hauteur: 1600,
        surcharges: surchargesDemonstration(horsLigne: true),
      );
      final Finder rejoindre = find.text(LibellesGroupe.rejoindre).first;
      await tester.ensureVisible(rejoindre);
      await tester.tap(rejoindre);
      await stabiliser(tester);
      expect(find.text(t.tc.groupe.carte.entreeAttendReseau), findsOneWidget);
      // La garde porte sur la phrase nouvelle et son bouton : les titres de
      // carte de la demonstration (« Classe Al-Fatiha ») coupent deja leur
      // nom compose a 320 px x2, defaut anterieur hors de cette etape.
      verifierAucunMotCoupe(
        tester,
        find.byKey(const ValueKey<String>('carte-groupe-attente-entree')),
      );
      verifierAucunMotCoupe(tester, find.text(LibellesGroupe.rejoindre));
      await _capturer(tester, 'mes_classes_attente_reseau_320x2_$l');
    });

    testWidgets('espace de classe : acces en lecture, 320 x2 $l', (
      WidgetTester tester,
    ) async {
      await monterCoupeMots4(
        tester,
        () => EspaceGroupePage(
          groupeId: GroupesDemonstration.anNour,
          onRejoindre: (_) {},
        ),
        langue: langue,
        hauteur: 1600,
        surcharges: <Override>[
          ...surchargesDemonstration(),
          accesAppelantProvider.overrideWithValue(
            const AsyncLoading<AccesBeneficiaire?>(),
          ),
        ],
      );
      final Finder rejoindre = find.text(LibellesGroupe.rejoindre);
      await tester.ensureVisible(rejoindre);
      await tester.tap(rejoindre);
      await tester.pump();
      expect(find.text(t.tc.groupe.carte.entreeSePrepare), findsOneWidget);
      verifierEcranSansMotCoupe(tester);
      await _capturer(tester, 'espace_classe_entree_se_prepare_320x2_$l');
    });
  }
}
