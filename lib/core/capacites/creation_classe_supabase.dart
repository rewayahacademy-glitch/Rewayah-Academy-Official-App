// Classe a plusieurs creneaux et mixite (decisions D1 et D2 du directeur,
// 29/10/2026) : la creation d'une classe a la main part par
// `creer_classe_creneaux_admin` (migration 20261030100000), qui retient enfin
// le genre choisi et le fuseau, et pose tous les creneaux de la semaine dans
// une seule transaction. Un refus du predicat arrive en
// `CreationClasseRefusee`, comme pour `creer_groupe`.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/creation_classe_refusee.dart';
import '../admin/service_groupes.dart';
import '../planning/service_planning.dart' show Creneau;
import 'port_creation_classe.dart';
import 'port_enseignants_classe.dart' show GenreClasse;

/// La valeur serveur d'un genre de classe nouvelle ; « indetermine » n'en
/// est pas une (D1).
String genreClasseSql(GenreClasse genre) => switch (genre) {
  GenreClasse.hommes => 'hommes',
  GenreClasse.femmes => 'femmes',
  GenreClasse.mixte => 'mixte',
  GenreClasse.indetermine => throw ArgumentError.value(
    genre,
    'genre',
    'une classe nouvelle a un genre ou est mixte (D1)',
  ),
};

/// L'adaptateur reel de la creation d'une classe.
class CreationClasseSupabase implements PortCreationClasse {
  /// Cree l'adaptateur.
  const CreationClasseSupabase(this._client);

  final SupabaseClient _client;

  @override
  bool get retientGenre => true;

  @override
  bool get retientFuseau => true;

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required GenreClasse genre,
    required String libelle,
    required Creneau creneau,
    required int seuilMax,
    List<Creneau> autresCreneaux = const <Creneau>[],
    List<int?> durees = const <int?>[],
  }) => traduireRefusCreationClasse<String>(
    () => _client.rpc<String>(
      'creer_classe_creneaux_admin',
      params: <String, dynamic>{
        'p_teacher_profile_id': teacherId,
        'p_type_public': type.valeurSql,
        'p_libelle': libelle,
        'p_seuil_max': seuilMax,
        'p_timezone_iana': creneau.fuseau,
        'p_creneaux': <Map<String, int>>[
          for (final (int i, Creneau c) in <Creneau>[
            creneau,
            ...autresCreneaux,
          ].indexed)
            <String, int>{
              'jour': c.jour,
              'heure': c.heure,
              // Nulle : la duree de la classe, que le serveur retient seul.
              if (i < durees.length && durees[i] != null) 'duree': durees[i]!,
            },
        ],
        'p_genre': genreClasseSql(genre),
        'p_couleur_jeton': null,
      },
    ),
  );
}
