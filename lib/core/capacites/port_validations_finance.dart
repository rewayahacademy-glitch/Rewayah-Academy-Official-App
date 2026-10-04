// Les validations des operations sensibles (spec §21.4, §9.5 ; CPT-BR-09).
// **Interface seulement**, posee par CPT-F ; **propriete de la voie CPT-DIR
// ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B). L'ecran Direction qui
// decide attend la reponse du directeur a CPT-Q1 ; cote Comptable, seul
// l'etat « Validation demandee » s'affiche.
//
// Une decision est prise par une **autre personne que le demandeur** : le
// serveur le garantit, l'ecran ne fait que rendre les demandes et la
// decision.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La nature d'une demande de validation.
enum NatureDemandeValidation {
  /// Un payout sensible (§21.4).
  payoutSensible,

  /// Un retrait de la Reserve strategique (§9.5).
  retraitReserve,

  /// Une obligation de contractuel a approuver (§22.3).
  obligationAApprouver,

  /// Le payout du Comptable lui-meme (§20).
  payoutDuComptable,

  /// Un mouvement sortant d'un coffre protege (§10.3).
  sortieCoffreProtege,
}

/// Une demande de validation.
@immutable
class DemandeValidation {
  /// Cree la demande.
  const DemandeValidation({
    required this.id,
    required this.nature,
    required this.date,
    required this.demandeur,
    required this.objet,
    required this.montant,
    required this.raison,
    required this.etat,
    this.objetId,
    this.decideur,
    this.motifDecision,
  });

  /// L'identifiant.
  final String id;

  /// La nature.
  final NatureDemandeValidation nature;

  /// La date de la demande.
  final DateTime date;

  /// Le demandeur, rendu.
  final String demandeur;

  /// L'objet, lisible.
  final String objet;

  /// Le montant **exact** (jamais masque dans la decision).
  final Montant montant;

  /// La raison de la sensibilite, rendue.
  final RaisonBlocage raison;

  /// L'etat.
  final EtatDemandeValidation etat;

  /// L'identifiant de l'objet (obligation, mouvement).
  final String? objetId;

  /// Qui a decide, rendu.
  final String? decideur;

  /// Le motif d'un refus.
  final String? motifDecision;
}

/// La decision.
enum DecisionValidation {
  /// Valider.
  valider,

  /// Refuser, avec motif.
  refuser,
}

/// Le filtre des demandes.
@immutable
class FiltreDemandesValidation {
  /// Cree le filtre.
  const FiltreDemandesValidation({this.etat, this.nature});

  /// Toutes.
  static const FiltreDemandesValidation tout = FiltreDemandesValidation();

  /// Un etat.
  final EtatDemandeValidation? etat;

  /// Une nature.
  final NatureDemandeValidation? nature;
}

/// Les validations (CPT-BR-09).
abstract interface class PortValidationsFinance {
  /// Les demandes, filtrees.
  Future<List<DemandeValidation>> demandes(FiltreDemandesValidation filtre);

  /// Decide, avec un motif obligatoire pour un refus.
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    String? motif,
  });

  /// Le journal d'une demande (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String demandeId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-09).
class ValidationsFinanceIndisponibles implements PortValidationsFinance {
  /// Cree l'implementation.
  const ValidationsFinanceIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-09');

  @override
  Future<List<DemandeValidation>> demandes(FiltreDemandesValidation filtre) =>
      Future<List<DemandeValidation>>.error(_manque);

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    String? motif,
  }) => Future<DemandeValidation>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String demandeId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`direction_demo.dart`).
final Provider<PortValidationsFinance> portValidationsFinanceProvider =
    Provider<PortValidationsFinance>(
      (Ref _) => const ValidationsFinanceIndisponibles(),
    );
