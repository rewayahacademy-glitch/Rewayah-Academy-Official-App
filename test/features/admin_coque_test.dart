// AD-S : la coque admin sur le VRAI routeur et la vraie application, comme
// `main.dart` la monte en demonstration (`?demo=admin`) : chaque bouton est
// tape depuis la coquille reelle (K-07, K-13).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(
  WidgetTester tester,
  Size taille,
  String depart,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging'),
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await _stabiliser(tester);
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

Finder _dans(Key cle, Finder cible) =>
    find.descendant(of: find.byKey(cle), matching: cible);

void main() {
  testWidgets('1440 : chaque entree de la barre 288 mene a sa route', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(1440, 900),
      Routes.admin,
    );
    expect(
      tester.getSize(find.byKey(AdminShell.barreLateraleKey)).width,
      AdminShell.largeurBarreLaterale,
    );

    final List<AdminDomaine> domaines = domainesAdmin(voitDirection: false);
    for (int i = 0; i < domaines.length; i++) {
      final AdminDomaine domaine = domaines[i];
      final String avant = _chemin(routeur);
      await tester.tap(
        _dans(AdminShell.barreLateraleKey, find.text(domaine.libelle)),
      );
      await _stabiliser(tester);
      final String? cible = domaine.chemin;
      if (cible == null) {
        // Finance : inerte, la route ne bouge pas.
        expect(_chemin(routeur), avant, reason: domaine.name);
        continue;
      }
      expect(_chemin(routeur), startsWith(cible), reason: domaine.name);
      final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
        _dans(AdminShell.barreLateraleKey, find.byType(NavigationDrawer)),
      );
      expect(tiroir.selectedIndex, i, reason: domaine.name);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('768 : le rail 80 mene a Personnes puis a l Accueil', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(768, 1024),
      Routes.admin,
    );
    expect(tester.getSize(find.byKey(AdminShell.railKey)).width, 80);

    await tester.tap(
      _dans(AdminShell.railKey, find.text(AdminDomaine.personnes.libelle)),
    );
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);

    await tester.tap(
      _dans(AdminShell.railKey, find.text(AdminDomaine.accueil.libelle)),
    );
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.admin);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 : Menu ouvre le tiroir, Personnes y mene', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(390, 844),
      Routes.admin,
    );
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
    expect(find.byKey(AdminShell.tiroirKey), findsOneWidget);

    await tester.tap(
      _dans(AdminShell.tiroirKey, find.text(AdminDomaine.personnes.libelle)),
    );
    await _stabiliser(tester);
    expect(find.byKey(AdminShell.tiroirKey), findsNothing);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1440 : la bascule de l en-tete change le theme', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900), Routes.admin);

    await tester.tap(find.bySemanticsLabel(t.commun.theme.sombre));
    await _stabiliser(tester);
    expect(
      Theme.of(tester.element(find.byType(AdminShell))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.bySemanticsLabel(t.commun.theme.clair));
    await _stabiliser(tester);
    expect(
      Theme.of(tester.element(find.byType(AdminShell))).brightness,
      Brightness.light,
    );
  });

  for (final Size taille in <Size>[
    const Size(1440, 900),
    const Size(390, 844),
  ]) {
    testWidgets('${taille.width.toInt()} : Mon compte, sous le repere '
        'Demonstration, mene a la deconnexion', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, taille, Routes.admin);
      expect(find.bySemanticsLabel('Mode Démonstration'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(t.nav.compte));
      await _stabiliser(tester);
      expect(_chemin(routeur), Routes.compte);
      final Finder sortie = find.text(t.compte.deconnexion);
      await tester.scrollUntilVisible(
        sortie,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(sortie, findsOneWidget);
    });
  }

  testWidgets('1440 : le pied de la barre 288 mene a Mon compte', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(1440, 900),
      Routes.admin,
    );
    await tester.tap(
      _dans(AdminShell.barreLateraleKey, find.text(t.compte.roles.admin)),
    );
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.compte);
  });

  testWidgets('Retour : present hors Accueil, mene a /admin', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(1440, 900),
      Routes.admin,
    );
    expect(find.byType(DisqueRetour), findsNothing);

    routeur.go(Routes.adminPersonnesDossiers);
    await _stabiliser(tester);
    await tester.tap(find.byType(DisqueRetour));
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.admin);
  });

  testWidgets('Personnes : titre, sous-titre et onglet Comptes', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      const Size(1440, 900),
      Routes.adminPersonnesDossiers,
    );
    expect(find.text(t.dossiers.sousTitre), findsOneWidget);

    await tester.tap(find.text(t.admin.comptes.titre).first);
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminPersonnesComptes);
    final List<AdminDomaine> domaines = domainesAdmin(voitDirection: false);
    final NavigationDrawer tiroir = tester.widget<NavigationDrawer>(
      _dans(AdminShell.barreLateraleKey, find.byType(NavigationDrawer)),
    );
    expect(tiroir.selectedIndex, domaines.indexOf(AdminDomaine.personnes));
  });

  testWidgets('Accueil : la 2e ligne de dossier ouvre ce dossier-la', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900), Routes.admin);
    final Finder lignes = find.textContaining(
      t.admin.tableau.ligneDossier(prenom: '').trim(),
    );
    expect(lignes, findsAtLeastNWidgets(2));
    final String libelle = tester.widget<Text>(lignes.at(1)).data!;
    final String prenom = libelle
        .replaceFirst(t.admin.tableau.ligneDossier(prenom: '').trim(), '')
        .trim();

    await tester.ensureVisible(lignes.at(1));
    await tester.tap(lignes.at(1));
    await _stabiliser(tester);

    expect(find.textContaining(prenom), findsWidgets);
  });
}
