// Les finances de l'eleve adulte autonome (FI-9b, guide Finance V4 §4
// « Eleve adulte » ; FI-BR-17) : les memes donnees que FI-BR-03 et
// FI-BR-05, pour SON SEUL profil.
//
// Pourquoi un port a part plutot qu'un filtre a l'ecran : `PortPaiementsFoyer`
// rend le foyer entier (`finances()`), pour le titulaire. Filtrer a l'ecran
// chargerait quand meme les soldes et les prenoms des autres membres sur
// l'appareil de l'adulte. Ici, le perimetre est celui de la session : le
// serveur ne rend que le profil de la personne connectee, et l'ecran n'a
// aucun identifiant a fournir (donc aucun a falsifier). La recharge reste le
// moteur unique (`PortRechargeFoyer`), dont la source rend, pour l'adulte
// autonome, son seul profil comme beneficiaire (FI-BR-17).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finances_profil.dart';
import '../finance/mouvements_profil.dart';
import 'capacite_indisponible.dart';

/// Les finances de la personne connectee, eleve adulte autonome.
abstract interface class PortMesFinances {
  /// La finance du seul profil eleve de la personne connectee (solde,
  /// periode financee, prochain debit, mensualite et ses lignes rendues,
  /// etat), `null` quand aucune n'est encore rendue (pas encore inscrit).
  Future<FinancesProfil?> finances();

  /// Les mouvements de ce seul profil, le plus recent d'abord (FI-BR-05) :
  /// historique en ajout seul, aucune ecriture exposee.
  Future<List<MouvementProfil>> mouvements();
}

/// **Aucune source serveur a ce jour** (FI-BR-17).
class MesFinancesIndisponible implements PortMesFinances {
  /// Cree l'implementation.
  const MesFinancesIndisponible();

  @override
  Future<FinancesProfil?> finances() =>
      Future<FinancesProfil?>.error(const CapaciteIndisponible('FI-BR-17'));

  @override
  Future<List<MouvementProfil>> mouvements() =>
      Future<List<MouvementProfil>>.error(
        const CapaciteIndisponible('FI-BR-17'),
      );
}

/// Le port employe par l'application ; la demonstration le surcharge.
final Provider<PortMesFinances> portMesFinancesProvider =
    Provider<PortMesFinances>((Ref _) => const MesFinancesIndisponible());

/// Mes finances, relues a chaque ouverture : `autoDispose`, la lecture est
/// liberee des que plus aucun ecran ne la regarde (revue FI-VAGUE-R R4-05),
/// et un retour de recharge relit donc le solde au lieu de montrer l'ancien.
final FutureProvider<FinancesProfil?> mesFinancesProvider =
    FutureProvider.autoDispose<FinancesProfil?>(
      (Ref ref) => ref.watch(portMesFinancesProvider).finances(),
    );

/// Mes mouvements, relus a chaque ouverture (`autoDispose`, comme
/// [mesFinancesProvider]).
final FutureProvider<List<MouvementProfil>> mesMouvementsProvider =
    FutureProvider.autoDispose<List<MouvementProfil>>(
      (Ref ref) => ref.watch(portMesFinancesProvider).mouvements(),
    );
