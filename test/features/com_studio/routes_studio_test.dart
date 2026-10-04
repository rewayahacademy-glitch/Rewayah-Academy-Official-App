// COM-STU-1 et COM-STU-2 : les entrees reelles du Studio, sur le VRAI
// routeur et la vraie coquille admin (K-07) : « Le Studio » se tape depuis
// l'en-tete de l'`AdminShell` (1440) et depuis son tiroir (390, UX_REV-02),
// ouvre la coquille propre du Studio (jamais celle du tuteur) sur son
// accueil, Aujourd'hui (spec section 14), et un canal s'ouvre a son adresse
// `/admin/studio/canaux/:canalId`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/liste_canaux.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../router/support_routeur.dart';
import 'support_studio.dart';

/// La vraie application en demonstration admin, avec le port du Studio
/// donne (aucun serveur).
Future<GoRouter> _monterAdmin(
  WidgetTester tester,
  String depart, {
  PortStudio? port,
  PortActiviteStudio? activite,
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final PortStudio? studio = port;
  final PortActiviteStudio? activiteDonnee = activite;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        if (studio != null) portStudioProvider.overrideWithValue(studio),
        if (activiteDonnee != null)
          portActiviteStudioProvider.overrideWithValue(activiteDonnee),
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

String _adresse(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();

void main() {
  testWidgets('1440 : « Le Studio » de l en-tete ouvre la coquille du '
      'Studio, puis un canal a son adresse', (WidgetTester tester) async {
    final GoRouter routeur = await _monterAdmin(
      tester,
      Routes.admin,
      port: portDemo(),
    );
    await tester.tap(
      find.bySemanticsLabel(t.com.socle.navigation.ouvrirStudio),
    );
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.adminStudio);
    expect(find.byType(StudioPage), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
    expect(find.byType(CoquilleStudio), findsOneWidget);
    // La navigation du Studio, pas celle d'un role : Aujourd'hui, Canaux,
    // Elements enregistres, Brouillons (spec section 15), jamais Foyer.
    final NavShell nav = tester.widget<NavShell>(find.byType(NavShell));
    expect(nav.destinations.map((Destination d) => d.libelle), <String>[
      t.com.studio.navigation.aujourdhui,
      t.com.studio.navigation.canaux,
      t.com.studio.navigation.enregistres,
      t.com.studio.navigation.brouillons,
    ]);
    expect(nav.indexActif, VueStudio.aujourdhui.index);
    expect(find.text(t.nav.tuteur.foyer), findsNothing);
    // L'accueil du Studio est Aujourd'hui ; sans port d'activite branche
    // (production), il dit « pas encore disponible ».
    expect(find.byType(TableauAujourdhui), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(NavShell.barreLateraleKey),
        matching: find.text(t.com.studio.navigation.canaux),
      ),
    );
    await stabiliser(tester);
    expect(_adresse(routeur), adresseVueStudio(VueStudio.canaux));

    await tester.tap(find.text('Organisation générale'));
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.canalStudioPour('organisation'));
    expect(find.byType(CanalStudio), findsOneWidget);

    // La sortie ramene a l'Accueil admin, dans sa coquille.
    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.admin);
    expect(find.byType(AdminShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390 : « Le Studio » du tiroir admin ouvre la liste des '
      'canaux ; un canal, puis retour', (WidgetTester tester) async {
    final GoRouter routeur = await _monterAdmin(
      tester,
      Routes.admin,
      port: portDemo(),
      taille: const Size(390, 844),
    );
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await stabiliser(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.tiroirKey),
        matching: find.text(t.com.socle.navigation.studio),
      ),
    );
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.adminStudio);
    expect(find.byType(TableauAujourdhui), findsOneWidget);
    expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(NavShell.barreBasseKey),
        matching: find.text(t.com.studio.navigation.canaux),
      ),
    );
    await stabiliser(tester);
    expect(find.byType(ListeCanaux), findsOneWidget);

    await tester.tap(find.text('Admissions'));
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.canalStudioPour('admissions'));
    expect(find.byType(CanalStudio), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.adminStudio);
    expect(find.byType(ListeCanaux), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("1440 : une ligne dossier d'Aujourd'hui ouvre le VRAI module "
      'Dossiers, dans la coquille admin (R-COM-11)', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monterAdmin(
      tester,
      Routes.adminStudio,
      port: portDemo(),
      activite: ActiviteStudioDemo(maintenant: maintenantTest),
    );
    expect(find.byType(TableauAujourdhui), findsOneWidget);
    final Finder dossier = find.text(
      'Dossier de la famille Karim prêt pour une décision',
    );
    await tester.ensureVisible(dossier);
    await stabiliser(tester);
    await tester.tap(dossier);
    await stabiliser(tester);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(DossiersPage), findsOneWidget);
    expect(
      tester.widget<DossiersPage>(find.byType(DossiersPage)).profilId,
      'profil-karim',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans port branche (production) : le Studio dit « pas encore '
      'disponible », sans Reessayer ni canal invente', (
    WidgetTester tester,
  ) async {
    await _monterAdmin(tester, Routes.adminStudio);
    expect(find.byType(StudioPage), findsOneWidget);
    expect(
      find.text(t.com.socle.composants.etats.indisponibleTitre),
      findsOneWidget,
    );
    expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
    expect(find.byType(ListeCanaux), findsNothing);
  });

  testWidgets('/admin/studio/canaux (ancien lien) ouvre la liste des '
      "canaux, jamais Aujourd'hui", (WidgetTester tester) async {
    final GoRouter routeur = await _monterAdmin(
      tester,
      Routes.adminStudioCanaux,
      port: portDemo(),
    );
    expect(_adresse(routeur), adresseVueStudio(VueStudio.canaux));
    expect(find.byType(ListeCanaux), findsOneWidget);
    expect(find.byType(TableauAujourdhui), findsNothing);
    expect(
      tester.widget<NavShell>(find.byType(NavShell)).indexActif,
      VueStudio.canaux.index,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Elements enregistres : une vue du Studio a son adresse', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monterAdmin(
      tester,
      Routes.adminStudio,
      port: portDemo(),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(NavShell.barreLateraleKey),
        matching: find.text(t.com.studio.navigation.enregistres),
      ),
    );
    await stabiliser(tester);
    expect(
      routeur.routerDelegate.currentConfiguration.uri.toString(),
      adresseVueStudio(VueStudio.enregistres),
    );
    expect(
      tester.widget<NavShell>(find.byType(NavShell)).indexActif,
      VueStudio.enregistres.index,
    );
    expect(tester.takeException(), isNull);
  });
}
