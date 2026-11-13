// SOURATES (directeur, 11/11/2026, option A) : « l'enseignant coche la
// sourate au cahier ». Les 17 sourates des bases de chaque eleve d'une
// Classe, avec celles deja validees, lues au serveur
// (`sourates_bases_classe`, migration 20261122900000). La liste et son ordre
// d'etude viennent du serveur (source unique) : rien n'est ecrit ici.
//
// Sans branchement (tests, demonstration), le port ne lit rien : le cahier
// ne propose aucune sourate, jamais une liste supposee.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Une sourate des bases pour un eleve.
@immutable
class SourateBases {
  /// Cree la sourate.
  const SourateBases({
    required this.ordre,
    required this.numero,
    required this.nom,
    required this.validee,
    this.nomArabe,
  });

  /// Son rang dans l'ordre d'etude (1 a 17).
  final int ordre;

  /// Son numero dans le Coran.
  final int numero;

  /// Son nom translittere (« Al-Fatiha »).
  final String nom;

  /// Son nom en arabe, quand le serveur le rend.
  final String? nomArabe;

  /// Le nom a montrer : en arabe dans l'interface arabe, sinon translittere.
  String nomPour({required bool arabe}) =>
      arabe && (nomArabe?.trim().isNotEmpty ?? false) ? nomArabe!.trim() : nom;

  /// Vrai quand elle est deja validee : elle ne se coche plus.
  final bool validee;
}

/// Les sourates des eleves d'une Classe, cote serveur.
abstract interface class PortSouratesClasse {
  /// Les 17 sourates des bases de chaque eleve actif de [groupeId], dans
  /// l'ordre d'etude, par `studentId`.
  Future<Map<String, List<SourateBases>>> souratesDeLaClasse(String groupeId);

  /// CORRIGER-SOURATE : les sourates validees de [groupeId] que la personne
  /// connectee peut retirer, par `studentId` puis numero, avec leur limite
  /// (`null` : sans limite). Le serveur seul en decide
  /// (`sourates_retirables_classe`, migration 20261123820000).
  Future<Map<String, Map<int, DateTime?>>> souratesRetirables(String groupeId);

  /// Retire la sourate [numero] des sourates validees de [eleveId]. Leve
  /// [RetraitSourateRefuse] quand le serveur refuse (delai passe, autre
  /// auteur) ; toute autre erreur remonte telle quelle.
  Future<void> retirer({
    required String eleveId,
    required int numero,
    String? motif,
  });
}

/// Le serveur refuse le retrait (42501) : le delai de 24 heures est passe, ou
/// la personne n'est pas l'auteur de la validation.
class RetraitSourateRefuse implements Exception {
  /// Cree le refus.
  const RetraitSourateRefuse();
}

/// Le port sans serveur : rien a lire.
class SouratesClasseAbsentes implements PortSouratesClasse {
  /// Cree le port.
  const SouratesClasseAbsentes();

  @override
  Future<Map<String, List<SourateBases>>> souratesDeLaClasse(
    String groupeId,
  ) async => const <String, List<SourateBases>>{};

  @override
  Future<Map<String, Map<int, DateTime?>>> souratesRetirables(
    String groupeId,
  ) async => const <String, Map<int, DateTime?>>{};

  @override
  Future<void> retirer({
    required String eleveId,
    required int numero,
    String? motif,
  }) async => throw const RetraitSourateRefuse();
}

/// Les sourates retirables lues dans la reponse de
/// `sourates_retirables_classe` ; les lignes illisibles sont ecartees.
Map<String, Map<int, DateTime?>> retirablesDepuisReponse(Object? brut) {
  if (brut is! List) return const <String, Map<int, DateTime?>>{};
  final Map<String, Map<int, DateTime?>> parEleve =
      <String, Map<int, DateTime?>>{};
  for (final Object? ligne in brut) {
    if (ligne is! Map) continue;
    final Object? id = ligne['student_id'];
    final Object? numero = ligne['numero'];
    if (id is! String || numero is! num) continue;
    final Object? jusqua = ligne['retirable_jusqua'];
    parEleve.putIfAbsent(id, () => <int, DateTime?>{})[numero.toInt()] =
        jusqua is String ? DateTime.tryParse(jusqua) : null;
  }
  return parEleve;
}

/// Les sourates lues dans la reponse de `sourates_bases_classe`, par
/// `studentId`, dans l'ordre d'etude ; les lignes illisibles sont ecartees.
Map<String, List<SourateBases>> souratesDepuisReponse(Object? brut) {
  if (brut is! List) return const <String, List<SourateBases>>{};
  final Map<String, List<SourateBases>> parEleve =
      <String, List<SourateBases>>{};
  for (final Object? ligne in brut) {
    if (ligne is! Map) continue;
    final Object? id = ligne['student_id'];
    final Object? ordre = ligne['ordre'];
    final Object? numero = ligne['numero'];
    final Object? nom = ligne['nom'];
    if (id is! String || ordre is! num || numero is! num || nom is! String) {
      continue;
    }
    parEleve
        .putIfAbsent(id, () => <SourateBases>[])
        .add(
          SourateBases(
            ordre: ordre.toInt(),
            numero: numero.toInt(),
            nom: nom.trim(),
            nomArabe: ligne['nom_arabe'] is String
                ? (ligne['nom_arabe'] as String).trim()
                : null,
            validee: ligne['validee'] == true,
          ),
        );
  }
  for (final List<SourateBases> l in parEleve.values) {
    l.sort((SourateBases a, SourateBases b) => a.ordre.compareTo(b.ordre));
  }
  return parEleve;
}

/// Le port employe. L'application reelle le surcharge par l'adaptateur
/// Supabase (`main.dart`).
final Provider<PortSouratesClasse> portSouratesClasseProvider =
    Provider<PortSouratesClasse>((Ref _) => const SouratesClasseAbsentes());

/// Les sourates des eleves d'une Classe, par `groupeId`.
final FutureProviderFamily<Map<String, List<SourateBases>>, String>
souratesClasseProvider =
    FutureProvider.family<Map<String, List<SourateBases>>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portSouratesClasseProvider).souratesDeLaClasse(groupeId),
      retry: (int _, Object _) => null,
    );

/// CORRIGER-SOURATE : les sourates que la personne connectee peut retirer
/// dans une Classe, par `groupeId`.
final FutureProviderFamily<Map<String, Map<int, DateTime?>>, String>
souratesRetirablesProvider =
    FutureProvider.family<Map<String, Map<int, DateTime?>>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portSouratesClasseProvider).souratesRetirables(groupeId),
      retry: (int _, Object _) => null,
    );
