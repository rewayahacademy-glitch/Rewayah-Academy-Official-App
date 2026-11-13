// L'adaptateur Supabase des etapes du programme publie (BIBLIOTHEQUE-UNE, D3),
// par `bibliotheque_etapes_publiees` (direction seulement) : le serveur lit les
// tables du programme si elles existent et rend une liste vide sinon.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'etapes_programme.dart';

/// Les etapes lues au serveur.
class EtapesProgrammeSupabase implements PortEtapesProgramme {
  /// Cree l'adaptateur.
  const EtapesProgrammeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EtapeProgramme>> publiees() async {
    final Object? brut = await _client.rpc<Object?>(
      'bibliotheque_etapes_publiees',
    );
    return lireEtapes(brut);
  }

  /// Les etapes d'une reponse serveur ; tout ce qui n'est pas une liste de
  /// `{code, nom}` valides est ecarte.
  static List<EtapeProgramme> lireEtapes(Object? brut) {
    if (brut is! List) return const <EtapeProgramme>[];
    return <EtapeProgramme>[
      for (final Object? e in brut)
        if (e is Map<dynamic, dynamic>)
          if (EtapeProgramme.depuisJson(Map<String, dynamic>.from(e))
              case final EtapeProgramme etape
              when etape.code.isNotEmpty && etape.nom.isNotEmpty)
            etape,
    ];
  }
}
