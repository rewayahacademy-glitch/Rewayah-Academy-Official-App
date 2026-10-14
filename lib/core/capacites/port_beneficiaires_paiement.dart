// Les profils de paiement vus par le personnel (spec §16, §19, §27.2, §35 ;
// CPT-BR-06). Pose par CPT-F avec son interface complete ; **propriete de la
// voie CPT-BEN ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// **Aucune ecriture de coordonnees par le personnel** (R-FIN-11, 12) : voir
// un statut, une representation masquee, demander une mise a jour, relancer
// (fil metier « Profil de paiement », CPT-COM), suspendre selon capacite,
// marquer une verification requise. La lecture par la Direction depend de CPT-Q1.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Un paiement passe d'un beneficiaire (historique de W07).
@immutable
class PaiementPasse {
  /// Cree le paiement.
  const PaiementPasse({
    required this.obligationId,
    required this.date,
    required this.periode,
    required this.montant,
    required this.etat,
    this.reference,
  });

  /// L'obligation payee.
  final String obligationId;

  /// La date.
  final DateTime date;

  /// La periode lisible.
  final String periode;

  /// Le montant.
  final Montant montant;

  /// L'etat final.
  final EtatPaiementSortant etat;

  /// La reference du prestataire.
  final String? reference;
}

/// Le profil de paiement d'un beneficiaire, vu par le Comptable (W07).
@immutable
class ProfilPaiementBeneficiaire {
  /// Cree le profil.
  const ProfilPaiementBeneficiaire({
    required this.identite,
    required this.etat,
    this.destination,
    this.derniereModification,
    this.capacite,
    this.historique = const <PaiementPasse>[],
    this.permissions = PermissionsFinance.lectureSeule,
    this.obligationsEnAttente = 0,
  });

  /// L'identite.
  final IdentiteBeneficiaire identite;

  /// L'etat du profil (§38, §18).
  final EtatProfilPaiement etat;

  /// La methode masquee, s'il y en a une.
  final DestinationMasquee? destination;

  /// La derniere modification du profil.
  final DateTime? derniereModification;

  /// La capacite de payout du corridor, si la source l'a evaluee.
  final CapacitePayout? capacite;

  /// L'historique des paiements.
  final List<PaiementPasse> historique;

  /// Ce que la source permet (`relancer`, `demanderMiseAJour`, `suspendre`).
  final PermissionsFinance permissions;

  /// Le nombre d'obligations qui attendent ce profil.
  final int obligationsEnAttente;
}

/// Le filtre de la liste des beneficiaires.
@immutable
class FiltreBeneficiaires {
  /// Cree le filtre.
  const FiltreBeneficiaires({this.etat, this.type, this.recherche});

  /// Tous.
  static const FiltreBeneficiaires tout = FiltreBeneficiaires();

  /// Un etat de profil.
  final EtatProfilPaiement? etat;

  /// Un type de beneficiaire.
  final TypeBeneficiaire? type;

  /// Une recherche sur le nom.
  final String? recherche;
}

/// Les beneficiaires (CPT-BR-06).
abstract interface class PortBeneficiairesPaiement {
  /// La liste, filtree.
  Future<List<ProfilPaiementBeneficiaire>> liste(FiltreBeneficiaires filtre);

  /// Le profil d'un beneficiaire.
  Future<ProfilPaiementBeneficiaire> profil(String beneficiaireId);

  /// Demande au beneficiaire de mettre a jour ses coordonnees.
  Future<ProfilPaiementBeneficiaire> demanderMiseAJour(String beneficiaireId);

  /// Suspend les payouts du beneficiaire, avec motif.
  Future<ProfilPaiementBeneficiaire> suspendre({
    required String beneficiaireId,
    required String motif,
  });

  /// Reprend les payouts.
  Future<ProfilPaiementBeneficiaire> reprendre(String beneficiaireId);

  /// Marque la methode comme necessitant une verification (§16.2).
  Future<ProfilPaiementBeneficiaire> marquerVerificationRequise(
    String beneficiaireId,
  );

  /// Le journal d'un profil (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String beneficiaireId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-06).
class BeneficiairesPaiementIndisponibles implements PortBeneficiairesPaiement {
  /// Cree l'implementation.
  const BeneficiairesPaiementIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-06');

  @override
  Future<List<ProfilPaiementBeneficiaire>> liste(FiltreBeneficiaires filtre) =>
      Future<List<ProfilPaiementBeneficiaire>>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> profil(String beneficiaireId) =>
      Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> demanderMiseAJour(String beneficiaireId) =>
      Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> suspendre({
    required String beneficiaireId,
    required String motif,
  }) => Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> reprendre(String beneficiaireId) =>
      Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<ProfilPaiementBeneficiaire> marquerVerificationRequise(
    String beneficiaireId,
  ) => Future<ProfilPaiementBeneficiaire>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String beneficiaireId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`beneficiaires_demo.dart`).
final Provider<PortBeneficiairesPaiement> portBeneficiairesPaiementProvider =
    Provider<PortBeneficiairesPaiement>(
      (Ref _) => const BeneficiairesPaiementIndisponibles(),
    );
