import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// La progression partageable d'un eleve avec sa famille.
///
/// **Forme provisoire** : aucune source famille n'existe (DB-CRS-11,
/// `progression_historique` est lisible par l'administration seule). Tout est
/// rendu par le serveur en mots humains, jamais un code de niveau.
@immutable
class ProgressionEleve {
  /// Cree une progression.
  const ProgressionEleve({
    required this.eleveId,
    this.niveauHumain,
    this.jalons = const <String>[],
  });

  /// L'eleve.
  final String eleveId;

  /// Le niveau courant, en mots. `null` : non dit.
  final String? niveauHumain;

  /// Les jalons franchis, deja rediges par le serveur.
  final List<String> jalons;
}

/// La progression d'un eleve (contrat K6).
abstract interface class PortProgressionFamille {
  /// La progression partageable de [eleveId].
  Future<ProgressionEleve> progression(String eleveId);
}

/// La progression tant qu'aucune source n'existe : « Progression non
/// disponible », jamais un bloc vide trompeur. Aucun adaptateur prevu avant
/// DB-CRS-11.
class ProgressionFamilleIndisponible implements PortProgressionFamille {
  /// Cree l'implementation.
  const ProgressionFamilleIndisponible();

  @override
  Future<ProgressionEleve> progression(String eleveId) =>
      Future<ProgressionEleve>.error(const CapaciteIndisponible('DB-CRS-11'));
}

/// La progression employee par l'application.
final Provider<PortProgressionFamille> portProgressionFamilleProvider =
    Provider<PortProgressionFamille>(
      (Ref ref) => const ProgressionFamilleIndisponible(),
    );
