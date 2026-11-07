// Adaptateur des versements de paie notes (migration 20261110710000).
//
// **Aucun calcul** : montants en unites mineures + ISO 4217, ecrits tels que
// la direction les a saisis ; la tresorerie est ecrite par le serveur. Un refus
// de droits (42501) ou de valeurs (22023, P0002) remonte tel quel : rien n'a ete
// enregistre. Une fonction absente du serveur devient [CapaciteIndisponible].

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/montant.dart';
import 'port_versements_paie.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'VERSEMENTS-PAIE';

String _date(DateTime d) => d.toIso8601String().substring(0, 10);

/// Le code serveur d'un moyen.
String codeMoyenVersement(MoyenVersement m) => switch (m) {
  MoyenVersement.virementBancaire => 'virement_bancaire',
  MoyenVersement.mobileMoney => 'mobile_money',
  MoyenVersement.autre => 'autre',
};

MoyenVersement _moyen(Object? v) => switch (v) {
  'virement_bancaire' => MoyenVersement.virementBancaire,
  'mobile_money' => MoyenVersement.mobileMoney,
  'autre' => MoyenVersement.autre,
  _ => throw FormatException('moyen de versement inconnu: $v'),
};

/// Decode un versement rendu par le serveur (enseignant ou direction).
VersementPaie versementPaieJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'versement');
  final String? prenom = texteNullableJson(j, 'prenom');
  final String? nom = texteNullableJson(j, 'nom');
  final String nomComplet = <String?>[
    prenom,
    nom,
  ].whereType<String>().where((String s) => s.isNotEmpty).join(' ');
  final Object? annule = j['annule'];
  return VersementPaie(
    id: texteJson(j, 'id'),
    montant: montantJson(j['montant'], 'montant'),
    verseLe: dateJson(j['verseLe'], 'verseLe'),
    mois: dateJson(j['mois'], 'mois'),
    moyen: _moyen(j['moyen']),
    annule: annule is bool ? annule : j['annuleLe'] != null,
    reference: texteNullableJson(j, 'reference'),
    enseignantId: texteNullableJson(j, 'enseignant'),
    enseignantNom: nomComplet.isEmpty ? null : nomComplet,
    note: texteNullableJson(j, 'note'),
    annuleMotif: texteNullableJson(j, 'annuleMotif'),
  );
}

/// Les versements de paie servis par Supabase.
class VersementsPaieSupabase implements PortVersementsPaie {
  /// Cree l'adaptateur sur le client de l'application.
  VersementsPaieSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  VersementsPaieSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  Future<List<VersementPaie>> _liste(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async => <VersementPaie>[
    for (final Object? v in listeJson(
      await appelerFinance(_appel, fonction, _dependance, params),
      fonction,
    ))
      versementPaieJson(v),
  ];

  @override
  Future<List<VersementPaie>> mesVersements() => _liste('mes_versements_paie');

  @override
  Future<List<VersementPaie>> versementsDirection({DateTime? mois}) => _liste(
    'versements_paie_direction',
    <String, dynamic>{'p_mois': mois == null ? null : _date(mois)},
  );

  @override
  Future<VersementPaie> noter(VersementANoter v) async {
    final Montant m = v.montant;
    return versementPaieJson(
      await appelerFinance(
        _appel,
        'versement_paie_noter',
        _dependance,
        <String, dynamic>{
          'p_enseignant': v.enseignantId,
          'p_montant_minor': m.mineur,
          'p_devise': m.devise,
          'p_verse_le': _date(v.verseLe),
          'p_moyen': codeMoyenVersement(v.moyen),
          'p_reference': v.reference,
          'p_mois': _date(v.mois),
          'p_note': v.note,
          'p_cle': v.cle,
        },
      ),
    );
  }

  @override
  Future<VersementPaie> annuler({
    required String versementId,
    required String motif,
  }) async => versementPaieJson(
    await appelerFinance(
      _appel,
      'versement_paie_annuler',
      _dependance,
      <String, dynamic>{'p_versement': versementId, 'p_motif': motif},
    ),
  );
}
