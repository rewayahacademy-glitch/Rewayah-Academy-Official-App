// L'adaptateur Supabase des autres competences (`PortAutresCompetences`,
// `PortCatalogueCompetences`), sur les RPC du lot CAND-AUTRES
// (`20261022000500_cand_autres_competences.sql`) :
// `lire_autres_competences`, `enregistrer_autres_competences`,
// `retirer_autres_competences` et `lire_catalogue_competences`.
//
// Les refus metier arrivent **dans la reponse** (`{"erreur": "..."}`), jamais
// en exception : le serveur les rend pour qu'ils ne laissent aucune ecriture.
// 42501 dit « non autorise » (pas le titulaire d'une candidature d'enseignant,
// ou compte non valide). 22023 dit un argument mal forme (jamais envoye par
// l'ecran) : il remonte tel quel. Une fonction que le serveur ne connait pas
// encore (lot non verse) est une capacite indisponible, pas une panne a
// reessayer. Une panne de reseau devient [HorsLigneCandidature] : ce qui a ete
// envoye est alors non confirme, et l'ecran le dit.
//
// L'adaptateur ne decide rien : il ne valide pas les reponses, ne choisit pas
// les competences offertes et ne calcule aucun niveau.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'modeles_autres_competences.dart';
import 'modeles_candidature.dart';
import 'port_autres_competences.dart';
import 'port_ma_candidature.dart';

/// Appelle une RPC. Une fonction absente du serveur est une capacite
/// indisponible.
Future<Object?> _appel(
  SupabaseClient client,
  String fonction, [
  Map<String, dynamic>? params,
]) async {
  try {
    return await client.rpc<Object?>(fonction, params: params);
  } on PostgrestException catch (e) {
    if (e.code == '42501') {
      throw PermissionInsuffisante(fonction);
    }
    // PGRST202 : fonction absente du cache de schema ; 42883 : fonction
    // inconnue de la base. Le lot serveur n'est pas encore verse.
    if (e.code == 'PGRST202' || e.code == '42883') {
      throw const CapaciteIndisponible(dependanceAutresCompetences);
    }
    rethrow;
  } on FormatException {
    rethrow;
  } on Exception {
    throw const HorsLigneCandidature();
  }
}

/// Les autres competences du candidat servies par Supabase.
class AutresCompetencesSupabase implements PortAutresCompetences {
  /// Cree l'adaptateur sur le client de l'application.
  const AutresCompetencesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<AutresCompetences> lire() async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'lire_autres_competences'),
    );
    return AutresCompetences.depuisJson(brut);
  }

  @override
  Future<ResultatEnregistrement> enregistrer({
    required Map<String, NiveauCompetence> domaines,
    required DisponibiliteMission disponibilite,
    required bool accord,
    required int versionAttendue,
    required String cleIdempotence,
    String? autreTexte,
  }) async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'enregistrer_autres_competences', <String, dynamic>{
        'p_domaines': <String, String>{
          for (final MapEntry<String, NiveauCompetence> e in domaines.entries)
            e.key: e.value.valeurSql,
        },
        'p_autre_texte': autreTexte,
        'p_disponibilite': disponibilite.valeurSql,
        'p_accord': accord,
        'p_version_attendue': versionAttendue,
        'p_cle_idempotence': cleIdempotence,
      }),
    );
    _refus(brut);
    return ResultatEnregistrement.depuisJson(brut);
  }

  @override
  Future<ResultatRetrait> retirer({
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'retirer_autres_competences', <String, dynamic>{
        'p_version_attendue': versionAttendue,
        'p_cle_idempotence': cleIdempotence,
      }),
    );
    _refus(brut);
    return ResultatRetrait.depuisJson(brut);
  }
}

/// Le catalogue des competences servi par Supabase (lecture).
class CatalogueCompetencesSupabase implements PortCatalogueCompetences {
  /// Cree l'adaptateur sur le client de l'application.
  const CatalogueCompetencesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<CatalogueCompetences> lire() async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'lire_catalogue_competences'),
    );
    return CatalogueCompetences.depuisJson(brut);
  }
}

/// Traduit un refus rendu par le serveur en exception typee.
void _refus(Map<String, dynamic> brut) {
  final Object? erreur = brut['erreur'];
  if (erreur == null) {
    return;
  }
  List<String> champs() => <String>[
    if (brut['champs'] is List)
      for (final Object? c in brut['champs'] as List)
        if (c is String) c,
  ];
  Map<String, String> motifs() => <String, String>{
    if (brut['motifs'] is Map)
      for (final MapEntry<Object?, Object?> e
          in (brut['motifs'] as Map<Object?, Object?>).entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
  };
  switch (erreur) {
    case 'questionnaire_non_envoye':
      throw const QuestionnaireNonEnvoye();
    case 'candidature_close':
      throw CandidatureClose(
        brut['issue'] is String
            ? IssueCandidature.depuisSql(brut['issue'])
            : null,
      );
    case 'conflit_autres_competences':
      final Object? version = brut['versionCourante'];
      throw ConflitAutresCompetences(version is int ? version : null);
    case 'reponses_invalides':
      throw ReponsesAutresCompetencesInvalides(champs(), motifs: motifs());
    case 'cle_idempotence_reutilisee':
      throw const CleAutresCompetencesReutilisee();
    default:
      throw FormatException('Refus inconnu : $erreur');
  }
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) {
    throw const FormatException('Objet attendu.');
  }
  return Map<String, dynamic>.from(v);
}
