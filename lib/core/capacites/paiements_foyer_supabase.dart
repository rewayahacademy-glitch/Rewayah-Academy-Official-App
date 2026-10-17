// Adaptateur DB-CPT-03, FI-BR-03, FI-BR-05 : les paiements et la finance du
// foyer, pour le titulaire seulement, lus par `paiements_foyer`,
// `finances_foyer`, `mouvements_profil_foyer` et `derniers_mouvements_foyer`
// (migration 20261017160100). Le serveur verifie le titulaire en base
// (households.primary_guardian_id) : le second adulte et l'enfant sont
// refuses (42501).
//
// `soldes()` reste indisponible : sa forme rend des soldes deja rediges en
// texte, que le serveur ne produit pas ; `finances()` porte les memes soldes
// en unites mineures.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/finances_profil.dart';
import '../finance/mouvements_profil.dart';
import 'capacite_indisponible.dart';
import 'port_paiements_foyer.dart';
import 'rpc_finance_supabase.dart';

/// Les paiements du foyer servis par Supabase.
class PaiementsFoyerSupabase implements PortPaiementsFoyer {
  /// Cree l'adaptateur sur le client de l'application.
  PaiementsFoyerSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  PaiementsFoyerSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<List<PaiementFoyer>> historique() async => _paiements(
    await appelerFinance(
      _appel,
      'paiements_foyer',
      'DB-CPT-03',
      <String, dynamic>{'p_id': null},
    ),
  );

  @override
  Future<PaiementFoyer?> detail(String id) async {
    final int? cle = int.tryParse(id);
    if (cle == null) return null;
    final List<PaiementFoyer> l = _paiements(
      await appelerFinance(
        _appel,
        'paiements_foyer',
        'DB-CPT-03',
        <String, dynamic>{'p_id': cle},
      ),
    );
    return l.isEmpty ? null : l.first;
  }

  @override
  Future<SoldesFoyer> soldes() =>
      Future<SoldesFoyer>.error(const CapaciteIndisponible('FI-BR-03'));

  @override
  Future<FinancesFoyer> finances() async {
    final Object? brut = await appelerFinance(
      _appel,
      'finances_foyer',
      'FI-BR-03',
    );
    // Aucun portefeuille pour ce foyer : la finance n'est pas encore ouverte.
    if (brut == null) throw const CapaciteIndisponible('FI-BR-03');
    final Map<String, dynamic> j = objetJson(brut, 'foyer');
    final Map<String, dynamic> s = objetJson(j['synthese'], 'synthese');
    return FinancesFoyer(
      synthese: SyntheseFoyer(
        totalSoldes: montantJson(s['totalSoldes'], 'totalSoldes'),
        aPayerCeMois: montantJson(s['aPayerCeMois'], 'aPayerCeMois'),
        profilsFinances: entierJson(s, 'profilsFinances'),
        profils: entierJson(s, 'profils'),
        paiementsDuMois: entierJson(s, 'paiementsDuMois'),
      ),
      profils: List<FinancesProfil>.unmodifiable(<FinancesProfil>[
        for (final Object? p in listeJson(j['profils'], 'profils'))
          financesProfilJson(p),
      ]),
    );
  }

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) async =>
      mouvementsJson(
        await appelerFinance(
          _appel,
          'mouvements_profil_foyer',
          'FI-BR-05',
          <String, dynamic>{'p_profil': profilId, 'p_limite': 50},
        ),
      );

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) async {
    final Object? brut = await appelerFinance(
      _appel,
      'derniers_mouvements_foyer',
      'FI-BR-05',
      <String, dynamic>{'p_limite': limite},
    );
    return List<MouvementFoyer>.unmodifiable(<MouvementFoyer>[
      for (final Object? m in listeJson(brut, 'derniers'))
        _mouvementFoyer(objetJson(m, 'dernier')),
    ]);
  }

  static MouvementFoyer _mouvementFoyer(Map<String, dynamic> m) =>
      MouvementFoyer(
        profilId: texteJson(m, 'profilId'),
        prenom: texteJson(m, 'prenom'),
        mouvement: mouvementProfilJson(m['mouvement']),
      );

  static List<PaiementFoyer> _paiements(Object? brut) =>
      List<PaiementFoyer>.unmodifiable(<PaiementFoyer>[
        for (final Object? p in listeJson(brut, 'paiements'))
          _paiement(objetJson(p, 'paiement')),
      ]);

  static PaiementFoyer _paiement(Map<String, dynamic> p) {
    final String devise = texteJson(p, 'devise');
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(devise)) {
      throw const FormatException('devise invalide');
    }
    return PaiementFoyer(
      id: texteJson(p, 'id'),
      montantMineur: entierJson(p, 'montantMineur'),
      devise: devise,
      statutServeur: switch (p['statut']) {
        final String s when s == 'confirme' || s == 'en_confirmation' => s,
        final Object? s => throw FormatException('statut inconnu: $s'),
      },
      date: instantJson(p['date'], 'date'),
      justificatifDisponible: booleenJson(p, 'justificatifDisponible'),
    );
  }
}
