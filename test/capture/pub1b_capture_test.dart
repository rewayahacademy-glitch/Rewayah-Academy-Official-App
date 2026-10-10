// PUB-1b (reserves 3 et 4 de la relecture R2 de PUB-1) : captures de preuve
// de TOUTES les pages de la presentation publique. 320 texte x2 en LTR et
// RTL, clair et sombre ; 1440 clair et sombre ; pages 2 et 3 a 390 en LTR et
// RTL (a 320 x2, une seconde capture `_fin` montre le bas de chaque page,
// apres defilement vertical). Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/preferences/presentation_vue.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/features/bienvenue/bienvenue_page.dart';

import 'outil_capture.dart';

List<Override> _surcharges() => <Override>[
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  stockagePresentationProvider.overrideWithValue(StockagePreferencesMemoire()),
];

void main() {
  group('Capture : PUB-1b', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    final List<(Size, ThemeMode, double, TextDirection, List<int>)> cas =
        <(Size, ThemeMode, double, TextDirection, List<int>)>[
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.light,
            ThemeMode.dark,
          ])
            for (final TextDirection sens in TextDirection.values)
              (const Size(320, 700), mode, 2, sens, <int>[0, 1, 2, 3, 4]),
          (
            const Size(1440, 900),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            <int>[0, 1, 2, 3, 4],
          ),
          (
            const Size(1440, 900),
            ThemeMode.dark,
            1,
            TextDirection.ltr,
            <int>[0, 1, 2, 3, 4],
          ),
          (
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            <int>[1, 2],
          ),
          (
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.rtl,
            <int>[1, 2],
          ),
        ];
    for (final (Size, ThemeMode, double, TextDirection, List<int>) c in cas) {
      final String suffixe =
          '${c.$1.width.toInt()}${c.$3 == 2 ? 'x2' : ''}_'
          '${c.$2 == ThemeMode.light ? 'clair' : 'sombre'}'
          '_${c.$4 == TextDirection.rtl ? 'rtl' : 'ltr'}';
      for (final int page in c.$5) {
        final String nom = 'pub1b_p${page + 1}_$suffixe';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, c.$1, 1);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(textDirection: c.$4, child: const BienvenuePage()),
              surcharges: _surcharges(),
              themeMode: c.$2,
              echelleTexte: c.$3,
            ),
          );
          await stabiliser(tester);
          if (page == 0) {
            // La ligne d'etat a mi-course du defilement automatique.
            for (int i = 0; i < 20; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          } else {
            for (int i = 0; i < page; i++) {
              await tester.tap(find.bySemanticsLabel(t.bienvenue.suivante));
              await tester.pumpAndSettle(AppMouvement.navigation);
            }
          }
          debugPrint('PNG ${await capturer(tester, nom)}');
          // A 320 texte x2, la fin de la page (suite du texte, sorties de la
          // derniere page) passe sous le bord : une seconde capture la montre
          // apres defilement vertical jusqu'au bout.
          if (c.$3 == 2) {
            for (final ScrollableState s in tester.stateList<ScrollableState>(
              find.byWidgetPredicate(
                (Widget w) =>
                    w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )) {
              s.position.jumpTo(s.position.maxScrollExtent);
            }
            // Deux images seulement, pas `pumpAndSettle` : sur la page 1, le
            // defilement automatique tourne encore et changerait de page.
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
            debugPrint('PNG ${await capturer(tester, '${nom}_fin')}');
          }
        });
      }
    }
  });
}
