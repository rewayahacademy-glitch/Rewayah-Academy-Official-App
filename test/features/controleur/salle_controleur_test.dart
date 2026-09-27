// CT-3 : CTR-02 Observation, depuis la VRAIE route de demonstration.
// « Commencer le controle » -> la salle en role controleur (zone haute,
// Son recu, Agrandir, Quitter) ; aucune commande interdite rendue, pas meme
// grisee ; « Quitter » -> le compte rendu (CTR-03, provisoire).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> _monter(WidgetTester tester) async {
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
    // Le rappel existant et le bandeau permanent, gardes.
    expect(find.text(t.salle.bandeauControle), findsOneWidget);
    expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    // Les deux commandes.
    expect(_parSens(t.salle.visiteControle.couperSon), findsOneWidget);
    expect(_parSens(t.salle.visiteControle.agrandir), findsOneWidget);

    // Aucune commande interdite, ni rendue ni grisee.
    for (final String interdit in <String>[
      t.salle.ouvrirMicro,
      t.salle.fermerMicro,
      t.salle.ouvrirCamera,
      t.salle.fermerCamera,
      t.salle.micro,
      t.salle.camera,
      t.salle.quitterLeCours,
    ]) {
      expect(find.text(interdit), findsNothing, reason: interdit);
      expect(_parSens('^$interdit\$'), findsNothing, reason: interdit);
    }
    expect(find.textContaining(RegExp('lever la main|main lev', caseSensitive: false)), findsNothing);
    expect(find.textContaining(RegExp('discussion|chat', caseSensitive: false)), findsNothing);
    // Pas de duree de presence (LIVE-CHRONO-01).
    expect(find.textContaining(RegExp(r'\d+ ?min')), findsNothing);

    // Eleves sans camera : prenom et initiales, jamais une photo.
    expect(find.text('Mariam'), findsWidgets);
    for (final AvatarTile a in tester.widgetList<AvatarTile>(
      find.byType(AvatarTile),
    )) {
      expect(a.urlSignee, isNull);
    }

    // Son recu : icone et mot changent ensemble.
    await tester.tap(_parSens(t.salle.visiteControle.couperSon));
    await tester.pumpAndSettle();
    expect(find.text(t.salle.visiteControle.sonCoupe), findsOneWidget);
    expect(_parSens(t.salle.visiteControle.retablirSon), findsOneWidget);

    // Agrandir, puis Echap rend la vue.
    await tester.tap(_parSens(t.salle.visiteControle.agrandir));
    await tester.pumpAndSettle();
    expect(_parSens(t.salle.visiteControle.reduire), findsOneWidget);
    expect(find.text(t.presence.titre), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_parSens(t.salle.visiteControle.agrandir), findsOneWidget);

    // Quitter, sans fenetre de confirmation, mene au compte rendu.
    await tester.tap(find.text(t.salle.quitter));
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.titre), findsWidgets);
    expect(Routes.controleurCompteRendu, '/controleur/compte-rendu');
  });
}
