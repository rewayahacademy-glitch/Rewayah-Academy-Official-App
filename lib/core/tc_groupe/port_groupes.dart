import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` : meme convention que `service_planning.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'demonstration_groupes.dart';
import 'group_summary_vm.dart';
import 'groupes_supabase.dart';

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
/// en section 2 de `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md`.
abstract class PortGroupes {
  /// Les groupes visibles par l'appelant, selon son role serveur.
  Future<List<GroupSummaryVM>> mesGroupes();

  /// Un groupe precis, ou `null` s'il n'est pas visible par l'appelant.
  Future<GroupSummaryVM?> groupe(String groupeId);
}

/// Choisit le port selon le mode de compilation.
///
/// **En production, la source est strictement reelle** (`mes_groupes_famille_v`
/// par [GroupesSupabase]). Le double de demonstration ne sort que sous
/// `PLAYGROUND=true`, que `flutter-deploy.yml` force a `false`. Avant le
/// 23 septembre 2026, le double etait le defaut pour tout le monde et un tuteur
/// en production voyait six groupes fictifs (decision V0 de
/// `docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`).
PortGroupes portGroupesSelon({required bool demo}) => demo
    ? GroupesDemonstrationLocale()
    : GroupesSupabase(Supabase.instance.client);

/// Le port des groupes employe par l'application.
///
/// Il suit le patron des trente et un services du depot : interface,
/// implementation et provider dans le meme voisinage, sans racine d'injection.
final Provider<PortGroupes> portGroupesProvider = Provider<PortGroupes>(
  (Ref ref) => portGroupesSelon(demo: Env.playgroundActif),
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
