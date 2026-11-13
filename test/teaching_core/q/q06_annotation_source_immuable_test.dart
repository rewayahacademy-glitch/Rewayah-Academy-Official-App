// Q-06 : une annotation ne modifie jamais resource_version.
//
// INVARIANT 6 de la Phase 6 (« aucune annotation ne modifie la source »),
// spec section 15 (« aucun support ne doit etre duplique pour une
// annotation », « le stylet n altere jamais la source »), CONTRACTS sections
// 5 et 10.
//
// LE DOUBLE REND LA FAUTE POSSIBLE. `FauxDepotVersions` expose une methode
// `remplacer()` et compte les ecritures. Si le depot d annotations touchait
// aux versions, le compteur monterait. Un double incapable de la faute ne
// prouverait rien.

import 'package:flutter_test/flutter_test.dart';

import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';

import '../fixtures/contrats/contrats_d_outils.dart';
import '../fixtures/fixtures_ressources.dart';
import 'faux/faux_annotations.dart';
import 'support/lecture_sources.dart';

final DateTime _maintenant = DateTime.utc(2026, 10, 19, 16, 30);

/// Construit un point sans passer par un contexte constant.
///
/// Detour necessaire : ecrit litteralement, `PointNormalise(1.4, 0.2)` serait
/// evalue a la compilation et l assertion deviendrait une erreur d analyse au
/// lieu du refus a l execution que le test veut observer.
PointNormalise pointDepuis(double x, double y) => PointNormalise(x, y);

TraitVectoriel _trait(String id) => TraitVectoriel(
  id: id,
  ancrage: positionAyatAlKursi,
  points: const <PointNormalise>[
    PointNormalise(0.1, 0.2),
    PointNormalise(0.4, 0.25),
  ],
  outil: OutilTrait.stylet,
  intention: IntentionPedagogique.aRevoir,
);

void main() {
  group('Q-06 : annoter n ecrit jamais dans la version', () {
    test('cent traits et un marqueur laissent la version intacte', () {
      final FauxDepotVersions versions = FauxDepotVersions(
        <ResourceVersion>[versionCoranPubliee, versionPdfPubliee],
      );
      final FauxDepotAnnotations annotations = FauxDepotAnnotations(
        horlogeUtc: _maintenant,
      );
      final ResourceVersion avant = versions.parId('ver-coran-1')!;

      annotations.couche(
        coucheId: 'couche-1',
        resourceId: 'res-coran',
        resourceVersionId: 'ver-coran-1',
        auteurProfilId: 'ens-001',
        sessionId: 'seance-1',
      );
      for (int i = 0; i < 100; i++) {
        annotations.ajouterTrait('couche-1', _trait('t$i'));
      }
      annotations.poserMarqueur(
        'couche-1',
        MarqueurSemantique(
          id: 'm1',
          plage: plageFinBaqara,
          intention: IntentionPedagogique.aRenforcer,
        ),
      );

      final ResourceVersion apres = versions.parId('ver-coran-1')!;
      expect(versions.ecritures, 0, reason: 'aucune ecriture de version');
      expect(apres, avant);
      expect(apres.empreinte, avant.empreinte);
      expect(apres.numeroVersion, avant.numeroVersion);
      expect(apres.downloadAssetId, avant.downloadAssetId);
      expect(apres.statut, StatutVersionRessource.publiee);
      // Et la couche a bien travaille, sinon le test serait vide de sens.
      expect(annotations.parId('couche-1')?.traits, hasLength(100));
      expect(annotations.parId('couche-1')?.marqueurs, hasLength(1));
    });

    test('la couche REFERENCE la version, elle n en garde aucune copie', () {
      final FauxDepotAnnotations annotations = FauxDepotAnnotations(
        horlogeUtc: _maintenant,
      );
      final AnnotationLayer couche = annotations.couche(
        coucheId: 'couche-2',
        resourceId: 'res-pdf',
        resourceVersionId: 'ver-pdf-2',
        auteurProfilId: 'ens-001',
      );

      expect(couche.resourceId, 'res-pdf');
      expect(couche.resourceVersionId, 'ver-pdf-2');

      // Une absence de champ ne se teste pas a l execution : on lit la forme.
      final String? source = lireSiPresent(CheminsDoubles.outils);
      expect(source, isNotNull);
      expect(
        motsTrouves(source!, const <String>[
          'octets',
          'contenusource',
          'contenu_source',
          'copiesupport',
          'copie_support',
          'bytes',
          'base64',
          'imagepage',
        ]),
        isEmpty,
        reason:
            'AnnotationLayer ne doit porter aucune copie du support : ni '
            'octets, ni image, ni texte source',
      );
    });

    test('un trait est vectoriel et normalise, jamais un raster', () {
      final TraitVectoriel t = _trait('t-unique');
      for (final PointNormalise p in t.points) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
      // Un point hors des bornes est refuse a la construction : sans cela,
      // un trait deviendrait dependant de la taille d ecran qui l a produit.
      expect(() => pointDepuis(1.4, 0.2), throwsA(isA<AssertionError>()));
      expect(() => pointDepuis(0.2, -0.1), throwsA(isA<AssertionError>()));
    });

    test('la couleur derive de l intention, jamais l inverse', () {
      // Le contrat ne porte AUCUN champ de couleur : c est l intention qui
      // est stockee, et le rendu en derive. Verification par la forme.
      final String? source = lireSiPresent(CheminsDoubles.outils);
      expect(source, isNotNull);
      expect(
        motsTrouves(source!, const <String>[
          'color(',
          'couleurhex',
          'couleur_hex',
          'argb',
          'rgba',
        ]),
        isEmpty,
      );
      expect(IntentionPedagogique.values, hasLength(5));
    });

    test('un marqueur est une metadonnee de plage, pas un dessin', () {
      final MarqueurSemantique m = MarqueurSemantique(
        id: 'm2',
        plage: plageFinBaqara,
        intention: IntentionPedagogique.aRevoir,
        note: 'Reprendre le madd',
      );

      expect(m.plage.typeAncrage, TypeAncrage.ayah);
      expect(
        m.plage.contient(
          const ContentPosition.ayah(
            resourceId: 'res-coran',
            sourate: 2,
            ayah: 285,
          ),
        ),
        isTrue,
      );
      expect(
        m.plage.contient(
          const ContentPosition.ayah(
            resourceId: 'res-coran',
            sourate: 2,
            ayah: 283,
          ),
        ),
        isFalse,
      );
    });

    test('LearningAssignment reutilise le meme vocabulaire d intentions', () {
      // Invariant 3 de CONTRACTS section 11 : il n existe PAS un second
      // vocabulaire d intentions pedagogiques.
      final LearningAssignment a = LearningAssignment(
        id: 'a1',
        groupId: 'grp-plein',
        resourceId: 'res-coran',
        resourceVersionId: 'ver-coran-1',
        contentRange: plageFinBaqara,
        purpose: IntentionPedagogique.aApprendre,
        startsAtUtc: _maintenant,
        createdBy: 'ens-001',
        status: StatutAssignation.aFaire,
      );
      expect(a.purpose, isA<IntentionPedagogique>());
      expect(a.studentId, isNull, reason: 'assignee au groupe par defaut');
    });

    test('la couche canonique, quand elle existe, subit le meme examen', () {
      // ARME MAIS DORMANT en phase parallele : Agent D n a pas encore publie
      // son fichier dans ce worktree. Le test mord des l integration.
      final String? source = lireSiPresent(CheminsCanoniques.coucheAnnotation);
      if (source == null) return;
      expect(
        motsTrouves(source, const <String>[
          'octets',
          'contenusource',
          'contenu_source',
          'copiesupport',
          'copie_support',
          'base64',
          'imagepage',
        ]),
        isEmpty,
        reason:
            'la couche publiee par Agent D porte une copie du support : '
            'BLOCKER au controle pre-merge',
      );
    });
  });
}
