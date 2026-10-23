// Demandes de suppression de compte, cote direction (CPT-SUPPR-EXPORT,
// migration 20261018150000) : `demandes_suppression_lister` et
// `traiter_demande_suppression`.
//
// Le serveur decide de tout : si le delai de reflexion est ecoule, ce qui
// reste du (solde, seances a venir), qui peut traiter (direction en double
// verification). Flutter affiche et envoie ; il ne calcule ni delai ni droit.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Ou en est une demande.
enum StatutSuppression {
  /// La personne attend, ou la direction doit traiter.
  enAttente,

  /// La personne l'a annulee.
  annulee,

  /// Le compte est anonymise.
  traitee,
}

/// Ce qui reste du pour une demande en attente, tel que le serveur le lit.
@immutable
class SituationSuppressionAdmin {
  /// Cree la situation.
  const SituationSuppressionAdmin({
    required this.montantsDus,
    required this.seancesAVenir,
  });

  /// Les montants restant a regler, par devise (aucun : rien n'est du).
  final List<Montant> montantsDus;

  /// Le nombre de seances encore prevues pour la personne ou son foyer.
  final int seancesAVenir;

  /// Vrai quand un solde reste a regler.
  bool get soldeDu => montantsDus.isNotEmpty;
}

/// Une demande de suppression, vue de la direction.
@immutable
class DemandeSuppressionAdmin {
  /// Cree la demande.
  const DemandeSuppressionAdmin({
    required this.id,
    required this.statut,
    required this.matricule,
    required this.prenom,
    required this.nom,
    required this.delaiJours,
    required this.demandeeLe,
    required this.echeanceLe,
    required this.delaiEcoule,
    required this.elevesDuFoyer,
    this.role,
    this.motif,
    this.annuleeLe,
    this.traiteeLe,
    this.situation,
  });

  /// L'identifiant de la demande.
  final String id;

  /// Son statut.
  final StatutSuppression statut;

  /// Le matricule de la personne.
  final String matricule;

  /// Son prenom, tel que le compte le porte (anonymise une fois traitee).
  final String prenom;

  /// Son nom.
  final String nom;

  /// Son role au depot, ou `null` s'il est illisible.
  final AppRole? role;

  /// Le motif ecrit par la personne, efface une fois la demande traitee.
  final String? motif;

  /// Le delai de reflexion applique, en jours.
  final int delaiJours;

  /// Le moment de la demande.
  final DateTime demandeeLe;

  /// Le moment a partir duquel la direction peut traiter.
  final DateTime echeanceLe;

  /// Le moment de l'annulation, s'il y en a une.
  final DateTime? annuleeLe;

  /// Le moment du traitement, s'il a eu lieu.
  final DateTime? traiteeLe;

  /// Capacite rendue par le serveur : le delai est ecoule et la demande
  /// attend encore.
  final bool delaiEcoule;

  /// Le nombre d'eleves du foyer d'un tuteur (zero pour les autres).
  final int elevesDuFoyer;

  /// Ce qui reste du : seulement pour une demande en attente.
  final SituationSuppressionAdmin? situation;

  /// Vrai quand la demande attend encore une decision.
  bool get enAttente => statut == StatutSuppression.enAttente;

  /// Des seances a venir : le serveur refuse de traiter tant qu'il en reste.
  bool get seancesBloquantes => (situation?.seancesAVenir ?? 0) > 0;

  /// Vrai quand le geste « Traiter » est ouvert : en attente, delai ecoule,
  /// aucune seance a venir. Le serveur re-verifie tout.
  bool get traitable => enAttente && delaiEcoule && !seancesBloquantes;
}

/// La reponse du serveur au traitement d'une demande.
enum ResultatTraitementSuppression {
  /// Le compte est anonymise.
  traitee,

  /// La demande n'est plus en attente (annulee ou deja traitee).
  dejaTraitee,

  /// Le delai de reflexion court encore.
  delaiEnCours,

  /// Des seances a venir existent.
  seancesAVenir,

  /// La demande n'existe plus.
  introuvable,
}

/// Les demandes de suppression (contrat CPT-SUPPR-EXPORT).
abstract interface class PortSuppressionsAdmin {
  /// Les demandes, celles en attente d'abord. Lecture seule.
  Future<List<DemandeSuppressionAdmin>> lister();

  /// Anonymise le compte de la demande [id]. Irreversible.
  Future<ResultatTraitementSuppression> traiter(String id);
}

/// Tant qu'aucun adaptateur serveur n'est branche (demonstration, tests) :
/// l'ecran dit que la fonction est indisponible.
class SuppressionsAdminIndisponibles implements PortSuppressionsAdmin {
  /// Cree l'implementation.
  const SuppressionsAdminIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'CPT-SUPPR-EXPORT',
  );

  @override
  Future<List<DemandeSuppressionAdmin>> lister() =>
      Future<List<DemandeSuppressionAdmin>>.error(_absente);

  @override
  Future<ResultatTraitementSuppression> traiter(String id) =>
      Future<ResultatTraitementSuppression>.error(_absente);
}

/// Le port des demandes de suppression.
final Provider<PortSuppressionsAdmin> portSuppressionsAdminProvider =
    Provider<PortSuppressionsAdmin>(
      (Ref ref) => const SuppressionsAdminIndisponibles(),
    );
