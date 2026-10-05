// La recharge du foyer (EA-10, planches 4.2 et 4.3) : les beneficiaires
// autorises et l'offre que le serveur rend pour chacun, la verification
// (recapitulatif separe par beneficiaire, F11), puis le paiement.
//
// **Aucun chiffre economique dans Flutter** (F12) : chaque montant, chaque
// quantite de solde, chaque remise, chaque statut et le total arrivent DEJA
// REDIGES par le serveur et s'affichent tels quels. Rien n'est additionne,
// reparti ni deduit ici. **Aucun succes local** (F13) : le paiement n'a
// aucune source a ce jour (le prestataire n'est pas choisi, doc section
// 20.8), il rend `CapaciteIndisponible`.
//
// Aucune source serveur (K-28) : les offres et la verification attendent
// EA-BR-24, le paiement EA-BR-25 ; la demonstration surcharge le port.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Une offre de recharge, telle que le serveur la rend pour un beneficiaire.
@immutable
class OffreRecharge {
  /// Cree une offre.
  const OffreRecharge({required this.id, required this.libelle, this.detail});

  /// L'identifiant de l'offre.
  final String id;

  /// Ce que l'offre coute, deja redige par le serveur.
  final String libelle;

  /// Ce qu'elle attribue (la quantite de solde), deja redige, ou `null`.
  final String? detail;
}

/// Un beneficiaire que le titulaire peut recharger (F10) : son prenom, sa
/// photo (jamais celle du second adulte, Q4), son solde tel que rendu et les
/// offres qui le concernent. Rien d'autre : ni Classe, ni niveau (F6).
@immutable
class BeneficiaireRecharge {
  /// Cree le beneficiaire.
  const BeneficiaireRecharge({
    required this.id,
    required this.prenom,
    required this.soldeRendu,
    required this.offres,
    this.cleAvatar,
  });

  /// L'identifiant du profil eleve.
  final String id;

  /// Le prenom.
  final String prenom;

  /// La cle de sa photo, ou `null` (initiales).
  final String? cleAvatar;

  /// Son solde, deja redige, affiche tel quel (E2).
  final String soldeRendu;

  /// Les offres qui le concernent, dans l'ordre rendu.
  final List<OffreRecharge> offres;
}

/// Le choix du titulaire pour un beneficiaire : une offre, jamais un montant
/// saisi ni reparti (F11).
@immutable
class ChoixRecharge {
  /// Cree le choix.
  const ChoixRecharge({required this.beneficiaireId, required this.offreId});

  /// Le beneficiaire.
  final String beneficiaireId;

  /// L'offre choisie pour lui.
  final String offreId;
}

/// Une remise, seulement quand le serveur la rend, avec SON libelle (F12).
@immutable
class RemiseRendue {
  /// Cree la remise.
  const RemiseRendue({required this.libelle, required this.valeur});

  /// Le libelle du serveur.
  final String libelle;

  /// Sa valeur, deja redigee.
  final String valeur;
}

/// Une ligne du recapitulatif, pour un beneficiaire (F11) : qui recoit, le
/// montant paye, la quantite de solde attribuee, l'eventuelle remise et le
/// statut de l'attribution.
@immutable
class LigneRecapitulatif {
  /// Cree la ligne.
  const LigneRecapitulatif({
    required this.beneficiaireId,
    required this.prenom,
    required this.montantPaye,
    required this.soldeAttribue,
    required this.statut,
    this.cleAvatar,
    this.remise,
  });

  /// Le beneficiaire.
  final String beneficiaireId;

  /// Son prenom.
  final String prenom;

  /// La cle de sa photo, ou `null`.
  final String? cleAvatar;

  /// Le montant paye pour lui, deja redige.
  final String montantPaye;

  /// La quantite de solde qui lui sera attribuee, deja redigee.
  final String soldeAttribue;

  /// La remise rendue, ou `null` : aucune ligne de remise.
  final RemiseRendue? remise;

  /// Le statut de l'attribution, deja redige.
  final String statut;
}

/// Le recapitulatif que le serveur arrete avant le paiement.
@immutable
class RecapitulatifRecharge {
  /// Cree le recapitulatif.
  const RecapitulatifRecharge({
    required this.id,
    required this.lignes,
    required this.total,
  });

  /// L'identifiant du recapitulatif, que le paiement reprend.
  final String id;

  /// Une ligne par beneficiaire choisi, dans l'ordre rendu.
  final List<LigneRecapitulatif> lignes;

  /// Le total a payer, deja redige : jamais additionne dans Flutter.
  final String total;
}

/// La recharge du foyer, pour le titulaire seulement.
abstract interface class PortRechargeFoyer {
  /// Les beneficiaires autorises et leurs offres (EA-BR-24).
  Future<List<BeneficiaireRecharge>> beneficiaires();

  /// Le recapitulatif de ces choix, arrete par le serveur (EA-BR-24).
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix);

  /// Paie le recapitulatif [recapitulatifId], idempotent par [cle] : une
  /// nouvelle tentative apres une coupure ne paie pas deux fois (EA-BR-25).
  /// Rend l'etat du paiement DEJA REDIGE par le serveur, affiche tel quel :
  /// l'ecran n'en deduit jamais une reussite (F13).
  Future<String> payer({required String recapitulatifId, required String cle});
}

/// **Aucune source serveur a ce jour** (EA-BR-24, EA-BR-25).
class RechargeFoyerIndisponible implements PortRechargeFoyer {
  /// Cree l'implementation.
  const RechargeFoyerIndisponible();

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() =>
      Future<List<BeneficiaireRecharge>>.error(
        const CapaciteIndisponible('EA-BR-24'),
      );

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('EA-BR-24'),
      );

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => Future<String>.error(const CapaciteIndisponible('EA-BR-25'));
}

/// Le port de la recharge ; la demonstration le surcharge.
final Provider<PortRechargeFoyer> portRechargeFoyerProvider =
    Provider<PortRechargeFoyer>((Ref _) => const RechargeFoyerIndisponible());

/// Les beneficiaires de la recharge et leurs offres.
final FutureProvider<List<BeneficiaireRecharge>> beneficiairesRechargeProvider =
    FutureProvider<List<BeneficiaireRecharge>>(
      (Ref ref) => ref.watch(portRechargeFoyerProvider).beneficiaires(),
    );
