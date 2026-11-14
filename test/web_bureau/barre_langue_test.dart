// WEB-BUREAU (harmonisation, 06/11/2026) : la colonne de navigation suit la
// langue choisie sans recharger la page. Constat du garde-cap sur une capture
// du lot 4 : a 1440, l'application passee en arabe gardait « Accueil »,
// « Ma classe »… dans la barre laterale, la coquille n'etant pas reconstruite.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

void main() {
  // L'arabe est une bibliotheque differee : chargee une fois, hors du temps
  // simule du test, puis changee d'un coup pendant le test.
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (AppRole role, String chemin, Key barre)
      in <(AppRole, String, Key)>[
        (AppRole.student, '/eleve', NavShell.barreLateraleKey),
        (AppRole.guardian, '/tuteur/foyer', NavShell.barreLateraleKey),
        (AppRole.teacher, '/enseignant/journee', NavShell.barreLateraleKey),
        (AppRole.student, '/tc/bibliotheque', NavShell.barreLateraleKey),
        (AppRole.admin, '/admin', AdminShell.barreLateraleKey),
      ]) {
    testWidgets('la barre laterale suit la langue : ${role.name} $chemin', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final SessionState session = sessionActive(role);
      final GoRouter routeur = await monterRouteur(
        tester,
        null,
        source: FausseSourceSession(session),
        taille: const Size(1440, 900),
        planFil: planFilPour(session),
      );
      routeur.go(chemin);
      await stabiliser(tester);
      tester.takeException();
      final String libelleFr = _libelles(tester, barre).join('|');
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await stabiliser(tester);
      tester.takeException();
      final String libelleAr = _libelles(tester, barre).join('|');
      expect(libelleAr, isNot(libelleFr));
      expect(libelleAr, contains(RegExp('[؀-ۿ]')));
    });
  }
}

List<String> _libelles(WidgetTester tester, Key barre) => <String>[
  for (final Element e
      in find
          .descendant(of: find.byKey(barre), matching: find.byType(Text))
          .evaluate())
    (e.widget as Text).data ?? '',
];
