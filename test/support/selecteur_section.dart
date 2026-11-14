import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
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
///
/// NAV-SOUS-LIENS (14/11/2026) : sur tablette et ordinateur, la page de la
/// direction ne montre plus son selecteur quand le panneau porte deja ses
/// sections ; la section se choisit alors par son sous-lien du panneau.
Future<void> choisirSection(WidgetTester tester, String libelle) async {
  if (sectionVisible(libelle).evaluate().isEmpty) {
    final Finder barre = find.byKey(AdminShell.barreLateraleKey);
    final Finder sousLien = find.descendant(
      of: barre,
      matching: find.text(libelle),
    );
    // Le panneau deplie defile et ne construit que ses entrees visibles (a
    // 200 %) : on le fait defiler comme un utilisateur.
    if (sousLien.hitTestable().evaluate().isEmpty &&
        barre.evaluate().isNotEmpty) {
      final Finder defilant = find.descendant(
        of: barre,
        matching: find.byType(Scrollable),
      );
      if (defilant.evaluate().isNotEmpty) {
        try {
          await tester.scrollUntilVisible(
            sousLien.hitTestable(),
            48,
            scrollable: defilant.first,
            maxScrolls: 40,
          );
        } on StateError {
          // Pas dans le panneau : la page garde son selecteur.
        }
      }
    }
    if (sousLien.evaluate().isNotEmpty) {
      await tester.ensureVisible(sousLien.first);
      await tester.tap(sousLien.first);
      await tester.pumpAndSettle();
      return;
    }
  }
  // Rail replie : la section est dans le menu des pages d'un domaine.
  final Finder rail = find.byKey(AdminShell.railKey);
  if (sectionVisible(libelle).evaluate().isEmpty &&
      selecteurSection.evaluate().isEmpty &&
      rail.evaluate().isNotEmpty) {
    final Finder declencheurs = find.descendant(
      of: rail,
      matching: find.byType(MenuActions),
    );
    for (int i = 0; i < declencheurs.evaluate().length; i++) {
      await tester.tap(declencheurs.at(i));
      await tester.pumpAndSettle();
      final Finder entree = find.descendant(
        of: find.byType(PopupMenuItem<int>),
        matching: find.text(libelle),
      );
      if (entree.evaluate().isNotEmpty) {
        await tester.tap(entree.first);
        await tester.pumpAndSettle();
        return;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }
  }
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
