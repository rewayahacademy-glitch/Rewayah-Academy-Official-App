import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';

/// Hors ligne se dit une seule fois (EA-HL-DOUBLE-1, decision du 04/10
/// deleguee par le directeur, K-42) : le bandeau de `PageShell` est LE
/// signal ; aucun autre texte affiche ne redit « hors ligne », « pas de
/// reseau » ni « pas de connexion ».

/// Ce qui dit l'absence de reseau, sous toutes les formes rencontrees dans le
/// catalogue (revue EA-HL-DOUBLE-1 : « Sans reseau », « Connexion
/// interrompue » passaient au travers). Partage avec la garde du catalogue
/// (`test/core/reseau/etat_sans_donnees_test.dart`).
final RegExp motifHorsLigne = RegExp(
  r'hors ligne|hors-ligne|pas de réseau|sans réseau|pas de connexion|'
  r'sans connexion|connexion (est |a été )?(interrompue|perdue|coupée)|'
  r'réseau (est |a été )?(coupé|perdu)|vous êtes déconnecté',
  caseSensitive: false,
);

bool _ditHorsLigne(String texte) => motifHorsLigne.hasMatch(texte);

/// Les textes affiches qui disent l'absence de reseau, bandeau compris.
Finder signauxHorsLigne() => find.byWidgetPredicate(
  (Widget w) =>
      w is Text && _ditHorsLigne(w.data ?? w.textSpan?.toPlainText() ?? ''),
  description: 'texte qui dit « hors ligne »',
);

/// Les icones « wifi barre » affichees, celle du bandeau comprise : une
/// seconde icone a cote du bandeau est un second signal (revue
/// EA-HL-DOUBLE-1, m3).
Finder iconesHorsLigne() => find.byWidgetPredicate(
  (Widget w) =>
      w is Icon && w.icon?.codePoint == AppIcons.horsLigne.repos.codePoint,
  description: 'icone « hors ligne »',
);

/// Le bandeau, et lui seul, dit l'absence de reseau, en mots comme en
/// icone. [bandeau] faux : le widget est monte seul, sans `PageShell`, et
/// rien ne le dit.
void expectHorsLigneUneFois({bool bandeau = true}) {
  expect(
    find.text(t.reseau.horsLigne),
    bandeau ? findsOneWidget : findsNothing,
  );
  expect(signauxHorsLigne(), bandeau ? findsOneWidget : findsNothing);
  expect(iconesHorsLigne(), bandeau ? findsOneWidget : findsNothing);
}

/// Le bloc « rien a afficher » dit [quoi], et rien d'autre ne le double.
void expectSansDonnees(String quoi, {bool bandeau = true}) {
  expectHorsLigneUneFois(bandeau: bandeau);
  expect(find.byType(EtatSansDonnees), findsOneWidget);
  expect(find.text(quoi), findsOneWidget);
}

/// Hors ligne avec donnees : le bandeau seul, aucun bloc, aucun echec.
void expectAvecDonnees() {
  expectHorsLigneUneFois();
  expect(find.byType(EtatSansDonnees), findsNothing);
  expect(
    find.byWidgetPredicate(
      (Widget w) => w is EtatSysteme && w.nature == NatureEtat.echecServeur,
    ),
    findsNothing,
  );
}
