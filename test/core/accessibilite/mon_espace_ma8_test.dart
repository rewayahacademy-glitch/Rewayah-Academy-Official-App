// MA-8 : Mon espace en Mode Accessibilite, depuis la VRAIE route
// /demo/accessibilite. La page commune des reglages est reprise ; s'y
// ajoutent l'identite (sans age), la ligne « Mode Accessibilite », l'aide
// honnete. Idriss (adulte) a la bascule ; Mariam (mineure) n'en a pas, mais
// peut demander la presentation standard a son tuteur (S7 = b) : en cours,
// envoyee, ou envoi non confirme avec « Reessayer » (D5).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/port_demande_presentation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../../router/support_routeur.dart' show stabiliser;

/// Un port dont l'envoi attend le test, puis reussit ou echoue.
class _PortPilote implements PortDemandePresentation {
  Completer<void> envoi = Completer<void>();
  int appels = 0;

  @override
  Future<void> demanderPresentationStandard() {
    appels++;
    envoi = Completer<void>();
    return envoi.future;
  }
}

Future<void> _ouvrirMonEspace(
  WidgetTester tester,
  EleveDemoAccessibilite eleve, {
  PortDemandePresentation? port,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: port == null ? adresseDemoAccessibilite(eleve) : '/',
    routes: port == null
        ? routesDemoAccessibilite('local')
        : <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext _, GoRouterState _) =>
                  EcranAccessibiliteDemo(eleve: eleve, portDemande: port),
            ),
          ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: routeur,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    ),
  );
  await stabiliser(tester);
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.eleve.monEspace),
    ),
  );
  await stabiliser(tester);
  expect(
    tester.widget<NavShell>(find.byType(NavShell)).indexActif,
    EcranAccessibiliteDemo.indexMonEspace,
  );
}

Future<void> _vers(WidgetTester tester, Finder cible) async {
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  testWidgets('Mariam (mineure) : reglages communs repris, sans bascule, '
      'sans age, sans « effets », aide honnete', (WidgetTester tester) async {
    await _ouvrirMonEspace(tester, EleveDemoAccessibilite.mariam);
    expect(find.byType(ReglagesComptePage), findsOneWidget);
    expect(find.text(t.accessibilite.monEspace.titre), findsWidgets);
    expect(find.text(t.accessibilite.monEspace.mode), findsOneWidget);
    expect(find.text(t.accessibilite.monEspace.modeDetail), findsOneWidget);
    expect(find.text(t.accessibilite.monEspace.modeActif), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('bascule-mode')), findsNothing);
    expect(
      find.text(t.accessibilite.monEspace.presentationStandard),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'\d+\s?ans\b')), findsNothing);
    // Le libelle existant est garde ; « Reduire les effets » (sans effet)
    // n'est pas affiche en Mode Accessibilite.
    await _vers(tester, find.text(t.compte.animations));
    expect(find.text(t.compte.effets), findsNothing);
    // MA-RC (M3, MA14) : « Besoin d'aide ? » ouvre la page d'aide honnete,
    // comme sur les autres ecrans ; le retour ramene a Mon espace.
    final Finder aide = find.text(t.accessibilite.accueil.aide);
    await _vers(tester, aide);
    await tester.tap(aide);
    await stabiliser(tester);
    expect(find.byKey(const ValueKey<String>('demo-aide')), findsOneWidget);
    expect(find.text(t.compte.tuteur.pageAide.aucunCanal), findsOneWidget);
    expect(
      find.text(t.compte.tuteur.pageAide.indisponibleTitre),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(find.byKey(const ValueKey<String>('demo-aide'))),
    ).pop();
    await stabiliser(tester);
    expect(find.byKey(const ValueKey<String>('demo-aide')), findsNothing);
    expect(find.byType(ReglagesComptePage), findsOneWidget);
  });

  testWidgets('MA-GR-1 : appareils et confidentialite masques, un seul '
      'ecart de section avant l\'aide', (WidgetTester tester) async {
    await _ouvrirMonEspace(tester, EleveDemoAccessibilite.mariam);
    final Finder aide = find.byKey(const ValueKey<String>('mon-espace-aide'));
    await _vers(tester, aide);
    expect(find.text(t.compte.appareils), findsNothing);
    expect(find.text(t.compte.confidentialite), findsNothing);
    final Finder derniere = find.ancestor(
      of: find.text(t.compte.lectureGrande),
      matching: find.byType(SettingRow),
    );
    final double ecart =
        tester.getTopLeft(aide).dy - tester.getBottomLeft(derniere).dy;
    expect(ecart, moreOrLessEquals(AppSpacing.section));
  });

  testWidgets('Idriss (adulte) : la bascule agit sur la presentation de la '
      'demonstration', (WidgetTester tester) async {
    await _ouvrirMonEspace(tester, EleveDemoAccessibilite.idriss);
    final Finder bascule = find.byKey(const ValueKey<String>('bascule-mode'));
    expect(bascule, findsOneWidget);
    expect(
      find.text(t.accessibilite.monEspace.presentationStandard),
      findsNothing,
    );
    expect(tester.widget<Switch>(bascule).value, isTrue);
    // MA-CMD-1 : la barre du bas du mode (onglets de 72) prend plus de
    // hauteur ; la bascule peut passer sous la ligne de flottaison.
    await _vers(tester, bascule);
    await tester.tap(bascule);
    await stabiliser(tester);
    expect(tester.widget<Switch>(bascule).value, isFalse);
    // Presentation standard : « Reduire les effets » revient, comme partout.
    await _vers(tester, find.text(t.compte.effets));
    expect(find.text(t.compte.effets), findsOneWidget);
  });

  testWidgets('Mariam : demande en cours, envoi non confirme puis '
      '« Reessayer », puis envoyee', (WidgetTester tester) async {
    final _PortPilote port = _PortPilote();
    await _ouvrirMonEspace(tester, EleveDemoAccessibilite.mariam, port: port);
    await tester.ensureVisible(
      find.text(t.accessibilite.monEspace.presentationStandard),
    );
    await tester.pump();
    await tester.tap(find.text(t.accessibilite.monEspace.presentationStandard));
    await tester.pump();
    expect(find.text(t.accessibilite.monEspace.demandeEnCours), findsOneWidget);
    port.envoi.completeError(StateError('reseau'));
    await tester.pump();
    expect(
      find.text(t.accessibilite.monEspace.demandeNonConfirmee),
      findsOneWidget,
    );
    expect(find.text(t.compte.reessayer), findsOneWidget);
    await tester.tap(find.text(t.accessibilite.monEspace.presentationStandard));
    await tester.pump();
    port.envoi.complete();
    await tester.pump();
    expect(find.text(t.accessibilite.monEspace.demandeEnvoyee), findsOneWidget);
    expect(port.appels, 2);
    // Une demande envoyee ne se renvoie pas.
    await tester.tap(find.text(t.accessibilite.monEspace.presentationStandard));
    await tester.pump();
    expect(port.appels, 2);
  });
}
