import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/recherche_catalogue.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart';

import 'faux/faux_ports_b.dart';

void main() {
  final List<LibraryResource> catalogue = <LibraryResource>[
    ressource(
      id: 'r1',
      titre: 'Le Coran, riwaya Hafs',
      titreCourt: 'Coran',
      type: TypeRessource.quran,
      langue: 'ar',
      categorie: 'Coran',
      edition: 'madina-hafs-604',
      niveaux: const <String>['F1'],
      capacites: const <CapaciteRessource>{
        CapaciteRessource.pageable,
        CapaciteRessource.searchable,
      },
    ),
    ressource(
      id: 'r2',
      titre: 'Règles du meem sâkinah',
      titreCourt: 'Meem',
      type: TypeRessource.pdf,
      categorie: 'Tajwid',
      niveaux: const <String>['F2'],
      capacites: const <CapaciteRessource>{CapaciteRessource.pageable},
    ),
    ressource(
      id: 'r3',
      titre: 'Alphabet arabe',
      titreCourt: 'Alphabet',
      type: TypeRessource.lecon,
      categorie: 'Lecture',
      niveaux: const <String>['F1'],
      capacites: const <CapaciteRessource>{},
    ),
  ];

  group('Recherche : accents, axes, absence de resultat', () {
    test('une requete vide n est pas une recherche', () {
      expect(RechercheCatalogue.chercher(catalogue, '   ').length, 3);
    });

    test('la recherche ignore les accents et la casse', () {
      expect(
        RechercheCatalogue.chercher(catalogue, 'regles')
            .map((LibraryResource r) => r.id),
        <String>['r2'],
      );
      expect(
        RechercheCatalogue.chercher(catalogue, 'SAKINAH')
            .map((LibraryResource r) => r.id),
        <String>['r2'],
      );
    });

    test('la recherche porte aussi sur la categorie, l edition et le niveau', () {
      expect(
        RechercheCatalogue.chercher(catalogue, 'hafs')
            .map((LibraryResource r) => r.id),
        <String>['r1'],
      );
      expect(
        RechercheCatalogue.chercher(catalogue, 'F2')
            .map((LibraryResource r) => r.id),
        <String>['r2'],
      );
    });

    test('une recherche sans resultat rend une liste vide, pas tout', () {
      expect(RechercheCatalogue.chercher(catalogue, 'biologie'), isEmpty);
    });

    test('un repere chiffre ne remonte que ce qui peut l accueillir', () {
      // « 2:255 » ne veut rien dire pour une lecon : la rendre ferait passer
      // une recherche de verset pour une recherche plein texte.
      expect(
        RechercheCatalogue.chercher(catalogue, '2:255')
            .map((LibraryResource r) => r.id),
        <String>['r1'],
      );
      expect(
        RechercheCatalogue.chercher(catalogue, '40')
            .map((LibraryResource r) => r.id),
        <String>['r1', 'r2'],
      );
    });

    test('un repere donne la position ou ouvrir, quand elle a un sens', () {
      final ContentPosition? verset = RechercheCatalogue.positionDemandee(
        '2:255',
        catalogue.first,
      );
      expect(verset?.typeAncrage, TypeAncrage.ayah);
      expect(verset?.sourate, 2);
      expect(verset?.ayah, 255);

      final ContentPosition? page = RechercheCatalogue.positionDemandee(
        '40',
        catalogue[1],
      );
      expect(page?.typeAncrage, TypeAncrage.page);
      expect(page?.page, 40);

      expect(
        RechercheCatalogue.positionDemandee('40', catalogue[2]),
        isNull,
        reason: 'une lecon non paginee n a pas de page 40',
      );
      expect(
        RechercheCatalogue.positionDemandee('meem', catalogue[1]),
        isNull,
        reason: 'un mot n est pas un repere',
      );
    });
  });

  group('Filtres : chaque axe relache se tait', () {
    test('un filtre vide ne filtre rien', () {
      expect(
        RechercheCatalogue.filtrer(
          catalogue,
          const FiltreCatalogue(),
        ).length,
        3,
      );
      expect(RechercheCatalogue.filtrer(catalogue, null).length, 3);
    });

    test('le type, la langue, la categorie et le niveau se cumulent', () {
      expect(
        RechercheCatalogue.filtrer(
          catalogue,
          const FiltreCatalogue(
            types: <TypeRessource>{TypeRessource.pdf, TypeRessource.lecon},
          ),
        ).map((LibraryResource r) => r.id),
        <String>['r2', 'r3'],
      );
      expect(
        RechercheCatalogue.filtrer(
          catalogue,
          const FiltreCatalogue(langue: 'ar'),
        ).map((LibraryResource r) => r.id),
        <String>['r1'],
      );
      expect(
        RechercheCatalogue.filtrer(
          catalogue,
          const FiltreCatalogue(niveau: 'F1', categorie: 'Lecture'),
        ).map((LibraryResource r) => r.id),
        <String>['r3'],
      );
    });

    test('un etat hors ligne non mesure ne satisfait aucun filtre d etat', () {
      // Une absence de mesure ne vaut pas une mesure : sans cette regle, un
      // filtre « Telecharge » remonterait des ressources dont on ne sait rien.
      expect(
        RechercheCatalogue.filtrer(
          catalogue,
          const FiltreCatalogue(etatOffline: EtatOffline.telecharge),
          etats: const <String, EtatOffline>{'r1': EtatOffline.telecharge},
        ).map((LibraryResource r) => r.id),
        <String>['r1'],
      );
      expect(
        RechercheCatalogue.filtrer(
          catalogue,
          const FiltreCatalogue(etatOffline: EtatOffline.telecharge),
        ),
        isEmpty,
      );
    });

    test('relacher un axe le retire du filtre', () {
      const FiltreCatalogue filtre = FiltreCatalogue(
        langue: 'ar',
        niveau: 'F1',
      );
      final FiltreCatalogue sansLangue = filtre.avec(
        relacher: const <String>{'langue'},
      );

      expect(sansLangue.langue, isNull);
      expect(sansLangue.niveau, 'F1');
      expect(sansLangue.vide, isFalse);
      expect(
        filtre
            .avec(relacher: const <String>{'langue', 'niveau'})
            .vide,
        isTrue,
      );
    });
  });
}
