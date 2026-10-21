// Adaptateur CPT-SUPPR-EXPORT : `mes_donnees_export`, `ma_situation_suppression`,
// `demander_suppression_compte` et `annuler_suppression_compte` (migration
// 20261018150000). Aucun identifiant n'est envoye : le serveur lit la session.
//
// Erreurs : une fonction absente du serveur (PGRST202) se dit
// [CapaciteIndisponible] ; un refus (42501) se dit [PermissionInsuffisante] ;
// toute autre erreur (reseau, serveur) remonte telle quelle, pour que l'ecran
// dise l'echec ou le hors ligne, jamais un succes.

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/montant.dart';
import 'permission_insuffisante.dart';
import 'port_mes_donnees.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'CPT-SUPPR-EXPORT';

/// Mes donnees servies par Supabase.
class MesDonneesSupabase implements PortMesDonnees {
  /// Cree l'adaptateur sur le client de l'application.
  MesDonneesSupabase(SupabaseClient client) : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  MesDonneesSupabase.avecAppel(this._appel);

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
  Future<CopieDonnees> exporter() async {
    final Map<String, dynamic> contenu = objetJson(
      await _appeler('mes_donnees_export'),
      'mes_donnees_export',
    );
    return copieDepuis(contenu);
  }

  @override
  Future<SituationSuppression> situation() async => situationDepuis(
    objetJson(
      await _appeler('ma_situation_suppression'),
      'ma_situation_suppression',
    ),
  );

  @override
  Future<void> demander({String? motif}) async {
    final String? propre = motif?.trim();
    await _appeler('demander_suppression_compte', <String, dynamic>{
      'p_motif': propre == null || propre.isEmpty ? null : propre,
    });
  }

  @override
  Future<void> annuler() async {
    await _appeler('annuler_suppression_compte');
  }
}

/// La copie prete a enregistrer : le JSON du serveur, mis en forme, en UTF-8,
/// sous un nom qui porte la date de la copie. Pure, testee.
CopieDonnees copieDepuis(Map<String, dynamic> contenu) {
  final String texte = const JsonEncoder.withIndent('  ').convert(contenu);
  final Object? genereLe = contenu['genere_le'];
  final DateTime? date = genereLe is String
      ? DateTime.tryParse(genereLe)?.toLocal()
      : null;
  final String jour = date == null
      ? ''
      : '-${date.year.toString().padLeft(4, '0')}'
            '-${date.month.toString().padLeft(2, '0')}'
            '-${date.day.toString().padLeft(2, '0')}';
  return CopieDonnees(
    octets: utf8.encode(texte),
    nomFichier: 'rewayah-mes-donnees$jour.json',
  );
}

/// La situation lue d'une reponse de `ma_situation_suppression`. Pure, testee.
SituationSuppression situationDepuis(Map<String, dynamic> j) {
  final Object? brute = j['demande'];
  final Map<String, dynamic> situation = objetJson(j['situation'], 'situation');
  return SituationSuppression(
    demande: brute == null ? null : demandeDepuis(objetJson(brute, 'demande')),
    delaiJours: entierJson(j, 'delai_jours'),
    montantsDus: <Montant>[
      for (final Object? m in listeJson(
        situation['montants_dus'],
        'montants_dus',
      ))
        _montantDu(objetJson(m, 'montant_du')),
    ],
    seancesAVenir: entierJson(situation, 'seances_a_venir'),
  );
}

/// Une demande lue d'un objet serveur. Pure, testee.
DemandeSuppression demandeDepuis(Map<String, dynamic> j) => DemandeSuppression(
  id: texteJson(j, 'id'),
  delaiJours: entierJson(j, 'delai_jours'),
  demandeeLe: instantJson(j['demandee_le'], 'demandee_le'),
  echeanceLe: instantJson(j['echeance_le'], 'echeance_le'),
);

Montant _montantDu(Map<String, dynamic> j) {
  final String devise = texteJson(j, 'devise');
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(devise)) {
    throw FormatException('devise invalide: $devise');
  }
  return Montant(entierJson(j, 'total_mineur'), devise);
}
