// CAP29-F : le rendu d'un support selon son type.
//
// Ce que le test prouve : une image se rend depuis l'artefact de la version
// publiee ; un artefact absent est dit sans panne ; des octets introuvables
// ouvrent un etat d'echec avec relance (jamais un ecran vide) ; le Coran n'est
// jamais rendu ici ; PDF, texte structure et lecon disent honnetement qu'aucun
// lecteur n'existe ; une ressource sans version publiee ne propose rien ;
// l'enseignant entre dans la bibliotheque ; 320 px, texte x2, LTR et RTL.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/rendu_ressource.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../teaching_core/b/faux/faux_ports_b.dart';
import '../../teaching_core/b/support/hote_b.dart';

/// Un PNG de 1 x 1 pixel.
const List<int> _png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59, 0xE7, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

DownloadAsset _image() => DownloadAsset(
  id: 'a1',
  resourceVersionId: 'v1',
  format: FormatArtefact.image,
  cleStockage: 'supports/demo.png',
  tailleOctets: _png.length,
  origine: OrigineArtefact.importeTelQuel,
  creeLeUtc: DateTime.utc(2026, 9, 1),
);

List<Override> _surcharges({
  required TypeRessource type,
  bool avecArtefact = false,
  bool avecOctets = false,
  bool publiee = true,
}) => surchargesCatalogue(
  ressources: <LibraryResource>[
    ressource(
      id: 'r1',
      titre: 'Tableau des lettres',
      type: type,
      versionCourante: publiee ? 'v1' : null,
    ),
  ],
  versions: publiee
      ? <String, List<ResourceVersion>>{
          'r1': <ResourceVersion>[version(id: 'v1', resourceId: 'r1')],
        }
      : const <String, List<ResourceVersion>>{},
  artefacts: avecArtefact
      ? <String, List<DownloadAsset>>{
          'v1': <DownloadAsset>[_image()],
        }
      : const <String, List<DownloadAsset>>{},
  octets: avecOctets
      ? <String, List<int>>{'supports/demo.png': _png}
      : const <String, List<int>>{},
);

Future<void> _monter(WidgetTester tester, List<Override> surcharges) async {
  fenetreHaute(tester);
  await tester.pumpWidget(
    hoteB(const DetailRessourcePage(resourceId: 'r1'), surcharges: surcharges),
  );
  await tester.pumpAndSettle();
}

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

void main() {
  group('image', () {
    testWidgets('rendue depuis l\'artefact de la version publiee', (
      tester,
    ) async {
      await _monter(
        tester,
        _surcharges(
          type: TypeRessource.image,
          avecArtefact: true,
          avecOctets: true,
        ),
      );
      expect(_cle('rendu-image'), findsOneWidget);
      expect(_cle('rendu-echec'), findsNothing);
    });

    testWidgets('sans artefact : dit sans panne', (tester) async {
      await _monter(tester, _surcharges(type: TypeRessource.image));
      expect(_cle('rendu-sans-lecteur'), findsOneWidget);
      expect(_cle('rendu-echec'), findsNothing);
    });

    testWidgets('octets introuvables : echec avec relance', (tester) async {
      await _monter(
        tester,
        _surcharges(type: TypeRessource.image, avecArtefact: true),
      );
      expect(_cle('rendu-echec'), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.rendu.imageInaccessible), findsOne);
      expect(_cle('rendu-reessayer'), findsOneWidget);
      // La relance rend la meme issue tant que rien ne change : pas de boucle.
      await tester.tap(_cle('rendu-reessayer'));
      await tester.pumpAndSettle();
      expect(_cle('rendu-echec'), findsOneWidget);
    });
  });

  group('autres types', () {
    testWidgets('Coran : jamais rendu ici', (tester) async {
      await _monter(tester, _surcharges(type: TypeRessource.quran));
      expect(find.text(t.tc.bibliotheque.detail.renduCoran), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    for (final TypeRessource type in <TypeRessource>[
      TypeRessource.pdf,
      TypeRessource.texteStructure,
      TypeRessource.lecon,
    ]) {
      testWidgets('${type.name} : aucun lecteur, dit honnetement', (
        tester,
      ) async {
        await _monter(tester, _surcharges(type: type));
        expect(_cle('rendu-sans-lecteur'), findsOneWidget);
        expect(
          find.text(t.tc.bibliotheque.detail.apercuIndisponible),
          findsOneWidget,
        );
      });
    }

    testWidgets('sans version publiee : rien a ouvrir', (tester) async {
      await _monter(
        tester,
        _surcharges(type: TypeRessource.image, publiee: false),
      );
      expect(find.text(t.tc.bibliotheque.detail.sansVersion), findsOneWidget);
      expect(find.byType(RenduRessource), findsOneWidget);
      expect(_cle('rendu-image'), findsNothing);
    });
  });

  group('adaptation', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          hoteB(
            Directionality(
              textDirection: d,
              child: const MediaQuery(
                data: MediaQueryData(
                  size: Size(320, 640),
                  textScaler: TextScaler.linear(2),
                ),
                child: DetailRessourcePage(resourceId: 'r1'),
              ),
            ),
            surcharges: _surcharges(
              type: TypeRessource.image,
              avecArtefact: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
