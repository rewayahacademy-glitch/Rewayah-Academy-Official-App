import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un eleve dont le niveau de placement n'a jamais ete decide.
///
/// **La file** : tout eleve actif absent de `progression_historique`
/// (migration `0021`) -- calculee, jamais une colonne « a diagnostiquer » a
/// garder synchronisee.
@immutable
class EleveADiagnostiquer {
  /// Cree une ligne de file.
  const EleveADiagnostiquer({
    required this.studentId,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.inscritDepuis,
  });

  /// Lit une ligne rendue par `diagnostics_a_traiter()`.
  factory EleveADiagnostiquer.depuisJson(Map<String, dynamic> json) =>
      EleveADiagnostiquer(
        studentId: json['student_id'] as String,
        identifiant: json['student_immutable_id'] as String? ?? '',
        prenom: json['student_prenom'] as String?,
        nom: json['student_nom'] as String?,
        inscritDepuis:
            DateTime.tryParse(
              json['inscrit_depuis'] as String? ?? '',
            )?.toLocal() ??
            DateTime.now(),
      );

  /// L'identifiant technique de l'eleve.
  final String studentId;

  /// L'identifiant immuable de l'eleve.
  final String identifiant;

  /// Le prenom. Nul quand l'identite est masquee.
  final String? prenom;

  /// Le nom. Nul dans les memes conditions.
  final String? nom;

  /// La date d'inscription, qui mesure l'attente.
  final DateTime inscritDepuis;

  /// Ce qui s'affiche pour nommer l'eleve.
  String get libelle {
    final String complet = <String?>[
      prenom,
      nom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? identifiant : complet;
  }

  /// Le nombre de jours entiers ecoules depuis l'inscription.
  int joursDAttente(DateTime maintenant) =>
      maintenant.difference(inscritDepuis).inDays;
}

/// La decision de placement par l'administration.
abstract interface class ServiceDiagnostics {
  /// La file des eleves sans niveau decide, les plus anciens d'abord.
  Future<List<EleveADiagnostiquer>> aTraiter();

  /// Decide le premier placement d'un eleve sur un niveau du programme.
  /// Refuse si l'eleve a deja un niveau decide (voir Progression).
  Future<void> deciderPlacement({
    required String studentId,
    required String niveauId,
    required String motif,
  });
}

/// L'implementation reelle.
class ServiceDiagnosticsSupabase implements ServiceDiagnostics {
  /// Cree le service.
  const ServiceDiagnosticsSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EleveADiagnostiquer>> aTraiter() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'diagnostics_a_traiter',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              EleveADiagnostiquer.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deciderPlacement({
    required String studentId,
    required String niveauId,
    required String motif,
  }) => _client.rpc<void>(
    'decider_placement',
    params: <String, dynamic>{
      'p_student_id': studentId,
      'p_niveau_id': niveauId,
      'p_motif': motif,
    },
  );
}

/// Le service des diagnostics employe par l'application.
final Provider<ServiceDiagnostics> serviceDiagnosticsProvider =
    Provider<ServiceDiagnostics>(
      (Ref ref) => ServiceDiagnosticsSupabase(Supabase.instance.client),
    );

/// La file des diagnostics, pour l'ecran Admin > Pedagogie > Diagnostics.
final FutureProvider<List<EleveADiagnostiquer>> diagnosticsATraiterProvider =
    FutureProvider<List<EleveADiagnostiquer>>(
      (Ref ref) => ref.watch(serviceDiagnosticsProvider).aTraiter(),
    );
