// DOSSIER-DIRECTION (PE-C1, 20/11/2026) : la reference du dossier d'un
// candidat enseignant, depuis son profil, pour que les Comptes, l'Espace de
// traitement et toute liste de comptes ouvrent LE dossier
// (`/admin/personnes/candidatures/<reference>`, l'ecran A du plan §3.1) et non
// « Fichiers a valider ».
//
// Lu par `public.references_dossiers_admin(uuid[])` (migration
// 20261130900000) : la reference seule, dans la portee de genre du lecteur ;
// le dossier se lit ensuite par `lire_candidature`, avec toutes ses gardes.
//
// Repli honnete : tant que la fonction n'est pas installee (PGRST202, 42883),
// ou si la lecture echoue, la table est vide et l'entree garde son ancienne
// destination. Aucun dossier n'est invente.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/router/routes.dart';

/// La lecture des references de dossier depuis des profils.
// ignore: one_member_abstracts
abstract interface class PortReferencesDossiers {
  /// La reference `CAND-…` de la candidature d'enseignant de chacun des
  /// [profils] qui en a une, par identifiant de profil.
  Future<Map<String, String>> references(List<String> profils);
}

/// Le plafond d'une lecture, celui du serveur.
const int plafondReferencesDossiers = 500;

/// L'adaptateur Supabase.
class ReferencesDossiersSupabase implements PortReferencesDossiers {
  /// Cree l'adaptateur ; [client] est lu a l'appel (jamais au demarrage).
  const ReferencesDossiersSupabase(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<Map<String, String>> references(List<String> profils) async {
    final Map<String, String> table = <String, String>{};
    for (int i = 0; i < profils.length; i += plafondReferencesDossiers) {
      final List<String> tranche = profils.sublist(
        i,
        (i + plafondReferencesDossiers).clamp(0, profils.length),
      );
      final Object? brut = await _client().rpc<Object?>(
        'references_dossiers_admin',
        params: <String, dynamic>{'p_profils': tranche},
      );
      table.addAll(referencesDepuisJson(brut));
    }
    return table;
  }
}

/// Lit la reponse de `references_dossiers_admin`. Une ligne mal formee est
/// ignoree. Pure.
Map<String, String> referencesDepuisJson(Object? brut) {
  if (brut is! List) return const <String, String>{};
  return <String, String>{
    for (final Object? ligne in brut)
      if (ligne is Map &&
          ligne['profile_id'] is String &&
          ligne['reference'] is String &&
          referenceDossierValide(ligne['reference'] as String))
        ligne['profile_id'] as String: ligne['reference'] as String,
  };
}

/// Vrai pour une reference de dossier de la forme du serveur (`CAND-` et des
/// chiffres). Pure.
bool referenceDossierValide(String reference) =>
    RegExp(r'^CAND-[0-9]{5,14}$').hasMatch(reference);

/// La demande d'une lecture : des profils, sans ordre ni doublon, pour que la
/// meme liste reutilise la meme lecture.
@immutable
class ProfilsDemandes {
  /// Cree la demande.
  ProfilsDemandes(Iterable<String> profils)
    : profils = List<String>.unmodifiable(
        profils.where((String p) => p.isNotEmpty).toSet().toList()..sort(),
      );

  /// Les profils, tries.
  final List<String> profils;

  @override
  bool operator ==(Object other) =>
      other is ProfilsDemandes && listEquals(other.profils, profils);

  @override
  int get hashCode => Object.hashAll(profils);
}

/// Le port employe par l'application.
final Provider<PortReferencesDossiers> portReferencesDossiersProvider =
    Provider<PortReferencesDossiers>(
      (Ref _) => ReferencesDossiersSupabase(() => Supabase.instance.client),
    );

/// Les references des profils demandes. Vide en cas d'echec : l'entree garde
/// son ancienne destination (repli, jamais un dossier invente).
final referencesDossiersProvider = FutureProvider.autoDispose
    .family<Map<String, String>, ProfilsDemandes>((
      Ref ref,
      ProfilsDemandes demande,
    ) async {
      if (demande.profils.isEmpty) return const <String, String>{};
      try {
        return await ref
            .watch(portReferencesDossiersProvider)
            .references(demande.profils);
      } on Object catch (e) {
        debugPrint('references_dossiers_admin : $e');
        return const <String, String>{};
      }
    });

/// Le chemin du dossier d'un candidat : l'ecran A quand sa reference est
/// connue, sinon « Fichiers a valider » (l'ancienne destination). Pure.
String cheminDossierDuProfil(String? reference) =>
    reference != null && referenceDossierValide(reference)
    ? Routes.adminPersonnesCandidaturePour(reference)
    : Routes.adminPersonnesDossiers;
