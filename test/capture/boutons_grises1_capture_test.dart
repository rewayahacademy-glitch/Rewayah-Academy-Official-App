// BOUTONS-GRISES-1 : les phrases nouvelles (ce qui manque, dit a l'appui
// d'un bouton jamais grise) ne coupent aucun mot a 320 px, texte x2, en
// francais et en arabe. La garde tourne toujours ; les PNG ne s'ecrivent
// qu'avec CAPTURE_DIR :
//
//   CAPTURE_DIR=docs/current/captures/BOUTONS-GRISES-1 \
//     flutter test test/capture/boutons_grises1_capture_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../features/coupe_mots_4/support_coupe_mots_4.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
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
      expect(find.text(t.admin.programmes.publierSansNiveau), findsOneWidget);
      verifierEcranSansMotCoupe(tester);
      await _capturer(tester, 'programmes_sans_niveau_320x2_$l');
    });
  }
}
