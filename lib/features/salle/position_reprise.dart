// CAHIER-C1 (06/11/2026, ETUDE-CAHIER-2026-11.md §5) : la position de reprise
// d'une Classe, tenue par le serveur.
//
// La salle enregistre la derniere page du Coran presentee, par Classe
// (`enregistrer_page_presentee`, migration 20261110100000) ; la preparation
// de seance la relit, sur tout appareil, pour le titulaire comme pour le
// remplacant (« On reprend page 14 »). Le serveur decide qui ecrit et qui
// lit ; rien n'est deduit ici.
//
// Sans branchement (tests, demonstration), le port ne lit rien et n'ecrit
// rien : la preparation reste vide, jamais supposee.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// La position de reprise d'une Classe, cote serveur.
abstract interface class PortPositionReprise {
  /// La derniere page presentee dans la Classe [groupeId], ou `null`.
  Future<int?> pageDeLaClasse(String groupeId);

  /// La derniere page presentee dans la Classe de la seance [sessionId], ou
  /// `null`. Sert la preparation d'entree dans la salle, remplacant compris.
  Future<int?> pageDeLaSeance(String sessionId);

  /// Retient [page] pour la Classe de la seance [sessionId].
  Future<void> enregistrer({required String sessionId, required int page});
}

/// Le port sans serveur : rien a lire, rien a ecrire.
class PositionRepriseAbsente implements PortPositionReprise {
  /// Cree le port.
  const PositionRepriseAbsente();

  @override
  Future<int?> pageDeLaClasse(String groupeId) async => null;

  @override
  Future<int?> pageDeLaSeance(String sessionId) async => null;

  @override
  Future<void> enregistrer({
    required String sessionId,
    required int page,
  }) async {}
}

/// Le port employe. L'application reelle le surcharge par l'adaptateur
/// Supabase (`main.dart`).
final Provider<PortPositionReprise> portPositionRepriseProvider =
    Provider<PortPositionReprise>((Ref _) => const PositionRepriseAbsente());

/// La page de reprise d'une Classe, par `groupeId`. `null` en lecture, en
/// echec ou sans page : rien n'est affiche plutot qu'une page supposee.
final FutureProviderFamily<int?, String> pageRepriseClasseProvider =
    FutureProvider.family<int?, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portPositionRepriseProvider).pageDeLaClasse(groupeId),
      retry: (int _, Object _) => null,
    );

/// La page de reprise de la Classe d'une seance, par `sessionId`.
final FutureProviderFamily<int?, String> pageRepriseSeanceProvider =
    FutureProvider.family<int?, String>(
      (Ref ref, String sessionId) =>
          ref.watch(portPositionRepriseProvider).pageDeLaSeance(sessionId),
      retry: (int _, Object _) => null,
    );
