// Lot (A), 02/11/2026 : les remises particulieres servies par les RPC de la
// migration 20261104700000 (`accorder_tarif_particulier`, `bourses_lister`)
// et de FAC-E-01 (`retirer_bourse`). **Aucun calcul** : le serveur verifie
// les droits et les valeurs ; un refus (42501, 22023, BO002) devient
// [RefusTarif], rien n'a ete enregistre.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_tarifs_particuliers.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FAC-E-01';

/// Les remises particulieres servies par Supabase.
class TarifsParticuliersSupabase implements PortTarifsParticuliers {
  /// Cree l'adaptateur sur le client de l'application.
  TarifsParticuliersSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  TarifsParticuliersSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<List<TarifParticulier>> liste() async => <TarifParticulier>[
    for (final Object? e in listeJson(
      await appelerFinance(_appel, 'bourses_lister', _dependance),
      'bourses',
    ))
      tarifParticulierJson(e),
  ];

  @override
  Future<void> accorder({
    required String profilId,
    required NatureTarif nature,
    required DateTime moisFin,
    required String motif,
    int? pourMille,
  }) => _ecrire('accorder_tarif_particulier', <String, dynamic>{
    'p_profil': profilId,
    'p_nature': switch (nature) {
      NatureTarif.accesOffert => 'acces_offert',
      NatureTarif.prixSpecial => 'prix_special',
      NatureTarif.bourse => throw ArgumentError.value(
        nature,
        'nature',
        'une bourse de la politique ne s accorde pas ici',
      ),
    },
    'p_pour_mille': pourMille,
    'p_mois_fin': _jour(moisFin),
    'p_motif': motif,
  });

  @override
  Future<void> retirer({required String profilId, required String motif}) =>
      _ecrire('retirer_bourse', <String, dynamic>{
        'p_profil': profilId,
        'p_motif': motif,
      });

  Future<void> _ecrire(String fonction, Map<String, dynamic> params) async {
    try {
      await appelerFinance(_appel, fonction, _dependance, params);
    } on PostgrestException catch (e) {
      final MotifRefusTarif? motif = switch (e.code) {
        '42501' => MotifRefusTarif.droits,
        '22023' || 'P0002' => MotifRefusTarif.invalide,
        'BO002' => MotifRefusTarif.dejaActive,
        _ => null,
      };
      if (motif == null) rethrow;
      throw RefusTarif(motif);
    }
  }
}

String _jour(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-01';

/// Une remise lue dans la reponse de `bourses_lister`.
TarifParticulier tarifParticulierJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'bourse');
  return TarifParticulier(
    profilId: texteJson(j, 'profilId'),
    prenom: texteJson(j, 'prenom'),
    nom: texteNullableJson(j, 'nom'),
    matricule: texteNullableJson(j, 'matricule'),
    nature: switch (j['nature']) {
      'acces_offert' => NatureTarif.accesOffert,
      'prix_special' => NatureTarif.prixSpecial,
      _ => NatureTarif.bourse,
    },
    pourMille: entierJson(j, 'pourMille'),
    moisFin: dateJson(j['moisFin'], 'moisFin'),
    motif: texteJson(j, 'motif'),
  );
}
