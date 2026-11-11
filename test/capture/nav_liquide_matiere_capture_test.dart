// Captures de la correction LIQUIDE-MATIERE (directeur, 11/11/2026, relayee
// par le garde-cap) : de la pilule au cercle Compte, le corps de la pilule
// s'etire en un pont de matiere (son fond, son ombre, son contour), puis la
// goutte se rompt et le cercle la recoit ; la couleur de selection n'entre
// pas dans le pont. Trois temps (repos, pont etire, goutte rompue), clair et
// sombre, francais et arabe, 390. Sans personne connectee (aucune donnee
// reelle).
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/indicateur_liquide.dart';
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

/// Avance le temps jusqu'a ce que le pont atteigne [seuil].
Future<void> _jusqua(WidgetTester tester, double seuil) async {
  for (int i = 0; i < 120; i++) {
    final double? e = IndicateurLiquide.pontDe(
      tester.element(find.bySemanticsLabel(t.nav.tuteur.accueil)),
    );
    if (e != null && e >= seuil) return;
    await tester.pump(const Duration(milliseconds: 4));
  }
}

void main() {
  group('Capture : liquide de matiere', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe_clair', AppLocale.ar, ThemeMode.light),
          ('arabe_sombre', AppLocale.ar, ThemeMode.dark),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 700), 1);
        await tester.pumpWidget(_barre(theme));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'matiere_${nom}_1_repos')}');
        await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
        await tester.pump();
        await tester.pump();
        await _jusqua(tester, 0.3);
        debugPrint(
          'PNG ${await capturer(tester, 'matiere_${nom}_2_pont_etire')}',
        );
        await _jusqua(tester, 0.72);
        debugPrint(
          'PNG ${await capturer(tester, 'matiere_${nom}_3_goutte_rompue')}',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
      });
    }
  });
}
