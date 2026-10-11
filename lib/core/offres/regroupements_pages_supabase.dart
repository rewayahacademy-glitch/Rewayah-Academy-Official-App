import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import 'offre_horaire.dart' show PublicOffre;
import 'page_regroupements.dart';
import 'port_regroupements_admin.dart';

/// Adaptateur serveur de la liste d'administration C-25.
class RegroupementsPagesSupabase implements PortRegroupementsPages {
  const RegroupementsPagesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PageRegroupements> page(
    FiltreRegroupements filtre, {
    required int page,
    required int taille,
  }) async {
    final FunctionResponse response = await _client.functions.invoke(
      'regroupements-pages',
      body: <String, Object?>{
        'texte': filtre.texte,
        'public': filtre.public?.valeurSql,
        'etat': filtre.etat?.name,
        'jour': filtre.jour,
        'heure': filtre.heure,
        'fuseau': filtre.fuseau,
        'page': page,
        'taille': taille,
      },
    );
    if (response.status != 200 || response.data is! Map) {
      throw const FormatException('liste des regroupements indisponible');
    }
    return pageRegroupementsDepuisJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

/// Décode la réponse allowlistée de l'Edge Function.
PageRegroupements pageRegroupementsDepuisJson(Map<String, dynamic> json) {
  final Object? rawRows = json['lignes'];
  if (rawRows is! List) throw const FormatException('lignes absentes');
  final Object? rawCounts = json['compteurs'];
  if (rawCounts is! Map) throw const FormatException('compteurs absents');
  final Map<String, dynamic> counts = Map<String, dynamic>.from(rawCounts);

  return PageRegroupements(
    lignes: rawRows
        .map((Object? row) {
          if (row is! Map) throw const FormatException('regroupement invalide');
          return regroupementDepuisJson(Map<String, dynamic>.from(row));
        })
        .toList(growable: false),
    total: _entier(json, 'total'),
    page: _entier(json, 'page'),
    taille: _entier(json, 'taille'),
    compteurs: <EtatRegroupement, int>{
      for (final EtatRegroupement etat in EtatRegroupement.values)
        etat: _entier(counts, etat.name),
    },
    jours: _entiers(json['jours']),
    heures: _entiers(json['heures']),
    fuseaux: _textes(json['fuseaux']),
    totalSansFiltre: _entier(json, 'total_sans_filtre'),
    demandesSansFiltre: _entier(json, 'demandes_sans_filtre'),
  );
}

/// Décode uniquement les champs autorisés par le contrat C-25.
RegroupementDemandes regroupementDepuisJson(Map<String, dynamic> json) {
  final String typePublic = _texte(json, 'type_public');
  if (typePublic != 'enfant' && typePublic != 'adulte') {
    throw const FormatException('type_public invalide');
  }
  final List<OccurrenceCreneau> occurrences = _objets(json['occurrences'])
      .map(
        (Map<String, dynamic> row) => OccurrenceCreneau(
          jourIso: _int(row, 'jour_iso'),
          heure: _int(row, 'heure'),
          minute: _int(row, 'minute', fallback: 0),
        ),
      )
      .toList(growable: false);
  final Object? rawClasse = json['classe'];
  final ClasseSansEnseignant? classe = rawClasse == null
      ? null
      : _classe(rawClasse);

  return RegroupementDemandes(
    id: _texte(json, 'regroupement_id'),
    public: PublicOffre.depuisSql(typePublic),
    langueCode: _texte(json, 'langue_code'),
    langueNom: _texte(json, 'langue_nom'),
    fuseau: _texte(json, 'fuseau_iana'),
    occurrences: occurrences,
    nombreEleves: _entier(json, 'nombre_eleves'),
    quota: _entier(json, 'quota'),
    autresFuseaux: _objets(json['autres_fuseaux'])
        .map(
          (Map<String, dynamic> row) => HeureDansFuseau(
            fuseau: _texte(row, 'fuseau'),
            jourIso: _nullableInt(row['jour_iso']),
            heure: _int(row, 'heure'),
            minute: _int(row, 'minute', fallback: 0),
            decalageJour: _int(row, 'decalage_jour', fallback: 0),
          ),
        )
        .toList(growable: false),
    peutCreerClasse: _booleen(json, 'peut_creer_classe'),
    classe: classe,
    classesPossibles: _nullableInt(json['classes_possibles']),
    numeroProchaineClasse: _nullableInt(json['numero_prochaine_classe']),
    minimum: _nullableInt(json['minimum']),
    classesExistantes: _nullableInt(json['classes_existantes']),
  );
}

ClasseSansEnseignant _classe(Object? raw) {
  if (raw is! Map) throw const FormatException('classe invalide');
  final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
  final GenreClasse? genre = switch (row['genre_classe']) {
    'hommes' => GenreClasse.hommes,
    'femmes' => GenreClasse.femmes,
    'indetermine' => GenreClasse.indetermine,
    null => null,
    _ => throw const FormatException('genre de classe invalide'),
  };
  return ClasseSansEnseignant(
    classeId: _texte(row, 'classe_id'),
    libelle: _texte(row, 'libelle'),
    genre: genre,
    peutAffecterEnseignant: _booleen(row, 'peut_affecter_enseignant'),
    codeCourt: row['code_court'] as String?,
    numeroDansFamille: _nullableInt(row['numero_dans_famille']),
  );
}

List<Map<String, dynamic>> _objets(Object? value) {
  if (value == null) return const <Map<String, dynamic>>[];
  if (value is! List) throw const FormatException('liste invalide');
  return value
      .map((Object? row) {
        if (row is! Map) throw const FormatException('ligne invalide');
        return Map<String, dynamic>.from(row);
      })
      .toList(growable: false);
}

List<int> _entiers(Object? value) {
  if (value is! List) throw const FormatException('liste numérique invalide');
  return value
      .map((Object? item) => _nullableInt(item) ?? _erreurInt('élément'))
      .toList(growable: false);
}

List<String> _textes(Object? value) {
  if (value is! List || value.any((Object? item) => item is! String)) {
    throw const FormatException('liste texte invalide');
  }
  return value.cast<String>();
}

String _texte(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  if (value is! String) throw FormatException('$key absent');
  return value;
}

int _entier(Map<String, dynamic> row, String key) => _int(row, key);

int _int(Map<String, dynamic> row, String key, {int? fallback}) {
  final Object? value = row[key];
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? (fallback ?? _erreurInt(key));
  }
  if (fallback != null) return fallback;
  return _erreurInt(key);
}

int _erreurInt(String key) => throw FormatException('$key invalide');

int? _nullableInt(Object? value) =>
    value == null ? null : _int(<String, Object?>{'v': value}, 'v');

bool _booleen(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  if (value is! bool) throw FormatException('$key invalide');
  return value;
}
