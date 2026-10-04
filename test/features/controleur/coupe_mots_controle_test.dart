// COUPE-MOTS-CTRL-1 (revue BENTO-3b-R, C7) : a 320 px et texte x2, le
// Controle coupait « Classe a observer maintenant » en pleine lettre
// (« Classe / a obser / ver mai / ntenan / t ») : le libelle partageait sa
// ligne avec la pastille « En direct ». Mesure par mot sur l'ecran ENTIER
// (carte, nom de la Classe, enseignant, notice, bouton, barre de
// navigation), dans chaque situation, en LTR et en RTL.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

Future<void> _monter(
  WidgetTester tester,
  EtatDemoControleur etat,
  TextDirection direction,
) async {
  // Haute, comme la capture de BENTO-3 : rien n'est hors de la vue.
  tester.view.physicalSize = const Size(320, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoControleur(
      EcranDemoControleur.controle,
      etat: etat,
    ),
    routes: routesDemoControleur('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext c, Widget? app) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(textDirection: direction, child: app!),
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(ControleControleurPage), findsOneWidget);
}

void main() {
  // En VRAIES polices : la police de test (carres de 1 em) couperait des
  // mots que le vrai rendu garde entiers.
  setUpAll(chargerPolicesDuDepot);
  for (final TextDirection direction in TextDirection.values) {
    for (final EtatDemoControleur etat in EtatDemoControleur.values) {
      testWidgets('Controle ${etat.name}, 320 px, texte x2, ${direction.name} '
          ': aucun mot coupe', (WidgetTester tester) async {
        await _monter(tester, etat, direction);
        expect(tester.takeException(), isNull);
        // « Classe An- / Nour » passe a la ligne apres le trait d'union,
        // comme le fait le moteur de texte : chaque partie reste entiere.
        expect(find.byType(Scaffold), findsWidgets);
        expect(
          motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
          isEmpty,
          reason: 'Un mot coupe ou tronque',
        );
      });
    }

    testWidgets('en direct, ${direction.name} : le libelle entier, la '
        'pastille sous lui quand la ligne ne suffit pas', (
      WidgetTester tester,
    ) async {
      await _monter(tester, EtatDemoControleur.enDirect, direction);
      final Finder libelle = find.text(t.controleur.controle.missionEnDirect);
      expect(libelle, findsOneWidget);
      verifierAucunMotCoupe(tester, libelle);
    });
  }
}
