// Les mouvements d'un profil eleve et le recu d'un paiement, tels qu'une
// source les rend (FI-6b, guide Finance V4 §4, §5.2, §5.4 ; FI-BR-05).
//
// **Historique en ajout seul** (guide §5.7 « invariants ») : un mouvement ne
// se modifie ni ne se supprime ; une correction est un nouveau mouvement.
// Aucun calcul dans Flutter (FI6) : chaque montant arrive deja signe et
// arrete. Rendu au titulaire et a l'eleve adulte pour son seul profil, jamais
// a l'enfant ni au second adulte (lecon 15).

import 'package:flutter/foundation.dart';

import 'montant.dart';
import 'politique_commerciale.dart';
import 'suivi_paiement.dart';

/// La nature d'un mouvement, qui choisit son libelle.
enum NatureMouvement {
  /// Une recharge du solde du profil (credit).
  recharge,

  /// Le debit de la periode financee (mois civil, FI3).
  debitPeriode,

  /// Un avoir (credit).
  avoir,

  /// Une remise (rang familial, reduction calendrier) : credit.
  remise,

  /// La taxe applicable a la periode (guide §5.2) : debit, distinct de la
  /// mensualite.
  taxe,
}

/// L'etat d'un mouvement. Un etat se dit par un texte, jamais par la couleur
/// seule (FI17).
enum StatutMouvement {
  /// Le mouvement est enregistre.
  enregistre,

  /// Le paiement attend la confirmation du prestataire (FI9) : rien n'est
  /// encore credite.
  enConfirmation,
}

/// Le recu d'un paiement (guide §5.4 « Succes ») : rien d'autre que ce que
/// la source rend.
@immutable
class RecuPaiement {
  /// Cree le recu.
  const RecuPaiement({
    required this.reference,
    required this.date,
    required this.rail,
    required this.total,
    this.allocations = const <AllocationProfil>[],
  });

  /// La reference du paiement.
  final String reference;

  /// La date du paiement.
  final DateTime date;

  /// Le moyen de paiement (seul le paiement web au lancement, FI10).
  final RailPaiement rail;

  /// Le total paye, arrete par la source.
  final Montant total;

  /// La repartition par profil, dans l'ordre rendu ; vide quand la source ne
  /// la rend pas.
  final List<AllocationProfil> allocations;
}

/// Un mouvement du solde d'un profil.
@immutable
class MouvementProfil {
  /// Cree le mouvement.
  const MouvementProfil({
    required this.id,
    required this.date,
    required this.nature,
    required this.montant,
    this.statut = StatutMouvement.enregistre,
    this.periode,
    this.recu,
  });

  /// L'identifiant.
  final String id;

  /// La date du mouvement.
  final DateTime date;

  /// Ce que represente le mouvement.
  final NatureMouvement nature;

  /// Le montant, **signe** : positif pour un credit, negatif pour un debit.
  final Montant montant;

  /// L'etat rendu.
  final StatutMouvement statut;

  /// Le premier jour du mois debite, pour un debit de periode.
  final DateTime? periode;

  /// Le recu du paiement, quand il en existe un (une recharge). Un
  /// mouvement en confirmation ne le montre pas : il n'est pas encore
  /// credite.
  final RecuPaiement? recu;
}

/// Un mouvement du foyer : le mouvement d'un profil, avec le profil qu'il
/// concerne (FI-5b, « Dernieres transactions » du Foyer sur ordinateur).
/// Rien n'est agrege ni trie dans Flutter : la source rend la liste deja
/// arretee, le plus recent d'abord.
@immutable
class MouvementFoyer {
  /// Cree le mouvement.
  const MouvementFoyer({
    required this.profilId,
    required this.prenom,
    required this.mouvement,
  });

  /// Le profil concerne.
  final String profilId;

  /// Son prenom.
  final String prenom;

  /// Le mouvement, tel que la source le rend.
  final MouvementProfil mouvement;
}
