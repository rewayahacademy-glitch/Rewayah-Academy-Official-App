// CAND-06 : la carte a partager, redessinee le 22/10/2026 sur la direction du
// directeur : un fond violet profond uni, le symbole contour officiel tres
// agrandi et tamise, le portail (une porte en arche, un chemin de lumiere) qui
// dit l'eleve entrant dans la lumiere du Coran, une typographie suisse.
//
// Ce que la carte porte (un titre sur ce que l'eleve y gagne, la signature de la
// marque pres de la porte, l'appel « Decouvrir l'offre » avec le QR et le lien,
// le logo, le hadith tout en bas, tres discret), ce qu'elle ne porte pas (aucun
// prix, aucune promesse, jamais l'academie comme motif), ses deux variantes (les
// hommes et le genre inconnu, les femmes), ses quatre langues, sa lisibilite
// (contraste mesure) et son independance du theme, de la taille de texte et de
// l'interface guidee.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/marque/contour_traces.g.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/features/partage_offre/branche_fleurie.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';
import 'package:rewayah_academy/features/partage_offre/decor_carte.dart';
import 'package:rewayah_academy/features/partage_offre/textes_carte.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../theme/support/contraste.dart';
import 'hote_partage.dart';
import 'image_carte.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

AppPaletteCarte _couleurs(VarianteCarte v) =>
    v == VarianteCarte.femmes ? AppPaletteCarte.femmes : AppPaletteCarte.hommes;

/// Monte la carte seule, a sa taille, dans un theme et une echelle de texte.
Future<void> _monter(
  WidgetTester tester, {
  LangueCarte langue = LangueCarte.francais,
  VarianteCarte variante = VarianteCarte.hommes,
  Uri? lien,
  Brightness luminosite = Brightness.light,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(800, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(mode, luminosite),
      builder: (BuildContext contexte, Widget? app) => MediaQuery(
        data: MediaQuery.of(contexte)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: Directionality(textDirection: direction, child: app!),
      ),
      home: Center(
        child: CartePartage(
          lien: lien ?? lienDeTest,
          langue: langue,
          variante: variante,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Les textes de la carte, sans l'adresse du lien (une adresse n'est pas un
/// motif : elle porte le nom du site).
List<String> _textesSansLien(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(
    find.descendant(of: find.byType(CartePartage), matching: find.byType(Text)),
  ))
    if (w.data != null && w.key != CartePartage.lienKey) w.data!,
];

/// Tous les textes de la carte.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(
    find.descendant(of: find.byType(CartePartage), matching: find.byType(Text)),
  ))
    if (w.data != null) w.data!,
];

/// La porte, dans le repere de la carte (en points logiques) ; en arabe la
/// scene est en miroir.
Rect _porteDansLaCarte({bool rtl = false}) {
  final GeometrieScene g = GeometrieScene(
    const Size(CartePartage.largeur, CartePartage.hauteurScene),
  );
  final Rect p = g.porte.shift(const Offset(0, CartePartage.hautScene));
  return rtl
      ? Rect.fromLTRB(
          CartePartage.largeur - p.right,
          p.top,
          CartePartage.largeur - p.left,
          p.bottom,
        )
      : p;
}

/// Un point de la scene dans le repere de la carte.
Offset _surLaCarte(Offset p, {bool rtl = false}) {
  final Offset d = p.translate(0, CartePartage.hautScene);
  return rtl ? Offset(CartePartage.largeur - d.dx, d.dy) : d;
}

/// La ligne de pixels, entre le QR et le hadith, ou seul le filigrane passe :
/// libre de tout texte et de toute la scene, dans toutes les langues (la plaque
/// du QR finit a 519 points, le hadith commence apres 540).
int get _ligneDuFiligrane => (530 * CartePartage.echelleExport).round();

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('ce que la carte porte, dans chaque langue et chaque variante', () {
    for (final VarianteCarte variante in VarianteCarte.values) {
      for (final LangueCarte langue in LangueCarte.values) {
        final String nom = '${variante.name} ${langue.code}';
        final TextesCarte c = textesCarte[langue]!;
        final TextDirection sens = langue.sens;

        group(nom, () {
          testWidgets(
            '360 x 640 : le format story 9:16, 1080 x 1920 a l\'export',
            (WidgetTester tester) async {
              await _monter(
                tester,
                langue: langue,
                variante: variante,
                direction: sens,
              );
              expect(
                tester.getSize(find.byType(CartePartage)),
                const Size(CartePartage.largeur, CartePartage.hauteur),
              );
              expect(
                CartePartage.largeur / CartePartage.hauteur,
                closeTo(9 / 16, 1e-9),
              );
              expect(CartePartage.largeur * CartePartage.echelleExport, 1080);
              expect(CartePartage.hauteur * CartePartage.echelleExport, 1920);
              expect(tester.takeException(), isNull);
            },
          );

          testWidgets(
            'le titre, sa ligne, l\'appel et la reference, tels que la langue '
            'les ecrit',
            (WidgetTester tester) async {
              await _monter(
                tester,
                langue: langue,
                variante: variante,
                direction: sens,
              );
              expect(tester.widget<Text>(_cle('carte-titre')).data, c.titre);
              expect(
                tester.widget<Text>(_cle('carte-sous-titre')).data,
                c.sousTitre,
              );
              expect(
                tester.widget<Text>(_cle('carte-decouvrir')).data,
                c.decouvrir,
              );
              expect(
                tester.widget<Text>(_cle('carte-reference')).data,
                c.reference,
              );
              expect(tester.takeException(), isNull);
            },
          );

          testWidgets('un seul hadith, en arabe, de droite a gauche', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              langue: langue,
              variante: variante,
              direction: sens,
            );
            final Text hadith = tester.widget<Text>(_cle('carte-hadith'));
            expect(hadith.data, hadithArabe);
            expect(hadith.textDirection, TextDirection.rtl);
            if (c.traduction == null) {
              expect(_cle('carte-traduction'), findsNothing);
            } else {
              expect(
                tester.widget<Text>(_cle('carte-traduction')).data,
                c.traduction,
              );
            }
            // Le hadith se compte une fois : une seule occurrence sur la carte.
            expect(
              _textes(tester).where((String t) => t == hadithArabe),
              hasLength(1),
            );
          });

          testWidgets('la signature arabe de la marque, dans toutes les '
              'langues', (WidgetTester tester) async {
            await _monter(
              tester,
              langue: langue,
              variante: variante,
              direction: sens,
            );
            final Text signature = tester.widget<Text>(_cle('carte-signature'));
            expect(signature.data, signatureArabe);
            expect(signature.textDirection, TextDirection.rtl);
          });

          testWidgets(
            'la signature est pres de la porte, a la hauteur de son milieu, '
            'sans la toucher',
            (WidgetTester tester) async {
              await _monter(
                tester,
                langue: langue,
                variante: variante,
                direction: sens,
              );
              final bool rtl = langue.droiteAGauche;
              final Rect porte = _porteDansLaCarte(rtl: rtl);
              final Rect carte = tester.getRect(find.byType(CartePartage));
              final Rect signature = tester
                  .getRect(_cle('carte-signature'))
                  .shift(-carte.topLeft);
              // A la hauteur du milieu de la porte (une demi-ligne au plus).
              expect(
                (signature.center.dy - porte.center.dy).abs(),
                lessThan(CartePartage.hauteurLigneSignature / 2),
              );
              // Du cote du debut de la ligne, avec du vide avant la porte :
              // au moins 16 points d'air.
              if (rtl) {
                expect(signature.left, greaterThan(porte.right + 16));
              } else {
                expect(signature.right, lessThan(porte.left - 16));
              }
            },
          );

          testWidgets('le logo blanc, une seule fois, a la taille minimale, au debut de '
              'la ligne', (WidgetTester tester) async {
            await _monter(
              tester,
              langue: langue,
              variante: variante,
              direction: sens,
            );
            final Finder logo = find.byType(BrandLogo);
            expect(logo, findsOneWidget);
            final BrandLogo b = tester.widget<BrandLogo>(logo);
            expect(b.fond, FondLogo.violet);
            expect(b.variante, VarianteLogo.horizontal);
            expect(b.hauteur, BrandLogo.minimumHorizontal);
            // Le logo ne se retourne jamais : ni miroir ni rotation au-dessus.
            expect(
              find.ancestor(
                of: logo,
                matching: find.byWidgetPredicate(
                  (Widget w) => w is Transform || w is RotatedBox,
                ),
              ),
              findsNothing,
            );
            // Au debut de la ligne : a gauche en LTR, a droite en RTL.
            final Rect carte = tester.getRect(find.byType(CartePartage));
            final Rect r = tester.getRect(logo);
            if (langue.droiteAGauche) {
              expect(r.center.dx, greaterThan(carte.center.dx));
            } else {
              expect(r.center.dx, lessThan(carte.center.dx));
            }
          });

          testWidgets(
            'l\'appel : le QR, « Decouvrir l\'offre » et le lien, au-dessus du '
            'hadith',
            (WidgetTester tester) async {
              await _monter(
                tester,
                langue: langue,
                variante: variante,
                direction: sens,
              );
              expect(find.byType(QrImageView), findsOneWidget);
              expect(
                tester.widget<Text>(_cle('carte-lien')).data,
                'rewayah.test/fr/',
              );
              expect(
                tester.getBottomLeft(_cle('carte-qr')).dy,
                lessThan(tester.getTopLeft(_cle('carte-hadith')).dy),
              );
              // Le QR et le texte de l'appel sont cote a cote, sur une bande.
              expect(
                tester.getTopLeft(_cle('carte-decouvrir')).dy,
                greaterThanOrEqualTo(tester.getTopLeft(_cle('carte-qr')).dy),
              );
            },
          );

          testWidgets(
            'l\'ordre de lecture : le titre, sa ligne, la signature, l\'appel, '
            'puis le hadith, en bas',
            (WidgetTester tester) async {
              await _monter(
                tester,
                langue: langue,
                variante: variante,
                direction: sens,
              );
              double haut(String cle) => tester.getTopLeft(_cle(cle)).dy;
              final List<String> ordre = <String>[
                'carte-titre',
                'carte-sous-titre',
                'carte-signature',
                'carte-decouvrir',
                'carte-hadith',
                'carte-reference',
              ];
              for (int i = 1; i < ordre.length; i++) {
                expect(
                  haut(ordre[i]),
                  greaterThan(haut(ordre[i - 1])),
                  reason: '${ordre[i - 1]} avant ${ordre[i]}',
                );
              }
              // Le hadith est un rappel, tout en bas : plus petit que le titre,
              // et dans le dernier cinquieme de la carte.
              double taille(String cle) =>
                  tester.widget<Text>(_cle(cle)).style!.fontSize!;
              expect(taille('carte-hadith'), lessThan(taille('carte-titre')));
              expect(
                haut('carte-hadith'),
                greaterThan(
                  tester.getTopLeft(find.byType(CartePartage)).dy +
                      CartePartage.hauteur * 0.8,
                ),
              );
            },
          );

          testWidgets('peu d\'elements : six textes, sept avec la traduction, '
              'jamais une liste', (WidgetTester tester) async {
            await _monter(
              tester,
              langue: langue,
              variante: variante,
              direction: sens,
            );
            final List<String> textes = _textes(tester);
            expect(
              textes.length,
              c.traduction == null ? 7 : 8,
              reason: '$textes',
            );
          });

          testWidgets(
            'la carte tient dans son cadre : ni debordement, ni texte coupe '
            'par le bord',
            (WidgetTester tester) async {
              await _monter(
                tester,
                langue: langue,
                variante: variante,
                direction: sens,
              );
              expect(tester.takeException(), isNull);
              final Rect carte = tester.getRect(find.byType(CartePartage));
              for (final String cle in <String>[
                'carte-titre',
                'carte-sous-titre',
                'carte-signature',
                'carte-decouvrir',
                'carte-lien',
                'carte-hadith',
                'carte-reference',
              ]) {
                final Rect r = tester.getRect(_cle(cle));
                expect(r.left, greaterThanOrEqualTo(carte.left), reason: cle);
                expect(r.right, lessThanOrEqualTo(carte.right), reason: cle);
                expect(r.top, greaterThanOrEqualTo(carte.top), reason: cle);
                expect(r.bottom, lessThanOrEqualTo(carte.bottom), reason: cle);
              }
            },
          );
        });
      }
    }
  });

  group('ce que la carte ne porte pas', () {
    for (final LangueCarte langue in LangueCarte.values) {
      testWidgets(
        '${langue.code} : aucun prix, aucune promesse, jamais l\'academie '
        'comme motif',
        (WidgetTester tester) async {
          await _monter(tester, langue: langue, direction: langue.sens);
          final String tout = _textesSansLien(tester).join('\n').toLowerCase();
          expect(
            RegExp(
              r'[0-9٠-٩]+\s*(\$|€|usd|dollars?|euros?|دولار|يورو|%)|[$€]',
              caseSensitive: false,
            ).hasMatch(tout),
            isFalse,
            reason: tout,
          );
          for (final String mot in <String>[
            'prix',
            'price',
            'preço',
            'tarif',
            'gratuit',
            'garanti',
            'rembours',
            'remise',
            'bourse',
            'سعر',
            'مجان',
            'خصم',
            ...motsQuiNommentLAcademie,
          ]) {
            expect(tout, isNot(contains(mot.toLowerCase())), reason: mot);
          }
        },
      );
    }

    testWidgets('l\'arabe n\'est pas une langue de cours : la carte ne promet '
        'aucune langue de cours', (WidgetTester tester) async {
      await _monter(tester);
      final String tout = _textes(tester).join('\n').toLowerCase();
      for (final String mot in <String>['poular', 'peul', 'wolof', 'langue']) {
        expect(tout, isNot(contains(mot)), reason: mot);
      }
    });
  });

  group('le decor : le symbole contour officiel, tres agrandi et tamise', () {
    test('1,6 a 2 fois la largeur de la carte, coupe par les bords', () {
      const Size carte = Size(CartePartage.largeur, CartePartage.hauteur);
      for (final TextDirection sens in TextDirection.values) {
        final (Offset origine, double largeur) = FiligraneCarte.geometrie(
          carte,
          sens: sens,
        );
        expect(
          largeur / carte.width,
          inInclusiveRange(1.6, 2),
          reason: 'de 1,6 a 2 fois la largeur de la carte',
        );
        final double hauteur = largeur / symboleContour.proportion;
        // Il deborde de la carte : on n'en voit qu'une partie.
        final Rect symbole = Rect.fromLTWH(
          origine.dx,
          origine.dy,
          largeur,
          hauteur,
        );
        expect(symbole.left, lessThan(0), reason: '$sens');
        expect(symbole.right, greaterThan(carte.width), reason: '$sens');
        expect(symbole.bottom, greaterThan(carte.height), reason: '$sens');
        // Et ce qui se voit est bien plus petit que le symbole.
        final Rect visible = symbole.intersect(Offset.zero & carte);
        expect(
          visible.width * visible.height,
          lessThan(symbole.width * symbole.height * 0.75),
          reason: '$sens',
        );
      }
    });

    test('la proportion du symbole officiel, jamais deformee', () {
      // Le symbole du directeur : 743 x 734, lu dans le fichier.
      expect(symboleContour.largeur, 743);
      expect(symboleContour.hauteur, 734);
      expect(symboleContour.proportion, closeTo(743 / 734, 1e-9));
    });

    test('blanc a tres faible opacite : de 6 a 12 pour cent, tamise', () {
      expect(AppPaletteCarte.opaciteFiligrane, inInclusiveRange(0.06, 0.12));
      for (final AppPaletteCarte c in AppPaletteCarte.values) {
        expect(c.filigrane.asBorderSide().color.toARGB32(), 0xFFFFFFFF);
      }
    });

    testWidgets('jamais retourne : en arabe, le meme dessin, seulement deplace '
        'avec la porte', (WidgetTester tester) async {
      // Le symbole seul, sans texte ni scene, dans chaque sens de lecture. Il se
      // deplace avec la porte (qui passe a gauche en arabe) : le dessin arabe
      // est le dessin francais, decale d'un nombre entier de pixels, pixel pour
      // pixel. Jamais un miroir.
      final ImageCarte fr = await imageFiligrane(tester);
      final ImageCarte ar = await imageFiligrane(
        tester,
        sens: TextDirection.rtl,
      );
      const Size carte = Size(CartePartage.largeur, CartePartage.hauteur);
      final double ecart =
          (FiligraneCarte.centreX(carte) -
              FiligraneCarte.centreX(carte, sens: TextDirection.rtl)) *
          carte.width *
          CartePartage.echelleExport;
      expect(ecart, closeTo(ecart.roundToDouble(), 1e-6));
      final int dx = ecart.round();
      expect(dx, greaterThan(300));
      final Color fond = AppPaletteCarte.hommes.fond.background;
      int differents = 0;
      int traits = 0;
      int miroirs = 0;
      for (int y = 0; y < fr.hauteur; y += 2) {
        for (int x = 0; x + dx < fr.largeur; x++) {
          final Color a = ar.pixel(x, y);
          if (!proches(a, fr.pixel(x + dx, y), 4)) {
            differents++;
          }
          if (!proches(a, fond)) {
            traits++;
          }
        }
        // Le meme dessin retourne (le miroir du francais, a la meme place) ne
        // serait pas celui-la : le symbole n'est pas symetrique.
        for (int x = 0; x < ar.largeur; x++) {
          if (!proches(ar.pixel(x, y), fr.pixel(fr.largeur - 1 - x, y), 1)) {
            miroirs++;
          }
        }
      }
      // A l'arrondi du rendu pres (quelques pixels de bord sur 600 000).
      expect(
        differents,
        lessThan(100),
        reason: 'le meme dessin, seulement deplace',
      );
      expect(traits, greaterThan(20000), reason: 'le symbole se voit');
      expect(miroirs, greaterThan(0), reason: 'et ce n\'est pas un miroir');
    });

    testWidgets('la zone de protection du logo est libre de filigrane, dans '
        'les deux sens de lecture', (WidgetTester tester) async {
      final Color fond = AppPaletteCarte.hommes.fond.background;
      for (final LangueCarte langue in <LangueCarte>[
        LangueCarte.francais,
        LangueCarte.arabe,
      ]) {
        // La zone : la place du logo et de sa marge de 25 pour cent, mesuree sur
        // la carte.
        await _monter(tester, langue: langue, direction: langue.sens);
        final Rect carte = tester.getRect(find.byType(CartePartage));
        final Rect zone = tester
            .getRect(find.byKey(CartePartage.zoneLogoKey))
            .shift(-carte.topLeft);
        // Le composant du logo porte sa zone de protection : 25 pour cent de la
        // hauteur du logo, au-dessus et au-dessous.
        final Rect logo = tester
            .getRect(find.byKey(CartePartage.logoKey))
            .shift(-carte.topLeft);
        expect(logo, zone, reason: 'la zone est celle du composant du logo');
        expect(
          zone.height,
          closeTo(
            BrandLogo.minimumHorizontal * (1 + 2 * BrandLogo.zoneProtection),
            0.01,
          ),
        );
        // Le symbole seul : pas un pixel de lui dans cette zone.
        final ImageCarte f = await imageFiligrane(tester, sens: langue.sens);
        int touches = 0;
        for (
          int y = (zone.top * CartePartage.echelleExport).floor();
          y < (zone.bottom * CartePartage.echelleExport).ceil();
          y++
        ) {
          for (
            int x = (zone.left * CartePartage.echelleExport).floor();
            x < (zone.right * CartePartage.echelleExport).ceil();
            x++
          ) {
            if (!proches(f.pixel(x, y), fond, 0)) {
              touches++;
            }
          }
        }
        expect(touches, 0, reason: '${langue.code} : le logo a son air');
      }
    });

    testWidgets(
      'aucun degrade : chaque pixel du fond est le fond uni ou le trait tamise',
      (WidgetTester tester) async {
        for (final VarianteCarte v in VarianteCarte.values) {
          final ImageCarte image = await imageCarte(tester, variante: v);
          final AppPaletteCarte c = _couleurs(v);
          final Color fond = c.fond.background;
          final Color trait = Color.alphaBlend(
            Colors.white.withValues(alpha: AppPaletteCarte.opaciteFiligrane),
            fond,
          );
          int fonds = 0;
          int traits = 0;
          int autres = 0;
          for (int x = 0; x < 1080; x++) {
            final Color p = image.pixel(x, _ligneDuFiligrane);
            if (proches(p, fond)) {
              fonds++;
            } else if (proches(p, trait)) {
              traits++;
            } else {
              autres++;
            }
          }
          // Hors des bords anti-aliases du trait : deux valeurs, pas de degrade.
          expect(fonds, greaterThan(500), reason: v.name);
          expect(traits, greaterThan(20), reason: v.name);
          expect(autres, lessThan(40), reason: '${v.name} : que des aplats');
        }
      },
    );

    testWidgets('le fond est un aplat : aucune decoration en degrade', (
      WidgetTester tester,
    ) async {
      for (final VarianteCarte v in VarianteCarte.values) {
        await _monter(tester, variante: v);
        final Iterable<BoxDecoration> decorations = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(CartePartage),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((DecoratedBox d) => d.decoration)
            .whereType<BoxDecoration>();
        expect(
          decorations.where((BoxDecoration d) => d.gradient != null),
          isEmpty,
          reason: 'aucun degrade (cahier des charges visuel, A.4)',
        );
        expect(
          decorations.where(
            (BoxDecoration d) => d.color == _couleurs(v).fond.background,
          ),
          hasLength(1),
          reason: 'un seul fond uni',
        );
      }
    });
  });

  group('le portail : une porte en arche, un chemin de lumiere', () {
    const Size bande = Size(CartePartage.largeur, CartePartage.hauteurScene);
    final GeometrieScene g = GeometrieScene(bande);

    /// L'etendue verticale du chemin sur la verticale d'abscisse [x] : de son
    /// bord haut a son bord bas, relevee par pas d'un demi-point.
    double epaisseurEn(Path chemin, double x) {
      double? haut;
      double? bas;
      for (double y = 0; y < bande.height; y += 0.5) {
        if (chemin.contains(Offset(x, y))) {
          haut ??= y;
          bas = y;
        }
      }
      return haut == null ? 0 : bas! - haut;
    }

    test('la porte est petite, avec du vide autour', () {
      expect(g.porte.width, lessThan(0.16 * bande.width));
      expect(g.porte.height, lessThan(0.5 * bande.height));
      // Plus haute que large : une arche.
      expect(g.porte.height, greaterThan(g.porte.width * 1.8));
      // Du vide a droite, au-dessus, et a sa gauche : la bande est a elle.
      expect(bande.width - g.porte.right, greaterThanOrEqualTo(24));
      expect(g.porte.top, greaterThanOrEqualTo(12));
      expect(g.porte.left, greaterThan(bande.width * 0.6));
    });

    test(
      'le cadre de la porte tombe sur la marge du texte : tout s\'aligne',
      () {
        final Rect cadre = g.cadrePath.getBounds();
        expect(bande.width - cadre.right, closeTo(AppSpacing.xxl, 0.01));
        // Le meme arrondi que la marge du titre, de la signature et du QR.
        expect(cadre.right, closeTo(bande.width - AppSpacing.xxl, 0.01));
      },
    );

    test('le chemin sort du seuil de la porte et s\'elargit vers le bas et '
        'vers le lecteur : un trapeze courbe', () {
      final Rect b = g.cheminPath.getBounds();
      // Il part du seuil de la porte : son sommet est le seuil, sous la porte.
      expect(b.top, closeTo(g.seuil, 0.01));
      expect(
        g.cheminPath.contains(Offset(g.porte.center.dx, g.seuil + 2)),
        isTrue,
      );
      expect(
        g.cheminPath.contains(Offset(g.porte.center.dx, g.seuil - 2)),
        isFalse,
      );
      // Il s'elargit : mince au pied de la porte, bien plus epais vers le
      // lecteur (de plus en plus, de la porte au bord de la carte).
      final double auSeuil = epaisseurEn(g.cheminPath, g.porte.center.dx);
      final double aMiChemin = epaisseurEn(g.cheminPath, 0.5 * bande.width);
      final double auBord = epaisseurEn(g.cheminPath, 0.05 * bande.width);
      expect(auSeuil, lessThan(0.2 * bande.height));
      expect(aMiChemin, greaterThan(auSeuil + 0.15 * bande.height));
      expect(auBord, greaterThan(aMiChemin));
      expect(auBord, greaterThan(0.3 * bande.height));
      // Il sort de la carte, sur le bord oppose a la porte.
      expect(b.left, lessThan(0));
      // Et il tient dans sa bande, avec de l'air avant le QR : il ne mord ni le
      // QR ni le hadith.
      expect(b.bottom, lessThanOrEqualTo(0.92 * bande.height));
      expect(b.right, lessThanOrEqualTo(g.porte.right));
    });

    test('le chemin n\'est qu\'un trait de lumiere : il ne passe jamais sur le '
        'texte', () {
      // La signature est au-dessus du seuil, a la hauteur de la porte : le
      // chemin est dessous.
      final Rect b = g.cheminPath.getBounds();
      expect(
        b.top,
        greaterThan(
          CartePartage.yPorte + CartePartage.hauteurLigneSignature / 2,
        ),
      );
    });

    test('au plus deux aplats superposes : le chemin et son coeur, plus clair, '
        'pris dans le chemin autour du seuil', () {
      for (final VarianteCarte v in VarianteCarte.values) {
        final AppPaletteCarte c = _couleurs(v);
        expect(
          c.coeur.background.computeLuminance(),
          greaterThan(c.chemin.background.computeLuminance()),
          reason: '${v.name} : le coeur est plus clair que le chemin',
        );
        expect(
          c.chemin.background.computeLuminance(),
          greaterThan(c.fond.background.computeLuminance()),
          reason: '${v.name} : le chemin est plus clair que le fond',
        );
      }
      // Le coeur est pris dans le chemin, jamais ailleurs, et il en laisse
      // une part : la lumiere s'eteint en s'eloignant de la porte.
      final Rect chemin = g.cheminPath.getBounds();
      final Rect coeur = g.coeurPath.getBounds();
      expect(coeur.top, closeTo(chemin.top, 0.01));
      expect(coeur.right, closeTo(chemin.right, 0.01));
      expect(coeur.left, greaterThan(chemin.left + 0.2 * bande.width));
      for (double x = 0; x < bande.width; x += 6) {
        for (double y = 0; y < bande.height; y += 6) {
          if (g.coeurPath.contains(Offset(x, y))) {
            expect(g.cheminPath.contains(Offset(x, y)), isTrue);
          }
        }
      }
      // La lumiere est la plus vive pres de la porte : le pied de la porte
      // est dans le coeur, le bord de la carte n'y est pas.
      expect(
        g.coeurPath.contains(Offset(g.porte.center.dx, g.seuil + 2)),
        isTrue,
      );
      expect(
        g.coeurPath.contains(Offset(2, g.seuil + 0.2 * bande.height)),
        isFalse,
      );
      expect(
        g.cheminPath.contains(Offset(2, g.seuil + 0.2 * bande.height)),
        isTrue,
      );
    });

    test('le symbole et la porte sont sur le meme axe : une porte dans la '
        'porte', () {
      const Size carte = Size(CartePartage.largeur, CartePartage.hauteur);
      // L'axe du symbole : le milieu de son dessin. L'arche interieure du
      // fichier officiel (187 a 556 de 743) est symetrique autour du meme axe.
      final (Offset origine, double largeur) = FiligraneCarte.geometrie(carte);
      expect(origine.dx + largeur / 2, closeTo(g.porte.center.dx, 0.01));
      // En arabe la scene est en miroir : la porte passe a gauche, le symbole
      // la suit.
      final (Offset origineAr, double largeurAr) = FiligraneCarte.geometrie(
        carte,
        sens: TextDirection.rtl,
      );
      expect(largeurAr, largeur);
      expect(
        origineAr.dx + largeurAr / 2,
        closeTo(carte.width - g.porte.center.dx, 0.01),
      );
      expect(origineAr.dy, origine.dy);
    });

    test('l\'arche du symbole passe au-dessus de la porte, avec du jeu', () {
      const Size carte = Size(CartePartage.largeur, CartePartage.hauteur);
      final (Offset origine, double largeur) = FiligraneCarte.geometrie(carte);
      // L'arche interieure du fichier : son sommet est a 197,566 de 743, son
      // trait a 17 : le bas de son trait, a l'echelle de la carte.
      final double echelle = largeur / symboleContour.largeur;
      final double basDuTrait = origine.dy + (197.566 + 8.5) * echelle;
      final Rect cadre = g.cadrePath.getBounds().shift(
        const Offset(0, CartePartage.hautScene),
      );
      expect(cadre.top - basDuTrait, greaterThanOrEqualTo(8));
    });

    test('la branche fleurie des femmes reste sur le chemin, hors de la '
        'lumiere vive, loin du texte : petite, en un coin', () {
      final BrancheFleurie b = g.branche;
      final Rect zone = b.bornes;
      // Elle entre par le bord de la carte, au bas du chemin, et reste a
      // gauche : loin de la porte, au plus pres du bord oppose.
      expect(zone.left, lessThanOrEqualTo(0));
      expect(zone.width, lessThan(0.4 * bande.width));
      expect(zone.right, lessThan(g.porte.left - 120));
      // Sous la signature et le seuil, avant le QR : jamais au-dessus du texte,
      // du logo ni de l'appel.
      expect(zone.top, greaterThan(g.seuil + 0.1 * bande.height));
      expect(zone.bottom, lessThanOrEqualTo(0.92 * bande.height));
      // Chaque point du trait et de chaque feuille est dans le chemin, et
      // aucun dans la lumiere vive : ton sur ton, rien ne depasse.
      for (final Offset p in <Offset>[
        ...b.pointsDesTiges(),
        ...b.pointsDesFeuilles(),
      ]) {
        expect(g.cheminPath.contains(p), isTrue, reason: 'chemin : $p');
        expect(g.coeurPath.contains(p), isFalse, reason: 'coeur : $p');
      }
      // Trois fleurs a cinq petales, petites (moins de 3 pour cent de la
      // bande en rayon) ; chaque pointe de petale est dans le chemin.
      expect(b.fleurs, hasLength(3));
      for (final FleurDeBranche f in b.fleurs) {
        expect(f.rayon, lessThan(0.03 * bande.height));
        expect(f.rayon, greaterThan(0.015 * bande.height));
        for (int i = 0; i < 5; i++) {
          final Offset pointe =
              f.centre +
              Offset.fromDirection(
                f.angle + i * 2 * 3.141592653589793 / 5,
                f.rayon,
              );
          expect(g.cheminPath.contains(pointe), isTrue, reason: '$pointe');
          expect(g.coeurPath.contains(pointe), isFalse, reason: '$pointe');
          expect(g.cheminPath.contains(f.pointDePetale(i)), isTrue);
        }
      }
      // Un fil : le trait est mince (au plus 2 points).
      expect(BrancheFleurie.epaisseurTige, lessThanOrEqualTo(2));
    });

    for (final VarianteCarte v in VarianteCarte.values) {
      testWidgets(
        '${v.name} : les pixels de la scene sont des aplats de la palette',
        (WidgetTester tester) async {
          final ImageCarte image = await imageCarte(tester, variante: v);
          final AppPaletteCarte c = _couleurs(v);
          // Le coeur de la porte.
          expect(
            image.enPoints(_surLaCarte(g.porte.center)),
            c.porte.background,
            reason: 'la porte',
          );
          // Deux points du second aplat, loin l'un de l'autre : meme couleur,
          // aucun degrade.
          final Offset p1 = Offset(
            0.7 * bande.width,
            g.seuil + 0.06 * bande.height,
          );
          final Offset p2 = Offset(
            0.5 * bande.width,
            g.seuil + 0.1 * bande.height,
          );
          for (final Offset p in <Offset>[p1, p2]) {
            expect(g.coeurPath.contains(p), isTrue, reason: '$p');
            expect(image.enPoints(_surLaCarte(p)), c.coeur.background);
          }
          // Deux points du premier aplat, loin l'un de l'autre : dans le
          // chemin, hors du coeur, tous deux de la couleur du chemin.
          final Offset q1 = Offset(
            0.2 * bande.width,
            g.seuil + 0.25 * bande.height,
          );
          final Offset q2 = Offset(
            0.08 * bande.width,
            g.seuil + 0.2 * bande.height,
          );
          for (final Offset q in <Offset>[q1, q2]) {
            expect(g.cheminPath.contains(q), isTrue, reason: '$q');
            expect(g.coeurPath.contains(q), isFalse, reason: '$q');
            expect(image.enPoints(_surLaCarte(q)), c.chemin.background);
          }
        },
      );
    }

    testWidgets('la branche fleurie n\'existe que pour les femmes : fleurs et '
        'tige ton sur ton, le centre de la fleur est le chemin, aucun '
        'personnage', (WidgetTester tester) async {
      final BrancheFleurie b = g.branche;
      final FleurDeBranche fleur = b.fleurs.first;
      final Offset petale = _surLaCarte(fleur.pointDePetale(0));
      final Offset centre = _surLaCarte(fleur.centre);
      final List<Offset> tige = b.pointsDesTiges();
      final Offset surLaTige = _surLaCarte(tige[tige.length ~/ 4]);
      final ImageCarte femmes = await imageCarte(
        tester,
        variante: VarianteCarte.femmes,
      );
      final ImageCarte hommes = await imageCarte(tester);
      const AppPaletteCarte f = AppPaletteCarte.femmes;
      expect(femmes.enPoints(petale), f.coeur.background, reason: 'un petale');
      expect(femmes.enPoints(surLaTige), f.coeur.background, reason: 'la tige');
      expect(
        femmes.enPoints(centre),
        f.chemin.background,
        reason: 'le centre de la fleur est le chemin',
      );
      for (final Offset p in <Offset>[petale, centre, surLaTige]) {
        expect(
          hommes.enPoints(p),
          AppPaletteCarte.hommes.chemin.background,
          reason: 'sans fleur ni branche chez les hommes : le chemin seul, $p',
        );
      }
    });

    for (final VarianteCarte v in VarianteCarte.values) {
      testWidgets('${v.name} : aucune figure sur le chemin, que ses deux aplats '
          '(le chemin et sa lumiere)', (WidgetTester tester) async {
        final ImageCarte image = await imageCarte(tester, variante: v);
        final AppPaletteCarte c = _couleurs(v);
        final Color bas = c.chemin.background;
        final Color haut = c.coeur.background;
        int controles = 0;
        // Tout l'interieur du chemin (a 3 points de ses bords), au demi-point :
        // chaque pixel est entre le chemin et sa lumiere, canal par canal
        // (la couleur d'un bord adouci est un melange des deux). Une forme
        // plus sombre, un personnage par exemple, sortirait de la boite.
        for (double x = 0; x < bande.width; x += 1) {
          for (double y = g.seuil; y < bande.height; y += 1) {
            final Offset p = Offset(x, y);
            if (<Offset>[
              p,
              p.translate(3, 0),
              p.translate(-3, 0),
              p.translate(0, 3),
              p.translate(0, -3),
            ].any((Offset q) => !g.cheminPath.contains(q))) {
              continue;
            }
            final Color px = image.enPoints(_surLaCarte(p));
            controles++;
            for (final (double, double, double) canal
                in <(double, double, double)>[
                  (px.r, bas.r, haut.r),
                  (px.g, bas.g, haut.g),
                  (px.b, bas.b, haut.b),
                ]) {
              expect(
                canal.$1 * 255,
                inInclusiveRange(canal.$2 * 255 - 1.5, canal.$3 * 255 + 1.5),
                reason: '${v.name} : $p',
              );
            }
          }
        }
        expect(controles, greaterThan(5000));
      });
    }

    testWidgets(
      'en arabe, la scene est en miroir : la porte passe du cote du debut de '
      'ligne, la branche fleurie le suit',
      (WidgetTester tester) async {
        final ImageCarte fr = await imageCarte(
          tester,
          variante: VarianteCarte.femmes,
        );
        final ImageCarte ar = await imageCarte(
          tester,
          variante: VarianteCarte.femmes,
          langue: LangueCarte.arabe,
        );
        const AppPaletteCarte c = AppPaletteCarte.femmes;
        final Offset porteFr = _surLaCarte(g.porte.center);
        final Offset porteAr = _surLaCarte(g.porte.center, rtl: true);
        expect(fr.enPoints(porteFr), c.porte.background);
        expect(ar.enPoints(porteAr), c.porte.background);
        expect(porteFr.dx, greaterThan(180));
        expect(porteAr.dx, lessThan(180));
        // Le meme point, de l'autre cote, n'est plus la porte.
        expect(fr.enPoints(porteAr), isNot(c.porte.background));
        expect(ar.enPoints(porteFr), isNot(c.porte.background));
        // La branche est en miroir elle aussi, avec la scene.
        final Offset petale = g.branche.fleurs.first.pointDePetale(0);
        expect(fr.enPoints(_surLaCarte(petale)), c.coeur.background);
        expect(ar.enPoints(_surLaCarte(petale, rtl: true)), c.coeur.background);
        expect(
          fr.enPoints(_surLaCarte(petale, rtl: true)),
          isNot(c.coeur.background),
        );
      },
    );
  });

  group('les deux variantes', () {
    test('une teinte plus douce et feminine pour les femmes, voisine de la '
        'marque : mauve, prune, jamais un rose vif', () {
      final Color h = AppPaletteCarte.hommes.fond.background;
      final Color f = AppPaletteCarte.femmes.fond.background;
      expect(f, isNot(h));
      // Plus clair que le violet profond des hommes : plus doux.
      expect(f.computeLuminance(), greaterThan(h.computeLuminance()));
      // La saturation reste moderee et la teinte mauve a prune : pas un rose
      // criard, pas un rouge.
      final HSLColor hsl = HSLColor.fromColor(f);
      expect(hsl.hue, inInclusiveRange(270, 300), reason: 'mauve a prune');
      expect(hsl.saturation, lessThan(0.5));
      // La porte des femmes tire vers la lavande rosee, tres claire.
      final HSLColor porte = HSLColor.fromColor(
        AppPaletteCarte.femmes.porte.background,
      );
      expect(porte.hue, inInclusiveRange(300, 340));
      expect(porte.lightness, greaterThan(0.9));
    });

    test('les hommes gardent le violet profond de la palette de l\'app', () {
      final AppPalette p = AppPalette.claire();
      expect(
        AppPaletteCarte.hommes.fond.background,
        p.washAccent.onBackground,
        reason: 'le violet sombre du lavis d\'accent',
      );
      expect(
        AppPaletteCarte.hommes.chemin.background,
        p.surfacePrimary.background,
      );
      expect(AppPaletteCarte.hommes.porte.background, p.washAccent.background);
    });

    test('le genre inconnu donne la variante des hommes : sans personnage', () {
      expect(VarianteCarte.depuisGenre(null), VarianteCarte.hommes);
    });
  });

  group('la lisibilite', () {
    for (final VarianteCarte v in VarianteCarte.values) {
      test('${v.name} : le contraste de chaque texte, mesure (4,5:1)', () {
        final AppPaletteCarte c = _couleurs(v);
        final Color fond = c.fond.background;
        final Color encre = c.encreDouce.asBorderSide().color;
        // Le blanc : le titre, la signature, l'appel.
        expect(
          contraste(c.fond.onBackground, fond),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'le blanc sur le fond',
        );
        // L'encre douce : la ligne, le lien, le hadith et sa source.
        expect(
          contraste(encre, fond),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'l\'encre douce sur le fond',
        );
        // Sous le trait tamise du filigrane, le fond est un peu plus clair : les
        // deux textes tiennent encore.
        final Color sousTrait = Color.alphaBlend(
          Colors.white.withValues(alpha: AppPaletteCarte.opaciteFiligrane),
          fond,
        );
        expect(
          contraste(c.fond.onBackground, sousTrait),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'le blanc sous le filigrane',
        );
        expect(
          contraste(encre, sousTrait),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'l\'encre douce sous le filigrane',
        );
      });

      test('${v.name} : les formes porteuses de sens se detachent (3:1)', () {
        final AppPaletteCarte c = _couleurs(v);
        final Color fond = c.fond.background;
        // La porte sur le fond.
        expect(
          contraste(c.porte.background, fond),
          greaterThanOrEqualTo(seuilComposant),
          reason: 'la porte',
        );
        // La plaque blanche du QR sur le fond.
        final AppPalette p = AppPalette.claire();
        expect(
          contraste(p.contenuQr.background, fond),
          greaterThanOrEqualTo(seuilComposant),
          reason: 'la plaque du QR',
        );
        // Le QR : noir sur blanc.
        expect(
          contraste(p.contenuQr.onBackground, p.contenuQr.background),
          greaterThanOrEqualTo(seuilTexte),
          reason: 'le QR',
        );
      });

      test(
        '${v.name} : le chemin et sa lumiere sont un decor, lisible en second '
        'regard seulement : faible contraste',
        () {
          final AppPaletteCarte c = _couleurs(v);
          final double ecart = contraste(
            c.coeur.background,
            c.chemin.background,
          );
          // La branche fleurie est ton sur ton, dans la couleur de la lumiere
          // posee sur le chemin : visible, mais sous les 3:1 d'une forme qui porte
          // un sens.
          expect(ecart, greaterThan(1.3), reason: 'on la voit');
          expect(ecart, lessThan(seuilComposant), reason: 'sans la crier');
        },
      );
    }

    for (final LangueCarte l in LangueCarte.values) {
      testWidgets(
        '${l.code} : les tailles de texte sont lisibles sur une story',
        (WidgetTester tester) async {
          await _monter(tester, langue: l, direction: l.sens);
          double taille(String cle) =>
              tester.widget<Text>(_cle(cle)).style!.fontSize!;
          // 360 points affichent 1080 pixels : 16 points font 48 pixels.
          expect(taille('carte-titre'), greaterThanOrEqualTo(28));
          expect(taille('carte-sous-titre'), greaterThanOrEqualTo(16));
          expect(taille('carte-signature'), greaterThanOrEqualTo(18));
          expect(taille('carte-decouvrir'), greaterThanOrEqualTo(18));
          expect(taille('carte-lien'), greaterThanOrEqualTo(14));
          // Le hadith est discret, mais lisible : 20 points (60 pixels) pour
          // l'arabe, 12 points (36 pixels) pour la traduction et la reference.
          expect(taille('carte-hadith'), greaterThanOrEqualTo(20));
          expect(taille('carte-reference'), greaterThanOrEqualTo(12));
          if (textesCarte[l]!.traduction != null) {
            expect(taille('carte-traduction'), greaterThanOrEqualTo(12));
          }
        },
      );
    }

    testWidgets(
      'le texte porte la couleur de sa variante : blanc pour le titre, '
      'lavande tres claire pour le reste',
      (WidgetTester tester) async {
        for (final VarianteCarte v in VarianteCarte.values) {
          await _monter(tester, variante: v);
          final AppPaletteCarte c = _couleurs(v);
          Color? couleur(String cle) =>
              tester.widget<Text>(_cle(cle)).style!.color;
          expect(couleur('carte-titre'), c.fond.onBackground);
          expect(couleur('carte-signature'), c.fond.onBackground);
          expect(couleur('carte-decouvrir'), c.fond.onBackground);
          expect(
            couleur('carte-sous-titre'),
            c.encreDouce.asBorderSide().color,
          );
          expect(couleur('carte-lien'), c.encreDouce.asBorderSide().color);
          expect(couleur('carte-hadith'), c.encreDouce.asBorderSide().color);
        }
      },
    );
  });

  group('une image ne suit ni le theme ni le texte de l\'appareil', () {
    testWidgets(
      'sombre, texte x2, interface guidee : memes tailles, memes couleurs',
      (WidgetTester tester) async {
        for (final VarianteCarte v in VarianteCarte.values) {
          await _monter(tester, variante: v);
          final Size reference = tester.getSize(_cle('carte-titre'));
          final double taille = tester
              .widget<Text>(_cle('carte-titre'))
              .style!
              .fontSize!;
          final Color? couleur = tester
              .widget<Text>(_cle('carte-titre'))
              .style!
              .color;
          final Rect qr = tester.getRect(_cle('carte-qr'));
          for (final (Brightness, double, InterfaceMode) variante
              in <(Brightness, double, InterfaceMode)>[
                (Brightness.dark, 1, InterfaceMode.standard),
                (Brightness.light, 2, InterfaceMode.standard),
                (Brightness.dark, 2, InterfaceMode.enfant),
              ]) {
            await _monter(
              tester,
              variante: v,
              luminosite: variante.$1,
              echelle: variante.$2,
              mode: variante.$3,
            );
            expect(
              tester.getSize(_cle('carte-titre')),
              reference,
              reason: '${v.name} $variante',
            );
            final TextStyle style = tester
                .widget<Text>(_cle('carte-titre'))
                .style!;
            expect(style.fontSize, taille, reason: '${v.name} $variante');
            expect(style.color, couleur, reason: '${v.name} $variante');
            expect(
              tester.getRect(_cle('carte-qr')),
              qr,
              reason: '${v.name} $variante',
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });

  group('l\'arabe : le texte en miroir, jamais le logo ni le symbole', () {
    testWidgets(
      'le QR, le logo et la signature passent au debut de la ligne, a droite ; '
      'l\'adresse reste lue de gauche a droite',
      (WidgetTester tester) async {
        await _monter(tester);
        final Rect qrFr = tester.getRect(_cle('carte-qr'));
        final Rect logoFr = tester.getRect(find.byType(BrandLogo));
        final Rect signatureFr = tester.getRect(_cle('carte-signature'));
        await _monter(
          tester,
          langue: LangueCarte.arabe,
          direction: TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(_cle('carte-qr')).center.dx,
          greaterThan(qrFr.center.dx),
        );
        expect(
          tester.getRect(find.byType(BrandLogo)).center.dx,
          greaterThan(logoFr.center.dx),
        );
        expect(
          tester.getRect(_cle('carte-signature')).center.dx,
          greaterThan(signatureFr.center.dx),
        );
        expect(
          tester.widget<Text>(_cle('carte-lien')).data,
          'rewayah.test/fr/',
        );
        // Rien de francais, d'anglais ni de portugais ne reste sur la carte
        // arabe.
        final String tout = _textes(tester).join('\n');
        for (final LangueCarte l in <LangueCarte>[
          LangueCarte.francais,
          LangueCarte.anglais,
          LangueCarte.portugais,
        ]) {
          expect(
            tout,
            isNot(contains(textesCarte[l]!.decouvrir)),
            reason: l.code,
          );
          expect(
            tout,
            isNot(contains(textesCarte[l]!.reference)),
            reason: l.code,
          );
        }
      },
    );

    testWidgets(
      'une carte arabe se met en miroir meme dans une page de gauche a droite, '
      'et une carte francaise reste de gauche a droite dans une page de droite '
      'a gauche',
      (WidgetTester tester) async {
        // La carte porte son propre sens de lecture : celui de sa langue, pas
        // celui de la page qui l'affiche.
        await _monter(tester, langue: LangueCarte.arabe);
        expect(
          tester.getRect(_cle('carte-qr')).center.dx,
          greaterThan(tester.getRect(find.byType(CartePartage)).center.dx),
        );
        await _monter(tester, direction: TextDirection.rtl);
        expect(
          tester.getRect(_cle('carte-qr')).center.dx,
          lessThan(tester.getRect(find.byType(CartePartage)).center.dx),
        );
      },
    );
  });

  group('les quatre langues, d\'un coup d\'oeil', () {
    testWidgets(
      'le francais, l\'anglais et le portugais mettent le QR au meme endroit ; '
      'chaque titre tient sur deux lignes au plus',
      (WidgetTester tester) async {
        Rect? qr;
        for (final LangueCarte l in <LangueCarte>[
          LangueCarte.francais,
          LangueCarte.anglais,
          LangueCarte.portugais,
        ]) {
          await _monter(tester, langue: l);
          final Rect r = tester.getRect(_cle('carte-qr'));
          qr ??= r;
          expect(r, qr, reason: l.code);
          final Size titre = tester.getSize(_cle('carte-titre'));
          // Deux lignes de 36 points au plus (28 points sur 36 d'interligne).
          expect(titre.height, lessThanOrEqualTo(72.5), reason: l.code);
        }
      },
    );

    testWidgets('un lien long se reduit, il ne deborde pas', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        lien: Uri.parse(
          'https://un-sous-domaine-vraiment-tres-long.exemple-de-site-public.test:8443/fr/',
        ),
      );
      expect(tester.takeException(), isNull);
      final Rect carte = tester.getRect(find.byType(CartePartage));
      final Rect lien = tester.getRect(_cle('carte-lien'));
      expect(lien.right, lessThanOrEqualTo(carte.right));
      expect(lien.left, greaterThanOrEqualTo(carte.left));
    });
  });

  group('l\'etiquette pour le lecteur d\'ecran', () {
    testWidgets('la carte est une image, decrite une fois, dans sa langue', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _monter(tester, langue: LangueCarte.portugais);
      final SemanticsNode noeud = tester.getSemantics(
        find.byType(CartePartage),
      );
      final String texte = noeud.label;
      expect(texte, contains(textesCarte[LangueCarte.portugais]!.titre));
      expect(texte, contains(textesCarte[LangueCarte.portugais]!.decouvrir));
      expect(texte, contains(signatureArabe));
      expect(texte, contains(hadithArabe));
      poignee.dispose();
    });
  });
}
