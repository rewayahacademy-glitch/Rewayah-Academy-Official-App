import 'package:flutter/foundation.dart';

/// L'exigence KYC qui pese sur un compte (contrat du sprint, section 5).
///
/// **Distincte de l'etat** : une exigence dit ce qui est attendu, un etat dit
/// ou l'on en est. Le verrou unique historique les confondait.
enum ExigenceKyc {
  /// Le KYC est obligatoire avant tout acces operationnel. Defaut de tout
  /// nouvel enseignant.
  requise,

  /// Le KYC est propose, jamais bloquant. Defaut des eleves et des tuteurs.
  optionnelle,

  /// L'academie a dispense explicitement ce compte. Reversible, journalise.
  dispensee,
}

/// Ou en est le dossier KYC d'un compte.
enum EtatKyc {
  /// Rien n'a ete depose.
  nonCommence,

  /// Une piece est deposee, l'academie n'a pas tranche.
  soumis,

  /// La piece est verifiee.
  verifie,

  /// L'academie demande une correction.
  correctionDemandee,

  /// La piece est refusee.
  refuse,

  /// Le compte est dispense : l'etat n'a plus a evoluer.
  dispense,
}

/// Une dispense de KYC, telle que le journal la retient.
@immutable
class DispenseKyc {
  /// Cree une dispense.
  const DispenseKyc({required this.acteur, required this.date, this.motif});

  /// Qui a dispense : un nom d'affichage, jamais un identifiant.
  final String acteur;

  /// Quand.
  final DateTime date;

  /// Pourquoi, quand le journal le rend.
  final String? motif;
}

/// La conformite d'un compte, separee en ses composantes.
///
/// C'est la regle normative du sprint (section 5) : etat du compte,
/// exigence KYC, etat KYC, exigences avant la Salle et contrat enseignant ne
/// se representent **plus** par un seul verrou identique pour tous les roles.
@immutable
class ConformiteCompte {
  /// Cree une conformite.
  const ConformiteCompte({
    required this.exigence,
    required this.etat,
    required this.contratAccepte,
    this.dispense,
    this.photoIdentificationPresente,
  });

  /// L'exigence qui pese sur ce compte.
  final ExigenceKyc exigence;

  /// L'etat du dossier.
  final EtatKyc etat;

  /// Vrai quand le contrat propre au role est accepte.
  final bool contratAccepte;

  /// La dispense, quand il y en a une.
  final DispenseKyc? dispense;

  /// Vrai quand une photo d'identification est televersee. `null` quand le
  /// serveur ne le dit pas.
  final bool? photoIdentificationPresente;

  /// Vrai quand le KYC ne bloque plus rien : verifie ou dispense.
  bool get kycSatisfait =>
      exigence == ExigenceKyc.dispensee ||
      etat == EtatKyc.verifie ||
      etat == EtatKyc.dispense;

  /// L'acces operationnel d'un enseignant :
  /// `contrat accepte` ET (`KYC verifie` OU `KYC dispense par l'academie`).
  ///
  /// **Le client ne l'invente pas** : il projette ce que le serveur rend. La
  /// barriere reelle reste la RLS et l'emission du jeton.
  bool get clearanceOperationnelle => contratAccepte && kycSatisfait;

  /// Vrai quand ce compte est dispense.
  bool get estDispense =>
      exigence == ExigenceKyc.dispensee || etat == EtatKyc.dispense;
}

/// Ce qu'il faut avant d'entrer en Salle, pour une personne donnee.
///
/// **Le serveur decide, l'ecran explique avant le clic.** Un membre mineur
/// sans photo d'identification televersee ne recoit pas de jeton : cette
/// precondition sert a le dire calmement, avec l'action qui debloque, plutot
/// que de laisser le bouton echouer.
@immutable
class PreconditionSalle {
  /// Cree une precondition.
  const PreconditionSalle({
    required this.prenom,
    this.photoRequise,
    this.photoPresente,
  });

  /// Une precondition que personne n'a pu lire : le serveur decidera seul.
  const PreconditionSalle.inconnue({this.prenom = ''})
    : photoRequise = null,
      photoPresente = null;

  /// Le prenom de la personne concernee, pour la phrase.
  final String prenom;

  /// Vrai quand une photo est exigee. `null` quand le serveur ne le dit pas.
  final bool? photoRequise;

  /// Vrai quand une photo est televersee. `null` quand on ne sait pas.
  final bool? photoPresente;

  /// Vrai quand l'entree doit etre expliquee au lieu d'etre proposee.
  ///
  /// **Seule une exigence positive bloque** : une precondition inconnue laisse
  /// le bouton, et le serveur tranche. Bloquer sur un doute inventerait une
  /// regle pour un eleve adulte.
  bool get bloqueParPhoto => photoRequise == true && photoPresente != true;
}
