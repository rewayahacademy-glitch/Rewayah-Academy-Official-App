import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../tc_bibliotheque/content_range.dart';
import 'intention_pedagogique.dart';
import 'learning_assignment.dart';

/// La lecture et l'ecriture du travail a preparer.
///
/// **Contrat produit par Agent D** (`TEACHING_CORE_CONTRACTS.md` section 11),
/// consomme par A (slot « Avant le prochain cours »), E, H et Q.
abstract class PortAssignations {
  /// Le travail d'un groupe, eventuellement filtre sur un eleve.
  Future<List<LearningAssignment>> pourGroupe(
    String groupId, {
    String? studentId,
  });

  /// Le travail a venir, **au maximum trois**, filtre pour un eleve quand il
  /// est donne.
  ///
  /// **`studentId` filtre a la source depuis l'amendement §2.1 de
  /// `TC_CONTRACT_REQUEST_H.md`** (entérine le 21/09 par Agent Z) : sans lui, un
  /// appelant qui filtrerait apres coup pouvait recevoir moins de trois
  /// actions alors que le groupe en portait assez pour cet eleve.
  /// `null` = le groupe entier, comme [LearningAssignment.studentId].
  ///
  /// Le plafond est garanti par l'implementation, jamais par l'appelant : un
  /// slot « Avant le prochain cours » qui afficherait sept lignes serait un
  /// defaut de contrat, pas un defaut d'ecran (invariant 2 de la section 11).
  Future<List<LearningAssignment>> aVenir({
    required String groupId,
    String? studentId,
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

/// Une implementation en memoire du travail a preparer.
///
/// **DOUBLE LOCAL ASSUME.** Aucune table `learning_assignment` n'existe en base,
/// et `0022_progression_suivi.sql` interdit explicitement d'etendre
/// `rule_overrides` ou `matching_requests` avec des clefs pedagogiques : la
/// demande SQL est ecrite dans `TC_CONTRACT_REQUEST_D.md` section 3.
class AssignationsMemoire implements PortAssignations {
  /// Cree un depot en memoire, pour le createur donne.
  AssignationsMemoire(
    this._createurProfilId, {
    Uuid? generateur,
    DateTime Function()? maintenant,
  }) : _generateur = generateur ?? const Uuid(),
       _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final String _createurProfilId;
  final Uuid _generateur;
  final DateTime Function() _maintenant;
  final List<LearningAssignment> _travaux = <LearningAssignment>[];

  @override
  Future<List<LearningAssignment>> pourGroupe(
    String groupId, {
    String? studentId,
  }) async => _travaux
      .where(
        (LearningAssignment travail) =>
            travail.groupId == groupId &&
            (studentId == null ||
                travail.studentId == null ||
                travail.studentId == studentId),
      )
      .toList(growable: false);

  @override
  Future<List<LearningAssignment>> aVenir({
    required String groupId,
    String? studentId,
    int limite = 3,
  }) async {
    final List<LearningAssignment> ouverts =
        _travaux
            .where(
              (LearningAssignment travail) =>
                  travail.groupId == groupId &&
                  (studentId == null ||
                      travail.studentId == null ||
                      travail.studentId == studentId) &&
                  (travail.status == StatutAssignation.aFaire ||
                      travail.status == StatutAssignation.enCours),
            )
            .toList()
          // Le plus urgent d'abord : une echeance proche passe devant une
          // echeance lointaine, et une absence d'echeance passe en dernier.
          ..sort(_parUrgence);
    return List<LearningAssignment>.unmodifiable(
      ouverts.take(limite < 0 ? 0 : limite),
    );
  }

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
    final LearningAssignment travail = LearningAssignment(
      id: _generateur.v4(),
      groupId: groupId,
      studentId: studentId,
      resourceId: resourceId,
      resourceVersionId: resourceVersionId,
      contentRange: contentRange,
      purpose: purpose,
      instructions: instructions,
      startsAtUtc: _maintenant(),
      dueAtUtc: dueAtUtc,
      createdBy: _createurProfilId,
      status: StatutAssignation.aFaire,
    );
    _travaux.add(travail);
    return travail;
  }

  @override
  Future<void> changerStatut(
    String assignmentId,
    StatutAssignation statut,
  ) async {
    final int rang = _travaux.indexWhere(
      (LearningAssignment travail) => travail.id == assignmentId,
    );
    if (rang == -1) {
      throw StateError('travail inconnu : $assignmentId');
    }
    _travaux[rang] = _travaux[rang].avecStatut(statut);
  }

  static int _parUrgence(LearningAssignment a, LearningAssignment b) {
    final DateTime? echeanceA = a.dueAtUtc;
    final DateTime? echeanceB = b.dueAtUtc;
    if (echeanceA == null && echeanceB == null) {
      return a.startsAtUtc.compareTo(b.startsAtUtc);
    }
    if (echeanceA == null) {
      return 1;
    }
    if (echeanceB == null) {
      return -1;
    }
    return echeanceA.compareTo(echeanceB);
  }
}

/// Le depot du travail a preparer employe par l'application.
final Provider<PortAssignations> portAssignationsProvider =
    Provider<PortAssignations>(
      (Ref ref) => throw UnimplementedError(
        'PortAssignations : aucune implementation serveur. '
        'Surcharger ce provider (AssignationsMemoire en attendant la table).',
      ),
    );
