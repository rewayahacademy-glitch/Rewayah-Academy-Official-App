/// V2-e (04/11/2026) : la coche « fondateur » d'un membre du personnel.
///
/// Decision du directeur (03/11/2026, relayee par garde-cap) : « fondateur »
/// est une coche sur le profil d'un membre du personnel, tenue par la
/// direction ; elle ne sert qu'a compter les fondateurs d'un entretien
/// (reglages `entretiens.fondateurs_minimum` et
/// `entretiens.regle_fondateurs_active`). Le serveur decide de tout :
/// `poser_fondateur` (20261108000001) refuse une direction inactive et un
/// compte qui n'est pas du personnel actif.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pourquoi le serveur a refuse la coche.
enum MotifFondateurRefuse {
  /// La coche est tenue par la direction active seulement.
  nonAutorise,

  /// Seul un membre du personnel au compte actif peut etre fondateur.
  personnelInactif,

  /// Toute autre reponse : rien n'est suppose avoir change.
  inconnu,
}

/// Le refus de `poser_fondateur`.
@immutable
class FondateurRefuse implements Exception {
  /// Cree un refus.
  const FondateurRefuse(this.motif);

  /// Le motif.
  final MotifFondateurRefuse motif;

  @override
  String toString() => 'FondateurRefuse(${motif.name})';
}

/// La coche fondateur, lue et posee par la direction.
abstract interface class PortFondateurs {
  /// Les identifiants de profil des fondateurs (coche vraie).
  Future<Set<String>> lire();

  /// Coche ou decoche [profilId] ; rend la valeur posee.
  ///
  /// Leve [FondateurRefuse] quand le serveur refuse.
  Future<bool> poser(String profilId, {required bool fondateur});
}

/// Le port, `null` tant qu'aucun adaptateur n'est branche (tests, galerie).
final Provider<PortFondateurs?> portFondateursProvider =
    Provider<PortFondateurs?>((Ref _) => null);

/// Les fondateurs, ou `null` sans port.
final FutureProvider<Set<String>?> fondateursProvider =
    FutureProvider.autoDispose<Set<String>?>((Ref ref) {
      final PortFondateurs? port = ref.watch(portFondateursProvider);
      if (port == null) return Future<Set<String>?>.value();
      return port.lire();
    }, retry: (int _, Object _) => null);
