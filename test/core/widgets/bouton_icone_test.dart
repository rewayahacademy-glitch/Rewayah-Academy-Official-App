// BOUTON-ICONE-1 : `BoutonIcone` absorbe la commande en icone seule du
// lecteur du Coran en Mode Accessibilite (ancien `_BoutonIcone` recompose
// dans `coran_accessibilite.dart`). Formes `disque` (surface d'overlay, filet
// fin) et `nue` (icone seule), icone de 20 en encre forte. La cible suit le
// mode pour toutes les formes (`Pressable` impose 48 en standard, 72 en
// interface guidee, la surface la remplit). Les formes `cercle` et `carre`
// gardent leur rendu (icone 24, encre d'accent).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';

Widget _hote(Widget enfant, InterfaceMode mode, Brightness luminosite) =>
    TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.pour(mode, luminosite),
        locale: AppLocale.fr.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: Center(child: enfant)),
      ),
    );

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
      });

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
