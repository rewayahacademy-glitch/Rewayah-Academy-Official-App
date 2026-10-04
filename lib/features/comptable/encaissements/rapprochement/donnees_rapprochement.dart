// Les lectures de l'espace de rapprochement et des remboursements (spec §25,
// §26, §48 ; CPT-BR-14, 15, 17). Les filtres comptent des lignes, jamais un
// montant (FI6).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../../../core/capacites/port_encaissements.dart';
import '../../../../core/capacites/port_rapprochement.dart';
import '../../../../core/comptable/modeles_comptable.dart';
import '../../../../core/i18n/strings.g.dart';

/// Les elements a rapprocher, tous etats, lus une fois ; le filtre d'etat
/// s'applique a l'affichage. `retry` nul : aucune relance silencieuse.
final FutureProvider<List<ElementRapprochement>> elementsRapprochementProvider =
    FutureProvider<List<ElementRapprochement>>(
      (Ref ref) => ref
          .watch(portRapprochementProvider)
          .aRapprocher(FiltreRapprochement.tout),
      retry: (int _, Object _) => null,
    );

/// Les correspondances proposees par la source pour une transaction.
final FutureProviderFamily<PropositionRapprochement, String>
propositionRapprochementProvider =
    FutureProvider.family<PropositionRapprochement, String>(
      (Ref ref, String id) => ref.watch(portRapprochementProvider).proposer(id),
      retry: (int _, Object _) => null,
    );

/// Le journal d'un element du rapprochement (§48, CPT-BR-17).
final FutureProviderFamily<List<EntreeJournal>, String>
journalRapprochementProvider =
    FutureProvider.family<List<EntreeJournal>, String>(
      (Ref ref, String id) => ref.watch(portRapprochementProvider).journal(id),
      retry: (int _, Object _) => null,
    );

/// Les remboursements et avoirs (§26, CPT-BR-15).
final FutureProvider<List<Remboursement>> remboursementsProvider =
    FutureProvider<List<Remboursement>>(
      (Ref ref) => ref
          .watch(portEncaissementsProvider)
          .remboursements(FiltreRemboursements.tout),
      retry: (int _, Object _) => null,
    );

/// Le libelle d'une nature d'element (§25).
String libelleNatureRapprochement(NatureElementRapprochement n) {
  final r = t.comptable.encaissements.rap;
  return switch (n) {
    NatureElementRapprochement.paiementAttendu => r.natPaiementAttendu,
    NatureElementRapprochement.transactionPrestataire => r.natTransaction,
    NatureElementRapprochement.mensualite => r.natMensualite,
    NatureElementRapprochement.frais => r.natFrais,
    NatureElementRapprochement.remboursement => r.natRemboursement,
    NatureElementRapprochement.payout => r.natPayout,
    NatureElementRapprochement.preuve => r.natPreuve,
  };
}
