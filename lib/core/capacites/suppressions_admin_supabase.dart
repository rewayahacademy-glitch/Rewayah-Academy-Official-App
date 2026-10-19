// Adaptateur CPT-SUPPR-EXPORT cote direction : `demandes_suppression_lister`
// et `traiter_demande_suppression` (migration 20261018150000).
//
// Erreurs : une fonction absente (PGRST202) se dit [CapaciteIndisponible] ; un
// refus (42501 : pas la direction, ou pas en double verification) se dit
// [PermissionInsuffisante] ; un refus metier (55000, P0002) devient un
// [ResultatTraitementSuppression] ; toute autre erreur (reseau, serveur)
// remonte telle quelle : l'ecran ne dit jamais un succes qu'il ignore.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../finance/montant.dart';
import 'permission_insuffisante.dart';
import 'port_suppressions_admin.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'CPT-SUPPR-EXPORT';

/// Les demandes de suppression servies par Supabase.
class SuppressionsAdminSupabase implements PortSuppressionsAdmin {
  /// Cree l'adaptateur sur le client de l'application.
  SuppressionsAdminSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  SuppressionsAdminSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<List<DemandeSuppressionAdmin>> lister() async {
    final Object? brut = await _appeler('demandes_suppression_lister');
    return List<DemandeSuppressionAdmin>.unmodifiable(<DemandeSuppressionAdmin>[
      for (final Object? ligne in listeJson(brut, 'demandes'))
        demandeAdminDepuis(objetJson(ligne, 'demande')),
    ]);
  }

  @override
  Future<ResultatTraitementSuppression> traiter(String id) async {
    try {
      await _appeler('traiter_demande_suppression', <String, dynamic>{
        'p_id': id,
      });
      return ResultatTraitementSuppression.traitee;
    } on PostgrestException catch (e) {
      final ResultatTraitementSuppression? refus = refusTraitement(e);
      if (refus == null) rethrow;
      return refus;
    }
  }

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
}

/// Le refus metier du serveur, ou `null` pour toute autre erreur. Pure,
/// testee. Le serveur ecrit `55000` pour trois raisons ; le message les
/// distingue.
ResultatTraitementSuppression? refusTraitement(PostgrestException e) {
  if (e.code == 'P0002') return ResultatTraitementSuppression.introuvable;
  if (e.code != '55000') return null;
  final String message = e.message.toLowerCase();
  if (message.contains('deja')) {
    return ResultatTraitementSuppression.dejaTraitee;
  }
  if (message.contains('delai')) {
    return ResultatTraitementSuppression.delaiEnCours;
  }
  if (message.contains('seances')) {
    return ResultatTraitementSuppression.seancesAVenir;
  }
  return null;
}

/// Une demande lue d'une ligne de `demandes_suppression_lister`. Pure, testee.
DemandeSuppressionAdmin demandeAdminDepuis(Map<String, dynamic> j) {
  final Object? sit = j['situation'];
  final Object? annulee = j['annulee_le'];
  final Object? traitee = j['traitee_le'];
  return DemandeSuppressionAdmin(
    id: texteJson(j, 'id'),
    statut: switch (j['statut']) {
      'en_attente' => StatutSuppression.enAttente,
      'annulee' => StatutSuppression.annulee,
      'traitee' => StatutSuppression.traitee,
      final Object? s => throw FormatException('statut inconnu: $s'),
    },
    matricule: texteNullableJson(j, 'matricule') ?? '',
    prenom: texteNullableJson(j, 'prenom') ?? '',
    nom: texteNullableJson(j, 'nom') ?? '',
    role: AppRole.depuisSql(texteNullableJson(j, 'role')),
    motif: texteNullableJson(j, 'motif'),
    delaiJours: entierJson(j, 'delai_jours'),
    demandeeLe: instantJson(j['demandee_le'], 'demandee_le'),
    echeanceLe: instantJson(j['echeance_le'], 'echeance_le'),
    annuleeLe: annulee == null ? null : instantJson(annulee, 'annulee_le'),
    traiteeLe: traitee == null ? null : instantJson(traitee, 'traitee_le'),
    delaiEcoule: booleenJson(j, 'delai_ecoule'),
    elevesDuFoyer: entierJson(j, 'eleves_du_foyer'),
    situation: sit == null ? null : _situation(objetJson(sit, 'situation')),
  );
}

SituationSuppressionAdmin _situation(Map<String, dynamic> j) =>
    SituationSuppressionAdmin(
      montantsDus: <Montant>[
        for (final Object? m in listeJson(j['montants_dus'], 'montants_dus'))
          _montantDu(objetJson(m, 'montant_du')),
      ],
      seancesAVenir: entierJson(j, 'seances_a_venir'),
    );

Montant _montantDu(Map<String, dynamic> j) {
  final String devise = texteJson(j, 'devise');
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(devise)) {
    throw FormatException('devise invalide: $devise');
  }
  return Montant(entierJson(j, 'total_mineur'), devise);
}
