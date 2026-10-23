// CAND-06 : la carte a partager, redessinee le 22/10/2026 sur la direction du
// directeur : un fond violet profond, le symbole contour officiel tres agrandi et
// tamise, le portail (une porte en arche, un faisceau de lumiere) qui dit l'eleve
// entrant dans la lumiere du Coran, une typographie suisse ; puis, le 23/10/2026,
// la lumiere et les tenebres : « une sorte de degrade qui montre la dissipation de
// la lumiere de l'immensite des tenebres ».
//
// Ce que la carte porte (un titre sur ce que l'eleve y gagne, la signature de la
// marque pres de la porte, l'appel « Decouvrir l'offre » avec le QR et le lien,
// le logo, le hadith tout en bas, tres discret), ce qu'elle ne porte pas (aucun
// prix, aucune promesse, jamais l'academie comme motif, aucun personnage), ses
// deux variantes (les hommes et le genre inconnu, les femmes), ses quatre langues,
// la scene de lumiere (la geometrie droite du faisceau, la lumiere qui decroit
// du seuil, les tenebres des bords, mesurees sur les pixels du rendu), sa
// lisibilite (contraste mesure sur le pixel le plus clair sous chaque texte) et
// son independance du theme, de la taille de texte et de l'interface guidee.

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/marque/contour_traces.g.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
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
    const Size(CartePartage.largeur, CartePartage.hauteur),
  );
  final Rect p = g.porte;
  return rtl
      ? Rect.fromLTRB(
          CartePartage.largeur - p.right,
          p.top,
          CartePartage.largeur - p.left,
          p.bottom,
        )
      : p;
}

/// Le miroir d'un point de la carte : la scene se retourne en arabe.
Offset _miroir(Offset p) => Offset(CartePartage.largeur - p.dx, p.dy);

/// Le point du faisceau a la part [t] de sa longueur, le long de son axe : 0 au
/// centre du seuil, 1 au bout de la lumiere.
Offset _surAxe(GeometrieScene g, double t) =>
    g.centreSeuil + g.axe * (g.longueur * t);

/// La distance du point [p] au segment [a]-[b].
double _distanceAuSegment(Offset p, Offset a, Offset b) {
  final Offset ab = b - a;
  final Offset ap = p - a;
  final double t =
      ((ap.dx * ab.dx + ap.dy * ab.dy) / (ab.dx * ab.dx + ab.dy * ab.dy)).clamp(
        0.0,
        1.0,
      );
  return (p - (a + ab * t)).distance;
}

/// La distance du point [p] au faisceau : 0 dedans ou sur un bord.
double _distanceAuFaisceau(GeometrieScene g, Offset p) {
  if (g.faisceauPath.contains(p)) {
    return 0;
  }
  final List<Offset> s = g.sommetsFaisceau;
  double d = double.infinity;
  for (int i = 0; i < s.length; i++) {
    d = math.min(d, _distanceAuSegment(p, s[i], s[(i + 1) % s.length]));
  }
  return d;
}

/// Les zones de la carte (en points, dans son repere) ou se posent un texte, le
/// logo ou le QR : la ou la lumiere ne doit rien noyer.
Map<String, Rect> _zones(WidgetTester tester) {
  final Rect carte = tester.getRect(find.byType(CartePartage));
  Rect zone(Finder f) => tester.getRect(f).shift(-carte.topLeft);
  return <String, Rect>{
    'titre': zone(_cle('carte-titre')),
    'sous-titre': zone(_cle('carte-sous-titre')),
    'signature': zone(_cle('carte-signature')),
    'decouvrir': zone(_cle('carte-decouvrir')),
    'lien': zone(_cle('carte-lien')),
    'hadith': zone(_cle('carte-hadith')),
    if (_cle('carte-traduction').evaluate().isNotEmpty)
      'traduction': zone(_cle('carte-traduction')),
    'reference': zone(_cle('carte-reference')),
    'qr': zone(_cle('carte-qr')),
    'logo': zone(find.byKey(CartePartage.logoKey)),
  };
}

/// Le pixel le plus clair de l'image dans [zone] (en points, dans le repere de
/// la carte), releve un pixel sur deux.
Color _pixelLePlusClair(ImageCarte image, Rect zone) {
  const double e = CartePartage.echelleExport;
  Color meilleur = Colors.black;
  double lumMax = -1;
  final int x0 = (zone.left * e).floor().clamp(0, image.largeur - 1);
  final int x1 = (zone.right * e).ceil().clamp(0, image.largeur - 1);
  final int y0 = (zone.top * e).floor().clamp(0, image.hauteur - 1);
  final int y1 = (zone.bottom * e).ceil().clamp(0, image.hauteur - 1);
  for (int y = y0; y <= y1; y += 2) {
    for (int x = x0; x <= x1; x += 2) {
      final Color p = image.pixel(x, y);
      final double l = p.computeLuminance();
      if (l > lumMax) {
        lumMax = l;
        meilleur = p;
      }
    }
  }
  return meilleur;
}

/// La ligne de pixels, au-dessus du fondu du symbole (il commence 80 points au-
/// dessus du seuil de la porte), ou le filigrane est entier : le fond uni et le
/// trait tamise s'y lisent sans lumiere ni texte.
int get _ligneDuFiligrane => (150 * CartePartage.echelleExport).round();

/// La luminosite d'un pixel telle qu'on la voit : la luminance de ses canaux
/// encodes (ceux de l'ecran), pas la luminance lineaire. C'est elle qui compare
/// deux teintes a l'oeil.
double _clarte(Color c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;

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
      'le filigrane seul reste un decor sans degrade : chaque pixel est le fond '
      'uni ou le trait tamise (le degrade n\'est que la lumiere de la scene)',
      (WidgetTester tester) async {
        const AppPaletteCarte c = AppPaletteCarte.hommes;
        final ImageCarte image = await imageFiligrane(tester);
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
        expect(fonds, greaterThan(500));
        expect(traits, greaterThan(20));
        expect(
          autres,
          lessThan(40),
          reason: 'le symbole n\'est que des aplats',
        );
      },
    );

    testWidgets('le symbole est un decor du mur : il s\'eteint en arrivant au seuil de la '
        'porte, et le sol n\'en porte aucun trait', (WidgetTester tester) async {
      final ImageCarte image = await imageFiligrane(tester);
      final Color fond = AppPaletteCarte.hommes.fond.background;
      final GeometrieScene g = GeometrieScene(
        const Size(CartePartage.largeur, CartePartage.hauteur),
      );
      // L'ecart au fond le plus fort de chaque bande de 20 points, de 80 points
      // au-dessus du seuil jusqu'au seuil : le trait s'eteint, de plus en plus.
      double ecartMax(double haut, double bas) {
        double m = 0;
        for (
          int y = (haut * CartePartage.echelleExport).round();
          y < (bas * CartePartage.echelleExport).round();
          y++
        ) {
          for (int x = 0; x < image.largeur; x++) {
            m = math.max(m, (_clarte(image.pixel(x, y)) - _clarte(fond)).abs());
          }
        }
        return m;
      }

      final List<double> bandes = <double>[
        for (int i = 0; i < 4; i++)
          ecartMax(
            g.seuil - FiligraneCarte.hauteurFondu + 20.0 * i,
            g.seuil - FiligraneCarte.hauteurFondu + 20.0 * (i + 1),
          ),
      ];
      final double entier = ecartMax(0, g.seuil - FiligraneCarte.hauteurFondu);
      expect(entier, greaterThan(0.02), reason: 'le symbole se voit au mur');
      for (int i = 1; i < bandes.length; i++) {
        expect(bandes[i], lessThan(bandes[i - 1]), reason: '$bandes');
      }
      expect(bandes.first, lessThan(entier + 1e-9));
      expect(bandes.last, lessThan(0.4 * entier), reason: '$bandes');
      // Du seuil au bas de la carte : le fond uni, pas un trait.
      for (
        int y = (g.seuil * CartePartage.echelleExport).ceil() + 2;
        y < image.hauteur;
        y += 2
      ) {
        for (int x = 0; x < image.largeur; x += 2) {
          expect(
            proches(image.pixel(x, y), fond, 0),
            isTrue,
            reason: '($x, $y) : le sol n\'a aucun motif',
          );
        }
      }
    });

    testWidgets(
      'le fond de la carte est un aplat de la palette : le degrade de '
      'la lumiere est peint par la scene, jamais par une decoration',
      (WidgetTester tester) async {
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
            reason: 'le logo, le QR et le fond sont des aplats',
          );
          expect(
            decorations.where(
              (BoxDecoration d) => d.color == _couleurs(v).fond.background,
            ),
            hasLength(1),
            reason: 'un seul fond uni',
          );
        }
      },
    );
  });

  group('le portail : une porte debout, un faisceau de lumiere droit', () {
    const Size carte = Size(CartePartage.largeur, CartePartage.hauteur);
    final GeometrieScene g = GeometrieScene(carte);

    test('la porte est petite, debout sur son seuil, avec du vide autour', () {
      expect(g.porte.width, lessThan(0.16 * carte.width));
      expect(g.porte.height, lessThan(0.23 * carte.height));
      // Plus haute que large : une arche.
      expect(g.porte.height, greaterThan(g.porte.width * 1.8));
      expect(carte.width - g.porte.right, greaterThanOrEqualTo(24));
      expect(g.porte.left, greaterThan(carte.width * 0.6));
      // Au-dessus de l'appel : le seuil est dans la bande du portail. Le haut de
      // la porte, lui, remonte pres du titre, sans jamais toucher un texte (mesure
      // sur les widgets, dans chaque langue : « la porte ne touche ni le titre... »).
      expect(
        g.seuil,
        lessThan(CartePartage.hautScene + CartePartage.hauteurScene),
      );
      expect(g.cadrePath.getBounds().top, greaterThan(0.25 * carte.height));
      // Debout sur une ligne de sol : le seuil est le bas de l'ouverture.
      expect(g.seuil, g.porte.bottom);
      expect(g.cadrePath.getBounds().bottom, closeTo(g.seuil, 1e-3));
    });

    test(
      'le cadre de la porte tombe sur la marge du texte : tout s\'aligne',
      () {
        final Rect cadre = g.cadrePath.getBounds();
        expect(carte.width - cadre.right, closeTo(AppSpacing.xxl, 0.01));
        expect(cadre.right, closeTo(carte.width - AppSpacing.xxl, 0.01));
      },
    );

    test(
      'le faisceau part exactement du seuil : sa largeur au depart est celle '
      'de l\'ouverture de la porte',
      () {
        final List<Offset> s = g.sommetsFaisceau;
        expect(s, hasLength(4));
        // Les deux coins du faisceau sont les deux coins du bas de l'ouverture.
        expect(s[0], Offset(g.porte.left, g.seuil));
        expect(s[1], Offset(g.porte.right, g.seuil));
        expect((s[1] - s[0]).distance, closeTo(g.porte.width, 1e-9));
        expect(g.coinHaut, s[0]);
        expect(g.coinBas, s[1]);
        // Le faisceau commence au seuil, ni plus haut ni plus bas.
        expect(g.faisceauPath.getBounds().top, closeTo(g.seuil, 1e-3));
        expect(
          g.faisceauPath.contains(Offset(g.porte.center.dx, g.seuil + 1)),
          isTrue,
        );
        expect(
          g.faisceauPath.contains(Offset(g.porte.center.dx, g.seuil - 1)),
          isFalse,
        );
        // Du cote de la porte, il ne depasse jamais son bord droit.
        expect(
          g.faisceauPath.contains(Offset(g.porte.right + 1, g.seuil + 1)),
          isFalse,
        );
        expect(g.faisceauPath.getBounds().right, closeTo(g.porte.right, 1e-3));
      },
    );

    test('ses bords sont des droites : un quadrilatere, aucune courbe', () {
      final List<PathMetric> contours = g.faisceauPath
          .computeMetrics()
          .toList();
      expect(contours, hasLength(1));
      expect(contours.single.isClosed, isTrue);
      final List<Offset> s = g.sommetsFaisceau;
      double perimetre = 0;
      for (int i = 0; i < s.length; i++) {
        perimetre += (s[(i + 1) % s.length] - s[i]).distance;
      }
      // Un trace qui n'a que des segments mesure exactement son perimetre : la
      // moindre courbe le rallongerait (a la precision du moteur, sur 4 points).
      expect(contours.single.length, closeTo(perimetre, 0.01));
      // Chaque point du trace reel est sur l'un des quatre segments.
      for (double d = 0; d <= contours.single.length; d += 1.5) {
        final Offset p = contours.single.getTangentForOffset(d)!.position;
        double ecart = double.infinity;
        for (int i = 0; i < s.length; i++) {
          ecart = math.min(
            ecart,
            _distanceAuSegment(p, s[i], s[(i + 1) % s.length]),
          );
        }
        expect(ecart, lessThan(0.01), reason: '$p');
      }
    });

    test('les deux bords s\'ecartent vers le lecteur : vers le bas et vers le '
        'cote oppose a la porte', () {
      final List<Offset> s = g.sommetsFaisceau;
      final Offset haut = s[3] - s[0];
      final Offset bas = s[2] - s[1];
      for (final Offset bord in <Offset>[haut, bas]) {
        expect(bord.dx, lessThan(0), reason: 'vers le cote oppose a la porte');
        expect(bord.dy, greaterThan(0), reason: 'vers le bas, vers le lecteur');
      }
      // Sous l'horizontale : le bord haut est le plus plat, le bord bas le plus
      // raide ; ils s'ecartent d'au moins 20 degres.
      final double angleHaut = math.atan2(haut.dy, -haut.dx);
      final double angleBas = math.atan2(bas.dy, -bas.dx);
      expect(angleHaut, closeTo(GeometrieScene.angleBordHaut, 1e-9));
      expect(angleBas, closeTo(GeometrieScene.angleBordBas, 1e-9));
      expect(angleBas - angleHaut, greaterThan(20 * math.pi / 180));
      // Aucune bande plate : aucun bord n'est (presque) horizontal.
      expect(angleHaut, greaterThan(8 * math.pi / 180));
      // L'axe est la direction de la lumiere : vers le bas et vers la gauche.
      expect(g.axe.distance, closeTo(1, 1e-9));
      expect(g.axe.dx, lessThan(0));
      expect(g.axe.dy, greaterThan(0));
      // Le bout est plus large que le seuil : le faisceau s'elargit, sans
      // jamais se refermer.
      expect((s[2] - s[3]).distance, greaterThan(2 * g.porte.width));
    });

    test('le faisceau s\'elargit de plus en plus, du seuil a son bout', () {
      double largeurA(double t) {
        final Offset c = _surAxe(g, t);
        double bas = 0;
        while (g.faisceauPath.contains(c + g.normale * (bas + 0.25))) {
          bas += 0.25;
        }
        double haut = 0;
        while (g.faisceauPath.contains(c - g.normale * (haut + 0.25))) {
          haut += 0.25;
        }
        return bas + haut;
      }

      final List<double> largeurs = <double>[
        for (final double t in <double>[0.1, 0.3, 0.5, 0.7, 0.9]) largeurA(t),
      ];
      for (int i = 1; i < largeurs.length; i++) {
        expect(largeurs[i], greaterThan(largeurs[i - 1]), reason: '$largeurs');
      }
      expect(largeurs.first, greaterThan(g.porte.width * 0.5));
    });

    test('la lumiere tient dans la carte : elle s\'eteint avant le bord oppose '
        'a la porte et ne passe ni sur le titre, ni sur la signature, ni sur '
        'le logo', () {
      expect(g.finFaisceau.dx, greaterThan(0));
      expect(g.finFaisceau.dy, lessThan(carte.height));
      expect(g.longueur, lessThan(carte.width));
      // Tout le faisceau est sous le seuil : sous la signature et le titre.
      expect(
        g.faisceauPath.getBounds().top,
        greaterThan(
          CartePartage.yPorte + CartePartage.hauteurLigneSignature / 2,
        ),
      );
      expect(g.faisceauPath.getBounds().bottom, lessThan(carte.height));
    });

    test('la lumiere decroit en table : tres vive au seuil, nulle au bout', () {
      expect(GeometrieScene.arretsFaisceau.first, 0);
      expect(GeometrieScene.arretsFaisceau.last, 1);
      expect(
        GeometrieScene.arretsFaisceau.length,
        GeometrieScene.opacitesFaisceau.length,
      );
      expect(GeometrieScene.eclairement(0), greaterThanOrEqualTo(0.9));
      expect(GeometrieScene.eclairement(1), 0);
      double precedent = 2;
      for (double t = 0; t <= 1.0001; t += 0.02) {
        final double e = GeometrieScene.eclairement(t);
        expect(e, lessThanOrEqualTo(precedent), reason: 't = $t');
        precedent = e;
      }
    });

    test('le symbole et la porte sont sur le meme axe : une porte dans la '
        'porte', () {
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

    test('le sommet de l\'arche du symbole reste sous le haut du cadre : il se '
        'perd derriere la porte et son halo, sans filet au-dessus d\'elle', () {
      final (Offset origine, double largeur) = FiligraneCarte.geometrie(carte);
      // L'arche interieure du fichier : son sommet est a 197,566 de 743, son
      // trait a 17 : le haut de son trait, a l'echelle de la carte.
      final double echelle = largeur / symboleContour.largeur;
      final double hautDuTrait = origine.dy + (197.566 - 8.5) * echelle;
      expect(hautDuTrait, greaterThanOrEqualTo(g.cadrePath.getBounds().top));
    });

    for (final VarianteCarte v in VarianteCarte.values) {
      final AppPaletteCarte c = _couleurs(v);

      testWidgets('${v.name} : la porte est la zone la plus claire, de la '
          'teinte de la variante, presque blanche', (
        WidgetTester tester,
      ) async {
        final ImageCarte image = await imageScene(
          tester,
          couleurs: c,
          variante: v,
        );
        final Color coeur = image.enPoints(g.porte.center);
        expect(proches(coeur, c.eclat.background, 3), isTrue, reason: '$coeur');
        expect(coeur.computeLuminance(), greaterThan(0.9));
        // Aucun pixel de la carte, hors de la porte, n'est aussi clair.
        double plusClair = 0;
        for (int y = 0; y < image.hauteur; y += 3) {
          for (int x = 0; x < image.largeur; x += 3) {
            final Offset p = Offset(
              x / CartePartage.echelleExport,
              y / CartePartage.echelleExport,
            );
            // Le liseré du halo, tout contre l'ouverture, en est le prolongement.
            if (g.porte.inflate(8).contains(p)) {
              continue;
            }
            plusClair = math.max(
              plusClair,
              image.pixel(x, y).computeLuminance(),
            );
          }
        }
        expect(plusClair, lessThan(0.9 * coeur.computeLuminance()));
        // Son pied et son sommet prennent la teinte de la porte, pas un blanc
        // neutre : l'eclat est au coeur, la teinte au bord.
        for (final double y in <double>[g.seuil - 3, g.porte.top + 3]) {
          final Color bord = image.enPoints(Offset(g.porte.center.dx, y));
          expect(
            proches(bord, c.porte.background, 14),
            isTrue,
            reason: '$bord',
          );
        }
      });

      testWidgets('${v.name} : le halo de la porte deborde sur le mur et se '
          'dissipe', (WidgetTester tester) async {
        final ImageCarte image = await imageScene(
          tester,
          couleurs: c,
          variante: v,
        );
        // Au-dessus de la porte, la ou rien ne passe : de plus en plus loin du
        // cadre, de moins en moins clair.
        final double haut = g.cadrePath.getBounds().top;
        final List<double> lum = <double>[
          for (final double ecart in <double>[4, 12, 28, 55, 95])
            image
                .enPoints(Offset(g.porte.center.dx, haut - ecart))
                .computeLuminance(),
        ];
        for (int i = 1; i < lum.length; i++) {
          expect(lum[i], lessThan(lum[i - 1]), reason: '$lum');
        }
        // Le halo se voit : tout contre le cadre, le mur est plus clair que le
        // fond uni de la variante, de loin ; il s'eteint, plus loin.
        final double fond = c.fond.background.computeLuminance();
        expect(lum.first, greaterThan(1.8 * fond), reason: '$lum');
        expect(lum.last, lessThan(0.5 * lum.first), reason: '$lum');
        // Et la porte se detache de son halo : 3:1 sur le mur le plus clair a
        // cote d'elle.
        expect(
          contraste(
            c.eclat.background,
            image.enPoints(Offset(g.porte.center.dx, haut - 4)),
          ),
          greaterThanOrEqualTo(seuilComposant),
          reason: 'la porte sur son halo',
        );
      });

      testWidgets(
        '${v.name} : la lumiere deborde sur le cadre : de l\'ouverture '
        'vers le mur, aucun creux entre elle et lui, puis la lumiere ne fait '
        'que baisser',
        (WidgetTester tester) async {
          final ImageCarte image = await imageScene(
            tester,
            couleurs: c,
            variante: v,
          );
          // Deux profils, du bord de l'ouverture vers l'exterieur : de profil, au
          // milieu de la porte (a gauche), et de face, au-dessus de son sommet.
          for (final (String, Offset Function(double)) profil
              in <(String, Offset Function(double))>[
                (
                  'a gauche',
                  (double d) => Offset(g.porte.left - d, g.porte.center.dy),
                ),
                (
                  'au-dessus',
                  (double d) => Offset(g.porte.center.dx, g.porte.top - d),
                ),
              ]) {
            double lum(double d) => _clarte(image.enPoints(profil.$2(d)));
            const double e = GeometrieScene.ecartCadre;
            // Le cadre : le trait de 2 points, a [e] points de l'ouverture.
            double cadre = 0;
            for (double d = e - 1; d <= e + 1; d += 1 / 3) {
              cadre = math.max(cadre, lum(d));
            }
            // Entre l'ouverture et le cadre : le halo l'eclaire, aucun creux.
            double creux = double.infinity;
            for (double d = 0.5; d <= e - 1.5; d += 1 / 3) {
              creux = math.min(creux, lum(d));
            }
            expect(
              creux,
              greaterThanOrEqualTo(0.88 * cadre),
              reason: '${profil.$1} : un creux entre l\'ouverture et le cadre',
            );
            // Le cadre se voit : plus clair que le mur juste derriere lui.
            expect(
              cadre,
              greaterThan(1.15 * lum(e + 3)),
              reason: '${profil.$1} : le cadre se detache',
            );
            // Au-dela du cadre, la lumiere ne fait que baisser.
            double precedent = lum(e + 1.5);
            for (double d = e + 2.5; d <= 40; d += 1) {
              final double l = lum(d);
              expect(
                l,
                lessThanOrEqualTo(precedent + 0.01),
                reason: '${profil.$1} a $d points : la lumiere ne remonte pas',
              );
              precedent = math.min(precedent, l);
            }
          }
        },
      );

      testWidgets('${v.name} : le cadre de la porte reste un aplat : un trait '
          'd\'une seule couleur de la palette, a opacite fixe, peint tel quel '
          '(la lumiere vient ensuite par-dessus)', (WidgetTester tester) async {
        await _monter(tester, variante: v);
        final RenderObject scene = tester.renderObject(
          find
              .descendant(
                of: find.byKey(CartePartage.sceneKey),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        expect(
          scene,
          paints..path(
            color: c.coeur.background.withValues(
              alpha: GeometrieScene.opaciteCadre,
            ),
            style: PaintingStyle.stroke,
            strokeWidth: GeometrieScene.epaisseurCadre,
            hasMaskFilter: false,
          ),
        );
        expect(GeometrieScene.opaciteCadre, inInclusiveRange(0.3, 1));
      });

      testWidgets('${v.name} : la lumiere du faisceau est tres vive au seuil '
          'et s\'eteint, de plus en plus, dans l\'obscurite', (
        WidgetTester tester,
      ) async {
        final ImageCarte image = await imageScene(
          tester,
          couleurs: c,
          variante: v,
        );
        final List<double> lum = <double>[
          for (final double t in <double>[0.03, 0.1, 0.2, 0.35, 0.5, 0.7, 0.9])
            image.enPoints(_surAxe(g, t)).computeLuminance(),
        ];
        for (int i = 1; i < lum.length; i++) {
          expect(lum[i], lessThan(lum[i - 1]), reason: '$lum');
        }
        expect(lum.first, greaterThan(0.5), reason: 'tres vive au seuil');
        expect(lum.last, lessThan(0.1 * lum.first), reason: 'presque eteinte');
        // Au bout, plus rien : de part et d'autre de la fin, le meme mur.
        final double avant = image
            .enPoints(_surAxe(g, 0.995))
            .computeLuminance();
        final double apres = image
            .enPoints(_surAxe(g, 1.06))
            .computeLuminance();
        expect((avant - apres).abs(), lessThan(0.012));
        // Le faisceau se detache du mur qu'il eclaire : a mi-longueur, dans la
        // lumiere, bien plus clair que le mur voisin, au-dessus de son bord.
        final Offset dedans = _surAxe(g, 0.3);
        final Offset dehors = dedans - g.normale * 90;
        expect(g.faisceauPath.contains(dedans), isTrue);
        expect(g.faisceauPath.contains(dehors), isFalse);
        expect(
          image.enPoints(dedans).computeLuminance(),
          greaterThan(2 * image.enPoints(dehors).computeLuminance()),
        );
      });

      testWidgets('${v.name} : le faisceau est un peu plus clair au centre '
          'qu\'aux bords', (WidgetTester tester) async {
        final ImageCarte image = await imageScene(
          tester,
          couleurs: c,
          variante: v,
        );
        for (final double t in <double>[0.3, 0.45]) {
          final Offset axe = _surAxe(g, t);
          double bas = 0;
          while (g.faisceauPath.contains(axe + g.normale * (bas + 0.25))) {
            bas += 0.25;
          }
          double haut = 0;
          while (g.faisceauPath.contains(axe - g.normale * (haut + 0.25))) {
            haut += 0.25;
          }
          // Le milieu du faisceau, en travers, et chacun de ses deux bords, a
          // quatre points a l'interieur.
          final Offset milieu = axe + g.normale * ((bas - haut) / 2);
          final double auMilieu = image.enPoints(milieu).computeLuminance();
          for (final Offset bord in <Offset>[
            axe + g.normale * (bas - 4),
            axe - g.normale * (haut - 4),
          ]) {
            expect(g.faisceauPath.contains(bord), isTrue);
            expect(
              image.enPoints(bord).computeLuminance(),
              lessThan(auMilieu),
              reason: 't = $t, $bord',
            );
          }
        }
      });

      testWidgets('${v.name} : les tenebres montent des bords et des coins : '
          'les quatre coins sont plus sombres que le pourtour de la porte', (
        WidgetTester tester,
      ) async {
        final ImageCarte image = await imageScene(
          tester,
          couleurs: c,
          variante: v,
        );
        final double pourtour = image
            .enPoints(
              Offset(g.porte.center.dx, g.cadrePath.getBounds().top - 28),
            )
            .computeLuminance();
        final double fond = c.fond.background.computeLuminance();
        for (final Offset coin in const <Offset>[
          Offset(3, 3),
          Offset(CartePartage.largeur - 3, 3),
          Offset(3, CartePartage.hauteur - 3),
          Offset(CartePartage.largeur - 3, CartePartage.hauteur - 3),
        ]) {
          final double l = image.enPoints(coin).computeLuminance();
          expect(l, lessThan(0.3 * pourtour), reason: '$coin');
          expect(
            l,
            lessThan(0.4 * fond),
            reason: '$coin : plus sombre que le fond',
          );
        }
        // Les tenebres s'epaississent, de plus en plus, en s'eloignant de la
        // lumiere : du milieu vers le coin du haut, le long du bord haut, et de la
        // porte vers le coin du bas, loin du faisceau.
        for (final (Offset, Offset) trajet in const <(Offset, Offset)>[
          (Offset(190, 270), Offset(4, 4)),
          (Offset(190, 8), Offset(4, 4)),
          (Offset(250, 450), Offset(356, 636)),
        ]) {
          final List<double> lum = <double>[
            for (double u = 0; u <= 1.0001; u += 0.2)
              image
                  .enPoints(Offset.lerp(trajet.$1, trajet.$2, u)!)
                  .computeLuminance(),
          ];
          for (int i = 1; i < lum.length; i++) {
            expect(
              lum[i],
              lessThanOrEqualTo(lum[i - 1] + 1e-4),
              reason: '$trajet $lum',
            );
          }
          expect(lum.last, lessThan(0.6 * lum.first), reason: '$trajet');
        }
      });
    }

    testWidgets('les deux variantes ont exactement la meme geometrie de lumiere : '
        'les memes zones eclairees, branche comprise', (WidgetTester tester) async {
      final ImageCarte h = await imageScene(tester);
      final ImageCarte f = await imageScene(
        tester,
        couleurs: AppPaletteCarte.femmes,
        variante: VarianteCarte.femmes,
      );
      // Les memes zones de lumiere : un pixel est « eclaire » quand il atteint
      // le tiers de l'eclat de la porte, dans l'une comme dans l'autre.
      final double seuilH = h.enPoints(g.porte.center).computeLuminance() / 3;
      final double seuilF = f.enPoints(g.porte.center).computeLuminance() / 3;
      int eclaires = 0;
      int differents = 0;
      for (int y = 0; y < h.hauteur; y += 3) {
        for (int x = 0; x < h.largeur; x += 3) {
          final bool a = h.pixel(x, y).computeLuminance() >= seuilH;
          final bool b = f.pixel(x, y).computeLuminance() >= seuilF;
          if (a || b) {
            eclaires++;
          }
          if (a != b) {
            differents++;
          }
        }
      }
      expect(eclaires, greaterThan(3000), reason: 'la lumiere se voit');
      // Moins d'un pixel sur dix d'ecart, au bord de la zone : la geometrie est
      // la meme (la branche des femmes ne change rien a la lumiere).
      expect(differents / eclaires, lessThan(0.1));
    });

    testWidgets(
      'les deux variantes ont la meme lumiere : a chaque endroit de la '
      'scene, la meme luminosite a 5 pour cent pres, seule la teinte change',
      (WidgetTester tester) async {
        // La scene seule, sans la branche des femmes (elle n'est pas de la
        // lumiere) : les hommes, puis les femmes.
        final ImageCarte h = await imageScene(tester);
        final ImageCarte f = await imageScene(
          tester,
          couleurs: AppPaletteCarte.femmes,
        );
        final List<(String, Offset)> points = <(String, Offset)>[
          ('haut du milieu', const Offset(180, 60)),
          ('haut a gauche', const Offset(40, 40)),
          ('bord gauche', const Offset(15, 230)),
          ('coin du bas', const Offset(20, 620)),
          ('bas du milieu', const Offset(180, 610)),
          ('le mur sous le sous-titre', const Offset(200, 175)),
          ('le mur a gauche de la porte', const Offset(150, 250)),
          ('a cote de la porte', Offset(g.porte.left - 20, g.porte.center.dy)),
          ('sous la porte, a droite', const Offset(345, 400)),
          ('coin du bas a droite', const Offset(340, 600)),
          for (final double t in <double>[0.05, 0.15, 0.3, 0.6, 0.8, 0.95])
            ('le faisceau a ${(t * 100).round()} %', _surAxe(g, t)),
        ];
        for (final (String, Offset) p in points) {
          final double a = _clarte(h.enPoints(p.$2));
          final double b = _clarte(f.enPoints(p.$2));
          expect(
            b / a,
            closeTo(1, 0.05),
            reason: '${p.$1} : hommes $a, femmes $b',
          );
        }
        // Et la teinte, elle, differe : le meme point n'a pas la meme couleur.
        const Offset mur = Offset(150, 250);
        expect(proches(h.enPoints(mur), f.enPoints(mur), 12), isFalse);
      },
    );

    testWidgets('en arabe la scene est en miroir : la porte et son faisceau '
        'passent du cote du debut de ligne, la lumiere y garde son modele', (
      WidgetTester tester,
    ) async {
      for (final VarianteCarte v in VarianteCarte.values) {
        final AppPaletteCarte c = _couleurs(v);
        final ImageCarte fr = await imageScene(
          tester,
          couleurs: c,
          variante: v,
        );
        final ImageCarte ar = await imageScene(
          tester,
          couleurs: c,
          variante: v,
          sens: TextDirection.rtl,
        );
        final Offset porteFr = g.porte.center;
        final Offset porteAr = _miroir(porteFr);
        expect(proches(fr.enPoints(porteFr), c.eclat.background, 3), isTrue);
        expect(proches(ar.enPoints(porteAr), c.eclat.background, 3), isTrue);
        expect(porteFr.dx, greaterThan(180));
        expect(porteAr.dx, lessThan(180));
        // Le meme point, de l'autre cote, n'est plus la porte.
        expect(proches(fr.enPoints(porteAr), c.eclat.background, 6), isFalse);
        expect(proches(ar.enPoints(porteFr), c.eclat.background, 6), isFalse);
        // Le faisceau est le meme, retourne : pixel pour pixel, au miroir pres.
        int ecarts = 0;
        for (int y = 0; y < fr.hauteur; y += 3) {
          for (int x = 0; x < fr.largeur; x += 3) {
            if (!proches(fr.pixel(x, y), ar.pixel(fr.largeur - 1 - x, y), 6)) {
              ecarts++;
            }
          }
        }
        expect(ecarts, lessThan(40), reason: '${v.name} : une scene en miroir');
        // La lumiere decroit dans le meme ordre, du seuil vers le bout.
        final List<double> lum = <double>[
          for (final double t in <double>[0.05, 0.3, 0.6, 0.9])
            ar.enPoints(_miroir(_surAxe(g, t))).computeLuminance(),
        ];
        for (int i = 1; i < lum.length; i++) {
          expect(lum[i], lessThan(lum[i - 1]), reason: '${v.name} $lum');
        }
      }
    });

    for (final VarianteCarte v in VarianteCarte.values) {
      for (final LangueCarte langue in LangueCarte.values) {
        testWidgets(
          '${v.name} ${langue.code} : la porte et son cadre ne touchent '
          'ni le titre, ni le sous-titre, ni la signature',
          (WidgetTester tester) async {
            await _monter(
              tester,
              langue: langue,
              variante: v,
              direction: langue.sens,
            );
            final Rect cadre = langue.droiteAGauche
                ? Rect.fromLTRB(
                    carte.width - g.cadrePath.getBounds().right,
                    g.cadrePath.getBounds().top,
                    carte.width - g.cadrePath.getBounds().left,
                    g.cadrePath.getBounds().bottom,
                  )
                : g.cadrePath.getBounds();
            // La lumiere du halo tient aussi hors du texte : 6 points de marge.
            final Rect cadreEtMarge = cadre.inflate(6);
            final Map<String, Rect> zones = _zones(tester);
            for (final String nom in <String>[
              'titre',
              'sous-titre',
              'signature',
            ]) {
              expect(
                zones[nom]!.overlaps(cadreEtMarge),
                isFalse,
                reason: '$nom ${zones[nom]} contre le cadre $cadre',
              );
            }
          },
        );
      }
    }

    group('la branche fleurie des femmes : discrete, dans la penombre au bord '
        'du faisceau', () {
      final BrancheFleurie b = g.branche;

      /// Les points a verifier : les tiges, les feuilles et les pointes de
      /// petales, dans le repere de la carte (en francais).
      final List<Offset> points = <Offset>[
        ...b.pointsDesTiges(),
        ...b.pointsDesFeuilles(),
        for (final FleurDeBranche f in b.fleurs)
          for (int i = 0; i < 5; i++)
            f.centre +
                Offset.fromDirection(f.angle + i * 2 * math.pi / 5, f.rayon),
      ];

      test('elle longe le bord haut du faisceau, du cote des tenebres, sans '
          'jamais couper la lumiere', () {
        for (final Offset p in points) {
          expect(g.faisceauPath.contains(p), isFalse, reason: '$p');
          expect(
            _distanceAuFaisceau(g, p),
            greaterThanOrEqualTo(5),
            reason: '$p',
          );
        }
        // Elle est au-dessus du bord haut : du cote des tenebres, jamais entre le
        // faisceau et la porte, ni plus bas que le faisceau.
        final Offset coin = g.coinHaut;
        for (final Offset p in points) {
          final double bordEnX =
              coin.dy +
              (coin.dx - p.dx) * math.tan(GeometrieScene.angleBordHaut);
          expect(p.dy, lessThan(bordEnX), reason: 'au-dessus du bord : $p');
        }
        // Et pres de lui : la branche n'est pas un ornement lointain.
        final double plusPres = points
            .map((Offset p) => _distanceAuFaisceau(g, p))
            .reduce(math.min);
        expect(plusPres, lessThan(14));
      });

      test('elle entre par le bord oppose a la porte, petite, en un coin', () {
        final Rect zone = b.bornes;
        expect(zone.left, lessThanOrEqualTo(0));
        expect(zone.width, lessThan(0.4 * carte.width));
        expect(zone.right, lessThan(g.porte.left - 120));
        // Sous la signature, avant le QR : jamais sur le titre, le logo ni la
        // signature (chaque texte est verifie un a un, plus bas).
        expect(
          zone.top,
          greaterThan(
            CartePartage.yPorte + CartePartage.hauteurLigneSignature / 2 + 8,
          ),
        );
        expect(
          zone.bottom,
          lessThan(CartePartage.hautScene + CartePartage.hauteurScene),
        );
        // Trois fleurs a cinq petales, petites ; un fil mince ; deux boutons.
        expect(b.fleurs, hasLength(3));
        for (final FleurDeBranche f in b.fleurs) {
          expect(f.rayon, inInclusiveRange(3, 8));
        }
        expect(b.boutons, hasLength(2));
        expect(BrancheFleurie.epaisseurTige, lessThanOrEqualTo(2));
        expect(BrancheFleurie.opacite, inInclusiveRange(0.3, 0.7));
      });

      for (final LangueCarte langue in LangueCarte.values) {
        testWidgets('${langue.code} : jamais sous un texte, le QR ni le logo', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            langue: langue,
            variante: VarianteCarte.femmes,
            direction: langue.sens,
          );
          for (final MapEntry<String, Rect> z in _zones(tester).entries) {
            for (final Offset p in points) {
              final Offset q = langue.droiteAGauche ? _miroir(p) : p;
              expect(
                z.value.inflate(2).contains(q),
                isFalse,
                reason: '${z.key} $q',
              );
            }
          }
        });
      }

      testWidgets('elle n\'existe que pour les femmes, et ne change que son '
          'propre dessin : ton sur ton, a faible contraste', (
        WidgetTester tester,
      ) async {
        const AppPaletteCarte c = AppPaletteCarte.femmes;
        final ImageCarte avec = await imageScene(
          tester,
          couleurs: c,
          variante: VarianteCarte.femmes,
        );
        final ImageCarte sans = await imageScene(tester, couleurs: c);
        final FleurDeBranche fleur = b.fleurs.first;
        final Offset petale = fleur.pointDePetale(0);
        final Color surLaBranche = avec.enPoints(petale);
        final Color surLeMur = sans.enPoints(petale);
        // Un petale : la couleur de la lumiere qui s'attenue, posee a l'opacite
        // de la branche sur le mur.
        expect(
          proches(
            surLaBranche,
            Color.alphaBlend(
              c.coeur.background.withValues(alpha: BrancheFleurie.opacite),
              surLeMur,
            ),
            4,
          ),
          isTrue,
          reason: '$surLaBranche sur $surLeMur',
        );
        // A faible contraste : on la voit au second regard, sans la crier (sous
        // les 3:1 d'une forme qui porte un sens).
        final double ecart = contraste(surLaBranche, surLeMur);
        expect(ecart, greaterThan(1.3), reason: 'on la voit');
        expect(ecart, lessThan(seuilComposant), reason: 'sans la crier');
        // Le centre de la fleur est troue : le mur reparait.
        expect(
          proches(avec.enPoints(fleur.centre), sans.enPoints(fleur.centre), 3),
          isTrue,
        );
        // Loin de la branche, la scene est la meme : la branche n'est qu'elle.
        final Rect zone = b.bornes.inflate(14);
        int hors = 0;
        int differents = 0;
        for (int y = 0; y < avec.hauteur; y += 3) {
          for (int x = 0; x < avec.largeur; x += 3) {
            final Offset p = Offset(
              x / CartePartage.echelleExport,
              y / CartePartage.echelleExport,
            );
            if (zone.contains(p)) {
              continue;
            }
            hors++;
            if (!proches(avec.pixel(x, y), sans.pixel(x, y), 1)) {
              differents++;
            }
          }
        }
        expect(hors, greaterThan(50000));
        expect(differents, 0, reason: 'rien d\'autre ne change');
      });
    });
  });

  group('les deux variantes', () {
    test('une teinte plus douce et feminine pour les femmes, voisine de la '
        'marque : mauve, prune, jamais un rose vif ; aussi profonde que celle '
        'des hommes', () {
      final Color h = AppPaletteCarte.hommes.fond.background;
      final Color f = AppPaletteCarte.femmes.fond.background;
      expect(f, isNot(h));
      // La meme profondeur : la meme lumiere sur les deux cartes (le mur des
      // femmes n'est pas plus clair, donc pas plus embrume, que celui des hommes).
      expect(
        f.computeLuminance() / h.computeLuminance(),
        closeTo(1, 0.1),
        reason: 'seule la teinte change',
      );
      // La saturation reste moderee et la teinte mauve a prune : pas un rose
      // criard, pas un rouge ; une autre teinte que le violet bleute des hommes.
      final HSLColor hsl = HSLColor.fromColor(f);
      expect(hsl.hue, inInclusiveRange(270, 300), reason: 'mauve a prune');
      expect(hsl.saturation, lessThan(0.5));
      expect(
        (hsl.hue - HSLColor.fromColor(h).hue).abs(),
        greaterThan(12),
        reason: 'une autre teinte que celle des hommes',
      );
      // La porte des femmes tire vers la lavande rosee, tres claire.
      final HSLColor porte = HSLColor.fromColor(
        AppPaletteCarte.femmes.porte.background,
      );
      expect(porte.hue, inInclusiveRange(300, 340));
      expect(porte.lightness, greaterThan(0.9));
      // L'ouverture de la porte a le meme blanc pur dans les deux variantes.
      for (final AppPaletteCarte c in AppPaletteCarte.values) {
        expect(c.eclat.background, const Color(0xFFFFFFFF), reason: c.name);
      }
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
        // La porte (son eclat comme son bord) sur le fond.
        for (final AppColorPair porte in <AppColorPair>[c.eclat, c.porte]) {
          expect(
            contraste(porte.background, fond),
            greaterThanOrEqualTo(seuilComposant),
            reason: 'la porte',
          );
        }
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

      test('${v.name} : la lumiere s\'eteint, teinte par teinte : l\'eclat, la '
          'porte, la lumiere qui s\'attenue, celle qui s\'eteint, le fond, '
          'puis les tenebres', () {
        final AppPaletteCarte c = _couleurs(v);
        final List<double> lum = <double>[
          c.eclat.background.computeLuminance(),
          c.porte.background.computeLuminance(),
          c.coeur.background.computeLuminance(),
          c.chemin.background.computeLuminance(),
          c.fond.background.computeLuminance(),
          c.tenebres.background.computeLuminance(),
        ];
        for (int i = 1; i < lum.length; i++) {
          expect(lum[i], lessThan(lum[i - 1]), reason: '${v.name} $lum');
        }
        // Des tenebres presque noires, de la teinte de la variante : un violet,
        // jamais un noir neutre.
        expect(lum.last, lessThan(0.01));
        final HSLColor t = HSLColor.fromColor(c.tenebres.background);
        expect(t.saturation, greaterThan(0.3));
        // Un eclat presque blanc.
        expect(lum.first, greaterThan(0.9));
      });
    }

    for (final VarianteCarte v in VarianteCarte.values) {
      for (final LangueCarte l in LangueCarte.values) {
        testWidgets(
          '${v.name} ${l.code} : chaque texte, le logo et le QR, mesures sur le '
          'pixel le plus clair que la lumiere leur laisse',
          (WidgetTester tester) async {
            final AppPaletteCarte c = _couleurs(v);
            await _monter(tester, langue: l, variante: v, direction: l.sens);
            final Map<String, Rect> zones = _zones(tester);
            // Les couleurs des textes, lues sur la carte.
            final Color blanc = c.fond.onBackground;
            final Color encre = c.encreDouce.asBorderSide().color;
            final Map<String, Color> encres = <String, Color>{
              'titre': blanc,
              'signature': blanc,
              'decouvrir': blanc,
              'logo': blanc,
              'sous-titre': encre,
              'lien': encre,
              'hadith': encre,
              'traduction': encre,
              'reference': encre,
            };
            final ImageCarte decor = await imageScene(
              tester,
              couleurs: c,
              variante: v,
              sens: l.sens,
              avecFiligrane: true,
            );
            for (final MapEntry<String, Color> e in encres.entries) {
              final Rect? zone = zones[e.key];
              if (zone == null) {
                continue;
              }
              final Color fond = _pixelLePlusClair(decor, zone.inflate(1));
              expect(
                contraste(e.value, fond),
                greaterThanOrEqualTo(seuilTexte),
                reason:
                    '${e.key} : ${e.value} sur le plus clair, $fond '
                    '(luminance ${fond.computeLuminance()})',
              );
            }
            // La plaque blanche du QR se detache du plus clair qui l'entoure :
            // 3:1, sans que le faisceau la noie.
            final Rect qr = zones['qr']!;
            final AppPalette p = AppPalette.claire();
            Color autour = Colors.black;
            for (final Rect bande in <Rect>[
              Rect.fromLTRB(qr.left - 6, qr.top - 6, qr.right + 6, qr.top),
              Rect.fromLTRB(
                qr.left - 6,
                qr.bottom,
                qr.right + 6,
                qr.bottom + 6,
              ),
              Rect.fromLTRB(qr.left - 6, qr.top, qr.left, qr.bottom),
              Rect.fromLTRB(qr.right, qr.top, qr.right + 6, qr.bottom),
            ]) {
              final Color m = _pixelLePlusClair(decor, bande);
              if (m.computeLuminance() > autour.computeLuminance()) {
                autour = m;
              }
            }
            expect(
              contraste(p.contenuQr.background, autour),
              greaterThanOrEqualTo(seuilComposant),
              reason: 'la plaque du QR sur $autour',
            );
          },
        );
      }
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
