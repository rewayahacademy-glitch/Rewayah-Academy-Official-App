// Les validations des operations sensibles (spec §21.4, §9.5 ; CPT-BR-09).
// Interface posee par CPT-F, completee par CPT-VAL-1 (05/10) apres la
// decision Q-8 = (a) du directeur : un onglet « A valider » dans la Finance
// de la direction recoit les demandes du Comptable (paiement sensible,
// retrait de la Reserve strategique, obligation ponctuelle, sa propre paie),
// avec Valider et Refuser (motif obligatoire). Cote Comptable, la demande
// passe « Validation demandee » puis « Validee » ou « Refusee (motif) ».
//
// Une decision est prise par une **autre personne que le demandeur** : le
// serveur le garantit et le rend en capacite sur chaque demande
// ([DemandeValidation.permissions] : `approuver` permise, ou bloquee avec
// `autoPaiement` quand la personne connectee est le demandeur). L'ecran ne
// lit jamais un role et ne compare jamais deux noms : il rend la capacite.
// Aucune decision n'est annoncee avant la reponse de la source.
//
// RPC attendues au branchement (BR-1, `docs/current/CPT-VAL-1.md` ; rien
// n'est branche, aucun fichier `supabase/` touche) :
// - `finance_validations_lister(etat?, nature?, objet_id?)` : les demandes
//   visibles par l'appelant (la direction : toutes ; le Comptable : les
//   siennes), chacune avec `actions_permises` / `raison_blocage` calcules
//   pour l'appelant ;
// - `finance_validation_decider(demande_id, decision, motif?, cle)` :
//   `security definer`, refuse `demandeur_ne_peut_pas_valider` si
//   `auth.uid()` est le demandeur, `motif_obligatoire` pour un refus sans
//   motif, `deja_decidee` si la demande n'est plus en attente ; idempotent
//   par cle ; ecrit le journal ;
// - `finance_validation_journal(demande_id)` (CPT-BR-17).

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
    this.dateDecision,
    this.precision,
    this.permissions = PermissionsFinance.lectureSeule,
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

  /// La date de la decision, une fois decidee.
  final DateTime? dateDecision;

  /// La precision de la raison, rendue par la source (« Coordonnees
  /// modifiees le 2 octobre 2026 »), ou `null`.
  final String? precision;

  /// Ce que la personne connectee peut faire de cette demande, calcule par
  /// la source : `approuver` (valider ou refuser) permise, ou bloquee avec
  /// la raison rendue (`autoPaiement` : c'est sa propre demande).
  final PermissionsFinance permissions;
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
  const FiltreDemandesValidation({this.etat, this.nature, this.objetId});

  /// Toutes.
  static const FiltreDemandesValidation tout = FiltreDemandesValidation();

  /// Un etat.
  final EtatDemandeValidation? etat;

  /// Une nature.
  final NatureDemandeValidation? nature;

  /// Les demandes d'un seul objet (obligation, mouvement), pour le suivi
  /// cote Comptable.
  final String? objetId;

  @override
  bool operator ==(Object other) =>
      other is FiltreDemandesValidation &&
      other.etat == etat &&
      other.nature == nature &&
      other.objetId == objetId;

  @override
  int get hashCode => Object.hash(etat, nature, objetId);
}

/// Pourquoi la source refuse une decision. Rien n'a change.
enum MotifRefusDecision {
  /// La personne connectee est le demandeur : elle ne decide jamais.
  demandeurNePeutPasValider,

  /// Un refus sans motif.
  motifObligatoire,

  /// La demande n'est plus en attente (decidee entre-temps).
  dejaDecidee,
}

/// Le refus explicite d'une decision par la source : rien n'a change. Toute
/// autre erreur laisse l'issue inconnue (la reponse a pu se perdre).
class RefusDecision implements Exception {
  /// Cree le refus.
  const RefusDecision(this.motif);

  /// Le motif.
  final MotifRefusDecision motif;

  @override
  String toString() => 'RefusDecision(${motif.name})';
}

/// Les validations (CPT-BR-09).
abstract interface class PortValidationsFinance {
  /// Les demandes, filtrees.
  Future<List<DemandeValidation>> demandes(FiltreDemandesValidation filtre);

  /// Decide, avec un motif obligatoire pour un refus, sous la cle
  /// d'idempotence tiree par l'ecran et rejouee telle quelle. Rend la
  /// demande telle que la source l'a enregistree ; jette [RefusDecision]
  /// quand la source refuse (rien n'a change).
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
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
    required String cleIdempotence,
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
