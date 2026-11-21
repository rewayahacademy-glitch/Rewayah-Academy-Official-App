import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
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
///
/// NAV-SOUS-LIENS (14/11/2026) : sur tablette et ordinateur, les sections
/// d'une page de la direction sont les sous-liens du panneau ; elles y
/// comptent comme visibles.
Finder sectionVisible(String libelle) => find.byElementPredicate((Element e) {
  final Widget w = e.widget;
  if (w is! Text || w.data != libelle) return false;
  bool trouve = false;
  e.visitAncestorElements((Element a) {
    if (a.widget is SelecteurSection ||
        a.widget.key == AdminShell.barreLateraleKey) {
      trouve = true;
      return false;
    }
    return true;
  });
  return trouve;
});

/// Le libelle dans le selecteur de la page seulement.
Finder _dansSelecteur(String libelle) =>
    find.descendant(of: selecteurSection, matching: find.text(libelle));

/// Choisit la section [libelle] : touche le segment, ou ouvre le menu puis
/// touche l'entree.
///
/// NAV-SOUS-LIENS (14/11/2026) : sur tablette et ordinateur, la page de la
/// direction ne montre plus son selecteur quand le panneau porte deja ses
/// sections ; la section se choisit alors par son sous-lien du panneau.
Future<void> choisirSection(WidgetTester tester, String libelle) async {
  if (_dansSelecteur(libelle).evaluate().isEmpty) {
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
  if (_dansSelecteur(libelle).evaluate().isEmpty &&
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
  // PERSONNES-UNE-PAGE (b) : « Personnes » ouvre la page unique ; ses
  // anciennes pages se choisissent dans son menu « Autres pages ».
  final Finder autresPages = find.byKey(
    const ValueKey<String>('personnes-autres-pages'),
  );
  if (_dansSelecteur(libelle).evaluate().isEmpty &&
      autresPages.evaluate().isNotEmpty) {
    await tester.ensureVisible(autresPages);
    await tester.tap(autresPages);
    await tester.pumpAndSettle();
    // PERSONNES-UNE-PAGE (e) : les anciennes listes s'y nomment
    // « Liste d'avant : … ».
    final Finder avant = find.text(
      t.admin.personnesPage.listeDAvant(nom: libelle),
    );
    final Finder entree = avant.evaluate().isNotEmpty
        ? avant.last
        : find.text(libelle).last;
    // Texte agrandi : le menu defile, l'entree se fait d'abord voir.
    await tester.ensureVisible(entree);
    await tester.pumpAndSettle();
    await tester.tap(entree);
    await tester.pumpAndSettle();
    return;
  }
  final Finder segment = _dansSelecteur(libelle);
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
