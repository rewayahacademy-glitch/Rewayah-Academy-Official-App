// Adaptateur SUPPRIMER : `direction_supprimer_comptes`,
// `retraits_comptes_lister`, `direction_restaurer_comptes` (direction en
// double verification) et `tuteur_supprimer_profil_enfant` (migrations
// 20261108600000 et 20261108900000).
//
// Erreurs : une fonction absente (PGRST202) se dit [CapaciteIndisponible] ; un
// refus de droit (42501) se dit [PermissionInsuffisante], sauf
// `profil_hors_foyer`, refus metier du tuteur ; toute autre erreur (reseau,
// serveur) remonte telle quelle : l'ecran ne dit jamais un succes qu'il
// ignore. Les refus par compte arrivent dans le resultat, jamais en erreur.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'permission_insuffisante.dart';
import 'port_retraits_comptes.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'SUPPRIMER';

/// Les retraits de comptes servis par Supabase.
class RetraitsComptesSupabase implements PortRetraitsComptes {
  /// Cree l'adaptateur sur le client de l'application.
  RetraitsComptesSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  RetraitsComptesSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) async {
    final String? m = motif?.trim();
    final Object? brut = await _appeler(
      'direction_supprimer_comptes',
      <String, dynamic>{
        'p_ids': ids,
        'p_motif': (m == null || m.isEmpty) ? null : m,
        'p_anonymiser_maintenant': anonymiserMaintenant,
      },
    );
    return List<ResultatRetrait>.unmodifiable(<ResultatRetrait>[
      for (final Object? l in listeJson(brut, 'resultats'))
        resultatRetraitDepuis(objetJson(l, 'resultat')),
    ]);
  }

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) async {
    final Object? brut = await _appeler(
      'retraits_comptes_lister',
      <String, dynamic>{
        'p_etat': etatSql(etat),
        'p_apres_le': apres?.apresLe.toUtc().toIso8601String(),
        'p_apres_id': apres?.apresId,
      },
    );
    return pageRetraitsDepuis(objetJson(brut, 'page'));
  }

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) async {
    final Object? brut = await _appeler(
      'direction_restaurer_comptes',
      <String, dynamic>{'p_ids': ids},
    );
    return List<ResultatRestauration>.unmodifiable(<ResultatRestauration>[
      for (final Object? l in listeJson(brut, 'resultats'))
        resultatRestaurationDepuis(objetJson(l, 'resultat')),
    ]);
  }

  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(
    String eleveId,
  ) async {
    try {
      await appelerFinance(
        _appel,
        'tuteur_supprimer_profil_enfant',
        _dependance,
        <String, dynamic>{'p_eleve': eleveId},
      );
      return ResultatSuppressionEnfant.retire;
    } on PostgrestException catch (e) {
      final ResultatSuppressionEnfant? refus = refusSuppressionEnfant(e);
      if (refus != null) return refus;
      if (e.code == '42501') throw const PermissionInsuffisante(_dependance);
      rethrow;
    }
  }

  Future<Object?> _appeler(String fonction, Map<String, dynamic> params) async {
    try {
      return await appelerFinance(_appel, fonction, _dependance, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const PermissionInsuffisante(_dependance);
      rethrow;
    }
  }
}

/// Le nom SQL d'un etat de la liste. Pur.
String etatSql(EtatRetraits e) => switch (e) {
  EtatRetraits.enCours => 'en_cours',
  EtatRetraits.anonymises => 'anonymises',
  EtatRetraits.restaures => 'restaures',
  EtatRetraits.tous => 'tous',
};

/// La raison d'un refus, ou [RaisonRefusRetrait.erreur] pour une raison
/// inconnue (le compte n'est pas traite, l'ecran le dit). Pure, testee.
RaisonRefusRetrait raisonRefusDepuis(Object? v) => switch (v) {
  'introuvable' => RaisonRefusRetrait.introuvable,
  'deja_retire' => RaisonRefusRetrait.dejaRetire,
  'soi_meme' => RaisonRefusRetrait.soiMeme,
  'compte_direction' => RaisonRefusRetrait.compteDirection,
  'seances_a_venir' => RaisonRefusRetrait.seancesAVenir,
  'aucun_retrait' => RaisonRefusRetrait.aucunRetrait,
  'deja_anonymise' => RaisonRefusRetrait.dejaAnonymise,
  'etat_avant_inconnu' => RaisonRefusRetrait.etatAvantInconnu,
  _ => RaisonRefusRetrait.erreur,
};

/// Le resultat d'un retrait, lu d'une ligne. Pur, teste.
ResultatRetrait resultatRetraitDepuis(Map<String, dynamic> j) {
  final String id = texteJson(j, 'id');
  switch (j['statut']) {
    case 'retire':
      return ResultatRetrait(
        id: id,
        retire: true,
        anonymiserLe: instantJson(j['anonymiser_le'], 'anonymiser_le'),
        anonymise: j['anonymise'] == true,
      );
    case 'refuse':
      final Object? seances = j['seances'];
      return ResultatRetrait(
        id: id,
        retire: false,
        raison: raisonRefusDepuis(j['raison']),
        seancesAVenir: seances is List ? seances.length : 0,
      );
    case final Object? s:
      throw FormatException('statut inconnu: $s');
  }
}

/// Le resultat d'une restauration, lu d'une ligne. Pur, teste.
ResultatRestauration resultatRestaurationDepuis(Map<String, dynamic> j) {
  final String id = texteJson(j, 'id');
  switch (j['statut']) {
    case 'restaure':
      return ResultatRestauration(
        id: id,
        restaure: true,
        classesQuittees: entierJson(j, 'classes_quittees'),
      );
    case 'refuse':
      return ResultatRestauration(
        id: id,
        restaure: false,
        raison: raisonRefusDepuis(j['raison']),
      );
    case final Object? s:
      throw FormatException('statut inconnu: $s');
  }
}

/// Une page de `retraits_comptes_lister`. Pure, testee.
PageRetraits pageRetraitsDepuis(Map<String, dynamic> j) {
  final Object? suivant = j['suivant'];
  return PageRetraits(
    lignes: List<RetraitCompte>.unmodifiable(<RetraitCompte>[
      for (final Object? l in listeJson(j['lignes'], 'lignes'))
        retraitDepuis(objetJson(l, 'ligne')),
    ]),
    suivant: suivant == null ? null : _curseur(objetJson(suivant, 'suivant')),
  );
}

CurseurRetraits _curseur(Map<String, dynamic> j) => CurseurRetraits(
  apresLe: instantJson(j['apres_le'], 'apres_le'),
  apresId: texteJson(j, 'apres_id'),
);

/// Un retrait, lu d'une ligne. Pur, teste.
RetraitCompte retraitDepuis(Map<String, dynamic> j) {
  final Object? anonymise = j['anonymise_le'];
  final Object? restaure = j['restaure_le'];
  return RetraitCompte(
    retraitId: texteJson(j, 'retrait_id'),
    profilId: texteJson(j, 'profile_id'),
    matricule: texteNullableJson(j, 'matricule') ?? '',
    nom: texteNullableJson(j, 'nom') ?? '',
    role: AppRole.depuisSql(texteNullableJson(j, 'role')),
    source: switch (j['source']) {
      'direction' => SourceRetrait.direction,
      'tuteur' => SourceRetrait.tuteur,
      final Object? s => throw FormatException('source inconnue: $s'),
    },
    motif: texteNullableJson(j, 'motif'),
    retireLe: instantJson(j['retire_le'], 'retire_le'),
    anonymiserLe: instantJson(j['anonymiser_le'], 'anonymiser_le'),
    anonymiseLe: anonymise == null
        ? null
        : instantJson(anonymise, 'anonymise_le'),
    restaureLe: restaure == null ? null : instantJson(restaure, 'restaure_le'),
    restaurable: booleenJson(j, 'restaurable'),
  );
}

/// Le refus metier du tuteur, ou `null` pour toute autre erreur. Pure, testee.
ResultatSuppressionEnfant? refusSuppressionEnfant(PostgrestException e) {
  if (e.code == '42501' && e.message == 'profil_hors_foyer') {
    return ResultatSuppressionEnfant.horsFoyer;
  }
  if (e.code == '55000') return ResultatSuppressionEnfant.dejaRetire;
  return null;
}
