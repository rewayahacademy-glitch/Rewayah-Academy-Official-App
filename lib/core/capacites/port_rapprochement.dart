// Le rapprochement (`ReconciliationWorkspace`, spec §25, §48 ; CPT-BR-14).
// Pose par CPT-F avec son interface complete ; **propriete de la voie
// CPT-ENC ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Relier paiement attendu, transaction prestataire, mensualite, frais,
// remboursement, payout, preuve ; `rapprocher` et `marquerDoublon` sont
// journalises par la source. Un doublon n'est jamais silencieux (§47).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La nature d'un element a relier (§25).
enum NatureElementRapprochement {
  /// Un paiement attendu.
  paiementAttendu,

  /// Une transaction du prestataire.
  transactionPrestataire,

  /// Un solde ou une mensualite.
  mensualite,

  /// Des frais.
  frais,

  /// Un remboursement.
  remboursement,

  /// Un payout.
  payout,

  /// Une preuve.
  preuve,
}

/// Un element du rapprochement.
@immutable
class ElementRapprochement {
  /// Cree l'element.
  const ElementRapprochement({
    required this.id,
    required this.nature,
    required this.date,
    required this.libelle,
    required this.montant,
    required this.etat,
    this.reference,
    this.prestataire,
    this.cibleId,
    this.cibleLibelle,
    this.permissions = PermissionsFinance.lectureSeule,
  });

  /// L'identifiant.
  final String id;

  /// La nature.
  final NatureElementRapprochement nature;

  /// La date.
  final DateTime date;

  /// Le libelle rendu.
  final String libelle;

  /// Le montant.
  final Montant montant;

  /// L'etat (§25).
  final EtatRapprochement etat;

  /// La reference.
  final String? reference;

  /// Le prestataire, nom neutre.
  final String? prestataire;

  /// L'element deja relie, s'il y en a un.
  final String? cibleId;

  /// Le libelle rendu de l'element relie (« Mensualite d'octobre ·
  /// Youssef ») : l'ecran ne montre jamais un identifiant (CPT-ENC-2).
  final String? cibleLibelle;

  /// Ce que la source permet (`rapprocher`).
  final PermissionsFinance permissions;
}

/// Une proposition de la source pour une transaction.
@immutable
class PropositionRapprochement {
  /// Cree la proposition.
  const PropositionRapprochement({
    required this.transactionId,
    required this.candidats,
    this.doublonPotentiel = false,
  });

  /// La transaction.
  final String transactionId;

  /// Les candidats, du plus probable au moins probable.
  final List<ElementRapprochement> candidats;

  /// Vrai quand la source voit un doublon potentiel.
  final bool doublonPotentiel;
}

/// Le filtre de l'espace de rapprochement.
@immutable
class FiltreRapprochement {
  /// Cree le filtre.
  const FiltreRapprochement({this.etat, this.nature});

  /// Tout.
  static const FiltreRapprochement tout = FiltreRapprochement();

  /// Un etat.
  final EtatRapprochement? etat;

  /// Une nature.
  final NatureElementRapprochement? nature;
}

/// Le rapprochement (CPT-BR-14).
abstract interface class PortRapprochement {
  /// Les elements a rapprocher, filtres.
  Future<List<ElementRapprochement>> aRapprocher(FiltreRapprochement filtre);

  /// Les candidats d'une transaction.
  Future<PropositionRapprochement> proposer(String transactionId);

  /// Relie une transaction a sa cible, une fois.
  Future<ElementRapprochement> rapprocher({
    required String transactionId,
    required String cibleId,
    required String cleIdempotence,
  });

  /// Marque un doublon potentiel, une fois.
  Future<ElementRapprochement> marquerDoublon({
    required String transactionId,
    required String cleIdempotence,
  });

  /// Le journal d'un element (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String elementId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-14).
class RapprochementIndisponible implements PortRapprochement {
  /// Cree l'implementation.
  const RapprochementIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-14');

  @override
  Future<List<ElementRapprochement>> aRapprocher(FiltreRapprochement filtre) =>
      Future<List<ElementRapprochement>>.error(_manque);

  @override
  Future<PropositionRapprochement> proposer(String transactionId) =>
      Future<PropositionRapprochement>.error(_manque);

  @override
  Future<ElementRapprochement> rapprocher({
    required String transactionId,
    required String cibleId,
    required String cleIdempotence,
  }) => Future<ElementRapprochement>.error(_manque);

  @override
  Future<ElementRapprochement> marquerDoublon({
    required String transactionId,
    required String cleIdempotence,
  }) => Future<ElementRapprochement>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String elementId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`encaissements_demo.dart`).
final Provider<PortRapprochement> portRapprochementProvider =
    Provider<PortRapprochement>((Ref _) => const RapprochementIndisponible());
