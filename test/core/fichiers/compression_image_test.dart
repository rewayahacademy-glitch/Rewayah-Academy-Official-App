// IMAGES-MESSAGERIE : la compression sur l'appareil (taille, metadonnees,
// miniature, couleur moyenne, limites).

import 'package:flutter/services.dart';
// Le plugin natif est simule : sa mise en oeuvre commune porte le canal.
// ignore: depend_on_referenced_packages
import 'package:flutter_image_compress_common/flutter_image_compress_common.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
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

    test('qualite 0,8 puis 0,6 une seule fois, puis refus', () async {
      final List<(int, double)> essais = <(int, double)>[];
      await expectLater(
        preparerImage(
          Uint8List(10),
          reducteur: _faux(<int>[imageMaxOctets + 1], essais),
        ),
        throwsA(isA<EchecImage>()),
      );
      expect(essais, <(int, double)>[(1600, 0.8), (1600, 0.6)]);
    });

    test('un second essai plus leger est retenu', () async {
      final ImagePrete prete = await preparerImage(
        Uint8List(10),
        reducteur: _faux(<int>[imageMaxOctets + 1, 1000], <(int, double)>[]),
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
      );
      expect(prete.miniature.length, 900);
      expect(essais.skip(1).map(((int, double) e) => e.$1), <int>[
        320,
        320,
        240,
      ]);
    });
  });

  group('hors navigateur : flutter_image_compress', () {
    const MethodChannel canal = MethodChannel('flutter_image_compress');
    final List<List<Object?>> appels = <List<Object?>>[];

    void simuler() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (MethodCall appel) async {
            if (appel.method != 'compressWithList') return true;
            final List<Object?> args = appel.arguments as List<Object?>;
            appels.add(args);
            // Le « plugin » rend une image de la taille demandee.
            return fabriquerPng(args[1]! as int, args[2]! as int);
          });
    }

    setUp(() {
      FlutterImageCompressPlatform.instance = FlutterImageCompressCommon();
      appels.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, null);
    });

    testWidgets('JPEG qualite 80, sans EXIF, 1600 de cote, miniature 320', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final Uint8List source = await fabriquerPng(3200, 2000);
        simuler();
        final ImagePrete prete = await preparerImage(source);
        // Premiere demande : l'image. Seconde : la miniature.
        expect(appels, hasLength(2));
        expect(appels[0][1], 1600, reason: 'plus grand cote');
        expect(appels[0][2], 1000);
        expect(appels[0][3], 80, reason: 'qualite');
        expect(appels[0][7], false, reason: 'keepExif');
        expect(appels[1][1], 320);
        expect(appels[1][2], 200);
        expect(prete.largeur, 1600);
        expect(prete.hauteur, 1000);
        expect(prete.mime, 'image/jpeg');
        expect(prete.mimeMiniature, 'image/jpeg');
        expect(prete.couleurMoyenne, matches(RegExp(r'^#[0-9a-f]{6}$')));
      });
    });

    testWidgets('un portrait : c\'est la hauteur qui vaut 1600', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final Uint8List source = await fabriquerPng(1000, 4000);
        simuler();
        final ImagePrete prete = await preparerImage(source);
        expect(appels[0][1], 400);
        expect(appels[0][2], 1600);
        expect(prete.hauteur, 1600);
      });
    });

    testWidgets('un fichier qui n\'est pas une image est illisible', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await expectLater(
          preparerImage(Uint8List.fromList(<int>[1, 2, 3, 4])),
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
