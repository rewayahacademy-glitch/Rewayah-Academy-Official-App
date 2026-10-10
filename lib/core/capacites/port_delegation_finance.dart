// `FinanceDelegationPolicy` (spec §21 ; CPT-BR-13). Pose par CPT-F avec son
// interface complete ; **propriete de la voie CPT-DIR ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Toutes les voies la lisent
// indirectement : chaque objet arrive avec ses `actionsPermises`, le serveur
// ayant deja applique cette politique ; l'ecran n'est qu'un reflet.
//
// Ecriture reservee a la Direction, auditee. Aucun plafond commercial code.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La politique de delegation financiere (§21.2).
@immutable
class PolitiqueDelegationFinance {
  /// Cree la politique.
  const PolitiqueDelegationFinance({
    required this.version,
    required this.paiementsStandardsAutorises,
    required this.remboursementStandardAutorise,
    required this.alimentationReserveAutorisee,
    required this.retraitReserveInterdit,
    required this.premierPaiementSecondeValidation,
    required this.coordonneesRecentesSecondeValidation,
    required this.autoPayoutInterdit,
    required this.montantManuelInterdit,
    required this.politiqueTarifaireInterdite,
    this.plafondParTransaction,
    this.plafondParLot,
    this.plafondParPeriode,
    this.joursCoordonneesRecentes,
    this.dateEffet,
    this.auteur,
  });

  /// La version.
  final String version;

  /// Paiements standards autorises sans validation quotidienne (§21.3).
  final bool paiementsStandardsAutorises;

  /// Plafond par transaction, par devise ; nul = aucun plafond rendu.
  final Montant? plafondParTransaction;

  /// Plafond par lot.
  final Montant? plafondParLot;

  /// Plafond cumule par periode (anti-fractionnement, §47).
  final Montant? plafondParPeriode;

  /// Remboursement standard autorise.
  final bool remboursementStandardAutorise;

  /// Mouvement vers la Reserve strategique autorise (§10.2).
  final bool alimentationReserveAutorisee;

  /// Retrait de la Reserve strategique interdit sans workflow (§10.4).
  final bool retraitReserveInterdit;

  /// Premier paiement d'un beneficiaire : seconde validation.
  final bool premierPaiementSecondeValidation;

  /// Coordonnees recemment modifiees : seconde validation.
  final bool coordonneesRecentesSecondeValidation;

  /// Le nombre de jours pendant lesquels une modification est « recente ».
  final int? joursCoordonneesRecentes;

  /// Auto-payout personnel interdit (§20). Toujours vrai chez la source.
  final bool autoPayoutInterdit;

  /// Montant manuel interdit au payout (§13.2). Toujours vrai.
  final bool montantManuelInterdit;

  /// Politique tarifaire interdite au Comptable. Toujours vrai.
  final bool politiqueTarifaireInterdite;

  /// La date d'effet.
  final DateTime? dateEffet;

  /// Qui l'a enregistree (« la direction »).
  final String? auteur;
}

/// Un brouillon de politique de delegation (Direction).
@immutable
class BrouillonDelegationFinance {
  /// Cree le brouillon.
  const BrouillonDelegationFinance({
    required this.paiementsStandardsAutorises,
    required this.remboursementStandardAutorise,
    required this.alimentationReserveAutorisee,
    required this.retraitReserveInterdit,
    required this.premierPaiementSecondeValidation,
    required this.coordonneesRecentesSecondeValidation,
    this.plafondParTransaction,
    this.plafondParLot,
    this.plafondParPeriode,
    this.joursCoordonneesRecentes,
  });

  /// Le brouillon qui reprend [p] telle quelle.
  BrouillonDelegationFinance.depuis(PolitiqueDelegationFinance p)
    : this(
        paiementsStandardsAutorises: p.paiementsStandardsAutorises,
        remboursementStandardAutorise: p.remboursementStandardAutorise,
        alimentationReserveAutorisee: p.alimentationReserveAutorisee,
        retraitReserveInterdit: p.retraitReserveInterdit,
        premierPaiementSecondeValidation: p.premierPaiementSecondeValidation,
        coordonneesRecentesSecondeValidation:
            p.coordonneesRecentesSecondeValidation,
        plafondParTransaction: p.plafondParTransaction,
        plafondParLot: p.plafondParLot,
        plafondParPeriode: p.plafondParPeriode,
        joursCoordonneesRecentes: p.joursCoordonneesRecentes,
      );

  /// Voir [PolitiqueDelegationFinance.paiementsStandardsAutorises].
  final bool paiementsStandardsAutorises;

  /// Voir [PolitiqueDelegationFinance.plafondParTransaction].
  final Montant? plafondParTransaction;

  /// Voir [PolitiqueDelegationFinance.plafondParLot].
  final Montant? plafondParLot;

  /// Voir [PolitiqueDelegationFinance.plafondParPeriode].
  final Montant? plafondParPeriode;

  /// Voir [PolitiqueDelegationFinance.remboursementStandardAutorise].
  final bool remboursementStandardAutorise;

  /// Voir [PolitiqueDelegationFinance.alimentationReserveAutorisee].
  final bool alimentationReserveAutorisee;

  /// Voir [PolitiqueDelegationFinance.retraitReserveInterdit].
  final bool retraitReserveInterdit;

  /// Voir [PolitiqueDelegationFinance.premierPaiementSecondeValidation].
  final bool premierPaiementSecondeValidation;

  /// Voir [PolitiqueDelegationFinance.coordonneesRecentesSecondeValidation].
  final bool coordonneesRecentesSecondeValidation;

  /// Voir [PolitiqueDelegationFinance.joursCoordonneesRecentes].
  final int? joursCoordonneesRecentes;
}

/// La delegation financiere (CPT-BR-13).
abstract interface class PortDelegationFinance {
  /// La politique en vigueur.
  Future<PolitiqueDelegationFinance> politique();

  /// Enregistre une nouvelle version (Direction seulement).
  Future<PolitiqueDelegationFinance> enregistrer({
    required BrouillonDelegationFinance brouillon,
    required String cleIdempotence,
  });

  /// Le journal des versions (CPT-BR-17).
  Future<List<EntreeJournal>> journal();
}

/// **Aucune source serveur a ce jour** (CPT-BR-13).
class DelegationFinanceIndisponible implements PortDelegationFinance {
  /// Cree l'implementation.
  const DelegationFinanceIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-13');

  @override
  Future<PolitiqueDelegationFinance> politique() =>
      Future<PolitiqueDelegationFinance>.error(_manque);

  @override
  Future<PolitiqueDelegationFinance> enregistrer({
    required BrouillonDelegationFinance brouillon,
    required String cleIdempotence,
  }) => Future<PolitiqueDelegationFinance>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal() =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`direction_demo.dart`).
final Provider<PortDelegationFinance> portDelegationFinanceProvider =
    Provider<PortDelegationFinance>(
      (Ref _) => const DelegationFinanceIndisponible(),
    );
