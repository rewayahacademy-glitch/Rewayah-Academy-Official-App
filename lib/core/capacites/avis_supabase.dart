// Adaptateur AVIS-PUBLICS : les RPC de la migration 20261019120000
// (`avis_lien_etat`, `avis_deposer`, `avis_lien_creer`, `avis_liens_lister`,
// `avis_lien_fermer`, `avis_lister_admin`, `avis_moderer`).
//
// Erreurs : une fonction absente du serveur (PGRST202) se dit
// [CapaciteIndisponible] ; un refus (42501 : pas la direction) se dit
// [PermissionInsuffisante] ; `22023` sur un depot devient [ChampAvisInvalide]
// (le message du serveur est le nom du champ), `P0002` devient [LienAvisFerme] ;
// sur la moderation, `P0002`, `55000` et `22023` deviennent un
// [ModerationAvisRefusee]. Toute autre erreur (reseau, serveur) remonte telle
// quelle : l'ecran ne dit jamais un succes qu'il ignore.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'permission_insuffisante.dart';
import 'port_avis.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'AVIS-PUBLICS';

/// Les avis servis par Supabase.
class AvisSupabase implements PortAvis {
  /// Cree l'adaptateur sur le client de l'application.
  AvisSupabase(SupabaseClient client) : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  AvisSupabase.avecAppel(this._appel);

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
  Future<bool> lienOuvert(String jeton) async {
    final Map<String, dynamic> j = objetJson(
      await _appeler('avis_lien_etat', <String, dynamic>{'p_jeton': jeton}),
      'avis_lien_etat',
    );
    return booleenJson(j, 'ouvert');
  }

  @override
  Future<void> deposer(String jeton, DepotAvis avis) async {
    try {
      await _appeler('avis_deposer', parametresDepot(jeton, avis));
    } on PostgrestException catch (e) {
      if (e.code == '22023') {
        throw ChampAvisInvalide(ChampAvis.depuisServeur(e.message));
      }
      if (e.code == 'P0002') throw const LienAvisFerme();
      rethrow;
    }
  }

  @override
  Future<LienAvisCree> creerLien({
    required String libelle,
    required int jours,
    required int avisMax,
  }) async {
    final Map<String, dynamic> j = objetJson(
      await _appeler('avis_lien_creer', <String, dynamic>{
        'p_libelle': libelle.trim(),
        'p_jours': jours,
        'p_avis_max': avisMax,
      }),
      'avis_lien_creer',
    );
    return LienAvisCree(
      id: texteJson(j, 'id'),
      jeton: texteJson(j, 'jeton'),
      expireLe: instantJson(j['expire_le'], 'expire_le'),
    );
  }

  @override
  Future<List<LienAvis>> listerLiens() async {
    final Object? brut = await _appeler('avis_liens_lister');
    return List<LienAvis>.unmodifiable(<LienAvis>[
      for (final Object? ligne in _liste(brut, 'liens'))
        lienDepuis(objetJson(ligne, 'lien')),
    ]);
  }

  @override
  Future<void> fermerLien(String id) async {
    await _appeler('avis_lien_fermer', <String, dynamic>{'p_id': id});
  }

  @override
  Future<List<AvisAdmin>> listerAvis({StatutAvis? statut}) async {
    final Object? brut = await _appeler('avis_lister_admin', <String, dynamic>{
      'p_statut': statut?.sql,
    });
    return List<AvisAdmin>.unmodifiable(<AvisAdmin>[
      for (final Object? ligne in _liste(brut, 'avis'))
        avisDepuis(objetJson(ligne, 'avis')),
    ]);
  }

  @override
  Future<void> moderer(String id, StatutAvis statut, {String? motif}) async {
    final String? propre = motif?.trim();
    try {
      await _appeler('avis_moderer', <String, dynamic>{
        'p_id': id,
        'p_statut': statut.sql,
        'p_motif': propre == null || propre.isEmpty ? null : propre,
      });
    } on PostgrestException catch (e) {
      final RefusModeration? raison = switch (e.code) {
        'P0002' => RefusModeration.introuvable,
        // Le serveur nomme le champ fautif : `motif`, ou `statut` quand
        // l'avis a deja change d'etat (transition refusee).
        '22023' when e.message == 'motif' => RefusModeration.motifManquant,
        '22023' || '55000' => RefusModeration.etatChange,
        _ => null,
      };
      if (raison == null) rethrow;
      throw ModerationAvisRefusee(raison);
    }
  }
}

/// Une liste serveur ; `null` (aucune ligne, selon la forme du jsonb) vaut une
/// liste vide, tout autre type est une erreur.
List<Object?> _liste(Object? brut, String cle) =>
    brut == null ? const <Object?>[] : listeJson(brut, cle);

/// Les parametres de `avis_deposer`. Pure, testee : le mois part au premier
/// jour (`AAAA-MM-01`), un titre vide part nul.
Map<String, dynamic> parametresDepot(String jeton, DepotAvis a) {
  final String titre = (a.titre ?? '').trim();
  return <String, dynamic>{
    'p_jeton': jeton,
    'p_nom': a.nom.trim(),
    'p_qualite': a.qualite.sql,
    'p_pays': a.pays.toUpperCase(),
    'p_depuis':
        '${a.depuis.year.toString().padLeft(4, '0')}'
        '-${a.depuis.month.toString().padLeft(2, '0')}-01',
    'p_note': a.note,
    'p_titre': titre.isEmpty ? null : titre,
    'p_texte': a.texte.trim(),
    'p_accord': a.accord,
  };
}

/// Un lien lu d'une ligne de `avis_liens_lister`. Pure, testee.
LienAvis lienDepuis(Map<String, dynamic> j) => LienAvis(
  id: texteJson(j, 'id'),
  libelle: texteJson(j, 'libelle'),
  creeLe: instantJson(j['cree_le'], 'cree_le'),
  expireLe: instantJson(j['expire_le'], 'expire_le'),
  avisMax: entierJson(j, 'avis_max'),
  avisRecus: entierJson(j, 'avis_recus'),
  ferme: booleenJson(j, 'ferme'),
  actif: booleenJson(j, 'actif'),
);

/// Un avis lu d'une ligne de `avis_lister_admin`. Pure, testee.
AvisAdmin avisDepuis(Map<String, dynamic> j) {
  final StatutAvis? statut = StatutAvis.depuisSql(texteJson(j, 'statut'));
  final QualiteAvis? qualite = QualiteAvis.depuisSql(texteJson(j, 'qualite'));
  if (statut == null) throw FormatException('statut inconnu: ${j['statut']}');
  if (qualite == null) {
    throw FormatException('qualite inconnue: ${j['qualite']}');
  }
  final Object? accord = j['accord_public_le'];
  final Object? modere = j['modere_le'];
  final Object? publie = j['publie_le'];
  return AvisAdmin(
    id: texteJson(j, 'id'),
    lienLibelle: texteNullableJson(j, 'lien_libelle'),
    nomAffiche: texteJson(j, 'nom_affiche'),
    qualite: qualite,
    pays: texteJson(j, 'pays').trim().toUpperCase(),
    depuis: dateJson(j['depuis'], 'depuis'),
    note: entierJson(j, 'note'),
    titre: texteNullableJson(j, 'titre'),
    texte: texteJson(j, 'texte'),
    accordPublicLe: accord == null
        ? null
        : instantJson(accord, 'accord_public_le'),
    statut: statut,
    motif: texteNullableJson(j, 'motif'),
    deposeLe: instantJson(j['depose_le'], 'depose_le'),
    modereLe: modere == null ? null : instantJson(modere, 'modere_le'),
    publieLe: publie == null ? null : instantJson(publie, 'publie_le'),
  );
}
