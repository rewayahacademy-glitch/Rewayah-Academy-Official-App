// NON-BRANCHE-LIVRAISON 1 (08/11/2026) : les observations du cahier, lues.
//
// L'enseignant note deja, dans le cahier de chaque seance, les objectifs de
// l'etape qu'un eleve doit renforcer et s'il est pret pour le petit bilan
// (CAHIER-C3, migration 20261110610000). Le serveur les range en lignes
// (`cahier_observations`) et les rend par `observations_classe`, mais aucun
// ecran ne les lisait (RELEVE-NON-BRANCHE-2026-11-08 §3, rang 1 ;
// VISION-ECOLE : une donnee saisie doit servir).
//
// Ce que montre la fiche : les observations de la DERNIERE seance ou
// l'enseignant a note quelque chose pour cet eleve, avec sa date. Rien n'est
// deduit : un cahier sans observation pour l'eleve ne cree aucune ligne, la
// date dit donc de quand date la note.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Ce que le dernier cahier a note pour un eleve.
@immutable
class ObservationsEleve {
  /// Cree les observations.
  const ObservationsEleve({
    required this.studentId,
    required this.notees,
    required this.aRenforcer,
    required this.pretBilan,
  });

  /// L'eleve.
  final String studentId;

  /// Le debut de la seance dont le cahier porte ces observations.
  final DateTime notees;

  /// Les objectifs de l'etape a renforcer, dans l'ordre du serveur.
  final List<String> aRenforcer;

  /// Vrai quand l'enseignant l'a dit pret pour le petit bilan.
  final bool pretBilan;
}

/// Les observations d'une Classe, cote serveur.
abstract interface class PortObservationsClasse {
  /// Les observations des eleves de la Classe [groupeId], par `studentId`.
  Future<Map<String, ObservationsEleve>> observationsDeLaClasse(
    String groupeId,
  );
}

/// Le port sans serveur (tests, page montee seule) : rien a lire.
/// L'application reelle le surcharge par l'adaptateur Supabase (`main.dart`).
class ObservationsClasseAbsentes implements PortObservationsClasse {
  /// Cree le port.
  const ObservationsClasseAbsentes();

  @override
  Future<Map<String, ObservationsEleve>> observationsDeLaClasse(
    String groupeId,
  ) async => const <String, ObservationsEleve>{};
}

/// Le port employe.
final Provider<PortObservationsClasse> portObservationsClasseProvider =
    Provider<PortObservationsClasse>(
      (Ref _) => const ObservationsClasseAbsentes(),
    );

/// Les observations d'une Classe, par `groupeId`. Sans retentative
/// silencieuse : un echec se dit, puis se relit au geste.
final FutureProviderFamily<Map<String, ObservationsEleve>, String>
observationsClasseProvider =
    FutureProvider.family<Map<String, ObservationsEleve>, String>(
      (Ref ref, String groupeId) => ref
          .watch(portObservationsClasseProvider)
          .observationsDeLaClasse(groupeId),
      retry: (int _, Object _) => null,
    );

/// Les observations lues dans la reponse de `observations_classe`
/// (`session_id`, `student_id`, `nature`, `objectif`, `observe_le`), par
/// eleve : seule la seance la plus recente de chaque eleve est gardee. Les
/// lignes illisibles sont ecartees.
Map<String, ObservationsEleve> observationsDepuisReponse(Object? brut) {
  if (brut is! List) return const <String, ObservationsEleve>{};
  final Map<String, ({String seance, DateTime le})> derniere =
      <String, ({String seance, DateTime le})>{};
  final List<({String eleve, String seance, String nature, String? objectif})>
  lignes = <({String eleve, String seance, String nature, String? objectif})>[];
  for (final Object? ligne in brut) {
    if (ligne is! Map) continue;
    final Object? eleve = ligne['student_id'];
    final Object? seance = ligne['session_id'];
    final Object? nature = ligne['nature'];
    final DateTime? le = DateTime.tryParse(ligne['observe_le'] as String? ?? '')
        ?.toLocal();
    if (eleve is! String || seance is! String || nature is! String) continue;
    if (le == null) continue;
    final Object? objectif = ligne['objectif'];
    lignes.add((
      eleve: eleve,
      seance: seance,
      nature: nature,
      objectif: objectif is String ? objectif.trim() : null,
    ));
    final ({String seance, DateTime le})? vue = derniere[eleve];
    if (vue == null || le.isAfter(vue.le)) {
      derniere[eleve] = (seance: seance, le: le);
    }
  }
  final Map<String, ObservationsEleve> resultat = <String, ObservationsEleve>{};
  for (final MapEntry<String, ({String seance, DateTime le})> e
      in derniere.entries) {
    final List<String> aRenforcer = <String>[];
    bool pret = false;
    for (final l in lignes) {
      if (l.eleve != e.key || l.seance != e.value.seance) continue;
      if (l.nature == 'pret_bilan') pret = true;
      final String? objectif = l.objectif;
      if (l.nature == 'a_renforcer' &&
          objectif != null &&
          objectif.isNotEmpty &&
          !aRenforcer.contains(objectif)) {
        aRenforcer.add(objectif);
      }
    }
    if (aRenforcer.isEmpty && !pret) continue;
    resultat[e.key] = ObservationsEleve(
      studentId: e.key,
      notees: e.value.le,
      aRenforcer: List<String>.unmodifiable(aRenforcer),
      pretBilan: pret,
    );
  }
  return resultat;
}
