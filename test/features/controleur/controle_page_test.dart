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

import '../../support/demo/controleur_demo.dart';
import '../../support/demo/demo_controleur_page.dart';
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

  // CTRL-BR-OBS-1 (BR-CT-19), puis N3 D3 (03/11/2026) : le chemin PAR
  // DEFAUT de « Commencer » (sans la redirection de la demonstration)
  // commence la visite au serveur (`demarrer_mission_controle`), puis va a
  // /salle avec le billet seul. L'inscription dans la salle
  // (`rejoindre_observation`) reste celle de la salle : rien ici. Un refus
  // du serveur reste sur CTR-01 et relit la mission.
  Future<GoRouter> monterParDefaut(
    WidgetTester tester,
    MissionControle mission,
    _FauxPortMission port,
    FauxServiceVideo video,
    void Function(BilletSalle?) recevoir,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
            recevoir(e.extra is BilletSalle ? e.extra! as BilletSalle : null);
            return const Scaffold(body: Text('salle'));
          },
        ),
      ],
    );
    port.mission = mission;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          portMissionControleProvider.overrideWithValue(port),
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
    return routeur;
  }

  testWidgets('chemin par defaut : la visite commence au serveur, puis '
      '/salle avec le billet seul (BR-CT-19, N3 D3)', (
    WidgetTester tester,
  ) async {
    final MissionControle mission = missionDemoControleur(
      EtatDemoControleur.enDirect,
    )!;
    final FauxServiceVideo video = FauxServiceVideo();
    final _FauxPortMission port = _FauxPortMission();
    BilletSalle? recu;
    final GoRouter routeur = await monterParDefaut(
      tester,
      mission,
      port,
      video,
      (BilletSalle? b) => recu = b,
    );
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    expect(port.demarrees, <String?>[mission.id]);
    expect(routeur.state.uri.path, Routes.salle);
    // Le billet seul, jamais par l'URL (ADR-005) : aucun parametre de requete.
    expect(routeur.state.uri.queryParameters, isEmpty);
    expect(recu?.sessionId, mission.seanceId);
    expect(video.observations, isEmpty);
  });

  testWidgets('chemin par defaut : un refus du serveur reste sur CTR-01 et '
      'relit la mission (N3 D3)', (WidgetTester tester) async {
    final MissionControle mission = missionDemoControleur(
      EtatDemoControleur.enDirect,
    )!;
    final _FauxPortMission port = _FauxPortMission()..refuser = true;
    final GoRouter routeur = await monterParDefaut(
      tester,
      mission,
      port,
      FauxServiceVideo(),
      (BilletSalle? _) {},
    );
    final int lectures = port.lectures;
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    expect(routeur.state.uri.path, '/');
    expect(port.lectures, greaterThan(lectures));
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

class _FauxPortMission implements PortMissionControle {
  MissionControle? mission;
  bool refuser = false;
  int lectures = 0;
  final List<String?> demarrees = <String?>[];

  @override
  Future<MissionControle?> maMission() async {
    lectures++;
    return mission;
  }

  @override
  Future<void> demarrer(String missionId) async {
    if (refuser) throw StateError('refus');
    demarrees.add(missionId);
  }
}
