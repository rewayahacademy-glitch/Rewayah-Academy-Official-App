import 'teacher_student_projection.dart';

/// Pourquoi un roster n'a pas pu etre lu.
///
/// **Deux motifs, et ils ne se confondent pas.** Une lecture qui echoue est
/// temporaire et se reessaye ; une projection absente est un manque serveur, et
/// reessayer ne la fera pas apparaitre. Un ecran qui les melangerait proposerait
/// un « Reessayer » qui echouerait a chaque fois.
enum MotifEchecRoster {
  /// Reseau coupe, lecture refusee, reponse illisible.
  lecture,

  /// Le serveur ne projette pas cette lecture pour l'enseignant.
  ///
  /// C'est le cas du roster **par groupe** : `groupe_membres` ne porte que
  /// `student_id`, et la jointure vers `profiles` est fermee a l'enseignant par
  /// la RLS. La variante enseignant est demandee en section 1 de
  /// `docs/teaching-core/TC_CONTRACT_REQUEST_E.md`.
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
/// **Contrat produit par Agent E** (`TEACHING_CORE_CONTRACTS.md` section 12),
/// consomme par E (roster, fiche) et H (signalement, post-cours).
///
/// Quatre lectures, et **aucune ecriture** : ce port ne sait que projeter. Un
/// enseignant n'ecrit pas dans le dossier d'un eleve par ce chemin ; les gestes
/// pedagogiques passent par les ports d'Agent D et d'Agent H.
///
/// **Ce que ce port ne fait pas, et ne doit jamais faire** : reconstituer par
/// jointure une colonne que le serveur ne delivre pas. `groupe_detail()` rend un
/// `student_nom` et reste reserve a l'administration ; l'ouvrir a l'enseignant
/// serait un contournement de l'ADR-008. La variante enseignant se construit sur
/// le modele de `teacher_roster_v`, en base, et elle est demandee dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_E.md`.
abstract class PortRosterEnseignant {
  /// Le roster d'une seance : qui est inscrit, et dans quel etat.
  ///
  /// **Les inscrits, pas les connectes.** Qui n'est jamais arrive n'a aucune
  /// piste temps reel, et c'est precisement de lui que l'enseignant doit savoir
  /// quelque chose.
  Future<List<TeacherStudentProjection>> rosterDeSeance(String sessionId);

  /// Le roster d'un groupe, hors seance.
  Future<List<TeacherStudentProjection>> rosterDeGroupe(String groupeId);

  /// La fiche pedagogique d'un eleve, eventuellement situee dans une seance.
  ///
  /// [academyId] et non un identifiant de profil : c'est l'identifiant
  /// d'academie qui desambiguise deux homonymes, et il remplace le nom de
  /// famille partout (decision D-08).
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  });

  /// Le roster en continu pendant la seance.
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId);
}
