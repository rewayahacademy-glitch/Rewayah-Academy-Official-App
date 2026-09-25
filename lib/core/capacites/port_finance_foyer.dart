import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

// Finance du foyer (complement Tuteur, section 5, S01 a S11).
//
// **Formes provisoires** : les tables `wallets`, `wallet_entries`, `payouts`
// existent en schema seulement (ADR-003) ; aucune RPC ni fonction ne les sert.
// Aucun calcul financier cote Flutter : montants en unites mineures et code
// ISO 4217, deja arretes par le serveur ; totaux, remises et consequences
// sont rendus par le serveur, jamais recalcules ici.

/// Le solde d'un profil (S01, S02).
@immutable
class SoldeProfil {
  /// Cree un solde.
  const SoldeProfil({
    required this.profilId,
    required this.montantMineur,
    required this.devise,
    this.derniereRemise,
  });

  /// Identifiant du profil (eleve).
  final String profilId;

  /// Montant en unites mineures. `null` = inconnu ou inaccessible, **jamais
  /// remplace par zero**.
  final int? montantMineur;

  /// Code ISO 4217 rendu par le serveur ; `null` si le solde est inconnu.
  final String? devise;

  /// Derniere remise liee a une seance, si le serveur en rend une.
  final MouvementSolde? derniereRemise;
}

/// Un sous-total par devise, rendu par le serveur (jamais une somme locale).
@immutable
class TotalSoldes {
  /// Cree un sous-total.
  const TotalSoldes({required this.montantMineur, required this.devise});

  /// Montant en unites mineures.
  final int montantMineur;

  /// Code ISO 4217.
  final String devise;
}

/// Les soldes des profils autorises du foyer (S01).
@immutable
class SoldesFoyer {
  /// Cree la lecture.
  const SoldesFoyer({
    required this.profils,
    required this.totaux,
    required this.complet,
    required this.luLe,
  });

  /// Un solde par profil autorise.
  final List<SoldeProfil> profils;

  /// Sous-totaux par devise, rendus par le serveur.
  final List<TotalSoldes> totaux;

  /// Faux si un profil est inaccessible ou son solde inconnu : le total est
  /// alors signale incomplet.
  final bool complet;

  /// Fraicheur de la lecture.
  final DateTime luLe;
}

/// Une ecriture du registre de solde (S07, S08).
@immutable
class MouvementSolde {
  /// Cree un mouvement.
  const MouvementSolde({
    required this.id,
    required this.profilId,
    required this.natureServeur,
    required this.statutServeur,
    required this.montantSigneMineur,
    required this.devise,
    required this.date,
    this.seanceId,
  });

  /// Identifiant.
  final String id;

  /// Profil concerne.
  final String profilId;

  /// Nature telle que le serveur la nommera (recharge, remise...). **Jamais
  /// affichee brute** : la liste sera fixee avec DB-FIN-02.
  final String natureServeur;

  /// Statut tel que le serveur le nommera. **Jamais affiche brut.**
  final String statutServeur;

  /// Montant signe en unites mineures.
  final int montantSigneMineur;

  /// Code ISO 4217.
  final String devise;

  /// Date de l'ecriture.
  final DateTime date;

  /// Seance liee, si le serveur en rend une (remise liee a une seance).
  final String? seanceId;
}

/// Une offre de recharge reellement proposee pour un profil (S04).
@immutable
class OffreRecharge {
  /// Cree une offre.
  const OffreRecharge({
    required this.id,
    required this.profilId,
    required this.prixMineur,
    required this.devise,
    required this.quantiteMineure,
  });

  /// Identifiant de l'offre.
  final String id;

  /// Profil beneficiaire.
  final String profilId;

  /// Prix en unites mineures.
  final int prixMineur;

  /// Code ISO 4217 du prix.
  final String devise;

  /// Quantite de solde obtenue, en unites mineures du solde (distincte du
  /// prix, F4).
  final int quantiteMineure;
}

/// Le choix d'une offre pour un profil, envoye au serveur pour devis.
@immutable
class ChoixRecharge {
  /// Cree un choix.
  const ChoixRecharge({required this.profilId, required this.offreId});

  /// Profil beneficiaire.
  final String profilId;

  /// Offre choisie.
  final String offreId;
}

/// Une ligne du devis, par profil (S05).
@immutable
class LigneDevis {
  /// Cree une ligne.
  const LigneDevis({
    required this.profilId,
    required this.prixMineur,
    required this.remiseMineure,
    required this.quantiteMineure,
  });

  /// Profil beneficiaire.
  final String profilId;

  /// Prix avant remise, en unites mineures.
  final int prixMineur;

  /// Remise commerciale, en unites mineures (0 si aucune).
  final int remiseMineure;

  /// Quantite de solde attribuee.
  final int quantiteMineure;
}

/// Le devis de recharge rendu par le serveur (S05).
@immutable
class DevisRecharge {
  /// Cree un devis.
  const DevisRecharge({
    required this.reference,
    required this.lignes,
    required this.totalMineur,
    required this.devise,
    required this.valableJusqua,
  });

  /// Reference du devis, a presenter au paiement.
  final String reference;

  /// Une ligne par profil.
  final List<LigneDevis> lignes;

  /// Total a payer, rendu par le serveur.
  final int totalMineur;

  /// Code ISO 4217.
  final String devise;

  /// Au-dela, le devis est caduc : aucun paiement sur un devis perime.
  final DateTime valableJusqua;
}

/// L'issue par profil, telle que le serveur la rend.
enum IssueServeur {
  /// Confirmee par le serveur.
  confirmee,

  /// Enregistree, en attente de traitement.
  enAttente,

  /// Echouee ou refusee.
  echouee,
}

/// L'issue d'une operation pour un profil (S06, S11).
@immutable
class IssueProfil {
  /// Cree l'issue.
  const IssueProfil({
    required this.profilId,
    required this.issue,
    this.motifServeur,
  });

  /// Profil concerne.
  final String profilId;

  /// Issue rendue par le serveur.
  final IssueServeur issue;

  /// Motif tel que le serveur le nommera. **Jamais affiche brut.**
  final String? motifServeur;
}

/// Le resultat d'une recharge (S06) : paiement et attribution sont distincts.
@immutable
class ResultatRecharge {
  /// Cree le resultat.
  const ResultatRecharge({
    required this.referencePaiement,
    required this.paiement,
    required this.attributions,
  });

  /// Reference du paiement, pour la reprise sans double paiement.
  final String referencePaiement;

  /// Etat du paiement.
  final IssueServeur paiement;

  /// Etat de l'attribution par profil.
  final List<IssueProfil> attributions;
}

/// Les consequences d'une annulation d'acces pour un profil (S10).
@immutable
class ConsequencesAnnulation {
  /// Cree les consequences.
  const ConsequencesAnnulation({
    required this.profilId,
    required this.eligible,
    required this.consequencesServeur,
    required this.repriseDisponible,
    this.motifServeur,
    this.dateEffet,
    this.soldeConserve,
  });

  /// Profil concerne.
  final String profilId;

  /// Faux : le profil reste visible avec [motifServeur].
  final bool eligible;

  /// Codes de consequences (seances, reservations, solde) tels que le
  /// serveur les nommera. **Jamais affiches bruts.**
  final List<String> consequencesServeur;

  /// Vrai si une reprise est possible.
  final bool repriseDisponible;

  /// Motif de non-eligibilite. **Jamais affiche brut.**
  final String? motifServeur;

  /// Date d'effet reelle.
  final DateTime? dateEffet;

  /// Solde restant du profil, tel que rendu.
  final SoldeProfil? soldeConserve;
}

/// L'apercu d'une annulation d'acces (S10).
@immutable
class ApercuAnnulation {
  /// Cree l'apercu.
  const ApercuAnnulation({required this.reference, required this.profils});

  /// Reference a presenter a la confirmation.
  final String reference;

  /// Une entree par profil demande.
  final List<ConsequencesAnnulation> profils;
}

/// Le resultat d'une annulation d'acces (S11).
@immutable
class ResultatAnnulation {
  /// Cree le resultat.
  const ResultatAnnulation({required this.profils});

  /// Issue par profil.
  final List<IssueProfil> profils;
}

/// La finance du foyer. Chaque methode depend d'un besoin serveur distinct
/// (DB-FIN-01 a DB-FIN-06).
abstract interface class PortFinanceFoyer {
  /// DB-FIN-01 : les soldes des profils autorises.
  Future<SoldesFoyer> soldes();

  /// DB-FIN-02 : les mouvements, filtres si demande.
  Future<List<MouvementSolde>> mouvements({String? profilId});

  /// DB-FIN-02 : un mouvement precis.
  Future<MouvementSolde?> mouvement(String id);

  /// DB-FIN-03 : les offres reellement proposees pour ces profils.
  Future<List<OffreRecharge>> offresRecharge(List<String> profilIds);

  /// DB-FIN-03 : le devis de ces choix.
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix);

  /// DB-FIN-04 : payer un devis et attribuer. [cleIdempotence] empeche le
  /// double paiement.
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  });

  /// DB-FIN-05 : les consequences d'une annulation, avant confirmation.
  Future<ApercuAnnulation> apercuAnnulation(List<String> profilIds);

  /// DB-FIN-06 : annuler l'acces des profils d'un apercu.
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  });
}

/// La finance tant qu'aucune source n'existe : jamais un solde, un paiement
/// ou une annulation simules. Aucun adaptateur avant DB-FIN-01 a 06.
class FinanceFoyerIndisponible implements PortFinanceFoyer {
  /// Cree l'implementation.
  const FinanceFoyerIndisponible();

  static Future<T> _manque<T>(String code) =>
      Future<T>.error(CapaciteIndisponible(code));

  @override
  Future<SoldesFoyer> soldes() => _manque('DB-FIN-01');

  @override
  Future<List<MouvementSolde>> mouvements({String? profilId}) =>
      _manque('DB-FIN-02');

  @override
  Future<MouvementSolde?> mouvement(String id) => _manque('DB-FIN-02');

  @override
  Future<List<OffreRecharge>> offresRecharge(List<String> profilIds) =>
      _manque('DB-FIN-03');

  @override
  Future<DevisRecharge> devisRecharge(List<ChoixRecharge> choix) =>
      _manque('DB-FIN-03');

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) => _manque('DB-FIN-04');

  @override
  Future<ApercuAnnulation> apercuAnnulation(List<String> profilIds) =>
      _manque('DB-FIN-05');

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) => _manque('DB-FIN-06');
}

/// La finance employee par l'application (K-09 : le reel ne se branche que
/// dans main.dart).
final Provider<PortFinanceFoyer> portFinanceFoyerProvider =
    Provider<PortFinanceFoyer>((Ref ref) => const FinanceFoyerIndisponible());
