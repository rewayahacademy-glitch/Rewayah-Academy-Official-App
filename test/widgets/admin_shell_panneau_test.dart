// NAV-REFONTE etape 4, part sans decision ouverte (feu vert du pilote du
// 11/11/2026) : la colonne de la direction recoit le bouton fixe du panneau
// (a partir de 1200), le compte au pied (photo, nom, menu) et garde ses huit
// domaines.
//
// NAV-SOUS-LIENS (14/11/2026, regle 19 des consignes du directeur) : les
// points en attente sont tranches. Sous 1200, le bouton du rail ouvre le
// panneau PAR-DESSUS la page, avec un voile ; le panneau a trois sections
// et montre les pages du domaine ouvert ; le rail les ouvre en menu ; la
// page ne repete pas sa sous-navigation quand le panneau la porte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';

import '../support/aucun_mot_coupe.dart';

Future<({ProviderContainer conteneur, List<String> journal})> _monter(
  WidgetTester tester, {
  required Size taille,
  TextDirection sens = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
  AdminDomaine domaineActif = AdminDomaine.accueil,
  Map<AdminDomaine, List<SousLien>> sousLiens =
      const <AdminDomaine, List<SousLien>>{},
  String? cheminCourant,
  Widget page = const PageShell(child: SizedBox()),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ProviderContainer conteneur = ProviderContainer();
  addTearDown(conteneur.dispose);
  final List<String> journal = <String>[];
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: conteneur,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: theme,
          builder: (BuildContext contexte, Widget? enfant) => Directionality(
            textDirection: sens,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: enfant!,
            ),
          ),
          home: AdminShell(
            domaines: domainesAdmin(voitDirection: true),
            domaineActif: domaineActif,
            onAller: journal.add,
            onCompte: () => journal.add('compte'),
            onDeconnexion: () => journal.add('sortie'),
            sousLiens: sousLiens,
            cheminCourant: cheminCourant,
            child: page,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (conteneur: conteneur, journal: journal);
}

Finder _bouton() => find.byKey(AdminShell.boutonPanneauKey);
Finder _pied() => find.byKey(NavShell.piedCompteKey);

void main() {
  _sousLiensTests();
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('1440 (${sens.name}) : un seul bouton, meme place ouvert et '
        'replie', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(1440, 900), sens: sens);
      expect(find.byKey(AdminShell.barreLateraleKey), findsOneWidget);
      final Rect ouvert = tester.getRect(_bouton());
      await tester.tap(_bouton());
      await tester.pump();
      expect(find.byKey(AdminShell.railKey), findsOneWidget);
      final Rect replie = tester.getRect(_bouton());
      expect(replie.top, ouvert.top);
      if (sens == TextDirection.ltr) {
        expect(replie.left, ouvert.left);
      } else {
        expect(replie.right, ouvert.right);
      }
      expect(_bouton(), findsOneWidget);
    });
  }

  testWidgets('le choix est garde par appareil (navigation.repliee)', (
    WidgetTester tester,
  ) async {
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(tester, taille: const Size(1440, 900));
    await tester.tap(_bouton());
    await tester.pump();
    expect(m.conteneur.read(navigationReplieeProvider), isTrue);
  });

  testWidgets('800 : le bouton du rail ouvre le panneau par-dessus la page, '
      'avec un voile (point 6)', (WidgetTester tester) async {
    await _monter(
      tester,
      taille: const Size(800, 1000),
      domaineActif: AdminDomaine.personnes,
      sousLiens: sousLiensAdmin(),
      cheminCourant: Routes.adminPersonnesComptes,
    );
    expect(find.byKey(AdminShell.railKey), findsOneWidget);
    expect(_pied(), findsOneWidget);
    final Rect pageAvant = tester.getRect(find.byType(PageShell));
    await tester.tap(_bouton());
    await tester.pumpAndSettle();
    // Le panneau entier, ses sections et les pages du domaine ouvert.
    expect(find.byKey(AdminShell.tiroirKey), findsOneWidget);
    expect(find.text(t.nav.admin.sections.quotidien), findsOneWidget);
    expect(find.text(t.admin.comptes.titre), findsOneWidget);
    // Par-dessus : la page garde sa place et sa largeur, un voile la couvre.
    expect(tester.getRect(find.byType(PageShell)), pageAvant);
    expect(find.byType(ModalBarrier), findsWidgets);
    // Le bouton, a la meme place, le referme.
    await tester.tap(find.byKey(AdminShell.boutonPanneauKey).last);
    await tester.pumpAndSettle();
    expect(find.byKey(AdminShell.tiroirKey), findsNothing);
  });

  testWidgets('800 : un sous-lien du panneau ouvert mene a sa page et le '
      'referme', (WidgetTester tester) async {
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(
          tester,
          taille: const Size(800, 1000),
          domaineActif: AdminDomaine.personnes,
          sousLiens: sousLiensAdmin(),
          cheminCourant: Routes.adminPersonnesDossiers,
        );
    await tester.tap(_bouton());
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.candidatures.titre));
    await tester.pumpAndSettle();
    expect(m.journal, contains(Routes.adminPersonnesCandidatures));
    expect(find.byKey(AdminShell.tiroirKey), findsNothing);
  });

  testWidgets('les huit domaines restent, dans le meme ordre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 900));
    for (final AdminDomaine d in domainesAdmin(voitDirection: true)) {
      expect(
        find.descendant(
          of: find.byKey(AdminShell.barreLateraleKey),
          matching: find.text(d.libelle),
        ),
        findsOneWidget,
        reason: d.libelle,
      );
    }
  });

  testWidgets('pied : menu Mon compte, theme, Se deconnecter', (
    WidgetTester tester,
  ) async {
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(tester, taille: const Size(1440, 900));
    await tester.tap(_pied());
    await tester.pumpAndSettle();
    expect(find.text(t.commun.theme.sombre), findsOneWidget);
    await tester.tap(find.text(t.compte.deconnexion));
    await tester.pumpAndSettle();
    expect(m.journal, <String>['sortie']);
    await tester.tap(_pied());
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.nav.compte).last);
    await tester.pumpAndSettle();
    expect(m.journal, <String>['sortie', 'compte']);
  });

  for (final Size taille in const <Size>[Size(800, 1000), Size(1440, 900)]) {
    for (final double echelle in const <double>[1, 2]) {
      for (final ThemeMode theme in const <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${taille.width.toInt()} x$echelle ${theme.name} '
              '${sens.name} : pied dans la colonne, rien de coupe', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              taille: taille,
              echelle: echelle,
              theme: theme,
              sens: sens,
            );
            final Finder colonne = find.byKey(
              taille.width < 1200
                  ? AdminShell.railKey
                  : AdminShell.barreLateraleKey,
            );
            final Rect r = tester.getRect(colonne);
            final Rect p = tester.getRect(_pied());
            expect(p.left, greaterThanOrEqualTo(r.left));
            expect(p.right, lessThanOrEqualTo(r.right));
            expect(p.bottom, lessThanOrEqualTo(r.bottom));
            verifierAucunMotCoupe(tester, _pied());
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}

/// NAV-SOUS-LIENS : les pages des domaines dans le panneau.
void _sousLiensTests() {
  testWidgets('1440 : trois sections, et les pages du domaine ouvert sous '
      'lui ; la page ouverte est annoncee selectionnee', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(
          tester,
          taille: const Size(1440, 900),
          domaineActif: AdminDomaine.personnes,
          sousLiens: sousLiensAdmin(),
          cheminCourant: Routes.adminPersonnesComptes,
        );
    final Finder barre = find.byKey(AdminShell.barreLateraleKey);
    for (final SectionAdmin section in SectionAdmin.values) {
      expect(
        find.descendant(of: barre, matching: find.text(section.libelle)),
        findsOneWidget,
        reason: section.name,
      );
    }
    // Les pages de Personnes, pas celles d'un autre domaine.
    expect(
      find.descendant(of: barre, matching: find.text(t.admin.comptes.titre)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: barre,
        matching: find.text(t.nav.admin.sousLiens.admissions),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: barre, matching: find.text(t.admin.journal.titre)),
      findsNothing,
    );
    expect(
      tester.getSemantics(
        find.descendant(of: barre, matching: find.text(t.admin.comptes.titre)),
      ),
      isSemantics(
        label: t.admin.comptes.titre,
        isSelected: true,
        isLink: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(
      find.descendant(
        of: barre,
        matching: find.text(t.admin.candidatures.titre),
      ),
    );
    await tester.pump();
    expect(m.journal, <String>[Routes.adminPersonnesCandidatures]);
    semantique.dispose();
  });

  testWidgets('rail replie : un domaine qui a des pages ouvre leur menu, la '
      'page choisie y mene', (WidgetTester tester) async {
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(
          tester,
          taille: const Size(1440, 900),
          sousLiens: sousLiensAdmin(),
          cheminCourant: Routes.admin,
        );
    await tester.tap(_bouton());
    await tester.pump();
    final Finder rail = find.byKey(AdminShell.railKey);
    expect(rail, findsOneWidget);
    await tester.tap(
      find.descendant(
        of: rail,
        matching: find.byTooltip(AdminDomaine.personnes.libelle),
      ),
    );
    await tester.pumpAndSettle();
    expect(m.journal, isEmpty, reason: 'le menu s ouvre, rien ne navigue');
    await tester.tap(find.text(t.admin.candidatures.titre).last);
    await tester.pumpAndSettle();
    expect(m.journal, <String>[Routes.adminPersonnesCandidatures]);
    // Un domaine sans pages (l'Accueil) y mene directement.
    await tester.tap(
      find.descendant(
        of: rail,
        matching: find.byTooltip(AdminDomaine.accueil.libelle),
      ),
    );
    await tester.pump();
    expect(m.journal.last, Routes.admin);
  });

  for (final ({Size taille, bool repetee}) cas
      in <({Size taille, bool repetee})>[
        (taille: const Size(1440, 900), repetee: false),
        (taille: const Size(800, 1000), repetee: false),
        (taille: const Size(390, 844), repetee: true),
      ]) {
    testWidgets('${cas.taille.width.toInt()} : la page '
        '${cas.repetee ? 'garde' : 'retire'} sa sous-navigation', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: cas.taille,
        domaineActif: AdminDomaine.personnes,
        sousLiens: sousLiensAdmin(),
        cheminCourant: Routes.adminPersonnesComptes,
        page: PageShell(
          titre: t.admin.comptes.titre,
          entete: SousNavigationDomaine(
            onglets: ongletsPersonnes(),
            indexActif: 1,
          ),
          child: const SizedBox(),
        ),
      );
      expect(
        find.byWidgetPredicate((Widget w) => w is SelecteurSection),
        cas.repetee ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('sans sous-liens, la page garde sa sous-navigation', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      taille: const Size(1440, 900),
      domaineActif: AdminDomaine.personnes,
      page: PageShell(
        titre: t.admin.comptes.titre,
        entete: SousNavigationDomaine(
          onglets: ongletsPersonnes(),
          indexActif: 1,
        ),
        child: const SizedBox(),
      ),
    );
    expect(
      find.byWidgetPredicate((Widget w) => w is SelecteurSection),
      findsOneWidget,
    );
  });
}
