// CT-1b : /demo/controleur n'existe pas en production, et monte la VRAIE
// coquille controleur (quatre destinations, C13) sur les donnees de
// demonstration. Chaque destination se tape depuis la coquille.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/planning_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

void main() {
  test('/demo/controleur absente en production, presente ailleurs', () {
    expect(routesDemoControleur('production'), isEmpty);
    expect(routesDemoControleur(' Production '), isEmpty);
    expect(routesDemoControleur(''), isEmpty);
    expect(routesDemoControleur('development'), hasLength(1));
  });

  test('la porte ne laisse passer /demo/controleur que hors production', () {
    String? decider(String environnement) => deciderRedirection(
      session: const SessionState.deconnecte(),
      cheminDemande: Routes.demoControleur,
      maintenant: DateTime.utc(2026, 9, 27),
      environnement: environnement,
    );
    expect(decider('production'), isNotNull);
    expect(decider('development'), isNull);
  });

  test('les donnees de demonstration sont coherentes (C1, C8, C19)', () {
    // Aucune mission, puis la meme seance d'An-Nour dans chaque etat.
    expect(DonneesControleurDemo.mission(EtatDemoControleur.aucune), isNull);
    final Map<EtatDemoControleur, EtatMissionDemo> etats =
        <EtatDemoControleur, EtatMissionDemo>{
          EtatDemoControleur.pasEncoreEnDirect: EtatMissionDemo.prevue,
          EtatDemoControleur.enDirect: EtatMissionDemo.enDirect,
          EtatDemoControleur.indisponible: EtatMissionDemo.indisponible,
        };
    for (final MapEntry<EtatDemoControleur, EtatMissionDemo> e
        in etats.entries) {
      final MissionControleurDemo m = DonneesControleurDemo.mission(e.key)!;
      expect(m.etat, e.value);
      expect(m.classe, 'Classe An-Nour');
      expect(m.enseignant, 'Ibrahim');
      expect(m.nombreEleves, DonneesControleurDemo.roster.length);
      expect(m.debut.year, 2026);
    }
    // En direct : l'instant de la demonstration tombe pendant la seance.
    final MissionControleurDemo direct = DonneesControleurDemo.mission(
      EtatDemoControleur.enDirect,
    )!;
    expect(DonneesControleurDemo.maintenant.isAfter(direct.debut), isTrue);
    expect(DonneesControleurDemo.maintenant.isBefore(direct.finPrevue), isTrue);
    // Faits : la seance en direct n'a pas de fin reelle, la seance finie si.
    expect(DonneesControleurDemo.faitsEnDirect.finReelle, isNull);
    expect(DonneesControleurDemo.faitsSeanceFinie.finReelle, isNotNull);
    expect(DonneesControleurDemo.faitsSeanceFinie.minutesDeRetard, 8);
    // Un rapport par statut du doc CTR-05.
    expect(
      DonneesControleurDemo.rapports.map((RapportControleurDemo r) => r.statut),
      unorderedEquals(StatutRapportDemo.values),
    );
    // Les fils ne citent aucun prenom d'eleve (C8).
    for (final FilAdminDemo f in DonneesControleurDemo.fils) {
      for (final MessageFilDemo m in f.messages) {
        for (final String prenom in DonneesControleurDemo.roster) {
          expect(m.texte.contains(prenom), isFalse, reason: f.id);
        }
      }
    }
    // Trois profils ; l'Enseignant-Controleur n'a jamais sa propre Classe.
    expect(
      DonneesControleurDemo.profils.map((ControleurDemo p) => p.profil),
      ProfilDemoControleur.values,
    );
  });

  Future<GoRouter> monter(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
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

  testWidgets('la liste propose chaque ecran x situation', (
    WidgetTester tester,
  ) async {
    await monter(tester, Routes.demoControleur);
    for (final EcranDemoControleur ecran in EcranDemoControleur.values) {
      for (final EtatDemoControleur etat in EtatDemoControleur.values) {
        expect(
          find.byKey(ValueKey<String>('lien-${ecran.name}-${etat.name}')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('chacune des quatre destinations se tape depuis la coquille', (
    WidgetTester tester,
  ) async {
    // Une tablette (rail, 600 a 1199) de hauteur realiste : le planning
    // global, remplace en CT-2, ne tient pas sous 600 de haut.
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GoRouter routeur = await monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.controle),
    );
    expect(find.byType(PlanningControleurPage), findsOneWidget);
    final NavShell depart = tester.widget<NavShell>(find.byType(NavShell));
    expect(depart.destinations, hasLength(4));
    expect(depart.indexActif, 0);

    // Depuis la VRAIE coquille, on tape chaque destination dans l'ordre C13,
    // puis on revient a Controle.
    final List<(String, EcranDemoControleur, Type)> parcours =
        <(String, EcranDemoControleur, Type)>[
          (
            t.nav.controleur.historique,
            EcranDemoControleur.historique,
            HistoriqueControleurPage,
          ),
          (
            t.nav.controleur.echanges,
            EcranDemoControleur.echanges,
            EchangesControleurPage,
          ),
          (t.nav.controleur.compte, EcranDemoControleur.compte, ComptePage),
          (
            t.nav.controleur.controle,
            EcranDemoControleur.controle,
            PlanningControleurPage,
          ),
        ];
    for (final (String libelle, EcranDemoControleur ecran, Type page)
        in parcours) {
      await tester.tap(
        find.descendant(
          of: find.byKey(NavShell.railKey),
          matching: find.text(libelle),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        routeur.state.uri.queryParameters['ecran'],
        ecran.name,
        reason: libelle,
      );
      expect(find.byType(page), findsOneWidget, reason: libelle);
      final NavShell coquille = tester.widget<NavShell>(find.byType(NavShell));
      expect(coquille.indexActif, ecran.index, reason: libelle);
    }
  });
}
