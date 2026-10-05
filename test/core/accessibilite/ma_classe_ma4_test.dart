// MA-4 : Ma classe avant la seance, en Mode Accessibilite. On ouvre la VRAIE
// route de demonstration /demo/accessibilite, qui arrive sur Ma classe dans
// la vraie coquille : titre « Ma classe » (plus « Mes classes »), identite en
// pile (photo au-dessus, nom en dessous), une seule ligne d'etat avant
// l'ouverture (aucun « Rejoindre »), tutoiement selon l'age ; puis on tape
// l'action de la page (« Mon suivi ») : le Suivi reste atteignable.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/photo_enseignant.dart';

import '../../router/support_routeur.dart' show stabiliser;

Future<void> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  EleveDemoAccessibilite eleve = EleveDemoAccessibilite.mariam,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoAccessibilite(eleve),
    routes: routesDemoAccessibilite('local'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp.router(
            routerConfig: routeur,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

/// La photo est au-dessus du nom de la Classe : l'identite est en pile.
void _attendrePile(WidgetTester tester) {
  final Finder identite = find.byType(IdentiteGroupe);
  expect(identite, findsOneWidget);
  // Cote famille, la photo ou ses initiales en repli (`AvatarTile`).
  final Finder photo = find.descendant(
    of: identite,
    matching: find.byWidgetPredicate(
      (Widget w) => w is PhotoEnseignant || w is AvatarTile,
    ),
  );
  final Finder nom = find.descendant(
    of: identite,
    // En pile, le nom s'affiche avec un trait d'union insecable (U+2011).
    matching: find.text(DonneesAccessibiliteDemo.classe.replaceAll('-', '‑')),
  );
  expect(
    tester.getBottomLeft(photo).dy,
    lessThanOrEqualTo(tester.getTopLeft(nom).dy),
  );
}

void main() {
  for (final double echelle in <double>[1, 2]) {
    testWidgets(
      'route de demonstration, texte x$echelle : Ma classe, titre aligne, '
      'identite en pile, une seule ligne d\'etat, puis Mon suivi',
      (WidgetTester tester) async {
        await _monter(
          tester,
          taille: Size(390, echelle == 1 ? 1900 : 3600),
          echelle: echelle,
        );

        // Le titre de la page est celui de l'onglet.
        expect(
          find.descendant(
            of: find.byType(NavShell),
            matching: find.text(t.accessibilite.maClasse.titre),
          ),
          findsNWidgets(2),
        );
        expect(find.text(LibellesGroupe.retour), findsNothing);

        _attendrePile(tester);

        // Avant l'ouverture : pas de bouton d'entree (R4, MA19).
        expect(find.text(LibellesGroupe.rejoindre), findsNothing);
        // Tutoiement de l'eleve mineure (MA4).
        expect(find.text(t.accessibilite.tutoiement.tonHeure), findsWidgets);

        // L'action de la page : le Suivi reste atteignable.
        final Finder suivi = find.text(t.accessibilite.maClasse.suivi);
        await tester.ensureVisible(suivi);
        await tester.pumpAndSettle();
        await tester.tap(suivi);
        await stabiliser(tester);
        expect(
          find.byKey(const ValueKey<String>('demo-suivi')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Idriss, adulte : vouvoye sur Ma classe', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      taille: const Size(390, 1900),
      eleve: EleveDemoAccessibilite.idriss,
    );
    expect(find.text(t.accessibilite.tutoiement.tonHeure), findsNothing);
    _attendrePile(tester);
  });

  testWidgets('hors Mode Accessibilite a 100 % : identite en ligne '
      '(rendu des autres roles inchange)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Scaffold(
              body: IdentiteGroupe(
                groupe: DonneesAccessibiliteDemo.espaceAccueil(
                  MomentDemoAccessibilite.avant,
                ).identite,
              ),
            ),
          ),
        ),
      ),
    );
    // AVATAR-1 : la photo est a cote du nom de l'enseignant (couple partage
    // `AvatarNom`), qui est centre verticalement sur le cercle ; le titre de la
    // Classe, le cours et le niveau sont au-dessus.
    final Finder photo = find.byType(PhotoEnseignant);
    final Finder couple = find.byType(AvatarNom);
    expect(couple, findsOneWidget);
    final Finder nomEnseignant = find
        .descendant(of: couple, matching: find.byType(Text))
        .first;
    expect(
      tester.getTopRight(photo).dx,
      lessThan(tester.getTopLeft(nomEnseignant).dx),
    );
    expect(
      (tester.getRect(photo).center.dy -
              tester.getRect(nomEnseignant).center.dy)
          .abs(),
      lessThanOrEqualTo(2),
    );
    expect(
      tester.getTopLeft(find.text(DonneesAccessibiliteDemo.classe)).dy,
      lessThan(tester.getTopLeft(photo).dy),
    );
  });
}
