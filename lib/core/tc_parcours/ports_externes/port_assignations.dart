// TC-STUB-PORT: canonique = lib/core/tc_outils/port_assignations.dart (Agent D)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 11, verifiee
// mot pour mot contre le fichier publie par Agent D.
// **La classe abstraite seule.** L'implementation en memoire d'Agent D et son
// provider ne sont pas recopies : un stub ne porte jamais d'implementation.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
import '../../tc_bibliotheque/content_range.dart';
import 'intention_pedagogique.dart';
import 'learning_assignment.dart';

/// La lecture et l'ecriture du travail a preparer.
///
/// **Contrat produit par Agent D**, consomme ici par `PortTravailAVenir` (le
/// slot « Avant le prochain cours ») et par le post-cours, qui propose un
/// travail sans jamais le poser d'autorite.
abstract class PortAssignations {
  /// Le travail d'un groupe, eventuellement filtre sur un eleve.
  Future<List<LearningAssignment>> pourGroupe(
    String groupId, {
    String? studentId,
  });

  /// Le travail a venir, **au maximum trois**.
  ///
  /// Le plafond est garanti par l'implementation, jamais par l'appelant.
  Future<List<LearningAssignment>> aVenir({
    required String groupId,
    int limite = 3,
  });

  /// Cree un travail depuis la selection courante. **Sans formulaire long.**
  Future<LearningAssignment> creerDepuisSelection({
    required String groupId,
    String? studentId,
    required String resourceId,
    String? resourceVersionId,
    ContentRange? contentRange,
    required IntentionPedagogique purpose,
    String? instructions,
    DateTime? dueAtUtc,
  });

  /// Change l'etat d'un travail.
  Future<void> changerStatut(String assignmentId, StatutAssignation statut);
}
