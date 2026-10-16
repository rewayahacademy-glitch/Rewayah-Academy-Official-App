import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import 'offre_horaire.dart' show NiveauDeclare, PublicOffre;
import 'port_regroupements_admin.dart';

/// Adaptateur Supabase des regroupements C-11 bis/F74.
///
/// Les clés, le public de genre, le niveau et l'éligibilité sont fournis ou
/// validés par PostgreSQL. Le paramètre `genre` historique du port est ignoré
/// à l'appel RPC : le client ne peut donc pas choisir le genre de la classe.
class RegroupementsC11bisSupabase implements PortRegroupementsAdmin {
  const RegroupementsC11bisSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RegroupementDemandes>> regroupements() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'regroupements_c11bis_admin',
    );
    return lignes
        .map((dynamic ligne) => _depuisJson(ligne as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ResultatCreationClasse> creerClasse({
    required String regroupementId,
    required GenreClasse genre,
    required String libelle,
    required String cleEnvoi,
  }) async {
    if (!_uuid.hasMatch(regroupementId) || !_uuid.hasMatch(cleEnvoi)) {
      throw const FormatException('Identifiant UUID invalide pour C-11 bis.');
    }
    final List<RegroupementDemandes> avant = await regroupements();
    final RegroupementDemandes? cible = avant
        .where((RegroupementDemandes r) => r.id == regroupementId)
        .firstOrNull;
    if (cible?.aCompleter == true) {
      return const CreationRefusee('regroupement_incoherent');
    }
    final String groupeId = await _client.rpc<String>(
      'creer_classe_depuis_regroupement',
      params: <String, dynamic>{
        'p_regroupement_id': regroupementId,
        'p_cle_idempotence': cleEnvoi,
        'p_libelle': libelle,
      },
    );
    if (cible?.classe?.classeId == groupeId) {
      return const CreationDejaFaite();
    }
    return ClasseCreee(
      classe: ClasseSansEnseignant(
        classeId: groupeId,
        libelle: libelle,
        genre: cible?.genrePublic,
      ),
      elevesIntegres: cible == null
          ? 0
          : (cible.nombreEleves < cible.quota
                ? cible.nombreEleves
                : cible.quota),
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

  RegroupementDemandes _depuisJson(Map<String, dynamic> json) {
    final List<dynamic> occurrences = _liste(json['occurrences']);
    final List<dynamic> autres = _liste(json['autres_fuseaux']);
    final Map<String, dynamic>? classeJson = _objet(json['classe']);
    final String? genreSql = json['genre_public'] as String?;
    final String? niveauSql = json['niveau'] as String?;
    final bool incomplete = json['etat'] == 'a_completer';
    return RegroupementDemandes(
      id: json['regroupement_id'] as String,
      public: PublicOffre.depuisSql(json['type_public'] as String?),
      langueCode: json['langue_code'] as String,
      langueNom: json['langue_nom'] as String,
      genrePublic: _genre(genreSql),
      niveau: NiveauDeclare.depuisSql(niveauSql),
      aCompleter: incomplete,
      motifACompleter: json['motif_a_completer'] as String?,
      fuseau: json['fuseau_iana'] as String,
      occurrences: occurrences.map((dynamic raw) {
        final Map<String, dynamic> ligne = raw as Map<String, dynamic>;
        return OccurrenceCreneau(
          jourIso: _entier(ligne['jour_iso']),
          heure: _entier(ligne['heure']),
          minute: _entier(ligne['minute'] ?? 0),
        );
      }),
      autresFuseaux: <HeureDansFuseau>[
        for (final dynamic raw in autres)
          _heureDansFuseau(raw as Map<String, dynamic>),
      ],
      nombreEleves: _entier(json['nombre_eleves']),
      quota: _entier(json['quota']),
      peutCreerClasse: json['peut_creer_classe'] == true && !incomplete,
      classe: classeJson == null
          ? null
          : ClasseSansEnseignant(
              classeId: _classeId(classeJson['classe_id'] as String),
              libelle: classeJson['libelle'] as String,
              genre: _genre(classeJson['genre_classe'] as String?),
              peutAffecterEnseignant:
                  classeJson['peut_affecter_enseignant'] == true,
            ),
    );
  }

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static int _entier(Object? valeur) => switch (valeur) {
    final int n => n,
    final num n => n.toInt(),
    _ => int.parse('$valeur'),
  };

  static List<dynamic> _liste(Object? valeur) =>
      valeur is List<dynamic> ? valeur : const <dynamic>[];

  static Map<String, dynamic>? _objet(Object? valeur) =>
      valeur is Map<String, dynamic> ? valeur : null;

  static GenreClasse? _genre(String? valeur) => switch (valeur) {
    'hommes' => GenreClasse.hommes,
    'femmes' => GenreClasse.femmes,
    _ => null,
  };

  static HeureDansFuseau _heureDansFuseau(Map<String, dynamic> ligne) =>
      HeureDansFuseau(
        fuseau: ligne['fuseau'] as String,
        jourIso: int.tryParse('${ligne['jour_iso']}'),
        heure: _entier(ligne['heure']),
        minute: _entier(ligne['minute'] ?? 0),
        decalageJour: _entier(ligne['decalage_jour'] ?? 0),
      );

  static String _classeId(String value) =>
      value.startsWith('g:') ? value.substring(2) : value;
}
