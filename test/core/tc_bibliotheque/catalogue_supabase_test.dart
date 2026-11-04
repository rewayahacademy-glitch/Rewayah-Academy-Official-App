// N4 : la lecture des reponses du catalogue lecteur du serveur
// (`bibliotheque_catalogue_lecteur`, `_recents_lecteur`, `_reprise_lecteur`).
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_supabase.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart';

Map<String, dynamic> _manifeste(String id, {String type = 'lesson'}) =>
    <String, dynamic>{
      'id': id,
      'title': 'Tajwid, les regles de base',
      'short_title': 'Tajwid',
      'cover_asset': null,
      'resource_type': type,
      'edition': null,
      'language': 'fr',
      'category': 'tajwid',
      'level_scope': <String>['N1'],
      'access_policy': 'inscrits',
      'offline_policy': 'jamais',
      'current_version_id': 'v-1',
      'capabilities': <String>[],
    };

void main() {
  group('N4 : filtre envoye au serveur', () {
    test('aucun filtre : objet vide (le serveur relache tous les axes)', () {
      expect(CatalogueSupabase.filtreServeur(null), isEmpty);
      expect(CatalogueSupabase.filtreServeur(const FiltreCatalogue()), isEmpty);
    });

    test('seuls les axes poses partent, avec les cles du serveur', () {
      final Map<String, dynamic> f = CatalogueSupabase.filtreServeur(
        const FiltreCatalogue(
          types: <TypeRessource>{TypeRessource.quran, TypeRessource.lecon},
          langue: 'ar',
          niveau: 'N2',
        ),
      );
      expect(f.keys.toSet(), <String>{'types', 'langue', 'niveau'});
      expect(f['types'], <String>['lesson', 'quran']);
      expect(f['langue'], 'ar');
      expect(f['niveau'], 'N2');
    });

    test('l etat hors ligne ne part jamais : il depend de l appareil', () {
      final Map<String, dynamic> f = CatalogueSupabase.filtreServeur(
        const FiltreCatalogue(etatOffline: EtatOffline.enCache),
      );
      expect(f, isEmpty);
    });

    test('une ressource precise passe par la cle id', () {
      expect(
        CatalogueSupabase.filtreServeur(null, id: 'r-1'),
        <String, dynamic>{'id': 'r-1'},
      );
    });
  });

  group('N4 : manifestes rendus', () {
    test('null ou liste vide : aucune ressource', () {
      expect(CatalogueSupabase.manifestes(null), isEmpty);
      expect(CatalogueSupabase.manifestes(<dynamic>[]), isEmpty);
    });

    test('lit chaque manifeste par LibraryResource.depuisJson', () {
      final List<LibraryResource> r = CatalogueSupabase.manifestes(<dynamic>[
        _manifeste('r-1'),
        _manifeste('r-2', type: 'quran'),
      ]);
      expect(r.map((LibraryResource x) => x.id), <String>['r-1', 'r-2']);
      expect(r.last.resourceType, TypeRessource.quran);
      expect(r.first.levelScope, <String>['N1']);
    });

    test('une forme inattendue est une erreur de format', () {
      expect(
        () => CatalogueSupabase.manifestes(<String, dynamic>{}),
        throwsFormatException,
      );
    });
  });

  group('N4 : reprise', () {
    test('rien a reprendre : null', () {
      expect(CatalogueSupabase.reprise(null), isNull);
    });

    test('une page : position et date en UTC', () {
      final ReprisLecture? r = CatalogueSupabase.reprise(<String, dynamic>{
        'ressource': _manifeste('r-1'),
        'position': <String, dynamic>{
          'type_ancrage': 'page',
          'resource_version_id': 'v-1',
          'page': 12,
          'sourate': null,
          'ayah': null,
          'section_id': null,
          'fraction': null,
        },
        'vue_le': '2026-11-03T20:15:00+00:00',
      });
      expect(r, isNotNull);
      expect(r!.ressource.id, 'r-1');
      expect(r.position.typeAncrage, TypeAncrage.page);
      expect(r.position.page, 12);
      expect(r.position.resourceVersionId, 'v-1');
      expect(r.vueLeUtc.isUtc, isTrue);
      expect(r.vueLeUtc, DateTime.utc(2026, 11, 3, 20, 15));
    });

    test('un verset : sourate et ayah', () {
      final ReprisLecture? r = CatalogueSupabase.reprise(<String, dynamic>{
        'ressource': _manifeste('r-2', type: 'quran'),
        'position': <String, dynamic>{
          'type_ancrage': 'ayah',
          'sourate': 2,
          'ayah': 255,
        },
        'vue_le': '2026-11-03T20:15:00Z',
      });
      expect(r!.position.sourate, 2);
      expect(r.position.ayah, 255);
    });

    test('une position incomplete ne fabrique pas de reprise', () {
      expect(
        CatalogueSupabase.reprise(<String, dynamic>{
          'ressource': _manifeste('r-1'),
          'position': <String, dynamic>{'type_ancrage': 'page'},
          'vue_le': '2026-11-03T20:15:00Z',
        }),
        isNull,
      );
    });
  });
}
