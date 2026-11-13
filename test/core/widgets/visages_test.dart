// VISAGES (directeur, 12/11/2026, points 7 et 9 de
// docs/current/salle/PLAN-RETOURS-2026-11-12.md) : le cadre de visage de la
// salle.
//
// - le fond du cadre se detache du fond de la page (contraste mesure, clair
//   et sombre) ;
// - dans une petite miniature sans nom, le cercle est au centre exact du
//   cadre (capture du directeur : il etait pousse vers le haut par une rangee
//   de nom vide) ;
// - sans photo, le cercle prend la couleur de la personne, stable ;
// - la lumiere de l'orateur est DANS le cadre, absente quand la personne se
//   tait, presente quand elle parle, et ses vagues ne tournent que pendant la
//   parole ; mouvement reduit : une bordure fixe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/cadre_visage.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';

import '../../capture/outil_capture.dart';

const Key _boite = ValueKey<String>('boite');
const Key _cercle = ValueKey<String>('tuile-sans-image-cercle');

double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

Future<void> _monter(
  WidgetTester tester,
  Widget cadre, {
  Size taille = const Size(240, 180),
  ThemeMode theme = ThemeMode.light,
  bool reduit = false,
  double texte = 1,
}) async {
  fixerVueCapture(tester, const Size(800, 700), 1);
  await tester.pumpWidget(
    hoteCapture(
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                key: _boite,
                width: taille.width,
                height: taille.height,
                child: cadre,
              ),
            ),
          ),
        ),
      ),
      themeMode: theme,
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('le fond du cadre se detache de la page', () {
    test('contraste mesure, clair et sombre', () {
      final AppPalette clair = AppPalette.claire();
      final AppPalette sombre = AppPalette.sombre();
      // Clair : l'ancien fond (surfaceSunken) etait a 1,0:1 du fond de page.
      expect(
        _contraste(
          clair.surfaceSunken.background,
          clair.surfaceCanvas.background,
        ),
        lessThan(1.1),
      );
      expect(
        _contraste(
          clair.surfaceVisage.background,
          clair.surfaceCanvas.background,
        ),
        greaterThanOrEqualTo(10),
      );
      expect(
        _contraste(
          clair.surfaceVisage.background,
          clair.surfaceRaised.background,
        ),
        greaterThanOrEqualTo(11),
      );
      // Sombre : plus clair que la nuit de la page, et plus marque que
      // l'ancien fond (1,3:1).
      final double avant = _contraste(
        sombre.surfaceSunken.background,
        sombre.surfaceCanvas.background,
      );
      final double apres = _contraste(
        sombre.surfaceVisage.background,
        sombre.surfaceCanvas.background,
      );
      expect(apres, greaterThanOrEqualTo(2));
      expect(apres, greaterThan(avant));
      for (final AppPalette p in <AppPalette>[clair, sombre]) {
        // L'encre (nom, micro) et les couleurs des personnes s'y lisent.
        expect(
          _contraste(p.surfaceVisage.onBackground, p.surfaceVisage.background),
          greaterThanOrEqualTo(7),
        );
        for (final AppColorPair accent in p.accentsProfil) {
          expect(
            _contraste(accent.background, p.surfaceVisage.background),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('le cadre pose bien ce fond (${theme.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          const CadreVisage(nom: 'Maryam', prenom: 'Maryam'),
          theme: theme,
        );
        final AppPalette palette = theme == ThemeMode.dark
            ? AppPalette.sombre()
            : AppPalette.claire();
        final Finder fond = find.descendant(
          of: find.byKey(_boite),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    palette.surfaceVisage.background,
          ),
        );
        expect(fond, findsOneWidget);
        expect(tester.getRect(fond.first), tester.getRect(find.byKey(_boite)));
      });
    }
  });

  group('le cercle au centre exact d une petite miniature', () {
    for (final (Size taille, bool micro) in const <(Size, bool)>[
      (Size(96, 72), false),
      (Size(96, 96), false),
      (Size(64, 64), false),
      (Size(104, 78), false),
    ]) {
      for (final double texte in <double>[1, 2]) {
        testWidgets('$taille, micro coupe $micro, texte x$texte', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            CadreVisage(
              nom: 'Nafissatou',
              prenom: 'Nafissatou',
              personneId: 'e1',
              microCoupe: micro,
            ),
            taille: taille,
            texte: texte,
          );
          expect(tester.takeException(), isNull);
          final Rect cadre = tester.getRect(find.byKey(_boite));
          final Rect rond = tester.getRect(find.byKey(_cercle));
          // Mesure au pixel : le centre du rond est celui du cadre.
          expect((rond.center.dx - cadre.center.dx).abs(), lessThan(0.5));
          expect((rond.center.dy - cadre.center.dy).abs(), lessThan(0.5));
          // Aucune rangee de nom vide n'est posee sous le cercle.
          expect(
            find.byKey(const ValueKey<String>('tuile-sans-image-nom')),
            findsNothing,
          );
        });
      }
    }

    testWidgets('micro coupe en petit : le signe reste, sous le cercle, sans '
        'emplacement vide', (WidgetTester tester) async {
      await _monter(
        tester,
        const CadreVisage(
          nom: 'Nafissatou',
          prenom: 'Nafissatou',
          microCoupe: true,
        ),
        taille: const Size(96, 72),
      );
      expect(tester.takeException(), isNull);
      final Rect rond = tester.getRect(find.byKey(_cercle));
      final Rect micro = tester.getRect(
        find.byKey(const ValueKey<String>('tuile-sans-image-micro')),
      );
      expect((rond.center.dx - micro.center.dx).abs(), lessThan(0.5));
      expect(micro.top, greaterThanOrEqualTo(rond.bottom));
    });
  });

  group('sans photo, la couleur de la personne', () {
    testWidgets('le cercle prend une teinte stable par identifiant, jamais la '
        'teinte neutre', (WidgetTester tester) async {
      Color fondDuCercle() {
        final Finder boite = find.descendant(
          of: find.byKey(_cercle),
          matching: find.byType(ColoredBox),
        );
        return tester.widget<ColoredBox>(boite.first).color;
      }

      final AppPalette palette = AppPalette.claire();
      await _monter(
        tester,
        const CadreVisage(nom: 'Yasmine', prenom: 'Yasmine', personneId: 'e1'),
      );
      expect(fondDuCercle(), palette.teintePersonne('e1').background);
      expect(fondDuCercle(), isNot(palette.washFamily.background));
      // La meme personne garde la meme couleur.
      expect(palette.teintePersonne('e1'), same(palette.teintePersonne('e1')));
      // Ailleurs (une liste), le cercle garde la teinte neutre.
      await _monter(
        tester,
        const TuileSansImage(prenom: 'Yasmine', nom: 'Yasmine'),
      );
      expect(fondDuCercle(), palette.washFamily.background);
    });

    test('des identifiants differents se repartissent sur les six teintes', () {
      final AppPalette palette = AppPalette.claire();
      final Set<AppColorPair> vues = <AppColorPair>{
        for (int i = 0; i < 40; i++) palette.teintePersonne('eleve-$i'),
      };
      expect(vues.length, palette.accentsProfil.length);
    });
  });

  group('la lumiere de l orateur', () {
    CadreVisage cadre({required bool parle, bool image = true}) => CadreVisage(
      key: const ValueKey<String>('c'),
      nom: 'Omar',
      prenom: 'Omar',
      parle: parle,
      image: image ? const ColoredBox(color: Color(0xFF3A3A3A)) : null,
    );

    double opacite(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(find.byKey(CadreVisage.cleAnneau))
        .opacity;

    testWidgets('absente quand la personne se tait, presente quand elle '
        'parle, et toujours DANS le cadre', (WidgetTester tester) async {
      await _monter(tester, cadre(parle: false));
      expect(opacite(tester), 0);
      final HaloLumiere eteinte = tester.widget<HaloLumiere>(
        find.byType(HaloLumiere),
      );
      expect(eteinte.voix, isFalse);

      await _monter(tester, cadre(parle: true));
      expect(opacite(tester), 1);
      expect(tester.widget<HaloLumiere>(find.byType(HaloLumiere)).voix, isTrue);
      // Rien ne deborde du cadre : la lumiere a exactement sa taille, et
      // elle est rognee a ses coins.
      final Rect lumiere = tester.getRect(find.byKey(HaloLumiere.voixKey));
      expect(lumiere, tester.getRect(find.byKey(_boite)));
      expect(
        find.ancestor(
          of: find.byKey(HaloLumiere.voixKey),
          matching: find.byType(ClipRRect),
        ),
        findsWidgets,
      );
      // Ce n'est plus l'anneau fonce d'avant : aucun contour d'accent.
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border ==
                  Border.fromBorderSide(
                    AppPalette.claire().inkAccent.asBorderSide(
                      width: CadreVisage.epaisseurAnneau,
                    ),
                  ),
        ),
        findsNothing,
      );
    });

    testWidgets('les vagues ne tournent que pendant la parole', (
      WidgetTester tester,
    ) async {
      HaloLumiere.boucleVoix = true;
      addTearDown(() => HaloLumiere.boucleVoix = false);
      await _monter(tester, cadre(parle: false));
      expect(tester.hasRunningAnimations, isFalse);

      fixerVueCapture(tester, const Size(800, 700), 1);
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(
            body: Center(
              child: SizedBox(
                key: _boite,
                width: 240,
                height: 180,
                child: cadre(parle: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isTrue);

      // Elle se tait : la lumiere s'efface et plus rien ne tourne (un
      // `pumpAndSettle` rend la main).
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(
            body: Center(
              child: SizedBox(
                key: _boite,
                width: 240,
                height: 180,
                child: cadre(parle: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(opacite(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('mouvement reduit : une bordure fixe borderStrong, aucune '
        'vague ; et rien quand la personne se tait', (
      WidgetTester tester,
    ) async {
      await _monter(tester, cadre(parle: true), reduit: true);
      expect(find.byKey(CadreVisage.cleBordureParole), findsOneWidget);
      expect(find.byKey(HaloLumiere.voixKey), findsNothing);
      final DecoratedBox bordure = tester.widget<DecoratedBox>(
        find.byKey(CadreVisage.cleBordureParole),
      );
      expect(
        (bordure.decoration as BoxDecoration).border,
        Border.fromBorderSide(
          AppPalette.claire().borderStrong.asBorderSide(
            width: CadreVisage.epaisseurAnneau,
          ),
        ),
      );
      await _monter(tester, cadre(parle: false), reduit: true);
      expect(find.byKey(CadreVisage.cleBordureParole), findsNothing);
    });

    testWidgets('sans image aussi (photo ou couleur), en sombre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        cadre(parle: true, image: false),
        theme: ThemeMode.dark,
      );
      expect(opacite(tester), 1);
      expect(tester.takeException(), isNull);
    });
  });
}
