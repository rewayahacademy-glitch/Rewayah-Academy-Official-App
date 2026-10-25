import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';

import '../../theme/support/contraste.dart';

/// Lot salle 3 (directeur et pilote, 25/10/2026) : une bascule active est
/// sombre neutre, coupee violet de marque, le tableau compris ; le rouge
/// reste a Quitter. Contraste mesure dans les deux themes.
void main() {
  for (final Brightness luminosite in Brightness.values) {
    for (final (String nom, bool? bascule, bool tableau, TonAppel attendu)
        in <(String, bool?, bool, TonAppel)>[
          ('micro ouvert', true, false, TonAppel.actif),
          ('micro coupe', false, false, TonAppel.coupe),
          ('tableau ouvert', true, true, TonAppel.actif),
          ('tableau ferme', false, true, TonAppel.coupe),
        ]) {
      testWidgets('$nom (${luminosite.name})', (WidgetTester tester) async {
        await tester.pumpWidget(
          TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, luminosite),
              home: Scaffold(
                body: Center(
                  child: BoutonAppel(
                    icone: AppIcons.micro,
                    libelle: 'etat',
                    onPress: () {},
                    bascule: bascule,
                    ouvertPrimaire: tableau,
                  ),
                ),
              ),
            ),
          ),
        );
        final BoutonIcone bouton = tester.widget<BoutonIcone>(
          find.byType(BoutonIcone),
        );
        expect(bouton.tonAppel, attendu);
        final AppPalette palette = luminosite == Brightness.dark
            ? AppPalette.sombre()
            : AppPalette.claire();
        final AppColorPair plein = attendu == TonAppel.coupe
            ? AppPalette.claire().surfacePrimary
            : palette.boutonAppelActif;
        // L'icone se lit sur son disque (element graphique, 3:1 au moins).
        expect(
          contraste(plein.onBackground, plein.background),
          greaterThanOrEqualTo(seuilComposant),
        );
        // Jamais le rouge de Quitter.
        expect(
          plein.background,
          isNot(AppPalette.claire().surfaceAlert.background),
        );
      });
    }
  }
}
