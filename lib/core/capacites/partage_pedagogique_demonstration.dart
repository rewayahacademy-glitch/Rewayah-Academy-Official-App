// DEMONSTRATION du partage pedagogique (PED-APRES-1). **Fictive, en memoire.**
//
// Branchee uniquement par `portPartagePedagogiqueSelon(demo: true)`, c'est-a-
// dire sous `PLAYGROUND=true`, que le deploiement force a `false`. Aucun nom,
// aucune date, aucun compte rendu d'ici n'est une donnee reelle ; aucun
// contenu interne n'y figure (le type ne sait pas en porter).

import 'port_partage_pedagogique.dart';

/// Le partage pedagogique de demonstration : une classe fictive, quatre eleves
/// fictifs, trois seances, et les memes regles de priorite que le contrat.
class PartagePedagogiqueDemonstration implements PortPartagePedagogique {
  /// Cree la demonstration.
  PartagePedagogiqueDemonstration();

  bool _classeActive = true;
  int _version = 1;
  final Map<String, ReglePartageEleve> _regles = <String, ReglePartageEleve>{
    'demo-eleve-2': ReglePartageEleve.toujours,
    'demo-eleve-3': ReglePartageEleve.jamais,
  };
  final Map<String, EtatDiffusion> _etats = <String, EtatDiffusion>{};

  static const List<(String, String)> _eleves = <(String, String)>[
    ('demo-eleve-1', 'Eleve demo 1'),
    ('demo-eleve-2', 'Eleve demo 2'),
    ('demo-eleve-3', 'Eleve demo 3'),
    ('demo-eleve-4', 'Eleve demo 4'),
  ];

  static const CompteRenduFamille _contenu = CompteRenduFamille(
    etat: EtatCompteRendu.partage,
    travaille: 'Passage de demonstration, lecture et prononciation.',
    appreciation: 'Appreciation de demonstration.',
    aRenforcer: <String>[
      'Point de demonstration A',
      'Point de demonstration B',
    ],
    aPreparer: <String>['Travail de demonstration'],
  );

  String get _jeton => 'demo-v$_version';

  SourceRegle _source(String eleveId) => switch (_regles[eleveId]) {
    ReglePartageEleve.toujours ||
    ReglePartageEleve.jamais => SourceRegle.exceptionEleve,
    _ => SourceRegle.classe,
  };

  bool _visible(String eleveId) => switch (_regles[eleveId]) {
    ReglePartageEleve.toujours => true,
    ReglePartageEleve.jamais => false,
    _ => _classeActive,
  };

  EtatDiffusion _etat(String seanceId, String eleveId) =>
      _etats['$seanceId/$eleveId'] ??
      (_visible(eleveId)
          ? EtatDiffusion.partageAuto
          : EtatDiffusion.confirmeNonPartage);

  PartageClasse _lecture(String classeId, {String? recherche}) {
    final String filtre = (recherche ?? '').trim().toLowerCase();
    return PartageClasse(
      classeId: classeId,
      actif: _classeActive,
      version: _jeton,
      total: _eleves.length,
      eleves: <PartageEleve>[
        for (final (String id, String nom) in _eleves)
          if (filtre.isEmpty || nom.toLowerCase().contains(filtre))
            PartageEleve(
              eleveId: id,
              libelle: nom,
              regle: _regles[id] ?? ReglePartageEleve.regleClasse,
              source: _source(id),
              visible: _visible(id),
            ),
      ],
    );
  }

  void _verifier(String versionAttendue) {
    if (versionAttendue != _jeton) {
      throw const ConflitPartage();
    }
  }

  @override
  Future<CompteRenduFamille> compteRenduFamille({
    required String seanceId,
    required String eleveId,
  }) async {
    final EtatDiffusion etat = _etat(seanceId, eleveId);
    final bool visible =
        etat == EtatDiffusion.partageAuto ||
        etat == EtatDiffusion.partageManuel;
    return visible
        ? _contenu
        : const CompteRenduFamille(etat: EtatCompteRendu.nonPartage);
  }

  @override
  Future<PartageClasse> partageClasse({
    required String classeId,
    int page = 1,
    String? recherche,
  }) async => _lecture(classeId, recherche: recherche);

  @override
  Future<PartageClasse> definirPartageClasse({
    required String classeId,
    required bool actif,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    _verifier(versionAttendue);
    _classeActive = actif;
    _version++;
    return _lecture(classeId);
  }

  @override
  Future<PartageClasse> definirRegleEleve({
    required String classeId,
    required String eleveId,
    required ReglePartageEleve regle,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    _verifier(versionAttendue);
    if (regle == ReglePartageEleve.regleClasse) {
      _regles.remove(eleveId);
    } else {
      _regles[eleveId] = regle;
    }
    _version++;
    return _lecture(classeId);
  }

  @override
  Future<List<LigneCompteRendu>> comptesRendusEleve({
    required String classeId,
    required String eleveId,
  }) async => <LigneCompteRendu>[
    for (final (int i, String s) in <(int, String)>[
      (3, 'demo-seance-3'),
      (10, 'demo-seance-2'),
      (17, 'demo-seance-1'),
    ])
      LigneCompteRendu(
        seanceId: s,
        seanceLe: DateTime(2026, 10, 18 - i),
        etat: _etat(s, eleveId),
      ),
  ];

  ApercuAdmin _apercu(String seanceId, String eleveId) {
    final EtatDiffusion etat = _etat(seanceId, eleveId);
    final String nom = _eleves.firstWhere((e) => e.$1 == eleveId).$2;
    return ApercuAdmin(
      seanceId: seanceId,
      eleveId: eleveId,
      elevePrenom: nom,
      classeLibelle: 'Classe de demonstration',
      seanceLe: DateTime(2026, 10, 8, 18),
      etat: etat,
      regleEffective: _visible(eleveId),
      sourceRegle: _source(eleveId),
      apercu: _contenu,
      version: '$_jeton/$seanceId/$eleveId/${etat.name}',
    );
  }

  @override
  Future<ApercuAdmin> apercuFamilial({
    required String seanceId,
    required String eleveId,
  }) async => _apercu(seanceId, eleveId);

  @override
  Future<ApercuAdmin> publier({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    if (versionAttendue != _apercu(seanceId, eleveId).version) {
      throw const ConflitPartage();
    }
    _etats['$seanceId/$eleveId'] = EtatDiffusion.partageManuel;
    return _apercu(seanceId, eleveId);
  }

  @override
  Future<ApercuAdmin> revoquer({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    if (versionAttendue != _apercu(seanceId, eleveId).version) {
      throw const ConflitPartage();
    }
    _etats['$seanceId/$eleveId'] = EtatDiffusion.revoque;
    return _apercu(seanceId, eleveId);
  }
}
