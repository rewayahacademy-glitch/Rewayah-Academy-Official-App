import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_resolution_ra.dart';

/// La resolution d'un matricule exact par le serveur (RECH-D2, RECHERCHE-
/// LIVRAISON, 08/11/2026) : `rechercher_personne_par_matricule` (RECH-BACK-3).
///
/// Le serveur tire l'identite de la session verifiee, applique le quota de
/// l'appelant et ne rend la personne que si elle est dans son perimetre
/// (`partie_concernee`). Un matricule inconnu, mal forme, hors perimetre ou une
/// session sans quota recoivent **la meme reponse vide** : l'adaptateur rend
/// alors `null`, jamais autre chose (non-enumerabilite).
///
/// **Un eleve seulement** (decision du pilote, 08/11/2026) : la RPC peut rendre
/// une personne d'un autre role de la portee de l'appelant ; la loupe ne la
/// resout pas (`null`, le meme vide), ce n'est pas une panne. La classe n'est
/// pas lue : elle reste nulle.
///
/// Une panne (reseau, refus du serveur, reponse illisible) leve : c'est une
/// exception, jamais `null` (le moteur la rend en `ReponseEchec`).
class ResolutionRaSupabase implements PortResolutionRa {
  /// Cree l'adaptateur sur le client de l'application.
  const ResolutionRaSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) async {
    final Object? brut = await _client.rpc<Object?>(
      'rechercher_personne_par_matricule',
      params: <String, dynamic>{'p_saisie': identifiantExact},
    );
    return elevePourRaDepuisReponse(brut);
  }
}

/// Lit la reponse de `rechercher_personne_par_matricule` : une liste de zero ou
/// une ligne. `null` pour le vide et pour une personne qui n'est pas un eleve.
/// Une reponse qui n'est pas une liste, ou une ligne sans identifiant ni
/// prenom, est illisible : `FormatException`.
ElevePourRa? elevePourRaDepuisReponse(Object? brut) {
  if (brut == null) return null;
  if (brut is! List) {
    throw const FormatException(
      'rechercher_personne_par_matricule : liste attendue',
    );
  }
  if (brut.isEmpty) return null;
  final Object? premiere = brut.first;
  if (premiere is! Map) {
    throw const FormatException(
      'rechercher_personne_par_matricule : ligne illisible',
    );
  }
  final Object? role = premiere['role'];
  if (role != 'student') return null;
  final Object? id = premiere['profile_id'];
  final Object? prenom = premiere['first_name'];
  if (id is! String || id.isEmpty || prenom is! String || prenom.isEmpty) {
    throw const FormatException(
      'rechercher_personne_par_matricule : ligne incomplete',
    );
  }
  return ElevePourRa(eleveId: id, prenom: prenom);
}
