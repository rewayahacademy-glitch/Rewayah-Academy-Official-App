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

/// La cle du reglage « Depassement autorise apres la fin prevue ».
const String cleDepassementSeance = 'grace_after_end_minutes';

/// Les cles du domaine Configuration > Regles -- les defauts de plateforme,
/// jamais les surcharges par profil (Operations > Regles individuelles).
const List<String> clesRegles = <String>[
  'absence_threshold_minutes',
  'session_duration_minutes',
  'session_paid_minimum_minutes',
  'break_minutes_between_sessions',
  // CHRONO-ETAT (directeur, 11/11/2026) : le depassement autorise apres la
  // fin prevue d'une seance (la salle reste ouverte, le chrono compte en
  // plus). La cle existe depuis `0033_tc_vues_rpc.sql` ; elle devient
  // reglable par la direction.
  cleDepassementSeance,
  'max_students_per_teacher',
  'matching_horizon_weeks',
  'camera_auto_allow_min_age',
  'child_ui_mode_max_age',
  'max_devices_per_student',
  'max_concurrent_sessions_per_profile',
  // Le nombre maximal de Classes par enseignant (decision du directeur du
  // 22/10/2026, migration 20261022000200_classes_plafond_par_enseignant.sql) :
  // 3 par defaut, de 1 a 80. Un serveur d'avant ce lot ne la rend pas.
  cleClassesParEnseignant,
  // L'enseignant qui n'a pas rejoint la salle (regle A3, migration
  // 20261102500000_remplacement_auto.sql) : trois minutes comptees depuis le
  // debut de la seance, dans cet ordre strict. Reglables ici sur demande du
  // directeur du 01/11/2026. Un serveur d'avant A3 ne les rend pas.
  ...clesRemplacement,
  // A3-bis (02/11/2026, migration 20261105700000) : l'alerte a la direction
  // quand personne n'est dans la salle, et la seance creee tard. Un serveur
  // d'avant A3-bis ne les rend pas.
  ...clesRemplacementA3bis,
  // SNT (03/11/2026, migration 20261106500000) : la seance non tenue,
  // reportee. Un serveur d'avant SNT ne la rend pas.
  cleRemplacementSeanceNonTenue,
  // V1-a (03/11/2026, migration 20261108000001) : la regle des fondateurs
  // d'un entretien, reglee ici (V2-a). Un serveur d'avant V1-a ne les rend pas.
  cleEntretiensRegleFondateurs,
  cleEntretiensFondateursMinimum,
  // REVENUS-VERITE (06/11/2026, migration 20261110200000) : le jour de paie,
  // un objet {"jourDebut", "jourFin"}. Un serveur d'avant ce lot ne le rend
  // pas.
  clePaieFenetreVersement,
  // PRIERE-1 (12/11/2026, migration 20261123930000) : les reglages de la
  // priere de toute l'academie. Un serveur d'avant ce lot ne les rend pas.
  ...clesPriere,
];

/// PRIERE-1 : les reglages de la priere, `app_config` (cles `priere.*`).
const String clePriereMethode = 'priere.methode_defaut';

/// L'ecole pour l'Asr de l'academie.
const String clePriereEcoleAsr = 'priere.ecole_asr_defaut';

/// La duree de la pause de priere.
const String clePrierePause = 'priere.pause_minutes';

/// La duree de la pause du Maghrib pendant le Ramadan.
const String clePrierePauseRamadan = 'priere.pause_ramadan_maghrib_minutes';

/// Le Ramadan est en cours (pose a la main, en attendant le calendrier).
const String clePriereRamadan = 'priere.ramadan_en_cours';

/// La marge de debut de seance.
const String clePriereMargeDebut = 'priere.debut_marge_minutes';

/// La marge de fin de seance.
const String clePriereMargeFin = 'priere.fin_marge_minutes';

/// L'horizon du recalcul de nuit, en jours.
const String clePriereHorizon = 'priere.horizon_jours';

/// Une priere entree moins de ce temps avant le cours, dont le temps se ferme
/// pendant le cours, porte la pause (arbitrage du 13/11/2026).
const String clePriereMargeAvant = 'priere.marge_avant_cours_minutes';

/// Le debut de cette pause, apres le debut du cours.
const String clePriereDelaiFermeture = 'priere.delai_fermeture_minutes';

/// La methode usuelle du pays du lieu s'applique (PRIERE-2, vrai par defaut).
const String clePriereMethodeSelonPays = 'priere.methode_selon_pays';

/// Toutes les cles de la priere de l'academie.
const List<String> clesPriere = <String>[
  clePriereMethode,
  clePriereEcoleAsr,
  clePrierePause,
  clePrierePauseRamadan,
  clePriereRamadan,
  clePriereMargeDebut,
  clePriereMargeFin,
  clePriereHorizon,
  clePriereMargeAvant,
  clePriereDelaiFermeture,
  clePriereMethodeSelonPays,
];

/// REVENUS-VERITE : la fenetre du jour de paie, du jour `jourDebut` au jour
/// `jourFin` du mois suivant (defaut du 1er au 10 ; 1 <= debut <= fin <= 28,
/// verifie par le declencheur `app_config_paie_fenetre_versement`).
const String clePaieFenetreVersement = 'paie.fenetre_versement';

/// Les deux jours du jour de paie, lus dans [valeur] ; nul si la valeur n'a
/// pas cette forme.
({int debut, int fin})? fenetreVersementDe(Object? valeur) => switch (valeur) {
  {'jourDebut': final num debut, 'jourFin': final num fin} => (
    debut: debut.toInt(),
    fin: fin.toInt(),
  ),
  _ => null,
};

/// V1-a : la regle des fondateurs d'un entretien est-elle active (vrai par
/// defaut) ?
const String cleEntretiensRegleFondateurs =
    'entretiens.regle_fondateurs_active';

/// V1-a : le nombre minimum de fondateurs parmi les participants d'un
/// entretien (2 par defaut, de 1 a 99).
const String cleEntretiensFondateursMinimum = 'entretiens.fondateurs_minimum';

/// La cle du reglage « Classes au plus par enseignant ».
const String cleClassesParEnseignant = 'enseignant.classes_max';

/// A3 : l'enseignant est prevenu qu'il va perdre la seance (3 par defaut).
const String cleRemplacementAvertissement =
    'remplacement.avertissement_minutes';

/// A3 : l'enseignant est note absent et perd la seance du jour (8 par defaut).
const String cleRemplacementPerteAcces = 'remplacement.perte_acces_minutes';

/// A3 : l'objectif, le remplacant est dans la salle (11 par defaut).
const String cleRemplacementObjectif = 'remplacement.debut_remplacant_minutes';

/// Les trois reglages A3, dans l'ordre que le serveur exige :
/// avertissement < perte de la seance < objectif.
const List<String> clesRemplacement = <String>[
  cleRemplacementAvertissement,
  cleRemplacementPerteAcces,
  cleRemplacementObjectif,
];

/// A3-bis : la direction recoit un e-mail si ni l'enseignant ni un remplacant
/// n'a rejoint la salle a ce delai (3 par defaut, fiche du directeur).
const String cleRemplacementAlerteDirection =
    'remplacement.alerte_direction_minutes';

/// A3-bis : une seance creee moins de ce delai avant son debut ne declenche ni
/// absence ni prise automatique (15 par defaut, reglage technique propose par
/// l'agent, non tranche par le directeur).
const String cleRemplacementSeanceTardive =
    'remplacement.seance_tardive_minutes';

/// Les deux reglages A3-bis, sans ordre impose entre eux.
const List<String> clesRemplacementA3bis = <String>[
  cleRemplacementAlerteDirection,
  cleRemplacementSeanceTardive,
];

/// SNT (03/11/2026) : a ce delai depuis le debut, si aucun enseignant n'a
/// rejoint la salle, la seance n'est pas tenue : elle est reportee et la
/// direction fixe la nouvelle date (30 par defaut, decision du directeur du
/// 03/11). Le serveur exige qu'il vienne apres [cleRemplacementObjectif].
const String cleRemplacementSeanceNonTenue =
    'remplacement.seance_non_tenue_minutes';

/// Les cles du domaine Configuration > Fonctionnalites.
const List<String> clesFonctionnalites = <String>[
  'allow_multi_participant_sessions',
  'max_participants_per_session',
];

/// Les defauts d'Academie de l'observation par les tuteurs.
///
/// **Aucun ecran de Configuration ne les edite aujourd'hui**, et cette liste ne
/// les y inscrit pas : elle sert a les LIRE, pour qu'un groupe personnalise
/// puisse afficher honnetement ce dont il herite. Le reglage par groupe, lui,
/// passe par `definir_politique_observation_groupe` depuis Operations >
/// Groupes -- deux natures differentes, jamais le meme reglage a deux endroits.
const List<String> clesObservation = <String>[
  'observation.policy_version',
  'observation.max_visits_per_session',
  'observation.max_total_seconds',
  'observation.max_seconds_per_visit',
];

/// Les cles du domaine Configuration > Conservation des donnees.
const List<String> clesConservationDonnees = <String>[
  'recording_retention_days',
  'kyc_retention_days',
  'compte.suppression_delai_jours',
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
      (Ref ref) =>
          ref.watch(serviceConfigurationProvider).lire(clesConservationDonnees),
    );
