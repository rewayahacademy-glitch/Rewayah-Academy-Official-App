// MES-CLASSES-ETAPE (08/11/2026) : l'etape du programme de chaque Classe de
// l'enseignant, lue sur le serveur (`mes_classes_details()`, migration
// 20261122500000). Branche `detailsClassesProvider` dans `lib/main.dart`.
//
// Rien n'est invente : une Classe sans etape publiee n'a pas de ligne
// d'etape (le serveur rend `null`, l'ecran n'ecrit rien a sa place).
// `remplacement` reste faux : la liste ne contient que des Classes dont
// l'enseignant est titulaire.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mes_classes_page.dart' show DetailClasse;

/// Les lignes de `mes_classes_details()` en details de Classe, par groupe.
/// Une ligne mal formee est ignoree, jamais devinee.
Map<String, DetailClasse> detailsDepuisLignes(Object? lignes) {
  if (lignes is! List<dynamic>) {
    throw const FormatException('Details de Classes invalides');
  }
  final Map<String, DetailClasse> details = <String, DetailClasse>{};
  for (final Object? ligne in lignes) {
    if (ligne is! Map<String, dynamic>) continue;
    final Object? id = ligne['groupe_id'];
    if (id is! String || id.isEmpty) continue;
    final Object? ordre = ligne['etape_ordre'];
    final Object? nom = ligne['etape_nom'];
    final Object? langue = ligne['langue'];
    final bool etapeConnue =
        ordre is int && nom is String && nom.trim().isNotEmpty;
    details[id] = DetailClasse(
      etapeOrdre: etapeConnue ? ordre : null,
      etapeNom: etapeConnue ? nom : null,
      langue: langue is String && langue.isNotEmpty ? langue : null,
    );
  }
  return details;
}

/// L'adaptateur serveur des details de Classes.
class DetailsClassesSupabase {
  /// Cree l'adaptateur.
  const DetailsClassesSupabase(this._client);

  final SupabaseClient _client;

  /// Les details des Classes actives de l'enseignant connecte.
  Future<Map<String, DetailClasse>> lire() async {
    final Object? reponse = await _client.rpc<Object?>('mes_classes_details');
    return detailsDepuisLignes(reponse);
  }
}

/// Les details lus sur le serveur. Branche par `lib/main.dart` ; en cas de
/// panne l'ecran garde ses lignes sans etape (la liste reste lisible).
final FutureProvider<Map<String, DetailClasse>> detailsClassesServeurProvider =
    FutureProvider<Map<String, DetailClasse>>(
      (Ref ref) => DetailsClassesSupabase(Supabase.instance.client).lire(),
    );
