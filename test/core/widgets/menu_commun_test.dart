// LISTES-1 (23/10/2026) : le menu du bouton d'action. Le defaut critique du
// directeur : « au clic, un petit panneau sombre et transparent apparait ».
// Cause prouvee : l'infobulle par defaut de Material (gris 700 a 90 %) que
// `PopupMenuButton` pose sur tout declencheur, et un menu sans theme
// (`surfaceSunken`, rayon 4, ombre noire, contraste 1,015:1).
//
// Ce que ces tests gardent, clair et sombre, 390 et 1440, texte x1 et x2,
// de gauche a droite et de droite a gauche :
//
//   * le theme : infobulle opaque et lente, menu a la surface des dialogues,
//     filet et ombre des jetons (une seule forme pour `MenuActions` et
//     `MenuFiltre`) ;
//   * aucune infobulle sur le declencheur d'un menu ;
//   * ce que `PopupMenuButton` apporte et qu'une refonte ne doit pas casser :
//     Echap, clic exterieur, un seul menu ouvert, bornage a l'ecran, miroir
//     en arabe ;
//   * le clavier : le declencheur et l'entree portent un anneau de focus ;
//   * le contenu : largeur 224 a 320, libelles qui passent a la ligne,
//     entrees destructives au meme corps, separees ;
//   * le contraste du filet en sombre.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/theme/forme_filet_ombre.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/menu_commun.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';

import '../../support/sens_et_echelle.dart';

const String _longLibelle =
    "Admettre en Salle de vérification et d'entretien le candidat retenu";

List<EntreeAction> _actions(List<String> choisies) => <EntreeAction>[
  EntreeAction(
    libelle: 'Exporter la fiche',
    icone: AppIcons.telecharger,
    onChoix: () => choisies.add('exporter'),
  ),
  EntreeAction(
    libelle: _longLibelle,
    icone: AppIcons.verrou,
    onChoix: () => choisies.add('admettre'),
  ),
  EntreeAction(
    libelle: 'Retirer la candidature',
    destructif: true,
    icone: AppIcons.interdit,
    onChoix: () => choisies.add('retirer'),
  ),
];

Widget _hote(
  Widget enfant, {
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  TextDirection? direction,
}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: sensEtEchelle(direction: direction, echelle: echelle),
      home: Scaffold(body: enfant),
    ),
  ),
);

void _vue(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Une infobulle qui dit quelque chose : `PopupMenuButton` pose toujours un
/// `Tooltip`, mais avec un message vide il ne rend que son enfant.
Finder get _infobulles => find.byWidgetPredicate(
  (Widget w) => w is Tooltip && (w.message?.isNotEmpty ?? false),
);

/// Le menu ouvert : la `Material` portant la forme commune.
Finder get _surfaceMenu => find.byWidgetPredicate(
  (Widget w) => w is Material && w.shape is FormeFiletEtOmbre,
);

Rect _rectDe(WidgetTester tester, Finder f) => tester.getRect(f.first);

/// Le contraste WCAG entre deux couleurs opaques.
double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

/// [dessus] (translucide) pose sur [dessous] (opaque).
Color _poser(Color dessus, Color dessous) => Color.alphaBlend(dessus, dessous);

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('Le theme', () {
    for (final Brightness luminosite in Brightness.values) {
      test(
        'infobulle opaque et lente, menu des jetons : ${luminosite.name}',
        () {
          final ThemeData theme = AppTheme.pour(
            InterfaceMode.standard,
            luminosite,
          );
          final AppPalette palette = theme.extension<AppPalette>()!;

          final TooltipThemeData infobulle = theme.tooltipTheme;
          final BoxDecoration fond = infobulle.decoration! as BoxDecoration;
          // Jamais translucide : le « petit panneau transparent » etait un gris
          // a 90 % (blanc a 90 % en sombre).
          expect(fond.color!.a, 1.0);
          expect(fond.color, palette.surfaceInverse.background);
          expect(
            infobulle.textStyle!.color,
            palette.surfaceInverse.onBackground,
          );
          expect(
            _contraste(fond.color!, infobulle.textStyle!.color!),
            greaterThan(7),
          );
          // Un jeton existant du budget de mouvement, aucun jeton ajoute.
          expect(infobulle.waitDuration, AppMouvement.plafond);
          expect(infobulle.waitDuration, greaterThan(AppMouvement.micro));

          final PopupMenuThemeData menu = theme.popupMenuTheme;
          expect(menu.color, palette.surfaceOverlay.background);
          expect(menu.elevation, 0);
          expect(menu.shape, isA<FormeFiletEtOmbre>());
          expect(menu.shape, FormeFiletEtOmbre.menu(palette));
        },
      );
    }

    test('le filet du menu est franc : l\'encre attenuee, pas le filet fin', () {
      for (final AppPalette p in <AppPalette>[
        AppPalette.sombre(),
        AppPalette.claire(),
      ]) {
        final FormeFiletEtOmbre forme = FormeFiletEtOmbre.menu(p);
        expect(forme.filet, isNot(p.borderHairline.asBorderSide()));
        expect(forme.filet, isNot(p.contourCarte.asBorderSide()));
        // Contre la ligne qu'il recouvre (la carte), il se lit a 2:1 au moins,
        // en clair comme en sombre (le filet des cartes donnait 1,1:1 : le menu
        // se confondait avec la liste, relecture visuelle C-01).
        final Color filet = _poser(
          forme.filet.color,
          p.surfaceOverlay.background,
        );
        expect(
          _contraste(filet, p.surfaceRaised.background),
          greaterThanOrEqualTo(2),
          reason: p.estSombre ? 'sombre' : 'clair',
        );
        // Et l'ombre est posee aussi en sombre.
        expect(forme.ombres, isNotEmpty);
      }
    });

    test('en sombre le filet se lit contre la carte ET contre la surface', () {
      // Mesure du 23/10/2026 : surface `#2D2D3B` contre carte `#272734` =
      // 1,09:1, et l'ancien filet `borderHairline` (`#32323F`) 1,17:1 : le
      // bord du menu disparaissait sur une carte sombre.
      final AppPalette p = AppPalette.sombre();
      final Color surface = p.surfaceOverlay.background;
      final Color carte = p.surfaceRaised.background;
      final Color filet = _poser(p.contourCarte.debugValue, surface);
      final Color ancien = p.borderHairline.debugValue;
      expect(_contraste(filet, carte), greaterThan(_contraste(ancien, carte)));
      expect(_contraste(filet, carte), greaterThanOrEqualTo(1.5));
      expect(_contraste(filet, surface), greaterThanOrEqualTo(1.4));
    });

    test(
      'en clair le filet du menu est celui des cartes, plus franc que le fin',
      () {
        // Mesure du 23/10/2026 : le filet des surfaces (A-12, directeur,
        // 17/10/2026) se lit a 1,33:1 contre la surface blanche du menu et a
        // 1,16:1 contre le fond de page ; l'ombre de niveau 2 fait le reste. Le
        // filet fin (`borderHairline`) donnait 1,07:1 contre ce fond.
        final AppPalette p = AppPalette.claire();
        final Color filet = _poser(
          p.contourCarte.debugValue,
          p.surfaceOverlay.background,
        );
        expect(
          _contraste(filet, p.surfaceOverlay.background),
          greaterThanOrEqualTo(1.3),
        );
        expect(
          _contraste(filet, p.surfaceCanvas.background),
          greaterThanOrEqualTo(1.15),
        );
        expect(
          _contraste(filet, p.surfaceCanvas.background),
          greaterThan(
            _contraste(p.borderHairline.debugValue, p.surfaceCanvas.background),
          ),
        );
      },
    );
  });

  group('L\'infobulle', () {
    testWidgets('n\'apparait ni au survol bref, ni jamais opaque a moitie', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Center(
            child: BoutonIcone(
              icone: AppIcons.fermer,
              libelle: 'Fermer ce panneau',
              onPress: () {},
            ),
          ),
        ),
      );
      final TestGesture souris = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: Offset.zero);
      addTearDown(souris.removePointer);
      await souris.moveTo(tester.getCenter(find.byType(BoutonIcone)));
      await tester.pump(AppMouvement.micro);
      // Avant son delai : rien. Un clic court ne montre jamais l'infobulle.
      expect(find.text('Fermer ce panneau'), findsNothing);

      await tester.pump(AppMouvement.plafond);
      await tester.pump(AppMouvement.micro);
      expect(find.text('Fermer ce panneau'), findsOneWidget);

      // Opaque : la decoration de l'infobulle n'a aucune transparence.
      final DecoratedBox fond = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Fermer ce panneau'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = fond.decoration as BoxDecoration;
      final AppPalette palette = AppPalette.claire();
      expect(decoration.color, palette.surfaceInverse.background);
      expect(decoration.color!.a, 1.0);
    });

    testWidgets('un menu d\'actions n\'a aucune infobulle, ni au survol', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: MenuActions(
              actions: _actions(<String>[]),
              objet: 'Classe 3',
            ),
          ),
        ),
      );
      expect(_infobulles, findsNothing);
      final TestGesture souris = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: Offset.zero);
      addTearDown(souris.removePointer);
      await souris.moveTo(tester.getCenter(find.byType(MenuActions)));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Actions\u00a0: Classe 3'), findsNothing);
      expect(find.text('Afficher le menu'), findsNothing);
      expect(_infobulles, findsNothing);
    });

    testWidgets('un menu de filtre n\'a pas d\'infobulle non plus', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: MenuFiltre<String>(
              libelle: 'État',
              valeur: null,
              entrees: const <EntreeFiltre<String>>[
                EntreeFiltre<String>(valeur: null, libelle: 'Tous'),
                EntreeFiltre<String>(valeur: 'a', libelle: 'Actif'),
              ],
              onChoix: (String? _) {},
            ),
          ),
        ),
      );
      expect(_infobulles, findsNothing);
    });

    testWidgets('le declencheur garde son libelle dans la voix', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          Column(
            children: <Widget>[
              MenuActions(actions: _actions(<String>[]), objet: 'Classe 3'),
              MenuActions(actions: _actions(<String>[])),
              MenuActions(
                actions: _actions(<String>[]),
                libelle: 'Autres gestes',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Actions\u00a0: Classe 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Actions'), findsOneWidget);
      expect(find.bySemanticsLabel('Autres gestes'), findsOneWidget);
      semantique.dispose();
    });
  });

  // Les 16 combinaisons : (clair, sombre) x (390, 1440) x (x1, x2) x (LTR,
  // RTL), avec le declencheur au bout de la ligne, la ou le menu doit se
  // replier pour tenir.
  for (final Brightness luminosite in Brightness.values) {
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final TextDirection direction in TextDirection.values) {
          final String cas =
              '${luminosite.name} ${taille.width.round()} x$echelle '
              '${direction.name}';
          group('MenuActions ouvert : $cas', () {
            Future<List<String>> ouvrir(
              WidgetTester tester, {
              AlignmentGeometry place = AlignmentDirectional.topEnd,
            }) async {
              _vue(tester, taille);
              final List<String> choisies = <String>[];
              await tester.pumpWidget(
                _hote(
                  Align(
                    alignment: place,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: MenuActions(
                        actions: _actions(choisies),
                        objet: 'Classe 3',
                      ),
                    ),
                  ),
                  luminosite: luminosite,
                  echelle: echelle,
                  direction: direction,
                ),
              );
              await tester.tap(find.byType(MenuActions));
              await tester.pumpAndSettle();
              return choisies;
            }

            testWidgets('surface des jetons, bornee a l\'ecran, rien tronque', (
              WidgetTester tester,
            ) async {
              await ouvrir(tester);
              expect(tester.takeException(), isNull);
              final Finder surface = _surfaceMenu;
              expect(surface, findsOneWidget);

              final AppPalette palette = luminosite == Brightness.dark
                  ? AppPalette.sombre()
                  : AppPalette.claire();
              final Material m = tester.widget<Material>(surface);
              // La surface des dialogues, pas la teinte creuse de Material.
              expect(m.color, palette.surfaceOverlay.background);
              expect(m.elevation, 0);
              expect(m.shape, FormeFiletEtOmbre.menu(palette));

              // Borne a l'ecran, marge de 8 comprise.
              final Rect r = _rectDe(tester, surface);
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.top, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(taille.width));
              expect(r.bottom, lessThanOrEqualTo(taille.height));

              // Largeur de 224 a 320 (moins la marge d'ecran sur un telephone).
              expect(
                r.width,
                greaterThanOrEqualTo(taille.width < 336 ? 0 : 224),
              );
              expect(r.width, lessThanOrEqualTo(320));

              // Aucune entree n'est coupee : chaque libelle est rendu entier.
              expect(find.text('Exporter la fiche'), findsOneWidget);
              expect(find.text(_longLibelle), findsOneWidget);
              expect(find.text('Retirer la candidature'), findsOneWidget);
              final Rect long = tester.getRect(find.text(_longLibelle));
              expect(long.left, greaterThanOrEqualTo(r.left));
              expect(long.right, lessThanOrEqualTo(r.right));
            });

            testWidgets('le libelle long passe a la ligne', (
              WidgetTester tester,
            ) async {
              await ouvrir(tester);
              final double haut = tester
                  .getSize(find.text(_longLibelle))
                  .height;
              final double court = tester
                  .getSize(find.text('Exporter la fiche'))
                  .height;
              expect(haut, greaterThan(court * 1.5));
              expect(tester.takeException(), isNull);
            });

            testWidgets(
              'l\'entree destructive a le corps des autres, en alerte',
              (WidgetTester tester) async {
                await ouvrir(tester);
                final AppPalette palette = luminosite == Brightness.dark
                    ? AppPalette.sombre()
                    : AppPalette.claire();
                final TextStyle normal = tester
                    .widget<Text>(find.text('Exporter la fiche'))
                    .style!;
                final TextStyle alerte = tester
                    .widget<Text>(find.text('Retirer la candidature'))
                    .style!;
                expect(alerte.fontSize, normal.fontSize);
                expect(alerte.fontWeight, normal.fontWeight);
                expect(alerte.height, normal.height);
                expect(alerte.color, palette.inkAlert.debugValue);
                expect(normal.color, palette.inkStrong.debugValue);
                // Separee des autres par un trait, jamais melangee.
                expect(find.byType(SeparateurMenu<int>), findsOneWidget);
                final double yTrait = tester
                    .getCenter(find.byType(SeparateurMenu<int>))
                    .dy;
                expect(
                  yTrait,
                  greaterThan(tester.getCenter(find.text(_longLibelle)).dy),
                );
                expect(
                  yTrait,
                  lessThan(
                    tester.getCenter(find.text('Retirer la candidature')).dy,
                  ),
                );
              },
            );

            testWidgets('chaque entree a la cible tactile', (
              WidgetTester tester,
            ) async {
              await ouvrir(tester);
              for (final String libelle in <String>[
                'Exporter la fiche',
                'Retirer la candidature',
              ]) {
                final Finder ligne = find.ancestor(
                  of: find.text(libelle),
                  matching: find.byType(PopupMenuItem<int>),
                );
                expect(tester.getSize(ligne).height, greaterThanOrEqualTo(48));
              }
            });

            testWidgets('Echap ferme le menu sans rien choisir', (
              WidgetTester tester,
            ) async {
              final List<String> choisies = await ouvrir(tester);
              expect(_surfaceMenu, findsOneWidget);
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.pumpAndSettle();
              expect(_surfaceMenu, findsNothing);
              expect(choisies, isEmpty);
            });

            testWidgets('un clic exterieur ferme le menu sans rien choisir', (
              WidgetTester tester,
            ) async {
              final List<String> choisies = await ouvrir(tester);
              expect(_surfaceMenu, findsOneWidget);
              await tester.tapAt(Offset(2, taille.height - 2));
              await tester.pumpAndSettle();
              expect(_surfaceMenu, findsNothing);
              expect(choisies, isEmpty);
            });

            testWidgets('choisir une entree la declenche et ferme le menu', (
              WidgetTester tester,
            ) async {
              final List<String> choisies = await ouvrir(tester);
              await tester.tap(find.text('Retirer la candidature'));
              await tester.pumpAndSettle();
              expect(choisies, <String>['retirer']);
              expect(_surfaceMenu, findsNothing);
            });
          });
        }
      }
    }
  }

  group('MenuActions : le placement suit le sens de lecture', () {
    Future<void> ouvrirA(
      WidgetTester tester,
      TextDirection direction,
      AlignmentGeometry place,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: place,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: MenuActions(
                actions: _actions(<String>[]),
                objet: 'Classe 3',
              ),
            ),
          ),
          direction: direction,
        ),
      );
      await tester.tap(find.byType(MenuActions));
      await tester.pumpAndSettle();
    }

    testWidgets('LTR : le menu part du bord de debut du declencheur', (
      WidgetTester tester,
    ) async {
      await ouvrirA(tester, TextDirection.ltr, Alignment.topCenter);
      final Rect declencheur = tester.getRect(find.byType(MenuActions));
      final Rect menu = _rectDe(tester, _surfaceMenu);
      expect(menu.left, closeTo(declencheur.left, 1));
      expect(menu.top, greaterThanOrEqualTo(declencheur.bottom - 1));
    });

    testWidgets('RTL : le menu part du bord de debut, a droite', (
      WidgetTester tester,
    ) async {
      await ouvrirA(tester, TextDirection.rtl, Alignment.topCenter);
      final Rect declencheur = tester.getRect(find.byType(MenuActions));
      final Rect menu = _rectDe(tester, _surfaceMenu);
      expect(menu.right, closeTo(declencheur.right, 1));
    });

    testWidgets('au bord de fin, le menu se replie vers l\'interieur', (
      WidgetTester tester,
    ) async {
      for (final TextDirection direction in TextDirection.values) {
        await ouvrirA(tester, direction, AlignmentDirectional.topEnd);
        final Rect menu = _rectDe(tester, _surfaceMenu);
        expect(menu.left, greaterThanOrEqualTo(0));
        expect(menu.right, lessThanOrEqualTo(1440));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('au bord de debut aussi (arabe : le bord droit)', (
      WidgetTester tester,
    ) async {
      for (final TextDirection direction in TextDirection.values) {
        await ouvrirA(tester, direction, AlignmentDirectional.topStart);
        final Rect menu = _rectDe(tester, _surfaceMenu);
        expect(menu.left, greaterThanOrEqualTo(0));
        expect(menu.right, lessThanOrEqualTo(1440));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a 320 px, texte x2, le menu tient dans l\'ecran', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(320, 700));
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: MenuActions(
              actions: _actions(<String>[]),
              objet: 'Classe 3',
            ),
          ),
          echelle: 2,
        ),
      );
      await tester.tap(find.byType(MenuActions));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Rect menu = _rectDe(tester, _surfaceMenu);
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(menu.right, lessThanOrEqualTo(320));
      expect(menu.bottom, lessThanOrEqualTo(700));
    });
  });

  group('Un seul menu ouvert a la fois', () {
    testWidgets('un clic sur un autre declencheur ferme le premier', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Column(
            children: <Widget>[
              MenuActions(
                key: const ValueKey<String>('un'),
                actions: _actions(<String>[]),
                objet: 'Classe 1',
              ),
              MenuActions(
                key: const ValueKey<String>('deux'),
                actions: _actions(<String>[]),
                objet: 'Classe 2',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('un')));
      await tester.pumpAndSettle();
      expect(_surfaceMenu, findsOneWidget);

      // Le second declencheur est sous la barriere : le clic ferme le
      // premier menu, il n'en ouvre pas un second par-dessus.
      await tester.tap(
        find.byKey(const ValueKey<String>('deux')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(_surfaceMenu, findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('deux')));
      await tester.pumpAndSettle();
      expect(_surfaceMenu, findsOneWidget);
    });
  });

  group('MenuActions : l\'ordre et les groupes des entrees', () {
    testWidgets('l\'ordre de l\'appelant est garde, un trait a chaque groupe', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      final List<String> choisies = <String>[];
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: MenuActions(
              objet: 'Classe 3',
              actions: <EntreeAction>[
                EntreeAction(
                  libelle: 'Premiere',
                  onChoix: () => choisies.add('premiere'),
                ),
                EntreeAction(
                  libelle: 'Ecarter',
                  destructif: true,
                  onChoix: () => choisies.add('ecarter'),
                ),
                EntreeAction(
                  libelle: 'Deuxieme',
                  onChoix: () => choisies.add('deuxieme'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MenuActions));
      await tester.pumpAndSettle();
      final List<double> hauteurs = <String>[
        'Premiere',
        'Ecarter',
        'Deuxieme',
      ].map((String t) => tester.getTopLeft(find.text(t)).dy).toList();
      // Le composant ne reordonne rien : l'ordre est celui de l'appelant.
      expect(hauteurs, orderedEquals(<double>[...hauteurs]..sort()));
      // Un trait a chaque changement de groupe : avant et apres le destructif.
      expect(find.byType(SeparateurMenu<int>), findsNWidgets(2));
      // Choisir une entree appelle la bonne action.
      await tester.tap(find.text('Ecarter'));
      await tester.pumpAndSettle();
      expect(choisies, <String>['ecarter']);
    });

    testWidgets('un separateur de groupe demande par l\'appelant est pose', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: MenuActions(
              objet: 'Classe 3',
              actions: <EntreeAction>[
                EntreeAction(libelle: 'A', onChoix: () {}),
                EntreeAction(
                  libelle: 'B',
                  separateurAvant: true,
                  onChoix: () {},
                ),
                EntreeAction(libelle: 'C', onChoix: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MenuActions));
      await tester.pumpAndSettle();
      expect(find.byType(SeparateurMenu<int>), findsOneWidget);
    });
  });

  group('Le survol (force : flutter test n\'a pas de vraie souris)', () {
    testWidgets('le declencheur du menu et la case peignent un disque doux', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      for (final Brightness luminosite in Brightness.values) {
        await tester.pumpWidget(
          _hote(
            luminosite: luminosite,
            PressionForcee(
              etat: const EtatPression(survole: true),
              child: Row(
                children: <Widget>[
                  MenuActions(
                    objet: 'Classe 3',
                    points: true,
                    actions: <EntreeAction>[
                      EntreeAction(libelle: 'A', onChoix: () {}),
                    ],
                  ),
                  CaseACocher(valeur: false, libelle: 'x', onChange: (_) {}),
                ],
              ),
            ),
          ),
        );
        // Le theme glisse d'un mode a l'autre : on attend qu'il se pose.
        await tester.pumpAndSettle();
        final AppPalette p = luminosite == Brightness.light
            ? AppPalette.claire()
            : AppPalette.sombre();
        final int disques = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((DecoratedBox d) {
              final Decoration dec = d.decoration;
              return dec is BoxDecoration &&
                  dec.shape == BoxShape.circle &&
                  dec.color == p.washAccent.background;
            })
            .length;
        expect(disques, 2, reason: luminosite.name);
      }
    });
  });

  group('Le clavier', () {
    DecoratedBox? anneau(WidgetTester tester, Finder dans) {
      final Iterable<DecoratedBox> trouves = tester.widgetList<DecoratedBox>(
        find.descendant(of: dans, matching: find.byType(DecoratedBox)),
      );
      for (final DecoratedBox d in trouves) {
        final Decoration decoration = d.decoration;
        if (decoration is BoxDecoration &&
            decoration.border is Border &&
            (decoration.border! as Border).top.width ==
                Pressable.epaisseurFocus) {
          return d;
        }
      }
      return null;
    }

    for (final Brightness luminosite in Brightness.values) {
      testWidgets('le declencheur porte un anneau au focus : '
          '${luminosite.name}', (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          _hote(
            Align(
              alignment: AlignmentDirectional.topStart,
              child: MenuActions(
                actions: _actions(<String>[]),
                objet: 'Classe 3',
              ),
            ),
            luminosite: luminosite,
          ),
        );
        expect(anneau(tester, find.byType(MenuActions)), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final DecoratedBox? a = anneau(tester, find.byType(MenuActions));
        expect(
          a,
          isNotNull,
          reason: 'aucun anneau de focus sur le declencheur',
        );
        final AppPalette palette = luminosite == Brightness.dark
            ? AppPalette.sombre()
            : AppPalette.claire();
        expect(
          ((a!.decoration as BoxDecoration).border! as Border).top.color,
          palette.inkAccent.debugValue,
        );
      });
    }

    testWidgets(
      'Entree ouvre le menu, fleche bas pose l\'anneau sur l\'entree, '
      'Entree la choisit',
      (WidgetTester tester) async {
        _vue(tester, const Size(1440, 900));
        final List<String> choisies = <String>[];
        await tester.pumpWidget(
          _hote(
            Align(
              alignment: AlignmentDirectional.topStart,
              child: MenuActions(
                actions: _actions(choisies),
                objet: 'Classe 3',
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_surfaceMenu, findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final DecoratedBox? a = anneau(tester, _surfaceMenu);
        expect(a, isNotNull, reason: 'aucun anneau de focus sur l\'entree');

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(choisies, hasLength(1));
        expect(_surfaceMenu, findsNothing);
      },
    );

    testWidgets('au doigt, aucune entree ne porte d\'anneau', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: MenuActions(
              actions: _actions(<String>[]),
              objet: 'Classe 3',
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MenuActions));
      await tester.pumpAndSettle();
      expect(anneau(tester, _surfaceMenu), isNull);
    });
  });

  group('MenuFiltre : la meme forme', () {
    testWidgets('surface et forme du theme, Echap et clic exterieur', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      String? choix = 'a';
      await tester.pumpWidget(
        _hote(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: MenuFiltre<String>(
              libelle: 'État',
              valeur: choix,
              entrees: const <EntreeFiltre<String>>[
                EntreeFiltre<String>(valeur: null, libelle: 'Tous'),
                EntreeFiltre<String>(valeur: 'a', libelle: 'Actif'),
                EntreeFiltre<String>(valeur: 'b', libelle: 'Suspendu'),
              ],
              onChoix: (String? v) => choix = v,
            ),
          ),
          luminosite: Brightness.dark,
        ),
      );
      await tester.tap(find.byType(MenuFiltre<String>));
      await tester.pumpAndSettle();
      final AppPalette palette = AppPalette.sombre();
      final Material m = tester.widget<Material>(_surfaceMenu);
      expect(m.color, palette.surfaceOverlay.background);
      expect(m.shape, FormeFiletEtOmbre.menu(palette));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_surfaceMenu, findsNothing);

      await tester.tap(find.byType(MenuFiltre<String>));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(1400, 800));
      await tester.pumpAndSettle();
      expect(_surfaceMenu, findsNothing);
      expect(choix, 'a');

      await tester.tap(find.byType(MenuFiltre<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suspendu'));
      await tester.pumpAndSettle();
      expect(choix, 'b');
    });

    testWidgets('l\'entree « tous » relache toujours le filtre', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(1440, 900));
      String? choix = 'a';
      await tester.pumpWidget(
        _hote(
          MenuFiltre<String>(
            libelle: 'État',
            valeur: choix,
            entrees: const <EntreeFiltre<String>>[
              EntreeFiltre<String>(valeur: null, libelle: 'Tous'),
              EntreeFiltre<String>(valeur: 'a', libelle: 'Actif'),
            ],
            onChoix: (String? v) => choix = v,
          ),
        ),
      );
      await tester.tap(find.byType(MenuFiltre<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tous'));
      await tester.pumpAndSettle();
      expect(choix, isNull);
    });
  });
}
