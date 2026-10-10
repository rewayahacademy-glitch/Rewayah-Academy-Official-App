import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import 'occurrence_creneau.dart';
import 'offre_horaire.dart' show PublicOffre;
import 'port_regroupements_admin.dart';

/// File de regroupements et mutations d'administration, via RPC autorisées.
class RegroupementsAdminSupabase implements PortRegroupementsAdmin {
  const RegroupementsAdminSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RegroupementDemandes>> regroupements() async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'regroupements_c11bis_admin',
    );
    return rows.map(_regroupementDepuisJson).toList(growable: false);
  }

  @override
  Future<ResultatCreationClasse> creerClasse({
    required String regroupementId,
    required GenreClasse genre,
    required String libelle,
    required String cleEnvoi,
  }) async {
    final Map<String, dynamic> resultat = await _client.rpc<Map<String, dynamic>>(
      'creer_classe_depuis_regroupement_c11bis',
      params: <String, dynamic>{
        'p_regroupement_id': regroupementId,
        'p_cle_idempotence': cleEnvoi,
        'p_libelle': libelle,
        'p_genre_classe': genre.name,
      },
    );
    if (resultat['statut'] == 'deja_creee') {
      return const CreationDejaFaite();
    }
    if (resultat['statut'] != 'creee') {
      return CreationRefusee(
        resultat['motif'] as String? ?? 'Création refusée par le serveur',
      );
    }
    return ClasseCreee(
      classe: ClasseSansEnseignant(
        classeId: resultat['classe_id'] as String,
        libelle: resultat['libelle'] as String? ?? libelle,
        genre: _genreDepuisCode(resultat['genre_classe'] as String?),
        peutAffecterEnseignant:
            resultat['peut_affecter_enseignant'] as bool? ?? false,
      ),
      elevesIntegres: (resultat['eleves_integres'] as num).toInt(),
    );
  }

  @override
  Future<ResultatAffectation> affecterEnseignant({
    required String classeId,
    required String enseignantId,
  }) async {
    final String resultat = await _client.rpc<String>(
      'affecter_enseignant_classe_c11bis',
      params: <String, dynamic>{
        'p_groupe_id': classeId,
        'p_teacher_profile_id': enseignantId,
      },
    );
    return resultat == 'deja_affecte'
        ? ResultatAffectation.dejaAffecte
        : ResultatAffectation.affecte;
  }

  RegroupementDemandes _regroupementDepuisJson(dynamic raw) {
    if (raw is! Map) {
      throw const FormatException('Regroupement admin invalide');
    }
    final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
    final List<dynamic> occurrences =
        (row['occurrences'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> autres =
        (row['autres_fuseaux'] as List<dynamic>?) ?? const <dynamic>[];
    final dynamic rawClasse = row['classe'];
    ClasseSansEnseignant? classe;
    if (rawClasse is Map) {
      final Map<String, dynamic> value = Map<String, dynamic>.from(rawClasse);
      classe = ClasseSansEnseignant(
        classeId: value['classe_id'] as String,
        libelle: value['libelle'] as String? ?? '',
        genre: _genreDepuisCode(value['genre_classe'] as String?),
        peutAffecterEnseignant:
            value['peut_affecter_enseignant'] as bool? ?? false,
      );
    }
    return RegroupementDemandes(
      id: row['regroupement_id'] as String,
      public: PublicOffre.depuisSql(row['type_public'] as String?),
      langueCode: row['langue_code'] as String,
      langueNom: row['langue_nom'] as String? ?? '',
      fuseau: row['fuseau_iana'] as String,
      occurrences: occurrences.map((dynamic item) {
        if (item is! Map) {
          throw const FormatException('Occurrence admin invalide');
        }
        final Map<String, dynamic> occurrence =
            Map<String, dynamic>.from(item);
        return OccurrenceCreneau(
          jourIso: (occurrence['jour_iso'] as num).toInt(),
          heure: (occurrence['heure'] as num).toInt(),
          minute: (occurrence['minute'] as num?)?.toInt() ?? 0,
        );
      }).toList(growable: false),
      nombreEleves: (row['nombre_eleves'] as num).toInt(),
      quota: (row['quota'] as num).toInt(),
      autresFuseaux: autres.map((dynamic item) {
        if (item is! Map) {
          throw const FormatException('Autre fuseau invalide');
        }
        final Map<String, dynamic> value = Map<String, dynamic>.from(item);
        return HeureDansFuseau(
          fuseau: value['fuseau'] as String,
          jourIso: (value['jour_iso'] as num?)?.toInt(),
          heure: (value['heure'] as num).toInt(),
          minute: (value['minute'] as num?)?.toInt() ?? 0,
          decalageJour: (value['decalage_jour'] as num?)?.toInt() ?? 0,
        );
      }).toList(growable: false),
      peutCreerClasse: row['peut_creer_classe'] as bool? ?? false,
      classe: classe,
    );
  }

  GenreClasse? _genreDepuisCode(String? code) => switch (code) {
    'hommes' => GenreClasse.hommes,
    'femmes' => GenreClasse.femmes,
    'indetermine' => GenreClasse.indetermine,
    _ => null,
  };
}
