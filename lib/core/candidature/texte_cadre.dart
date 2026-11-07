/// CADRE-ECRAN (pilote, 07/11/2026) : la lecture du texte PUBLIE du cadre
/// religieux et pedagogique du candidat enseignant.
///
/// Aucun mot du cadre ne vit dans le client. Le texte valide par le
/// directeur le 07/11/2026 (`docs/current/TEXTES-VALIDES/
/// CADRE-RELIGIEUX-ENSEIGNANT.md`) est publie par une migration dans
/// `contract_texts` (`teacher_religious_framework`, une ligne par langue,
/// chacune avec sa sha256), et sa version dans `contract_required_versions`.
/// L'ecran lit la ligne courante dans la langue de l'application, retombe
/// sur le francais quand cette langue n'a pas de ligne, et ne montre le
/// texte que si sa version est celle que le serveur exige.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../domain/enums.dart';

/// Ce qui manque quand l'application n'a pas de lecture du cadre.
const String dependanceCadre = 'CAND-L2A1';

/// Le texte publie du cadre, dans une langue.
class TexteCadre {
  /// Cree le texte lu.
  const TexteCadre({
    required this.version,
    required this.texte,
    required this.langue,
  });

  /// La version publiee (`2026-11-07`).
  final String version;

  /// Le texte, tel que publie.
  final String texte;

  /// La langue de la ligne lue (`fr` ou `ar`).
  final String langue;
}

/// La lecture du texte publie.
abstract interface class PortTexteCadre {
  /// Le texte courant dans [langue], ou en francais si [langue] n'a pas de
  /// ligne ; `null` quand rien n'est publie.
  Future<TexteCadre?> lire({required String langue});
}

/// Sans lecture branchee : la capacite est dite indisponible.
class TexteCadreIndisponible implements PortTexteCadre {
  /// Cree le port.
  const TexteCadreIndisponible();

  @override
  Future<TexteCadre?> lire({required String langue}) async =>
      throw const CapaciteIndisponible(dependanceCadre);
}

/// L'adaptateur Supabase : `contract_texts`, ligne courante, lue sous la
/// policy `contract_texts_published_read`.
class TexteCadreSupabase implements PortTexteCadre {
  /// Cree l'adaptateur.
  const TexteCadreSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<TexteCadre?> lire({required String langue}) async {
    final TexteCadre? lu = await _ligne(langue);
    if (lu != null || langue == 'fr') return lu;
    return _ligne('fr');
  }

  Future<TexteCadre?> _ligne(String langue) async {
    final Map<String, dynamic>? ligne = await _client
        .from('contract_texts')
        .select('version, body, locale')
        .eq('contract_kind', SorteContrat.cadreReligieuxEnseignant.valeurSql)
        .eq('locale', langue)
        .eq('is_current', true)
        .maybeSingle();
    if (ligne == null) return null;
    final Object? version = ligne['version'];
    final Object? texte = ligne['body'];
    if (version is! String || texte is! String || texte.trim().isEmpty) {
      return null;
    }
    return TexteCadre(
      version: version,
      texte: texte,
      langue: ligne['locale'] as String? ?? langue,
    );
  }
}

/// Le port ; l'application le surcharge avec l'adaptateur Supabase.
final Provider<PortTexteCadre> portTexteCadreProvider =
    Provider<PortTexteCadre>((Ref _) => const TexteCadreIndisponible());

/// Le texte publie, par langue.
final FutureProviderFamily<TexteCadre?, String> texteCadreProvider =
    FutureProvider.family<TexteCadre?, String>(
      (Ref ref, String langue) =>
          ref.watch(portTexteCadreProvider).lire(langue: langue),
    );
