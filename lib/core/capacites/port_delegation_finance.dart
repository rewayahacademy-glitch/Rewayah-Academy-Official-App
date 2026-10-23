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
import '../comptable/statuts_comptable.dart' show Coffre;
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// L'etat d'une delegation (DELEG-FIN-1), rendu par la source.
enum EtatDelegation {
  /// En vigueur.
  active,

  /// Suspendue par la Direction : rien n'est plus delegue, tout de suite.
  suspendue,

  /// Arrivee a expiration : a renouveler.
  expiree,
}

/// Un beneficiaire que la Direction exclut d'une delegation.
@immutable
class BeneficiaireExclu {
  /// Cree la ligne.
  const BeneficiaireExclu({required this.id, required this.nom});

  /// L'identifiant du beneficiaire.
  final String id;

  /// Son nom, rendu par la source.
  final String nom;

  @override
  bool operator ==(Object other) =>
      other is BeneficiaireExclu && other.id == id && other.nom == nom;

  @override
  int get hashCode => Object.hash(id, nom);
}

/// Une exception a la politique generale (DELEG-FIN-1), reglee par
/// delegation : les coffres autorises (liste fermee), les beneficiaires
/// exclus et un plafond par transaction **plus bas** que celui de la
/// politique generale, jamais plus haut. Appliquee par le serveur.
@immutable
class ExceptionDelegation {
  /// Cree l'exception.
  const ExceptionDelegation({
    required this.id,
    required this.libelle,
    this.coffresAutorises = const <Coffre>{},
    this.beneficiairesExclus = const <BeneficiaireExclu>[],
    this.plafondParTransaction,
  });

  /// L'identifiant de l'exception.
  final String id;

  /// Le nom de la delegation concernee (« Delegation du Comptable »).
  final String libelle;

  /// Les coffres que la delegation peut toucher.
  final Set<Coffre> coffresAutorises;

  /// Les beneficiaires exclus.
  final List<BeneficiaireExclu> beneficiairesExclus;

  /// Le plafond par transaction propre a cette delegation, plus bas que la
  /// politique generale.
  final Montant? plafondParTransaction;
}

/// Une sortie retenue par le delai de 24 h (DELEG-FIN-1) : au-dessus du
/// plafond par transaction, elle attend, et la Direction peut l'annuler.
@immutable
class SortieEnAttente {
  /// Cree la ligne.
  const SortieEnAttente({
    required this.id,
    required this.beneficiaire,
    required this.objet,
    required this.montant,
    required this.demandeeLe,
    required this.liberableLe,
  });

  /// L'identifiant de la sortie.
  final String id;

  /// Le beneficiaire, nom rendu par la source.
  final String beneficiaire;

  /// L'objet (« Octobre 2026 · Classe Al-Fajr »).
  final String objet;

  /// Le montant.
  final Montant montant;

  /// Quand la sortie a ete demandee.
  final DateTime demandeeLe;

  /// Quand elle part si personne ne l'annule, rendu par la source.
  final DateTime liberableLe;
}

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
    this.etat = EtatDelegation.active,
    this.suspendueLe,
    this.expireLe,
    this.dureeJours,
    this.delaiSortieHeures,
    this.exceptions = const <ExceptionDelegation>[],
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

  /// DELEG-FIN-1 : l'etat de la delegation, **rendu par la source** (active,
  /// suspendue, expiree) ; l'ecran ne le deduit jamais d'une date.
  final EtatDelegation etat;

  /// Quand la Direction a suspendu toutes les delegations, si elle l'a fait.
  final DateTime? suspendueLe;

  /// La date d'expiration de la delegation (chaque delegation expire,
  /// renouvelable), rendue par la source.
  final DateTime? expireLe;

  /// La duree d'une delegation, en jours (90 par defaut cote source).
  final int? dureeJours;

  /// Le delai, en heures, d'une sortie au-dessus du plafond par transaction
  /// (24 par defaut cote source), annulable par la Direction.
  final int? delaiSortieHeures;

  /// Les exceptions par delegation (coffres autorises, beneficiaires exclus,
  /// plafond plus bas que la politique generale), rendues par la source.
  final List<ExceptionDelegation> exceptions;
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
    this.exceptions = const <ExceptionDelegation>[],
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
        exceptions: p.exceptions,
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

  /// DELEG-FIN-1 : les exceptions proposees (le serveur refuse un plafond plus
  /// haut que celui de la politique generale).
  final List<ExceptionDelegation> exceptions;
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

/// DELEG-FIN-1 : les gestes de controle de la Direction sur les delegations
/// (suspension immediate, renouvellement, sorties en attente). **Tout est
/// applique par le serveur** (CPT-BR-13) ; l'ecran envoie le geste, lit le
/// resultat, ne calcule rien.
abstract interface class PortControleDelegation {
  /// Suspend TOUTES les delegations, effet immediat. Rend la politique relue.
  Future<PolitiqueDelegationFinance> suspendreToutes({
    required String cleIdempotence,
  });

  /// Leve la suspension, sur action explicite de la Direction et avec une
  /// [raison] obligatoire. La capacite est exigee et le serveur exige la MFA,
  /// comme pour toute action Direction ; il inscrit la reactivation au
  /// journal. **Ne restaure jamais une delegation expiree** : la politique
  /// rendue dit `expiree`, et seul [renouveler] repart sur la duree (90 j).
  /// Les sorties annulees pendant la suspension restent annulees.
  Future<PolitiqueDelegationFinance> reactiver({
    required String cleIdempotence,
    required String raison,
  });

  /// Renouvelle la delegation pour sa duree. Rend la politique relue.
  Future<PolitiqueDelegationFinance> renouveler({
    required String cleIdempotence,
  });

  /// Les sorties retenues par le delai, la plus proche de sa liberation
  /// d'abord.
  Future<List<SortieEnAttente>> sortiesEnAttente();

  /// Annule une sortie en attente (une seule fois, cle d'idempotence).
  Future<void> annulerSortie({
    required String sortieId,
    required String cleIdempotence,
  });
}

/// **Aucune source serveur a ce jour** (CPT-BR-13).
class ControleDelegationIndisponible implements PortControleDelegation {
  /// Cree l'implementation.
  const ControleDelegationIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-13');

  @override
  Future<PolitiqueDelegationFinance> suspendreToutes({
    required String cleIdempotence,
  }) => Future<PolitiqueDelegationFinance>.error(_manque);

  @override
  Future<PolitiqueDelegationFinance> reactiver({
    required String cleIdempotence,
    required String raison,
  }) => Future<PolitiqueDelegationFinance>.error(_manque);

  @override
  Future<PolitiqueDelegationFinance> renouveler({
    required String cleIdempotence,
  }) => Future<PolitiqueDelegationFinance>.error(_manque);

  @override
  Future<List<SortieEnAttente>> sortiesEnAttente() =>
      Future<List<SortieEnAttente>>.error(_manque);

  @override
  Future<void> annulerSortie({
    required String sortieId,
    required String cleIdempotence,
  }) => Future<void>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`direction_demo.dart`).
final Provider<PortControleDelegation> portControleDelegationProvider =
    Provider<PortControleDelegation>(
      (Ref _) => const ControleDelegationIndisponible(),
    );
