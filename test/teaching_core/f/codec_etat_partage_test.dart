import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_etat_partage/codec_etat_partage.dart';
import 'package:rewayah_academy/core/tc_etat_partage/ports_externes/content_position.dart';
import 'package:rewayah_academy/core/tc_etat_partage/ports_externes/content_range.dart';
import 'package:rewayah_academy/core/tc_etat_partage/ports_externes/marqueur_semantique.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';

import 'support/fabriques.dart';

/// L'encodage de l'etat partage : aller-retour fidele, et **aucun repli
/// silencieux** sur une donnee illisible.
///
/// Un paquet vient du reseau, donc d'une version d'application qu'on ne
/// controle pas. Le principe du socle -- un paquet illisible ne casse rien --
/// s'applique ici, mais il ne doit pas devenir « un paquet illisible invente
/// une valeur ».
void main() {
  group('aller-retour', () {
    test('un etat complet se retrouve a l identique', () {
      final SharedContentState depart = etatPartage(
        revision: 12,
        resourceVersionId: 'v-3',
        mode: ModeAffichagePartage.focus,
        plage: plagePages(4, 9),
        masquees: <ContentRange>[plagePages(20, 22), plagePages(30, 31)],
        marqueurs: <MarqueurSemantique>[
          marqueur('m1', 4, 5, note: 'Confusion sur la liaison'),
          marqueur(
            'm2',
            6,
            9,
            intention: IntentionPedagogique.aRenforcer,
          ),
        ],
        reprise: positionPage(9),
      );

      final SharedContentState? relu = etatDepuisJson(etatVersJson(depart));

      expect(relu, isNotNull);
      expect(relu, depart);
    });

    test('les quatre types d ancrage survivent', () {
      const List<ContentPosition> positions = <ContentPosition>[
        ContentPosition.page(resourceId: 'r', page: 7),
        ContentPosition.ayah(resourceId: 'r', sourate: 2, ayah: 255),
        ContentPosition.section(resourceId: 'r', sectionId: 's-1'),
        ContentPosition.fraction(resourceId: 'r', fraction: 0.5),
      ];

      for (final ContentPosition position in positions) {
        expect(
          positionDepuisJson(positionVersJson(position)),
          position,
          reason: 'ancrage ${position.typeAncrage.valeurSql}',
        );
      }
    });
  });

  group('donnee illisible', () {
    test('un mode d affichage inconnu rend null, jamais un repli', () {
      final Map<String, dynamic> brut = etatVersJson(etatPartage())
        ..['display_mode'] = 'cinema';

      // Un paquet ecrit par une version plus recente ne doit pas faire
      // basculer une classe entiere dans un mode qu'elle n'a pas demande.
      expect(etatDepuisJson(brut), isNull);
    });

    test('une revision negative rend null', () {
      final Map<String, dynamic> brut = etatVersJson(etatPartage())
        ..['revision'] = -1;

      expect(etatDepuisJson(brut), isNull);
    });

    test('une position absente rend null', () {
      final Map<String, dynamic> brut = etatVersJson(etatPartage())
        ..remove('content_position');

      expect(etatDepuisJson(brut), isNull);
    });

    test('un marqueur illisible ne fait perdre que lui', () {
      final Map<String, dynamic> brut = etatVersJson(
        etatPartage(
          marqueurs: <MarqueurSemantique>[
            marqueur('m1', 1, 2),
            marqueur('m2', 3, 4),
          ],
        ),
      );
      final List<dynamic> marqueurs = brut['semantic_markers'] as List<dynamic>;
      (marqueurs.first as Map<String, dynamic>)['intention'] = 'inconnue';

      final SharedContentState? relu = etatDepuisJson(brut);

      // La page ouverte devant la classe ne disparait pas parce qu'un marqueur
      // vient d'une version plus recente.
      expect(relu, isNotNull);
      expect(relu!.semanticMarkers, hasLength(1));
      expect(relu.semanticMarkers.single.id, 'm2');
    });

    test('une plage aux bornes incomparables rend null', () {
      final Map<String, dynamic> brut = plageVersJson(plagePages(1, 4));
      brut['fin'] = positionVersJson(
        const ContentPosition.ayah(resourceId: 'res-1', sourate: 2, ayah: 1),
      );

      // En release les assertions de `ContentRange` ne s'executent pas : le
      // test est refait dans le codec pour que le comportement soit le meme
      // des deux cotes.
      expect(plageDepuisJson(brut), isNull);
    });

    test('une fraction hors bornes rend null', () {
      final Map<String, dynamic> brut = positionVersJson(
        const ContentPosition.fraction(resourceId: 'r', fraction: 0.5),
      )..['fraction'] = 1.5;

      expect(positionDepuisJson(brut), isNull);
    });

    test('un ancrage ayah ampute rend null', () {
      final Map<String, dynamic> brut = positionVersJson(
        const ContentPosition.ayah(resourceId: 'r', sourate: 2, ayah: 255),
      )..['ayah'] = null;

      expect(positionDepuisJson(brut), isNull);
    });
  });

  test('aucune donnee sensible ne figure dans la charge encodee', () {
    final String encode = etatVersJson(etatPartage()).toString();

    // Le contrat ne porte que des identifiants de ressource, des positions et
    // un profile_id d'emetteur. Ce test fige cette surface : une cle ajoutee
    // par megarde le ferait tomber.
    expect(
      etatVersJson(etatPartage()).keys.toSet(),
      <String>{
        'session_id',
        'resource_id',
        'resource_version_id',
        'content_position',
        'content_range',
        'display_mode',
        'hidden_ranges',
        'semantic_markers',
        'group_resume_position',
        'revision',
        'updated_by',
        'updated_at',
      },
    );
    expect(encode.contains('@'), isFalse, reason: 'aucun courriel');
  });
}
