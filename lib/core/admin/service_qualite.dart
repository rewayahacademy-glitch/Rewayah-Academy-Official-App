import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le type d'une anomalie pedagogique detectee.
enum TypeAnomalieQualite {
  /// Une seance tenue sans rapport de seance (`lesson_reports`).
  rapportManquant('rapport_manquant'),

  /// Un blocage de progression actif depuis plus de sept jours.
  blocageSansSuivi('blocage_sans_suivi'),

  /// Une evaluation encore planifiee alors que sa date prevue est passee.
  evaluationEnRetard('evaluation_en_retard');

  const TypeAnomalieQualite(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. Se replie sur `rapportManquant` : une
  /// valeur mal lue ne doit jamais disparaitre silencieusement de la liste.
  static TypeAnomalieQualite depuisSql(String? valeur) => switch (valeur) {
    'blocage_sans_suivi' => TypeAnomalieQualite.blocageSansSuivi,
    'evaluation_en_retard' => TypeAnomalieQualite.evaluationEnRetard,
    _ => TypeAnomalieQualite.rapportManquant,
  };
}

/// Le statut de controle d'une anomalie.
enum StatutControleQualite {
  /// Detectee, pas encore revue.
  ouvert('ouvert'),

  /// Revue par l'administration.
  traite('traite');

  const StatutControleQualite(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. Se replie sur `ouvert`.
  static StatutControleQualite depuisSql(String? valeur) =>
      valeur == 'traite'
      ? StatutControleQualite.traite
      : StatutControleQualite.ouvert;
}

/// Une anomalie pedagogique, vue par l'administration.
///
/// **Calculee, jamais stockee** : `anomalies_qualite()` (migration `0024`)
/// recoupe `sessions`/`lesson_reports`, `progression_exceptions` et
/// `evaluations` a chaque lecture. Seul le controle (« traite » ou non) est
/// retenu, dans `controles_qualite`.
@immutable
class AnomalieQualite {
  /// Cree une ligne d'anomalie.
  const AnomalieQualite({
    required this.type,
    required this.refId,
    required this.studentId,
    required this.studentPrenom,
    required this.studentNom,
    required this.teacherId,
    required this.teacherPrenom,
    required this.teacherNom,
    required this.depuis,
    required this.controleStatut,
    required this.controleNote,
  });

  /// Lit une ligne rendue par `anomalies_qualite()`.
  factory AnomalieQualite.depuisJson(Map<String, dynamic> json) =>
      AnomalieQualite(
        type: TypeAnomalieQualite.depuisSql(json['type_anomalie'] as String?),
        refId: json['ref_id'] as String,
        studentId: json['student_id'] as String?,
        studentPrenom: json['student_prenom'] as String?,
        studentNom: json['student_nom'] as String?,
        teacherId: json['teacher_id'] as String?,
        teacherPrenom: json['teacher_prenom'] as String?,
        teacherNom: json['teacher_nom'] as String?,
        depuis:
            DateTime.tryParse(
              json['depuis'] as String? ?? '',
            )?.toLocal() ??
            DateTime.now(),
        controleStatut: StatutControleQualite.depuisSql(
          json['controle_statut'] as String?,
        ),
        controleNote: json['controle_note'] as String?,
      );

  /// Le type d'anomalie.
  final TypeAnomalieQualite type;

  /// L'identifiant de la ligne source (seance, exception ou evaluation).
  final String refId;

  /// L'eleve concerne, nul pour un rapport manquant (l'anomalie porte sur
  /// l'enseignant qui devait rediger le rapport).
  final String? studentId;

  /// Le prenom de cet eleve. Nul aussi quand l'identite est masquee.
  final String? studentPrenom;

  /// Le nom de cet eleve.
  final String? studentNom;

  /// L'enseignant concerne, non nul seulement pour un rapport manquant.
  final String? teacherId;

  /// Le prenom de cet enseignant. Nul aussi quand l'identite est masquee.
  final String? teacherPrenom;

  /// Le nom de cet enseignant.
  final String? teacherNom;

  /// Depuis quand l'anomalie existe (date de la seance, de la pose du
  /// blocage, ou date prevue de l'evaluation).
  final DateTime depuis;

  /// Le statut de controle.
  final StatutControleQualite controleStatut;

  /// La note laissee lors du dernier traitement.
  final String? controleNote;

  /// Ce qui s'affiche pour nommer la personne concernee : l'eleve pour un
  /// blocage ou une evaluation, l'enseignant pour un rapport manquant.
  String get personneLibelle {
    final String? identifiant = studentId ?? teacherId;
    final String complet = <String?>[
      studentPrenom ?? teacherPrenom,
      studentNom ?? teacherNom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? (identifiant ?? '') : complet;
  }

  /// Le nombre de jours entiers ecoules depuis [depuis].
  int joursDepuis(DateTime maintenant) => maintenant.difference(depuis).inDays;
}

/// Le contrôle qualité pédagogique par l'administration.
abstract interface class ServiceQualite {
  /// Toutes les anomalies detectees, les plus anciennes d'abord.
  Future<List<AnomalieQualite>> anomalies();

  /// Marque une anomalie comme traitee. Idempotent : re-traiter met a jour
  /// la note plutot que dupliquer.
  Future<void> traiter({
    required TypeAnomalieQualite type,
    required String refId,
    String? note,
  });
}

/// L'implementation reelle.
class ServiceQualiteSupabase implements ServiceQualite {
  /// Cree le service.
  const ServiceQualiteSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AnomalieQualite>> anomalies() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'anomalies_qualite',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              AnomalieQualite.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<void> traiter({
    required TypeAnomalieQualite type,
    required String refId,
    String? note,
  }) => _client.rpc<void>(
    'traiter_anomalie_qualite',
    params: <String, dynamic>{
      'p_type_anomalie': type.valeurSql,
      'p_ref_id': refId,
      'p_note': note,
    },
  );
}

/// Le service de qualite employe par l'application.
final Provider<ServiceQualite> serviceQualiteProvider =
    Provider<ServiceQualite>(
      (Ref ref) => ServiceQualiteSupabase(Supabase.instance.client),
    );

/// Les anomalies pedagogiques, pour l'ecran Admin > Pedagogie > Qualite.
final FutureProvider<List<AnomalieQualite>> anomaliesQualiteProvider =
    FutureProvider<List<AnomalieQualite>>(
      (Ref ref) => ref.watch(serviceQualiteProvider).anomalies(),
    );
