// MA-7 : le Coran de la demonstration du Mode Accessibilite, SANS serveur.
//
// Aucun corpus n'existe dans `lib/` hors du serveur, et la demonstration n'en
// invente pas : le lecteur existant y affiche donc son etat honnete « Le
// texte n'a pas pu etre charge ». Aucune position n'est lue ni ecrite. Les
// tests et les captures posent a la place le corpus de reference deja
// present dans les tests (`test/teaching_core/c/goldens`).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/coran/service_coran.dart' show PositionLecture;
import '../../core/tc_coran/corpus_service_coran.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/port_corpus_coran.dart';
import '../../core/tc_coran/port_navigation_coran.dart';

/// Les surcharges du Coran en demonstration : aucun appel serveur.
List<Override> surchargesCoranDemoAccessibilite() => <Override>[
  portCorpusCoranProvider.overrideWithValue(const _CorpusDemoAbsent()),
  portNavigationCoranProvider.overrideWithValue(const _NavigationDemo()),
];

class _CorpusDemoAbsent implements PortCorpusCoran {
  const _CorpusDemoAbsent();

  static const EchecCorpusCoran _echec = EchecCorpusCoran(
    'demonstration : aucun corpus hors serveur',
  );

  @override
  Future<List<SourateVM>> sourates() async => throw _echec;

  @override
  Future<PageCorpus?> page(int numeroPage) async => throw _echec;

  @override
  Future<PageCorpus?> pageDeAyah({
    required int sourate,
    required int ayah,
  }) async => null;

  @override
  Future<int?> pageDeDebutDeSourate(int sourate) async => null;

  @override
  Future<int?> pageDeDebutDeJuz(int juz) async => null;

  @override
  Future<List<ResultatRechercheCoran>> rechercher(String requete) async =>
      const <ResultatRechercheCoran>[];
}

class _NavigationDemo implements PortNavigationCoran {
  const _NavigationDemo();

  @override
  Future<int?> pageDe(CibleCoran cible) async => null;

  @override
  Future<PositionLecture?> dernierePositionPersonnelle() async => null;

  @override
  Future<bool> memoriserPositionPersonnelle(
    PositionLecture position, {
    required OrigineNavigation origine,
  }) async => false;

  @override
  Future<PositionLecture?> positionDeGroupe(String sessionId) async => null;

  @override
  Future<List<ResultatRechercheCoran>> rechercheRapide(String requete) async =>
      const <ResultatRechercheCoran>[];
}
