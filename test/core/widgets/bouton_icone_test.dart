// BOUTON-ICONE-1 : `BoutonIcone` absorbe la commande en icone seule du
// lecteur du Coran en Mode Accessibilite (ancien `_BoutonIcone` recompose
// dans `coran_accessibilite.dart`). Formes `disque` (surface d'overlay, filet
// fin) et `nue` (icone seule), icone de 20 en encre forte. La cible suit le
// mode pour toutes les formes (`Pressable` impose 48 en standard, 72 en
// interface guidee, la surface la remplit). Les formes `cercle` et `carre`
// gardent leur rendu (icone 24, encre d'accent).

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';

Widget _hote(
  Widget enfant,
  InterfaceMode mode,
  Brightness luminosite, {
  double echelleTexte = 1,
}) => TranslationProvider(
  child: MaterialApp(
    theme: AppTheme.pour(mode, luminosite),
    locale: AppLocale.fr.flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(echelleTexte)),
      child: child!,
    ),
    home: Scaffold(body: Center(child: enfant)),
  ),
);

/// Le theme d'icone qui habille l'icone du bouton.
IconThemeData _themeIcone(WidgetTester tester) => tester
    .widget<IconTheme>(
      find
          .ancestor(of: find.byType(Icon), matching: find.byType(IconTheme))
          .first,
    )
    .data;

/// La surface peinte du bouton : `Pressable` peut elargir la zone de toucher
/// (cible du mode), la surface est la mesure du rendu.
Finder _surface() => find.descendant(
  of: find.byType(BoutonIcone),
  matching: find.byType(DecoratedBox),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(BoutonIcone),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  for (final InterfaceMode mode in InterfaceMode.values) {
    for (final Brightness luminosite in Brightness.values) {
      final String cas = '${mode.name}, ${luminosite.name}';
      final double attendue = mode == InterfaceMode.enfant
          ? AppTouchTarget.enfant
          : AppTouchTarget.standard;

      testWidgets('disque a la cible du mode : $cas', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _hote(
            BoutonIcone(
              icone: AppIcons.menu,
              libelle: 'Ouvrir la navigation',
              forme: FormeBoutonIcone.disque,
              onPress: () {},
            ),
            mode,
            luminosite,
          ),
        );
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(BoutonIcone)),
        );
        expect(tester.getSize(_surface()), Size(attendue, attendue));
        final BoxDecoration deco = _decoration(tester);
        expect(deco.color, palette.surfaceOverlay.background);
        expect(
          deco.border,
          Border.fromBorderSide(palette.borderHairline.asBorderSide()),
        );
        final IconTheme theme = tester.widget<IconTheme>(
          find
              .ancestor(of: find.byType(Icon), matching: find.byType(IconTheme))
              .first,
        );
        expect(theme.data.size, AppSpacing.xl);
        expect(theme.data.color, palette.inkStrong.asIconTheme().color);
        expect(find.byTooltip('Ouvrir la navigation'), findsOneWidget);
        expect(find.bySemanticsLabel('Ouvrir la navigation'), findsOneWidget);
      });

      testWidgets('nue : aucune surface, cible du mode : $cas', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _hote(
            BoutonIcone(
              icone: AppIcons.retour,
              libelle: 'Retour',
              forme: FormeBoutonIcone.nue,
              onPress: () {},
            ),
            mode,
            luminosite,
          ),
        );
        expect(tester.getSize(_surface()), Size(attendue, attendue));
        final BoxDecoration deco = _decoration(tester);
        expect(deco.color, isNull);
        expect(deco.border, isNull);
        final AppPalette palette = AppPalette.of(
          tester.element(find.byType(BoutonIcone)),
        );
        expect(_themeIcone(tester).size, AppSpacing.xl);
        expect(
          _themeIcone(tester).color,
          palette.inkStrong.asIconTheme().color,
        );
      });

      for (final FormeBoutonIcone forme in <FormeBoutonIcone>[
        FormeBoutonIcone.disque,
        FormeBoutonIcone.nue,
      ]) {
        testWidgets(
          '${forme.name} inerte : encre attenuee, non activable : $cas',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              _hote(
                BoutonIcone(
                  icone: AppIcons.menu,
                  libelle: 'Ouvrir la navigation',
                  forme: forme,
                  onPress: null,
                ),
                mode,
                luminosite,
              ),
            );
            final AppPalette palette = AppPalette.of(
              tester.element(find.byType(BoutonIcone)),
            );
            expect(
              _themeIcone(tester).color,
              palette.inkMuted.asIconTheme().color,
            );
            expect(_themeIcone(tester).size, AppSpacing.xl);
            // La cible reste celle du mode : un bouton inerte ne retrecit pas.
            expect(tester.getSize(_surface()), Size(attendue, attendue));
            final SemanticsNode noeud = tester.getSemantics(
              find.bySemanticsLabel('Ouvrir la navigation'),
            );
            expect(
              noeud.getSemanticsData().flagsCollection.isEnabled,
              Tristate.isFalse,
            );
          },
        );
      }

      for (final double echelle in <double>[1, 2]) {
        testWidgets('disque qui suit le texte, texte x$echelle : icone bornee, '
            'cible elargie : $cas', (WidgetTester tester) async {
          await tester.pumpWidget(
            _hote(
              BoutonIcone(
                icone: AppIcons.menu,
                libelle: 'Ouvrir la navigation',
                forme: FormeBoutonIcone.disque,
                suitTexte: true,
                onPress: () {},
              ),
              mode,
              luminosite,
              echelleTexte: echelle,
            ),
          );
          // Icone de 20 a texte x1, de 40 (borne echelleMax) a texte x2 ;
          // la surface entoure l'icone de 8 de chaque cote, 48 au moins,
          // et jamais sous la cible du mode.
          final double icone = AppSpacing.xl * echelle;
          final double surface = <double>[
            attendue,
            icone + AppSpacing.lg,
          ].reduce((double a, double b) => a > b ? a : b);
          expect(_themeIcone(tester).size, icone);
          expect(tester.getSize(_surface()), Size(surface, surface));
        });
      }

      testWidgets(
        'cercle par defaut : rendu inchange (cible du mode, icone 24) : $cas',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _hote(
              BoutonIcone(
                icone: AppIcons.zoomPlus,
                libelle: 'Agrandir',
                onPress: () {},
              ),
              mode,
              luminosite,
            ),
          );
          final AppPalette palette = AppPalette.of(
            tester.element(find.byType(BoutonIcone)),
          );
          expect(tester.getSize(_surface()), Size(attendue, attendue));
          final IconTheme theme = tester.widget<IconTheme>(
            find
                .ancestor(
                  of: find.byType(Icon),
                  matching: find.byType(IconTheme),
                )
                .first,
          );
          expect(theme.data.size, AppSpacing.xxl);
          expect(theme.data.color, palette.inkAccent.asIconTheme().color);
        },
      );
    }
  }
}
