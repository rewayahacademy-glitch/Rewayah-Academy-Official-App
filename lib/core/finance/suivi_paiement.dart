// Le suivi d'une commande de recharge multi-profils (FI-1c, guide Finance V4
// §1.6, §5.4 ; FI-BR-06).
//
// Un paiement externe unique, une allocation nominative par profil. **Jamais
// « confirme » au retour d'un ecran externe** (FI9) : seul l'etat rendu par
// la source fait foi, et une meme confirmation recue deux fois ne credite
// qu'une fois (la source est idempotente, l'ecran ne credite rien).

import 'package:flutter/foundation.dart';

import 'montant.dart';
import 'politique_commerciale.dart';

/// Les huit etats d'un paiement (guide §1.6, FI9).
enum EtatPaiement {
  /// La commande se prepare (`preparing`).
  preparation,

  /// Le prestataire n'a pas encore confirme (`awaiting_confirmation`).
  attenteConfirmation,

  /// Le prestataire a confirme, l'allocation n'a pas commence (`confirmed`).
  confirme,

  /// Les soldes sont en cours de mise a jour (`allocation_in_progress`).
  allocationEnCours,

  /// Les soldes sont credites (`completed`) : le seul etat de reussite.
  termine,

  /// Le paiement a echoue (`failed`) : la selection est gardee.
  echec,

  /// Le paiement a ete annule (`cancelled`).
  annule,

  /// La commande est perimee (`stale`).
  perime,
}

/// La part d'un profil dans une commande.
@immutable
class AllocationProfil {
  /// Cree la part.
  const AllocationProfil({
    required this.profilId,
    required this.prenom,
    required this.montant,
    this.nouveauSolde,
  });

  /// Le profil credite.
  final String profilId;

  /// Son prenom.
  final String prenom;

  /// Le montant attribue a ce profil.
  final Montant montant;

  /// Son nouveau solde, rendu seulement quand l'etat est `termine`.
  final Montant? nouveauSolde;
}

/// L'etat d'une commande tel que la source le rend.
@immutable
class SuiviPaiement {
  /// Cree le suivi.
  const SuiviPaiement({
    required this.commandeId,
    required this.etat,
    required this.total,
    required this.allocations,
    this.reference,
    this.date,
    this.moyen,
    this.motif,
  });

  /// L'identifiant de la commande (cle d'idempotence cote source).
  final String commandeId;

  /// L'etat rendu.
  final EtatPaiement etat;

  /// Le total externe, arrete par la source avant le paiement.
  final Montant total;

  /// La repartition par profil, dans l'ordre rendu.
  final List<AllocationProfil> allocations;

  /// La reference du paiement, rendue quand elle existe.
  final String? reference;

  /// La date du paiement, rendue quand elle existe.
  final DateTime? date;

  /// Le moyen de paiement employe, rendu quand il existe (guide §5.4,
  /// FI-8) : l'ecran ne le deduit jamais du moyen choisi avant le paiement.
  final RailPaiement? moyen;

  /// Le motif d'un echec, deja redige pour l'utilisateur par la source, ou
  /// `null` (guide §5.4 : « motif utilisateur lorsque disponible »).
  final String? motif;
}
