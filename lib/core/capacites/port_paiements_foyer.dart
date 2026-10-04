import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finances_profil.dart';
import '../finance/mouvements_profil.dart';
import 'capacite_indisponible.dart';

/// Un paiement du foyer, tel qu'une future source le rendra.
///
/// **Forme provisoire** : aucune table de paiement famille n'existe
/// (DB-CPT-03). Aucun calcul financier cote Flutter : le montant arrive en
/// unites mineures, deja arrete par le serveur.
@immutable
class PaiementFoyer {
  /// Cree un paiement.
  const PaiementFoyer({
    required this.id,
    required this.montantMineur,
    required this.devise,
    required this.statutServeur,
    required this.date,
    required this.justificatifDisponible,
  });

  /// Identifiant.
  final String id;

  /// Montant en unites mineures (centimes), rendu par le serveur.
  final int montantMineur;

  /// Code ISO 4217.
  final String devise;

  /// Statut tel que le serveur le nommera. **Jamais affiche brut** : la liste
  /// des statuts sera fixee avec DB-CPT-03.
  final String statutServeur;

  /// Date du paiement.
  final DateTime date;

  /// Vrai quand un justificatif est telechargeable.
  final bool justificatifDisponible;
}

/// Une exception sur le solde d'un beneficiaire, quand le serveur la rend
/// (F12) : jamais deduite d'un seuil dans Flutter. L'etat normal n'en a pas
/// (E12) : aucune pastille « Actif ».
enum ExceptionSolde {
  /// Le serveur dit que le solde sera bientot epuise.
  bientotEpuise,

  /// Le serveur dit que l'acces du beneficiaire est inactif.
  inactif,
}

/// Le solde d'un beneficiaire autorise, tel que le serveur le rend (F9, F10,
/// EA-BR-23).
///
/// **Aucun calcul** : le solde arrive deja redige ([soldeRendu]), sans taux
/// ni devise ajoutes par Flutter (decision E2, Q9). Rien d'autre sur le
/// beneficiaire : ni Classe, ni niveau, ni seance (F6, doc section 7.3).
@immutable
class SoldeBeneficiaire {
  /// Cree un solde.
  const SoldeBeneficiaire({
    required this.id,
    required this.prenom,
    required this.soldeRendu,
    this.cleAvatar,
    this.exception,
  });

  /// L'identifiant du profil eleve.
  final String id;

  /// Le prenom du beneficiaire.
  final String prenom;

  /// La cle de sa photo, `null` sans photo ou quand le serveur ne la rend
  /// pas (le second adulte, Q4) : les initiales.
  final String? cleAvatar;

  /// Le solde, deja redige par le serveur, affiche tel quel.
  final String soldeRendu;

  /// L'exception que le serveur rend, `null` pour l'etat normal.
  final ExceptionSolde? exception;
}

/// Les soldes du foyer vus par le titulaire (EA-BR-23).
@immutable
class SoldesFoyer {
  /// Cree la vue.
  const SoldesFoyer({required this.beneficiaires, this.recapitulatif});

  /// Une ligne par beneficiaire autorise, dans l'ordre rendu.
  final List<SoldeBeneficiaire> beneficiaires;

  /// Le recapitulatif du foyer, deja redige par le serveur, ou `null`.
  /// Jamais additionne dans Flutter, jamais une somme a depenser (F9).
  final String? recapitulatif;
}

/// Les paiements du foyer (contrat K6).
abstract interface class PortPaiementsFoyer {
  /// L'historique des paiements.
  Future<List<PaiementFoyer>> historique();

  /// Un paiement precis.
  Future<PaiementFoyer?> detail(String id);

  /// Les soldes des beneficiaires autorises, pour le titulaire seulement
  /// (EA-BR-23).
  Future<SoldesFoyer> soldes();

  /// Les finances du foyer (FI-1c, FI-BR-03, FI-BR-04) : par profil, solde
  /// individuel en unites mineures + ISO, periode financee, prochain debit,
  /// lignes de mensualite et etat ; synthese du foyer en lecture. Pour le
  /// titulaire seulement : jamais rendu a l'enfant ni au second adulte
  /// (lecon 15).
  Future<FinancesFoyer> finances();

  /// Les mouvements du profil [profilId] (FI-6b, FI-BR-05) : recharges,
  /// debits de periode, avoirs et remises, montants signes, statut et recu
  /// eventuel, dans l'ordre rendu (le plus recent d'abord). Historique en
  /// ajout seul : aucune ecriture n'est exposee. Pour le titulaire seulement
  /// (lecon 15).
  Future<List<MouvementProfil>> mouvements(String profilId);
}

/// Les paiements tant qu'aucune source n'existe : une page, une phrase, aucun
/// bouton, jamais un paiement simule comme regle. Aucun adaptateur prevu avant
/// DB-CPT-03.
class PaiementsFoyerIndisponible implements PortPaiementsFoyer {
  /// Cree l'implementation.
  const PaiementsFoyerIndisponible();

  @override
  Future<List<PaiementFoyer>> historique() => Future<List<PaiementFoyer>>.error(
    const CapaciteIndisponible('DB-CPT-03'),
  );

  @override
  Future<PaiementFoyer?> detail(String id) =>
      Future<PaiementFoyer?>.error(const CapaciteIndisponible('DB-CPT-03'));

  @override
  Future<SoldesFoyer> soldes() =>
      Future<SoldesFoyer>.error(const CapaciteIndisponible('EA-BR-23'));

  @override
  Future<FinancesFoyer> finances() =>
      Future<FinancesFoyer>.error(const CapaciteIndisponible('FI-BR-03'));

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) =>
      Future<List<MouvementProfil>>.error(
        const CapaciteIndisponible('FI-BR-05'),
      );
}

/// Les paiements employes par l'application.
final Provider<PortPaiementsFoyer> portPaiementsFoyerProvider =
    Provider<PortPaiementsFoyer>(
      (Ref ref) => const PaiementsFoyerIndisponible(),
    );
