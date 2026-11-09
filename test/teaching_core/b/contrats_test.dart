import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_telechargement/download_asset.dart';

void main() {
  group('ContentPosition : un seul ancrage a la fois', () {
    test('une position de page ne porte que sa page', () {
      const ContentPosition p = ContentPosition.page(
        resourceId: 'r1',
        page: 40,
      );

      expect(p.typeAncrage, TypeAncrage.page);
      expect(p.page, 40);
      expect(p.sourate, isNull);
      expect(p.ayah, isNull);
      expect(p.sectionId, isNull);
      expect(p.fraction, isNull);
    });

    test('une position de verset porte sourate et verset, rien d autre', () {
      const ContentPosition p = ContentPosition.ayah(
        resourceId: 'r1',
        sourate: 2,
        ayah: 255,
      );

      expect(p.sourate, 2);
      expect(p.ayah, 255);
      expect(p.page, isNull);
    });

    test('une fraction hors de 0..1 est refusee a la construction', () {
      expect(
        () => ContentPosition.fraction(resourceId: 'r1', fraction: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('deux positions identiques sont egales', () {
      expect(
        const ContentPosition.page(resourceId: 'r1', page: 3),
        const ContentPosition.page(resourceId: 'r1', page: 3),
      );
      expect(
        const ContentPosition.page(resourceId: 'r1', page: 3),
        isNot(const ContentPosition.page(resourceId: 'r2', page: 3)),
      );
    });
  });

  group('ContentRange : bornes, appartenance, chevauchement', () {
    ContentRange pages(int debut, int fin, {String ressource = 'r1'}) =>
        ContentRange(
          resourceId: ressource,
          debut: ContentPosition.page(resourceId: ressource, page: debut),
          fin: ContentPosition.page(resourceId: ressource, page: fin),
        );

    test('la fin est incluse', () {
      final ContentRange plage = pages(10, 12);

      expect(
        plage.contient(const ContentPosition.page(resourceId: 'r1', page: 12)),
        isTrue,
      );
      expect(
        plage.contient(const ContentPosition.page(resourceId: 'r1', page: 13)),
        isFalse,
      );
    });

    test('une borne inversee est refusee a la construction', () {
      expect(() => pages(12, 10), throwsA(isA<AssertionError>()));
    });

    test('deux types d ancrage differents sont refuses', () {
      expect(
        () => ContentRange(
          resourceId: 'r1',
          debut: const ContentPosition.page(resourceId: 'r1', page: 1),
          fin: const ContentPosition.ayah(
            resourceId: 'r1',
            sourate: 1,
            ayah: 7,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('une position d une autre ressource ne tombe jamais dedans', () {
      expect(
        pages(
          1,
          100,
        ).contient(const ContentPosition.page(resourceId: 'autre', page: 50)),
        isFalse,
      );
    });

    test('les versets se rangent sourate puis verset', () {
      final ContentRange plage = ContentRange(
        resourceId: 'r1',
        debut: const ContentPosition.ayah(
          resourceId: 'r1',
          sourate: 2,
          ayah: 250,
        ),
        fin: const ContentPosition.ayah(resourceId: 'r1', sourate: 3, ayah: 10),
      );

      expect(
        plage.contient(
          const ContentPosition.ayah(resourceId: 'r1', sourate: 2, ayah: 286),
        ),
        isTrue,
      );
      expect(
        plage.contient(
          const ContentPosition.ayah(resourceId: 'r1', sourate: 3, ayah: 11),
        ),
        isFalse,
      );
    });

    test('le chevauchement se mesure aux bornes comprises', () {
      expect(pages(1, 10).chevauche(pages(10, 20)), isTrue);
      expect(pages(1, 10).chevauche(pages(11, 20)), isFalse);
      expect(pages(1, 10).chevauche(pages(5, 8, ressource: 'autre')), isFalse);
    });
  });

  group('Enumerations : aucun repli silencieux', () {
    test('un type de ressource inconnu rend null', () {
      expect(
        TypeRessource.depuisSql('structured_text'),
        TypeRessource.texteStructure,
      );
      expect(TypeRessource.depuisSql('video'), isNull);
      expect(TypeRessource.depuisSql(null), isNull);
    });

    test('une capacite inconnue rend null', () {
      expect(
        CapaciteRessource.depuisSql('presentable_in_class'),
        CapaciteRessource.presentableInClass,
      );
      expect(CapaciteRessource.depuisSql('teleportable'), isNull);
    });

    test('un statut de version inconnu se replie sur publiee', () {
      // Meme repli que `0020` : un statut mal lu ne doit jamais laisser croire
      // qu'une version est encore modifiable.
      expect(
        StatutVersionRessource.depuisSql('inconnu'),
        StatutVersionRessource.publiee,
      );
      expect(
        StatutVersionRessource.depuisSql('brouillon'),
        StatutVersionRessource.brouillon,
      );
    });
  });

  group('Temps : UTC impose', () {
    test('une version publiee en heure locale est refusee', () {
      expect(
        () => ResourceVersion(
          id: 'v1',
          resourceId: 'r1',
          numeroVersion: 1,
          statut: StatutVersionRessource.publiee,
          publieeLeUtc: DateTime(2026, 9, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('un artefact date en heure locale est refuse', () {
      expect(
        () => DownloadAsset(
          id: 'a1',
          resourceVersionId: 'v1',
          format: FormatArtefact.pdf,
          cleStockage: 'k',
          tailleOctets: 1,
          origine: OrigineArtefact.importeTelQuel,
          creeLeUtc: DateTime(2026, 9, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('LibraryResource : lecture d une ligne serveur', () {
    test('les capacites inconnues sont ignorees, pas devinees', () {
      final LibraryResource r = LibraryResource.depuisJson(
        const <String, dynamic>{
          'id': 'r1',
          'title': 'Les regles du meem',
          'short_title': 'Meem',
          'resource_type': 'pdf',
          'language': 'fr',
          'category': 'Tajwid',
          'level_scope': <String>['F1', 'F2'],
          'access_policy': 'inscrits',
          'offline_policy': 'sur_demande',
          'current_version_id': 'v1',
          'capabilities': <String>['pageable', 'teleportable'],
        },
      );

      expect(r.resourceType, TypeRessource.pdf);
      expect(r.levelScope, <String>['F1', 'F2']);
      expect(r.capabilities, <CapaciteRessource>{CapaciteRessource.pageable});
      expect(r.peut(CapaciteRessource.annotatable), isFalse);
      expect(r.publiee, isTrue);
    });

    test('une politique d acces inconnue se ferme sur admin', () {
      final LibraryResource r = LibraryResource.depuisJson(
        const <String, dynamic>{'id': 'r1', 'access_policy': 'tout_le_monde'},
      );

      // Se fermer et non s'ouvrir : un repli permissif transformerait une
      // valeur mal lue en fuite.
      expect(r.accessPolicy, PolitiqueAcces.admin);
      expect(r.offlinePolicy, PolitiqueOffline.jamais);
    });
  });
}
