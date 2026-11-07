// CAND-PHOTO (06/11/2026) : l'envoi de la photo du candidat. Ce que le test
// prouve : le fichier part dans le seau des enseignants (le candidat a deja sa
// ligne d'enseignant, sans photo encore), puis `poser_photo_candidat` pose la
// cle ; l'envoi de l'enseignant, lui, garde `poser_ma_photo`.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

class _FauxPort implements PortPhotos {
  final List<String> appels = <String>[];

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async =>
      <String, SourcePhoto>{
        for (final String id in profileIds)
          id: const SourcePhoto(seau: 'photos_enseignants'),
      };

  @override
  Future<String> urlSignee(String seau, String cle) async => 'url';

  @override
  Future<String> televerser({
    required String profileId,
    required String seau,
    required PhotoEnfant photo,
  }) async {
    appels.add('televerser:$seau');
    return '$profileId/photo.jpg';
  }

  @override
  Future<SourcePhoto?> poserMaPhoto(String? cle) async {
    appels.add('poserMaPhoto:$cle');
    return null;
  }

  @override
  Future<SourcePhoto?> poserPhotoEleve(String eleveId, String? cle) async =>
      null;

  @override
  Future<SourcePhoto?> poserPhotoCandidat(String? cle) async {
    appels.add('poserPhotoCandidat:$cle');
    return null;
  }

  @override
  Future<bool> peutPoserMaPhoto() async => false;
}

// Un JPEG minimal (signature FFD8FF) : le nom de fichier se deduit des octets.
final PhotoChoisie _photo = PhotoChoisie(
  octets: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0]),
);

void main() {
  test('candidat : seau des enseignants, puis poser_photo_candidat', () async {
    final _FauxPort port = _FauxPort();
    final List<String> relus = <String>[];
    final String cle = await EnvoiPhotoPubliqueServeur(
      port: port,
      moi: () => 'c1',
      relire: relus.add,
      candidat: true,
    ).envoyer(_photo);
    expect(cle, 'c1/photo.jpg');
    expect(port.appels, <String>[
      'televerser:photos_enseignants',
      'poserPhotoCandidat:c1/photo.jpg',
    ]);
    expect(relus, <String>['c1']);
  });

  test('enseignant : poser_ma_photo, comme avant', () async {
    final _FauxPort port = _FauxPort();
    await EnvoiPhotoPubliqueServeur(
      port: port,
      moi: () => 'e1',
      relire: (String _) {},
    ).envoyer(_photo);
    expect(port.appels.last, 'poserMaPhoto:e1/photo.jpg');
  });
}
