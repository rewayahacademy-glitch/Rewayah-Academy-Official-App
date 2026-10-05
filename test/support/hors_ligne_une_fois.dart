import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';

/// Hors ligne se dit une seule fois (EA-HL-DOUBLE-1, decision du 04/10
/// deleguee par le directeur, K-42) : le bandeau de `PageShell` est LE
/// signal ; aucun autre texte affiche ne redit « hors ligne », « pas de
/// reseau » ni « pas de connexion ».

bool _ditHorsLigne(String texte) {
  final String bas = texte.toLowerCase();
  return bas.contains('hors ligne') ||
      bas.contains('pas de réseau') ||
      bas.contains('pas de connexion');
}

/// Les textes affiches qui disent l'absence de reseau, bandeau compris.
Finder signauxHorsLigne() => find.byWidgetPredicate(
  (Widget w) =>
      w is Text && _ditHorsLigne(w.data ?? w.textSpan?.toPlainText() ?? ''),
  description: 'texte qui dit « hors ligne »',
);

/// Le bandeau, et lui seul, dit l'absence de reseau. [bandeau] faux : le
/// widget est monte seul, sans `PageShell`, et rien ne le dit.
void expectHorsLigneUneFois({bool bandeau = true}) {
  expect(
    find.text(t.reseau.horsLigne),
    bandeau ? findsOneWidget : findsNothing,
  );
  expect(signauxHorsLigne(), bandeau ? findsOneWidget : findsNothing);
}

/// Le bloc « rien a afficher » dit [quoi], et rien d'autre ne le double.
void expectSansDonnees(String quoi, {bool bandeau = true}) {
  expectHorsLigneUneFois(bandeau: bandeau);
  expect(find.byType(EtatSansDonnees), findsOneWidget);
  expect(find.text(quoi), findsOneWidget);
}

/// Hors ligne avec donnees : le bandeau seul, aucun bloc.
void expectAvecDonnees() {
  expectHorsLigneUneFois();
  expect(find.byType(EtatSansDonnees), findsNothing);
}
