// La politique commerciale effective et ses versions (FI-1c, guide Finance
// V4 §1, §5.7 ; FI-BR-01, FI-BR-02).
//
// Lecture seule dans ce lot : le brouillon et la publication arrivent avec
// FI-11b, et « Publier » restera sur un etat honnete jusqu'au branchement
// (K-28). Aucune source serveur a ce jour : la demonstration surcharge le
// port (`finance_demo.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/politique_commerciale.dart';
import 'capacite_indisponible.dart';

/// Les politiques commerciales, lues par tous les ecrans qui en dependent.
abstract interface class PortPolitiquesCommerciales {
  /// La politique effective aujourd'hui (FI-BR-01).
  Future<PolitiqueCommerciale> active();

  /// L'historique des versions, la plus recente d'abord (FI-BR-02).
  Future<List<PolitiqueCommerciale>> versions();
}

/// **Aucune source serveur a ce jour** (FI-BR-01, FI-BR-02).
class PolitiquesCommercialesIndisponibles
    implements PortPolitiquesCommerciales {
  /// Cree l'implementation.
  const PolitiquesCommercialesIndisponibles();

  @override
  Future<PolitiqueCommerciale> active() => Future<PolitiqueCommerciale>.error(
    const CapaciteIndisponible('FI-BR-01'),
  );

  @override
  Future<List<PolitiqueCommerciale>> versions() =>
      Future<List<PolitiqueCommerciale>>.error(
        const CapaciteIndisponible('FI-BR-02'),
      );
}

/// Le port des politiques ; la demonstration le surcharge.
final Provider<PortPolitiquesCommerciales> portPolitiquesCommercialesProvider =
    Provider<PortPolitiquesCommerciales>(
      (Ref _) => const PolitiquesCommercialesIndisponibles(),
    );
