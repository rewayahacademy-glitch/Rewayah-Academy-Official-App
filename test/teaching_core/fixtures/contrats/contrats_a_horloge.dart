// TC-DOUBLE-CONTRAT: canonique = lib/core/tc_horloge/session_clock_vm.dart
// (Agent A). Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 3.
//
// Agent Q n'ecrit aucune ligne de production : ce fichier est un DOUBLE de
// test. Agent Z le supprime a l'integration.

import 'package:flutter/foundation.dart';

/// La phase d'une seance, du point de vue de l'usager.
enum PhaseSeance {
  /// Avant l'ouverture de la fenetre : « Rejoindre » absent ou desactive.
  avantFenetre,

  /// T-fenetre .. T0 : « Salle ouverte - cours dans 18 min ».
  salleOuverte,

  /// Connecte avant T0 : **AUCUN temps academique consomme**.
  attenteAvantT0,

  /// T0 .. fin prevue.
  enCours,

  /// Apres la fin prevue, seance encore ouverte : « Cours toujours en cours ».
  prolongee,

  /// Terminee : retour a la prochaine seance, « Rejoindre » ferme.
  terminee,
}

/// L'echeance d'une alerte de changement d'heure.
enum EcheanceDst { j30, j7, j1 }

/// Une horloge deja rendue, cote serveur.
///
/// **Le widget ne recalcule rien.** [heureLocaleRendue] est une chaine deja
/// convertie : aucun offset numerique ne traverse jamais ce contrat
/// (CONTRACTS section 3, invariant 1).
@immutable
class HorlogeAffichee {
  /// Cree une horloge affichee.
  const HorlogeAffichee({
    required this.fuseauIana,
    required this.libelleVille,
    required this.heureLocaleRendue,
    required this.dateLocaleRendue,
  });

  /// Le fuseau, au format IANA : `Asia/Riyadh`.
  final String fuseauIana;

  /// Le nom de ville lisible : `Riyad`. **Jamais `UTC+3`.**
  final String libelleVille;

  /// L'heure locale deja rendue : `18:00`.
  final String heureLocaleRendue;

  /// La date locale deja rendue : `Lundi 21 septembre`.
  final String dateLocaleRendue;
}

/// L'alerte de changement d'heure a venir.
@immutable
class NoticeDst {
  /// Cree une alerte.
  NoticeDst({
    required this.transitionUtc,
    required this.fuseauConcerne,
    required this.heureAvantRendue,
    required this.heureApresRendue,
    required this.echeance,
  }) : assert(transitionUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// L'instant de la transition, en UTC.
  final DateTime transitionUtc;

  /// Le fuseau concerne, au format IANA.
  final String fuseauConcerne;

  /// L'heure de seance avant la transition, deja rendue.
  final String heureAvantRendue;

  /// L'heure de seance apres la transition, deja rendue.
  final String heureApresRendue;

  /// A quelle distance l'alerte est posee.
  final EcheanceDst echeance;
}

/// Le temps d'une seance (CONTRACTS section 3).
///
/// **`SessionClockVM` UNIFIE les deux countdowns existants du depot ; il ne
/// devient pas le troisieme.**
@immutable
class SessionClockVM {
  /// Cree une horloge de seance.
  SessionClockVM({
    required this.debutUtc,
    required this.finPrevueUtc,
    required this.joinOpensAtUtc,
    required this.fenetreAcces,
    required this.graceApresFin,
    required this.horlogeUtilisateur,
    required this.phase,
    required this.rejoindreOuvert,
    required this.calculeeAUtc,
    this.sessionId,
    this.horlogeContrepartie,
    this.restant,
    this.noticeDst,
  }) : assert(debutUtc.isUtc, 'tout DateTime de contrat est en UTC'),
       assert(finPrevueUtc.isUtc, 'tout DateTime de contrat est en UTC'),
       assert(joinOpensAtUtc.isUtc, 'tout DateTime de contrat est en UTC'),
       assert(calculeeAUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// L'identifiant de seance. `null` si l'occurrence n'est pas materialisee.
  final String? sessionId;

  /// Le debut prevu, en UTC.
  final DateTime debutUtc;

  /// La fin prevue, en UTC.
  final DateTime finPrevueUtc;

  /// L'instant d'ouverture de « Rejoindre » : `debutUtc - fenetreAcces`.
  final DateTime joinOpensAtUtc;

  /// La fenetre d'acces. Defaut 20 min, **CONFIGURABLE**, jamais une
  /// constante cliente (decision D-13).
  final Duration fenetreAcces;

  /// La tolerance apres la fin prevue.
  final Duration graceApresFin;

  /// L'horloge de l'usager.
  final HorlogeAffichee horlogeUtilisateur;

  /// L'horloge d'en face. `null` quand les deux fuseaux coincident : on
  /// n'affiche pas deux fois la meme heure.
  final HorlogeAffichee? horlogeContrepartie;

  /// La phase courante.
  final PhaseSeance phase;

  /// Le temps restant avant le debut, ou avant la fin si le cours est en
  /// cours. `null` quand la seance est terminee.
  final Duration? restant;

  /// Vrai quand le bouton « Rejoindre » est ouvert.
  final bool rejoindreOuvert;

  /// L'alerte de changement d'heure, s'il y en a une.
  final NoticeDst? noticeDst;

  /// L'instant serveur de reference. **Jamais `DateTime.now()` seul.**
  final DateTime calculeeAUtc;
}
