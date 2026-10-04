// Les encaissements et les remboursements (spec §24, §26, §33 ; CPT-BR-07,
// 15). Pose par CPT-F avec son interface complete ; **propriete de la voie
// CPT-ENC ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Meme source serveur que les recharges du foyer (FI-BR-06) et que
// l'« encaisse » de la Vue globale (FI-BR-12) : un adaptateur, pas deux.
// « Confirme » seulement apres le prestataire (§24.3). Les remboursements se
// voient et s'executent selon la politique Finance, jamais reecrite ici.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// L'affectation d'un encaissement a un profil (`LigneAllocation`).
@immutable
class AffectationProfil {
  /// Cree l'affectation.
  const AffectationProfil({
    required this.profilId,
    required this.prenom,
    required this.montant,
    this.cleAccent,
  });

  /// Le profil.
  final String profilId;

  /// Le prenom rendu.
  final String prenom;

  /// La part affectee.
  final Montant montant;

  /// La cle d'accent du profil, si la source la rend.
  final String? cleAccent;
}

/// Un encaissement (§24.2).
@immutable
class Encaissement {
  /// Cree l'encaissement.
  const Encaissement({
    required this.id,
    required this.date,
    required this.famille,
    required this.brut,
    required this.frais,
    required this.net,
    required this.moyen,
    required this.prestataire,
    required this.reference,
    required this.etat,
    this.rapprochement,
    this.profils = const <AffectationProfil>[],
    this.foyerId,
  });

  /// L'identifiant.
  final String id;

  /// La date.
  final DateTime date;

  /// La famille payeuse, rendue.
  final String famille;

  /// Le montant brut.
  final Montant brut;

  /// Les frais.
  final Montant frais;

  /// Le net.
  final Montant net;

  /// Le moyen (« Carte bancaire », « Mobile money »), rendu.
  final String moyen;

  /// Le prestataire, nom neutre.
  final String prestataire;

  /// La reference.
  final String reference;

  /// L'etat (§24.1).
  final EtatEncaissement etat;

  /// L'etat de rapprochement, s'il y en a un (§25).
  final EtatRapprochement? rapprochement;

  /// L'affectation par profil.
  final List<AffectationProfil> profils;

  /// Le foyer, pour le lien vers sa fiche.
  final String? foyerId;
}

/// Le filtre de la liste W05.
@immutable
class FiltreEncaissements {
  /// Cree le filtre.
  const FiltreEncaissements({this.etat, this.recherche, this.depuis});

  /// Tous.
  static const FiltreEncaissements tout = FiltreEncaissements();

  /// Un etat.
  final EtatEncaissement? etat;

  /// Famille ou reference.
  final String? recherche;

  /// Depuis une date.
  final DateTime? depuis;
}

/// Un remboursement ou un avoir (§26).
@immutable
class Remboursement {
  /// Cree le remboursement.
  const Remboursement({
    required this.id,
    required this.date,
    required this.beneficiaire,
    required this.motif,
    required this.montant,
    required this.source,
    required this.etat,
    required this.approbationRequise,
    this.encaissementId,
    this.permissions = PermissionsFinance.lectureSeule,
  });

  /// L'identifiant.
  final String id;

  /// La date de la demande.
  final DateTime date;

  /// Le beneficiaire du remboursement, rendu.
  final String beneficiaire;

  /// Le motif.
  final String motif;

  /// Le montant.
  final Montant montant;

  /// La source (encaissement, avoir).
  final String source;

  /// L'etat.
  final EtatRemboursement etat;

  /// Vrai si la politique exige une approbation.
  final bool approbationRequise;

  /// L'encaissement d'origine, s'il y en a un.
  final String? encaissementId;

  /// Ce que la source permet (`rembourser`).
  final PermissionsFinance permissions;
}

/// Le filtre des remboursements.
@immutable
class FiltreRemboursements {
  /// Cree le filtre.
  const FiltreRemboursements({this.etat});

  /// Tous.
  static const FiltreRemboursements tout = FiltreRemboursements();

  /// Un etat.
  final EtatRemboursement? etat;
}

/// Les encaissements (CPT-BR-07, 15).
abstract interface class PortEncaissements {
  /// La liste, filtree.
  Future<List<Encaissement>> liste(FiltreEncaissements filtre);

  /// Le detail d'un encaissement.
  Future<Encaissement> detail(String encaissementId);

  /// Les remboursements et avoirs.
  Future<List<Remboursement>> remboursements(FiltreRemboursements filtre);

  /// Execute un remboursement selon la politique, une fois.
  Future<Remboursement> executerRemboursement({
    required String remboursementId,
    required String cleIdempotence,
  });

  /// Le journal d'un encaissement ou d'un remboursement (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String objetId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-07).
class EncaissementsIndisponibles implements PortEncaissements {
  /// Cree l'implementation.
  const EncaissementsIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-07');
  static const CapaciteIndisponible _manqueRemboursement = CapaciteIndisponible(
    'CPT-BR-15',
  );

  @override
  Future<List<Encaissement>> liste(FiltreEncaissements filtre) =>
      Future<List<Encaissement>>.error(_manque);

  @override
  Future<Encaissement> detail(String encaissementId) =>
      Future<Encaissement>.error(_manque);

  @override
  Future<List<Remboursement>> remboursements(FiltreRemboursements filtre) =>
      Future<List<Remboursement>>.error(_manqueRemboursement);

  @override
  Future<Remboursement> executerRemboursement({
    required String remboursementId,
    required String cleIdempotence,
  }) => Future<Remboursement>.error(_manqueRemboursement);

  @override
  Future<List<EntreeJournal>> journal(String objetId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`encaissements_demo.dart`).
final Provider<PortEncaissements> portEncaissementsProvider =
    Provider<PortEncaissements>((Ref _) => const EncaissementsIndisponibles());
