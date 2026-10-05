// CT-2 : CTR-01 Controle refondu. La coquille s'ouvre depuis la VRAIE route
// de demonstration (/demo/controleur) pour chacune des quatre situations ;
// en direct, on TAPE « Commencer le controle » et on arrive dans /salle
// avec le billet de la seance (rôle controleur, CT-3 completera la salle).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import '../../support/harnais.dart' show FauxServiceVideo;

void main() {
  BilletSalle? billet;

  Future<GoRouter> monter(
    WidgetTester tester,
    EtatDemoControleur etat, {
    Size taille = const Size(390, 844),
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    billet = null;
    final GoRouter routeur = GoRouter(
      initialLocation: adresseDemoControleur(
        EcranDemoControleur.controle,
        etat: etat,
      ),
      routes: <RouteBase>[
        // Pose AVANT les routes de demonstration : la premiere qui
        // correspond l'emporte. La demonstration entre dans SA salle (CT-3).
        GoRoute(
          path: cheminDemoSalleControleur,
          builder: (BuildContext _, GoRouterState e) {
            billet = e.extra is BilletSalle ? e.extra! as BilletSalle : null;
            return const Scaffold(body: Text('salle'));
          },
        ),
        ...routesDemoControleur('dev'),
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState e) {
            billet = e.extra is BilletSalle ? e.extra! as BilletSalle : null;
            return const Scaffold(body: Text('salle'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavShell), findsOneWidget);
    expect(find.byType(ControleControleurPage), findsOneWidget);
    return routeur;
  }

  // Ce que CTR-01 ne montre jamais (C1, C3, C13) : ni planning, ni carte
  // « Mon compte » qui doublerait la destination Compte.
  void sansPlanningNiCompte() {
    expect(find.textContaining('Planning'), findsNothing);
    expect(find.text(t.compte.titre), findsNothing);
    expect(find.text(t.compte.profilDetail), findsNothing);
  }

  testWidgets('aucune mission : le texte du doc, aucun bouton', (
    WidgetTester tester,
  ) async {
    await monter(tester, EtatDemoControleur.aucune);
    expect(find.text(t.controleur.controle.vide), findsOneWidget);
    expect(find.text(t.controleur.controle.videAide), findsOneWidget);
    expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
    sansPlanningNiCompte();
  });

  testWidgets('pas encore en direct : ligne calme, aucun bouton (R4)', (
    WidgetTester tester,
  ) async {
    await monter(tester, EtatDemoControleur.pasEncoreEnDirect);
    expect(find.text(t.controleur.controle.mission), findsOneWidget);
    expect(find.text('Classe An-Nour'), findsOneWidget);
    expect(find.text('Sayyid Ibrahim'), findsOneWidget);
    expect(find.text(t.controleur.controle.attente), findsOneWidget);
    expect(find.text(t.controleur.controle.commencer), findsNothing);
    expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
    sansPlanningNiCompte();
  });

  testWidgets('mission indisponible : le message generique seul (P-CTR-08)', (
    WidgetTester tester,
  ) async {
    await monter(tester, EtatDemoControleur.indisponible);
    expect(find.text(t.controleur.controle.indisponible), findsOneWidget);
    expect(find.text('Classe An-Nour'), findsNothing);
    expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
    sansPlanningNiCompte();
  });

  testWidgets('en direct : on tape « Commencer le controle » et on entre en '
      'salle avec le billet de la seance', (WidgetTester tester) async {
    final GoRouter routeur = await monter(tester, EtatDemoControleur.enDirect);
    expect(find.text(t.controleur.controle.attente), findsNothing);
    expect(find.text(t.controleur.controle.commencer), findsOneWidget);
    sansPlanningNiCompte();
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    expect(routeur.state.uri.path, cheminDemoSalleControleur);
    expect(find.text('salle'), findsOneWidget);
    expect(
      billet?.sessionId,
      DonneesControleurDemo.mission(EtatDemoControleur.enDirect)!.seanceId,
    );
  });

  // CTRL-BR-OBS-1 (BR-CT-19) : le chemin PAR DEFAUT de « Commencer » (sans
  // la redirection de la demonstration) va a /salle avec le billet seul.
  // Il n'inscrit pas la visite (`observerEnControle`, RPC
  // `rejoindre_observation`) : a brancher a BR-1, sinon le jeton est refuse
  // en reel et le passage n'est pas journalise. Ce test fixe l'etat actuel.
  testWidgets('chemin par defaut : /salle avec le billet seul, aucune '
      'inscription de visite avant BR-1 (BR-CT-19)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final MissionControle mission = missionDemoControleur(
      EtatDemoControleur.enDirect,
    )!;
    final FauxServiceVideo video = FauxServiceVideo();
    BilletSalle? recu;
    final GoRouter routeur = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: ControleControleurPage()),
        ),
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState e) {
            recu = e.extra is BilletSalle ? e.extra! as BilletSalle : null;
            return const Scaffold(body: Text('salle'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          missionControleProvider.overrideWith((Ref _) async => mission),
          serviceVideoProvider.overrideWithValue(video),
        ],
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    expect(routeur.state.uri.path, Routes.salle);
    expect(recu?.sessionId, mission.seanceId);
    expect(video.observations, isEmpty);
  });

  testWidgets('aucun debordement a 800x600, dans chaque situation', (
    WidgetTester tester,
  ) async {
    for (final EtatDemoControleur etat in EtatDemoControleur.values) {
      await monter(tester, etat, taille: const Size(800, 600));
      expect(tester.takeException(), isNull, reason: etat.name);
    }
  });

  test('le fournisseur par defaut est neutre : aucune mission', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(missionControleProvider.future), isNull);
  });

  test('la demonstration traduit chaque situation', () {
    expect(missionDemoControleur(EtatDemoControleur.aucune), isNull);
    expect(
      missionDemoControleur(EtatDemoControleur.pasEncoreEnDirect)!.etat,
      EtatMissionControle.prevue,
    );
    expect(
      missionDemoControleur(EtatDemoControleur.enDirect)!.etat,
      EtatMissionControle.enDirect,
    );
    expect(
      missionDemoControleur(EtatDemoControleur.indisponible)!.etat,
      EtatMissionControle.indisponible,
    );
  });
  // Revue CT-2 : « 1 eleves » ; en francais, 0 et 1 sont au singulier.
  test('le nombre d eleves s accorde', () {
    final e = t.controleur.controle;
    expect(e.eleves(n: 0), '0 élève');
    expect(e.eleves(n: 1), '1 élève');
    expect(e.eleves(n: 3), '3 élèves');
  });
}
