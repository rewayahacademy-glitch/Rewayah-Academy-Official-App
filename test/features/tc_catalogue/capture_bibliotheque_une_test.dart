// Captures du lot BIBLIOTHEQUE-UNE : la bibliotheque de l'eleve (contenu, vide,
// erreur, hors ligne, arabe, sombre), la fiche d'un lien externe et d'un audio,
// et le formulaire de la direction. Par le VRAI routeur.
//
// CAPTURE_DIR=docs/current/captures/E2E/bibliotheque-une flutter test \
//   test/features/tc_catalogue/capture_bibliotheque_une_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart'
    show horsLigneProvider;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart';
import '../../support/demo/bibliotheque_admin_demo.dart';
import '../../support/harnais.dart' hide FauxServiceReseau;
import '../../support/monter_admin_demo.dart' as admin;
import '../../teaching_core/b/faux/faux_ports_b.dart';

class _Liens extends ArtefactsLocaux {
  @override
  bool get lienLectureServi => true;
}

final List<LibraryResource> _catalogue = <LibraryResource>[
  ressource(
    id: 'coran',
    titre: 'Le Coran',
    type: TypeRessource.quran,
    langue: 'ar',
    description: 'Le Coran en entier, page par page.',
  ),
  ressource(
    id: 'audio',
    titre: "Les lettres, à l'oreille",
    type: TypeRessource.audio,
    description: 'La voix de la direction, lettre par lettre.',
    ordre: 1,
  ),
  ressource(
    id: 'pdf',
    titre: 'Le livre de lecture',
    type: TypeRessource.pdf,
    description: 'Les pages du livre, une par une.',
    ordre: 2,
  ),
  ressource(
    id: 'lien',
    titre: 'Un site de référence',
    type: TypeRessource.lienExterne,
    description: 'Un site pour aller plus loin.',
    lienExterne: 'https://exemple.org/page',
    rayon: codeRayonPlusLoin,
  ),
  ressource(
    id: 'video',
    titre: 'Une vidéo du cours',
    type: TypeRessource.video,
    description: 'La vidéo du cours, par lien.',
    lienExterne: 'https://video.exemple.org/v/1',
    rayon: codeRayonPlusLoin,
  ),
];

List<Override> _surcharges({
  List<LibraryResource>? ressources,
  PortCatalogue? catalogue,
  bool horsLigne = false,
  bool navigateur = false,
}) {
  final List<LibraryResource> r = ressources ?? _catalogue;
  final ArtefactsLocaux artefacts = _Liens();
  return <Override>[
    portCatalogueProvider.overrideWithValue(
      catalogue ?? CatalogueLocal(ressources: r),
    ),
    portVersionsRessourceProvider.overrideWithValue(
      VersionsLocales(
        parRessource: <String, List<ResourceVersion>>{
          for (final LibraryResource x in r)
            x.id: <ResourceVersion>[version(id: 'v-${x.id}', resourceId: x.id)],
        },
      ),
    ),
    portTelechargementProvider.overrideWithValue(artefacts),
    lecteurArtefactProvider.overrideWithValue(artefacts),
    depotOctetsProvider.overrideWithValue(FauxCacheMedia()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    ouvreurOngletProvider.overrideWithValue(navigateur ? (Uri _) => true : null),
    portCapaciteEleveProvider.overrideWithValue(
      const PortCapaciteEleveFactice(autonomes: <String>{}),
    ),
  ];
}

Future<void> _eleve(
  WidgetTester tester,
  String nom,
  String adresse,
  List<Override> surcharges, {
  Size taille = const Size(390, 900),
  ThemeMode mode = ThemeMode.light,
  TextDirection? direction,
}) async {
  await monterRouteur(
    tester,
    adresse,
    source: FausseSourceSession(sessionActive(AppRole.student)),
    taille: taille,
    surcharges: surcharges,
    themeMode: mode,
    direction: direction,
  );
  await capturerVue(tester, nom);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('captures', skip: sautSansCapture, () {
    testWidgets('bibliothèque de l\'élève', (tester) async {
      await _eleve(
        tester,
        '01-bibliotheque-fr-clair-390',
        Routes.tcBibliotheque,
        _surcharges(),
      );
      await _eleve(
        tester,
        '02-bibliotheque-fr-sombre-390',
        Routes.tcBibliotheque,
        _surcharges(),
        mode: ThemeMode.dark,
      );
      await _eleve(
        tester,
        '03-bibliotheque-fr-clair-1440',
        Routes.tcBibliotheque,
        _surcharges(),
        taille: const Size(1440, 1100),
      );
      await _eleve(
        tester,
        '04-bibliotheque-vide-390',
        Routes.tcBibliotheque,
        _surcharges(ressources: const <LibraryResource>[]),
      );
      await _eleve(
        tester,
        '05-bibliotheque-erreur-390',
        Routes.tcBibliotheque,
        _surcharges(catalogue: CatalogueEnEchec()),
      );
      await _eleve(
        tester,
        '06-bibliotheque-hors-ligne-390',
        Routes.tcBibliotheque,
        _surcharges(horsLigne: true),
      );
    });

    testWidgets('bibliothèque en arabe', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _eleve(
        tester,
        '07-bibliotheque-ar-clair-390',
        Routes.tcBibliotheque,
        _surcharges(),
        direction: TextDirection.rtl,
      );
    });

    testWidgets('fiches', (tester) async {
      await _eleve(
        tester,
        '08-fiche-lien-externe-web-390',
        '${Routes.tcBibliotheque}/lien',
        _surcharges(navigateur: true),
      );
      await _eleve(
        tester,
        '09-fiche-lien-externe-sans-navigateur-390',
        '${Routes.tcBibliotheque}/lien',
        _surcharges(),
      );
      await _eleve(
        tester,
        '10-fiche-audio-web-390',
        '${Routes.tcBibliotheque}/audio',
        _surcharges(navigateur: true),
      );
      await _eleve(
        tester,
        '11-fiche-audio-sans-lecteur-390',
        '${Routes.tcBibliotheque}/audio',
        _surcharges(),
      );
      await _eleve(
        tester,
        '12-fiche-coran-390',
        '${Routes.tcBibliotheque}/coran',
        _surcharges(),
      );
    });

    testWidgets('formulaire de la direction', (tester) async {
      Future<void> direction(String nom, Size taille) async {
        await admin.monterAdminDemo(
          tester,
          route: Routes.adminPedagogieBibliothequeNouveau,
          bibliotheque: BibliothequeAdminDemo(),
          taille: taille,
          plus: <Override>[
            portCatalogueProvider.overrideWithValue(CatalogueLocal()),
          ],
        );
        await capturerVue(tester, nom);
      }

      await direction('13-direction-formulaire-1440', const Size(1440, 2000));
      await direction('14-direction-formulaire-390', const Size(390, 3000));
    });
  });
}
