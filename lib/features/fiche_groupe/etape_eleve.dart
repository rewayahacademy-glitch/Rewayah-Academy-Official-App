// CAHIER-C2 (06/11/2026, ETUDE-CAHIER-2026-11.md §4.5) : l'etape du programme
// de chaque eleve d'une Classe, lue au serveur (`etapes_eleves_classe`,
// migration 20261110600000).
//
// Ce que la fiche de l'eleve en montre : l'etape, ses objectifs et la date a
// laquelle elle doit etre finie, pour la tranche d'age de l'eleve. Seule une
// version publiee du programme compte ; le serveur choisit l'etape (decision
// de niveau de l'eleve, sinon etape de la Classe) et calcule la date limite.
// Rien n'est deduit ici.
//
// Sans branchement (tests, demonstration), le port ne lit rien : la fiche
// dit qu'aucune etape n'est encore publiee, jamais une etape supposee.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// L'etape en cours d'un eleve.
@immutable
class EtapeEleve {
  /// Cree l'etape.
  const EtapeEleve({
    required this.studentId,
    required this.nom,
    required this.objectifs,
    this.dureePrevueSemaines,
    this.dateLimiteSemaines,
    this.dateLimite,
  });

  /// Lit une ligne de `etapes_eleves_classe` ; `null` si elle est illisible.
  static EtapeEleve? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['student_id'];
    final Object? nom = brut['etape_nom'];
    if (id is! String || nom is! String || nom.trim().isEmpty) return null;
    final Object? objectifs = brut['objectifs'];
    final Object? limite = brut['date_limite'];
    return EtapeEleve(
      studentId: id,
      nom: nom.trim(),
      objectifs: objectifs is List
          ? <String>[
              for (final Object? o in objectifs)
                if (o is String && o.trim().isNotEmpty) o.trim(),
            ]
          : const <String>[],
      dureePrevueSemaines: (brut['duree_prevue_semaines'] as num?)?.toInt(),
      dateLimiteSemaines: (brut['date_limite_semaines'] as num?)?.toInt(),
      dateLimite: limite is String ? DateTime.tryParse(limite) : null,
    );
  }

  /// L'eleve (`profiles.id`).
  final String studentId;

  /// Le nom humain de l'etape (« Lire avec les voyelles »).
  final String nom;

  /// Les objectifs de l'etape, dans l'ordre.
  final List<String> objectifs;

  /// La duree prevue pour la tranche d'age de l'eleve, en semaines.
  final int? dureePrevueSemaines;

  /// La date limite, en semaines depuis le debut de l'etape.
  final int? dateLimiteSemaines;

  /// La date a laquelle l'etape doit etre finie ; `null` quand le debut de
  /// l'etape n'est pas connu (etape de la Classe, sans decision de niveau).
  final DateTime? dateLimite;
}

/// Les etapes des eleves d'une Classe, cote serveur.
abstract interface class PortEtapesEleves {
  /// Les etapes des eleves actifs de la Classe [groupeId], par `studentId`.
  Future<Map<String, EtapeEleve>> etapesDeLaClasse(String groupeId);
}

/// Le port sans serveur : rien a lire.
class EtapesElevesAbsentes implements PortEtapesEleves {
  /// Cree le port.
  const EtapesElevesAbsentes();

  @override
  Future<Map<String, EtapeEleve>> etapesDeLaClasse(String groupeId) async =>
      const <String, EtapeEleve>{};
}

/// Le port employe. L'application reelle le surcharge par l'adaptateur
/// Supabase (`main.dart`).
final Provider<PortEtapesEleves> portEtapesElevesProvider =
    Provider<PortEtapesEleves>((Ref _) => const EtapesElevesAbsentes());

/// Les etapes des eleves d'une Classe, par `groupeId`.
final FutureProviderFamily<Map<String, EtapeEleve>, String>
etapesElevesClasseProvider =
    FutureProvider.family<Map<String, EtapeEleve>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portEtapesElevesProvider).etapesDeLaClasse(groupeId),
      retry: (int _, Object _) => null,
    );
