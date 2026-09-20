// TC-STUB-PORT: canonique = lib/core/tc_horloge/session_clock_vm.dart (Agent A)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 3.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// Seule la surface CANONIQUE est copiee : les champs, le constructeur et les
// trois types de valeur. La fabrique `SessionClockVM.depuisFenetre` et le type
// `FenetreSeance` qu'Agent A a ajoutes dans son namespace ne sont PAS repris --
// ils ne figurent pas au contrat, et un stub qui les copierait ferait entrer
// chez Agent E une derivation de phase qui ne lui appartient pas.
//
// Agent E n'en LIT que `phase`, `restant`, `horlogeUtilisateur` et
// `horlogeContrepartie` : le header de la Classe Live affiche le temps restant,
// il ne le calcule pas.

import 'package:flutter/foundation.dart';

/// Le moment de la seance.
enum PhaseSeance {
  /// Avant l'ouverture de la fenetre : « Rejoindre » absent ou desactive.
  avantFenetre,

  /// De l'ouverture a l'heure de debut.
  salleOuverte,

  /// Connecte avant le debut : **aucun temps academique consomme**.
  attenteAvantT0,

  /// Le cours se tient.
  enCours,

  /// Apres la fin prevue, seance encore ouverte. **Aucun compte a rebours.**
  prolongee,

  /// Terminee : « Rejoindre » ferme.
  terminee,
}

/// A quelle distance se trouve une transition d'heure ete/hiver.
enum EcheanceDst {
  /// Trente jours.
  j30,

  /// Sept jours.
  j7,

  /// La veille.
  j1,
}

/// Une heure prete a lire, dans un fuseau donne.
///
/// **Tout est deja rendu.** Un widget ne calcule jamais une regle de fuseau :
/// il n'y a ni `timezone`, ni `tz`, ni `intl` au `pubspec.yaml`, et celui-ci
/// est gele (decision D-11).
@immutable
class HorlogeAffichee {
  /// Cree une heure affichable.
  const HorlogeAffichee({
    required this.fuseauIana,
    required this.libelleVille,
    required this.heureLocaleRendue,
    required this.dateLocaleRendue,
  });

  /// L'identifiant IANA, par exemple `Asia/Riyadh`.
  final String fuseauIana;

  /// Le nom lisible de la ville, par exemple `Riyad`. **Jamais « UTC+3 ».**
  final String libelleVille;

  /// L'heure, deja convertie et formatee, par exemple `18:00`.
  final String heureLocaleRendue;

  /// La date, deja convertie et formatee, par exemple `Lundi 21 septembre`.
  final String dateLocaleRendue;
}

/// L'avertissement de changement d'heure.
@immutable
class NoticeDst {
  /// Cree une notice.
  const NoticeDst({
    required this.transitionUtc,
    required this.fuseauConcerne,
    required this.heureAvantRendue,
    required this.heureApresRendue,
    required this.echeance,
  });

  /// L'instant UTC de la transition.
  final DateTime transitionUtc;

  /// Le fuseau IANA concerne.
  final String fuseauConcerne;

  /// L'heure du cours avant la transition, deja rendue.
  final String heureAvantRendue;

  /// L'heure du cours apres la transition, deja rendue.
  final String heureApresRendue;

  /// A quelle distance on se trouve de la transition.
  final EcheanceDst echeance;
}

/// Le temps d'une seance, tel que l'interface le lit.
@immutable
class SessionClockVM {
  /// Cree une horloge de seance.
  const SessionClockVM({
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
  }) : assert(
         phase != PhaseSeance.prolongee || restant == null,
         'une prolongation n affiche jamais un compte a rebours',
       ),
       assert(
         phase != PhaseSeance.terminee || restant == null,
         'une seance terminee n a plus de temps restant',
       ),
       assert(
         restant == null || restant >= Duration.zero,
         'un temps restant negatif est un defaut, pas un affichage',
       );

  /// Identifiant de la seance, `null` si l'occurrence n'est pas materialisee.
  final String? sessionId;

  /// Debut prevu, en UTC.
  final DateTime debutUtc;

  /// Fin prevue, en UTC.
  final DateTime finPrevueUtc;

  /// Ouverture de la salle, soit `debutUtc - fenetreAcces`.
  final DateTime joinOpensAtUtc;

  /// La fenetre d'acces. **Jamais ecrite en dur cote client.**
  final Duration fenetreAcces;

  /// De combien la seance reste joignable apres sa fin prevue.
  final Duration graceApresFin;

  /// L'heure de la personne qui regarde.
  final HorlogeAffichee horlogeUtilisateur;

  /// L'heure de la contrepartie. `null` quand les deux fuseaux coincident.
  final HorlogeAffichee? horlogeContrepartie;

  /// Le moment de la seance.
  final PhaseSeance phase;

  /// Le temps restant. `null` des la prolongation.
  final Duration? restant;

  /// Vrai quand il faut proposer « Rejoindre ».
  final bool rejoindreOuvert;

  /// L'avertissement de changement d'heure, quand il y en a un.
  final NoticeDst? noticeDst;

  /// L'instant serveur de reference. **Jamais `DateTime.now()` seul.**
  final DateTime calculeeAUtc;

  /// Vrai quand le cours se tient, prolongation comprise.
  bool get enDirect =>
      phase == PhaseSeance.enCours || phase == PhaseSeance.prolongee;
}
