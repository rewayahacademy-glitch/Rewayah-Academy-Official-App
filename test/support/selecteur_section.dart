import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';

/// Les helpers de test de `SelecteurSection` (ONGLETS-1).
///
/// Le composant rend un controle segmente ou un menu selon la largeur : un
/// test qui change de section ne doit pas dependre de ce choix. Les finders
/// ne dependent pas du type de la valeur (`int`, enum...).

/// Le selecteur de section, quel que soit le type de ses valeurs.
final Finder selecteurSection = find.byWidgetPredicate(
  (Widget w) => w is SelecteurSection,
);

/// Le libelle de la section est visible dans le selecteur (segment, ou section
/// courante du menu ferme).
Finder sectionVisible(String libelle) =>
    find.descendant(of: selecteurSection, matching: find.text(libelle));

/// Choisit la section [libelle] : touche le segment, ou ouvre le menu puis
/// touche l'entree.
Future<void> choisirSection(WidgetTester tester, String libelle) async {
  final Finder segment = sectionVisible(libelle);
  final Finder menu = find.descendant(
    of: selecteurSection,
    matching: find.byWidgetPredicate((Widget w) => w is MenuFiltre),
  );
  if (menu.evaluate().isEmpty) {
    await tester.ensureVisible(segment.first);
    await tester.tap(segment.first);
    await tester.pump();
    return;
  }
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle).last);
  await tester.pumpAndSettle();
}
