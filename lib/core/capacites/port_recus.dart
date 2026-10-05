// Le recu d'un paiement, a telecharger depuis la fiche Finances d'un profil
// (FI-6a, guide Finance V4 §5.2, maquette 06 ; FI-BR-05).
//
// « Télécharger le reçu » est montre avant que le serveur produise les recus,
// sur un etat honnete (FI-Q7 (a), decide par delegation le 05/10) : la
// production ET la demonstration rendent `CapaciteIndisponible`, aucun
// fichier n'est invente (K-28).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Les recus des paiements d'un profil.
abstract interface class PortRecus {
  /// Prepare et remet le recu du dernier paiement qui a finance le profil
  /// [profilId] (FI-BR-05). **Aucune implementation a ce jour.**
  Future<void> telechargerDernierRecu(String profilId);
}

/// **Aucune source serveur a ce jour** (FI-BR-05) : la demonstration garde
/// cette implementation, le meme etat qu'en production.
class RecusIndisponibles implements PortRecus {
  /// Cree l'implementation.
  const RecusIndisponibles();

  @override
  Future<void> telechargerDernierRecu(String profilId) =>
      Future<void>.error(const CapaciteIndisponible('FI-BR-05'));
}

/// Le port des recus.
final Provider<PortRecus> portRecusProvider = Provider<PortRecus>(
  (Ref _) => const RecusIndisponibles(),
);
