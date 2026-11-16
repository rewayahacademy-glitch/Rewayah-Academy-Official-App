// IMAGES-MESSAGERIE : la compression sur l'appareil (taille, metadonnees,
// miniature, couleur moyenne, limites).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/image_message.dart';
import 'package:rewayah_academy/core/fichiers/compression_image.dart';

import '../../support/image_png.dart';

/// Un reducteur qui rend une image de [taille] octets quelle que soit la
/// demande, et note chaque essai.
Reducteur _faux(List<int> taillesImage, List<(int, double)> essais) {
  int i = 0;
  return (
    Uint8List source, {
    required int coteMax,
    required double qualite,
    required bool couleur,
  }) async {
    essais.add((coteMax, qualite));
    final int taille = couleur ? 5000 : taillesImage[i++ % taillesImage.length];
    return ReductionImage(
      octets: Uint8List(taille),
      mime: 'image/jpeg',
      largeur: 100,
      hauteur: 50,
      couleurMoyenne: couleur ? '#102030' : null,
    );
  };
}

void main() {
  group('limites', () {
    test('une source de plus de 15 Mo est refusee tout de suite', () async {
      final List<(int, double)> essais = <(int, double)>[];
      await expectLater(
        preparerImage(
          Uint8List(sourceImageMaxOctets + 1),
          reducteur: _faux(<int>[10], essais),
        ),
        throwsA(
          isA<EchecImage>().having(
            (EchecImage e) => e.refus,
            'refus',
            RefusImage.imageTropGrosse,
          ),
        ),
      );
      expect(essais, isEmpty, reason: 'rien n\'est decode');
    });

    test('navigateur : qualite 0,8 puis 0,6 une fois, puis refus', () async {
      final List<(int, double)> essais = <(int, double)>[];
      await expectLater(
        preparerImage(
          Uint8List(10),
          reducteur: _faux(<int>[imageMaxOctets + 1], essais),
          reglable: true,
        ),
        throwsA(isA<EchecImage>()),
      );
      expect(essais, <(int, double)>[(1600, 0.8), (1600, 0.6)]);
    });

    test(
      'ailleurs : la taille baisse (1600, 1280, 1024) avant refus',
      () async {
        final List<(int, double)> essais = <(int, double)>[];
        await expectLater(
          preparerImage(
            Uint8List(10),
            reducteur: _faux(<int>[imageMaxOctets + 1], essais),
            reglable: false,
          ),
          throwsA(isA<EchecImage>()),
        );
        expect(essais.map(((int, double) e) => e.$1), <int>[1600, 1280, 1024]);
      },
    );

    test('un second essai plus leger est retenu', () async {
      final ImagePrete prete = await preparerImage(
        Uint8List(10),
        reducteur: _faux(<int>[imageMaxOctets + 1, 1000], <(int, double)>[]),
        reglable: true,
      );
      expect(prete.octets.length, 1000);
      expect(prete.couleurMoyenne, '#102030');
    });

    test('une miniature de plus de 100 Ko est reessayee plus petite', () async {
      final List<(int, double)> essais = <(int, double)>[];
      int n = 0;
      final ImagePrete prete = await preparerImage(
        Uint8List(10),
        reducteur:
            (
              Uint8List s, {
              required int coteMax,
              required double qualite,
              required bool couleur,
            }) async {
              essais.add((coteMax, qualite));
              final int taille = couleur
                  ? (n++ < 2 ? miniatureMaxOctets + 1 : 900)
                  : 2000;
              return ReductionImage(
                octets: Uint8List(taille),
                mime: 'image/jpeg',
                largeur: 8,
                hauteur: 8,
              );
            },
        reglable: true,
      );
      expect(prete.miniature.length, 900);
      expect(essais.skip(1).map(((int, double) e) => e.$1), <int>[
        320,
        320,
        240,
      ]);
    });
  });

  group('image reelle (dart:ui)', () {
    testWidgets('reduite a 1600, miniature de 320, metadonnees retirees', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final Uint8List source = avecMetadonnees(
          await fabriquerPng(3200, 2000, r: 200, g: 60, b: 40),
        );
        expect(contient(source, 'GPS'), isTrue, reason: 'la source en porte');
        final ImagePrete prete = await preparerImage(source, reglable: false);
        expect(prete.largeur, 1600);
        expect(prete.hauteur, 1000);
        expect(prete.octets.length, lessThanOrEqualTo(imageMaxOctets));
        expect(contient(prete.octets, 'GPS'), isFalse);
        expect(contient(prete.octets, 'Exif'), isFalse);
        expect(prete.mime, 'image/png');
        expect(prete.miniature.length, lessThanOrEqualTo(miniatureMaxOctets));
        expect(prete.mimeMiniature, 'image/png');
        // La couleur moyenne se lit sur la miniature : ici un aplat.
        expect(prete.couleurMoyenne, '#c83c28');
      });
    });

    testWidgets('une photo portrait garde son rapport', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final ImagePrete prete = await preparerImage(
          await fabriquerPng(900, 1800),
          reglable: false,
        );
        expect(prete.largeur, 800);
        expect(prete.hauteur, 1600);
      });
    });

    testWidgets('un fichier qui n\'est pas une image est illisible', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await expectLater(
          preparerImage(Uint8List.fromList(<int>[1, 2, 3, 4]), reglable: false),
          throwsA(
            isA<EchecImage>().having(
              (EchecImage e) => e.refus,
              'refus',
              RefusImage.imageIllisible,
            ),
          ),
        );
      });
    });
  });
}
