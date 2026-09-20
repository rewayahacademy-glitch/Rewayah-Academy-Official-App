import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/ports_externes/marqueur_semantique.dart';
import 'package:rewayah_academy/core/tc_coran/ports_externes/port_etat_partage.dart';

import 'faux/faux_corpus_coran.dart';
import 'goldens/corpus_reference.dart';

/// Un etat partage minimal, avec une position de reprise de groupe.
class _FauxEtatPartage implements PortEtatPartage {
  _FauxEtatPartage(this.reprise);

  final ContentPosition? reprise;

  @override
  Future<SharedContentState?> etatCourant(String sessionId) async =>
      SharedContentState(
        sessionId: sessionId,
        resourceId: identifiantRessourceCoran,
        contentPosition: const ContentPosition.page(
          resourceId: identifiantRessourceCoran,
          page: 1,
        ),
        displayMode: ModeAffichagePartage.page,
        hiddenRanges: const <ContentRange>[],
        semanticMarkers: const <MarqueurSemantique>[],
        groupResumePosition: reprise,
        revision: 1,
        updatedBy: 'profil-enseignant',
        updatedAtUtc: DateTime.utc(2026, 9, 20, 10),
      );

  @override
  Stream<SharedContentState> suivre(String sessionId) =>
      const Stream<SharedContentState>.empty();

  @override
  Future<void> publier(SharedContentState etat) async {}

  @override
  Future<SharedContentState?> restaurer(String sessionId) =>
      etatCourant(sessionId);
}

void main() {
  late CorpusReference reference;
  late FauxServiceCoranGolden service;
  late FauxCorpusCoran corpus;

  setUpAll(() => reference = CorpusReference.charger());
  setUp(() {
    service = FauxServiceCoranGolden(reference);
    corpus = FauxCorpusCoran(reference);
  });

  NavigationCoran navigation({
    PortEtatPartage? partage,
    String? profil = 'profil-eleve',
  }) => NavigationCoran(
    corpus: corpus,
    service: service,
    profilCourant: () => profil,
    etatPartage: partage,
  );

  group('les cinq navigations de la specification', () {
    test('par page', () async {
      expect(await navigation().pageDe(const CiblePage(3)), 3);
    });

    test('une page hors de l edition ne resout rien', () async {
      expect(await navigation().pageDe(const CiblePage(0)), isNull);
      expect(await navigation().pageDe(const CiblePage(605)), isNull);
    });

    test('par sourate : la page ou la sourate commence', () async {
      expect(await navigation().pageDe(const CibleSourate(1)), 1);
      expect(await navigation().pageDe(const CibleSourate(2)), 2);
      expect(await navigation().pageDe(const CibleSourate(3)), 4);
    });

    test('par juz', () async {
      expect(await navigation().pageDe(const CibleJuz(1)), 1);
      expect(await navigation().pageDe(const CibleJuz(2)), 5);
    });

    test('par ayah', () async {
      expect(
        await navigation().pageDe(const CibleAyah(sourate: 2, ayah: 16)),
        3,
      );
    });

    test('un ayah inexistant ne resout rien', () async {
      expect(
        await navigation().pageDe(const CibleAyah(sourate: 2, ayah: 900)),
        isNull,
      );
    });
  });

  group('position personnelle', () {
    test('elle est lue depuis le service existant', () async {
      service.positionEnregistree = const PositionLecture(
        page: 3,
        sourate: 2,
        verset: 6,
      );

      final PositionLecture? lue = await navigation()
          .dernierePositionPersonnelle();

      expect(lue?.page, 3);
    });

    test('sans session, il n y a pas de position personnelle', () async {
      expect(
        await navigation(profil: null).dernierePositionPersonnelle(),
        isNull,
      );
    });

    test('une navigation personnelle s ecrit', () async {
      final bool ecrit = await navigation().memoriserPositionPersonnelle(
        const PositionLecture(page: 3, sourate: 2, verset: 6),
        origine: OrigineNavigation.personnelle,
      );

      expect(ecrit, isTrue);
      expect(service.ecritures.single.page, 3);
    });
  });

  group('invariant J2 : la classe n ecrit jamais la position de l eleve', () {
    test('une page tournee par le groupe n ecrit rien', () async {
      final bool ecrit = await navigation().memoriserPositionPersonnelle(
        const PositionLecture(page: 300, sourate: 2, verset: 6),
        origine: OrigineNavigation.groupe,
      );

      expect(ecrit, isFalse);
      expect(service.ecritures, isEmpty);
    });

    test('l ouverture de l ecran n ecrit rien non plus', () async {
      final bool ecrit = await navigation().memoriserPositionPersonnelle(
        const PositionLecture(page: 1, sourate: 1, verset: 1),
        origine: OrigineNavigation.ouverture,
      );

      expect(ecrit, isFalse);
      expect(service.ecritures, isEmpty);
    });
  });

  group('position de groupe', () {
    test('sans etat partage, il n y en a pas', () async {
      expect(await navigation().positionDeGroupe('seance-1'), isNull);
    });

    test('un ancrage ayah se resout en page du mushaf', () async {
      final PositionLecture? position = await navigation(
        partage: _FauxEtatPartage(
          const ContentPosition.ayah(
            resourceId: identifiantRessourceCoran,
            sourate: 3,
            ayah: 5,
          ),
        ),
      ).positionDeGroupe('seance-1');

      expect(position?.page, 5);
      expect(position?.sourate, 3);
      expect(position?.verset, 5);
    });

    test('un ancrage page rend le premier verset de la page', () async {
      final PositionLecture? position = await navigation(
        partage: _FauxEtatPartage(
          const ContentPosition.page(
            resourceId: identifiantRessourceCoran,
            page: 4,
          ),
        ),
      ).positionDeGroupe('seance-1');

      expect(position?.page, 4);
      expect(position?.sourate, 2);
      expect(position?.verset, 17);
    });

    test('un ancrage que le mushaf ne sait pas lire ne rend rien', () async {
      final PositionLecture? position = await navigation(
        partage: _FauxEtatPartage(
          const ContentPosition.fraction(
            resourceId: identifiantRessourceCoran,
            fraction: 0.5,
          ),
        ),
      ).positionDeGroupe('seance-1');

      // Surtout pas la page 1 : arrondir une position inconnue a la premiere
      // page presenterait Al-Fatiha a une classe qui travaillait ailleurs.
      expect(position, isNull);
    });

    test('un etat partage sans reprise de groupe ne rend rien', () async {
      expect(
        await navigation(partage: _FauxEtatPartage(null)).positionDeGroupe(
          'seance-1',
        ),
        isNull,
      );
    });
  });

  group('pont vers la position canonique', () {
    test('la position voyage en ancrage semantique, pas en page', () {
      const PositionLecture position = PositionLecture(
        page: 255,
        sourate: 2,
        verset: 255,
      );

      final ContentPosition canonique = position.versContentPosition();

      expect(canonique.typeAncrage, TypeAncrage.ayah);
      expect(canonique.sourate, 2);
      expect(canonique.ayah, 255);
      expect(canonique.page, isNull);
      expect(canonique.resourceId, identifiantRessourceCoran);
    });
  });

  group('lecture de reference, sans reseau', () {
    test('« 2:255 » se lit comme une reference', () {
      expect(
        CorpusDepuisServiceCoran.lireReference('2:255'),
        (sourate: 2, ayah: 255),
      );
      expect(
        CorpusDepuisServiceCoran.lireReference('2 255'),
        (sourate: 2, ayah: 255),
      );
      expect(
        CorpusDepuisServiceCoran.lireReference('2.255'),
        (sourate: 2, ayah: 255),
      );
    });

    test('une sourate hors bornes n est pas une reference', () {
      expect(CorpusDepuisServiceCoran.lireReference('115:1'), isNull);
      expect(CorpusDepuisServiceCoran.lireReference('0:1'), isNull);
      expect(CorpusDepuisServiceCoran.lireReference('2:0'), isNull);
    });

    test('un texte quelconque n est pas une reference', () {
      expect(CorpusDepuisServiceCoran.lireReference('Al-Kahf'), isNull);
      expect(CorpusDepuisServiceCoran.lireReference(''), isNull);
    });

    test('« juz 15 » et « page 300 » se lisent dans les deux ordres', () {
      expect(CorpusDepuisServiceCoran.lireNombreApresMot('juz 15', 'juz'), 15);
      expect(CorpusDepuisServiceCoran.lireNombreApresMot('15 juz', 'juz'), 15);
      expect(
        CorpusDepuisServiceCoran.lireNombreApresMot('page 300', 'page'),
        300,
      );
      expect(
        CorpusDepuisServiceCoran.lireNombreApresMot('300', 'page'),
        isNull,
      );
    });

    test('la normalisation ignore casse et ponctuation', () {
      expect(CorpusDepuisServiceCoran.normaliser('Al-Faatiha'), 'alfaatiha');
      expect(CorpusDepuisServiceCoran.normaliser('AL FAATIHA'), 'alfaatiha');
      expect(CorpusDepuisServiceCoran.normaliser('Aal-`Imraan'), 'aalimraan');
    });
  });

  group('adaptateur au-dessus de ServiceCoran', () {
    test('il rend les sourates du service', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      final List<SourateVM> sourates = await adaptateur.sourates();

      expect(sourates.length, reference.sourates.length);
      expect(sourates.first.nomTranslittere, 'Al-Faatiha');
    });

    test('une lecture impossible leve, elle ne rend pas une liste vide', () {
      service.echoue = true;
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      expect(adaptateur.sourates(), throwsA(isA<EchecCorpusCoran>()));
    });

    test('une page hors de l edition rend null sans interroger', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      expect(await adaptateur.page(0), isNull);
      expect(await adaptateur.page(605), isNull);
    });

    test('la recherche par nom de sourate trouve la page de debut', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      final List<ResultatRechercheCoran> trouves = await adaptateur.rechercher(
        'baqara',
      );

      expect(trouves.single.type, TypeResultatRecherche.sourate);
      expect(trouves.single.page, 2);
      expect(trouves.single.sourate, 2);
    });

    test('un nombre nu propose la sourate ET la page', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      final List<ResultatRechercheCoran> trouves = await adaptateur.rechercher(
        '2',
      );

      expect(
        trouves.map((ResultatRechercheCoran r) => r.type).toList(),
        <TypeResultatRecherche>[
          TypeResultatRecherche.sourate,
          TypeResultatRecherche.page,
        ],
      );
    });

    test('une reference resout la page du verset', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      final List<ResultatRechercheCoran> trouves = await adaptateur.rechercher(
        '2:17',
      );

      expect(trouves.single.type, TypeResultatRecherche.reference);
      expect(trouves.single.page, 4);
    });

    test('la recherche plein texte ne rend rien, et c est declare', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      // Un mot arabe : aucun index texte n'existe en base, et l'ecran le dit.
      expect(await adaptateur.rechercher('الرحمن'), isEmpty);
    });

    test('les trente debuts de juz sont declares', () {
      expect(DebutsDeJuz.table.length, DebutsDeJuz.nombre);
      expect(DebutsDeJuz.table.first, (sourate: 1, verset: 1));
      expect(DebutsDeJuz.table.last, (sourate: 78, verset: 1));
      for (final ({int sourate, int verset}) debut in DebutsDeJuz.table) {
        expect(debut.sourate, inInclusiveRange(1, 114));
        expect(debut.verset, greaterThan(0));
      }
    });

    test('un juz hors bornes ne resout rien', () async {
      final CorpusDepuisServiceCoran adaptateur = CorpusDepuisServiceCoran(
        service,
      );

      expect(await adaptateur.pageDeDebutDeJuz(0), isNull);
      expect(await adaptateur.pageDeDebutDeJuz(31), isNull);
    });
  });
}
