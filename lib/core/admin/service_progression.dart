import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le type d'une exception de progression.
enum TypeExceptionProgression {
  /// L'eleve ne peut pas progresser en l'etat : quelque chose bloque.
  blocage('blocage'),

  /// Une derogation ponctuelle, hors regle habituelle.
  derogation('derogation');

  const TypeExceptionProgression(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. Se replie sur `blocage`, le plus
  /// visible des deux : une valeur mal lue ne doit jamais passer inapercue.
  static TypeExceptionProgression depuisSql(String? valeur) =>
      valeur == 'derogation'
      ? TypeExceptionProgression.derogation
      : TypeExceptionProgression.blocage;
}

/// Un eleve, sa progression courante, vu par l'administration.
///
/// **Groupe et niveau peuvent etre nuls** : un eleve sans groupe actif (entre
/// deux groupes) ou sans niveau decide (diagnostic non encore fait, voir
/// `ADM-10`) reste visible -- c'est la meme discipline que `ADM-08`
/// (« une personne sans piece deposee est visible »).
@immutable
class EleveProgression {
  /// Cree une ligne de progression.
  const EleveProgression({
    required this.studentId,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.groupeId,
    required this.groupeLibelle,
    required this.niveauId,
    required this.niveauNomHumain,
    required this.niveauCycle,
    required this.niveauDepuis,
    required this.exceptionActiveId,
    required this.exceptionActiveType,
  });

  /// Lit une ligne rendue par `progression_admin()`.
  factory EleveProgression.depuisJson(Map<String, dynamic> json) =>
      EleveProgression(
        studentId: json['student_id'] as String,
        identifiant: json['student_immutable_id'] as String? ?? '',
        prenom: json['student_prenom'] as String?,
        nom: json['student_nom'] as String?,
        groupeId: json['groupe_id'] as String?,
        groupeLibelle: json['groupe_libelle'] as String?,
        niveauId: json['niveau_id'] as String?,
        niveauNomHumain: json['niveau_nom_humain'] as String?,
        niveauCycle: json['niveau_cycle'] as String?,
        niveauDepuis: DateTime.tryParse(json['niveau_depuis'] as String? ?? '')
            ?.toLocal(),
        exceptionActiveId: json['exception_active_id'] as String?,
        exceptionActiveType: json['exception_active_type'] == null
            ? null
            : TypeExceptionProgression.depuisSql(
                json['exception_active_type'] as String?,
              ),
      );

  /// L'identifiant technique de l'eleve.
  final String studentId;

  /// L'identifiant immuable de l'eleve.
  final String identifiant;

  /// Le prenom. Nul quand l'identite est masquee.
  final String? prenom;

  /// Le nom. Nul dans les memes conditions.
  final String? nom;

  /// Le groupe actif de l'eleve, nul s'il n'en a pas.
  final String? groupeId;

  /// Le libelle de ce groupe.
  final String? groupeLibelle;

  /// Le niveau courant, nul si aucun diagnostic n'a encore ete decide.
  final String? niveauId;

  /// Le nom humain de ce niveau.
  final String? niveauNomHumain;

  /// Le cycle de ce niveau.
  final String? niveauCycle;

  /// La date d'entree dans ce niveau.
  final DateTime? niveauDepuis;

  /// L'exception active de l'eleve, nulle s'il n'en a pas.
  final String? exceptionActiveId;

  /// Le type de cette exception.
  final TypeExceptionProgression? exceptionActiveType;

  /// Ce qui s'affiche pour nommer l'eleve.
  String get libelle {
    final String complet = <String?>[
      prenom,
      nom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? identifiant : complet;
  }
}

/// Le suivi de progression par l'administration.
abstract interface class ServiceProgression {
  /// Tous les eleves actifs, groupe par groupe.
  Future<List<EleveProgression>> tous();

  /// Pose une exception (blocage ou derogation) sur un eleve. Refuse si une
  /// exception du meme type est deja active.
  Future<String> poserException({
    required String studentId,
    required TypeExceptionProgression type,
    required String motif,
  });

  /// Clot une exception active.
  Future<void> clorerException({
    required String exceptionId,
    required String motif,
  });

  /// Change manuellement le niveau d'un eleve deja diagnostique.
  Future<String> promouvoir({
    required String studentId,
    required String niveauId,
    required String motif,
  });
}

/// L'implementation reelle.
class ServiceProgressionSupabase implements ServiceProgression {
  /// Cree le service.
  const ServiceProgressionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EleveProgression>> tous() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'progression_admin',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              EleveProgression.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<String> poserException({
    required String studentId,
    required TypeExceptionProgression type,
    required String motif,
  }) => _client.rpc<String>(
    'poser_exception_progression',
    params: <String, dynamic>{
      'p_student_id': studentId,
      'p_type': type.valeurSql,
      'p_motif': motif,
    },
  );

  @override
  Future<void> clorerException({
    required String exceptionId,
    required String motif,
  }) => _client.rpc<void>(
    'clore_exception_progression',
    params: <String, dynamic>{'p_exception_id': exceptionId, 'p_motif': motif},
  );

  @override
  Future<String> promouvoir({
    required String studentId,
    required String niveauId,
    required String motif,
  }) => _client.rpc<String>(
    'progression_promouvoir',
    params: <String, dynamic>{
      'p_student_id': studentId,
      'p_niveau_id': niveauId,
      'p_motif': motif,
    },
  );
}

/// Le service de progression employe par l'application.
final Provider<ServiceProgression> serviceProgressionProvider =
    Provider<ServiceProgression>(
      (Ref ref) => ServiceProgressionSupabase(Supabase.instance.client),
    );

/// La progression de tous les eleves, pour l'ecran Admin > Pedagogie >
/// Progression.
final FutureProvider<List<EleveProgression>> progressionProvider =
    FutureProvider<List<EleveProgression>>(
      (Ref ref) => ref.watch(serviceProgressionProvider).tous(),
    );
