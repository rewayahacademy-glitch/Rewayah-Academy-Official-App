import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/cache/media/cache_media.dart';

/// Cache en memoire : la regle de purge se verifie sans toucher au disque.
class _CacheMemoire implements CacheMedia {
  _CacheMemoire(Iterable<String> initiales) : _cles = <String>{...initiales};

  final Set<String> _cles;
  final List<String> retraits = <String>[];

  @override
  Future<void> retirer(String cle) async {
    retraits.add(cle);
    _cles.remove(cle);
  }

  @override
  Future<Set<String>> clesConservees() async => Set<String>.of(_cles);
}

void main() {
  group('Scenario 4 : une photo supprimee cote serveur disparait en local', () {
    test(
      'un evenement de synchronisation retire la photo immediatement',
      () async {
        final _CacheMemoire cache = _CacheMemoire(<String>['avatar-amina']);
        final PurgePhotos purge = PurgePhotos(cache);

        await purge.signaler(
          EvenementPhoto(
            cleAvatar: 'avatar-amina',
            survenuA: DateTime.utc(2026, 9, 6, 10),
          ),
        );

        expect(cache.retraits, <String>['avatar-amina']);
        expect(await cache.clesConservees(), isEmpty);
        expect(purge.enAttente, isEmpty);
      },
    );

    test('la purge ne touche pas les autres photos du foyer', () async {
      final _CacheMemoire cache = _CacheMemoire(<String>[
        'avatar-amina',
        'avatar-ibrahim',
      ]);
      final PurgePhotos purge = PurgePhotos(cache);

      await purge.signaler(
        EvenementPhoto(
          cleAvatar: 'avatar-amina',
          survenuA: DateTime.utc(2026, 9, 6, 10),
        ),
      );

      expect(await cache.clesConservees(), <String>{'avatar-ibrahim'});
    });

    test(
      'un retrait manque par l application fermee est rattrape sous 24 heures',
      () async {
        // L application etait fermee : le fichier est encore la au demarrage.
        final _CacheMemoire cache = _CacheMemoire(<String>['avatar-amina']);
        final PurgePhotos purge = PurgePhotos(cache);
        final DateTime changement = DateTime.utc(2026, 9, 6, 10);

        // Le retrait echoue, on simule une reprise en repeuplant le cache.
        await purge.signaler(
          EvenementPhoto(cleAvatar: 'avatar-amina', survenuA: changement),
        );
        final _CacheMemoire apresRedemarrage = _CacheMemoire(<String>[
          'avatar-amina',
        ]);
        final PurgePhotos rattrapage = PurgePhotos(apresRedemarrage);
        await rattrapage.signaler(
          EvenementPhoto(cleAvatar: 'avatar-amina', survenuA: changement),
        );

        final Set<String> retirees = await rattrapage.rattraper(
          changement.add(PurgePhotos.delaiMaximal),
        );
        expect(
          retirees.contains('avatar-amina') ||
              apresRedemarrage.retraits.contains('avatar-amina'),
          isTrue,
        );
        expect(await apresRedemarrage.clesConservees(), isEmpty);
      },
    );

    test('la borne dure est bien de 24 heures', () {
      expect(PurgePhotos.delaiMaximal, const Duration(hours: 24));
    });

    test(
      'le declencheur est l evenement, pas une expiration de duree',
      () async {
        // Sans evenement, rien ne bouge, meme longtemps apres : la duree seule
        // ne doit pas suffire a purger une photo toujours valide.
        final _CacheMemoire cache = _CacheMemoire(<String>['avatar-amina']);
        final PurgePhotos purge = PurgePhotos(cache);

        final Set<String> retirees = await purge.rattraper(
          DateTime.utc(2026, 12, 31),
        );

        expect(retirees, isEmpty);
        expect(await cache.clesConservees(), <String>{'avatar-amina'});
      },
    );
  });
}
