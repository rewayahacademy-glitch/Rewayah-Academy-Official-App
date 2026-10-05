// CT-4 : CTR-03 Compte rendu, depuis la VRAIE route de demonstration.
// « Commencer le controle » -> « Quitter » -> compte rendu : faits replies,
// trois cartes sans preselection, « Rien a signaler » puis « Envoyer le
// compte rendu » -> resultat. « Plus tard » laisse un compte rendu « a
// terminer » sur le Controle. Sans serveur, l'envoi echoue honnetement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart'
    show heureDeLAppareil;
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

/// Echoue au premier essai de transmission, reussit ensuite.
class _PortEchecPuisSucces implements EnvoiCompteRendu {
  int essais = 0;

  @override
  Future<void> transmettreVisite(String seanceId) async {
    essais++;
    if (essais == 1) throw StateError('pas de reponse');
  }

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) async {}

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) async {}
}

/// Note chaque appel, avec la seance visee (revue CT-R B1).
class _PortTemoin implements EnvoiCompteRendu {
  final List<String> transmises = <String>[];
  final List<(String, ChoixCompteRendu)> envois =
      <(String, ChoixCompteRendu)>[];

  @override
  Future<void> transmettreVisite(String seanceId) async =>
      transmises.add(seanceId);

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) async =>
      envois.add((seanceId, choix));

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) async {}
}

/// La visite A, copiee a l'entree en salle.
final CompteRenduEnSuspens _visiteA = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
  missionId: 'mission-A',
);

/// Une autre mission, proposee par le serveur apres la seance A.
MissionControle _missionB() {
  final MissionControle m = missionDemoControleur(EtatDemoControleur.enDirect)!;
  return MissionControle(
    id: 'mission-B',
    seanceId: 'seance-B',
    classe: 'Classe Al-Qamar',
    enseignant: m.enseignant,
    nombreEleves: m.nombreEleves,
    debut: DateTime(2026, 9, 28, 19),
    finPrevue: DateTime(2026, 9, 28, 19, 45),
    etat: EtatMissionControle.enDirect,
  );
}

/// Le compte rendu par sa route reelle (`?seance=`), la mission courante
/// remplacee par [mission].
Future<void> _monterRouteReelle(
  WidgetTester tester, {
  required EnvoiCompteRendu port,
  required MissionControle? mission,
  required String seance,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseCompteRendu(Routes.controleurCompteRendu, seance),
    routes: <RouteBase>[
      // Le meme constructeur que `app_router.dart`.
      GoRoute(
        path: Routes.controleurCompteRendu,
        builder: (BuildContext _, GoRouterState etat) =>
            CompteRenduControlePage(
              seanceId: etat.uri.queryParameters['seance'],
            ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        missionControleProvider.overrideWith((Ref _) async => mission),
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            _visiteA.seanceId: _visiteA,
          }),
        ),
        envoiCompteRenduProvider.overrideWithValue(port),
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
}

Future<void> _monter(
  WidgetTester tester,
  GoRouter routeur, {
  Size taille = const Size(1280, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
}

GoRouter _routeurDemo() => GoRouter(
  initialLocation: adresseDemoControleur(EcranDemoControleur.controle),
  routes: routesDemoControleur('dev'),
);

Future<void> _jusquAuCompteRendu(
  WidgetTester tester, {
  Size taille = const Size(1280, 900),
}) async {
  await _monter(tester, _routeurDemo(), taille: taille);
  await tester.tap(find.byKey(ControleControleurPage.commencerKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.salle.quitter));
  await tester.pumpAndSettle();
  expect(find.byType(CompteRenduControlePage), findsOneWidget);
}

void main() {
  testWidgets('Rien a signaler, puis Envoyer le compte rendu : resultat', (
    WidgetTester tester,
  ) async {
    await _jusquAuCompteRendu(tester);
    final r = t.controleur.compteRendu;

    expect(find.text(r.titre), findsWidgets);
    expect(find.text(r.question), findsOneWidget);
    // Aucune preselection : aucun bouton d'envoi, aucune notice.
    expect(find.byKey(CompteRenduControlePage.actionKey), findsNothing);
    expect(find.text(r.notice), findsNothing);
    expect(find.text(r.envoyer), findsNothing);
    // Aucun interrupteur de partage (C2).
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    // Faits replies par defaut ; deplier ecrit l'ecart (C4).
    expect(find.textContaining('min de retard'), findsNothing);
    await tester.tap(find.text(r.faits));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 min de retard'), findsOneWidget);
    expect(find.text(r.enCours), findsOneWidget);
    expect(find.textContaining('Enregistrement'), findsNothing);

    // Choisir n'envoie rien : le bouton apparait.
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(r.notice), findsOneWidget);
    expect(find.text(r.envoyer), findsOneWidget);
    expect(find.text(r.envoyeTitre), findsNothing);

    await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pump();
    // Pas de succes avant la reponse.
    expect(find.text(r.envoyeTitre), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text(r.envoyeTitre), findsOneWidget);
    expect(find.text(r.ecrireAdmin), findsOneWidget);

    // Retour au controle : plus rien a terminer.
    await tester.tap(find.text(r.revenir));
    await tester.pumpAndSettle();
    expect(find.byType(ControleControleurPage), findsOneWidget);
    expect(find.text(r.aTerminer), findsNothing);
  });

  testWidgets('Quitter puis Plus tard : les faits de la visite sont partis', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _routeurDemo());
    final r = t.controleur.compteRendu;
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.salle.quitter));
    await tester.pump();
    await tester.pump();
    // La visite part des l'arrivee, sans geste du controleur (C2) ; aucun
    // succes avant la reponse.
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    expect(find.text(r.visiteEnCours), findsOneWidget);
    expect(find.text(r.visiteTransmise), findsNothing);

    // « Plus tard » tout de suite : la transmission n'est pas retenue. Les
    // lignes d'aide (K-58) allongent la page : on fait defiler jusqu'au
    // bouton, comme l'utilisateur.
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.tap(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ControleControleurPage), findsOneWidget);
    expect(find.text(r.aTerminer), findsOneWidget);
    expect(find.text(r.visiteTransmise), findsOneWidget);
    expect(find.text(r.visiteEnCours), findsNothing);

    // La reprise garde l'etat : rien ne repart en double.
    await tester.tap(find.byKey(ControleControleurPage.reprendreKey));
    await tester.pumpAndSettle();
    expect(find.text(r.visiteTransmise), findsOneWidget);
    expect(find.text(r.visiteEnCours), findsNothing);
  });

  testWidgets(
    'Transmission de la visite en echec : le dit, puis nouvel essai',
    (WidgetTester tester) async {
      final _PortEchecPuisSucces port = _PortEchecPuisSucces();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            visitesObserveesProvider.overrideWith(
              () => VisitesObservees(<String, CompteRenduEnSuspens>{
                _visiteA.seanceId: _visiteA,
              }),
            ),
            envoiCompteRenduProvider.overrideWithValue(port),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: CompteRenduControlePage(seanceId: _visiteA.seanceId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final r = t.controleur.compteRendu;
      expect(port.essais, 1);
      expect(find.text(r.visiteEchec), findsOneWidget);
      expect(find.text(r.visiteTransmise), findsNothing);

      await tester.tap(find.byKey(LigneTransmissionVisite.reessayerKey));
      await tester.pumpAndSettle();
      expect(port.essais, 2);
      expect(find.text(r.visiteTransmise), findsOneWidget);
      expect(find.byKey(LigneTransmissionVisite.reessayerKey), findsNothing);
    },
  );

  testWidgets('Plus tard et Envoyer : cote a cote sur ordinateur', (
    WidgetTester tester,
  ) async {
    await _jusquAuCompteRendu(tester);
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      ),
    );
    await tester.pumpAndSettle();
    final Rect plusTard = tester.getRect(
      find.byKey(CompteRenduControlePage.plusTardKey),
    );
    final Rect envoyer = tester.getRect(
      find.byKey(CompteRenduControlePage.actionKey),
    );
    // Meme ligne, le dominant en dernier, aucun ne s'etire.
    expect(plusTard.center.dy, closeTo(envoyer.center.dy, 1));
    expect(envoyer.left, greaterThan(plusTard.right));
    expect(plusTard.width, lessThan(320));
    // Les deux tiennent dans la colonne de 640 : aucun ne prend la largeur.
    expect(envoyer.right - plusTard.left, lessThanOrEqualTo(640));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('Plus tard et Envoyer : empiles pleine largeur sur mobile', (
    WidgetTester tester,
  ) async {
    await _jusquAuCompteRendu(tester, taille: const Size(390, 844));
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      ),
    );
    await tester.pumpAndSettle();
    final Rect plusTard = tester.getRect(
      find.byKey(CompteRenduControlePage.plusTardKey),
    );
    final Rect envoyer = tester.getRect(
      find.byKey(CompteRenduControlePage.actionKey),
    );
    expect(envoyer.bottom, lessThanOrEqualTo(plusTard.top));
    expect(plusTard.width, closeTo(envoyer.width, 1));
    expect(plusTard.width, greaterThan(300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('Plus tard : compte rendu a terminer, puis reprise', (
    WidgetTester tester,
  ) async {
    await _jusquAuCompteRendu(tester);
    final r = t.controleur.compteRendu;

    await tester.ensureVisible(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ControleControleurPage), findsOneWidget);
    expect(find.text(r.aTerminer), findsOneWidget);

    await tester.tap(find.byKey(ControleControleurPage.reprendreKey));
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);

    // Ajouter une observation mene a CTR-03A (CT-5).
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.ajouterObservation),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(r.notice), findsNothing);
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    expect(find.byType(ObservationControlePage), findsOneWidget);
  });

  testWidgets('Sans serveur, l envoi echoue et le dit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          visitesObserveesProvider.overrideWith(
            () => VisitesObservees(<String, CompteRenduEnSuspens>{
              _visiteA.seanceId: _visiteA,
            }),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: CompteRenduControlePage(seanceId: _visiteA.seanceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final r = t.controleur.compteRendu;
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    expect(find.text(r.envoyeTitre), findsNothing);
    // Revue CT-R m1 : message propre a « Rien a signaler », qui n'a pas de
    // texte ; il dit « non confirme » (D5) et ce qui reste fiable (K-59).
    expect(find.text(r.echecRien), findsOneWidget);
    expect(find.text(r.echec), findsNothing);
    expect(r.echecRien, contains("n'est pas confirmé"));
    expect(r.echecRien, isNot(contains('texte')));
    // Le choix est garde : le bouton reste la.
    expect(find.text(r.envoyer), findsOneWidget);
  });

  // Revue CT-R B1 : le compte rendu suit la visite qui sort de la salle,
  // jamais la mission courante.
  for (final (String cas, MissionControle? Function() mission)
      in <(String, MissionControle? Function())>[
        ('la mission courante est devenue une autre', _missionB),
        ('la mission courante est vide', () => null),
      ]) {
    testWidgets('Sortie de la seance A, $cas : A est transmise et envoyee', (
      WidgetTester tester,
    ) async {
      final _PortTemoin port = _PortTemoin();
      await _monterRouteReelle(
        tester,
        port: port,
        mission: mission(),
        seance: _visiteA.seanceId,
      );
      final r = t.controleur.compteRendu;
      expect(port.transmises, <String>[_visiteA.seanceId]);
      expect(
        find.text(
          r.sousTitre(
            classe: _visiteA.classe,
            heure: heureDeLAppareil(_visiteA.debut),
          ),
        ),
        findsWidgets,
      );
      expect(find.textContaining('Al-Qamar'), findsNothing);
      await tester.tap(
        find.byKey(
          CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pumpAndSettle();
      expect(port.envois, <(String, ChoixCompteRendu)>[
        (_visiteA.seanceId, ChoixCompteRendu.rienASignaler),
      ]);
      expect(find.text(r.envoyeTitre), findsOneWidget);
    });
  }

  testWidgets('Seance inconnue : le message generique, aucune transmission', (
    WidgetTester tester,
  ) async {
    final _PortTemoin port = _PortTemoin();
    await _monterRouteReelle(
      tester,
      port: port,
      mission: _missionB(),
      seance: 'seance-inconnue',
    );
    expect(find.text(t.controleur.controle.indisponible), findsOneWidget);
    expect(port.transmises, isEmpty);
    expect(find.textContaining('Al-Qamar'), findsNothing);
  });

  test('Deux visites a terminer coexistent ; terminer en retire une', () {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    final CompteRenduATerminer suivi = c.read(
      compteRenduATerminerProvider.notifier,
    );
    final CompteRenduEnSuspens b = CompteRenduEnSuspens.deMission(_missionB());
    suivi
      ..ouvrir(_visiteA)
      ..ouvrir(b)
      ..ouvrir(_visiteA.avec(TransmissionVisite.echec));
    expect(c.read(compteRenduATerminerProvider).keys, <String>[
      _visiteA.seanceId,
      b.seanceId,
    ]);
    // Rouvrir A ne remplace pas son etat.
    expect(
      c.read(compteRenduATerminerProvider)[_visiteA.seanceId]!.transmission,
      isNull,
    );
    suivi.terminer(_visiteA.seanceId);
    expect(c.read(compteRenduATerminerProvider).keys, <String>[b.seanceId]);
  });

  testWidgets('Deux visites a terminer : la reprise ouvre la bonne', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _PortTemoin port = _PortTemoin();
    final CompteRenduEnSuspens b = CompteRenduEnSuspens.deMission(_missionB());
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        missionControleProvider.overrideWith((Ref _) async => null),
        envoiCompteRenduProvider.overrideWithValue(port),
      ],
    );
    addTearDown(c.dispose);
    c.read(compteRenduATerminerProvider.notifier)
      ..ouvrir(_visiteA)
      ..ouvrir(b);
    final GoRouter routeur = GoRouter(
      initialLocation: Routes.controleur,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.controleur,
          builder: (BuildContext _, GoRouterState _) =>
              const ControleControleurPage(),
        ),
        GoRoute(
          path: Routes.controleurCompteRendu,
          builder: (BuildContext _, GoRouterState etat) =>
              CompteRenduControlePage(
                seanceId: etat.uri.queryParameters['seance'],
              ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
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
    final r = t.controleur.compteRendu;
    // Les deux blocs, la plus recente (B) d'abord.
    expect(find.text(r.aTerminer), findsNWidgets(2));
    final Finder repriseA = find.byKey(
      ControleControleurPage.cleReprendre(_visiteA.seanceId),
    );
    await tester.ensureVisible(repriseA);
    await tester.pumpAndSettle();
    await tester.tap(repriseA);
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    expect(
      find.text(
        r.sousTitre(
          classe: _visiteA.classe,
          heure: heureDeLAppareil(_visiteA.debut),
        ),
      ),
      findsWidgets,
    );
    expect(port.transmises, <String>[_visiteA.seanceId]);
  });
}
