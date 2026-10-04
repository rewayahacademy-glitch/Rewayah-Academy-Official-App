// PT-B-CORAN-ADULTE : le corpus du Coran de la DEMONSTRATION, sans serveur.
//
// La demonstration n'a aucun serveur (K-28) ; sans corpus, la vraie page
// Coran ne pouvait afficher que son erreur reseau. Ce service rend le MEME
// corpus que la base, recopie mot pour mot de la migration
// `0013_corpus_coranique.sql` (Tanzil, Mushaf de Medine, riwaya Hafs) dans
// `corpus_demo_coran_donnees.dart`, et verifie verset par verset par
// `test/features/demo/corpus_demo_coran_test.dart`. Rien n'est invente,
// rien n'est modifie : la licence l'interdit, et le bon sens avant elle.
//
// Il implemente le contrat existant `ServiceCoran` : au-dessus de lui, ce
// sont l'adaptateur reel (`CorpusDepuisServiceCoran`), la navigation reelle
// (`NavigationCoran`) et la vraie `MushafPage` qui travaillent. Aucune
// position n'est lue ni ecrite (aucun profil en demonstration).
//
// Cette bibliotheque est chargee en DIFFERE (`deferred as`) par
// `coran_demo_adulte.dart` : son texte (1,4 Mo) ne pese sur aucun autre
// ecran.

import '../../core/coran/service_coran.dart';
import 'corpus_demo_coran_donnees.dart';

/// Le corpus de la demonstration, lu une fois.
final _CorpusDemo _corpus = _CorpusDemo.lire();

/// Cree le service du Coran de la demonstration.
ServiceCoran creerServiceCoranDemo() => const ServiceCoranDemo();

/// Le `ServiceCoran` de la demonstration : le corpus de la base, en memoire.
class ServiceCoranDemo implements ServiceCoran {
  /// Cree le service.
  const ServiceCoranDemo();

  @override
  Future<String?> editionCourante() async => codeMushafReference;

  @override
  Future<List<Sourate>?> sourates() async => _corpus.sourates;

  @override
  Future<PageCoran?> page(int numero) async => PageCoran(
    numero: numero,
    // Comme la base : une page hors de l'edition ne porte aucun verset.
    versets: _corpus.versetsParPage[numero] ?? const <VersetCoran>[],
    juzNumero: _corpus.juzParPage[numero],
  );

  @override
  Future<int?> pageDe(int sourate, int verset) async =>
      _corpus.pageParReference['$sourate:$verset'];

  /// Aucun profil en demonstration : aucune position a relire.
  @override
  Future<PositionLecture?> position(String profilId) async => null;

  /// Aucun profil en demonstration : rien n'est enregistre.
  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => false;

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async =>
      _corpus.debutsDeJuz[juz];

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => _corpus.versets
      .where((VersetCoran v) => v.texte.contains(requete))
      .take(limite)
      .toList(growable: false);
}

/// Le corpus lu depuis les donnees recopiees de la migration.
class _CorpusDemo {
  _CorpusDemo._({
    required this.sourates,
    required this.versets,
    required this.versetsParPage,
    required this.juzParPage,
    required this.pageParReference,
    required this.debutsDeJuz,
  });

  factory _CorpusDemo.lire() {
    final List<Sourate> sourates = <Sourate>[
      for (final List<String> c in _lignes(souratesDemo))
        Sourate(
          numero: int.parse(c[0]),
          nomArabe: c[1],
          nomTranslittere: c[2],
          lieuRevelation: c[3],
          nombreVersets: int.parse(c[4]),
        ),
    ];
    final List<VersetCoran> versets = <VersetCoran>[
      for (final List<String> c in _lignes(versetsDemo, champs: 4))
        VersetCoran(
          sourateNumero: int.parse(c[0]),
          numero: int.parse(c[1]),
          pageNumero: int.parse(c[2]),
          texte: c[3],
        ),
    ];
    final Map<int, List<VersetCoran>> parPage = <int, List<VersetCoran>>{};
    for (final VersetCoran v in versets) {
      (parPage[v.pageNumero] ??= <VersetCoran>[]).add(v);
    }
    return _CorpusDemo._(
      sourates: List<Sourate>.unmodifiable(sourates),
      versets: List<VersetCoran>.unmodifiable(versets),
      versetsParPage: <int, List<VersetCoran>>{
        for (final MapEntry<int, List<VersetCoran>> e in parPage.entries)
          e.key: List<VersetCoran>.unmodifiable(e.value),
      },
      juzParPage: <int, int>{
        for (final List<String> c in _lignes(pagesDemo))
          int.parse(c[0]): int.parse(c[1]),
      },
      pageParReference: <String, int>{
        for (final VersetCoran v in versets) v.reference: v.pageNumero,
      },
      debutsDeJuz: <int, ({int sourate, int verset})>{
        for (final List<String> c in _lignes(juzDemo))
          int.parse(c[0]): (sourate: int.parse(c[1]), verset: int.parse(c[2])),
      },
    );
  }

  final List<Sourate> sourates;
  final List<VersetCoran> versets;
  final Map<int, List<VersetCoran>> versetsParPage;
  final Map<int, int> juzParPage;
  final Map<String, int> pageParReference;
  final Map<int, ({int sourate, int verset})> debutsDeJuz;

  /// Les lignes non vides d'un bloc, decoupees sur `|`. Avec [champs], le
  /// dernier champ garde tout le reste de la ligne (le texte d'un verset).
  static Iterable<List<String>> _lignes(String bloc, {int? champs}) sync* {
    for (final String ligne in bloc.split('\n')) {
      if (ligne.isEmpty) {
        continue;
      }
      if (champs == null) {
        yield ligne.split('|');
        continue;
      }
      final List<String> morceaux = <String>[];
      String reste = ligne;
      for (int i = 0; i < champs - 1; i++) {
        final int barre = reste.indexOf('|');
        morceaux.add(reste.substring(0, barre));
        reste = reste.substring(barre + 1);
      }
      morceaux.add(reste);
      yield morceaux;
    }
  }
}
