import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L'etat du reseau, tel que les ecrans le lisent.
///
/// **Une seule source pour tout le produit.** Le bandeau `OfflineBanner` et le
/// bloc « Rejoindre » de `ELV-02` parlent du meme fait : si chacun interrogeait
/// la plateforme de son cote, l'ecran pourrait afficher un bandeau « pas de
/// reseau » au-dessus d'un bouton d'entree en seance encore actif, ou l'inverse.
/// C'est la meme raison qui fait de `mes_seances_v` une vue unique pour les
/// trois roles.
///
/// La forme est celle des autres services du projet : une interface abstraite,
/// une implementation reelle, un faux en memoire pour les tests. Sans elle, le
/// sixieme etat de `ELV-02`, le hors ligne, ne serait pas mesurable : aucun test
/// ne peut couper le reseau d'une machine de CI.
abstract interface class ServiceReseau {
  /// Vrai quand l'appareil n'a aucune connexion.
  ///
  /// Le flux emet l'etat courant a l'abonnement, puis a chaque changement : un
  /// ecran monte hors ligne doit se rendre hors ligne du premier coup, pas au
  /// premier basculement.
  Stream<bool> horsLigne();
}

/// L'implementation reelle, sur `connectivity_plus`.
class ServiceReseauConnectivity implements ServiceReseau {
  /// Cree le service.
  const ServiceReseauConnectivity();

  @override
  Stream<bool> horsLigne() async* {
    final Connectivity connectivite = Connectivity();
    yield _horsLigne(await connectivite.checkConnectivity());
    yield* connectivite.onConnectivityChanged.map(_horsLigne);
  }
}

/// Le service de reseau employe par l'application.
final Provider<ServiceReseau> serviceReseauProvider = Provider<ServiceReseau>(
  (Ref ref) => const ServiceReseauConnectivity(),
);

/// Vrai quand l'appareil est hors ligne.
///
/// A lire par `hasValue` et `value`, jamais par le type d'execution de
/// l'`AsyncValue` : Riverpod 3 relance un provider en echec tout seul et l'etat
/// repasse par `AsyncLoading` en conservant `hasError`. Tant que la reponse
/// n'est pas connue, l'appareil est repute **en ligne** : afficher « pas de
/// reseau » pendant la premiere frame ferait clignoter chaque ecran au
/// demarrage.
final StreamProvider<bool> horsLigneProvider = StreamProvider<bool>(
  (Ref ref) => ref.watch(serviceReseauProvider).horsLigne(),
);

/// Ce que la plateforme rend, traduit en un seul fait.
///
/// Une liste vide vaut « aucune interface », au meme titre qu'une liste qui ne
/// contient que [ConnectivityResult.none].
bool _horsLigne(List<ConnectivityResult> resultats) =>
    resultats.isEmpty ||
    resultats.every((ConnectivityResult r) => r == ConnectivityResult.none);
