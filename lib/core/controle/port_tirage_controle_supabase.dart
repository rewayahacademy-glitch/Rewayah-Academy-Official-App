import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_tirage_controle.dart';

/// Adaptateur du contrat de tirage versionne cote serveur.
class PortTirageControleSupabase implements PortTirageControle {
  const PortTirageControleSupabase(this._client);

  final SupabaseClient _client;

  static Map<String, dynamic> _object(Object? value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((Object? k, Object? v) => MapEntry('$k', v));
    }
    throw FormatException('$name: objet JSON attendu');
  }

  static List<dynamic> _list(Object? value, String name) {
    if (value is List) return value;
    throw FormatException('$name: liste JSON attendue');
  }

  static int _int(Object? value, String name) {
    if (value is int) return value;
    throw FormatException('$name: entier attendu');
  }

  static String _string(Object? value, String name) {
    if (value is String) return value;
    throw FormatException('$name: texte attendu');
  }

  static T _enum<T extends Enum>(List<T> values, Object? value, String name) {
    final String raw = _string(value, name);
    return values.firstWhere(
      (T item) => item.name == raw,
      orElse: () => throw FormatException('$name: valeur inconnue ($raw)'),
    );
  }

  static void _throwServerError(Map<String, dynamic> json) {
    final Object? message = json['erreur'];
    if (message is String) throw PostgrestException(message: message);
  }

  @override
  Future<AccesTirage> acces() async {
    final Map<String, dynamic> json = _object(
      await _client.rpc('capacites_tirage_controle'),
      'capacites_tirage_controle',
    );
    if (json['peut_lire'] is! bool || json['peut_modifier'] is! bool) {
      throw const FormatException(
        'capacites_tirage_controle: booleens attendus',
      );
    }
    return AccesTirage(
      peutLire: json['peut_lire'] as bool,
      peutModifier: json['peut_modifier'] as bool,
    );
  }

  @override
  Future<ReglesTirage> regles() async {
    final Map<String, dynamic> json = _object(
      await _client.rpc('lire_regles_tirage'),
      'lire_regles_tirage',
    );
    _throwServerError(json);
    final Map<String, dynamic> weights = _object(
      json['ponderations'],
      'ponderations',
    );
    final Map<CriterePonderation, NiveauPonderation> parsedWeights = {};
    for (final CriterePonderation criterion in CriterePonderation.values) {
      final String key = switch (criterion) {
        CriterePonderation.enseignantsRecents => 'enseignants_recents',
        CriterePonderation.classesSignalees => 'classes_signalees',
        CriterePonderation.heuresDePointe => 'heures_de_pointe',
      };
      parsedWeights[criterion] = _enum(
        NiveauPonderation.values,
        weights[key],
        key,
      );
    }
    final List<CibleTirage> targets = _list(json['cibles'], 'cibles')
        .map((Object? item) {
          final Map<String, dynamic> row = _object(item, 'cible');
          return CibleTirage(
            id: _string(row['id'], 'cible.id'),
            type: _enum(TypeCible.values, row['type'], 'cible.type'),
            libelle: _string(row['libelle'], 'cible.libelle'),
          );
        })
        .toList(growable: false);
    return ReglesTirage(
      version: _int(json['version'], 'version'),
      missionsParSemaine: _int(
        json['missions_par_semaine'],
        'missions_par_semaine',
      ),
      ponderations: parsedWeights,
      cibles: targets,
    );
  }

  @override
  Future<ResultatRegles> enregistrer(
    ReglesTirage regles, {
    required String cleEnvoi,
  }) async {
    final Map<String, dynamic> payload = {
      'missions_par_semaine': regles.missionsParSemaine,
      'ponderations': {
        for (final MapEntry<CriterePonderation, NiveauPonderation> entry
            in regles.ponderations.entries)
          switch (entry.key) {
            CriterePonderation.enseignantsRecents => 'enseignants_recents',
            CriterePonderation.classesSignalees => 'classes_signalees',
            CriterePonderation.heuresDePointe => 'heures_de_pointe',
          }: entry.value.name,
      },
      'cibles': regles.cibles
          .map(
            (CibleTirage target) => {'id': target.id, 'type': target.type.name},
          )
          .toList(growable: false),
    };
    final Map<String, dynamic> result = _object(
      await _client.rpc(
        'enregistrer_regles_tirage',
        params: {'p_regles': payload, 'p_cle': cleEnvoi},
      ),
      'enregistrer_regles_tirage',
    );
    _throwServerError(result);
    return result['statut'] == 'enregistrees'
        ? ReglesEnregistrees(version: _int(result['version'], 'version'))
        : ReglesRefusees(_string(result['erreur'], 'erreur'));
  }

  @override
  Future<List<CibleTirage>> candidatsCible() async {
    final Map<String, dynamic> json = _object(
      await _client.rpc('candidats_cible_tirage'),
      'candidats_cible_tirage',
    );
    _throwServerError(json);
    return _list(json['cibles'], 'cibles')
        .map((Object? item) {
          final Map<String, dynamic> row = _object(item, 'cible');
          return CibleTirage(
            id: _string(row['id'], 'cible.id'),
            type: _enum(TypeCible.values, row['type'], 'cible.type'),
            libelle: _string(row['libelle'], 'cible.libelle'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<PageTirages> tirages(
    FiltreTirages filtre, {
    required int page,
    required int taille,
  }) async {
    final Map<String, dynamic> json = _object(
      await _client.rpc(
        'historique_tirages',
        params: {
          'p_statut': filtre.statut?.name,
          'p_texte': filtre.texte,
          'p_page': page,
          'p_taille': taille,
        },
      ),
      'historique_tirages',
    );
    _throwServerError(json);
    final Map<String, dynamic> rawCounts = _object(
      json['compteurs'],
      'compteurs',
    );
    final Map<StatutTirage, int> counts = {
      for (final StatutTirage status in StatutTirage.values)
        status: rawCounts[status.name] == null
            ? 0
            : _int(rawCounts[status.name], 'compteurs.${status.name}'),
    };
    final List<TirageAudite> rows = _list(json['lignes'], 'lignes')
        .map((Object? item) {
          final Map<String, dynamic> row = _object(item, 'ligne');
          final Object? report = row['rapport_envoye'];
          if (report is! bool)
            throw const FormatException('rapport_envoye: booleen attendu');
          return TirageAudite(
            id: _string(row['id'], 'id'),
            quand: DateTime.parse(_string(row['quand'], 'quand')).toLocal(),
            classe: _string(row['classe'], 'classe'),
            enseignant: _string(row['enseignant'], 'enseignant'),
            controleur: _string(row['controleur'], 'controleur'),
            statut: _enum(StatutTirage.values, row['statut'], 'statut'),
            critere: _enum(CritereTirage.values, row['critere'], 'critere'),
            rapportEnvoye: report,
          );
        })
        .toList(growable: false);
    return PageTirages(
      lignes: rows,
      total: _int(json['total'], 'total'),
      page: _int(json['page'], 'page'),
      taille: _int(json['taille'], 'taille'),
      compteurs: counts,
      totalSansFiltre: _int(json['total_sans_filtre'], 'total_sans_filtre'),
    );
  }

  @override
  Future<void> declarerConflit(
    String missionId, {
    required String cleConflit,
  }) async {
    final Map<String, dynamic> result = _object(
      await _client.rpc(
        'declarer_conflit_mission',
        params: {'p_mission_id': missionId, 'p_cle': cleConflit},
      ),
      'declarer_conflit_mission',
    );
    _throwServerError(result);
    if (_string(result['statut'], 'statut') != 'conflit_declare') {
      throw const FormatException(
        'declarer_conflit_mission: statut de confirmation inattendu',
      );
    }
  }
}
