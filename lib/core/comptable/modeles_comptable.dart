// Les valeurs que plusieurs voies du Comptable V1 lisent (CPT-F) : identite
// d'un beneficiaire, destination masquee, synthese de tresorerie, indicateurs
// de la Reserve, entree de journal, prestataire, permissions d'un objet.
//
// **Fichier gele apres CPT-F** (ajout a la liste A de
// `20_comptable/02_DECOUPAGE.md`, motive dans le compte rendu de CPT-F) : un
// type lu par deux voies ne vit dans le port d'aucune des deux, sinon la
// premiere qui le retouche casse l'autre. Les types propres a une voie
// restent dans son port.
//
// Tout montant est un `Montant` (entier en unites mineures, ISO 4217) rendu
// par la source : Flutter n'additionne ni ne convertit rien (FI6). Les
// agregats (fonds proteges, tresorerie libre, part en pour mille) arrivent
// calcules.

import 'package:flutter/foundation.dart';

import '../finance/montant.dart';
import 'statuts_comptable.dart';

/// L'identite d'un beneficiaire de paiement, telle que la source la rend.
@immutable
class IdentiteBeneficiaire {
  /// Cree l'identite.
  const IdentiteBeneficiaire({
    required this.id,
    required this.nom,
    required this.type,
    this.lieALOperateur = false,
    this.estMoi = false,
  });

  /// L'identifiant stable du beneficiaire.
  final String id;

  /// Le nom affiche (« Sayyid Youssouf Diallo », « Karim Studio »).
  final String nom;

  /// Enseignant ou contractuel.
  final TypeBeneficiaire type;

  /// Vrai quand le beneficiaire est lie a l'operateur : paiement sensible
  /// (§21.4).
  final bool lieALOperateur;

  /// Vrai quand le beneficiaire est la personne connectee : « Payer » absent,
  /// « Traitement par un autre responsable requis » (§20). Rendu par la
  /// source, jamais compare a un identifiant local.
  final bool estMoi;
}

/// Une destination de paiement **masquee par la source** (spec §16.3) :
/// « Orange Money •••• 4423 ». L'app ne recoit ni ne conserve jamais une
/// coordonnee complete (`CPT-BR.md` §1).
@immutable
class DestinationMasquee {
  /// Cree la destination.
  const DestinationMasquee({
    required this.type,
    required this.suffixe,
    required this.pays,
    required this.devise,
    required this.verification,
    this.operateur,
    this.derniereModification,
  });

  /// Le type lisible (« Orange Money », « Compte bancaire », « Wave »).
  final String type;

  /// L'operateur ou la banque, quand il differe du type.
  final String? operateur;

  /// Les derniers caracteres visibles, **rendus masques par la source**
  /// (« 4423 ») : l'app n'a jamais vu le reste.
  final String suffixe;

  /// Le pays (code ou nom rendu).
  final String pays;

  /// La devise ISO 4217 de la destination.
  final String devise;

  /// L'etat de verification de la methode (§19).
  final EtatProfilPaiement verification;

  /// La date de derniere modification, quand la source la rend : une
  /// modification recente rend le paiement sensible (§21.4).
  final DateTime? derniereModification;
}

/// Ce qu'une source permet sur un objet et pourquoi le reste est bloque.
@immutable
class PermissionsFinance {
  /// Cree les permissions.
  const PermissionsFinance({
    this.actions = const <ActionFinance>{},
    this.blocages = const <ActionFinance, RaisonBlocage>{},
  });

  /// Aucune action permise, aucune raison : l'objet se lit seulement.
  static const PermissionsFinance lectureSeule = PermissionsFinance();

  /// Les actions permises.
  final Set<ActionFinance> actions;

  /// Pour chaque action attendue mais absente, la raison rendue (DR-19).
  final Map<ActionFinance, RaisonBlocage> blocages;

  /// Vrai si [action] est permise.
  bool permet(ActionFinance action) => actions.contains(action);

  /// La raison du blocage de [action], ou `null` si elle est permise ou
  /// simplement absente.
  RaisonBlocage? raisonDe(ActionFinance action) => blocages[action];
}

/// Le solde d'un coffre (spec §8.1), avec sa part rendue en pour mille.
@immutable
class SoldeCoffre {
  /// Cree le solde.
  const SoldeCoffre({
    required this.coffre,
    required this.montant,
    this.partPourMille,
    this.regleUsage,
  });

  /// Le coffre.
  final Coffre coffre;

  /// Son montant.
  final Montant montant;

  /// Sa part de la tresorerie detenue, en pour mille, rendue par la source
  /// (jamais calculee ici, DR-08).
  final int? partPourMille;

  /// La regle d'usage lisible, quand la source en rend une.
  final String? regleUsage;
}

/// La synthese de tresorerie (`AvailableTreasurySummary`, spec §11, §12.1) :
/// la Tresorerie libre est le chiffre central, jamais le solde brut.
@immutable
class SyntheseTresorerie {
  /// Cree la synthese.
  const SyntheseTresorerie({
    required this.detenue,
    required this.libre,
    required this.protegee,
    required this.enTransit,
  });

  /// La tresorerie detenue (solde brut : jamais presentee comme depensable).
  final Montant detenue;

  /// La tresorerie reellement libre (§11).
  final Montant libre;

  /// Les fonds proteges (somme des coffres proteges, rendue par la source).
  final Montant protegee;

  /// L'argent en transit.
  final Montant enTransit;
}

/// Le mode d'objectif de la Reserve strategique (spec §9.2).
enum ModeObjectifReserve {
  /// Mode A : montant cible fixe (10 USD comme 1 000 000 USD).
  montantFixe,

  /// Mode B : couverture en N mois de charges essentielles.
  couvertureMois,
}

/// Les indicateurs de la Reserve strategique (spec §9.7), rendus par la
/// source. Le titre reste toujours « Reserve strategique » (§9.1).
@immutable
class IndicateursReserve {
  /// Cree les indicateurs.
  const IndicateursReserve({
    required this.mode,
    required this.objectif,
    required this.actuel,
    required this.manque,
    required this.atteintPourMille,
    required this.etat,
    this.nombreMois,
    this.derniereAllocation,
    this.prochaineAllocation,
  });

  /// Le mode de calcul de l'objectif.
  final ModeObjectifReserve mode;

  /// Le nombre de mois de couverture, en mode [ModeObjectifReserve.couvertureMois].
  final int? nombreMois;

  /// L'objectif en montant (rendu par la source dans les deux modes).
  final Montant objectif;

  /// Le montant actuel du coffre.
  final Montant actuel;

  /// Le manque a completer (nul ou negatif quand l'objectif est depasse).
  final Montant manque;

  /// Le pourcentage atteint, en pour mille, rendu par la source.
  final int atteintPourMille;

  /// Le statut.
  final EtatReserve etat;

  /// La date de la derniere allocation.
  final DateTime? derniereAllocation;

  /// La prochaine allocation prevue.
  final DateTime? prochaineAllocation;
}

/// Un prestataire de paiement reellement active (spec §42 ; CPT-BR-10). Nom
/// neutre, jamais un logo (DR-21).
@immutable
class PrestataireFinance {
  /// Cree le prestataire.
  const PrestataireFinance({
    required this.id,
    required this.nom,
    required this.capacite,
    this.solde,
  });

  /// L'identifiant.
  final String id;

  /// Le nom rendu.
  final String nom;

  /// Son etat du moment.
  final CapacitePayout capacite;

  /// Son solde, quand la source le rend.
  final Montant? solde;
}

/// Une entree du journal d'une operation (spec §48 ; CPT-BR-17). Le
/// frontend n'invente aucun audit : chaque champ vient de la source.
@immutable
class EntreeJournal {
  /// Cree l'entree.
  const EntreeJournal({
    required this.id,
    required this.date,
    required this.initiateur,
    required this.objet,
    this.source,
    this.ancienEtat,
    this.nouvelEtat,
    this.montant,
    this.preuve,
    this.prestataire,
    this.reference,
  });

  /// L'identifiant.
  final String id;

  /// La date.
  final DateTime date;

  /// Qui a agi (nom rendu, « la direction », jamais « admin », K-53.6).
  final String initiateur;

  /// L'objet concerne, lisible.
  final String objet;

  /// La source de l'operation.
  final String? source;

  /// L'etat avant, lisible.
  final String? ancienEtat;

  /// L'etat apres, lisible.
  final String? nouvelEtat;

  /// Le montant, s'il y en a un (masquable).
  final Montant? montant;

  /// La preuve, quand il y en a une (reference rendue).
  final String? preuve;

  /// Le prestataire, quand il y en a un.
  final String? prestataire;

  /// La reference.
  final String? reference;
}

/// Une ligne de calcul d'une obligation (spec §13.3, §23) : « Classe
/// Al-Fajr 100 USD », chacune avec sa source.
@immutable
class LigneCalcul {
  /// Cree la ligne.
  const LigneCalcul({
    required this.id,
    required this.libelle,
    required this.montant,
    required this.source,
    this.auteur,
    this.validation,
    this.date,
    this.route,
  });

  /// L'identifiant de la ligne (pour « Signaler un ecart »).
  final String id;

  /// Le libelle (« Classe Al-Fajr », « Remplacement », « Bonus Internet »).
  final String libelle;

  /// Le montant, signe pour un ajustement negatif.
  final Montant montant;

  /// La source lisible.
  final String source;

  /// L'auteur d'un ajustement ou d'un bonus (§23).
  final String? auteur;

  /// La validation d'un ajustement, lisible.
  final String? validation;

  /// La date de la ligne.
  final DateTime? date;

  /// La route de la source quand elle en a une dans l'application.
  final String? route;
}
