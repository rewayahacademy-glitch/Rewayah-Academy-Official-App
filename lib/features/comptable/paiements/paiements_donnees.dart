// Les lectures et les regles d'affichage des paiements a effectuer (W02,
// W03 ; CPT-PAY-1). Rien ici ne calcule un montant ni ne lit un role :
// chaque decision vient de l'etat et des permissions rendus par la source
// (`PortObligationsPayables`, CPT-BR-01 ; DR-19).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderOrFamily;

import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';

/// La liste W02 pour un filtre. Relue par `invalidate` apres un paiement ou
/// un recalcul (R-FIN-18).
final FutureProviderFamily<List<ObligationPayable>, FiltreObligations>
obligationsPayablesProvider = FutureProvider.autoDispose
    .family<List<ObligationPayable>, FiltreObligations>(
      (Ref ref, FiltreObligations filtre) =>
          ref.watch(portObligationsPayablesProvider).liste(filtre),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portObligationsPayablesProvider],
    );

/// Le detail W03 d'une obligation.
final FutureProviderFamily<ObligationPayable, String>
obligationPayableProvider = FutureProvider.autoDispose
    .family<ObligationPayable, String>(
      (Ref ref, String id) =>
          ref.watch(portObligationsPayablesProvider).detail(id),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portObligationsPayablesProvider],
    );

/// Le journal d'une obligation (§48).
final FutureProviderFamily<List<EntreeJournal>, String>
journalObligationProvider = FutureProvider.autoDispose
    .family<List<EntreeJournal>, String>(
      (Ref ref, String id) =>
          ref.watch(portObligationsPayablesProvider).journal(id),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portObligationsPayablesProvider],
    );

// Chaque lecture declare le port dont elle depend : une demonstration qui
// surcharge le port dans une `ProviderScope` imbriquee (la coquille de
// `/demo/comptable`) est alors lue dans cette portee, pas a la racine.

/// Aucune retentative automatique : « Reessayer » est la seule relance, et
/// une capacite absente ne revient pas en insistant (`BlocAsynchrone`).
Duration? _sansRetentative(int essai, Object erreur) => null;

/// Le filtre d'etat lu dans l'adresse (`?filtre=`), ou `null` s'il est
/// absent ou inconnu : une valeur inconnue ne filtre rien plutot que de
/// vider la liste sans explication.
FiltrePaiements? filtrePaiementsDe(String? brut) =>
    _lire(FiltrePaiements.values, brut);

/// Le type de beneficiaire lu dans l'adresse (`?type=`).
TypeBeneficiaire? typeBeneficiaireDe(String? brut) =>
    _lire(TypeBeneficiaire.values, brut);

/// La Classe lue dans l'adresse (`?classe=`), vide = aucune.
String? classeDe(String? brut) =>
    brut == null || brut.trim().isEmpty ? null : brut.trim();

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// Le libelle d'un filtre d'etat.
String libelleFiltrePaiements(FiltrePaiements filtre) {
  final f = t.comptable.paiements.filtres;
  return switch (filtre) {
    FiltrePaiements.prets => f.prets,
    FiltrePaiements.infos => f.infos,
    FiltrePaiements.verification => f.verification,
    FiltrePaiements.validation => f.validation,
    FiltrePaiements.retard => f.retard,
  };
}

/// Le libelle d'un type de beneficiaire.
String libelleTypeBeneficiaire(TypeBeneficiaire type) => switch (type) {
  TypeBeneficiaire.enseignant => t.comptable.paiements.types.enseignant,
  TypeBeneficiaire.contractuel => t.comptable.paiements.types.contractuel,
};

/// Les etats ou un paiement est deja parti ou termine : la ligne se suit,
/// elle ne se choisit plus.
const Set<EtatPaiementSortant> etatsPartis = <EtatPaiementSortant>{
  EtatPaiementSortant.soumis,
  EtatPaiementSortant.enTransit,
  EtatPaiementSortant.reussi,
  EtatPaiementSortant.annule,
  EtatPaiementSortant.retourne,
};

/// Ce que la ligne propose, decide par la source (§30 : voir, payer,
/// relancer). L'ecran ne deduit rien : il lit `permissions`.
enum ActionLigne {
  /// La source permet le paiement.
  payer,

  /// Paiement sensible : la source permet seulement d'en demander la
  /// validation (§21.4, §40).
  demanderValidation,

  /// Infos de paiement manquantes : la relance vit sur le profil du
  /// beneficiaire (W07, « une fonction = un endroit », §5.1).
  relancer,

  /// Rien a faire ici : on ouvre le detail.
  voir,
}

/// L'action d'une ligne, lue dans ses permissions.
ActionLigne actionDe(ObligationPayable o) {
  final PermissionsFinance p = o.permissions;
  if (p.permet(ActionFinance.payer)) return ActionLigne.payer;
  if (p.permet(ActionFinance.demanderValidation)) {
    return ActionLigne.demanderValidation;
  }
  if (p.permet(ActionFinance.relancer)) return ActionLigne.relancer;
  return ActionLigne.voir;
}

/// La raison rendue pour laquelle « Payer » est absent, ou `null`.
RaisonBlocage? raisonSansPaiement(ObligationPayable o) =>
    o.permissions.permet(ActionFinance.payer)
    ? null
    : o.permissions.raisonDe(ActionFinance.payer);

/// Vrai quand la case de la ligne est proposee : un paiement pas encore
/// parti, que la source ne reserve pas a un autre responsable (R-FIN-15).
/// Une ligne non prete peut etre choisie : le preflight l'exclura en disant
/// pourquoi (§41) ; elle ne partira jamais avec le lot (R-FIN-23).
bool estSelectionnable(ObligationPayable o) =>
    !etatsPartis.contains(o.etat) &&
    raisonSansPaiement(o) != RaisonBlocage.autoPaiement;

/// Vrai quand la ligne entre dans « Selectionner tous les paiements prets »
/// (§14.3) : pret a payer **et** payable selon la source.
bool estPrete(ObligationPayable o) =>
    o.etat == EtatPaiementSortant.pretAPayer &&
    o.permissions.permet(ActionFinance.payer);
