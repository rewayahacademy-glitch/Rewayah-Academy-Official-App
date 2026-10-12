// Le double du port de partage pedagogique (PED-APRES-1).
//
// **Un petit simulateur de serveur**, pas un simple tiroir : il applique la
// priorite du contrat (publication ou revocation ciblee > exception eleve >
// classe > defaut) et le tableau de verite de la spec (section 2.3), pour que
// les tests de l'interface parcourent un aller-retour complet (la direction
// decide, la famille lit) sans rien supposer de plus que le contrat.
//
// PROPRIETE : tests PED-APRES-1. Aucune ligne de production ne l'importe. Les
// donnees « internes » que le serveur garde (notes, autres eleves, paie) sont
// posees ici expres : elles ne doivent jamais sortir par la projection.

import 'dart:async';

import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';

/// La decision manuelle de la direction sur un compte rendu.
enum DecisionManuelle {
  /// Aucune.
  aucune,

  /// Publie.
  publie,

  /// Revoque.
  revoque,
}

/// Un compte rendu cote serveur, avec ce qu'il ne faut jamais divulguer.
class RapportSim {
  /// Cree un rapport.
  RapportSim({
    this.confirme = true,
    this.autoPartage = true,
    this.contenu = const CompteRenduFamille(
      etat: EtatCompteRendu.partage,
      travaille: 'Sourate Al-Baqara, versets 20 a 30',
      appreciation: 'Tres bonne implication.',
      aRenforcer: <String>['Regles du madd'],
      aPreparer: <String>['Reviser les versets 31 a 40'],
      commentairePartage: 'Belle regularite.',
    ),
    this.decision = DecisionManuelle.aucune,
    this.corrigeApresPublication = false,
    this.version = 1,
  });

  /// Le cahier est confirme (K-45 valide, hors file hors ligne).
  bool confirme;

  /// Le compte rendu a ete partage automatiquement a la validation (la regle
  /// etait active ce jour-la). Une reactivation ne le change jamais.
  bool autoPartage;

  /// La projection familiale approuvee.
  CompteRenduFamille contenu;

  /// La decision manuelle.
  DecisionManuelle decision;

  /// Corrige apres une publication manuelle.
  bool corrigeApresPublication;

  /// Le jeton de concurrence de ce rapport.
  int version;

  /// Ce que le cahier brut contient et que la famille ne doit jamais lire.
  final List<String> interne = <String>[
    'NOTE INTERNE : parents difficiles',
    'AUTRE ELEVE : Ibrahim a rate son examen',
    'PAIE : 18 USD retenus',
  ];
}

/// Le simulateur.
class FauxPartagePedagogique implements PortPartagePedagogique {
  /// Cree le simulateur.
  FauxPartagePedagogique({this.taillePage = 25});

  /// L'effectif d'une page d'eleves.
  final int taillePage;

  /// Le partage automatique de la classe.
  bool classeActive = true;

  /// Les regles d'eleves (absente : regle de la classe).
  final Map<String, ReglePartageEleve> regles = <String, ReglePartageEleve>{};

  /// Les eleves de la classe (identifiant, nom).
  final Map<String, String> eleves = <String, String>{
    'e1': 'Yusuf Ahmad',
    'e2': 'Mariam Ali',
    'e3': 'Adam Hassan',
  };

  /// Les eleves retires de la classe.
  final Set<String> retires = <String>{};

  /// Les comptes rendus : (seance, eleve).
  final Map<(String, String), RapportSim> rapports =
      <(String, String), RapportSim>{};

  /// Le jeton de concurrence de la politique.
  int version = 1;

  /// La cle de chaque ecriture recue, dans l'ordre.
  final List<String> cles = <String>[];

  /// Chaque appel recu, par nom de methode.
  final List<String> appels = <String>[];

  /// Le journal serveur des lectures du cahier brut (qui, quand, quelle
  /// seance) : ici la seance et l'eleve lus.
  final List<(String, String)> lecturesJournalisees = <(String, String)>[];

  /// Les pages et filtres demandes a `comptesRendusClasse`.
  final List<(int, EtatDiffusion?)> demandesCahiers = <(int, EtatDiffusion?)>[];

  /// Les pages demandees a `partageClasse`.
  final List<int> pagesDemandees = <int>[];

  /// Les recherches recues par `partageClasse`.
  final List<String?> recherches = <String?>[];

  /// Une erreur a lever, par nom de methode, jusqu'a ce qu'on la retire.
  final Map<String, Object> erreurs = <String, Object>{};

  /// Une porte a ouvrir avant que la methode s'execute (envoi « en cours »).
  final Map<String, Completer<void>> portes = <String, Completer<void>>{};

  /// L'historique d'un rapport, si la source en fournit un (sinon `null`).
  List<ActionPartage>? historique;

  /// La classe est vide.
  bool vide = false;

  /// Un total d'eleves force (grandes classes) : les eleves sont generes.
  int? effectifGenere;

  /// Pose [n] eleves generes, `g1` a `gN`.
  void genererEleves(int n) => effectifGenere = n;

  /// Simule **une autre personne de la direction** qui modifie : la politique
  /// et chaque rapport changent de version, donc toute ecriture portant la
  /// version lue avant cet appel est refusee (conflit).
  void simulerAutreAdministrateur({bool? classeActive}) {
    version++;
    for (final RapportSim r in rapports.values) {
      r.version++;
    }
    if (classeActive != null) {
      this.classeActive = classeActive;
    }
  }

  // ---- la verite du serveur -------------------------------------------

  bool _regleEffective(String eleveId) => switch (regles[eleveId]) {
    ReglePartageEleve.toujours => true,
    ReglePartageEleve.jamais => false,
    _ => classeActive,
  };

  SourceRegle _source(String eleveId) =>
      regles[eleveId] == null ||
          regles[eleveId] == ReglePartageEleve.regleClasse
      ? SourceRegle.classe
      : SourceRegle.exceptionEleve;

  EtatDiffusion _etat(RapportSim r, String eleveId) {
    if (!r.confirme) {
      return EtatDiffusion.nonValide;
    }
    if (r.decision == DecisionManuelle.revoque) {
      return EtatDiffusion.revoque;
    }
    if (r.decision == DecisionManuelle.publie) {
      return r.corrigeApresPublication
          ? EtatDiffusion.corrigeApresPartageManuel
          : EtatDiffusion.partageManuel;
    }
    if (r.autoPartage && _regleEffective(eleveId)) {
      return EtatDiffusion.partageAuto;
    }
    return EtatDiffusion.confirmeNonPartage;
  }

  /// Ce que la famille lit : la regle effective et la decision ciblee.
  bool visiblePourLaFamille(String seanceId, String eleveId) {
    final RapportSim? r = rapports[(seanceId, eleveId)];
    if (r == null) {
      return false;
    }
    return switch (_etat(r, eleveId)) {
      EtatDiffusion.partageAuto ||
      EtatDiffusion.partageManuel ||
      EtatDiffusion.corrigeApresPartageManuel => true,
      _ => false,
    };
  }

  Future<void> _entree(String methode) async {
    appels.add(methode);
    final Completer<void>? porte = portes[methode];
    if (porte != null) {
      await porte.future;
    }
    final Object? e = erreurs[methode];
    if (e != null) {
      // ignore: only_throw_errors
      throw e;
    }
  }

  // ---- le port ----------------------------------------------------------

  @override
  Future<CompteRenduFamille> compteRenduFamille({
    required String seanceId,
    required String eleveId,
  }) async {
    await _entree('compteRenduFamille');
    final RapportSim? r = rapports[(seanceId, eleveId)];
    if (r == null || !r.confirme) {
      return const CompteRenduFamille(etat: EtatCompteRendu.enAttente);
    }
    if (!visiblePourLaFamille(seanceId, eleveId)) {
      return const CompteRenduFamille(etat: EtatCompteRendu.nonPartage);
    }
    return r.contenu.aDuContenu
        ? r.contenu
        : const CompteRenduFamille(etat: EtatCompteRendu.aucunChamp);
  }

  List<PartageEleve> _tous() {
    final int? n = effectifGenere;
    if (vide) {
      return const <PartageEleve>[];
    }
    final Iterable<MapEntry<String, String>> source = n == null
        ? eleves.entries
        : <MapEntry<String, String>>[
            for (int i = 1; i <= n; i++)
              MapEntry<String, String>('g$i', 'Eleve genere $i'),
          ];
    return <PartageEleve>[
      for (final MapEntry<String, String> e in source)
        PartageEleve(
          eleveId: e.key,
          libelle: e.value,
          regle: regles[e.key] ?? ReglePartageEleve.regleClasse,
          source: _source(e.key),
          visible: _regleEffective(e.key),
          situation: retires.contains(e.key)
              ? SituationEleveClasse.retire
              : SituationEleveClasse.actif,
          modifieLe: regles.containsKey(e.key)
              ? DateTime(2026, 10, 9, 14)
              : null,
          modifiePar: regles.containsKey(e.key) ? 'Direction' : null,
        ),
    ];
  }

  PartageClasse _lecture(String classeId, int page, String? recherche) {
    final String filtre = (recherche ?? '').trim().toLowerCase();
    final List<PartageEleve> tous = _tous()
        .where(
          (PartageEleve e) =>
              filtre.isEmpty || e.libelle.toLowerCase().contains(filtre),
        )
        .toList();
    final int debut = (page - 1) * taillePage;
    return PartageClasse(
      classeId: classeId,
      actif: classeActive,
      version: 'v$version',
      total: tous.length,
      page: page,
      eleves: tous.skip(debut).take(taillePage).toList(),
      modifieLe: DateTime(2026, 10, 9, 14, 20),
      modifiePar: 'Direction',
    );
  }

  @override
  Future<PartageClasse> partageClasse({
    required String classeId,
    int page = 1,
    String? recherche,
  }) async {
    await _entree('partageClasse');
    pagesDemandees.add(page);
    recherches.add(recherche);
    return _lecture(classeId, page, recherche);
  }

  void _verifierPolitique(String versionAttendue) {
    if (versionAttendue != 'v$version') {
      throw const ConflitPartage();
    }
  }

  @override
  Future<PartageClasse> definirPartageClasse({
    required String classeId,
    required bool actif,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    await _entree('definirPartageClasse');
    _verifierPolitique(versionAttendue);
    cles.add(cleIdempotence);
    classeActive = actif;
    version++;
    return _lecture(classeId, 1, null);
  }

  @override
  Future<PartageClasse> definirRegleEleve({
    required String classeId,
    required String eleveId,
    required ReglePartageEleve regle,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    await _entree('definirRegleEleve');
    _verifierPolitique(versionAttendue);
    cles.add(cleIdempotence);
    if (regle == ReglePartageEleve.regleClasse) {
      regles.remove(eleveId);
    } else {
      regles[eleveId] = regle;
    }
    version++;
    return _lecture(classeId, 1, null);
  }

  @override
  Future<List<LigneCompteRendu>> comptesRendusEleve({
    required String classeId,
    required String eleveId,
  }) async {
    await _entree('comptesRendusEleve');
    return <LigneCompteRendu>[
      for (final MapEntry<(String, String), RapportSim> e in rapports.entries)
        if (e.key.$2 == eleveId)
          LigneCompteRendu(
            seanceId: e.key.$1,
            seanceLe: DateTime(2026, 10, 8),
            etat: _etat(e.value, eleveId),
          ),
    ];
  }

  @override
  Future<PageCahiersClasse> comptesRendusClasse({
    required String classeId,
    int page = 1,
    EtatDiffusion? filtreEtat,
  }) async {
    await _entree('comptesRendusClasse');
    demandesCahiers.add((page, filtreEtat));
    final List<LigneCahierClasse> tout = <LigneCahierClasse>[
      for (final MapEntry<(String, String), RapportSim> e in rapports.entries)
        if (filtreEtat == null || _etat(e.value, e.key.$2) == filtreEtat)
          LigneCahierClasse(
            seanceId: e.key.$1,
            eleveId: e.key.$2,
            elevePrenom: (eleves[e.key.$2] ?? e.key.$2).split(' ').first,
            seanceLe: DateTime(2026, 10, 8),
            etat: _etat(e.value, e.key.$2),
          ),
    ];
    final int debut = (page - 1) * taillePage;
    return PageCahiersClasse(
      lignes: tout.skip(debut).take(taillePage).toList(),
      total: tout.length,
      page: page,
    );
  }

  @override
  Future<CahierAdmin> lireCahierAdmin({
    required String seanceId,
    required String eleveId,
  }) async {
    await _entree('lireCahierAdmin');
    final RapportSim r = rapports[(seanceId, eleveId)]!;
    lecturesJournalisees.add((seanceId, eleveId));
    return CahierAdmin(
      seanceId: seanceId,
      eleveId: eleveId,
      elevePrenom: (eleves[eleveId] ?? eleveId).split(' ').first,
      classeLibelle: 'Classe An-Nour',
      seanceLe: DateTime(2026, 10, 8, 18),
      confirme: r.confirme,
      enseignant: 'Sayyida Aicha',
      evaluation: <RubriqueInterne>[
        if ((r.contenu.travaille ?? '').isNotEmpty)
          RubriqueInterne(libelle: 'Travaille', texte: r.contenu.travaille!),
      ],
      detailsInternes: <RubriqueInterne>[
        // Contrat : jamais un autre eleve ni la paie, meme pour la direction.
        for (final String n in r.interne)
          if (n.startsWith('NOTE INTERNE'))
            RubriqueInterne(libelle: 'Note interne', texte: n),
      ],
    );
  }

  ApercuAdmin _apercu(String seanceId, String eleveId) {
    final RapportSim r = rapports[(seanceId, eleveId)]!;
    return ApercuAdmin(
      seanceId: seanceId,
      eleveId: eleveId,
      elevePrenom: (eleves[eleveId] ?? eleveId).split(' ').first,
      classeLibelle: 'Classe An-Nour',
      seanceLe: DateTime(2026, 10, 8, 18),
      enseignant: 'Sayyida Aicha',
      etat: _etat(r, eleveId),
      regleEffective: _regleEffective(eleveId),
      sourceRegle: _source(eleveId),
      // L'apercu est exactement la projection familiale approuvee.
      apercu: r.contenu,
      version: 'r${r.version}',
      historique: historique,
    );
  }

  @override
  Future<ApercuAdmin> apercuFamilial({
    required String seanceId,
    required String eleveId,
  }) async {
    await _entree('apercuFamilial');
    return _apercu(seanceId, eleveId);
  }

  @override
  Future<ApercuAdmin> publier({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    await _entree('publier');
    final RapportSim r = rapports[(seanceId, eleveId)]!;
    if (versionAttendue != 'r${r.version}') {
      throw const ConflitPartage();
    }
    cles.add(cleIdempotence);
    // Ne change NI la classe NI l'eleve : seul ce compte rendu.
    r
      ..decision = DecisionManuelle.publie
      ..version += 1;
    return _apercu(seanceId, eleveId);
  }

  @override
  Future<ApercuAdmin> revoquer({
    required String seanceId,
    required String eleveId,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    await _entree('revoquer');
    final RapportSim r = rapports[(seanceId, eleveId)]!;
    if (versionAttendue != 'r${r.version}') {
      throw const ConflitPartage();
    }
    cles.add(cleIdempotence);
    r
      ..decision = DecisionManuelle.revoque
      ..version += 1;
    return _apercu(seanceId, eleveId);
  }
}
