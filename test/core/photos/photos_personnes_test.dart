// PHOTOS-2a : une seule photo par personne, lue au serveur, la meme partout.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photos_personnes.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../../support/faux_photos.dart';
import '../../support/harnais.dart';

const String _hakim = 'f0700000-0000-0000-0000-000000000002';
const String _camil = 'f0700000-0000-0000-0000-000000000004';
const String _omar = 'f0700000-0000-0000-0000-000000000006';
const String _prof = 'f0700000-0000-0000-0000-000000000008';

/// Un PNG d'un pixel.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

FauxPhotos _serveur() => FauxPhotos(
  sources: <String, SourcePhoto>{
    // Hakim a une photo ; Camil n'en a pas ; Omar n'est pas visible
    // (absent de la reponse) ; l'enseignant est dans son seau.
    _hakim: const SourcePhoto(seau: 'avatars', cle: '$_hakim/hakim.jpg'),
    _camil: const SourcePhoto(seau: 'avatars', cle: null),
    _prof: const SourcePhoto(seau: 'photos_enseignants', cle: null),
  },
);

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  required FauxPhotos photos,
  List<Override> autres = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portPhotosProvider.overrideWithValue(photos),
        horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(false)),
        ...autres,
      ],
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: Scaffold(body: SingleChildScrollView(child: enfant)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Les URL des images reseau a l'ecran : une par photo affichee.
Set<String> _urls(WidgetTester tester) => <String>{
  for (final Image image in tester.widgetList<Image>(find.byType(Image)))
    if (image.image case final NetworkImage n) n.url,
};

void main() {
  group('LotPhotos', () {
    test('les demandes d une meme image partent en un seul appel', () async {
      final FauxPhotos photos = _serveur();
      final LotPhotos lot = LotPhotos(photos);
      final List<SourcePhoto?> lues = await Future.wait(<Future<SourcePhoto?>>[
        lot.source(_hakim),
        lot.source(_camil),
        lot.source(_omar),
        lot.source(_hakim),
      ]);
      expect(photos.lectures, hasLength(1));
      expect(photos.lectures.single, <String>[_hakim, _camil, _omar]);
      expect(lues[0]?.cle, '$_hakim/hakim.jpg');
      expect(lues[1]?.cle, isNull);
      expect(lues[2], isNull, reason: 'une personne non visible : rien');
      expect(lues[3]?.cle, '$_hakim/hakim.jpg');
    });

    test(
      'une lecture en echec rend les initiales, jamais une erreur',
      () async {
        final FauxPhotos photos = _serveur()
          ..erreurLecture = Exception('reseau');
        final LotPhotos lot = LotPhotos(photos);
        expect(await lot.source(_hakim), isNull);
      },
    );

    test('le port par defaut dit qu il n est pas branche', () async {
      await expectLater(
        const PhotosIndisponibles().lire(<String>[_hakim]),
        throwsA(isA<Object>()),
      );
    });
  });

  group('AvatarTile personneId', () {
    testWidgets('visible avec photo : l URL du serveur ; sinon les initiales', (
      WidgetTester tester,
    ) async {
      final FauxPhotos photos = _serveur();
      await _monter(
        tester,
        photos: photos,
        const Column(
          children: <Widget>[
            AvatarTile(prenom: 'Hakim', personneId: _hakim),
            AvatarTile(prenom: 'Camil', personneId: _camil),
            AvatarTile(prenom: 'Omar', personneId: _omar),
          ],
        ),
      );
      // Seul Hakim a une photo visible : Camil n'en a pas, Omar n'est pas
      // visible (les initiales pour les deux).
      expect(_urls(tester), <String>{
        'https://exemple.test/avatars/$_hakim/hakim.jpg',
      });
      expect(find.byType(AvatarTile), findsNWidgets(3));
      expect(photos.lectures, hasLength(1), reason: 'un seul appel groupe');
      expect(tester.takeException(), isNull);
    });

    testWidgets('l URL est relue avant ses 600 s', (WidgetTester tester) async {
      final FauxPhotos photos = _serveur();
      await _monter(
        tester,
        photos: photos,
        const AvatarTile(prenom: 'Hakim', personneId: _hakim),
      );
      expect(photos.lectures, hasLength(1));
      await tester.pump(delaiRelecturePhoto);
      await tester.pump();
      await tester.pump();
      expect(photos.lectures, hasLength(2));
      expect(delaiRelecturePhoto.inSeconds, lessThan(600));
    });

    testWidgets('sans ecran qui l ecoute, la photo est liberee', (
      WidgetTester tester,
    ) async {
      final FauxPhotos photos = _serveur();
      await _monter(
        tester,
        photos: photos,
        const AvatarTile(prenom: 'Hakim', personneId: _hakim),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(delaiRelecturePhoto * 2);
      expect(photos.lectures, hasLength(1), reason: 'aucune relecture');
    });
  });

  group('Ma photo (poser_ma_photo)', () {
    testWidgets('un adulte depose dans son dossier et son seau, puis pose', (
      WidgetTester tester,
    ) async {
      final FauxPhotos photos = _serveur()..moi = _prof;
      await _monter(
        tester,
        photos: photos,
        autres: <Override>[
          selecteurPhotoProvider.overrideWithValue(
            FauxSelecteurPhoto(PhotoEnfant(octets: _png, nomFichier: 'a.png')),
          ),
        ],
        const EditeurPhotoEleve.moi(personneId: _prof, prenom: 'Bilal'),
      );
      expect(find.text(t.ficheEleve.informations.photoAucune), findsOneWidget);
      expect(
        find.text(t.ficheEleve.informations.photoLegendeMoi),
        findsOneWidget,
      );

      await tester.tap(find.byKey(EditeurPhotoEleve.choisirKey));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(EditeurPhotoEleve.envoyerKey));
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(photos.depots.single.personneId, _prof);
      expect(
        photos.depots.single.seau,
        'photos_enseignants',
        reason: 'le seau que le serveur rend pour cette personne',
      );
      expect(photos.posesMoi.single, '$_prof/1.png');
      expect(photos.posesEleve, isEmpty);
      expect(find.text(t.ficheEleve.informations.succes), findsOneWidget);
      expect(
        find.text(t.ficheEleve.informations.photoPresente),
        findsOneWidget,
      );
    });

    testWidgets('pose refusee : le fichier n est pas renvoye a la reprise', (
      WidgetTester tester,
    ) async {
      final FauxPhotos photos = _serveur()
        ..moi = _camil
        ..erreurPose = Exception('refus');
      await _monter(
        tester,
        photos: photos,
        autres: <Override>[
          selecteurPhotoProvider.overrideWithValue(
            FauxSelecteurPhoto(PhotoEnfant(octets: _png, nomFichier: 'a.png')),
          ),
        ],
        const EditeurPhotoEleve.moi(personneId: _camil, prenom: 'Camil'),
      );
      await tester.tap(find.byKey(EditeurPhotoEleve.choisirKey));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(EditeurPhotoEleve.envoyerKey));
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(
        find.text(t.ficheEleve.informations.echecEnregistrement),
        findsOneWidget,
      );
      photos.erreurPose = null;
      await tester.tap(find.byKey(EditeurPhotoEleve.reprendreKey));
      for (int i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(photos.depots, hasLength(1));
      expect(photos.posesMoi.single, '$_camil/1.png');
      expect(photos.depots.single.seau, 'avatars');
    });

    test('sans capacite lue, « Changer ma photo » n est pas propose', () async {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          portPhotosProvider.overrideWithValue(const PhotosIndisponibles()),
        ],
      );
      addTearDown(c.dispose);
      final ProviderSubscription<AsyncValue<bool>> s = c.listen(
        peutPoserMaPhotoProvider,
        (_, _) {},
      );
      addTearDown(s.close);
      expect(await c.read(peutPoserMaPhotoProvider.future), isFalse);
    });
  });

  group('Photo publique de l enseignant', () {
    test('le fichier va dans son seau, puis poser_ma_photo', () async {
      final FauxPhotos photos = _serveur()..moi = _prof;
      final EnvoiPhotoPubliqueServeur envoi = EnvoiPhotoPubliqueServeur(
        port: photos,
        lot: LotPhotos(photos),
        personneId: _prof,
      );
      final String cle = await envoi.envoyer(
        PhotoChoisie(octets: _png, nomFichier: 'portrait.png'),
      );
      expect(cle, '$_prof/1.png');
      expect(photos.depots.single.seau, 'photos_enseignants');
      expect(photos.depots.single.photo.typeMime, 'image/png');
      expect(photos.posesMoi.single, cle);
    });

    test('sans session, rien ne part', () async {
      final FauxPhotos photos = _serveur();
      final EnvoiPhotoPubliqueServeur envoi = EnvoiPhotoPubliqueServeur(
        port: photos,
        lot: LotPhotos(photos),
        personneId: null,
      );
      await expectLater(
        envoi.envoyer(PhotoChoisie(octets: _png)),
        throwsA(isA<StateError>()),
      );
      expect(photos.depots, isEmpty);
      expect(photos.posesMoi, isEmpty);
    });
  });
}
