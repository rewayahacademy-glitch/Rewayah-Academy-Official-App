// Adaptateur FN-115c : les remboursements de la direction, servis par les RPC
// de la migration 20261105100000 et la fonction Edge `remboursement-stripe`.
//
// **Aucun calcul** : le montant propose, son detail et le plafond de la
// confirmation sont arretes par le serveur. Une RPC absente (migration pas
// encore appliquee) se dit [CapaciteIndisponible] ; un refus (42501, 22023)
// remonte tel quel.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';
import 'port_remboursements_direction.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FN-115c';

/// L'envoi au prestataire : le corps, la reponse de la fonction Edge.
typedef AppelEnvoiRemboursement = Future<Object?> Function(
  Map<String, dynamic> corps,
);

/// Les remboursements de la direction servis par Supabase.
class RemboursementsDirectionSupabase implements PortRemboursementsDirection {
  /// Cree l'adaptateur sur le client de l'application.
  RemboursementsDirectionSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client),
      _envoi = _envoiFonction(client);

  /// Cree l'adaptateur sur des appels injectes (tests).
  RemboursementsDirectionSupabase.avecAppels(this._appel, this._envoi);

  final AppelRpc _appel;
  final AppelEnvoiRemboursement _envoi;

  static AppelEnvoiRemboursement _envoiFonction(SupabaseClient client) =>
      (Map<String, dynamic> corps) async {
        try {
          return (await client.functions.invoke(
            'remboursement-stripe',
            body: corps,
          )).data;
        } on FunctionException catch (e) {
          if (e.status == 503 || e.status == 404) {
            throw const CapaciteIndisponible(_dependance);
          }
          if (e.status == 502) return <String, dynamic>{'etat': 'echec'};
          rethrow;
        }
      };

  @override
  Future<Set<String>> elevesRemboursables() async {
    final Object? brut = await appelerFinance(
      _appel,
      'remboursement_eleves_remboursables',
      _dependance,
    );
    return <String>{
      for (final Object? v in listeJson(brut, 'eleves'))
        if (v is String)
          v
        else if (v is Map && v.values.firstOrNull is String)
          v.values.first as String,
    };
  }

  @override
  Future<List<PaiementRemboursable>> paiements(String profilId) async =>
      <PaiementRemboursable>[
        for (final Object? l in listeJson(
          await appelerFinance(
            _appel,
            'remboursement_paiements_eleve',
            _dependance,
            <String, dynamic>{'p_profil': profilId},
          ),
          'paiements',
        ))
          paiementRemboursableJson(l),
      ];

  @override
  Future<String> confirmer({
    required String commandeId,
    required String profilId,
    required Montant montant,
    required String cle,
  }) async {
    final Object? id = await appelerFinance(
      _appel,
      'remboursement_confirmer',
      _dependance,
      <String, dynamic>{
        'p_commande': commandeId,
        'p_profil': profilId,
        'p_montant': montant.mineur,
        'p_cle': cle,
      },
    );
    if (id is String && id.isNotEmpty) return id;
    throw const FormatException('demande de remboursement invalide');
  }

  @override
  Future<IssueRemboursement> envoyer(String demandeId) async {
    final Object? r = await _envoi(<String, dynamic>{'demandeId': demandeId});
    final String etat = r is Map ? '${r['etat']}' : '';
    return switch (etat) {
      'envoyee' => IssueRemboursement.envoye,
      'remboursee' => IssueRemboursement.rembourse,
      'echec' => IssueRemboursement.refuse,
      _ => throw FormatException('issue de remboursement inconnue: $etat'),
    };
  }
}

/// Un paiement rendu par `remboursement_paiements_eleve`.
PaiementRemboursable paiementRemboursableJson(Object? v) {
  final Map<String, dynamic> j = objetJson(v, 'paiement');
  final String devise = texteJson(j, 'devise');
  final Map<String, dynamic> d = j['detail'] is Map
      ? Map<String, dynamic>.from(j['detail'] as Map)
      : <String, dynamic>{};
  Montant? montant(Object? x) => x is int ? Montant(x, devise) : null;
  final int deja =
      (d['deja_rendu_mineur'] is int ? d['deja_rendu_mineur'] as int : 0) +
      (d['en_cours_mineur'] is int ? d['en_cours_mineur'] as int : 0);
  return PaiementRemboursable(
    commandeId: texteJson(j, 'commande_id'),
    reference: texteJson(j, 'reference'),
    payeLe: DateTime.parse(texteJson(j, 'paye_le')),
    paye: Montant(entierJson(j, 'paye_mineur'), devise),
    propose: Montant(entierJson(j, 'montant_propose_mineur'), devise),
    regle: switch (d['regle']) {
      'delai' => RegleRemboursement.delai,
      'prepaiement' => RegleRemboursement.prepaiement,
      'hors_delai' => RegleRemboursement.horsDelai,
      _ => RegleRemboursement.aucune,
    },
    dejaRendu: deja > 0 ? Montant(deja, devise) : null,
    seancesSuivies: d['seances_suivies'] is int
        ? d['seances_suivies'] as int
        : 0,
    prixSeance: montant(d['prix_seance_mineur']),
    moisCommences: d['mois_commences'] is int ? d['mois_commences'] as int : 0,
    prixMensuel: montant(d['prix_mensuel_mineur']),
    delaiJours: d['delai_jours'] is int ? d['delai_jours'] as int : null,
  );
}
