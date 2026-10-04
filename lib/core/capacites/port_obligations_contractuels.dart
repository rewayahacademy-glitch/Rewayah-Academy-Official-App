// Les obligations de contractuels (spec §18, §22, §23, §34 ; CPT-BR-08).
// Pose par CPT-F avec son interface complete ; **propriete de la voie
// CPT-CTR ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Recurrente (calculee si le contrat est connu) ou ponctuelle (montant saisi
// **a la creation seulement**, fige apres approbation : « Karim Studio -
// Facture #024 - 350 USD » → « Payer 350 USD »). Une obligation approuvee
// devient une obligation payable (CPT-BR-01) : « Payer » ouvre W03, jamais
// un second tunnel (DR-12). Le beneficiaire externe sans compte recoit une
// invitation securisee : etat « Invitation envoyee » (§18, DR-16).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Une obligation de contractuel (§22.3).
@immutable
class ObligationContractuel {
  /// Cree l'obligation.
  const ObligationContractuel({
    required this.id,
    required this.type,
    required this.beneficiaire,
    required this.objet,
    required this.montant,
    required this.echeance,
    required this.etat,
    required this.auteur,
    this.justificatif,
    this.centreCout,
    this.approbateur,
    this.obligationPayableId,
    this.profilBeneficiaire,
    this.permissions = PermissionsFinance.lectureSeule,
  });

  /// L'identifiant.
  final String id;

  /// Recurrente ou ponctuelle.
  final TypeObligationContractuel type;

  /// Le beneficiaire.
  final IdentiteBeneficiaire beneficiaire;

  /// L'objet (« Facture #024 »).
  final String objet;

  /// Le montant, fige apres approbation.
  final Montant montant;

  /// L'echeance.
  final DateTime echeance;

  /// L'etat.
  final EtatObligationContractuel etat;

  /// L'auteur, rendu.
  final String auteur;

  /// Le justificatif, reference rendue.
  final String? justificatif;

  /// Le centre de cout, rendu.
  final String? centreCout;

  /// L'approbateur requis ou effectif, rendu.
  final String? approbateur;

  /// L'obligation payable creee a l'approbation : la cible de « Payer »
  /// (`Routes.comptablePaiementObligationPour`).
  final String? obligationPayableId;

  /// L'etat du profil de paiement du beneficiaire (dont « Invitation
  /// envoyee » pour un externe).
  final EtatProfilPaiement? profilBeneficiaire;

  /// Ce que la source permet (`approuver`, `payer`...).
  final PermissionsFinance permissions;
}

/// Le brouillon d'une nouvelle obligation ponctuelle (K-57 : le beneficiaire,
/// la devise, l'echeance et le centre de cout se preremplissent ou se
/// choisissent ; seuls l'objet et le montant se saisissent, parce qu'une
/// facture externe n'est connue que de celui qui la recoit).
@immutable
class BrouillonObligationContractuel {
  /// Cree le brouillon.
  const BrouillonObligationContractuel({
    required this.beneficiaireId,
    required this.objet,
    required this.montant,
    required this.echeance,
    this.type = TypeObligationContractuel.ponctuelle,
    this.justificatif,
    this.centreCout,
    this.nouveauBeneficiaire,
  });

  /// Le beneficiaire existant, ou vide avec [nouveauBeneficiaire].
  final String beneficiaireId;

  /// Le type.
  final TypeObligationContractuel type;

  /// L'objet.
  final String objet;

  /// Le montant, saisi a la creation seulement.
  final Montant montant;

  /// L'echeance.
  final DateTime echeance;

  /// Le justificatif (reference d'une piece deposee).
  final String? justificatif;

  /// Le centre de cout.
  final String? centreCout;

  /// Le nom d'un beneficiaire externe sans compte, a inviter (§18).
  final String? nouveauBeneficiaire;
}

/// Le filtre de la liste W06.
@immutable
class FiltreObligationsContractuels {
  /// Cree le filtre.
  const FiltreObligationsContractuels({this.etat, this.type});

  /// Toutes.
  static const FiltreObligationsContractuels tout =
      FiltreObligationsContractuels();

  /// Un etat.
  final EtatObligationContractuel? etat;

  /// Un type.
  final TypeObligationContractuel? type;
}

/// Les obligations de contractuels (CPT-BR-08).
abstract interface class PortObligationsContractuels {
  /// La liste, filtree.
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  );

  /// Le detail d'une obligation.
  Future<ObligationContractuel> detail(String obligationId);

  /// Cree une obligation, une fois (cle d'idempotence) ; reserve a la
  /// capacite `creerObligation`.
  Future<ObligationContractuel> creer({
    required BrouillonObligationContractuel brouillon,
    required String cleIdempotence,
  });

  /// Approuve une obligation (capacite `approuver`, personne distincte de
  /// l'auteur) : le montant est fige, une obligation payable est creee.
  Future<ObligationContractuel> approuver(String obligationId);

  /// Envoie ou renvoie l'invitation securisee a un beneficiaire externe.
  Future<ObligationContractuel> inviterBeneficiaire(String obligationId);

  /// Le journal d'une obligation (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String obligationId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-08).
class ObligationsContractuelsIndisponibles
    implements PortObligationsContractuels {
  /// Cree l'implementation.
  const ObligationsContractuelsIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-08');

  @override
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  ) => Future<List<ObligationContractuel>>.error(_manque);

  @override
  Future<ObligationContractuel> detail(String obligationId) =>
      Future<ObligationContractuel>.error(_manque);

  @override
  Future<ObligationContractuel> creer({
    required BrouillonObligationContractuel brouillon,
    required String cleIdempotence,
  }) => Future<ObligationContractuel>.error(_manque);

  @override
  Future<ObligationContractuel> approuver(String obligationId) =>
      Future<ObligationContractuel>.error(_manque);

  @override
  Future<ObligationContractuel> inviterBeneficiaire(String obligationId) =>
      Future<ObligationContractuel>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal(String obligationId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`contractuels_demo.dart`).
final Provider<PortObligationsContractuels>
portObligationsContractuelsProvider = Provider<PortObligationsContractuels>(
  (Ref _) => const ObligationsContractuelsIndisponibles(),
);
