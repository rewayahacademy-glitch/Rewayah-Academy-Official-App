// Q-01 : aucune PII famille dans la projection enseignant.
//
// INVARIANT 5 de la Phase 6 (spec section 15 : « aucune vue enseignant ne
// recoit de coordonnees famille »), decisions D-08 et CONTRACTS section 0.
//
// CE TEST EST ECRIT COMME UN REFUS, PAS COMME UNE VERIFICATION.
// Il ne se contente pas de constater qu'une projection propre est propre : il
// LUI DONNE une ligne serveur empoisonnee, celle qu'une vue qui fuirait
// renverrait, et exige que rien n'en ressorte. Puis il relit le fichier de
// contrat lui-meme, parce qu'un test d'execution ne peut pas voir un champ
// que personne n'a encore ajoute -- et c'est precisement l'ajout qu'il faut
// empecher.
//
// CE QU'IL NE PROUVE PAS. La vraie protection est SERVEUR : `teacher_roster_v`
// ne delivre pas ces colonnes (0005, ADR-008) et `profiles` n'accorde aucune
// policy `select` a l'enseignant. Ce test garde la seconde ligne, pas la
// premiere.

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/contrats/contrats_e_classe.dart';
import '../fixtures/fixtures_projection.dart';
import 'support/lecture_sources.dart';

/// Les valeurs empoisonnees, telles qu'elles sont posees dans la ligne piege.
///
/// On les cherche **telles quelles** dans la sortie : un fragment reconnu est
/// une fuite, quel que soit le champ qui l'a laisse passer.
const List<String> _valeursEmpoisonnees = <String>[
  'Benali',
  'famille.benali@exemple.invalid',
  '+33600000000',
  '12 rue des Oliviers, Lyon',
  'foyer-77',
  'Nadia',
  'FR7630001007941234567890185',
  'ANDROID-9f2c41',
  '45.764',
  'B.',
];

/// Les fuites trouvees dans une projection aplatie : cle ET valeur.
List<String> _fuites(Map<String, Object?> plat) {
  final List<String> trouvees = <String>[];
  plat.forEach((String cle, Object? valeur) {
    final String bas = '$cle ${valeur ?? ''}'.toLowerCase();
    for (final String mot in motsInterditsPii) {
      if (bas.contains(mot)) trouvees.add('$cle -> $mot');
    }
  });
  return trouvees;
}

void main() {
  group('Q-01 : la projection enseignant refuse la PII', () {
    test('une ligne serveur qui fuirait ne traverse pas la projection', () {
      final TeacherStudentProjection projection = projectionDepuisLigneServeur(
        ligneServeurEmpoisonnee(),
      );
      final String sortie = aplatirPourAudit(projection).toString();

      for (final String poison in _valeursEmpoisonnees) {
        expect(
          sortie.contains(poison),
          isFalse,
          reason:
              'la valeur « $poison » de la ligne serveur est ressortie de la '
              'projection : elle ne doit jamais etre recopiee',
        );
      }
      // Ce qui DOIT passer passe : sans cela, le test serait vert sur une
      // projection vide, ce qui ne prouverait rien.
      expect(projection.firstName, 'Amina');
      expect(projection.academyId, 'RA-AB0012');
      expect(projection.level, 'n2');
    });

    test('aucun champ de la projection ne porte un mot interdit', () {
      for (final TeacherStudentProjection p in rosterDeFixture()) {
        expect(
          _fuites(aplatirPourAudit(p)),
          isEmpty,
          reason: 'fuite detectee sur la projection de ${p.academyId}',
        );
      }
    });

    test('le double de contrat ne declare aucun champ interdit', () {
      // Le test d'execution ne voit que les champs qui existent. Celui-ci lit
      // le texte : il refuse l'ajout le jour ou quelqu'un l'ecrit.
      final String? source = lireSiPresent(CheminsDoubles.projectionEnseignant);
      expect(source, isNotNull, reason: 'le double de contrat doit exister');
      expect(
        motsTrouves(source!, motsInterditsPii),
        isEmpty,
        reason:
            'un identifiant interdit apparait dans le double de '
            'TeacherStudentProjection',
      );
    });

    test('le contrat canonique, quand il existe, subit le meme examen', () {
      // ARME MAIS DORMANT en phase parallele : Agent E n'a pas encore publie
      // son fichier dans ce worktree, et c'est l'etat attendu. Le test mord
      // des qu'Agent Z reunit les branches, sans qu'une ligne change ici.
      final String? source = lireSiPresent(
        CheminsCanoniques.projectionEnseignant,
      );
      if (source == null) return;
      expect(
        motsTrouves(source, motsInterditsPii),
        isEmpty,
        reason:
            'le contrat publie par Agent E porte un identifiant interdit : '
            'BLOCKER au controle pre-merge',
      );
    });

    test(
      'deux homonymes se distinguent par academyId, jamais par une initiale',
      () {
        // La maquette de la spec section 10.1 affiche « Amina B. ». ADR-008
        // l'emporte : la desambiguisation passe par l'identifiant immuable,
        // exactement comme `journee_page.dart` le fait deja.
        expect(projectionAmina.firstName, projectionAminaHomonyme.firstName);
        expect(
          projectionAmina.academyId,
          isNot(projectionAminaHomonyme.academyId),
        );
        final String libelleA =
            '${projectionAmina.firstName} ${projectionAmina.academyId}';
        final String libelleB =
            '${projectionAminaHomonyme.firstName} '
            '${projectionAminaHomonyme.academyId}';
        expect(libelleA, isNot(libelleB));
        expect(libelleA.contains('B.'), isFalse);
      },
    );

    test('une lecture qui echoue dit inconnu, jamais absent', () {
      // Invariant J3 du depot, deja tenu par `service_presence.dart` : ne pas
      // savoir n'est pas une absence, et ne doit ni alarmer ni rassurer.
      expect(projectionLectureEchouee.liveStatus, EtatPresenceProjete.inconnu);
      expect(
        projectionLectureEchouee.liveStatus,
        isNot(EtatPresenceProjete.absent),
      );
      final TeacherStudentProjection depuisRienDuTout =
          projectionDepuisLigneServeur(const <String, Object?>{});
      expect(depuisRienDuTout.liveStatus, EtatPresenceProjete.inconnu);
    });

    test('« interface guidee » est un libelle, pas un champ nouveau', () {
      // Decision D-07 : la valeur SQL reste 'child', le contrat expose un
      // booleen nomme `interfaceGuidee`, et aucune interface n'ecrit
      // « mode enfant ».
      expect(projectionAmina.interfaceGuidee, isTrue);
      final String? source = lireSiPresent(CheminsDoubles.projectionEnseignant);
      expect(source, isNotNull);
      expect(
        motsTrouves(source!, const <String>['mode enfant', 'modeenfant']),
        isEmpty,
      );
    });
  });
}
