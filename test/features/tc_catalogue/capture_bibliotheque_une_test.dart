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
  // Un document dont le titre et la description sont en arabe : le contenu
  // arabe se rend dans la police du Coran (directeur, 13/11/2026).
  ressource(
    id: 'tajwid',
    titre: 'أحكام التجويد',
    type: TypeRessource.pdf,
    langue: 'ar',
    description: 'شرح مبسط لأحكام النون الساكنة.',
    ordre: 3,
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
    ouvreurOngletProvider.overrideWithValue(
      navigateur ? (Uri _) => true : null,
    ),
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

  // Une capture par test : chaque ecran monte sa propre application (monter
  // plusieurs fois dans un meme test laisse des flux de reseau se refermer
  // sous les pas du test suivant).
  void capture(
    String nom,
    String adresse,
    List<Override> Function() surcharges, {
    Size taille = const Size(390, 900),
    ThemeMode mode = ThemeMode.light,
    bool arabe = false,
  }) {
    testWidgets(nom, (tester) async {
      if (arabe) {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      }
      await _eleve(
        tester,
        nom,
        adresse,
        surcharges(),
        taille: taille,
        mode: mode,
        direction: arabe ? TextDirection.rtl : null,
      );
    }, skip: sautSansCapture != false);
  }

  const String bib = Routes.tcBibliotheque;
  capture('01-bibliotheque-fr-clair-390', bib, _surcharges);
  capture(
    '02-bibliotheque-fr-sombre-390',
    bib,
    _surcharges,
    mode: ThemeMode.dark,
  );
  capture(
    '03-bibliotheque-fr-clair-1440',
    bib,
    _surcharges,
    taille: const Size(1440, 1100),
  );
  capture(
    '04-bibliotheque-vide-390',
    bib,
    () => _surcharges(ressources: const <LibraryResource>[]),
  );
  capture(
    '05-bibliotheque-erreur-390',
    bib,
    () => _surcharges(catalogue: CatalogueEnEchec()),
  );
  capture(
    '06-bibliotheque-hors-ligne-390',
    bib,
    () => _surcharges(horsLigne: true),
  );
  capture('07-bibliotheque-ar-clair-390', bib, _surcharges, arabe: true);
  capture(
    '08-fiche-lien-externe-web-390',
    '$bib/lien',
    () => _surcharges(navigateur: true),
  );
  capture(
    '09-fiche-lien-externe-sans-navigateur-390',
    '$bib/lien',
    _surcharges,
  );
  capture(
    '10-fiche-audio-web-390',
    '$bib/audio',
    () => _surcharges(navigateur: true),
  );
  capture('11-fiche-audio-sans-lecteur-390', '$bib/audio', _surcharges);
  capture('12-fiche-coran-390', '$bib/coran', _surcharges);
  // L'arabe de contenu dans la police du Coran : titre et description d'un
  // document arabe, sur sa fiche.
  capture('19-fiche-document-arabe-390', '$bib/tajwid', _surcharges);

  // D1 : la confirmation avant d'ouvrir un lien (la feuille, ouverte au toucher).
  testWidgets('15-lien-confirmation-390', (tester) async {
    await monterRouteur(
      tester,
      '$bib/lien',
      source: FausseSourceSession(sessionActive(AppRole.student)),
      taille: const Size(390, 900),
      surcharges: _surcharges(navigateur: true),
    );
    await tester.tap(find.byKey(const ValueKey<String>('rendu-ouvrir-lien')));
    await tester.pumpAndSettle();
    await capturerVue(tester, '15-lien-confirmation-390');
  }, skip: sautSansCapture != false);

  // D2 : lecture du Coran et ecole suivie sur la fiche.
  capture(
    '16-fiche-lecture-ecole-390',
    '$bib/priere',
    () => _surcharges(
      ressources: <LibraryResource>[
        ressource(
          id: 'priere',
          titre: 'Les ablutions, pas à pas',
          type: TypeRessource.lienExterne,
          description: 'Les gestes, un par un.',
          lienExterne: 'https://exemple.org/ablutions',
          lectureCoran: 'warsh',
          ecolePriere: 'École malikite',
        ),
      ],
      navigateur: true,
    ),
  );

  // D1, D2, D3 et C2 : le formulaire de la direction, dépôt pas encore activé.
  for (final (String nom, bool depotActif) in <(String, bool)>[
    ('17-direction-depot-non-active-1440', false),
    ('18-direction-tranches-lecture-1440', true),
  ]) {
    testWidgets(nom, (tester) async {
      await admin.monterAdminDemo(
        tester,
        route: Routes.adminPedagogieBibliothequeNouveau,
        bibliotheque: BibliothequeAdminDemo()..depotActifServeur = depotActif,
        taille: const Size(1440, 3000),
        plus: <Override>[
          portCatalogueProvider.overrideWithValue(CatalogueLocal()),
        ],
      );
      await capturerVue(tester, nom);
    }, skip: sautSansCapture != false);
  }

  for (final (String nom, Size taille) in <(String, Size)>[
    ('13-direction-formulaire-1440', const Size(1440, 2000)),
    ('14-direction-formulaire-390', const Size(390, 3000)),
  ]) {
    testWidgets(nom, (tester) async {
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
    }, skip: sautSansCapture != false);
  }
}
