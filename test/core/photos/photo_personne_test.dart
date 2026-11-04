// PHOTOS-2a : une seule photo par personne, la meme partout.
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/photos/photos_supabase.dart';

class _FauxPort implements PortPhotos {
  _FauxPort(this.connues);

  final Map<String, SourcePhoto> connues;
  final List<String> posees = <String>[];
  int lectures = 0;

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async {
    lectures++;
    return <String, SourcePhoto>{
      for (final String id in profileIds)
        if (connues[id] case final SourcePhoto s) id: s,
    };
  }

  @override
  Future<String> urlSignee(String seau, String cle) async =>
      'https://signee.test/$seau/$cle';

  @override
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  }) async => '$profileId/1.${photo.extension}';

  @override
  Future<SourcePhoto?> poserMaPhoto(String? cle) async {
    posees.add(cle ?? '-');
    return null;
  }

  @override
  Future<SourcePhoto?> poserPhotoEleve(String eleveId, String? cle) async =>
      null;
}

void main() {
  test('la photo visible rend une URL signee de son seau', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        portPhotosProvider.overrideWithValue(
          _FauxPort(<String, SourcePhoto>{
            'hakim': const SourcePhoto(seau: 'avatars', cle: 'hakim/1.jpg'),
            'prof': const SourcePhoto(
              seau: 'photos_enseignants',
              cle: 'prof/1.jpg',
            ),
          }),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(
      await c.read(photoPersonneProvider('hakim').future),
      'https://signee.test/avatars/hakim/1.jpg',
    );
    expect(
      await c.read(photoPersonneProvider('prof').future),
      'https://signee.test/photos_enseignants/prof/1.jpg',
    );
  });

  test(
    'sans photo, ou sans le droit de la voir : rien (les initiales)',
    () async {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          portPhotosProvider.overrideWithValue(
            _FauxPort(<String, SourcePhoto>{
              'sans': const SourcePhoto(seau: 'avatars'),
            }),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(await c.read(photoPersonneProvider('sans').future), isNull);
      expect(await c.read(photoPersonneProvider('invisible').future), isNull);
    },
  );

  test('par defaut, aucun port branche : les initiales', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(photoPersonneProvider('x').future), isNull);
  });

  test('l URL est relue avant les 600 s du serveur', () {
    expect(dureeVieUrl.inSeconds, lessThan(dureeUrlPhotoSecondes));
  });

  test('les lignes du serveur, et rien d autre', () {
    final Map<String, SourcePhoto> l = PhotosSupabase.lignes(<dynamic>[
      <String, dynamic>{'profile_id': 'a', 'seau': 'avatars', 'cle': 'a/1.jpg'},
      <String, dynamic>{'profile_id': 'b', 'seau': 'avatars', 'cle': null},
      <String, dynamic>{'seau': 'avatars'},
    ]);
    expect(l.keys, <String>['a', 'b']);
    expect(l['a']!.cle, 'a/1.jpg');
    expect(l['b']!.cle, isNull);
    expect(PhotosSupabase.lignes(null), isEmpty);
  });

  test('le nom de fichier se deduit des premiers octets', () {
    expect(
      nomFichierDepuisOctets(Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47])),
      'photo.png',
    );
    expect(
      nomFichierDepuisOctets(Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xe0])),
      'photo.jpg',
    );
    expect(
      nomFichierDepuisOctets(
        Uint8List.fromList(<int>[
          0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, //
        ]),
      ),
      'photo.webp',
    );
    expect(
      nomFichierDepuisOctets(
        Uint8List.fromList(<int>[0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70]),
      ),
      'photo.heic',
    );
  });
}
