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
import 'package:rewayah_academy/core/widgets/status_pill.dart';
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

    // Contrat D a 1440 : barre 288 + padding 32 -> file a x=320, large de
    // 336 ; ecart 24 -> detail a x=680, large de 728 ; rien en pleine largeur.
    final Finder fileZone = find.byKey(
      const PageStorageKey<String>('adm02a-file'),
    );
    final Finder detailZone = find.byKey(
      const ValueKey<String?>(DonneesDossiersDemo.enseignantNominal),
    );
    expect(tester.getSize(fileZone).width, largeurFileDossiers);
    expect(tester.getTopLeft(fileZone).dx, 320);
    expect(tester.getTopLeft(detailZone).dx, 320 + 336 + ecartFileDetail);
    expect(tester.getSize(detailZone).width, largeurDetailDossier);

    // Taper la 2e ligne : la selection et le detail suivent.
    await tester.tap(_ligne('Amina'));
    await _stabiliser(tester);
    expect(tester.getSemantics(_ligne('Amina')), isSemantics(isSelected: true));
    // AD-6 : le detail porte le titre ; nom et prenom sont sur leurs lignes.
    expect(find.text('Amina Benali'), findsOneWidget);
    expect(find.text("Dossier d'Amina Benali"), findsOneWidget);
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
    // Valider reste ferme (non rendu, HL-A-5) : aucune coche n'a survecu.
    expect(find.text(t.dossiers.approuver), findsNothing);
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
    // AD-8 : 02E, puis la confirmation.
    await tester.tap(find.text(t.dossiers.approuver).last);
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

    // Le disque « Retour » de l'en-tete rend le focus a la ligne ouverte.
    await tester.tap(_ligne('Amina'));
    await _stabiliser(tester);
    await tester.tap(find.bySemanticsLabel(t.commun.entete.retour));
    await _stabiliser(tester);
    expect(_ligne('Amina'), findsOneWidget);
    _focusSur(tester, _ligne('Amina'));
  });

  testWidgets('390 : apres une decision, le focus va a la ligne suivante', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, const Size(390, 844), etat: etat);
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.tiroirKey),
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
    await _stabiliser(tester);
    await tester.tap(_ligne('Omar'));
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
    // AD-8 : 02E, puis la confirmation.
    await tester.tap(find.text(t.dossiers.approuver).last);
    await _stabiliser(tester);
    expect(_ligne('Omar'), findsNothing);
    expect(find.text(t.dossiers.verifications), findsNothing);
    _focusSur(tester, _ligne('Amina'));
  });

  for (final (String nom, Size taille, double texte)
      in <(String, Size, double)>[
        ('768', const Size(768, 1024), 1),
        ('1200', const Size(1200, 900), 1),
        // HL-A-1 : la barre laterale ne deborde plus a 200 %.
        ('1440 a 200 %', const Size(1440, 900), 2),
      ]) {
    testWidgets('$nom : repli sequentiel, ni revue ni selection', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = texte;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monter(tester, taille);
      routeurDe(tester).go(Routes.adminPersonnesDossiers);
      await _stabiliser(tester);
      expect(_ligne('Omar'), findsOneWidget);
      expect(find.text(t.dossiers.verifications), findsNothing);
      expect(find.text(t.dossiers.file.aucuneSelection), findsNothing);
      expect(
        tester.getSemantics(_ligne('Omar')),
        isNot(isSemantics(isSelected: true)),
      );
    });
  }

  testWidgets('1440 a 200 % : Personnes tape dans la barre laterale, repli', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final GoRouter routeur = await _monter(tester, const Size(1440, 900));
    // Aucun debordement de la coque (une erreur de rendu ferait echouer).
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.descendant(
        of: find.byKey(AdminShell.barreLateraleKey),
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
    await _stabiliser(tester);
    expect(tester.takeException(), isNull);
    expect(_chemin(routeur), Routes.adminPersonnesDossiers);
    expect(_ligne('Omar'), findsOneWidget);
    expect(find.text(t.dossiers.verifications), findsNothing);
  });

  for (final (String nom, Size taille) in <(String, Size)>[
    ('390', const Size(390, 844)),
    ('1440', const Size(1440, 900)),
  ]) {
    testWidgets('$nom : pastille au meme endroit sur toutes les lignes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille);
      await _ouvrirDossiers(tester);
      final Finder pastilles = find.descendant(
        of: find.byKey(const PageStorageKey<String>('adm02a-file')),
        matching: find.byType(StatusPill),
      );
      expect(pastilles, findsWidgets);
      final Set<double> debuts = <double>{
        for (final Element e in pastilles.evaluate())
          tester.getTopLeft(find.byWidget(e.widget)).dx.roundToDouble(),
      };
      final Set<double> fins = <double>{
        for (final Element e in pastilles.evaluate())
          tester.getTopRight(find.byWidget(e.widget)).dx.roundToDouble(),
      };
      // Sous le nom partout (debuts alignes) ou a cote partout (fins
      // alignees au bord de fin) : jamais un melange.
      expect(debuts.length == 1 || fins.length == 1, isTrue);
      if (nom == '1440') {
        // 336 ne suffit pas au nom et a sa pastille : dessous, partout.
        expect(debuts, hasLength(1));
        final Rect nomOmar = tester.getRect(
          find.descendant(
            of: find.byKey(const PageStorageKey<String>('adm02a-file')),
            matching: find.text('Omar Haddad'),
          ),
        );
        final Rect pastilleOmar = tester.getRect(pastilles.first);
        expect(pastilleOmar.top, greaterThanOrEqualTo(nomOmar.bottom));
      }
    });
  }

  testWidgets('390 : « Pièce hors de votre portée » sur la ligne', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(390, 844));
    await _ouvrirDossiers(tester);
    final Finder ligne = _ligne('Adam');
    await tester.ensureVisible(ligne);
    await _stabiliser(tester);
    final Finder pastille = find.text(t.dossiers.pieceNonVisible);
    expect(pastille, findsOneWidget);
    expect(tester.getRect(ligne).contains(tester.getCenter(pastille)), isTrue);
    // Les autres lignes gardent leur pastille propre.
    expect(find.text(t.dossiers.file.enVerification), findsWidgets);
  });

  testWidgets('390 : la decision qui vide la file rend le focus au titre', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    for (final String id in etat.dossiers.keys) {
      if (id != DonneesDossiersDemo.enseignantNominal) {
        etat.dossiers[id]!.statut = StatutRevue.valide;
      }
    }
    await _monter(tester, const Size(390, 844), etat: etat);
    await _ouvrirDossiers(tester);
    await tester.tap(_ligne('Omar'));
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
    // AD-8 : 02E, puis la confirmation.
    await tester.tap(find.text(t.dossiers.approuver).last);
    await _stabiliser(tester);
    expect(_ligne('Omar'), findsNothing);
    expect(find.text(t.dossiers.aucun), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'adm02a-titre');
  });

  // AD-FOCUS-MD (VERIF-AD-2 LOT-1) : sans dossier suivant, le focus ne se
  // perd plus (il restait sur le Focus Scope, aucun element) : il va au
  // titre, a 390 comme a 1440, file videe ou dernier d'une file non vide.
  for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
    for (final bool fileVidee in <bool>[true, false]) {
      final String cas = fileVidee ? 'file videe' : 'dernier, file non vide';
      testWidgets('${taille.width.toInt()} : $cas, le focus va au titre', (
        WidgetTester tester,
      ) async {
        // Omar (le plus ancien) puis Amina : decider Amina laisse Omar.
        final Set<String> gardes = <String>{
          DonneesDossiersDemo.enseignantDocumentaire,
          if (!fileVidee) DonneesDossiersDemo.enseignantNominal,
        };
        final EtatRevueDemo etat = EtatRevueDemo.initial();
        for (final String id in etat.dossiers.keys) {
          if (!gardes.contains(id)) {
            etat.dossiers[id]!.statut = StatutRevue.valide;
          }
        }
        await _monter(tester, taille, etat: etat);
        await _ouvrirDossiers(tester);
        await tester.tap(_ligne('Amina'));
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
        await tester.tap(find.text(t.dossiers.approuver).last);
        await _stabiliser(tester);
        expect(_ligne('Amina'), findsNothing);
        expect(_ligne('Omar'), fileVidee ? findsNothing : findsOneWidget);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'adm02a-titre');
      });
    }
  }
}

/// Ouvre Personnes > Dossiers depuis la coque, comme l'administrateur : le
/// tiroir sur mobile, la barre laterale sur bureau.
Future<void> _ouvrirDossiers(WidgetTester tester) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  if (barre.evaluate().isEmpty) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  await tester.tap(
    find.descendant(
      of: barre.evaluate().isEmpty ? find.byKey(AdminShell.tiroirKey) : barre,
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
}

GoRouter routeurDe(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
        .read(routeurProvider);

/// Le focus primaire tombe dans la ligne [ligne].
void _focusSur(WidgetTester tester, Finder ligne) {
  final FocusNode? focus = FocusManager.instance.primaryFocus;
  expect(focus, isNotNull);
  expect(tester.getRect(ligne).contains(focus!.rect.center), isTrue);
}
