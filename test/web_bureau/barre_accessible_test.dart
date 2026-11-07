// WEB-BUREAU (A11Y, 06/11/2026) : la colonne de navigation est dans l'arbre
// d'accessibilite, a 1440, pour chaque role a `NavShell`. Constat du lot
// FIL-ARIANE (robot web) : la barriere modale des pages (`BlockSemantics`)
// effacait la colonne, peinte avant elles ; ni lecteur d'ecran ni robot ne
// trouvaient la navigation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

void main() {
  for (final (AppRole role, String chemin) in <(AppRole, String)>[
    (AppRole.guardian, '/tuteur/foyer'),
    (AppRole.student, '/eleve'),
    (AppRole.teacher, '/enseignant/journee'),
    (AppRole.controller, '/controleur'),
    (AppRole.accountant, '/comptable'),
  ]) {
    testWidgets('la navigation est lue : ${role.name} $chemin', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
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
      expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(NavShell.barreLateraleKey),
          matching: find.bySemanticsLabel(t.nav.principale),
        ),
        findsOneWidget,
      );
      semantique.dispose();
    });
  }
}
