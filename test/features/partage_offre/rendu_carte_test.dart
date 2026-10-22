// CAND-06 : le rendu reel de la carte en image. Le vrai `toImage` de Flutter,
// sans double : la taille de l'export (1080 x 1920), les couleurs du design,
// la lisibilite du QR (chaque module relu dans les pixels), l'independance du
// theme et de la taille de texte (memes octets), et le rendu a travers
// l'apercu reduit de la page.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';
import 'package:rewayah_academy/features/partage_offre/rendu_carte.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/partage_offre/faux_partage_offre.dart';
import 'hote_partage.dart';

/// Une image decodee : ses pixels RGBA.
class _Image {
  _Image(this.largeur, this.hauteur, this._octets);

  final int largeur;
  final int hauteur;
  final ByteData _octets;

  Color pixel(int x, int y) {
    final int i = (y * largeur + x) * 4;
    return Color.fromARGB(
      _octets.getUint8(i + 3),
      _octets.getUint8(i),
      _octets.getUint8(i + 1),
      _octets.getUint8(i + 2),
    );
  }
}

/// Decode un PNG, dans `runAsync` (decodage reel).
Future<_Image> _decoder(Uint8List png) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.Image image = (await codec.getNextFrame()).image;
  final ByteData octets = (await image.toByteData())!;
  final _Image rendu = _Image(image.width, image.height, octets);
  image.dispose();
  return rendu;
}

/// Monte la carte dans sa `RepaintBoundary`, comme la page, et la rend en PNG.
Future<Uint8List> _rendre(
  WidgetTester tester, {
  Brightness luminosite = Brightness.light,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  Uri? lien,
  Size? vue,
}) async {
  tester.view.physicalSize = vue ?? const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GlobalKey cle = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(mode, luminosite),
      builder: (BuildContext contexte, Widget? app) => MediaQuery(
        data: MediaQuery.of(contexte)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: app!,
      ),
      home: Center(
        child: RepaintBoundary(
          key: cle,
          child: CartePartage(lien: lien ?? lienDeTest),
        ),
      ),
    ),
  );
  await tester.pump();
  return (await tester.runAsync(() => rendreCarteEnPng(cle)))!;
}

bool _egaux(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le PNG exporte', () {
    testWidgets(
      '1080 x 1920 pixels, le violet de marque en fond, l\'arche lavande',
      (WidgetTester tester) async {
        final Uint8List png = await _rendre(tester);
        // La signature d'un PNG.
        expect(png.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
        final _Image image = (await tester.runAsync(() => _decoder(png)))!;
        expect(image.largeur, 1080);
        expect(image.hauteur, 1920);
        final AppPalette p = AppPalette.claire();
        // Les quatre coins de l'image sont le violet de marque : une image
        // pleine, sans bord ni angle arrondi.
        for (final (int, int) coin in <(int, int)>[
          (2, 2),
          (1077, 2),
          (2, 1917),
          (1077, 1917),
        ]) {
          expect(
            image.pixel(coin.$1, coin.$2),
            p.surfacePrimary.background,
            reason: '$coin',
          );
        }
        // L'arche : un pixel a sa marge de debut, a mi-hauteur.
        expect(image.pixel(3 * 36, 3 * 330), p.washAccent.background);
        // Hors de l'arche, a la hauteur du haut des epaules (coin haut de
        // l'arche, arrondi en demi-cercle) : encore le violet.
        expect(image.pixel(3 * 26, 3 * 84), p.surfacePrimary.background);
      },
    );

    testWidgets(
      'le QR se relit dans les pixels : chaque module est celui du lien',
      (WidgetTester tester) async {
        final Uint8List png = await _rendre(tester);
        final _Image image = (await tester.runAsync(() => _decoder(png)))!;
        final Rect carte = tester.getRect(find.byType(CartePartage));
        final Rect plaque = tester.getRect(find.byKey(CartePartage.qrKey));
        // La grille du QR : la plaque moins sa marge blanche de 12 points.
        final Rect grille = plaque.deflate(12);
        expect(grille.width, CartePartage.coteQr);
        final QrImage attendu = QrImage(
          QrCode.fromData(
            data: lienDeTest.toString(),
            errorCorrectLevel: QrErrorCorrectLevel.M,
          ),
        );
        final int n = attendu.moduleCount;
        final double module = grille.width / n;
        int fausses = 0;
        for (int ligne = 0; ligne < n; ligne++) {
          for (int colonne = 0; colonne < n; colonne++) {
            final double x =
                (grille.left - carte.left + (colonne + 0.5) * module) *
                CartePartage.echelleExport;
            final double y =
                (grille.top - carte.top + (ligne + 0.5) * module) *
                CartePartage.echelleExport;
            final bool sombre =
                image.pixel(x.round(), y.round()).computeLuminance() < 0.5;
            if (sombre != attendu.isDark(ligne, colonne)) {
              fausses++;
            }
          }
        }
        expect(fausses, 0, reason: '$fausses modules sur ${n * n} different');
        // Le module de 8 pixels au moins : lisible par un lecteur de QR.
        expect(
          module * CartePartage.echelleExport,
          greaterThanOrEqualTo(6),
          reason: 'un module doit faire au moins 6 pixels dans l\'export',
        );
        // La marge blanche autour de la grille (4 modules recommandes).
        const double marge = 12 * CartePartage.echelleExport;
        expect(marge / (module * CartePartage.echelleExport), greaterThan(3));
      },
    );

    testWidgets(
      'sombre, texte x2 et interface guidee : exactement les memes octets',
      (WidgetTester tester) async {
        final Uint8List reference = await _rendre(tester);
        final Uint8List sombre = await _rendre(
          tester,
          luminosite: Brightness.dark,
        );
        final Uint8List agrandi = await _rendre(tester, echelle: 2);
        final Uint8List guide = await _rendre(
          tester,
          mode: InterfaceMode.enfant,
          luminosite: Brightness.dark,
          echelle: 2,
        );
        expect(_egaux(sombre, reference), isTrue, reason: 'sombre');
        expect(_egaux(agrandi, reference), isTrue, reason: 'texte x2');
        expect(_egaux(guide, reference), isTrue, reason: 'interface guidee');
      },
    );

    testWidgets('l\'arabe et le francais ne rendent pas la meme image', (
      WidgetTester tester,
    ) async {
      final Uint8List francais = await _rendre(tester);
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      final Uint8List arabe = await _rendre(tester);
      expect(_egaux(arabe, francais), isFalse);
      final _Image image = (await tester.runAsync(() => _decoder(arabe)))!;
      expect(image.largeur, 1080);
      expect(image.hauteur, 1920);
    });

    testWidgets('un autre lien change le QR', (WidgetTester tester) async {
      final Uint8List a = await _rendre(tester);
      final Uint8List b = await _rendre(
        tester,
        lien: Uri.parse('https://autre.test/fr/'),
      );
      expect(_egaux(a, b), isFalse);
    });
  });

  group('a travers la page', () {
    testWidgets(
      'l\'apercu est reduit mais l\'image exportee a la taille de la carte',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(
          tester,
          vraiRendu: true,
          attendre: false,
        );
        // Le rendu reel est asynchrone : on laisse l'horloge reelle tourner.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pumpAndSettle();
        // L'apercu est bien plus petit que la carte...
        final Size apercu = tester.getSize(
          find.byKey(const ValueKey<String>('partage-apercu')),
        );
        expect(apercu.width, lessThan(CartePartage.largeur));
        // ... mais « Partager » transmet le PNG de 1080 x 1920.
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('partage-partager')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('partage-partager')),
        );
        await tester.pump();
        expect(m.partage.appels, hasLength(1));
        final AppelPartage appel = m.partage.appels.single;
        final _Image image = (await tester.runAsync(
          () => _decoder(appel.png),
        ))!;
        expect(image.largeur, 1080);
        expect(image.hauteur, 1920);
        expect(
          image.pixel(2, 2),
          AppPalette.claire().surfacePrimary.background,
        );
        // Et il est identique a l'image de la carte rendue seule.
        final Uint8List seule = await _rendre(
          tester,
          vue: const Size(800, 900),
        );
        expect(_egaux(appel.png, seule), isTrue);
      },
    );

    testWidgets(
      'sur bureau, meme image : la mise en page de la page ne compte pas',
      (WidgetTester tester) async {
        final MontagePartage m = await monterPartage(
          tester,
          vraiRendu: true,
          attendre: false,
          taille: const Size(1440, 900),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('partage-partager')),
        );
        await tester.pump();
        final Uint8List png = m.partage.appels.single.png;
        final _Image image = (await tester.runAsync(() => _decoder(png)))!;
        expect(image.largeur, 1080);
        expect(image.hauteur, 1920);
      },
    );

    test('le nom du fichier est un PNG et la route est sous /attente', () {
      expect(nomFichierCarte, endsWith('.png'));
      expect(Routes.attentePartage, startsWith('${Routes.attente}/'));
      expect(NiveauPartage.values, hasLength(3));
    });
  });
}
