import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';

import '../goldens/corpus_reference.dart';

/// Un corpus en memoire, pose sur le golden.
///
/// **Il ne recopie pas la logique de l'adaptateur** : il rend les donnees, et
/// c'est le moteur qui est teste. L'adaptateur reel, lui, se teste separement
/// au-dessus d'un faux `ServiceCoran`.
class FauxCorpusCoran implements PortCorpusCoran {
  /// Cree un corpus a partir du golden.
  FauxCorpusCoran(this.reference);

  /// Le corpus de reference.
  final CorpusReference reference;

  /// Mis a vrai pour verifier le chemin « lecture impossible ».
  bool echoue = false;

  @override
  Future<List<SourateVM>> sourates() async {
    if (echoue) {
      throw const EchecCorpusCoran('faux corpus en echec');
    }
    return reference.sourates;
  }

  @override
  Future<PageCorpus?> page(int numeroPage) async {
    if (echoue) {
      throw const EchecCorpusCoran('faux corpus en echec');
    }
    for (final PageCorpus p in reference.pages) {
      if (p.numero == numeroPage) {
        return p;
      }
    }
    return null;
  }

  @override
  Future<PageCorpus?> pageDeAyah({
    required int sourate,
    required int ayah,
  }) async {
    for (final PageCorpus p in reference.pages) {
      for (final VersetCorpus v in p.versets) {
        if (v.sourate == sourate && v.numero == ayah) {
          return p;
        }
      }
    }
    return null;
  }

  @override
  Future<int?> pageDeDebutDeSourate(int sourate) async =>
      (await pageDeAyah(sourate: sourate, ayah: 1))?.numero;

  @override
  Future<int?> pageDeDebutDeJuz(int juz) async {
    for (final PageCorpus p in reference.pages) {
      if (p.juzNumero == juz) {
        return p.numero;
      }
    }
    return null;
  }

  @override
  Future<List<ResultatRechercheCoran>> rechercher(String requete) async =>
      const <ResultatRechercheCoran>[];
}

/// Un `ServiceCoran` en memoire, pose sur le golden.
///
/// Sert a tester l'adaptateur reel `CorpusDepuisServiceCoran` et la barriere
/// d'ecriture de la position personnelle, sans Supabase.
class FauxServiceCoranGolden implements ServiceCoran {
  /// Cree le faux service.
  FauxServiceCoranGolden(this.reference);

  /// Le corpus de reference.
  final CorpusReference reference;

  /// Mis a vrai pour que toutes les lectures rendent `null`.
  bool echoue = false;

  /// Les positions ecrites, pour verifier ce qui a ete persiste.
  final List<PositionLecture> ecritures = <PositionLecture>[];

  /// La position deja enregistree, quand le test en pose une.
  PositionLecture? positionEnregistree;

  @override
  Future<String?> editionCourante() async => echoue ? null : 'edition-de-test';

  @override
  Future<List<Sourate>?> sourates() async {
    if (echoue) {
      return null;
    }
    return <Sourate>[
      for (final SourateVM s in reference.sourates)
        Sourate(
          numero: s.numero,
          nomArabe: s.nomArabe,
          nomTranslittere: s.nomTranslittere,
          lieuRevelation: s.mecquoise ? 'mecque' : 'medine',
          nombreVersets: s.nombreVersets,
        ),
    ];
  }

  @override
  Future<PageCoran?> page(int numero) async {
    if (echoue) {
      return null;
    }
    for (final PageCorpus p in reference.pages) {
      if (p.numero != numero) {
        continue;
      }
      return PageCoran(
        numero: p.numero,
        juzNumero: p.juzNumero,
        versets: <VersetCoran>[
          for (final VersetCorpus v in p.versets)
            VersetCoran(
              sourateNumero: v.sourate,
              numero: v.numero,
              texte: v.texte,
              pageNumero: v.pageNumero,
            ),
        ],
      );
    }
    return PageCoran(numero: numero, versets: const <VersetCoran>[]);
  }

  @override
  Future<int?> pageDe(int sourate, int verset) async {
    if (echoue) {
      return null;
    }
    for (final PageCorpus p in reference.pages) {
      for (final VersetCorpus v in p.versets) {
        if (v.sourate == sourate && v.numero == verset) {
          return p.numero;
        }
      }
    }
    return null;
  }

  @override
  Future<PositionLecture?> position(String profilId) async =>
      positionEnregistree;

  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async {
    ecritures.add(position);
    positionEnregistree = position;
    return true;
  }

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async {
    if (echoue) {
      return null;
    }
    for (final PageCorpus p in reference.pages) {
      if (p.juzNumero != juz || p.versets.isEmpty) {
        continue;
      }
      final VersetCorpus premier = p.versets.first;
      return (sourate: premier.sourate, verset: premier.numero);
    }
    return null;
  }

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async {
    if (echoue) {
      return null;
    }
    final String aiguille = requete.toLowerCase();
    final List<VersetCoran> trouves = <VersetCoran>[];
    for (final PageCorpus p in reference.pages) {
      for (final VersetCorpus v in p.versets) {
        if (!v.texte.toLowerCase().contains(aiguille)) {
          continue;
        }
        trouves.add(
          VersetCoran(
            sourateNumero: v.sourate,
            numero: v.numero,
            texte: v.texte,
            pageNumero: v.pageNumero,
          ),
        );
        if (trouves.length >= limite) {
          return trouves;
        }
      }
    }
    return trouves;
  }
}

/// Une navigation en memoire, pour monter un ecran sans session ni Supabase.
class FauxNavigationCoran implements PortNavigationCoran {
  /// Cree la navigation.
  FauxNavigationCoran({this.personnelle, this.groupe});

  /// La position personnelle rendue par le port.
  PositionLecture? personnelle;

  /// La position de groupe rendue par le port.
  PositionLecture? groupe;

  /// Les positions que l'ecran a demande d'ecrire, avec leur origine.
  final List<({PositionLecture position, OrigineNavigation origine})>
  ecritures = <({PositionLecture position, OrigineNavigation origine})>[];

  @override
  Future<int?> pageDe(CibleCoran cible) async => switch (cible) {
    CiblePage(page: final int page) => page,
    CibleSourate(sourate: final int sourate) => sourate,
    CibleJuz(juz: final int juz) => juz,
    CibleAyah(sourate: final int sourate) => sourate,
  };

  @override
  Future<PositionLecture?> dernierePositionPersonnelle() async => personnelle;

  @override
  Future<bool> memoriserPositionPersonnelle(
    PositionLecture position, {
    required OrigineNavigation origine,
  }) async {
    ecritures.add((position: position, origine: origine));
    return origine == OrigineNavigation.personnelle;
  }

  @override
  Future<PositionLecture?> positionDeGroupe(String sessionId) async => groupe;

  @override
  Future<List<ResultatRechercheCoran>> rechercheRapide(String requete) async =>
      const <ResultatRechercheCoran>[];
}

/// Une source de layout qui se dit fidele et rend de vraies lignes.
///
/// **Elle n'existe que dans les tests.** Aucune donnee de ligne n'existe dans
/// le depot ; ce faux sert a verifier que le chemin « lignes reelles » du
/// moteur et du renderer fonctionne le jour ou une source apparaitra, et que
/// `DisponibiliteLayout.fidele` remonte bien jusqu'a l'ecran.
class FauxLayoutFidele implements PortLayoutMushaf {
  /// Cree la source.
  const FauxLayoutFidele(this.lignesParPage);

  /// Les lignes servies, par numero de page.
  final Map<int, List<SectionLigne>> lignesParPage;

  @override
  Future<DisponibiliteLayout> disponibilite() async =>
      DisponibiliteLayout.fidele;

  @override
  Future<LayoutPage?> layoutDe(int numeroPage) async {
    final List<SectionLigne>? lignes = lignesParPage[numeroPage];
    if (lignes == null) {
      return null;
    }
    return LayoutPage(
      numeroPage: numeroPage,
      lignes: lignes,
      nombreLignes: lignes.length,
      ratioLargeurSurHauteur: 2 / 3,
    );
  }
}
