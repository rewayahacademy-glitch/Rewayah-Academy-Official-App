// La fiche d'un eleve de `/tc/classe` (image CLV-07) : une date pour la
// derniere seance, un intitule pour le travail, « Niveau » jamais repete.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_classe_live.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

LearningAssignment _travail({String? consigne}) => LearningAssignment(
  id: 'a1',
  groupId: 'g1',
  resourceId: 'r1',
  purpose: IntentionPedagogique.aRevoir,
  instructions: consigne,
  startsAtUtc: DateTime.utc(2026, 9, 24),
  createdBy: 't1',
  status: StatutAssignation.enCours,
);

TeacherStudentProjection _eleve({
  String? niveau,
  ResumeSeance? derniere,
  AssiduiteRecente? assiduite,
  List<LearningAssignment> travaux = const <LearningAssignment>[],
}) => TeacherStudentProjection(
  firstName: 'Mariam',
  academyId: 'RA-Mariam',
  level: niveau,
  lastLesson: derniere,
  recentAttendance: assiduite,
  currentAssignments: travaux,
  liveStatus: EtatPresenceProjete.present,
  interfaceGuidee: false,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('la fiche de l image CLV-07', () {
    final FicheEleveSeance fiche = DepuisClasseLive.fiche(
      _eleve(
        niveau: 'Niveau 1',
        derniere: ResumeSeance(dateUtc: DateTime.utc(2026, 9, 24, 14)),
        assiduite: const AssiduiteRecente(presences: 3, total: 3),
        travaux: <LearningAssignment>[
          _travail(consigne: 'Écoute de la récitation'),
        ],
      ),
    );
    expect(fiche.niveau, '1');
    expect(fiche.derniereSeance, '24 sept. 2026');
    expect(fiche.presenceRecente, '3 séances cette semaine');
    expect(fiche.travailActuel, 'Écoute de la récitation');
  });

  test('un niveau sans intitule reste tel quel', () {
    expect(DepuisClasseLive.niveauSansIntitule('Débutant'), 'Débutant');
    expect(DepuisClasseLive.niveauSansIntitule('niveau 2'), '2');
    expect(DepuisClasseLive.niveauSansIntitule('Niveau'), 'Niveau');
  });

  test('un travail sans consigne se dit par son intention', () {
    expect(
      DepuisClasseLive.intituleTravail(_travail()),
      t.tc.outils.intention.aRevoir,
    );
  });

  test('une ou aucune seance se dit sans pluriel faux', () {
    expect(DepuisClasseLive.seancesSemaine(1), '1 séance cette semaine');
    expect(DepuisClasseLive.seancesSemaine(0), 'Aucune séance cette semaine');
  });

  test('un fait inconnu reste un tiret', () {
    final FicheEleveSeance fiche = DepuisClasseLive.fiche(_eleve());
    expect(fiche.niveau, '-');
    expect(fiche.derniereSeance, '-');
    expect(fiche.presenceRecente, '-');
    expect(fiche.travailActuel, '-');
  });
}
