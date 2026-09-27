import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Un paiement du foyer, tel qu'une future source le rendra.
///
/// **Forme provisoire** : aucune table de paiement famille n'existe
/// (DB-CPT-03). Aucun calcul financier cote Flutter : le montant arrive en
/// unites mineures, deja arrete par le serveur.
@immutable
class PaiementFoyer {
  /// Cree un paiement.
  const PaiementFoyer({
    required this.id,
    required this.montantMineur,
    required this.devise,
    required this.statutServeur,
    required this.date,
    required this.justificatifDisponible,
  });

  /// Identifiant.
  final String id;

  /// Montant en unites mineures (centimes), rendu par le serveur.
  final int montantMineur;

  /// Code ISO 4217.
  final String devise;

  /// Statut tel que le serveur le nommera. **Jamais affiche brut** : la liste
  /// des statuts sera fixee avec DB-CPT-03.
  final String statutServeur;

  /// Date du paiement.
  final DateTime date;

  /// Vrai quand un justificatif est telechargeable.
  final bool justificatifDisponible;
}

/// Les paiements du foyer (contrat K6).
abstract interface class PortPaiementsFoyer {
  /// L'historique des paiements.
  Future<List<PaiementFoyer>> historique();

  /// Un paiement precis.
  Future<PaiementFoyer?> detail(String id);
}

/// Les paiements tant qu'aucune source n'existe : une page, une phrase, aucun
/// bouton, jamais un paiement simule comme regle. Aucun adaptateur prevu avant
/// DB-CPT-03.
class PaiementsFoyerIndisponible implements PortPaiementsFoyer {
  /// Cree l'implementation.
  const PaiementsFoyerIndisponible();

  @override
  Future<List<PaiementFoyer>> historique() => Future<List<PaiementFoyer>>.error(
    const CapaciteIndisponible('DB-CPT-03'),
  );

  @override
  Future<PaiementFoyer?> detail(String id) =>
      Future<PaiementFoyer?>.error(const CapaciteIndisponible('DB-CPT-03'));
}

/// Les paiements employes par l'application.
final Provider<PortPaiementsFoyer> portPaiementsFoyerProvider =
    Provider<PortPaiementsFoyer>(
      (Ref ref) => const PaiementsFoyerIndisponible(),
    );
