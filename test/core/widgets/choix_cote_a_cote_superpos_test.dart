// SUPERPOS-1 (decision du 05/10/2026, prise par delegation) : le radio des
// cartes cote a cote (etape « Genre » de l'inscription) ne se pose plus
// par-dessus l'icone ni le libelle.
//
// Avant : le radio etait peint dans un `Stack`, en haut a la fin de la
// carte ; a 320 de large, la carte n'a que 92 de contenu et le radio
// recouvrait le disque de l'icone (et, en texte double, le libelle).
// Et en texte double a 320, « homme » se coupait en « hom / me » : les
// cartes passent en liste quand un mot ne tient pas dans une carte.
// Contre-epreuve faite : ce test echoue sur l'ancien rendu (recouvrement a
// 320, mot coupe a 320 x2).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';

import '../../support/garde_interface.dart';

/// Aucun mot de [libelle] n'est coupe sur deux lignes.
void _verifierMotsEntiers(WidgetTester tester, String libelle) {
  final RenderParagraph rendu = tester.renderObject<RenderParagraph>(
    find.text(libelle),
  );
  int debut = 0;
  for (final String mot in libelle.split(' ')) {
    final List<TextBox> boites = rendu.getBoxesForSelection(
      TextSelection(baseOffset: debut, extentOffset: debut + mot.length),
    );
    final Set<double> lignes = <double>{for (final TextBox b in boites) b.top};
    expect(lignes, hasLength(1), reason: '« $mot » est coupe');
    debut += mot.length + 1;
  }
}

void main() {
  for (final (double, double, TextDirection) cas
      in <(double, double, TextDirection)>[
        (320, 2, TextDirection.ltr),
        (320, 2, TextDirection.rtl),
        (320, 1, TextDirection.ltr),
        (390, 1, TextDirection.ltr),
        (1440, 1, TextDirection.ltr),
      ]) {
    testWidgets('${cas.$1.toInt()} x${cas.$2.toInt()} ${cas.$3.name} : le '
        'radio ne recouvre ni l icone ni le libelle, aucun mot coupe', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(cas.$1, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(cas.$1, 900),
              textScaler: TextScaler.linear(cas.$2),
            ),
            child: Directionality(
              textDirection: cas.$3,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ChoiceCardGroup(
                    autoriserSaisieLibre: false,
                    coteACote: true,
                    valeurInitiale: const ReponseChoix(valeurs: <String>{'h'}),
                    options: const <OptionChoix>[
                      OptionChoix(
                        valeur: 'h',
                        libelle: 'Un homme',
                        icone: AppIcons.homme,
                      ),
                      OptionChoix(
                        valeur: 'f',
                        libelle: 'Une femme',
                        icone: AppIcons.femme,
                      ),
                    ],
                    onChange: (ReponseChoix _) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Finder radios = find.byType(RadioChoix);
      expect(radios, findsNWidgets(2));
      for (final (int i, String libelle) in <(int, String)>[
        (0, 'Un homme'),
        (1, 'Une femme'),
      ]) {
        final Finder icone = find.byIcon(
          i == 0 ? AppIcons.homme.actif : AppIcons.femme.repos,
        );
        // Le disque de l'icone (pas seulement le glyphe).
        final Finder disque = find.ancestor(
          of: icone,
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is SizedBox &&
                w.width == AppSpacing.respiration + AppSpacing.sm &&
                w.height == w.width,
          ),
        );
        expect(disque, findsOneWidget);
        verifierSansChevauchement(tester, <Finder>[
          radios.at(i),
          find.text(libelle),
          disque,
        ]);
        _verifierMotsEntiers(tester, libelle);
      }
    });
  }
}
