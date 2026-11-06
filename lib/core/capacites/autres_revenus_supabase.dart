// Adaptateur REVENUS-VERITE point 5 : les autres revenus d'un enseignant,
// lus par `autres_revenus_lister`, attribues par `autre_revenu_attribuer`,
// annules par `autre_revenu_annuler` (migration 20261110210000). Le serveur
// garde chaque appel (direction pour ecrire, direction et comptabilite pour
// lire) ; rien n'est recalcule ici.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_autres_revenus.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'REVENUS-VERITE-5';

/// Les autres revenus servis par Supabase.
class AutresRevenusSupabase implements PortAutresRevenus {
  /// Cree l'adaptateur sur le client de l'application.
  AutresRevenusSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  AutresRevenusSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<AutresRevenusMois> lister(String enseignantId, DateTime mois) async =>
      decoder(
        await appelerFinance(
          _appel,
          'autres_revenus_lister',
          _dependance,
          <String, dynamic>{
            'p_enseignant': enseignantId,
            'p_mois': _jour(mois),
          },
        ),
      );

  @override
  Future<void> attribuer({
    required String enseignantId,
    required DateTime mois,
    required NatureAutreRevenu nature,
    required String libelle,
    required int montantMineur,
    required String cle,
  }) async {
    await appelerFinance(
      _appel,
      'autre_revenu_attribuer',
      _dependance,
      <String, dynamic>{
        'p_enseignant': enseignantId,
        'p_mois': _jour(mois),
        'p_nature': natureAutreRevenuServeur(nature),
        'p_libelle': libelle,
        'p_montant_minor': montantMineur,
        'p_cle': cle,
      },
    );
  }

  @override
  Future<void> annuler(String id) async {
    await appelerFinance(
      _appel,
      'autre_revenu_annuler',
      _dependance,
      <String, dynamic>{'p_id': id},
    );
  }

  /// Decode la reponse de `autres_revenus_lister`, sans rien recalculer.
  static AutresRevenusMois decoder(Object? brut) {
    final Map<String, dynamic> j = objetJson(brut, 'autres');
    return AutresRevenusMois(
      mois: dateJson(j['mois'], 'mois'),
      devise: texteJson(j, 'devise'),
      peutAttribuer: booleenJson(j, 'peutAttribuer'),
      aideInternetPolitique: montantNullableJson(
        j['aideInternetPolitique'],
        'aideInternetPolitique',
      ),
      lignes: List<AutreRevenu>.unmodifiable(<AutreRevenu>[
        for (final Object? l in listeJson(j['lignes'], 'lignes'))
          ligne(objetJson(l, 'ligne')),
      ]),
    );
  }

  /// Decode une ligne d'autre revenu (aussi rendue par
  /// `mes_revenus_enseignant` et `releve_paie_seances`).
  static AutreRevenu ligne(Map<String, dynamic> l) => AutreRevenu(
    id: texteJson(l, 'id'),
    nature: natureAutreRevenuJson(l['nature']),
    libelle: texteJson(l, 'libelle'),
    montant: montantJson(l['montant'], 'montant'),
  );

  static String _jour(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-01';
}
