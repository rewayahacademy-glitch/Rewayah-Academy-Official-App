import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';

void main() {
  group('Ce que la base rend, et ce que les ecrans en lisent', () {
    test('une seance porte les deux prenoms, et aucun nom de famille', () {
      final Seance seance = Seance.depuisJson(const <String, dynamic>{
        'session_id': 's1',
        'started_at': '2026-09-07T15:00:00Z',
        'ended_at': '2026-09-07T15:45:00Z',
        'status': 'planned',
        'session_type': 'child',
        'prayer_pause_minutes': 5,
        'student_id': 'e1',
        'student_first_name': 'Amina',
        'student_immutable_id': 'STUD-AD-000001',
        'teacher_id': 't1',
        'teacher_first_name': 'Omar',
        'teacher_immutable_id': 'TEACH-OS-000001',
      });

      expect(seance.elevePrenom, 'Amina');
      expect(seance.enseignantPrenom, 'Omar');
      expect(seance.statut, StatutSeance.planifiee);
      expect(seance.duree, const Duration(minutes: 45));
      expect(seance.minutesInterruption, 5);
    });

    test('un statut inconnu ne se replie pas sur « planifiee »', () {
      // Un etat illisible qui deviendrait « planifiee » ferait croire a un cours
      // a venir : mieux vaut ne rien affirmer.
      final Seance seance = Seance.depuisJson(const <String, dynamic>{
        'session_id': 's1',
        'started_at': '2026-09-07T15:00:00Z',
        'ended_at': '2026-09-07T16:00:00Z',
        'status': 'quelque_chose_de_neuf',
      });
      expect(seance.statut, isNull);
    });

    test('une seance annulee se reconnait quelle qu\'en soit la forme', () {
      for (final String valeur in <String>['canceled', 'canceled_late']) {
        expect(StatutSeance.depuisSql(valeur)?.estAnnulee, isTrue);
      }
      expect(StatutSeance.planifiee.estAnnulee, isFalse);
    });

    test(
      'une seance est en cours pendant sa plage, meme si le statut tarde',
      () {
        final DateTime debut = DateTime(2026, 9, 7, 17);
        final Seance seance = Seance.depuisJson(<String, dynamic>{
          'session_id': 's1',
          'started_at': debut.toUtc().toIso8601String(),
          'ended_at': debut
              .add(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
          'status': 'planned',
        });

        expect(seance.enCoursA(debut.add(const Duration(minutes: 10))), isTrue);
        expect(
          seance.enCoursA(debut.subtract(const Duration(minutes: 10))),
          isFalse,
        );
        expect(
          seance.avantDebut(debut.subtract(const Duration(minutes: 10))),
          const Duration(minutes: 10),
        );
        // Jamais de duree negative : un compte a rebours passe reste a zero.
        expect(
          seance.avantDebut(debut.add(const Duration(hours: 2))),
          Duration.zero,
        );
      },
    );

    test('un creneau est un motif hebdomadaire, avec son fuseau', () {
      final Creneau creneau = Creneau.depuisJson(const <String, dynamic>{
        'weekday': 1,
        'hour_local': 17,
        'timezone_iana': 'Africa/Conakry',
      });

      expect(creneau.jour, 1);
      expect(creneau.heure, 17);
      expect(creneau.fuseau, 'Africa/Conakry');
      // Deux cases de meme heure dans deux fuseaux ne sont pas la meme case :
      // c'est ce qui interdit de les comparer par leur heure locale.
      expect(
        creneau == const Creneau(jour: 1, heure: 17, fuseau: 'Europe/Paris'),
        isFalse,
      );
    });

    test(
      'une regle dit ce qu\'elle vaut ici et ce qu\'elle vaudrait ailleurs',
      () {
        final RegleProfil surchargee = RegleProfil.depuisJson(
          const <String, dynamic>{
            'key': 'session_duration_minutes',
            'valeur_plateforme': 60,
            'valeur_surchargee': 30,
            'valeur_effective': 30,
            'override_id': 'r1',
            'motif': 'age de l\'enfant',
            'pose_le': '2026-09-06T12:00:00Z',
          },
        );
        final RegleProfil defaut = RegleProfil.depuisJson(
          const <String, dynamic>{
            'key': 'session_paid_minimum_minutes',
            'valeur_plateforme': 45,
            'valeur_effective': 45,
          },
        );

        expect(surchargee.cle, CleRegle.dureeSeance);
        expect(surchargee.surchargee, isTrue);
        expect(surchargee.valeurEffective, 30);
        expect(surchargee.valeurPlateforme, 60);
        expect(defaut.surchargee, isFalse);
        expect(defaut.valeurEffective, defaut.valeurPlateforme);
      },
    );

    test(
      'une demande porte qui l\'a faite, en quelle qualite, et pourquoi',
      () {
        final Demande demande = Demande.depuisJson(const <String, dynamic>{
          'id': 'd1',
          'kind': 'capacity',
          'subject_profile_id': 't1',
          'subject_first_name': 'Omar',
          'subject_immutable_id': 'TEACH-OS-000001',
          'rule_key': 'max_students_per_teacher',
          'rule_value': 8,
          'reason': 'j\'ai du temps le samedi',
          'requester_role': 'teacher',
          'created_at': '2026-09-06T09:00:00Z',
        });

        expect(demande.sorte, SorteDemande.plafond);
        expect(demande.cleRegle, CleRegle.plafondEleves);
        expect(demande.valeurDemandee, 8);
        expect(demande.roleDemandeur, AppRole.teacher);
        expect(demande.motif, isNotEmpty);
      },
    );
  });
}
