import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/port_roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/roster_classe_vm.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';

import 'faux/faux_classe.dart';

/// Le roster pedagogique : composition, projection d'etats, et tailles reelles.
///
/// **Les inscrits, pas les connectes.** Qui n'est jamais arrive n'a aucune piste
/// temps reel, et c'est justement de lui que l'enseignant doit savoir quelque
/// chose : batir le roster sur la seule liste LiveKit effacerait exactement ceux
/// qu'il faut regarder.
void main() {
  TeacherStudentProjection fiche(String prenom, {String? niveau}) =>
      TeacherStudentProjection(
        firstName: prenom,
        academyId: 'RA-$prenom',
        level: niveau,
        liveStatus: EtatPresenceProjete.inconnu,
        interfaceGuidee: false,
      );

  group('projection des quatorze etats sur les neuf du contrat', () {
    test('une lecture qui echoue rend inconnu, jamais absent', () {
      expect(
        projeterEtatPresence(EtatPresence.inconnu),
        EtatPresenceProjete.inconnu,
      );
      expect(
        projeterEtatPresence(EtatPresence.inconnu),
        isNot(EtatPresenceProjete.absent),
      );
    });

    test('les trois etats de consolidation rendent inconnu', () {
      // Ils qualifient une decision administrative sur une seance close, pas
      // une place dans la salle.
      for (final EtatPresence etat in <EtatPresence>[
        EtatPresence.confirmationEnAttente,
        EtatPresence.corrigeeManuel,
        EtatPresence.finalisee,
      ]) {
        expect(projeterEtatPresence(etat), EtatPresenceProjete.inconnu);
      }
    });

    test('les quatorze etats sont tous projetes, aucun ne leve', () {
      for (final EtatPresence etat in EtatPresence.values) {
        expect(() => projeterEtatPresence(etat), returnsNormally);
      }
    });

    test('planifiee et en attente deviennent attendu', () {
      expect(
        projeterEtatPresence(EtatPresence.planifiee),
        EtatPresenceProjete.attendu,
      );
      expect(
        projeterEtatPresence(EtatPresence.enAttente),
        EtatPresenceProjete.attendu,
      );
    });

    test('reconnectee est present : la seance a continue', () {
      expect(
        projeterEtatPresence(EtatPresence.reconnectee),
        EtatPresenceProjete.present,
      );
    });
  });

  group('composition du roster', () {
    test('roster de 1', () {
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[
          presenceDe(profilId: 'p1', prenom: 'Amina'),
        ],
      );
      expect(roster, hasLength(1));
      expect(roster.single.firstName, 'Amina');
      expect(roster.single.liveStatus, EtatPresenceProjete.present);
    });

    test('roster de 5 : un groupe d enfants complet', () {
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[
          for (int i = 0; i < 5; i++)
            presenceDe(profilId: 'p$i', prenom: 'Eleve$i'),
        ],
      );
      expect(roster, hasLength(5));
    });

    test('roster de 15 : rien ne casse au-dela du plafond metier', () {
      // Le plafond serveur vaut 5 ou 6, mais un roster de quinze doit rester
      // lisible : le client ne refuse pas une donnee que la base lui a rendue.
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[
          for (int i = 0; i < 15; i++)
            presenceDe(profilId: 'p$i', prenom: 'Eleve${i.toString().padLeft(2, '0')}'),
        ],
      );
      expect(roster, hasLength(15));
      // L'ordre reste stable, par prenom : une ligne qui se deplacerait sous le
      // doigt de l'enseignant au moment ou il la touche serait un defaut.
      expect(roster.first.firstName, 'Eleve00');
      expect(roster.last.firstName, 'Eleve14');
    });

    test('seuls les eleves entrent dans le roster', () {
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[
          presenceDe(profilId: 'p1', prenom: 'Amina'),
          presenceDe(profilId: 't1', prenom: 'Youssouf', role: 'teacher'),
          presenceDe(
            profilId: 'g1',
            prenom: 'Tuteur',
            role: 'guardian_observer',
          ),
          presenceDe(
            profilId: 'c1',
            prenom: 'Controle',
            role: 'masked_controller',
          ),
        ],
      );
      expect(roster.map((TeacherStudentProjection e) => e.firstName), <String>[
        'Amina',
      ]);
    });

    test('l etat vient de la presence, jamais de la fiche', () {
      // La fiche est lue une fois, la presence toutes les vingt secondes :
      // prendre l'etat de la fiche figerait le roster a l'entree.
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[
          presenceDe(
            profilId: 'p1',
            prenom: 'Amina',
            etat: EtatPresence.enRetard,
          ),
        ],
        fichesParAcademyId: <String, TeacherStudentProjection>{
          'RA-p1': fiche('Amina', niveau: 'Decodage consolide'),
        },
      );
      expect(roster.single.liveStatus, EtatPresenceProjete.enRetard);
      expect(roster.single.level, 'Decodage consolide');
    });

    test('une fiche manquante ne fait pas disparaitre la ligne', () {
      // Une ligne sans niveau reste vraie ; une ligne absente serait fausse.
      final List<TeacherStudentProjection> roster = composerRoster(
        presences: <PresenceParticipant>[
          presenceDe(profilId: 'p1', prenom: 'Amina'),
        ],
        fichesParAcademyId: <String, TeacherStudentProjection>{
          'RA-autre': fiche('Ilyas'),
        },
      );
      expect(roster, hasLength(1));
      expect(roster.single.level, isNull);
    });
  });

  group('indisponible n est pas vide', () {
    test('le roster indisponible se distingue d un roster sans eleve', () {
      expect(RosterClasseVM.indisponible.disponible, isFalse);
      expect(RosterClasseVM.indisponible.eleves, isEmpty);

      const RosterClasseVM vide = RosterClasseVM(
        eleves: <TeacherStudentProjection>[],
        disponible: true,
      );
      expect(vide.disponible, isTrue);
      expect(vide.eleves, isEmpty);
    });
  });

  group('file de recitation', () {
    test('changer d eleve ne porte rien d autre qu un identifiant', () {
      // Structurellement : la file ne contient aucun champ qui designe une
      // page, un focus, un stylet ou un support. Elle ne PEUT donc pas les
      // deplacer (spec section 10.3).
      const FileRecitation file = FileRecitation(
        actif: 'RA-p1',
        suivants: <String>['RA-p2', 'RA-p3'],
      );
      final FileRecitation apres = file.donnerLaParoleA('RA-p2');
      expect(apres.actif, 'RA-p2');
      expect(apres.suivants, <String>['RA-p3']);
    });

    test('la liste des suivants reste courte', () {
      const FileRecitation file = FileRecitation(
        suivants: <String>['a', 'b', 'c', 'd', 'e'],
      );
      expect(file.suivantsVisibles, hasLength(FileRecitation.suivantsMontres));
    });

    test('rendre la file au repos n efface pas la file d attente', () {
      const FileRecitation file = FileRecitation(
        actif: 'a',
        suivants: <String>['b'],
      );
      expect(file.sansActif.actif, isNull);
      expect(file.sansActif.suivants, <String>['b']);
    });
  });

  test('le plafond du groupe vient de la donnee, jamais d une constante', () {
    const RosterClasseVM roster = RosterClasseVM(
      eleves: <TeacherStudentProjection>[],
      disponible: true,
    );
    // Aucun plafond par defaut : le client n'en invente pas un.
    expect(roster.seuilMax, isNull);
    expect(roster.avecSeuil(6).seuilMax, 6);
  });

  test('le roster de groupe refuse explicitement au lieu de mentir', () async {
    // Une liste vide dirait « ce groupe n'a aucun membre » d'un groupe qui en a
    // cinq : `groupe_membres` ne porte que `student_id`, et la jointure vers
    // `profiles` est fermee a l'enseignant par la RLS.
    final FauxRosterEnseignant faux = FauxRosterEnseignant();
    await expectLater(
      faux.rosterDeGroupe('g1'),
      throwsA(
        isA<EchecRoster>().having(
          (EchecRoster e) => e.motif,
          'motif',
          MotifEchecRoster.projectionAbsente,
        ),
      ),
    );
  });
}
