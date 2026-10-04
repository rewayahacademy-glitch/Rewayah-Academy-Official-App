// Le payout (`PayoutPort`, spec §7.5, §20, §21, §40, §41, §43, §47 ;
// CPT-BR-02). Pose par CPT-F avec son interface complete ; **propriete de la
// voie CPT-PAY ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Preflight obligatoire d'une selection, soumission des seuls prets par
// (id, version) avec une cle d'idempotence generee par l'app, suivi par
// payout depuis le prestataire : **jamais « reussi » sur simple appui**
// (§5.3). Les plafonds cumules (par Comptable, par beneficiaire, par periode)
// sont verifies par le serveur : aucun contournement par fractionnement
// (§47).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Une obligation choisie, par identifiant **et** version.
@immutable
class ObligationChoisie {
  /// Cree le choix.
  const ObligationChoisie({required this.obligationId, required this.version});

  /// L'obligation.
  final String obligationId;

  /// La version vue par le Comptable au moment du choix.
  final String version;
}

/// Une obligation exclue du lot, avec sa raison rendue (§41).
@immutable
class ExclusionLot {
  /// Cree l'exclusion.
  const ExclusionLot({
    required this.obligationId,
    required this.beneficiaire,
    required this.raison,
  });

  /// L'obligation.
  final String obligationId;

  /// Le beneficiaire, pour la lire sans rouvrir la liste.
  final IdentiteBeneficiaire beneficiaire;

  /// La raison.
  final RaisonBlocage raison;
}

/// Les frais et le change connus pour un payout (§43), **seulement si le
/// prestataire les donne** ; aucune conversion fictive.
@immutable
class FraisEtChange {
  /// Cree le detail.
  const FraisEtChange({
    required this.deviseObligation,
    required this.devisePayout,
    this.tauxRendu,
    this.dateTaux,
    this.fraisPrestataire,
    this.coutChange,
    this.montantEnvoye,
    this.montantRecuAttendu,
  });

  /// La devise de l'obligation.
  final String deviseObligation;

  /// La devise du payout.
  final String devisePayout;

  /// Le taux utilise, tel que rendu (texte, jamais recalcule).
  final String? tauxRendu;

  /// La date et l'heure du taux.
  final DateTime? dateTaux;

  /// Les frais du prestataire.
  final Montant? fraisPrestataire;

  /// Le cout du change.
  final Montant? coutChange;

  /// Le montant envoye.
  final Montant? montantEnvoye;

  /// Le montant recu attendu.
  final Montant? montantRecuAttendu;
}

/// Le resultat du preflight d'une selection (§41) : « 18 prets / 3 exclus ».
@immutable
class PreflightLot {
  /// Cree le preflight.
  const PreflightLot({
    required this.id,
    required this.nombreBeneficiaires,
    required this.totauxParDevise,
    required this.prets,
    this.exclus = const <ExclusionLot>[],
    this.prestataires = const <PrestataireFinance>[],
    this.erreurs = const <String>[],
    this.plafondsRestants = const <Montant>[],
    this.fraisEtChange,
    this.sensible = false,
  });

  /// L'identifiant du preflight, a soumettre tel quel.
  final String id;

  /// Le nombre de beneficiaires prets.
  final int nombreBeneficiaires;

  /// Le total **rendu par la source**, par devise.
  final List<Montant> totauxParDevise;

  /// Les obligations pretes (id, version).
  final List<ObligationChoisie> prets;

  /// Les exclues, avec leur raison.
  final List<ExclusionLot> exclus;

  /// Les prestataires concernes.
  final List<PrestataireFinance> prestataires;

  /// Les erreurs rendues, lisibles.
  final List<String> erreurs;

  /// Les plafonds de delegation restants, par devise.
  final List<Montant> plafondsRestants;

  /// Frais et change, si connus.
  final FraisEtChange? fraisEtChange;

  /// Vrai quand le lot est sensible : « Demander validation » remplace
  /// « Confirmer le paiement » (§40).
  final bool sensible;
}

/// Le suivi d'un payout, tel que le prestataire le rend.
@immutable
class SuiviPayout {
  /// Cree le suivi.
  const SuiviPayout({
    required this.payoutId,
    required this.obligationId,
    required this.etat,
    required this.montant,
    this.reference,
    this.prestataire,
    this.miseAJour,
  });

  /// L'identifiant du payout.
  final String payoutId;

  /// L'obligation payee.
  final String obligationId;

  /// L'etat du moment (`soumis`, `enTransit`, `reussi`, `echoue`, `annule`,
  /// `retourne`).
  final EtatPaiementSortant etat;

  /// Le montant exact envoye.
  final Montant montant;

  /// La reference du prestataire.
  final String? reference;

  /// Le prestataire.
  final String? prestataire;

  /// La date de la derniere mise a jour.
  final DateTime? miseAJour;
}

/// Pourquoi la source refuse une soumission (§41, §47 ; DR-13). Un refus
/// n'envoie **rien** : aucun paiement du lot n'est parti.
enum MotifRefusPayout {
  /// Une obligation a ete recalculee depuis le preflight (R-FIN-18) : sa
  /// version a change, l'ancien montant ne part pas.
  versionChangee,

  /// La cle d'idempotence ou l'obligation a deja ete soumise : le suivi
  /// existant fait foi, rien n'est renvoye.
  dejaSoumis,

  /// Le cumul depasse la delegation (par Comptable, par beneficiaire, par
  /// periode : jamais par lot, donc aucun contournement par fractionnement).
  horsDelegation,

  /// Le preflight est perime ou inconnu : il faut le relancer.
  preflightPerime,

  /// Le prestataire est devenu indisponible pour ce corridor.
  fournisseurIndisponible,
}

/// Le refus d'une soumission par la source, avec les obligations en cause.
@immutable
class RefusPayout implements Exception {
  /// Cree le refus.
  const RefusPayout(this.motif, {this.obligationIds = const <String>[]});

  /// Le motif rendu.
  final MotifRefusPayout motif;

  /// Les obligations en cause (une version changee, un doublon).
  final List<String> obligationIds;

  @override
  String toString() => 'RefusPayout(${motif.name}, $obligationIds)';
}

/// Une demande de validation deposee (§21.4) : « Validation demandee ».
@immutable
class DemandeValidationDeposee {
  /// Cree la demande.
  const DemandeValidationDeposee({
    required this.demandeId,
    required this.obligationId,
    required this.etat,
  });

  /// L'identifiant de la demande.
  final String demandeId;

  /// L'obligation.
  final String obligationId;

  /// L'etat rendu.
  final EtatDemandeValidation etat;
}

/// Le payout (CPT-BR-02).
abstract interface class PortPayout {
  /// Le preflight d'une selection (§41).
  Future<PreflightLot> preflight(List<ObligationChoisie> selection);

  /// Soumet les seuls prets d'un preflight, une fois, avec la cle
  /// d'idempotence generee par l'app et rejouee telle quelle : la meme cle
  /// rend le meme suivi, sans second envoi. Jette [RefusPayout] quand la
  /// source refuse (rien n'est parti) ; toute autre erreur laisse l'issue
  /// inconnue (la reponse a pu se perdre apres l'envoi).
  Future<List<SuiviPayout>> soumettre({
    required String preflightId,
    required String cleIdempotence,
  });

  /// Le suivi d'un payout (depuis le webhook du prestataire).
  Future<SuiviPayout> suivre(String payoutId);

  /// Demande une validation pour un payout sensible (§21.4), une fois par
  /// [cleIdempotence].
  Future<DemandeValidationDeposee> demanderValidation({
    required String obligationId,
    required String motif,
    required String cleIdempotence,
  });
}

/// **Aucune source serveur a ce jour** (CPT-BR-02).
class PayoutIndisponible implements PortPayout {
  /// Cree l'implementation.
  const PayoutIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-02');

  @override
  Future<PreflightLot> preflight(List<ObligationChoisie> selection) =>
      Future<PreflightLot>.error(_manque);

  @override
  Future<List<SuiviPayout>> soumettre({
    required String preflightId,
    required String cleIdempotence,
  }) => Future<List<SuiviPayout>>.error(_manque);

  @override
  Future<SuiviPayout> suivre(String payoutId) =>
      Future<SuiviPayout>.error(_manque);

  @override
  Future<DemandeValidationDeposee> demanderValidation({
    required String obligationId,
    required String motif,
    required String cleIdempotence,
  }) => Future<DemandeValidationDeposee>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`paiements_demo.dart`).
final Provider<PortPayout> portPayoutProvider = Provider<PortPayout>(
  (Ref _) => const PayoutIndisponible(),
);
