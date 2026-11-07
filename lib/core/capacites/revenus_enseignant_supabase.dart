// Adaptateur FI-BR-11 : les revenus de l'enseignant connecte, lus par
// `mes_revenus_enseignant` et `mes_revenus_mois_disponibles` (migration
// 20261017160000). Le serveur borne la lecture a la session : aucun
// identifiant d'enseignant n'est envoye.
//
// Deux capacites restent indisponibles, faute de source serveur : le releve
// des mois arretes (aucune cloture mensuelle n'existe) et, pour un mois sans
// regle de remuneration, la vue elle-meme (`regle` nulle).
//
// REVENUS-VERITE (06/11/2026, migration 20261110200000) : ni base, ni
// plafond, ni sieges eligibles ; le detail par seance et par eleve (present
// ou absent, part calculee par le serveur) et le jour de paie (`versement`).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'autres_revenus_supabase.dart';
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
    if (j['regle'] == null) throw const CapaciteIndisponible(_dependance);
    final Map<String, dynamic> t = objetJson(j['total'], 'total');
    final Object? versement = j['versement'];
    return RevenusEnseignant(
      debut: dateJson(j['debut'], 'debut'),
      fin: dateJson(j['fin'], 'fin'),
      classes: List<RevenusClasse>.unmodifiable(<RevenusClasse>[
        for (final Object? c in listeJson(j['classes'], 'classes'))
          _classe(objetJson(c, 'classe')),
      ]),
      seances: List<RevenusSeance>.unmodifiable(<RevenusSeance>[
        if (j['seances'] != null)
          for (final Object? s in listeJson(j['seances'], 'seances'))
            _seance(objetJson(s, 'seance')),
      ]),
      total: TotalRevenus(
        minutesAssurees: entierJson(t, 'minutesAssurees'),
        capacite: entierJson(t, 'capacite'),
        tauxHoraireMoyen: montantJson(t['tauxHoraireMoyen'], 'tauxMoyen'),
      ),
      totalEstime: montantJson(j['totalEstime'], 'totalEstime'),
      versement: versement == null
          ? null
          : _fenetre(objetJson(versement, 'versement')),
      autres: List<AutreRevenu>.unmodifiable(<AutreRevenu>[
        if (j['autres'] != null)
          for (final Object? a in listeJson(j['autres'], 'autres'))
            AutresRevenusSupabase.ligne(objetJson(a, 'autre')),
      ]),
      totalAutres: montantNullableJson(j['totalAutres'], 'totalAutres'),
      allocationInternet: montantNullableJson(
        j['allocationInternet'],
        'allocationInternet',
      ),
    );
  }

  static FenetreVersement _fenetre(Map<String, dynamic> v) => FenetreVersement(
    du: dateJson(v['du'], 'du'),
    au: dateJson(v['au'], 'au'),
  );

  static TypeClasseRevenus _type(Object? x) => switch (x) {
    'enfants' => TypeClasseRevenus.enfants,
    'debutants' => TypeClasseRevenus.debutants,
    'adultes' => TypeClasseRevenus.adultes,
    _ => throw FormatException('type de classe inconnu: $x'),
  };

  static RevenusClasse _classe(Map<String, dynamic> c) => RevenusClasse(
    classeId: texteJson(c, 'classeId'),
    classe: texteJson(c, 'classe'),
    type: _type(c['type']),
    minutesAssurees: entierJson(c, 'minutesAssurees'),
    capacite: entierJson(c, 'capacite'),
    tauxHoraireEffectif: montantJson(c['tauxHoraireEffectif'], 'taux'),
    montantEstime: montantJson(c['montantEstime'], 'montant'),
    enRemplacement: booleenJson(c, 'enRemplacement'),
  );

  static RevenusSeance _seance(Map<String, dynamic> s) => RevenusSeance(
    seanceId: texteJson(s, 'seanceId'),
    debut: instantJson(s['debut'], 'debut'),
    classeId: texteJson(s, 'classeId'),
    classe: texteJson(s, 'classe'),
    type: _type(s['type']),
    minutes: entierJson(s, 'minutes'),
    montant: montantNullableJson(s['montant'], 'montant'),
    attente: switch (s['attente']) {
      null => null,
      'cahier' => AttenteVersement.cahier,
      'direction' => AttenteVersement.direction,
      final Object x => throw FormatException('attente inconnue: $x'),
    },
    enRemplacement: booleenJson(s, 'enRemplacement'),
    eleves: List<RevenusEleveSeance>.unmodifiable(<RevenusEleveSeance>[
      for (final Object? e in listeJson(s['eleves'], 'eleves'))
        _eleve(objetJson(e, 'eleve')),
    ]),
  );

  static RevenusEleveSeance _eleve(Map<String, dynamic> e) =>
      RevenusEleveSeance(
        eleveId: texteJson(e, 'eleveId'),
        prenom: texteJson(e, 'prenom'),
        present: booleenJson(e, 'present'),
        montant: montantNullableJson(e['montant'], 'montant'),
      );

  static String _jour(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-01';
}
