// Adaptateur COURRIELS-1 : les RPC de la migration 20261023120000
// (`admin_courriel_envoyer`, `admin_courriels_lister`,
// `admin_courriel_reessayer`, `admin_courriel_categories`).
//
// Erreurs : une fonction absente du serveur (PGRST202) se dit
// [CapaciteIndisponible] ; un refus (42501 : pas la direction) se dit
// [PermissionInsuffisante] ; `22023` sur un envoi devient [CourrielInvalide]
// (le message du serveur est le champ), `P0002` sur une relance devient
// [CourrielIntrouvable]. Toute autre erreur (reseau, serveur) remonte telle
// quelle : l'ecran ne dit jamais un succes qu'il ignore.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'permission_insuffisante.dart';
import 'port_courriels.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'COURRIELS-1';

/// Les e-mails sortants servis par Supabase.
class CourrielsSupabase implements PortCourriels {
  /// Cree l'adaptateur sur le client de l'application.
  CourrielsSupabase(SupabaseClient client) : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  CourrielsSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  Future<Object?> _appeler(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      return await appelerFinance(_appel, fonction, _dependance, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const PermissionInsuffisante(_dependance);
      rethrow;
    }
  }

  @override
  Future<String> envoyer({
    required String categorie,
    required String sujet,
    required String corps,
    required String cle,
    String? adresse,
    String? profil,
  }) async {
    final String? propre = adresse?.trim();
    try {
      final Object? id = await _appeler(
        'admin_courriel_envoyer',
        <String, dynamic>{
          'p_profil': profil,
          'p_adresse': propre == null || propre.isEmpty ? null : propre,
          'p_categorie': categorie,
          'p_sujet': sujet.trim(),
          'p_corps': corps.trim(),
          'p_cle': cle,
        },
      );
      if (id is String && id.isNotEmpty) return id;
      throw const FormatException(
        'identifiant invalide: admin_courriel_envoyer',
      );
    } on PostgrestException catch (e) {
      if (e.code == '22023') {
        throw CourrielInvalide(ChampCourriel.depuisServeur(e.message));
      }
      rethrow;
    }
  }

  @override
  Future<List<CourrielSortant>> lister({
    StatutCourriel? statut,
    int limite = 100,
  }) async {
    final Object? brut = await _appeler(
      'admin_courriels_lister',
      <String, dynamic>{'p_statut': statut?.sql, 'p_limite': limite},
    );
    return List<CourrielSortant>.unmodifiable(<CourrielSortant>[
      for (final Object? ligne in _liste(brut, 'courriels'))
        courrielDepuis(objetJson(ligne, 'courriel')),
    ]);
  }

  @override
  Future<void> reessayer(String id) async {
    try {
      await _appeler('admin_courriel_reessayer', <String, dynamic>{'p_id': id});
    } on PostgrestException catch (e) {
      if (e.code == 'P0002') throw const CourrielIntrouvable();
      rethrow;
    }
  }

  @override
  Future<List<CategorieCourriel>> categories() async {
    final Object? brut = await _appeler('admin_courriel_categories');
    return List<CategorieCourriel>.unmodifiable(<CategorieCourriel>[
      for (final Object? ligne in _liste(brut, 'categories'))
        categorieDepuis(objetJson(ligne, 'categorie')),
    ]);
  }
}

List<Object?> _liste(Object? brut, String cle) =>
    brut == null ? const <Object?>[] : listeJson(brut, cle);

/// Une ligne de `admin_courriels_lister`. Pure, testee.
CourrielSortant courrielDepuis(Map<String, dynamic> j) {
  final StatutCourriel? statut = StatutCourriel.depuisSql(
    texteJson(j, 'statut'),
  );
  final OrigineCourriel? origine = OrigineCourriel.depuisSql(
    texteJson(j, 'origine'),
  );
  if (statut == null) throw FormatException('statut inconnu: ${j['statut']}');
  if (origine == null) {
    throw FormatException('origine inconnue: ${j['origine']}');
  }
  final Object? envoye = j['envoye_le'];
  return CourrielSortant(
    id: texteJson(j, 'id'),
    categorie: texteJson(j, 'categorie'),
    modele: texteJson(j, 'modele'),
    destinataire: texteJson(j, 'destinataire_adresse'),
    origine: origine,
    statut: statut,
    tentatives: entierJson(j, 'tentatives'),
    derniereErreur: texteNullableJson(j, 'derniere_erreur'),
    creeLe: instantJson(j['cree_le'], 'cree_le'),
    envoyeLe: envoye == null ? null : instantJson(envoye, 'envoye_le'),
    sujet: texteNullableJson(j, 'sujet'),
  );
}

/// Une ligne de `admin_courriel_categories`. Pure, testee.
CategorieCourriel categorieDepuis(Map<String, dynamic> j) => CategorieCourriel(
  code: texteJson(j, 'code'),
  libelle: texteJson(j, 'libelle'),
  expediteurAdresse: texteJson(j, 'expediteur_adresse'),
  expediteurNom: texteJson(j, 'expediteur_nom'),
  repondreA: texteJson(j, 'repondre_a'),
  essentielle: booleenJson(j, 'essentielle'),
  active: booleenJson(j, 'active'),
);
