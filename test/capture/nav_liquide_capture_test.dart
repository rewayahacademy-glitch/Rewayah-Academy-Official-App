// Captures de l'effet liquide (decisions du directeur du 10/11/2026) : la
// goutte en vol, d'un onglet a l'autre (etiree) et de la pilule au cercle
// Compte (le pont), clair et sombre, francais et arabe, 390. Au repos, rien
// ne change (captures de nav-barre-flottante).
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

Widget _barre(ThemeMode theme) {
  int actif = 0;
  final List<Destination> d = destinationsPour(
    role: AppRole.guardian,
    mode: InterfaceMode.standard,
  );
  return hoteCapture(
    StatefulBuilder(
      builder: (BuildContext _, StateSetter majeur) => NavShell(
        destinations: d,
        indexActif: actif,
        onAller: (String c) => majeur(
          () => actif = d.indexWhere((Destination x) => x.chemin == c),
        ),
        child: PageShell(
          titre: d[actif].libelle,
          child: const SizedBox(height: 200),
        ),
      ),
    ),
    surcharges: <Override>[sansPersonneConnectee()],
    themeMode: theme,
  );
}

void main() {
  group('Capture : effet liquide', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (
          String nom,
          AppLocale langue,
          ThemeMode theme,
          bool cercle,
          int ms,
        )
        in <(String, AppLocale, ThemeMode, bool, int)>[
          ('onglet_etire_clair', AppLocale.fr, ThemeMode.light, false, 80),
          ('onglet_etire_sombre', AppLocale.fr, ThemeMode.dark, false, 80),
          ('cercle_pont_clair', AppLocale.fr, ThemeMode.light, true, 120),
          ('cercle_pont_sombre', AppLocale.fr, ThemeMode.dark, true, 120),
          ('cercle_pont_arabe', AppLocale.ar, ThemeMode.light, true, 120),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 700), 1);
        await tester.pumpWidget(_barre(theme));
        await stabiliser(tester);
        await tester.tap(
          find.bySemanticsLabel(
            cercle ? t.nav.tuteur.compte : t.nav.tuteur.historique,
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(Duration(milliseconds: ms));
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'liquide_$nom')}');
        await tester.pumpAndSettle();
      });
    }
  });
}
