import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, comme dans le harnais partage.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';

/// Un corpus en memoire, reduit a ce que la conversion demande.
///
/// Aucun test ne peut interroger PostgREST : sans ce faux, la seule facon
/// d'exercer « 2:255 devient une page » serait une base reelle -- et la
/// conversion est precisement ce qui manquait pour que l'enseignant puisse
/// presenter un verset.
class _FauxServiceCoran implements ServiceCoran {
  /// Les pages connues, par reference « sourate:verset ».
  final Map<String, int> pages = <String, int>{'2:255': 42, '1:1': 1};

  /// Les references demandees, dans l'ordre. C'est par elles qu'un test constate
  /// qu'une meme reference ne relit pas deux fois.
  final List<String> demandes = <String>[];

  @override
  Future<String?> editionCourante() async => 'edition-test';

  @override
  Future<List<Sourate>?> sourates() async => const <Sourate>[];

  @override
  Future<PageCoran?> page(int numero) async =>
      PageCoran(numero: numero, versets: const <VersetCoran>[]);

  @override
  Future<int?> pageDe(int sourate, int verset) async {
    demandes.add('$sourate:$verset');
    return pages['$sourate:$verset'];
  }

  @override
  Future<PositionLecture?> position(String profilId) async => null;

  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => true;

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async => null;

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => const <VersetCoran>[];
}

void main() {
  group('De la reference a la page du mushaf', () {
    test('2:255 devient un numero de page presentable', () async {
      // Sans cette conversion, « pousser un verset » etait hors d'atteinte : une
      // page ne s'ouvre que par son numero, et rien dans le corpus ne le donnait
      // a partir d'une reference.
      final _FauxServiceCoran corpus = _FauxServiceCoran();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[serviceCoranProvider.overrideWithValue(corpus)],
      );
      addTearDown(conteneur.dispose);

      final int? page = await conteneur.read(
        pageDuVersetProvider((sourate: 2, verset: 255)).future,
      );

      expect(page, 42);
      expect(corpus.demandes, <String>['2:255']);
    });

    test('un verset inconnu rend null, jamais la page 1', () async {
      // « Je ne sais pas », jamais « page 1 » : ouvrir la Fatiha devant une
      // classe parce qu'une requete a echoue serait pire que ne rien presenter.
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          serviceCoranProvider.overrideWithValue(_FauxServiceCoran()),
        ],
      );
      addTearDown(conteneur.dispose);

      final int? page = await conteneur.read(
        pageDuVersetProvider((sourate: 114, verset: 7)).future,
      );

      expect(page, isNull);
    });

    test('la meme reference ne relit pas deux fois', () async {
      // La cle de famille est un enregistrement nomme : il compare ses champs
      // tout seul. Une classe sans `==` aurait relu le corpus a chaque tour de
      // page, et le cache de Riverpod n'aurait servi a rien.
      final _FauxServiceCoran corpus = _FauxServiceCoran();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[serviceCoranProvider.overrideWithValue(corpus)],
      );
      addTearDown(conteneur.dispose);

      await conteneur.read(
        pageDuVersetProvider((sourate: 2, verset: 255)).future,
      );
      await conteneur.read(
        pageDuVersetProvider((sourate: 2, verset: 255)).future,
      );

      expect(corpus.demandes, <String>['2:255']);
    });
  });
}
