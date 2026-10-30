// La politique commerciale lue par une famille (TRANSPARENCE, 30/10/2026) :
// `politique_commerciale_famille`, ouverte a tout compte connecte, sans paie,
// marge ni budget. La politique de la direction reste
// `PortPolitiquesCommerciales`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/politique_famille.dart';
import 'capacite_indisponible.dart';

/// La politique commerciale en vigueur, vue d'une famille.
// ignore: one_member_abstracts
abstract interface class PortPolitiqueFamille {
  /// La politique en vigueur aujourd'hui et sa repartition.
  Future<PolitiqueFamille> lire();
}

/// Aucune source : l'ecran dit l'indisponibilite, jamais un prix invente.
class PolitiqueFamilleIndisponible implements PortPolitiqueFamille {
  /// Cree l'implementation.
  const PolitiqueFamilleIndisponible();

  @override
  Future<PolitiqueFamille> lire() => Future<PolitiqueFamille>.error(
    const CapaciteIndisponible('TRANSPARENCE'),
  );
}

/// Le port ; la production le surcharge (main.dart), la demonstration aussi.
final Provider<PortPolitiqueFamille> portPolitiqueFamilleProvider =
    Provider<PortPolitiqueFamille>(
      (Ref _) => const PolitiqueFamilleIndisponible(),
    );
