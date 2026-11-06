// WEB-BUREAU (harmonisation, arbitrage du garde-cap du 06/11/2026) : une
// seule cloche dans l'en-tete de la direction. Avec la capacite « alertes »,
// l'entree des alertes portait la meme cloche que les notifications (capture
// du lot 8, Programmes a 1440) ; elle porte desormais l'icone d'avertissement
// et garde son libelle « Alertes » pour le lecteur d'ecran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

bool _estIcone(Widget w, AppIcon icone) =>
    w is Icon && (w.icon == icone.repos || w.icon == icone.actif);

void main() {
  for (final String chemin in <String>[
    '/admin',
    '/admin/pedagogie/programmes',
    '/admin/operations',
  ]) {
    testWidgets('une seule cloche, alertes a part : $chemin', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      final SessionState session = sessionActive(AppRole.admin);
      final GoRouter routeur = await monterRouteur(
        tester,
        null,
        source: FausseSourceSession(session),
        taille: const Size(1440, 900),
        planFil: planFilPour(session),
        surcharges: <Override>[alertesUrgentesProvider.overrideWithValue(0)],
      );
      routeur.go(chemin);
      await stabiliser(tester);
      tester.takeException();
      expect(
        find.byWidgetPredicate(
          (Widget w) => _estIcone(w, AppIcons.notifications),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => _estIcone(w, AppIcons.avertissement),
        ),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(t.alertes.cloche), findsWidgets);
      semantique.dispose();
    });
  }
}
