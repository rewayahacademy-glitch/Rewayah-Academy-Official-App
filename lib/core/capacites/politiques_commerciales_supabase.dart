// Adaptateur FI-BR-01 / FI-BR-02 : la politique commerciale versionnee, lue
// et publiee par les RPC de FAC-A-01 (migration 20261017170000).
//
// **Aucun calcul** : les apercus (mensualites par rang, taux horaire) sont
// arretes par le serveur, comme les tarifs et les remises. Le brouillon edite
// a l'ecran repart au serveur dans la meme forme que celle qu'il a rendue ;
// le serveur le valide (numero, date d'effet future, montants, devise) et
// refuse toute forme inattendue (22023), ou un appelant autre que la
// direction en double verification (42501).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/montant.dart';
import '../finance/politique_commerciale.dart';
import '../finance/politique_famille.dart';
import 'port_politique_famille.dart';
import 'port_politiques_commerciales.dart';
import 'rpc_finance_supabase.dart';

const String _lecture = 'FI-BR-01';
const String _versions = 'FI-BR-02';
const String _famille = 'TRANSPARENCE';

/// Les politiques commerciales servies par Supabase.
class PolitiquesCommercialesSupabase implements PortPolitiquesCommerciales {
  /// Cree l'adaptateur sur le client de l'application.
  PolitiquesCommercialesSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  PolitiquesCommercialesSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<PolitiqueCommerciale> active() async => politiqueJson(
    await appelerFinance(_appel, 'politique_commerciale_active', _lecture),
  );

  @override
  Future<List<PolitiqueCommerciale>> versions() async => <PolitiqueCommerciale>[
    for (final Object? v in listeJson(
      await appelerFinance(
        _appel,
        'politiques_commerciales_versions',
        _versions,
      ),
      'versions',
    ))
      politiqueJson(v),
  ];

  @override
  Future<void> publier(PolitiqueCommerciale brouillon) async {
    politiqueJson(
      await appelerFinance(
        _appel,
        'publier_politique_commerciale',
        _versions,
        <String, dynamic>{'p_politique': politiqueVersJson(brouillon)},
      ),
    );
  }

  @override
  Future<ApercuFamille> apercuFamille(
    PolitiqueCommerciale brouillon,
    int enfants,
  ) async {
    final Map<String, dynamic> j = objetJson(
      await appelerFinance(
        _appel,
        'apercu_politique_famille',
        _lecture,
        <String, dynamic>{
          'p_politique': politiqueVersJson(brouillon),
          'p_enfants': enfants,
        },
      ),
      'apercu',
    );
    return ApercuFamille(
      enfants: <MensualiteApercu>[
        for (final Object? e in listeJson(j['enfants'], 'enfants'))
          _mensualite(objetJson(e, 'enfant')),
      ],
      total: montantJson(j['total'], 'total'),
    );
  }

  @override
  Future<ApercuEnseignant> apercuEnseignant(
    PolitiqueCommerciale brouillon, {
    required int capacite,
    required int eligibles,
  }) async {
    final Map<String, dynamic> j = objetJson(
      await appelerFinance(
        _appel,
        'apercu_politique_enseignant',
        _lecture,
        <String, dynamic>{
          'p_politique': politiqueVersJson(brouillon),
          'p_capacite': capacite,
          'p_eligibles': eligibles,
        },
      ),
      'apercu',
    );
    return ApercuEnseignant(
      capacite: entierJson(j, 'capacite'),
      eligibles: entierJson(j, 'eligibles'),
      baseHoraire: montantJson(j['baseHoraire'], 'baseHoraire'),
      occupation: montantJson(j['occupation'], 'occupation'),
      tauxHoraire: montantJson(j['tauxHoraire'], 'tauxHoraire'),
      plafondHoraire: montantJson(j['plafondHoraire'], 'plafondHoraire'),
    );
  }

  MensualiteApercu _mensualite(Map<String, dynamic> e) => MensualiteApercu(
    rang: entierJson(e, 'rang'),
    tarif: montantJson(e['tarif'], 'tarif'),
    remise: montantNullableJson(e['remise'], 'remise'),
    mensualite: montantJson(e['mensualite'], 'mensualite'),
  );
}

const Map<String, RailPaiement> _rails = <String, RailPaiement>{
  'webStripe': RailPaiement.webStripe,
  'iosStoreKit': RailPaiement.iosStoreKit,
  'androidPlay': RailPaiement.androidPlay,
};

const Map<String, NatureBudget> _natures = <String, NatureBudget>{
  'marketing': NatureBudget.marketing,
  'operationnel': NatureBudget.operationnel,
};

/// Une version de politique rendue par le serveur.
PolitiqueCommerciale politiqueJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'politique');
  final Map<String, dynamic> marge = objetJson(
    j['margeReferencePourMille'],
    'margeReferencePourMille',
  );
  final Object? relances = j['joursRelance'];
  return PolitiqueCommerciale(
    version: texteJson(j, 'version'),
    statut: switch (j['statut']) {
      'publiee' => StatutPolitique.publiee,
      'brouillon' => StatutPolitique.brouillon,
      final Object? s => throw FormatException('statut inconnu: $s'),
    },
    dateEffet: dateJson(j['dateEffet'], 'dateEffet'),
    tarifEnfant: montantJson(j['tarifEnfant'], 'tarifEnfant'),
    tarifAdulte: montantJson(j['tarifAdulte'], 'tarifAdulte'),
    essaisMax: entierJson(j, 'essaisMax'),
    essaiActif: booleenJson(j, 'essaiActif'),
    remisesParRang: <RemiseRang>[
      for (final Object? r in listeJson(j['remisesParRang'], 'remisesParRang'))
        _remiseRang(objetJson(r, 'remise')),
    ],
    baseHoraire: montantJson(j['baseHoraire'], 'baseHoraire'),
    plafondHoraire: montantJson(j['plafondHoraire'], 'plafondHoraire'),
    capaciteEnfant: entierJson(j, 'capaciteEnfant'),
    capaciteAdulte: entierJson(j, 'capaciteAdulte'),
    capaciteDebutant: entierJson(j, 'capaciteDebutant'),
    minimumOuverture: entierJson(j, 'minimumOuverture'),
    classesObjectif: entierJson(j, 'classesObjectif'),
    classesMax: entierJson(j, 'classesMax'),
    joursConservationPlace: entierJson(j, 'joursConservationPlace'),
    margeReferencePourMille: (
      objectif: entierJson(marge, 'objectif'),
      forte: entierJson(marge, 'forte'),
      stretch: entierJson(marge, 'stretch'),
    ),
    railsActifs: <RailPaiement>{
      for (final Object? r in listeJson(j['railsActifs'], 'railsActifs'))
        _rails[r] ?? (throw FormatException('rail inconnu: $r')),
    },
    allocationInternet: montantNullableJson(
      j['allocationInternet'],
      'allocationInternet',
    ),
    joursRelance: relances == null
        ? null
        : <int>[
            for (final Object? n in listeJson(relances, 'joursRelance'))
              n is int ? n : throw const FormatException('joursRelance'),
          ],
    budgets: <BudgetPilotage>[
      for (final Object? b in listeJson(j['budgets'], 'budgets'))
        BudgetPilotage(
          nature:
              _natures[objetJson(b, 'budget')['nature']] ??
              (throw const FormatException('nature de budget inconnue')),
          pourMille: entierJson(objetJson(b, 'budget'), 'pourMille'),
        ),
    ],
    tauxEleveHeureEnfant: montantNullableJson(
      j['tauxEleveHeureEnfant'],
      'tauxEleveHeureEnfant',
    ),
    tauxEleveHeureAdulte: montantNullableJson(
      j['tauxEleveHeureAdulte'],
      'tauxEleveHeureAdulte',
    ),
    plafondEleveHeureEnfant: montantNullableJson(
      j['plafondEleveHeureEnfant'],
      'plafondEleveHeureEnfant',
    ),
    plafondEleveHeureAdulte: montantNullableJson(
      j['plafondEleveHeureAdulte'],
      'plafondEleveHeureAdulte',
    ),
    dureeDueEnfantMinutes: _entierFacultatif(j, 'dureeDueEnfantMinutes'),
    dureeDueAdulteMinutes: _entierFacultatif(j, 'dureeDueAdulteMinutes'),
    prepaiementTrimestrielPourMille: _entierFacultatif(
      j,
      'prepaiementTrimestrielPourMille',
    ),
    prepaiementAnnuelPourMille: _entierFacultatif(
      j,
      'prepaiementAnnuelPourMille',
    ),
    parrainageCredit: montantNullableJson(
      j['parrainageCredit'],
      'parrainageCredit',
    ),
    boursePourMille: _entierFacultatif(j, 'boursePourMille'),
    boursePlacesPourMille: _entierFacultatif(j, 'boursePlacesPourMille'),
    bourseDureeMois: _entierFacultatif(j, 'bourseDureeMois'),
    cumulMaxPourMille: _entierFacultatif(j, 'cumulMaxPourMille'),
    jourSuspension: _entierFacultatif(j, 'jourSuspension'),
  );
}

/// Une remise de rang : en montant (`remise`) ou en pour mille du tarif
/// (`pourMille`), jamais les deux.
RemiseRang _remiseRang(Map<String, dynamic> r) {
  final int rang = entierJson(r, 'aPartirDuRang');
  final bool enMontant = r['remise'] != null;
  final bool enPourMille = r['pourMille'] != null;
  if (enMontant == enPourMille) {
    throw const FormatException('remise de rang : montant ou pour mille');
  }
  return enPourMille
      ? RemiseRang(aPartirDuRang: rang, pourMille: entierJson(r, 'pourMille'))
      : RemiseRang(
          aPartirDuRang: rang,
          remise: montantJson(r['remise'], 'remise'),
        );
}

/// Un entier que la version peut ne pas porter (absent ou nul : `null`).
int? _entierFacultatif(Map<String, dynamic> j, String cle) =>
    j[cle] == null ? null : entierJson(j, cle);

Map<String, Object?> _montantVersJson(Montant m) => <String, Object?>{
  'mineur': m.mineur,
  'devise': m.devise,
};

String _dateVersJson(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Une version de politique dans la forme que le serveur rend et relit.
Map<String, Object?> politiqueVersJson(PolitiqueCommerciale p) =>
    <String, Object?>{
      'version': p.version,
      'statut': p.statut == StatutPolitique.publiee ? 'publiee' : 'brouillon',
      'dateEffet': _dateVersJson(p.dateEffet),
      'tarifEnfant': _montantVersJson(p.tarifEnfant),
      'tarifAdulte': _montantVersJson(p.tarifAdulte),
      'essaisMax': p.essaisMax,
      'essaiActif': p.essaiActif,
      'remisesParRang': <Object?>[
        for (final RemiseRang r in p.remisesParRang)
          <String, Object?>{
            'aPartirDuRang': r.aPartirDuRang,
            if (r.remise case final Montant m) 'remise': _montantVersJson(m),
            if (r.pourMille case final int pm) 'pourMille': pm,
          },
      ],
      'baseHoraire': _montantVersJson(p.baseHoraire),
      'plafondHoraire': _montantVersJson(p.plafondHoraire),
      'capaciteEnfant': p.capaciteEnfant,
      'capaciteAdulte': p.capaciteAdulte,
      'capaciteDebutant': p.capaciteDebutant,
      'minimumOuverture': p.minimumOuverture,
      'classesObjectif': p.classesObjectif,
      'classesMax': p.classesMax,
      'joursConservationPlace': p.joursConservationPlace,
      'margeReferencePourMille': <String, Object?>{
        'objectif': p.margeReferencePourMille.objectif,
        'forte': p.margeReferencePourMille.forte,
        'stretch': p.margeReferencePourMille.stretch,
      },
      'railsActifs': <Object?>[
        for (final MapEntry<String, RailPaiement> e in _rails.entries)
          if (p.railsActifs.contains(e.value)) e.key,
      ],
      'allocationInternet': p.allocationInternet == null
          ? null
          : _montantVersJson(p.allocationInternet!),
      'joursRelance': p.joursRelance,
      'budgets': <Object?>[
        for (final BudgetPilotage b in p.budgets)
          <String, Object?>{
            'nature': b.nature == NatureBudget.marketing
                ? 'marketing'
                : 'operationnel',
            'pourMille': b.pourMille,
          },
      ],
      'tauxEleveHeureEnfant': _montantFacultatif(p.tauxEleveHeureEnfant),
      'tauxEleveHeureAdulte': _montantFacultatif(p.tauxEleveHeureAdulte),
      'plafondEleveHeureEnfant': _montantFacultatif(p.plafondEleveHeureEnfant),
      'plafondEleveHeureAdulte': _montantFacultatif(p.plafondEleveHeureAdulte),
      'dureeDueEnfantMinutes': p.dureeDueEnfantMinutes,
      'dureeDueAdulteMinutes': p.dureeDueAdulteMinutes,
      'prepaiementTrimestrielPourMille': p.prepaiementTrimestrielPourMille,
      'prepaiementAnnuelPourMille': p.prepaiementAnnuelPourMille,
      'parrainageCredit': _montantFacultatif(p.parrainageCredit),
      'boursePourMille': p.boursePourMille,
      'boursePlacesPourMille': p.boursePlacesPourMille,
      'bourseDureeMois': p.bourseDureeMois,
      'cumulMaxPourMille': p.cumulMaxPourMille,
      'jourSuspension': p.jourSuspension,
    };

Map<String, Object?>? _montantFacultatif(Montant? m) =>
    m == null ? null : _montantVersJson(m);

/// La politique lue par une famille (`politique_commerciale_famille`,
/// migration 20261031100000) : sans paie, marge ni budget.
class PolitiqueFamilleSupabase implements PortPolitiqueFamille {
  /// Cree l'adaptateur sur le client de l'application.
  PolitiqueFamilleSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  PolitiqueFamilleSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<PolitiqueFamille> lire() async => politiqueFamilleJson(
    await appelerFinance(_appel, 'politique_commerciale_famille', _famille),
  );
}

const Map<String, PosteRepartition> _postes = <String, PosteRepartition>{
  'enseignant': PosteRepartition.enseignant,
  'frais_carte_change': PosteRepartition.fraisCarteChange,
  'frais_envoi_paie': PosteRepartition.fraisEnvoiPaie,
  'visioconference': PosteRepartition.visioconference,
  'application_hebergement': PosteRepartition.applicationHebergement,
  'emails': PosteRepartition.emails,
  'stockage': PosteRepartition.stockage,
  'comptabilite': PosteRepartition.comptabilite,
  'developpement': PosteRepartition.developpement,
  'administration': PosteRepartition.administration,
  'impot_societes': PosteRepartition.impotSocietes,
  'benefice': PosteRepartition.benefice,
};

/// La politique d'une famille, au format rendu par le serveur. Une
/// repartition dont la somme n'est pas 1000 est refusee : la page ne montre
/// jamais un total faux.
PolitiqueFamille politiqueFamilleJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'politique');
  final Object? r = j['repartition'];
  return PolitiqueFamille(
    version: texteJson(j, 'version'),
    dateEffet: dateJson(j['dateEffet'], 'dateEffet'),
    tarifEnfant: montantJson(j['tarifEnfant'], 'tarifEnfant'),
    tarifAdulte: montantJson(j['tarifAdulte'], 'tarifAdulte'),
    essaiActif: booleenJson(j, 'essaiActif'),
    essaisMax: entierJson(j, 'essaisMax'),
    remisesParRang: <RemiseRang>[
      for (final Object? x in listeJson(j['remisesParRang'], 'remisesParRang'))
        _remiseRang(objetJson(x, 'remise')),
    ],
    railsActifs: <RailPaiement>{
      for (final Object? x in listeJson(j['railsActifs'], 'railsActifs'))
        _rails[x] ?? (throw FormatException('rail inconnu: $x')),
    },
    repartition: r == null
        ? null
        : _repartitionJson(objetJson(r, 'repartition')),
  );
}

RepartitionPaiement _repartitionJson(Map<String, dynamic> r) {
  final List<PartPoste> postes = <PartPoste>[
    for (final Object? x in listeJson(r['postes'], 'postes'))
      (
        poste:
            _postes[objetJson(x, 'poste')['poste']] ??
            (throw FormatException('poste inconnu: $x')),
        pourMille: entierJson(objetJson(x, 'poste'), 'pourMille'),
      ),
  ];
  final int somme = postes.fold(0, (int s, PartPoste p) => s + p.pourMille);
  if (somme != 1000) {
    throw FormatException('repartition : somme $somme au lieu de 1000');
  }
  return RepartitionPaiement(
    politiqueVersion: texteJson(r, 'politiqueVersion'),
    dateEffet: dateJson(r['dateEffet'], 'dateEffet'),
    baseElevesEnfants: entierJson(r, 'baseElevesEnfants'),
    baseElevesAdultes: entierJson(r, 'baseElevesAdultes'),
    postes: postes,
  );
}
