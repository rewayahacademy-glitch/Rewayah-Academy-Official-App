// L'age de l'eleve lu sur le serveur (garde-cap et pilote, 11/11/2026).
//
// Une lecture, sous la session de l'appelant, aucune ecriture :
// `student_profiles.student_type` de l'eleve. Les politiques de la table
// (0001 : « eleve L soi, tuteur L E foyer ») decident qui peut la lire : un
// eleve lit la sienne, un tuteur celle d'un enfant de son foyer ; personne
// d'autre n'obtient de ligne, et l'age reste inconnu (vouvoiement).
//
// Aucun age n'est calcule ici : le serveur dit `minor` ou `autonomous`
// (la meme source que l'Accueil du Mode Accessibilite,
// `accueil_accessibilite_supabase.dart`).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'age_eleve.dart';

/// L'age d'un eleve servi par Supabase.
class LectureAgeEleveSupabase implements PortLectureAgeEleve {
  /// Cree l'adaptateur sur la table `student_profiles`.
  LectureAgeEleveSupabase(SupabaseClient client)
    : _lireType = ((String id) => _typeDe(client, id));

  /// Pour les tests : la lecture du `student_type` est donnee, aucun client.
  LectureAgeEleveSupabase.avecLecture(
    Future<String?> Function(String eleveId) lireType,
  ) : _lireType = lireType;

  final Future<String?> Function(String eleveId) _lireType;

  static Future<String?> _typeDe(SupabaseClient client, String eleveId) async {
    final Map<String, dynamic>? ligne = await client
        .from('student_profiles')
        .select('student_type')
        .eq('profile_id', eleveId)
        .maybeSingle();
    return ligne?['student_type'] as String?;
  }

  /// Le type du serveur traduit : `minor` est un mineur, `autonomous` un
  /// adulte ; toute autre valeur, ou aucune ligne lisible : inconnu.
  static AgeEleve depuisType(String? type) => switch (type) {
    'minor' => AgeEleve.mineur,
    'autonomous' => AgeEleve.adulte,
    _ => AgeEleve.inconnu,
  };

  @override
  Future<AgeEleve> lire(String eleveId) async {
    try {
      return depuisType(await _lireType(eleveId));
    } on Object {
      // Reseau, droit refuse : on ne sait pas ; le vouvoiement reste.
      return AgeEleve.inconnu;
    }
  }
}
