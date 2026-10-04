// CT-3 : CTR-02 Observation, depuis la VRAIE route de demonstration.
// « Commencer le controle » -> la salle en role controleur (zone haute,
// Quitter ; « Son reçu » retire jusqu'a BR-1, CTRL-SON-1 ; « Agrandir »
// retire tant qu'aucun support n'est rendu, CTRL-AGRANDIR-1) ; aucune
// commande interdite rendue, pas meme grisee ; « Quitter » -> le compte rendu (CTR-03, provisoire).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

Future<GoRouter> _monter(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoControleur(EcranDemoControleur.controle),
    routes: routesDemoControleur('dev'),
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
  return routeur;
}

Finder _parSens(String libelle) => find.bySemanticsLabel(RegExp(libelle));

void main() {
  testWidgets('Commencer, observer sans commande interdite, puis Quitter', (
    WidgetTester tester,
  ) async {
    await _monter(tester);

    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();

    // La zone haute, visible du seul controleur.
    expect(find.text(t.salle.visiteControle.titre), findsOneWidget);
    expect(find.text(t.etat.enDirect), findsOneWidget);
    expect(find.text(t.salle.quitter), findsOneWidget);
    // Le rappel du controleur, garde ; la mention « visite de controle
    // possible », pour les participants seulement (CTRL-SALLE-1).
    expect(find.text(t.salle.bandeauControle), findsOneWidget);
    expect(find.text(t.salle.bandeauPermanent), findsNothing);
    // Aucune commande en bas. « Agrandir le support » est retire tant
    // qu'aucun support n'est rendu : il agrandissait l'enseignant
    // (CTRL-AGRANDIR-1, releve VERIF-CT-1).
    for (final String agrandir in <String>[
      t.salle.visiteControle.agrandir,
      t.salle.visiteControle.reduire,
    ]) {
      expect(find.text(agrandir), findsNothing, reason: agrandir);
      expect(_parSens(agrandir), findsNothing, reason: agrandir);
    }
    expect(find.byTooltip(t.tc.observation.visite.agrandir), findsNothing);
    // Les eleves restent a la vue (la colonne de presence n'est pas
    // remplacee par un cadre agrandi).
    expect(find.text(t.presence.titre), findsWidgets);
    // « Son reçu » est retire jusqu'a BR-1 (CTRL-SON-1, decision C5 = a) :
    // la bascule locale ne coupait rien.
    for (final String son in <String>[
      t.salle.visiteControle.sonRecu,
      t.salle.visiteControle.sonCoupe,
      t.salle.visiteControle.couperSon,
      t.salle.visiteControle.retablirSon,
    ]) {
      expect(find.text(son), findsNothing, reason: son);
      expect(_parSens(son), findsNothing, reason: son);
    }

    // Aucune commande interdite, ni rendue ni grisee.
    for (final String interdit in <String>[
      t.salle.ouvrirMicro,
      t.salle.fermerMicro,
      t.salle.ouvrirCamera,
      t.salle.fermerCamera,
      t.salle.micro,
      t.salle.camera,
      t.salle.microOuvert,
      t.salle.microCoupe,
      t.salle.cameraAllumee,
      t.salle.cameraCoupee,
      t.salle.quitterLeCours,
    ]) {
      expect(find.text(interdit), findsNothing, reason: interdit);
      expect(_parSens('^$interdit\$'), findsNothing, reason: interdit);
    }
    expect(
      find.textContaining(
        RegExp('lever la main|main lev', caseSensitive: false),
      ),
      findsNothing,
    );
    expect(
      find.textContaining(RegExp('discussion|chat', caseSensitive: false)),
      findsNothing,
    );
    // Pas de duree de presence (LIVE-CHRONO-01).
    expect(find.textContaining(RegExp(r'\d+ ?min')), findsNothing);

    // Eleves sans camera : prenom et initiales, jamais une photo.
    expect(find.text('Mariam'), findsWidgets);
    for (final AvatarTile a in tester.widgetList<AvatarTile>(
      find.byType(AvatarTile),
    )) {
      expect(a.urlSignee, isNull);
    }

    // Quitter, sans fenetre de confirmation, mene au compte rendu.
    await tester.tap(find.text(t.salle.quitter));
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.titre), findsWidgets);
    expect(Routes.controleurCompteRendu, '/controleur/compte-rendu');
    // La visite part a l'arrivee (CT-4) : sa reponse simulee arrive ensuite.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.compteRendu.visiteTransmise), findsOneWidget);
  });

  // CTRL-RETOUR-1 : la sortie de salle porte `?seance=` (salle_page.dart,
  // `_quitterControle`). La demonstration retombe sur sa visite par defaut
  // sans ce parametre : seule l'adresse prouve que la visite voyage.
  testWidgets('Quitter : l adresse du compte rendu porte la seance', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester);
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    final String seance = tester
        .widget<SallePage>(find.byType(SallePage))
        .seanceId;
    expect(seance, isNotEmpty);

    await tester.tap(find.text(t.salle.quitter));
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    expect(routeur.state.uri.path, cheminDemoCompteRenduControleur);
    expect(routeur.state.uri.queryParameters['seance'], seance);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}
