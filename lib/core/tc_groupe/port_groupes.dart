import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` : meme convention que `service_planning.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import 'demonstration_groupes.dart';
import 'group_summary_vm.dart';

/// L'acces aux groupes visibles par l'appelant.
///
/// **Deux methodes, pas trois.** La composition de l'Espace Groupe par role est
/// un calcul (`GroupHomeVM.pourRole`), pas une lecture : lui donner une methode
/// de port ferait croire a un aller-retour serveur qui n'existe pas.
///
/// Le filtrage par role est **serveur**, jamais ici : `mesGroupes()` rend ce que
/// l'appelant a le droit de voir. Aujourd'hui, la seule lecture de groupes du
/// depot est `groupes_admin()`, **reservee a l'administration** et qui ne rend
/// ni le fuseau, ni la prochaine occurrence. Une variante par role est demandee
/// en section 2 de `docs/teaching-core/TC_CONTRACT_REQUEST_A.md`.
abstract class PortGroupes {
  /// Les groupes visibles par l'appelant, selon son role serveur.
  Future<List<GroupSummaryVM>> mesGroupes();

  /// Un groupe precis, ou `null` s'il n'est pas visible par l'appelant.
  Future<GroupSummaryVM?> groupe(String groupeId);
}

/// Le port des groupes employe par l'application.
///
/// Il suit le patron des trente et un services du depot : interface,
/// implementation et provider dans le meme voisinage, sans racine d'injection.
///
/// **Le defaut est un double de demonstration**, parce qu'aucune lecture
/// serveur ne peut alimenter cette vue aujourd'hui. Agent Z le remplace par
/// l'adaptateur reel quand les sections 1 a 6 de `TC_CONTRACT_REQUEST_A.md`
/// sont livrees.
final Provider<PortGroupes> portGroupesProvider = Provider<PortGroupes>(
  (Ref ref) => GroupesDemonstrationLocale(),
);

/// Les groupes de l'appelant.
final FutureProvider<List<GroupSummaryVM>> mesGroupesProvider =
    FutureProvider<List<GroupSummaryVM>>(
      (Ref ref) => ref.watch(portGroupesProvider).mesGroupes(),
    );

/// Un groupe donne.
final FutureProviderFamily<GroupSummaryVM?, String> groupeProvider =
    FutureProvider.family<GroupSummaryVM?, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portGroupesProvider).groupe(groupeId),
    );
