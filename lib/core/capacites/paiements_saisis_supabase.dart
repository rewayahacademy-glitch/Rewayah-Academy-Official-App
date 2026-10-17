// Adaptateur FI-BR-14 : la saisie des paiements recus, servie par les RPC de
// FAC-C-01 (migration 20261017172000).
//
// **Aucun calcul** : le reste a payer et l'etat financier apres paiement
// sont arretes par le serveur. Un refus de droits (42501) ou de valeurs
// (22023, P0002) devient [RefusPaiement] : rien n'a ete enregistre. Toute
// autre erreur remonte telle quelle : l'issue est inconnue.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/montant.dart';
import 'port_paiements_saisis.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FI-BR-14';

/// La saisie des paiements servie par Supabase.
class PaiementsSaisisSupabase implements PortPaiementsSaisis {
  /// Cree l'adaptateur sur le client de l'application.
  PaiementsSaisisSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  PaiementsSaisisSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<List<ElevePourPaiement>> eleves() async => <ElevePourPaiement>[
    for (final Object? e in listeJson(
      await appelerFinance(_appel, 'eleves_pour_paiement', _dependance),
      'eleves',
    ))
      elevePourPaiementJson(e),
  ];

  @override
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  }) async {
    final Object? brut;
    try {
      brut = await appelerFinance(
        _appel,
        'enregistrer_paiement',
        _dependance,
        <String, dynamic>{
          'p_profil': profilId,
          'p_montant_mineur': montant.mineur,
          'p_devise': montant.devise,
          'p_reference': reference,
          'p_cle': cle,
        },
      );
    } on PostgrestException catch (e) {
      throw switch (e.code) {
        '42501' => const RefusPaiement(MotifRefusPaiement.droits),
        '22023' || 'P0002' => const RefusPaiement(MotifRefusPaiement.invalide),
        _ => e,
      };
    }
    return paiementEnregistreJson(brut);
  }
}

/// Une ligne de `eleves_pour_paiement`.
ElevePourPaiement elevePourPaiementJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'eleve');
  return ElevePourPaiement(
    profilId: texteJson(j, 'profilId'),
    prenom: texteJson(j, 'prenom'),
    nom: texteNullableJson(j, 'nom'),
    matricule: texteNullableJson(j, 'matricule'),
    resteAPayer: montantJson(j['resteAPayer'], 'resteAPayer'),
  );
}

/// Le resultat de `enregistrer_paiement`.
PaiementEnregistre paiementEnregistreJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'paiement');
  final Object? finance = j['finance'];
  return PaiementEnregistre(
    paiementId: texteJson(j, 'paiement'),
    nouveau: booleenJson(j, 'nouveau'),
    finance: finance == null ? null : financesProfilJson(finance),
  );
}
