import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une valeur de `app_config`, telle que Configuration > Regles /
/// Fonctionnalites / Conservation des donnees l'editent.
///
/// **Le defaut de plateforme, jamais une exception de profil.** Certaines de
/// ces cles (`session_duration_minutes`, `max_students_per_teacher`...) ont
/// deja une surcharge par profil sous Operations > Regles individuelles
/// (`rule_overrides`, `core/regles/service_regles.dart`). Ce service n'y
/// touche pas : il edite uniquement la valeur qui s'applique quand aucune
/// surcharge n'existe -- deux natures differentes, deux routes canoniques,
/// jamais le meme reglage a deux endroits (`ADMIN_FINANCE_CONFIGURATION.md`).
@immutable
class ValeurConfig {
  /// Cree une valeur lue.
  const ValeurConfig({required this.cle, required this.valeur});

  /// Lit une ligne de `app_config`.
  factory ValeurConfig.depuisJson(Map<String, dynamic> json) =>
      ValeurConfig(cle: json['key'] as String, valeur: json['value']);

  /// La cle, telle que la base la connait.
  final String cle;

  /// La valeur brute (`jsonb`) : un entier ou un booleen selon la cle.
  final Object? valeur;

  /// La valeur lue comme un entier. Se replie sur zero -- une cle jamais
  /// seedee ne doit pas faire planter l'ecran, seulement afficher un defaut
  /// visiblement suspect.
  int get versEntier => switch (valeur) {
    final num n => n.toInt(),
    _ => 0,
  };

  /// La valeur lue comme un booleen.
  bool get versBooleen => valeur == true;
}

/// Lecture et ecriture directe de `app_config` (admin uniquement -- RLS
/// `app_config_admin_read`/`app_config_admin_update`, migration `0001`).
///
/// **Jamais par RPC** : contrairement a `video_config` (Classe en ligne, qui
/// n'a pas encore de fonction d'ecriture), `app_config` porte deja les trois
/// policies admin directement sur la table.
abstract interface class ServiceConfiguration {
  /// Les valeurs actuelles des [cles] demandees, dans l'ordre demande.
  Future<List<ValeurConfig>> lire(List<String> cles);

  /// Ecrit une valeur. Le trigger `app_config_history` journalise l'ancienne
  /// valeur automatiquement -- rien a faire ici pour l'historique.
  Future<void> ecrire(String cle, Object valeur);
}

/// L'implementation reelle.
class ServiceConfigurationSupabase implements ServiceConfiguration {
  /// Cree le service.
  const ServiceConfigurationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('app_config')
        .select()
        .inFilter('key', cles);
    final Map<String, ValeurConfig> parCle = <String, ValeurConfig>{
      for (final Map<String, dynamic> ligne in lignes)
        (ligne['key'] as String): ValeurConfig.depuisJson(ligne),
    };
    // L'ordre demande, jamais celui rendu par postgrest : une cle jamais
    // seedee ne doit pas disparaitre silencieusement de l'ecran.
    return <ValeurConfig>[
      for (final String cle in cles)
        parCle[cle] ?? ValeurConfig(cle: cle, valeur: null),
    ];
  }

  @override
  Future<void> ecrire(String cle, Object valeur) => _client
      .from('app_config')
      .update(<String, dynamic>{
        'value': valeur,
        'updated_by': _client.auth.currentUser?.id,
      })
      .eq('key', cle);
}

/// Le service de configuration employe par l'application.
final Provider<ServiceConfiguration> serviceConfigurationProvider =
    Provider<ServiceConfiguration>(
      (Ref ref) => ServiceConfigurationSupabase(Supabase.instance.client),
    );

/// Les cles du domaine Configuration > Regles -- les defauts de plateforme,
/// jamais les surcharges par profil (Operations > Regles individuelles).
const List<String> clesRegles = <String>[
  'absence_threshold_minutes',
  'session_duration_minutes',
  'session_paid_minimum_minutes',
  'break_minutes_between_sessions',
  'max_students_per_teacher',
  'matching_horizon_weeks',
  'camera_auto_allow_min_age',
  'child_ui_mode_max_age',
  'max_devices_per_student',
  'max_concurrent_sessions_per_profile',
];

/// Les cles du domaine Configuration > Fonctionnalites.
const List<String> clesFonctionnalites = <String>[
  'allow_multi_participant_sessions',
  'max_participants_per_session',
];

/// Les cles du domaine Configuration > Conservation des donnees.
const List<String> clesConservationDonnees = <String>[
  'recording_retention_days',
  'kyc_retention_days',
];

/// Les valeurs de Configuration > Regles.
final FutureProvider<List<ValeurConfig>> valeursReglesProvider =
    FutureProvider<List<ValeurConfig>>(
      (Ref ref) => ref.watch(serviceConfigurationProvider).lire(clesRegles),
    );

/// Les valeurs de Configuration > Fonctionnalites.
final FutureProvider<List<ValeurConfig>> valeursFonctionnalitesProvider =
    FutureProvider<List<ValeurConfig>>(
      (Ref ref) =>
          ref.watch(serviceConfigurationProvider).lire(clesFonctionnalites),
    );

/// Les valeurs de Configuration > Conservation des donnees.
final FutureProvider<List<ValeurConfig>> valeursConservationDonneesProvider =
    FutureProvider<List<ValeurConfig>>(
      (Ref ref) => ref
          .watch(serviceConfigurationProvider)
          .lire(clesConservationDonnees),
    );
