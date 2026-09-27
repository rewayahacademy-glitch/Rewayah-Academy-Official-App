import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` et `FutureProviderFamily` ne sont pas exportes par l'entree
// principale de Riverpod 3 : ils vivent dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily, Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';

import '../fixtures/tuteur/foyers.dart';
import '../support/harnais.dart';

ProviderContainer _conteneur(List<EleveDuFoyer> eleves) {
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = eleves;
  final ProviderContainer conteneur = ProviderContainer(
    overrides: <Override>[
      serviceAppairageProvider.overrideWithValue(appairage),
    ],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

Future<ProfilEleveFoyer?> _retenu(ProviderContainer conteneur) async {
  await conteneur.read(profilsElevesFoyerProvider.future);
  final AsyncValue<ProfilEleveFoyer?> valeur = conteneur.read(
    eleveSelectionneProvider,
  );
  expect(valeur.hasValue, isTrue);
  return valeur.value;
}

void main() {
  group('K1 : le profil retenu', () {
    test('sans demande, le premier profil du foyer est retenu', () async {
      // Le foyer est rendu dans le desordre : le tri explicite garde le meme
      // premier profil d'une lecture a l'autre.
      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerA);

      expect((await _retenu(conteneur))?.eleveId, FoyersFictifs.a1.id);
    });

    test('un profil demande et connu du foyer est retenu', () async {
      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerA);
      conteneur
          .read(selectionEleveProvider.notifier)
          .choisir(FoyersFictifs.a2.id);

      expect((await _retenu(conteneur))?.eleveId, FoyersFictifs.a2.id);
    });

    test('un identifiant inconnu du foyer est ignore, jamais servi', () async {
      // L'identifiant d'un eleve du foyer B, arrive par `?eleve=` : la
      // selection n'est pas une autorisation, le premier profil du foyer A est
      // retenu et aucun profil du foyer B n'apparait.
      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerA);
      conteneur
          .read(selectionEleveProvider.notifier)
          .choisir(FoyersFictifs.b1.id);

      final ProfilEleveFoyer? retenu = await _retenu(conteneur);
      expect(retenu?.eleveId, FoyersFictifs.a1.id);
      final List<ProfilEleveFoyer> profils = await conteneur.read(
        profilsElevesFoyerProvider.future,
      );
      expect(
        profils.map((ProfilEleveFoyer p) => p.eleveId),
        isNot(contains(FoyersFictifs.b1.id)),
      );
    });

    test('un foyer vide rend une valeur nulle, pas une erreur', () async {
      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerVide);

      expect(await _retenu(conteneur), isNull);
      expect(conteneur.read(eleveSelectionneProvider).hasError, isFalse);
    });

    test('effacer la demande revient au premier profil', () async {
      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerA);
      final SelectionEleveControleur selection = conteneur.read(
        selectionEleveProvider.notifier,
      );
      selection.choisir(FoyersFictifs.a2.id);
      expect((await _retenu(conteneur))?.eleveId, FoyersFictifs.a2.id);

      selection.effacer();
      expect((await _retenu(conteneur))?.eleveId, FoyersFictifs.a1.id);
    });

    test('un profil du foyer porte la nature membre du foyer', () async {
      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerA);

      final ProfilEleveFoyer? retenu = await _retenu(conteneur);
      expect(retenu?.nature, NatureProfilEleve.membreDuFoyer);
      expect(retenu, FoyersFictifs.profil(FoyersFictifs.a1));
    });
  });

  group('K1 : aucune valeur residuelle entre deux eleves', () {
    test('le bloc d un eleve ne montre jamais la donnee du precedent', () async {
      // Un bloc dependant d'un eleve lit la selection puis une famille indexee
      // par `eleveId`. Changer d'eleve change de cle : pendant le chargement du
      // second, le bloc est en attente, sans la donnee du premier.
      final Map<String, Completer<String>> lectures =
          <String, Completer<String>>{
            FoyersFictifs.a1.id: Completer<String>(),
            FoyersFictifs.a2.id: Completer<String>(),
          };
      final FutureProviderFamily<String, String> donneeDeLEleve =
          FutureProvider.family<String, String>(
            (Ref ref, String eleveId) => lectures[eleveId]!.future,
          );
      final Provider<AsyncValue<String>> bloc = Provider<AsyncValue<String>>((
        Ref ref,
      ) {
        final String? eleveId = ref
            .watch(eleveSelectionneProvider)
            .value
            ?.eleveId;
        if (eleveId == null) {
          return const AsyncLoading<String>();
        }
        return ref.watch(donneeDeLEleve(eleveId));
      });

      final ProviderContainer conteneur = _conteneur(FoyersFictifs.foyerA);
      conteneur.listen<AsyncValue<String>>(
        bloc,
        (AsyncValue<String>? _, AsyncValue<String> _) {},
      );
      await conteneur.read(profilsElevesFoyerProvider.future);

      lectures[FoyersFictifs.a1.id]!.complete('donnee de A1');
      await conteneur.read(donneeDeLEleve(FoyersFictifs.a1.id).future);
      expect(conteneur.read(bloc).value, 'donnee de A1');

      conteneur
          .read(selectionEleveProvider.notifier)
          .choisir(FoyersFictifs.a2.id);
      final AsyncValue<String> pendant = conteneur.read(bloc);
      expect(pendant.isLoading, isTrue);
      expect(pendant.value, isNull);

      lectures[FoyersFictifs.a2.id]!.complete('donnee de A2');
      await conteneur.read(donneeDeLEleve(FoyersFictifs.a2.id).future);
      expect(conteneur.read(bloc).value, 'donnee de A2');
    });
  });
}
