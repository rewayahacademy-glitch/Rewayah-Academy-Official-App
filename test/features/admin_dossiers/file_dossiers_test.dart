// AD-5 : la file ADM-02A sur la VRAIE coque admin et le vrai routeur, en
// demonstration (`?demo=admin`). Chaque geste part d'un bouton reel (K-07).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _monter(
  WidgetTester tester,
  Size taille, {
  EtatRevueDemo? etat,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging', etat: etat),
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
  routeur.go(Routes.admin);
  await _stabiliser(tester);
  return routeur;
}

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

/// Amene un libelle a l'ecran puis le tape, comme l'administrateur.
Future<void> _taperTexte(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle));
  await _stabiliser(tester);
  await tester.tap(find.text(libelle));
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('1440 : Personnes, maitre-detail 336/24/728, selection', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, const Size(1440, 900));
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.barreLateraleKey),
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);

    // La 1re ligne est selectionnee automatiquement, sans prendre le focus.
    final Finder premiere = _ligne('Omar');
    expect(tester.getSemantics(premiere), isSemantics(isSelected: true));
    // Deux panneaux : aucun « Selectionnez... », le detail du premier.
    expect(find.text(t.dossiers.file.aucuneSelection), findsNothing);
    expect(find.text(t.dossiers.verifications), findsOneWidget);

    // Largeurs du contrat D : file 336, detail 728.
    expect(
      tester
          .getSize(find.byKey(const PageStorageKey<String>('adm02a-file')))
          .width,
      largeurFileDossiers,
    );

    // Taper la 2e ligne : la selection et le detail suivent.
    await tester.tap(_ligne('Amina'));
    await _stabiliser(tester);
    expect(tester.getSemantics(_ligne('Amina')), isSemantics(isSelected: true));
    expect(find.text('Amina Benali'), findsNWidgets(2));
  });

  testWidgets('1440 : les coches repartent a vide en changeant de dossier', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.barreLateraleKey),
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
    await _stabiliser(tester);
    await _taperTexte(tester, t.dossiers.pointLisible);
    await _stabiliser(tester);
    await tester.tap(_ligne('Amina'));
    await _stabiliser(tester);
    await tester.tap(_ligne('Omar'));
    await _stabiliser(tester);
    // Valider reste ferme : aucune coche n'a survecu au changement.
    expect(find.text(t.dossiers.approuver), findsOneWidget);
  });

  testWidgets('1440 : valider passe au dossier suivant', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, const Size(1440, 900), etat: etat);
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.barreLateraleKey),
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
    await _stabiliser(tester);
    for (final String point in <String>[
      t.dossiers.pointLisible,
      t.dossiers.pointNom,
      t.dossiers.pointValidite,
    ]) {
      await _taperTexte(tester, point);
      await _stabiliser(tester);
    }
    await tester.ensureVisible(find.text(t.dossiers.approuver));
    await tester.tap(find.text(t.dossiers.approuver));
    await _stabiliser(tester);
    expect(
      etat.dossiers[DonneesDossiersDemo.enseignantNominal]!.statut,
      StatutRevue.valide,
    );
    expect(_ligne('Omar'), findsNothing);
    expect(tester.getSemantics(_ligne('Amina')), isSemantics(isSelected: true));
  });

  testWidgets('390 : tiroir, liste seule, detail puis Retour vers la liste', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, const Size(390, 844));
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.tiroirKey),
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
    await _stabiliser(tester);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);

    // Liste seule : aucune revue, aucune ligne annoncee selectionnee.
    expect(find.text(t.dossiers.verifications), findsNothing);
    expect(_ligne('Omar'), findsOneWidget);

    await tester.tap(_ligne('Amina'));
    await _stabiliser(tester);
    expect(find.text('Dossier d’Amina Benali'), findsNothing);
    expect(find.text("Dossier d'Amina Benali"), findsOneWidget);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);

    // Retour systeme : la liste revient, la route ne change pas.
    await tester.binding.handlePopRoute();
    await _stabiliser(tester);
    expect(find.text(t.dossiers.titre), findsWidgets);
    expect(_ligne('Amina'), findsOneWidget);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);
  });
}
