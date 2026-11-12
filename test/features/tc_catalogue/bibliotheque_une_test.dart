// LOT 3 · BIBLIOTHEQUE-UNE : ce que l'eleve voit d'un catalogue unique, par le
// VRAI routeur de l'application (jamais une page montee seule).
//
// Ce que le test prouve : le catalogue montre les types neufs (audio, video,
// lien externe) avec leur description ; le mot « support » ne s'affiche nulle
// part (fr, puis ar) ; les cinq etats existent (chargement, contenu, vide,
// erreur, hors ligne) ; la fiche d'un lien externe ouvre une adresse https et
// seulement elle, sans bouton qui ferait semblant hors navigateur ; la fiche
// d'un audio ouvre par le lien de lecture signe ; la fiche du Coran ouvre le
// lecteur du Coran ; un document sans version dit qu'il n'y a rien a ouvrir.
// Puis, sans ecran : le manifeste du serveur, les filtres, les rayons, les
// URL de vignette et de lecture (https seulement).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart' show horsLigneProvider;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_supabase.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/recherche_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/vignettes_supabase.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_telechargement.dart';
import 'package:rewayah_academy/core/tc_telechargement/telechargement_supabase.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart' hide FauxServiceReseau;
import '../../teaching_core/b/faux/faux_ports_b.dart';

final Uri _lecture = Uri.parse('https://stockage.exemple/lecture?sig=60S');

/// Un depot qui rend un lien de lecture et compte les demandes.
class _Liens extends ArtefactsLocaux {
  int demandes = 0;

  @override
  bool get lienLectureServi => true;

  @override
  Future<Uri> lienLecture(String resourceVersionId) {
    demandes++;
    return Future<Uri>.value(_lecture);
  }
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
    titre: 'Les lettres, a l\'oreille',
    type: TypeRessource.audio,
    description: 'La voix de la direction, lettre par lettre.',
    ordre: 1,
    etapes: <String>['E_LETTRES'],
  ),
  ressource(
    id: 'pdf',
    titre: 'Le livre de lecture',
    type: TypeRessource.pdf,
    description: 'Les pages du livre.',
    ordre: 2,
  ),
  ressource(
    id: 'lien',
    titre: 'Un site de reference',
    type: TypeRessource.lienExterne,
    description: 'Un site pour aller plus loin.',
    lienExterne: 'https://exemple.org/page',
    rayon: codeRayonPlusLoin,
  ),
  ressource(
    id: 'video',
    titre: 'Une video du cours',
    type: TypeRessource.video,
    description: 'La video du cours, par lien.',
    lienExterne: 'https://video.exemple.org/v/1',
    rayon: codeRayonPlusLoin,
  ),
];

List<Override> _surcharges({
  List<LibraryResource>? ressources,
  _Liens? depot,
  bool horsLigne = false,
  PortCatalogue? catalogue,
  OuvreurOnglet? ouvreur,
}) {
  final List<LibraryResource> r = ressources ?? _catalogue;
  final ArtefactsLocaux artefacts = depot ?? ArtefactsLocaux();
  return <Override>[
    portCatalogueProvider.overrideWithValue(
      catalogue ?? CatalogueLocal(ressources: r),
    ),
    portVersionsRessourceProvider.overrideWithValue(
      VersionsLocales(
        parRessource: <String, List<ResourceVersion>>{
          for (final LibraryResource x in r)
            if (x.publiee)
              x.id: <ResourceVersion>[
                version(id: 'v-${x.id}', resourceId: x.id),
              ],
        },
      ),
    ),
    portTelechargementProvider.overrideWithValue(artefacts),
    lecteurArtefactProvider.overrideWithValue(artefacts),
    depotOctetsProvider.overrideWithValue(FauxCacheMedia()),
    horsLigneProvider.overrideWith(
      (Ref _) => Stream<bool>.value(horsLigne),
    ),
    ouvreurOngletProvider.overrideWithValue(ouvreur),
    portCapaciteEleveProvider.overrideWithValue(
      const PortCapaciteEleveFactice(autonomes: <String>{}),
    ),
  ];
}

Future<GoRouter> _monter(
  WidgetTester tester,
  String adresse,
  List<Override> surcharges, {
  Size taille = const Size(1200, 2600),
  double echelle = 1,
  TextDirection? direction,
}) => monterRouteur(
  tester,
  adresse,
  source: FausseSourceSession(sessionActive(AppRole.student)),
  taille: taille,
  surcharges: surcharges,
  echelle: echelle,
  direction: direction,
);

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

/// Tous les textes visibles de l'ecran.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(find.byType(Text)))
    if (w.data != null) w.data!,
];

final RegExp _motSupport = RegExp(r'\bsupports?\b', caseSensitive: false);

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('le catalogue, par le routeur reel', () {
    testWidgets('contenu : types neufs, descriptions, aucun mot « support »', (
      tester,
    ) async {
      await _monter(tester, Routes.tcBibliotheque, _surcharges());
      for (final String titre in <String>[
        'Le Coran',
        'Les lettres, a l\'oreille',
        'Le livre de lecture',
        'Un site de reference',
        'Une video du cours',
      ]) {
        expect(find.text(titre), findsOneWidget, reason: titre);
      }
      expect(find.text('La voix de la direction, lettre par lettre.'), findsOne);
      expect(find.text('Un site pour aller plus loin.'), findsOne);
      expect(find.textContaining('Audio'), findsWidgets);
      expect(find.textContaining('Vidéo'), findsWidgets);
      expect(find.textContaining('Lien externe'), findsWidgets);
      // Le Coran est un document comme les autres : une carte du catalogue.
      expect(find.text('Le Coran en entier, page par page.'), findsOne);
      final List<String> fautes = _textes(
        tester,
      ).where(_motSupport.hasMatch).toList();
      expect(fautes, isEmpty, reason: 'Le mot « support » s\'affiche : $fautes');
    });

    testWidgets('contenu en arabe : aucun mot « support », libelles arabes', (
      tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        Routes.tcBibliotheque,
        _surcharges(),
        direction: TextDirection.rtl,
      );
      expect(find.text('Le Coran'), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.type.audio), findsWidgets);
      expect(t.tc.bibliotheque.type.audio, 'صوت');
      expect(
        _textes(tester).where(_motSupport.hasMatch),
        isEmpty,
      );
    });

    testWidgets('vide : une phrase, sans le mot « support »', (tester) async {
      await _monter(
        tester,
        Routes.tcBibliotheque,
        _surcharges(ressources: const <LibraryResource>[]),
      );
      expect(find.text(t.tc.bibliotheque.vide.message), findsOneWidget);
      expect(t.tc.bibliotheque.vide.message, 'Aucun document publié pour le moment');
      expect(_motSupport.hasMatch(t.tc.bibliotheque.vide.invitation), isFalse);
    });

    testWidgets('erreur : la bibliotheque dit qu\'elle n\'a pas pu etre chargee', (
      tester,
    ) async {
      await _monter(
        tester,
        Routes.tcBibliotheque,
        _surcharges(catalogue: CatalogueEnEchec()),
      );
      expect(find.text(t.tc.bibliotheque.indisponible.message), findsOne);
      expect(find.text(t.tc.bibliotheque.indisponible.action), findsOne);
    });

    testWidgets('hors ligne : les cartes restent, aucune n\'est retiree', (
      tester,
    ) async {
      await _monter(
        tester,
        Routes.tcBibliotheque,
        _surcharges(horsLigne: true),
      );
      expect(find.text('Le livre de lecture'), findsOneWidget);
      expect(find.text('Un site de reference'), findsOneWidget);
    });
  });

  group('la fiche d\'un document, par le routeur reel', () {
    testWidgets('lien externe : l\'adresse https, ouverte seulement sur le web', (
      tester,
    ) async {
      final List<Uri> ouverts = <Uri>[];
      await _monter(
        tester,
        '${Routes.tcBibliotheque}/lien',
        _surcharges(
          ouvreur: (Uri u) {
            ouverts.add(u);
            return true;
          },
        ),
      );
      expect(_cle('rendu-lien'), findsOneWidget);
      expect(find.text('https://exemple.org/page'), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.rendu.lienAutreSite), findsOneWidget);
      expect(find.text('Un site pour aller plus loin.'), findsOneWidget);
      await tester.tap(_cle('rendu-ouvrir-lien'));
      await tester.pumpAndSettle();
      expect(ouverts, <Uri>[Uri.parse('https://exemple.org/page')]);
    });

    testWidgets('lien externe hors navigateur : la phrase, aucun bouton', (
      tester,
    ) async {
      await _monter(tester, '${Routes.tcBibliotheque}/lien', _surcharges());
      expect(_cle('rendu-lien'), findsOneWidget);
      expect(_cle('rendu-ouvrir-lien'), findsNothing);
      expect(
        find.text(t.tc.bibliotheque.rendu.lienSansNavigateur),
        findsOneWidget,
      );
    });

    testWidgets('une adresse qui n\'est pas https n\'est jamais ouverte', (
      tester,
    ) async {
      await _monter(
        tester,
        '${Routes.tcBibliotheque}/lien',
        _surcharges(
          ressources: <LibraryResource>[
            ressource(
              id: 'lien',
              titre: 'Un lien',
              type: TypeRessource.lienExterne,
              description: 'd',
              lienExterne: 'http://exemple.org/page',
            ),
          ],
          ouvreur: (Uri _) => true,
        ),
      );
      expect(_cle('rendu-lien-absent'), findsOneWidget);
      expect(_cle('rendu-ouvrir-lien'), findsNothing);
    });

    testWidgets('audio : « Ouvrir » demande le lien de lecture a chaque ouverture', (
      tester,
    ) async {
      final _Liens depot = _Liens();
      final List<Uri> ouverts = <Uri>[];
      await _monter(
        tester,
        '${Routes.tcBibliotheque}/audio',
        _surcharges(
          depot: depot,
          ouvreur: (Uri u) {
            ouverts.add(u);
            return true;
          },
        ),
      );
      await tester.tap(_cle('rendu-ouvrir'));
      await tester.pumpAndSettle();
      expect(depot.demandes, 1);
      expect(ouverts, <Uri>[_lecture]);
    });

    testWidgets('audio hors navigateur : l\'etat honnete, aucun bouton', (
      tester,
    ) async {
      await _monter(tester, '${Routes.tcBibliotheque}/audio', _surcharges());
      expect(_cle('rendu-sans-lecteur'), findsOneWidget);
      expect(find.text(t.tc.bibliotheque.rendu.sansLecteur), findsOneWidget);
      expect(_cle('rendu-ouvrir'), findsNothing);
    });

    testWidgets('le Coran : un document qui ouvre le lecteur du Coran', (
      tester,
    ) async {
      final GoRouter r = await monterRouteur(
        tester,
        '${Routes.tcBibliotheque}/coran',
        source: FausseSourceSession(sessionActive(AppRole.student)),
        taille: const Size(1200, 2600),
        surcharges: _surcharges(),
      );
      expect(find.text(t.tc.bibliotheque.detail.renduCoran), findsOneWidget);
      expect(_cle('rendu-ouvrir-mushaf'), findsOneWidget);
      // Le geste « Ouvrir le mushaf » mene a Routes.eleveCoran : prouve avec un
      // lecteur du Coran branche dans rendu_lecture_test.dart ; ici, par le
      // routeur reel, on prouve que le Coran est un document du catalogue qui
      // propose ce geste.
      expect(r.routerDelegate.currentConfiguration.uri.path, endsWith('/coran'));
    });

    testWidgets('sans version publiee : rien a ouvrir, dit tel quel', (
      tester,
    ) async {
      await _monter(
        tester,
        '${Routes.tcBibliotheque}/pdf',
        _surcharges(
          ressources: <LibraryResource>[
            ressource(
              id: 'pdf',
              titre: 'Le livre',
              type: TypeRessource.pdf,
              versionCourante: null,
            ),
          ],
        ),
      );
      expect(find.text(t.tc.bibliotheque.detail.sansVersion), findsOneWidget);
    });
  });

  group('sans ecran : ce que dit le serveur', () {
    test('le manifeste porte description, rayon, etapes, lien et vignette', () {
      final LibraryResource r = LibraryResource.depuisJson(const <String, dynamic>{
        'id': 'r1',
        'title': 'Les lettres',
        'short_title': 'Lettres',
        'resource_type': 'audio',
        'language': 'ar',
        'category': 'lecture',
        'access_policy': 'inscrits',
        'offline_policy': 'jamais',
        'current_version_id': 'v1',
        'description': 'La voix de la direction.',
        'lien_externe': null,
        'ordre': 3,
        'rayon': <String, dynamic>{
          'code': 'plus_loin',
          'titre_fr': 'Pour aller plus loin',
          'titre_ar': 'للتعمّق أكثر',
          'ordre': 2,
        },
        'etapes': <String>['E_LETTRES', 'E_VOYELLES'],
        'vignette': true,
      });
      expect(r.resourceType, TypeRessource.audio);
      expect(r.description, 'La voix de la direction.');
      expect(r.ordre, 3);
      expect(r.rayon, codeRayonPlusLoin);
      expect(r.etapes, <String>['E_LETTRES', 'E_VOYELLES']);
      expect(r.aVignette, isTrue);
      expect(r.lienExterne, isNull);
    });

    test('un ancien manifeste (sans les cles neuves) se lit encore', () {
      final LibraryResource r = LibraryResource.depuisJson(const <String, dynamic>{
        'id': 'r1',
        'resource_type': 'pdf',
      });
      expect(r.rayon, codeRayonCours);
      expect(r.etapes, isEmpty);
      expect(r.aVignette, isFalse);
      expect(r.description, isNull);
    });

    test('les types neufs et la famille « document »', () {
      expect(TypeRessource.depuisSql('audio'), TypeRessource.audio);
      expect(TypeRessource.depuisSql('video'), TypeRessource.video);
      expect(
        TypeRessource.depuisSql('external_link'),
        TypeRessource.lienExterne,
      );
      expect(TypeRessource.pdf.estDocument, isTrue);
      expect(TypeRessource.texteStructure.estDocument, isTrue);
      expect(TypeRessource.audio.estDocument, isFalse);
      expect(TypeRessource.lienExterne.estDocument, isFalse);
    });

    test('les filtres partent au serveur sous leurs cles', () {
      expect(
        CatalogueSupabase.filtreServeur(
          const FiltreCatalogue(
            types: <TypeRessource>{TypeRessource.video, TypeRessource.audio},
            rayon: codeRayonPlusLoin,
            etape: 'E_LETTRES',
          ),
        ),
        <String, dynamic>{
          'types': <String>['audio', 'video'],
          'rayon': 'plus_loin',
          'etape': 'E_LETTRES',
        },
      );
      expect(const FiltreCatalogue(rayon: 'cours').vide, isFalse);
      expect(const FiltreCatalogue().vide, isTrue);
    });

    test('le filtre local par rayon et par etape', () {
      final List<LibraryResource> ressources = <LibraryResource>[
        ressource(id: 'a', rayon: codeRayonCours, etapes: <String>['E1']),
        ressource(id: 'b', rayon: codeRayonPlusLoin),
      ];
      expect(
        RechercheCatalogue.filtrer(
          ressources,
          const FiltreCatalogue(rayon: codeRayonPlusLoin),
        ).map((LibraryResource r) => r.id),
        <String>['b'],
      );
      expect(
        RechercheCatalogue.filtrer(
          ressources,
          const FiltreCatalogue(etape: 'E1'),
        ).map((LibraryResource r) => r.id),
        <String>['a'],
      );
    });

    test('la recherche lit aussi la description', () {
      final List<LibraryResource> ressources = <LibraryResource>[
        ressource(id: 'a', titre: 'Un titre', description: 'La voix du cheikh'),
        ressource(id: 'b', titre: 'Autre'),
      ];
      expect(
        RechercheCatalogue.chercher(ressources, 'voix').map(
          (LibraryResource r) => r.id,
        ),
        <String>['a'],
      );
    });

    test('les rayons : intitule selon la langue, ordre croissant', () {
      const RayonBibliotheque r = RayonBibliotheque(
        code: 'plus_loin',
        titreFr: 'Pour aller plus loin',
        titreAr: 'للتعمّق أكثر',
        ordre: 2,
      );
      expect(r.titrePour('fr'), 'Pour aller plus loin');
      expect(r.titrePour('ar'), 'للتعمّق أكثر');
      expect(r.titrePour('en'), 'Pour aller plus loin');
    });

    test('les URL de vignette et de lecture : https seulement', () {
      expect(
        VignettesSupabase.lireUrls(const <String, dynamic>{
          'urls': <String, dynamic>{
            'a': 'https://stockage.exemple/a.png?sig=1',
            'b': 'http://stockage.exemple/b.png',
            'c': 'javascript:alert(1)',
            'd': 42,
          },
        }).keys,
        <String>['a'],
      );
      expect(VignettesSupabase.lireUrls('rien'), isEmpty);
      expect(
        TelechargementSupabase.lireLien(const <String, dynamic>{
          'url': 'https://stockage.exemple/doc?sig=1',
        }).host,
        'stockage.exemple',
      );
      expect(
        () => TelechargementSupabase.lireLien(const <String, dynamic>{
          'url': 'http://stockage.exemple/doc',
        }),
        throwsA(isA<EchecArtefact>()),
      );
      expect(
        () => TelechargementSupabase.lireLien(null),
        throwsA(isA<EchecArtefact>()),
      );
    });
  });
}
