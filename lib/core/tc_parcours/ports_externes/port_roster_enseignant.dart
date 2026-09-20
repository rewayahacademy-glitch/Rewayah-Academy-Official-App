// TC-STUB-PORT: canonique = lib/core/tc_classe/port_roster_enseignant.dart (Agent E)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 12, verifiee
// mot pour mot contre le fichier publie par Agent E, `EchecRoster` compris.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
import 'teacher_student_projection.dart';

/// Pourquoi un roster n'a pas pu etre lu.
///
/// **Deux motifs, et ils ne se confondent pas.** Une lecture qui echoue est
/// temporaire et se reessaye ; une projection absente est un manque serveur, et
/// reessayer ne la fera pas apparaitre.
enum MotifEchecRoster {
  /// Reseau coupe, lecture refusee, reponse illisible.
  lecture,

  /// Le serveur ne projette pas cette lecture pour l'enseignant.
  projectionAbsente,
}

/// L'echec d'une lecture de roster.
class EchecRoster implements Exception {
  /// Cree un echec.
  const EchecRoster(this.motif);

  /// Ce qui a empeche la lecture.
  final MotifEchecRoster motif;

  @override
  String toString() => 'EchecRoster($motif)';
}

/// La lecture du roster pedagogique, cote enseignant.
///
/// **Contrat produit par Agent E**, consomme par E (roster, fiche) et H
/// (signalement, post-cours). Quatre lectures, et **aucune ecriture**.
abstract class PortRosterEnseignant {
  /// Le roster d'une seance : qui est inscrit, et dans quel etat.
  Future<List<TeacherStudentProjection>> rosterDeSeance(String sessionId);

  /// Le roster d'un groupe, hors seance.
  Future<List<TeacherStudentProjection>> rosterDeGroupe(String groupeId);

  /// La fiche pedagogique d'un eleve, eventuellement situee dans une seance.
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  });

  /// Le roster en continu pendant la seance.
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId);
}
