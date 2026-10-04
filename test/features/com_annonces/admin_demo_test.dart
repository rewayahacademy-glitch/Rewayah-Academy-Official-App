// COM-ANN-2 : la demonstration de l'Administration des communications et du
// publieur de l'enseignant (`/demo/communications?voie=annonces&...`), hors
// production seulement. La VRAIE coquille Admin, des onglets qui restent dans
// la demonstration, des donnees marquees « Démonstration ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_planifiees.dart';
import 'package:rewayah_academy/features/com_annonces/file_moderation.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../router/support_routeur.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[...routesDemoCommunications('staging')],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await stabiliser(tester);
  return routeur;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  testWidgets('le choix du role mene a l Administration des communications', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoCommunications(VoieDemoCommunications.annonces),
      taille: const Size(390, 844),
    );
    expect(find.byKey(const ValueKey<String>('lien-publier')), findsOneWidget);
    await _toucher(
      tester,
      find.byKey(const ValueKey<String>('lien-administration')),
    );
    expect(routeur.state.uri.path, Routes.demoCommunications);
    expect(routeur.state.uri.queryParameters['ecran'], 'administration');
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(StatTile), findsNWidgets(4));
    expect(find.byType(MarqueDemonstration), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les onglets restent dans la demonstration', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      adresseAdministrationDemo(OngletCommunications.annonces),
    );
    await _toucher(
      tester,
      find.text(t.com.socle.navigation.ongletModeration).first,
    );
    expect(routeur.state.uri.path, Routes.demoCommunications);
    expect(routeur.state.uri.queryParameters['onglet'], 'moderation');
    expect(find.byType(FileModeration), findsOneWidget);
    expect(
      find.text(t.com.annonces.demoPublication.signalementAffilie),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la demonstration publie et la liste suit', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresseAdministrationDemo(OngletCommunications.annonces),
    );
    final int avant = tester
        .widget<StatTile>(find.byType(StatTile).first)
        .valeur;
    await _toucher(
      tester,
      find.byKey(AdministrationCommunicationsPage.cleNouvelle),
    );
    await tester.enterText(
      find.byKey(PublieurAnnonce.cleTitre),
      'Annonce de demonstration',
    );
    await tester.enterText(find.byKey(PublieurAnnonce.cleTexte), 'Texte.');
    await _toucher(tester, find.byKey(PublieurAnnonce.cleAction));
    await _toucher(
      tester,
      find.byKey(PublieurAnnonce.cleCible('demo-enseignants')),
    );
    for (int i = 0; i < 4; i++) {
      await _toucher(tester, find.byKey(PublieurAnnonce.cleAction));
    }
    expect(find.text(t.com.annonces.publieur.publiee), findsOneWidget);
    await _toucher(tester, find.byKey(PublieurAnnonce.cleAction));
    expect(
      tester.widget<StatTile>(find.byType(StatTile).first).valeur,
      avant + 1,
    );
    expect(find.text('Annonce de demonstration'), findsOneWidget);
  });

  testWidgets('le publieur de l enseignant : sa Classe, sans programmation', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adressePublierDemo(), taille: const Size(390, 844));
    expect(find.text(t.commun.etape.sur(n: 1, total: 4)), findsOneWidget);
    await tester.enterText(find.byKey(PublieurAnnonce.cleTitre), 'Titre');
    await tester.enterText(find.byKey(PublieurAnnonce.cleTexte), 'Texte');
    await _toucher(tester, find.byKey(PublieurAnnonce.cleAction));
    expect(
      find.text(
        t.com.annonces.publieur.contexte.audienceFixee(
          cible: t.com.annonces.demo.classeNour,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
