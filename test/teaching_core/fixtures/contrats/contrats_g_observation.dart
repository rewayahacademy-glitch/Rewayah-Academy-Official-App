// TC-DOUBLE-CONTRAT: canoniques =
// lib/core/tc_observation/guardian_observation_policy.dart,
// lib/core/tc_observation/guardian_session_visit.dart,
// lib/core/tc_observation/port_politique_observation.dart,
// lib/core/tc_observation/port_visite_observation.dart,
// lib/core/tc_observation/port_annonce_observation.dart (Agent G).
// Signatures copiees depuis TEACHING_CORE_CONTRACTS.md sections 13 et 14.
//
// Agent Q n'ecrit aucune ligne de production : ce fichier est un DOUBLE de
// test. Agent Z le supprime a l'integration.

import 'package:flutter/foundation.dart';

/// D'ou vient la politique effective.
enum SourcePolitique { academie, groupe, desactivee }

/// Pourquoi une entree en observation est refusee.
enum MotifRefusObservation {
  policyDesactivee,
  quotaVisitesAtteint,
  tempsEpuise,
  lienTuteurAbsent,
  seanceNonActive,
  horsFenetre,
}

/// Qui observe.
///
/// **Le Controleur est incognito uniquement** (decision D-16) : il n'existe
/// volontairement aucune valeur `controleurVisible` dans ce chantier.
enum RoleObservateur { tuteur, adminIncognito, adminVisible, controleur }

/// Comment une visite s'est terminee.
enum FinDeVisite {
  sortieVolontaire,
  quotaAtteint,
  seanceTerminee,
  revocationServeur,
  deconnexion,
}

/// La politique d'observation tuteur (CONTRACTS section 13).
///
/// Defauts normatifs (spec 1.1 et 11.1) : observation activee, 1 visite,
/// 120 secondes totales par seance, micro interdit, camera interdite,
/// publication data interdite, admission enseignant aucune.
@immutable
class GuardianObservationPolicy {
  /// Cree une politique.
  const GuardianObservationPolicy({
    required this.policyVersion,
    required this.source,
    this.observationActivee = true,
    this.maxVisitsPerSession = 1,
    this.maxTotalObservationTime = const Duration(seconds: 120),
    this.maxParVisite,
    this.microAutorise = false,
    this.cameraAutorisee = false,
    this.publicationDataAutorisee = false,
    this.admissionEnseignantRequise = false,
  }) : assert(policyVersion != '', 'policyVersion est obligatoire');

  /// La version de politique, **obligatoire**, journalisee avec chaque visite.
  final String policyVersion;

  /// La source apres resolution academie -> groupe -> desactivation.
  final SourcePolitique source;

  /// L'observation est-elle activee.
  final bool observationActivee;

  /// Le nombre maximal de visites par seance.
  final int maxVisitsPerSession;

  /// Le temps total maximal par seance.
  final Duration maxTotalObservationTime;

  /// Un plafond par visite. **Ne contourne JAMAIS le plafond total.**
  final Duration? maxParVisite;

  /// Toujours faux.
  final bool microAutorise;

  /// Toujours faux.
  final bool cameraAutorisee;

  /// Toujours faux.
  final bool publicationDataAutorisee;

  /// Toujours faux : l'entree est automatique apres validation serveur.
  final bool admissionEnseignantRequise;
}

/// Le budget restant d'un tuteur pour une seance.
///
/// **Verite serveur.** Un compte a rebours Dart est un affichage, jamais
/// l'application de la limite (decision D-14).
@immutable
class BudgetObservation {
  /// Cree un budget.
  const BudgetObservation({
    required this.policyVersion,
    required this.visitesUtilisees,
    required this.visitesMax,
    required this.tempsConsomme,
    required this.tempsTotalMax,
    required this.restant,
    required this.peutEntrer,
    this.motifRefus,
  });

  /// La version de politique appliquee.
  final String policyVersion;

  /// Les visites deja faites.
  final int visitesUtilisees;

  /// Les visites autorisees.
  final int visitesMax;

  /// Le temps deja consomme.
  final Duration tempsConsomme;

  /// Le temps total autorise.
  final Duration tempsTotalMax;

  /// Le temps restant, tel que le serveur le calcule.
  final Duration restant;

  /// Le serveur autorise-t-il une entree maintenant.
  final bool peutEntrer;

  /// Le motif de refus, quand il y en a un.
  final MotifRefusObservation? motifRefus;
}

/// L'intervalle d'observation auditable (CONTRACTS section 14).
///
/// Les donnees doivent permettre, **sans reconstruction** : la date, le nombre
/// de visites, la duree exacte et la `policy_version`.
@immutable
class GuardianSessionVisit {
  /// Cree une visite.
  GuardianSessionVisit({
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
  }) : assert(enteredAtUtc.isUtc, 'tout DateTime de contrat est en UTC'),
       assert(
         leftAtUtc == null || leftAtUtc.isUtc,
         'tout DateTime de contrat est en UTC',
       ),
       assert(visitNumber >= 1, 'le numero de visite est 1-based');

  /// L'identifiant de la visite.
  final String id;

  /// La seance observee.
  final String sessionId;

  /// Le groupe.
  final String groupeId;

  /// L'observateur.
  final String observateurProfilId;

  /// Son role.
  final RoleObservateur role;

  /// L'enfant concerne, **uniquement pour le tuteur**.
  final String? enfantConcerneId;

  /// L'entree, en UTC.
  final DateTime enteredAtUtc;

  /// La sortie, en UTC. `null` = visite en cours.
  final DateTime? leftAtUtc;

  /// La duree exacte, **fermee cote serveur**.
  final Duration? durationSeconds;

  /// Le numero de visite, 1-based, par (seance, observateur).
  final int visitNumber;

  /// La version de politique appliquee.
  final String policyVersion;

  /// Comment la visite s'est terminee.
  final FinDeVisite? finDeVisite;
}

/// Le resultat d'une demande d'entree en observation.
@immutable
class ResultatEntreeObservation {
  /// Cree un resultat.
  const ResultatEntreeObservation({
    required this.autorise,
    this.motifRefus,
    this.visite,
    this.budget,
  });

  /// L'entree est-elle autorisee.
  final bool autorise;

  /// Le motif de refus.
  final MotifRefusObservation? motifRefus;

  /// La visite ouverte, quand l'entree est accordee.
  final GuardianSessionVisit? visite;

  /// Le budget apres la decision.
  final BudgetObservation? budget;
}

/// L'annonce affichee a l'enseignant.
///
/// « Tuteur d'Amina observe » + temps restant. **Pas de notification de sortie.**
@immutable
class AnnonceObservation {
  /// Cree une annonce.
  const AnnonceObservation({
    required this.libelle,
    this.tempsRestant,
    this.enfantConcerneId,
  });

  /// Le libelle affiche.
  final String libelle;

  /// Le temps restant, quand il est connu.
  final Duration? tempsRestant;

  /// L'enfant concerne, pour l'indicateur discret de son cote.
  final String? enfantConcerneId;
}
