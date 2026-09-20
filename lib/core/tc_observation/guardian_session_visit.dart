import 'package:flutter/foundation.dart';

/// Qui observe, et a quel titre.
///
/// **Les valeurs SQL ne sont pas inventees ici** : `guardian_observer` et
/// `masked_controller` existent depuis la migration `0012` et sont deja portees
/// par l'enum `participant_role`. Les deux valeurs administratives, elles,
/// n'existent pas encore : elles font l'objet d'une demande SQL
/// (`TC_CONTRACT_REQUEST_G.md`, section DEMANDE SQL), avec le rappel que tout
/// nouveau role d'observation doit etre ajoute aux **deux** listes d'exemption
/// de `0012` (`guard_session_participant_cap` et `guard_session_overlap`),
/// faute de quoi l'administrateur sera refuse par un declencheur ecrit pour
/// tout autre chose.
enum RoleObservateur {
  /// Le tuteur qui regarde le cours de son enfant. Visible, muet, borne.
  tuteur('guardian_observer'),

  /// L'administration qui constate sans perturber. Invisible aux participants,
  /// **jamais invisible a l'audit**.
  adminIncognito('admin_masked'),

  /// L'administration qui intervient, sous un nom institutionnel clair.
  adminVisible('admin_visible'),

  /// Le controle qualite. Incognito, et seulement incognito.
  controleur('masked_controller');

  const RoleObservateur(this.valeurSql);

  /// La valeur telle que `participant_role` la nomme.
  final String valeurSql;

  /// Lit un role depuis sa valeur SQL. `null` sur une valeur inconnue.
  static RoleObservateur? depuisSql(String? valeur) {
    for (final RoleObservateur role in RoleObservateur.values) {
      if (role.valeurSql == valeur) {
        return role;
      }
    }
    return null;
  }

  /// Vrai quand ce role n'apparait dans la liste de personne.
  bool get incognito =>
      this == RoleObservateur.adminIncognito ||
      this == RoleObservateur.controleur;

  /// Vrai quand ce role consomme un budget d'observation borne par politique.
  ///
  /// Seul le tuteur en consomme un. L'administration et le controle qualite
  /// sont audites, pas rationnes : borner une visite de controle reviendrait a
  /// donner a l'observe le moyen d'epuiser le controleur.
  bool get soumisAuQuota => this == RoleObservateur.tuteur;
}

/// Pourquoi une visite s'est terminee.
enum FinDeVisite {
  /// L'observateur a quitte de lui-meme.
  sortieVolontaire('sortie_volontaire'),

  /// Le budget de la seance est epuise.
  quotaAtteint('quota_atteint'),

  /// La seance s'est terminee pendant la visite.
  seanceTerminee('seance_terminee'),

  /// Le serveur a revoque l'acces.
  revocationServeur('revocation_serveur'),

  /// Le lien a ete perdu sans sortie annoncee.
  deconnexion('deconnexion');

  const FinDeVisite(this.valeurSql);

  /// La valeur telle qu'elle est journalisee.
  final String valeurSql;

  /// Lit une fin depuis sa valeur SQL. `null` sur une valeur inconnue.
  static FinDeVisite? depuisSql(String? valeur) {
    for (final FinDeVisite fin in FinDeVisite.values) {
      if (fin.valeurSql == valeur) {
        return fin;
      }
    }
    return null;
  }
}

/// L'intervalle d'observation, tel qu'il doit pouvoir etre relu sans
/// reconstruction.
///
/// **Le besoin n'est pas celui du journal d'audit.** `audit_logs` existe, il
/// est chaine, il est lisible par `ADM-04`, et il repond a « qui, quand,
/// quelle identite ». Il ne repond pas a « combien de visites, combien de
/// secondes, sous quelle version de politique » : ces trois colonnes ne sont ni
/// requetables ni contraintes dans un `payload` jsonb. C'est pour cela que
/// cette table existe a cote du journal, et non a sa place (MAPPING section
/// 9.5 : « ne pas fabriquer un second journal chaine »).
@immutable
class GuardianSessionVisit {
  /// Cree une visite.
  const GuardianSessionVisit({
    required this.id,
    required this.sessionId,
    required this.groupeId,
    required this.observateurProfilId,
    required this.role,
    required this.enteredAtUtc,
    required this.visitNumber,
    required this.policyVersion,
    this.enfantConcerneId,
    this.leftAtUtc,
    this.durationSeconds,
    this.finDeVisite,
  });

  /// Lit une visite rendue par le serveur.
  factory GuardianSessionVisit.depuisJson(Map<String, dynamic> json) {
    final int? duree = (json['duration_seconds'] as num?)?.toInt();
    return GuardianSessionVisit(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      groupeId: json['groupe_id'] as String? ?? '',
      observateurProfilId: json['observateur_profile_id'] as String? ?? '',
      role:
          RoleObservateur.depuisSql(json['role'] as String?) ??
          RoleObservateur.tuteur,
      enfantConcerneId: json['enfant_profile_id'] as String?,
      enteredAtUtc:
          DateTime.tryParse(json['entered_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      leftAtUtc: DateTime.tryParse(json['left_at'] as String? ?? '')?.toUtc(),
      durationSeconds: duree == null ? null : Duration(seconds: duree),
      visitNumber: (json['visit_number'] as num?)?.toInt() ?? 0,
      policyVersion: json['policy_version'] as String? ?? '',
      finDeVisite: FinDeVisite.depuisSql(json['fin_de_visite'] as String?),
    );
  }

  /// Identifiant de l'intervalle.
  final String id;

  /// La seance observee.
  final String sessionId;

  /// Le groupe dont releve la seance.
  final String groupeId;

  /// Qui observe.
  final String observateurProfilId;

  /// A quel titre.
  final RoleObservateur role;

  /// L'enfant concerne. Renseigne pour le tuteur seulement.
  final String? enfantConcerneId;

  /// Quand la visite a commence, en UTC.
  final DateTime enteredAtUtc;

  /// Quand elle s'est terminee. `null` = visite en cours.
  final DateTime? leftAtUtc;

  /// Sa duree. `null` tant que l'intervalle est ouvert.
  ///
  /// **Ecrite par le serveur**, jamais deduite du client : deux horodatages
  /// recolles a l'ecran donneraient une duree que la machine de l'observateur
  /// aurait pu choisir.
  final Duration? durationSeconds;

  /// Le rang de la visite dans la seance, a partir de 1.
  final int visitNumber;

  /// La version de politique en vigueur au moment de la visite.
  final String policyVersion;

  /// Pourquoi elle s'est terminee. `null` tant qu'elle dure.
  final FinDeVisite? finDeVisite;

  /// Vrai tant que l'intervalle n'est pas ferme.
  bool get enCours => leftAtUtc == null;
}
