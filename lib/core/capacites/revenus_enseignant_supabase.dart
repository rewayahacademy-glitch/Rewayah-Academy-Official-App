// Adaptateur FI-BR-11 : les revenus de l'enseignant connecte, lus par
// `mes_revenus_enseignant` et `mes_revenus_mois_disponibles` (migration
// 20261017160000). Le serveur borne la lecture a la session : aucun
// identifiant d'enseignant n'est envoye.
//
// Deux capacites restent indisponibles, faute de source serveur : le releve
// des mois arretes (aucune cloture mensuelle n'existe) et, pour un mois sans
// regle de remuneration, la vue elle-meme (base et plafond inconnus).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'capacite_indisponible.dart';
import 'port_revenus_enseignant.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FI-BR-11';

/// Les revenus servis par Supabase.
class RevenusEnseignantSupabase implements PortRevenusEnseignant {
  /// Cree l'adaptateur sur le client de l'application.
  RevenusEnseignantSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  RevenusEnseignantSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<RevenusEnseignant> moisEnCours() => _lire(null);

  @override
  Future<RevenusEnseignant> duMois(DateTime mois) => _lire(mois);

  Future<RevenusEnseignant> _lire(DateTime? mois) async {
    final Object? brut = await appelerFinance(
      _appel,
      'mes_revenus_enseignant',
      _dependance,
      <String, dynamic>{
        'p_mois': mois == null ? null : _jour(DateTime(mois.year, mois.month)),
      },
    );
    return decoderRevenus(brut);
  }

  @override
  Future<List<DateTime>> moisDisponibles() async {
    final Object? brut = await appelerFinance(
      _appel,
      'mes_revenus_mois_disponibles',
      _dependance,
    );
    return List<DateTime>.unmodifiable(<DateTime>[
      for (final Object? m in listeJson(brut, 'mois')) dateJson(m, 'mois'),
    ]);
  }

  /// Aucune cloture mensuelle n'existe cote serveur : jamais un releve
  /// invente.
  @override
  Future<List<LigneReleve>> releve() =>
      Future<List<LigneReleve>>.error(const CapaciteIndisponible(_dependance));

  /// Decode la reponse de `mes_revenus_enseignant`, sans rien recalculer.
  static RevenusEnseignant decoderRevenus(Object? brut) {
    final Map<String, dynamic> j = objetJson(brut, 'revenus');
    final Object? regle = j['regle'];
    if (regle == null) throw const CapaciteIndisponible(_dependance);
    final Map<String, dynamic> r = objetJson(regle, 'regle');
    final Map<String, dynamic> t = objetJson(j['total'], 'total');
    return RevenusEnseignant(
      debut: dateJson(j['debut'], 'debut'),
      fin: dateJson(j['fin'], 'fin'),
      classes: List<RevenusClasse>.unmodifiable(<RevenusClasse>[
        for (final Object? c in listeJson(j['classes'], 'classes'))
          _classe(objetJson(c, 'classe')),
      ]),
      total: TotalRevenus(
        minutesAssurees: entierJson(t, 'minutesAssurees'),
        capacite: entierJson(t, 'capacite'),
        siegesEligibles: entierJson(t, 'siegesEligibles'),
        tauxHoraireMoyen: montantJson(t['tauxHoraireMoyen'], 'tauxMoyen'),
      ),
      totalEstime: montantJson(j['totalEstime'], 'totalEstime'),
      baseHoraire: montantJson(r['base'], 'base'),
      plafondHoraire: montantJson(r['plafond'], 'plafond'),
      allocationInternet: montantNullableJson(
        j['allocationInternet'],
        'allocationInternet',
      ),
    );
  }

  static RevenusClasse _classe(Map<String, dynamic> c) => RevenusClasse(
    classeId: texteJson(c, 'classeId'),
    classe: texteJson(c, 'classe'),
    type: switch (c['type']) {
      'enfants' => TypeClasseRevenus.enfants,
      'debutants' => TypeClasseRevenus.debutants,
      'adultes' => TypeClasseRevenus.adultes,
      final Object? x => throw FormatException('type de classe inconnu: $x'),
    },
    minutesAssurees: entierJson(c, 'minutesAssurees'),
    capacite: entierJson(c, 'capacite'),
    siegesEligibles: entierJson(c, 'siegesEligibles'),
    tauxHoraireEffectif: montantJson(c['tauxHoraireEffectif'], 'taux'),
    montantEstime: montantJson(c['montantEstime'], 'montant'),
    enRemplacement: booleenJson(c, 'enRemplacement'),
  );

  static String _jour(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-01';
}
