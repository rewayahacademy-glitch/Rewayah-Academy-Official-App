import 'package:rewayah_academy/core/tc_parcours/ports_externes/content_position.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/content_range.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/port_assignations.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/port_roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_parcours/source_contenu_seance.dart';

/// Le roster d'Agent E, en memoire.
class FauxRoster implements PortRosterEnseignant {
  /// Cree un roster.
  FauxRoster({this.eleves = const <TeacherStudentProjection>[]});

  /// Ce que [rosterDeSeance] renverra.
  List<TeacherStudentProjection> eleves;

  /// Vrai quand le serveur ne projette pas le roster pour l'enseignant.
  ///
  /// C'est l'etat courant du depot, pas une panne : `groupe_membres` ne porte
  /// que `student_id` et la jointure vers `profiles` est fermee a l'enseignant.
  bool projectionAbsente = false;

  @override
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  }) async {
    for (final TeacherStudentProjection eleve in eleves) {
      if (eleve.academyId == academyId) {
        return eleve;
      }
    }
    return null;
  }

  @override
  Future<List<TeacherStudentProjection>> rosterDeGroupe(
    String groupeId,
  ) async => rosterDeSeance(groupeId);

  @override
  Future<List<TeacherStudentProjection>> rosterDeSeance(
    String sessionId,
  ) async {
    if (projectionAbsente) {
      throw const EchecRoster(MotifEchecRoster.projectionAbsente);
    }
    return eleves;
  }

  @override
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId) =>
      Stream<List<TeacherStudentProjection>>.value(eleves);
}

/// Les assignations d'Agent D, en memoire.
///
/// Volontairement minimal : le lot H ne teste pas le port d'Agent D, il teste
/// ce qu'il en fait.
class FauxAssignations implements PortAssignations {
  /// Cree un depot d'assignations.
  FauxAssignations({this.travaux = const <LearningAssignment>[]});

  /// Ce que [aVenir] et [pourGroupe] renverront.
  List<LearningAssignment> travaux;

  /// Vrai quand l'ecriture doit echouer, comme hors ligne.
  bool ecritureIndisponible = false;

  /// Les creations reellement demandees.
  final List<LearningAssignment> creations = <LearningAssignment>[];

  /// La derniere limite demandee a [aVenir].
  int? derniereLimite;

  @override
  Future<List<LearningAssignment>> aVenir({
    required String groupId,
    int limite = 3,
  }) async {
    derniereLimite = limite;
    return travaux
        .where((LearningAssignment t) => t.groupId == groupId)
        .take(limite < 0 ? 0 : limite)
        .toList(growable: false);
  }

  @override
  Future<void> changerStatut(
    String assignmentId,
    StatutAssignation statut,
  ) async {}

  @override
  Future<LearningAssignment> creerDepuisSelection({
    required String groupId,
    String? studentId,
    required String resourceId,
    String? resourceVersionId,
    ContentRange? contentRange,
    required IntentionPedagogique purpose,
    String? instructions,
    DateTime? dueAtUtc,
  }) async {
    if (ecritureIndisponible) {
      throw const _PanneReseau();
    }
    final LearningAssignment travail = LearningAssignment(
      id: 'cree-${creations.length + 1}',
      groupId: groupId,
      studentId: studentId,
      resourceId: resourceId,
      resourceVersionId: resourceVersionId,
      contentRange: contentRange,
      purpose: purpose,
      instructions: instructions,
      startsAtUtc: DateTime.utc(2026, 9, 20),
      dueAtUtc: dueAtUtc,
      createdBy: 'ens-1',
      status: StatutAssignation.aFaire,
    );
    creations.add(travail);
    return travail;
  }

  @override
  Future<List<LearningAssignment>> pourGroupe(
    String groupId, {
    String? studentId,
  }) async => travaux
      .where((LearningAssignment t) => t.groupId == groupId)
      .toList(growable: false);
}

/// Le contenu presente en seance, en memoire.
class FauxContenuSeance implements SourceContenuSeance {
  /// Cree une source de contenu.
  FauxContenuSeance({
    this.reprisesDeSeance = const <String, ContentPosition>{},
    this.reprisesDeGroupe = const <String, ContentPosition>{},
    this.ranges = const <String, List<ContentRange>>{},
  });

  /// Les positions de fin de seance, par seance.
  Map<String, ContentPosition> reprisesDeSeance;

  /// Les positions de reprise, par groupe.
  Map<String, ContentPosition> reprisesDeGroupe;

  /// Les plages travaillees, par seance.
  Map<String, List<ContentRange>> ranges;

  @override
  Future<ContentPosition?> positionDeReprise(String sessionId) async =>
      reprisesDeSeance[sessionId];

  @override
  Future<List<ContentRange>> rangesTravailles(String sessionId) async =>
      ranges[sessionId] ?? const <ContentRange>[];

  @override
  Future<ContentPosition?> repriseDeGroupe(String groupeId) async =>
      reprisesDeGroupe[groupeId];
}

/// Une panne de reseau, du point de vue du client Supabase.
class _PanneReseau implements Exception {
  const _PanneReseau();

  @override
  String toString() => 'reseau indisponible';
}
