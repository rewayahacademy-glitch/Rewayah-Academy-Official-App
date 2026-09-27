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
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
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
  Future<void> envoyer(ChoixCompteRendu choix) async {}
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
      find.byKey(CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler)),
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

    // « Plus tard » tout de suite : la transmission n'est pas retenue.
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

  testWidgets('Transmission de la visite en echec : le dit, puis nouvel essai', (
    WidgetTester tester,
  ) async {
    final _PortEchecPuisSucces port = _PortEchecPuisSucces();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          missionControleProvider.overrideWith(
            (Ref _) async => missionDemoControleur(EtatDemoControleur.enDirect),
          ),
          envoiCompteRenduProvider.overrideWithValue(port),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const CompteRenduControlePage(),
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
  });

  testWidgets('Plus tard et Envoyer : cote a cote sur ordinateur', (
    WidgetTester tester,
  ) async {
    await _jusquAuCompteRendu(tester);
    await tester.tap(
      find.byKey(CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler)),
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
      find.byKey(CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler)),
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

    await tester.tap(find.byKey(CompteRenduControlePage.plusTardKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ControleControleurPage), findsOneWidget);
    expect(find.text(r.aTerminer), findsOneWidget);

    await tester.tap(find.byKey(ControleControleurPage.reprendreKey));
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);

    // Ajouter une observation mene a CTR-03A (provisoire, CT-5).
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.ajouterObservation),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(r.notice), findsNothing);
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    expect(find.byType(ObservationControlePage), findsOneWidget);
  });

  testWidgets('Sans serveur, l envoi echoue et le dit', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) =>
                const CompteRenduControlePage(),
          ),
        ],
      ),
    );
    final r = t.controleur.compteRendu;
    await tester.tap(
      find.byKey(CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    expect(find.text(r.envoyeTitre), findsNothing);
    expect(find.text(r.echec), findsOneWidget);
    // Le choix est garde : le bouton reste la.
    expect(find.text(r.envoyer), findsOneWidget);
  });
}
