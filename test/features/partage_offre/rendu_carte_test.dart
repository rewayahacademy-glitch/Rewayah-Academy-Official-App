// CAND-06 : le rendu reel de la carte en image. Le vrai `toImage` de Flutter,
// sans double : la taille de l'export (1080 x 1920), le fond violet uni et la
// porte, la lisibilite du QR (chaque module relu dans les pixels), l'independance
// du theme et de la taille de texte (memes octets), les quatre langues et les
// deux variantes, et le rendu a travers l'apercu reduit de la page.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';
import 'package:rewayah_academy/features/partage_offre/decor_carte.dart';
import 'package:rewayah_academy/features/partage_offre/rendu_carte.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/partage_offre/faux_partage_offre.dart';
import 'hote_partage.dart';
import 'image_carte.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le PNG exporte', () {
    for (final VarianteCarte v in VarianteCarte.values) {
      testWidgets(
        '${v.name} : 1080 x 1920 pixels, le fond violet uni, la porte claire',
        (WidgetTester tester) async {
          final Uint8List png = await rendreCarte(tester, variante: v);
          // La signature d'un PNG.
          expect(png.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
          final ImageCarte image = (await tester.runAsync(
            () => decoderCarte(png),
          ))!;
          expect(image.largeur, 1080);
          expect(image.hauteur, 1920);
          final AppPaletteCarte c = v == VarianteCarte.femmes
              ? AppPaletteCarte.femmes
              : AppPaletteCarte.hommes;
          final Color fond = c.fond.background;
          final Color trait = Color.alphaBlend(
            Colors.white.withValues(alpha: AppPaletteCarte.opaciteFiligrane),
            fond,
          );
          // Les quatre coins de l'image sont le fond (ou le trait tamise du
          // symbole qui les traverse) : une image pleine, sans bord ni angle
          // arrondi.
          for (final (int, int) coin in <(int, int)>[
            (2, 2),
            (1077, 2),
            (2, 1917),
            (1077, 1917),
          ]) {
            final Color p = image.pixel(coin.$1, coin.$2);
            expect(
              proches(p, fond) || proches(p, trait),
              isTrue,
              reason: '$coin : $p',
            );
          }
          // Le fond, hors de tout ornement : un aplat de la palette.
          expect(proches(image.pixel(3 * 20, 3 * 300), fond), isTrue);
          // La porte : un aplat clair, au milieu de son arche.
          final Rect porte = GeometrieScene(
            const Size(CartePartage.largeur, CartePartage.hauteurScene),
          ).porte.shift(const Offset(0, CartePartage.hautScene));
          expect(image.enPoints(porte.center), c.porte.background);
        },
      );
    }

    testWidgets('le QR se relit dans les pixels, dans chaque langue et chaque variante : '
        'chaque module est celui du lien', (WidgetTester tester) async {
      for (final VarianteCarte v in VarianteCarte.values) {
        for (final LangueCarte l in LangueCarte.values) {
          final Uint8List png = await rendreCarte(
            tester,
            langue: l,
            variante: v,
          );
          final ImageCarte image = (await tester.runAsync(
            () => decoderCarte(png),
          ))!;
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
          // qr_flutter arrondit le module au demi-point et centre le dessin.
          final double module = ((grille.width / n) * 2).roundToDouble() / 2;
          final double decalage = (grille.width - module * n) / 2;
          int fausses = 0;
          for (int ligne = 0; ligne < n; ligne++) {
            for (int colonne = 0; colonne < n; colonne++) {
              final double x =
                  (grille.left -
                      carte.left +
                      decalage +
                      (colonne + 0.5) * module) *
                  CartePartage.echelleExport;
              final double y =
                  (grille.top - carte.top + decalage + (ligne + 0.5) * module) *
                  CartePartage.echelleExport;
              final bool sombre =
                  image.pixel(x.round(), y.round()).computeLuminance() < 0.5;
              if (sombre != attendu.isDark(ligne, colonne)) {
                fausses++;
              }
            }
          }
          expect(
            fausses,
            0,
            reason:
                '${v.name} ${l.code} : $fausses modules sur ${n * n} different',
          );
          // Le module de 8 pixels au moins : lisible par un lecteur de QR.
          expect(
            module * CartePartage.echelleExport,
            greaterThanOrEqualTo(6),
            reason: 'un module doit faire au moins 6 pixels dans l\'export',
          );
          // La marge blanche autour de la grille (4 modules recommandes).
          const double marge = 12 * CartePartage.echelleExport;
          expect(marge / (module * CartePartage.echelleExport), greaterThan(3));
        }
      }
    });

    testWidgets(
      'sombre, texte x2 et interface guidee : exactement les memes octets',
      (WidgetTester tester) async {
        final Uint8List reference = await rendreCarte(tester);
        final Uint8List sombre = await rendreCarte(
          tester,
          luminosite: Brightness.dark,
        );
        final Uint8List agrandi = await rendreCarte(tester, echelle: 2);
        final Uint8List guide = await rendreCarte(
          tester,
          mode: InterfaceMode.enfant,
          luminosite: Brightness.dark,
          echelle: 2,
        );
        expect(memesOctets(sombre, reference), isTrue, reason: 'sombre');
        expect(memesOctets(agrandi, reference), isTrue, reason: 'texte x2');
        expect(
          memesOctets(guide, reference),
          isTrue,
          reason: 'interface guidee',
        );
      },
    );

    testWidgets(
      'chaque langue et chaque variante rend sa propre image, aux 1080 x 1920 '
      'pixels',
      (WidgetTester tester) async {
        final List<Uint8List> rendus = <Uint8List>[];
        for (final VarianteCarte v in VarianteCarte.values) {
          for (final LangueCarte l in LangueCarte.values) {
            final Uint8List png = await rendreCarte(
              tester,
              langue: l,
              variante: v,
            );
            final ImageCarte image = (await tester.runAsync(
              () => decoderCarte(png),
            ))!;
            expect(image.largeur, 1080, reason: '${v.name} ${l.code}');
            expect(image.hauteur, 1920, reason: '${v.name} ${l.code}');
            for (final Uint8List autre in rendus) {
              expect(
                memesOctets(png, autre),
                isFalse,
                reason: '${v.name} ${l.code}',
              );
            }
            rendus.add(png);
          }
        }
        expect(rendus, hasLength(8));
      },
    );

    testWidgets(
      'la langue de la carte ne depend pas de la langue de l\'application',
      (WidgetTester tester) async {
        final Uint8List francais = await rendreCarte(tester);
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        final Uint8List memeCarte = await rendreCarte(tester);
        expect(
          memesOctets(francais, memeCarte),
          isTrue,
          reason: 'une carte francaise reste francaise dans une app arabe',
        );
      },
    );

    testWidgets('un autre lien change le QR', (WidgetTester tester) async {
      final Uint8List a = await rendreCarte(tester);
      final Uint8List b = await rendreCarte(
        tester,
        lien: Uri.parse('https://autre.test/fr/'),
      );
      expect(memesOctets(a, b), isFalse);
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
        // Les reglages de la carte se lisent, la page se construit, puis le
        // rendu reel (asynchrone) part : on laisse l'horloge reelle tourner.
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
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
        final ImageCarte image = (await tester.runAsync(
          () => decoderCarte(appel.png),
        ))!;
        expect(image.largeur, 1080);
        expect(image.hauteur, 1920);
        expect(
          proches(image.pixel(2, 2), AppPaletteCarte.hommes.fond.background),
          isTrue,
        );
        // Et il est identique a l'image de la carte rendue seule.
        final Uint8List seule = await rendreCarte(
          tester,
          vue: const Size(800, 900),
        );
        expect(memesOctets(appel.png, seule), isTrue);
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
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('partage-partager')),
        );
        await tester.pump();
        final Uint8List png = m.partage.appels.single.png;
        final ImageCarte image = (await tester.runAsync(
          () => decoderCarte(png),
        ))!;
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
