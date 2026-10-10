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
// FI-BR-06 (qui remplace EA-BR-24, 25 et 26) ; la demonstration surcharge
// le port.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import '../finance/suivi_paiement.dart';
import '../session/session_controleur.dart';
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
/// montants qu'il peut recevoir. Rien d'autre : ni Classe, ni niveau (F6).
@immutable
class BeneficiaireRecharge {
  /// Cree le beneficiaire.
  const BeneficiaireRecharge({
    required this.id,
    required this.prenom,
    this.soldeRendu,
    this.solde,
    this.offres = const <OffreRecharge>[],
    this.montantsProposes = const <Montant>[],
    this.montantSuggere,
    this.montantsRediges = const <Montant, String>{},
    this.cleAvatar,
  });

  /// L'identifiant du profil eleve.
  final String id;

  /// Le prenom.
  final String prenom;

  /// La cle de sa photo, ou `null` (initiales).
  final String? cleAvatar;

  /// Son solde, deja redige, affiche tel quel (E2), ou `null`.
  final String? soldeRendu;

  /// Son solde en unites mineures + ISO (FI-7), ou `null` : il prime sur
  /// [soldeRendu] quand la source le rend.
  final Montant? solde;

  /// Les offres qui le concernent, dans l'ordre rendu (EA-10, F11).
  final List<OffreRecharge> offres;

  /// Les montants qu'il peut recevoir, croissants, tels que la source les
  /// rend (FI-7, guide V4 §5.3) : l'ecran passe de l'un a l'autre, il n'en
  /// calcule aucun (FI6). Choisi plutot que saisi (K-57).
  final List<Montant> montantsProposes;

  /// Le montant suggere (par exemple le manque du mois), l'un de
  /// [montantsProposes], ou `null` : rien n'est choisi d'avance (guide V4
  /// §5.3, « minimum requis peut etre suggere »).
  final Montant? montantSuggere;

  /// Le libelle que la source redige pour un montant propose, affiche tel
  /// quel a la place du montant formate (E2) : la demonstration EA marque
  /// ainsi ses prix « (demonstration) » (F12, revue EA-R m4). Un montant
  /// absent se formate (`formaterMontant`).
  final Map<Montant, String> montantsRediges;
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

/// Le montant choisi par le titulaire pour un beneficiaire (FI-1c, guide
/// Finance V4 §5.3, revue FI-1a E-1) : il remplace l'offre unique de F11.
/// Le serveur arrete ensuite le total (FI8).
@immutable
class MontantRecharge {
  /// Cree le montant choisi.
  const MontantRecharge({required this.beneficiaireId, required this.montant});

  /// Le beneficiaire.
  final String beneficiaireId;

  /// Le montant choisi pour lui, en unites mineures + ISO.
  final Montant montant;
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
  /// Les beneficiaires autorises et leurs offres (FI-BR-06).
  Future<List<BeneficiaireRecharge>> beneficiaires();

  /// Le recapitulatif de ces choix, arrete par le serveur (FI-BR-06). Depuis
  /// FI-7, l'ecran verifie par montants ([verifierMontants]) : ce contrat par
  /// offres reste celui des sources EA, il n'a plus d'appelant a l'ecran.
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix);

  /// Paie le recapitulatif [recapitulatifId], idempotent par [cle] : une
  /// nouvelle tentative apres une coupure ne paie pas deux fois (FI-BR-06),
  /// et la meme cle rend la meme commande (FI-8 : double confirmation, un
  /// seul credit). Rend l'identifiant de la commande, dont l'etat se lit par
  /// [suivre] : l'ecran n'en deduit jamais une reussite (F13, FI9).
  Future<String> payer({required String recapitulatifId, required String cle});

  /// Le recapitulatif d'une recharge par montants choisis (FI-1c, FI-BR-06) :
  /// un montant par profil, le total et la taxe arretes par le serveur avant
  /// le paiement.
  Future<RecapitulatifRecharge> verifierMontants(List<MontantRecharge> choix);

  /// L'etat de la commande [commandeId], tel que la source le rend (FI-1c,
  /// FI-BR-06) : l'un des huit etats, jamais deduit par l'ecran (FI9).
  Future<SuiviPaiement> suivre(String commandeId);
}

/// **Aucune source serveur a ce jour** (FI-BR-06, qui remplace EA-BR-24 et
/// EA-BR-25).
class RechargeFoyerIndisponible implements PortRechargeFoyer {
  /// Cree l'implementation.
  const RechargeFoyerIndisponible();

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() =>
      Future<List<BeneficiaireRecharge>>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => Future<String>.error(const CapaciteIndisponible('FI-BR-06'));

  @override
  Future<RecapitulatifRecharge> verifierMontants(List<MontantRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Future<SuiviPaiement>.error(const CapaciteIndisponible('FI-BR-06'));
}

/// Le port de la recharge ; la demonstration le surcharge.
final Provider<PortRechargeFoyer> portRechargeFoyerProvider =
    Provider<PortRechargeFoyer>((Ref _) => const RechargeFoyerIndisponible());

/// Les beneficiaires de la recharge et leurs offres.
final FutureProvider<List<BeneficiaireRecharge>> beneficiairesRechargeProvider =
    FutureProvider<List<BeneficiaireRecharge>>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portRechargeFoyerProvider).beneficiaires();
    });
