// Aujourd'hui du Comptable (FIN-CPT-W01, M01 ecran 1 ; CPT-BR-03). Pose par
// CPT-F avec son interface complete ; **propriete de la voie CPT (CPT-JOUR)
// ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Repond a « Que dois-je faire maintenant ? » : la file « A traiter » et les
// « Alertes » (une ligne n'appartient qu'a une liste, DR-10), les echeances
// datees, les encaissements recents, l'activite recente (§48), la synthese
// de tresorerie (CPT-BR-04), la Reserve en lecture (CPT-BR-12) et l'etat des
// prestataires (CPT-BR-10). Aucun montant n'est additionne ici.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Un element de la file d'Aujourd'hui : un type d'alerte, sa liste, un
/// compteur et la **route de l'ecran canonique** qui le traite (spec §5.1 :
/// un raccourci ouvre toujours l'ecran canonique, deja filtre).
@immutable
class ElementAttention {
  /// Cree l'element.
  const ElementAttention({
    required this.id,
    required this.type,
    required this.compteur,
    required this.route,
    this.liste,
    this.montant,
    this.depuis,
  });

  /// L'identifiant.
  final String id;

  /// Le type d'alerte (§28).
  final TypeAlerteComptable type;

  /// La liste rendue par la source, ou celle par defaut du type.
  final ListeAttention? liste;

  /// Le nombre d'objets concernes (« 14 enseignants a payer »).
  final int compteur;

  /// La route canonique, filtree (`Routes.comptablePaiementsFiltres(...)`).
  final String route;

  /// Le montant total concerne, quand la source le rend.
  final Montant? montant;

  /// Depuis quand l'element attend.
  final DateTime? depuis;

  /// La liste effective.
  ListeAttention get listeEffective => liste ?? type.listeParDefaut;
}

/// Une echeance datee d'Aujourd'hui (obligations, remboursements ; jamais un
/// fournisseur non specifie, DR-25).
@immutable
class EcheanceComptable {
  /// Cree l'echeance.
  const EcheanceComptable({
    required this.id,
    required this.date,
    required this.libelle,
    required this.route,
    this.montant,
    this.beneficiaire,
  });

  /// L'identifiant.
  final String id;

  /// La date.
  final DateTime date;

  /// Le libelle rendu (« Paie d'octobre », « Facture #024 »).
  final String libelle;

  /// La route de l'objet.
  final String route;

  /// Le montant, s'il est connu.
  final Montant? montant;

  /// Le beneficiaire, s'il y en a un.
  final IdentiteBeneficiaire? beneficiaire;
}

/// Un encaissement recent, resume pour Aujourd'hui.
@immutable
class EncaissementRecent {
  /// Cree le resume.
  const EncaissementRecent({
    required this.id,
    required this.date,
    required this.famille,
    required this.net,
    required this.etat,
  });

  /// L'identifiant (route `Routes.comptableEncaissementPour`).
  final String id;

  /// La date.
  final DateTime date;

  /// La famille payeuse, rendue.
  final String famille;

  /// Le net encaisse.
  final Montant net;

  /// L'etat (§24.1).
  final EtatEncaissement etat;
}

/// Tout ce que W01 affiche, rendu en une lecture.
@immutable
class AujourdhuiComptable {
  /// Cree la vue.
  const AujourdhuiComptable({
    required this.tresorerie,
    required this.reserve,
    this.file = const <ElementAttention>[],
    this.echeances = const <EcheanceComptable>[],
    this.encaissementsRecents = const <EncaissementRecent>[],
    this.activite = const <EntreeJournal>[],
    this.prestataires = const <PrestataireFinance>[],
  });

  /// La synthese de tresorerie (zone 1).
  final SyntheseTresorerie tresorerie;

  /// La Reserve strategique en lecture (zone 2).
  final IndicateursReserve reserve;

  /// La file, les deux listes melangees ; [aTraiter] et [alertes] la trient.
  final List<ElementAttention> file;

  /// Les echeances proches.
  final List<EcheanceComptable> echeances;

  /// Les encaissements recents.
  final List<EncaissementRecent> encaissementsRecents;

  /// L'activite recente (§48).
  final List<EntreeJournal> activite;

  /// L'etat des prestataires (§42).
  final List<PrestataireFinance> prestataires;

  /// Les elements « A traiter ».
  List<ElementAttention> get aTraiter => file
      .where(
        (ElementAttention e) => e.listeEffective == ListeAttention.aTraiter,
      )
      .toList();

  /// Les « Alertes ».
  List<ElementAttention> get alertes => file
      .where((ElementAttention e) => e.listeEffective == ListeAttention.alerte)
      .toList();

  /// Les elements « A traiter » qui sont des paiements a effectuer (zone 6
  /// de §29 sur bureau) : enseignants a payer, contractuels a echeance.
  /// Sur bureau, ils vivent dans « Paiements a effectuer » et nulle part
  /// ailleurs (DR-10 : un probleme, un endroit) ; sur telephone et dans la
  /// file complete, ils restent en tete de « A traiter ».
  List<ElementAttention> get paiementsAEffectuer =>
      aTraiter.where((ElementAttention e) => e.type.estPaiement).toList();

  /// Les elements « A traiter » hors paiements a effectuer (zone 3 sur
  /// bureau) : relancer, rapprocher, valider, reprendre un echec.
  List<ElementAttention> get aTraiterHorsPaiements =>
      aTraiter.where((ElementAttention e) => !e.type.estPaiement).toList();

  /// Vrai quand rien n'attend le Comptable : aucune file, aucune echeance,
  /// aucun encaissement ni activite recente. La tresorerie et la Reserve
  /// restent affichees : un jour calme n'est pas un ecran vide de chiffres.
  bool get estCalme =>
      file.isEmpty &&
      echeances.isEmpty &&
      encaissementsRecents.isEmpty &&
      activite.isEmpty;
}

/// Les familles de paiements a effectuer parmi les types d'alerte (§28).
extension TypeAlertePaiement on TypeAlerteComptable {
  /// Vrai pour « Enseignants a payer » et « Contractuels a echeance ».
  bool get estPaiement =>
      this == TypeAlerteComptable.enseignantsAPayer ||
      this == TypeAlerteComptable.contractuelsAEcheance;
}

/// Aujourd'hui du Comptable (CPT-BR-03).
abstract interface class PortAujourdhuiComptable {
  /// La vue du jour.
  Future<AujourdhuiComptable> aujourdhui();

  /// Le journal d'un objet (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String objetId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-03).
class AujourdhuiComptableIndisponible implements PortAujourdhuiComptable {
  /// Cree l'implementation.
  const AujourdhuiComptableIndisponible();

  @override
  Future<AujourdhuiComptable> aujourdhui() => Future<AujourdhuiComptable>.error(
    const CapaciteIndisponible('CPT-BR-03'),
  );

  @override
  Future<List<EntreeJournal>> journal(String objetId) =>
      Future<List<EntreeJournal>>.error(
        const CapaciteIndisponible('CPT-BR-03'),
      );
}

/// Le port ; la demonstration le surcharge (`aujourdhui_demo.dart`).
final Provider<PortAujourdhuiComptable> portAujourdhuiComptableProvider =
    Provider<PortAujourdhuiComptable>(
      (Ref _) => const AujourdhuiComptableIndisponible(),
    );
