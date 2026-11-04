// N3, S2 (03/11/2026) : l'adaptateur Supabase de la pause programmee
// (LIVE-PAUSE-01), sur les cinq fonctions du serveur deja installees par
// `20261012061517_x2_22_pause_seance.sql` :
//
//   pause_reglage_lire, pause_reglage_ecrire,
//   pause_seance_etat, pause_seance_demarrer, pause_seance_terminer.
//
// Contrat : `docs/current/CONTRAT_PORT_PAUSE_SEANCE.md`. Le serveur decide de
// tout : qui lit, qui ecrit (`peut_modifier`, `peut_piloter`), l'horodatage du
// debut et de la fin. Le client n'envoie jamais d'heure.
//
// Une version perimee (`40001`, « reglage_obsolete ») devient
// `ReglagePauseObsolete` : l'ecran relit et le dit, jamais d'ecrasement. Toute
// autre erreur remonte telle quelle : l'ecran dit qu'il n'a pas pu.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_pause_seance.dart';

/// La pause programmee, lue et ecrite par les fonctions du serveur.
class PauseSeanceSupabase implements PortPauseSeance {
  /// Cree l'adaptateur.
  const PauseSeanceSupabase(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _appeler(
    String fonction,
    Map<String, dynamic> parametres,
  ) async {
    final Object? brut;
    try {
      brut = await _client.rpc<Object?>(fonction, params: parametres);
    } on PostgrestException catch (e) {
      if (e.code == '40001' || e.message.contains('reglage_obsolete')) {
        throw const ReglagePauseObsolete();
      }
      rethrow;
    }
    if (brut is! Map) {
      throw FormatException('Reponse de $fonction invalide.');
    }
    return Map<String, dynamic>.from(brut);
  }

  @override
  Future<ReglagePause> reglage(String groupeId) async => reglageDepuis(
    await _appeler('pause_reglage_lire', <String, dynamic>{
      'p_groupe_id': groupeId,
    }),
  );

  @override
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  }) async => reglageDepuis(
    await _appeler('pause_reglage_ecrire', <String, dynamic>{
      'p_groupe_id': groupeId,
      'p_actif': actif,
      'p_apres_minutes': apresMinutes,
      'p_duree_minutes': dureeMinutes,
      'p_version_attendue': versionAttendue,
      'p_cle_idempotence': cleIdempotence,
    }),
  );

  @override
  Future<PauseSeance> etat(String seanceId) async => pauseDepuis(
    await _appeler('pause_seance_etat', <String, dynamic>{
      'p_seance_id': seanceId,
    }),
  );

  @override
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  }) async => pauseDepuis(
    await _appeler('pause_seance_demarrer', <String, dynamic>{
      'p_seance_id': seanceId,
      'p_cle_idempotence': cleIdempotence,
    }),
  );

  @override
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  }) async => pauseDepuis(
    await _appeler('pause_seance_terminer', <String, dynamic>{
      'p_seance_id': seanceId,
      'p_cle_idempotence': cleIdempotence,
    }),
  );
}

/// Le reglage lu dans la reponse du serveur. Une valeur hors bornes leve
/// `FormatException` plutot qu'une assertion.
ReglagePause reglageDepuis(Map<String, dynamic> ligne) {
  final int apres = _entier(ligne, 'apres_minutes');
  final int duree = _entier(ligne, 'duree_minutes');
  if (apres < BornesPause.apresMin ||
      apres > BornesPause.apresMax ||
      duree < BornesPause.dureeMin ||
      duree > BornesPause.dureeMax) {
    throw const FormatException('Reglage de pause hors bornes.');
  }
  final Object? version = ligne['version'];
  if (version == null) throw const FormatException('Version absente.');
  return ReglagePause(
    actif: ligne['actif'] == true,
    apresMinutes: apres,
    dureeMinutes: duree,
    version: '$version',
    peutModifier: ligne['peut_modifier'] == true,
  );
}

/// L'etat de la pause d'une seance lu dans la reponse du serveur.
PauseSeance pauseDepuis(Map<String, dynamic> ligne) {
  final StatutPause statut = switch (ligne['statut']) {
    'non_prevue' => StatutPause.nonPrevue,
    'programmee' => StatutPause.programmee,
    'en_cours' => StatutPause.enCours,
    'prise' => StatutPause.prise,
    'non_prise' => StatutPause.nonPrise,
    _ => throw const FormatException('Statut de pause inconnu.'),
  };
  if (statut == StatutPause.nonPrevue) {
    return const PauseSeance.nonPrevue();
  }
  return PauseSeance(
    statut: statut,
    dureePrevueMinutes: _entier(ligne, 'duree_prevue_minutes'),
    debutPrevuUtc: _date(ligne['debut_prevu_utc']),
    debutUtc: _date(ligne['debut_utc']),
    finUtc: _date(ligne['fin_utc']),
    peutPiloter: ligne['peut_piloter'] == true,
  );
}

int _entier(Map<String, dynamic> ligne, String cle) {
  final Object? v = ligne[cle];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final int? n = int.tryParse(v);
    if (n != null) return n;
  }
  throw FormatException('Champ $cle invalide.');
}

DateTime? _date(Object? brut) {
  if (brut == null) return null;
  if (brut is! String) throw const FormatException('Horodatage invalide.');
  return DateTime.parse(brut).toUtc();
}
