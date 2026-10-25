import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/porte_lumiere.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/recuperation_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../theme/support/contraste.dart';

/// Le parcours d'entree, PR 1 (`docs/current/PARCOURS-ENTREE-2026-10-25.md`
/// §3 C et D) : connexion et recuperation d'acces sur la surface de marque.
/// Rendu a 320 et 1440, texte x1 et x2, clair et sombre, francais et arabe :
/// aucune carte, un seul bouton plein, aucun chevauchement, logo blanc sur le
/// violet, image au debut de ligne (a droite en arabe), contraste mesure.
void main() {
  Future<void> monter(
    WidgetTester tester,
    Widget page, {
    required Size vue,
    double texte = 1,
    ThemeMode theme = ThemeMode.light,
    TextDirection sens = TextDirection.ltr,
  }) async {
    tester.view.physicalSize = vue;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: theme,
            builder: (BuildContext context, Widget? enfant) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(texte)),
              child: Directionality(textDirection: sens, child: enfant!),
            ),
            home: page,
          ),
        ),
      ),
    );
    // L'illustration joue une fois, 1,5 s au plus, puis reste immobile.
    await tester.pump(AppMouvement.entreeIllustration);
    await tester.pump();
  }

  for (final (String nom, Widget page) in <(String, Widget)>[
    ('connexion', const ConnexionPage()),
    ('recuperation', const RecuperationPage()),
  ]) {
    for (final Size vue in <Size>[
      const Size(320, 640),
      const Size(1440, 900),
    ]) {
      for (final double texte in <double>[1, 1.5, 2]) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          for (final TextDirection sens in TextDirection.values) {
            testWidgets('$nom ${vue.width.toInt()} px, texte x$texte, '
                '${theme.name}, ${sens.name}', (WidgetTester tester) async {
              await monter(
                tester,
                page,
                vue: vue,
                texte: texte,
                theme: theme,
                sens: sens,
              );
              expect(tester.takeException(), isNull);
              expect(find.byType(AppCard), findsNothing);
              verifierUnSeulBoutonPlein(tester);

              // Logo horizontal blanc, la porte du site.
              final BrandLogo logo = tester.widget<BrandLogo>(
                find.byKey(const ValueKey<String>('entree-logo')),
              );
              expect(logo.variante, VarianteLogo.horizontal);
              expect(logo.fond, FondLogo.violet);
              expect(find.byType(PorteLumiere), findsOneWidget);

              // Rien ne recouvre le titre, le champ ni le bouton plein.
              final Finder plein = find.byWidgetPredicate(
                (Widget w) =>
                    w is ActionPrincipale &&
                    w.niveau == NiveauAction.principale,
              );
              verifierSansChevauchement(tester, <Finder>[
                find.byKey(const ValueKey<String>('entree-logo')),
                find.byType(PorteLumiere),
                find.byType(TextField),
                plein,
              ]);

              final double largeurUtile = vue.width / texte;
              if (largeurUtile >= 840) {
                // Deux volets : l'image au debut de ligne, a droite en arabe.
                final Rect image = tester.getRect(find.byType(PorteLumiere));
                final Rect champ = tester.getRect(find.byType(TextField));
                if (sens == TextDirection.ltr) {
                  expect(image.center.dx, lessThan(vue.width / 2));
                  expect(champ.center.dx, greaterThan(vue.width / 2));
                } else {
                  expect(image.center.dx, greaterThan(vue.width / 2));
                  expect(champ.center.dx, lessThan(vue.width / 2));
                }
                // Le bouton plein a la largeur de son contenu, au bord de fin.
                expect(
                  tester.widget<ActionPrincipale>(plein).pleineLargeur,
                  isFalse,
                );
                final Rect bouton = tester.getRect(plein);
                final Rect champ2 = tester.getRect(find.byType(TextField));
                if (sens == TextDirection.ltr) {
                  expect(bouton.right, moreOrLessEquals(champ2.right));
                } else {
                  expect(bouton.left, moreOrLessEquals(champ2.left));
                }
                // Connexion : Google puis le lien sur une rangee au bord de
                // fin ; si elle ne tient pas (police de test tres large,
                // texte agrandi), empilees pleine largeur.
                final Finder google = find.widgetWithText(
                  ActionPrincipale,
                  t.connexion.avecGoogle,
                );
                if (google.evaluate().isNotEmpty) {
                  final Rect g = tester.getRect(google);
                  if (g.top == bouton.top) {
                    expect(g.height, bouton.height);
                    if (sens == TextDirection.ltr) {
                      expect(bouton.left - g.right, moreOrLessEquals(8));
                    } else {
                      expect(g.left - bouton.right, moreOrLessEquals(8));
                    }
                  } else {
                    expect(g.width, moreOrLessEquals(champ2.width));
                    expect(bouton.width, moreOrLessEquals(champ2.width));
                  }
                }
              } else {
                // Telephone : le logo est centre, le bouton pleine largeur.
                final Rect logoRect = tester.getRect(
                  find.byKey(const ValueKey<String>('entree-logo')),
                );
                expect(logoRect.center.dx, moreOrLessEquals(vue.width / 2));
                expect(
                  tester.getSize(plein).width,
                  moreOrLessEquals(
                    tester.getSize(find.byType(TextField)).width,
                  ),
                );
              }
            });
          }
        }
      }
    }
  }

  testWidgets('identique en clair et en sombre : le theme clair est force', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      const ConnexionPage(),
      vue: const Size(1440, 900),
      theme: ThemeMode.dark,
    );
    final ThemeData champ = Theme.of(tester.element(find.byType(TextField)));
    expect(champ.brightness, Brightness.light);
  });

  testWidgets('l illustration joue une fois puis s arrete', (
    WidgetTester tester,
  ) async {
    await monter(tester, const ConnexionPage(), vue: const Size(390, 844));
    // Aucune animation ne reste armee : la page se stabilise en moins de
    // deux secondes (une boucle sans fin ferait echouer cet appel).
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('RangeeActions sur ordinateur (correctif du 25/10/2026)', () {
    Widget rangee(double largeur, TextDirection sens) => Directionality(
      textDirection: sens,
      child: Center(
        child: SizedBox(
          width: largeur,
          child: const RangeeActions(
            pileePleineLargeur: true,
            children: <Widget>[
              SizedBox(key: ValueKey<String>('g'), width: 150, height: 52),
              SizedBox(key: ValueKey<String>('p'), width: 120, height: 52),
            ],
          ),
        ),
      ),
    );

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('une rangee au bord de fin quand elle tient (${sens.name})', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(rangee(400, sens));
        final Rect g = tester.getRect(find.byKey(const ValueKey<String>('g')));
        final Rect p = tester.getRect(find.byKey(const ValueKey<String>('p')));
        final Rect cadre = tester.getRect(find.byType(RangeeActions));
        expect(g.top, p.top);
        if (sens == TextDirection.ltr) {
          expect(p.right, cadre.right);
          expect(p.left - g.right, 8);
        } else {
          expect(p.left, cadre.left);
          expect(g.left - p.right, 8);
        }
      });
    }

    testWidgets('empilee pleine largeur quand elle ne tient pas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(rangee(260, TextDirection.ltr));
      final Rect g = tester.getRect(find.byKey(const ValueKey<String>('g')));
      final Rect p = tester.getRect(find.byKey(const ValueKey<String>('p')));
      expect(g.width, 260);
      expect(p.width, 260);
      expect(p.top - g.bottom, 8);
    });
  });

  group('contraste mesure', () {
    final AppPalette claire = AppPalette.claire();
    final AppPalette sur = AppPalette.surMarque();

    test('blanc sur #6538E4 : 6,5:1', () {
      expect(
        contraste(
          claire.surfaceMarque.onBackground,
          claire.surfaceMarque.background,
        ),
        greaterThanOrEqualTo(6.4),
      );
    });

    test('encre, encre secondaire, accent et alerte sur le parchemin', () {
      final Color parchemin = claire.surfaceQuran.background;
      for (final (String nom, Color encre) in <(String, Color)>[
        ('surfaceCanvas.onBackground', claire.surfaceCanvas.onBackground),
        ('inkMuted', claire.inkMuted.asBorderSide().color),
        ('inkAccent', claire.inkAccent.asBorderSide().color),
        ('inkAlert', claire.inkAlert.asBorderSide().color),
      ]) {
        expect(
          contraste(encre, parchemin),
          greaterThanOrEqualTo(seuilTexte),
          reason: '$nom sur surfaceQuran',
        );
      }
    });

    test('bouton plein : blanc sur violet, violet sur blanc', () {
      // Sur la marque : aplat blanc, encre violette.
      expect(
        contraste(
          sur.surfacePrimary.onBackground,
          sur.surfacePrimary.background,
        ),
        greaterThanOrEqualTo(seuilTexte),
      );
      // Sur le parchemin : ActionPrincipale(affirmee: true).
      expect(
        contraste(
          claire.surfacePrimary.onBackground,
          claire.surfacePrimary.background,
        ),
        greaterThanOrEqualTo(seuilTexte),
      );
      expect(
        contraste(
          claire.surfacePrimary.background,
          claire.surfaceQuran.background,
        ),
        greaterThanOrEqualTo(seuilComposant),
      );
    });
  });
}
