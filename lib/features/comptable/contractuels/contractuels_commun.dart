// Ce que les trois ecrans de W06 partagent (CPT-CTR-1) : les lectures du port
// (CPT-BR-08), les onglets internes et leur filtre, la lecture d'un montant
// saisi. **Propriete de la voie CPT-CTR** (`lib/features/comptable/
// contractuels/**`).
//
// Aucun role n'est lu ici : ce qui se montre vient de `permissions` rendues
// par la source (DR-19). Aucun montant n'est calcule : un montant saisi
// devient un entier en unites mineures, sans `double` (FI6).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderOrFamily;

import '../../../core/capacites/port_obligations_contractuels.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/format_montant.dart';

/// Les quatre zones de W06 (spec §34), dans l'ordre d'affichage.
enum OngletContractuels {
  /// Les obligations en cours.
  obligations('obligations'),

  /// Celles qui attendent une approbation.
  aApprouver('a-approuver'),

  /// Celles qui sont approuvees : le montant est fige, « Payer » ouvre W03.
  aPayer('a-payer'),

  /// Les obligations terminees (payees, refusees, annulees).
  historique('historique');

  const OngletContractuels(this.parametre);

  /// La valeur de `?onglet=`.
  final String parametre;

  /// L'onglet demande par l'adresse ; un valeur inconnue ou absente ouvre
  /// « Obligations ».
  static OngletContractuels depuis(String? brut) {
    for (final OngletContractuels o in values) {
      if (o.parametre == brut) return o;
    }
    return obligations;
  }

  /// Vrai quand [o] appartient a cette zone.
  bool contient(ObligationContractuel o) => switch (this) {
    obligations =>
      o.etat == EtatObligationContractuel.brouillon ||
          o.etat == EtatObligationContractuel.aApprouver ||
          o.etat == EtatObligationContractuel.approuvee,
    aApprouver => o.etat == EtatObligationContractuel.aApprouver,
    aPayer => o.etat == EtatObligationContractuel.approuvee,
    historique =>
      o.etat == EtatObligationContractuel.payee ||
          o.etat == EtatObligationContractuel.refusee ||
          o.etat == EtatObligationContractuel.annulee,
  };
}

/// Les obligations de contractuels, toutes. Aucune relance automatique : un
/// echec se relit par « Reessayer », geste de la personne.
final FutureProvider<List<ObligationContractuel>>
obligationsContractuelsProvider =
    FutureProvider.autoDispose<List<ObligationContractuel>>(
      (Ref ref) => ref
          .watch(portObligationsContractuelsProvider)
          .liste(FiltreObligationsContractuels.tout),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portObligationsContractuelsProvider],
    );

/// Ce dont part le formulaire, et si le compte peut creer (§34).
final FutureProvider<ContexteCreationObligation>
contexteCreationObligationProvider =
    FutureProvider.autoDispose<ContexteCreationObligation>(
      (Ref ref) =>
          ref.watch(portObligationsContractuelsProvider).contexteCreation(),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portObligationsContractuelsProvider],
    );

/// Le detail d'une obligation.
final FutureProviderFamily<ObligationContractuel, String>
obligationContractuelProvider = FutureProvider.autoDispose
    .family<ObligationContractuel, String>(
      (Ref ref, String id) =>
          ref.watch(portObligationsContractuelsProvider).detail(id),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portObligationsContractuelsProvider],
    );

/// Le journal d'une obligation (CPT-BR-17).
final FutureProviderFamily<List<EntreeJournal>, String>
journalObligationContractuelProvider = FutureProvider.autoDispose
    .family<List<EntreeJournal>, String>(
      (Ref ref, String id) =>
          ref.watch(portObligationsContractuelsProvider).journal(id),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portObligationsContractuelsProvider],
    );

/// Lit un montant saisi (« 350 », « 350,50 », « 1 250.5 ») en unites
/// mineures de [devise], sans `double`. Nul si la saisie n'est pas un nombre
/// strictement positif a au plus autant de decimales que la devise.
int? lireMontantSaisi(String saisie, String devise) {
  final int decimales = decimalesDe(devise);
  final String propre = saisie
      .replaceAll(RegExp(r'[\s  ]'), '')
      .replaceAll(',', '.');
  final RegExpMatch? m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(propre);
  if (m == null) return null;
  final String entier = m.group(1)!;
  final String fraction = m.group(2) ?? '';
  if (fraction.length > decimales) return null;
  final String complet = '$entier${fraction.padRight(decimales, '0')}';
  final int? mineur = int.tryParse(complet);
  if (mineur == null || mineur <= 0) return null;
  return mineur;
}
