import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le type d'une evaluation.
enum TypeEvaluation {
  /// La toute premiere evaluation d'un eleve sur un niveau.
  initiale('initiale'),

  /// Une evaluation de suivi reguliere.
  periodique('periodique'),

  /// Une nouvelle tentative apres un echec.
  reevaluation('reevaluation'),

  /// Valide l'acquisition d'un niveau ou d'un cycle.
  certification('certification');

  const TypeEvaluation(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. Se replie sur `periodique`, le type
  /// le plus neutre : une valeur mal lue ne doit jamais se faire passer pour
  /// une certification.
  static TypeEvaluation depuisSql(String? valeur) => switch (valeur) {
    'initiale' => TypeEvaluation.initiale,
    'reevaluation' => TypeEvaluation.reevaluation,
    'certification' => TypeEvaluation.certification,
    _ => TypeEvaluation.periodique,
  };
}

/// Le statut d'une evaluation.
enum StatutEvaluation {
  /// Prevue, pas encore realisee.
  planifiee('planifiee'),

  /// Realisee, avec un resultat.
  realisee('realisee'),

  /// Annulee avant d'avoir eu lieu.
  annulee('annulee');

  const StatutEvaluation(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. Se replie sur `planifiee`.
  static StatutEvaluation depuisSql(String? valeur) => switch (valeur) {
    'realisee' => StatutEvaluation.realisee,
    'annulee' => StatutEvaluation.annulee,
    _ => StatutEvaluation.planifiee,
  };
}

/// Le resultat d'une evaluation realisee.
enum ResultatEvaluation {
  /// Le niveau est acquis.
  reussi('reussi'),

  /// Le niveau n'est pas acquis.
  echec('echec'),

  /// A reprendre avant de trancher.
  aRevoir('a_revoir');

  const ResultatEvaluation(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un resultat depuis sa valeur SQL. Nul si l'evaluation n'est pas
  /// encore realisee.
  static ResultatEvaluation? depuisSql(String? valeur) => switch (valeur) {
    'reussi' => ResultatEvaluation.reussi,
    'echec' => ResultatEvaluation.echec,
    'a_revoir' => ResultatEvaluation.aRevoir,
    _ => null,
  };
}

/// Une evaluation, vue par l'administration.
///
/// **Une certification est une evaluation** de [TypeEvaluation.certification]
/// reussie -- pas un objet separe. Une reevaluation, de meme, est une
/// nouvelle ligne apres un `echec` (migration `0023`).
@immutable
class EvaluationAdmin {
  /// Cree une ligne d'evaluation.
  const EvaluationAdmin({
    required this.id,
    required this.studentId,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.niveauId,
    required this.niveauNomHumain,
    required this.type,
    required this.statut,
    required this.datePrevue,
    required this.dateRealisee,
    required this.resultat,
    required this.notes,
  });

  /// Lit une ligne rendue par `evaluations_admin()`.
  factory EvaluationAdmin.depuisJson(Map<String, dynamic> json) =>
      EvaluationAdmin(
        id: json['evaluation_id'] as String,
        studentId: json['student_id'] as String,
        identifiant: json['student_immutable_id'] as String? ?? '',
        prenom: json['student_prenom'] as String?,
        nom: json['student_nom'] as String?,
        niveauId: json['niveau_id'] as String,
        niveauNomHumain: json['niveau_nom_humain'] as String? ?? '',
        type: TypeEvaluation.depuisSql(json['type'] as String?),
        statut: StatutEvaluation.depuisSql(json['statut'] as String?),
        datePrevue:
            DateTime.tryParse(json['date_prevue'] as String? ?? '') ??
            DateTime.now(),
        dateRealisee: DateTime.tryParse(
          json['date_realisee'] as String? ?? '',
        ),
        resultat: ResultatEvaluation.depuisSql(json['resultat'] as String?),
        notes: json['notes'] as String?,
      );

  /// L'identifiant technique de l'evaluation.
  final String id;

  /// L'identifiant technique de l'eleve evalue.
  final String studentId;

  /// L'identifiant immuable de l'eleve.
  final String identifiant;

  /// Le prenom de l'eleve. Nul quand l'identite est masquee.
  final String? prenom;

  /// Le nom de l'eleve. Nul dans les memes conditions.
  final String? nom;

  /// Le niveau evalue.
  final String niveauId;

  /// Le nom humain de ce niveau.
  final String niveauNomHumain;

  /// Le type d'evaluation.
  final TypeEvaluation type;

  /// Le statut courant.
  final StatutEvaluation statut;

  /// La date prevue.
  final DateTime datePrevue;

  /// La date de realisation, nulle tant que l'evaluation n'a pas eu lieu.
  final DateTime? dateRealisee;

  /// Le resultat, nul tant que l'evaluation n'a pas eu lieu.
  final ResultatEvaluation? resultat;

  /// Des notes libres.
  final String? notes;

  /// Ce qui s'affiche pour nommer l'eleve.
  String get eleveLibelle {
    final String complet = <String?>[
      prenom,
      nom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? identifiant : complet;
  }
}

/// La gestion des evaluations par l'administration.
abstract interface class ServiceEvaluations {
  /// Toutes les evaluations, planifiees d'abord puis les plus recentes.
  Future<List<EvaluationAdmin>> toutes();

  /// Planifie une evaluation.
  Future<String> planifier({
    required String studentId,
    required String niveauId,
    required TypeEvaluation type,
    required DateTime datePrevue,
  });

  /// Enregistre le resultat d'une evaluation planifiee.
  Future<void> enregistrerResultat({
    required String evaluationId,
    required ResultatEvaluation resultat,
    String? notes,
  });

  /// Annule une evaluation planifiee.
  Future<void> annuler({required String evaluationId, required String motif});
}

/// L'implementation reelle.
class ServiceEvaluationsSupabase implements ServiceEvaluations {
  /// Cree le service.
  const ServiceEvaluationsSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EvaluationAdmin>> toutes() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'evaluations_admin',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              EvaluationAdmin.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<String> planifier({
    required String studentId,
    required String niveauId,
    required TypeEvaluation type,
    required DateTime datePrevue,
  }) => _client.rpc<String>(
    'planifier_evaluation',
    params: <String, dynamic>{
      'p_student_id': studentId,
      'p_niveau_id': niveauId,
      'p_type': type.valeurSql,
      'p_date_prevue': _iso(datePrevue),
    },
  );

  @override
  Future<void> enregistrerResultat({
    required String evaluationId,
    required ResultatEvaluation resultat,
    String? notes,
  }) => _client.rpc<void>(
    'enregistrer_resultat_evaluation',
    params: <String, dynamic>{
      'p_evaluation_id': evaluationId,
      'p_resultat': resultat.valeurSql,
      'p_notes': notes,
    },
  );

  @override
  Future<void> annuler({
    required String evaluationId,
    required String motif,
  }) => _client.rpc<void>(
    'annuler_evaluation',
    params: <String, dynamic>{
      'p_evaluation_id': evaluationId,
      'p_motif': motif,
    },
  );
}

/// Le service des evaluations employe par l'application.
final Provider<ServiceEvaluations> serviceEvaluationsProvider =
    Provider<ServiceEvaluations>(
      (Ref ref) => ServiceEvaluationsSupabase(Supabase.instance.client),
    );

/// Les evaluations, pour l'ecran Admin > Pedagogie > Evaluations.
final FutureProvider<List<EvaluationAdmin>> evaluationsProvider =
    FutureProvider<List<EvaluationAdmin>>(
      (Ref ref) => ref.watch(serviceEvaluationsProvider).toutes(),
    );
