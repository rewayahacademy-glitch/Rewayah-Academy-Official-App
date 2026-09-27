// CT-4 : CTR-03 Compte rendu, depuis la VRAIE route de demonstration.
// « Commencer le controle » -> « Quitter » -> compte rendu : faits replies,
// trois cartes sans preselection, « Rien a signaler » puis « Envoyer le
// compte rendu » -> resultat. « Plus tard » laisse un compte rendu « a
// terminer » sur le Controle. Sans serveur, l'envoi echoue honnetement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

Future<void> _monter(WidgetTester tester, GoRouter routeur) async {
  tester.view.physicalSize = const Size(1280, 900);
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

Future<void> _jusquAuCompteRendu(WidgetTester tester) async {
  await _monter(tester, _routeurDemo());
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

  testWidgets('Plus tard : compte rendu a terminer, puis reprise', (
    WidgetTester tester,
  ) async {
    await _jusquAuCompteRendu(tester);
    final r = t.controleur.compteRendu;

    await tester.tap(find.byKey(CompteRenduControlePage.plusTardKey));
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
