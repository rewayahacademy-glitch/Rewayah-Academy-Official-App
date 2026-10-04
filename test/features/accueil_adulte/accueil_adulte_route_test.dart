// DASH-EA-PROD : l'Accueil de l'eleve adulte sur sa route reelle
// (`/eleve/adulte`), atteint depuis la VRAIE navigation (K-07) : le vrai
// routeur, une session d'eleve, la capacite « accueil adulte » servie par le
// double de demonstration. Puis « Voir tout » des dernieres seances, la page
// d'historique, et les cinq etats de chacune. Contre-epreuve : sans double
// (production), `/eleve` ne change pas et rien n'est invente.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/historique_seances_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/routes_accueil_adulte.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show lieu;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import 'support_accueil_adulte_route.dart';

/// Le lien « Voir tout » des dernieres seances, dans leur tuile.
Finder _voirToutSeances() => find.descendant(
  of: find
      .ancestor(
        of: find.text(t.adulte.accueil.dernieresSeances),
        matching: find.byType(Column),
      )
      .first,
  matching: find.widgetWithText(ActionPrincipale, t.tuteur.accueil.voirTout),
);

bool _nature(Widget w, NatureEtat n) => w is EtatSysteme && w.nature == n;

void main() {
  test('redirection : la capacite seule decide, jamais le role', () {
    expect(
      redirectionAccueilEleve(capaciteAccueilAdulte: true),
      Routes.eleveAdulte,
    );
    expect(redirectionAccueilEleve(capaciteAccueilAdulte: false), isNull);
  });

  group('vraie navigation (K-07)', () {
    testWidgets('capacite servie : /eleve ouvre l\'Accueil adulte, la '
        'destination Accueil reste allumee', (WidgetTester tester) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          accueil: Valeur(accueilDemo()),
          historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
        ),
        depart: Routes.eleve,
      );
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(find.byType(AccueilElevePage), findsNothing);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
      expect(
        find.text(t.adulte.accueil.salutation(prenom: 'Mamadou')),
        findsOneWidget,
      );
      // Pas de centre de notifications pour l'eleve : pas de cloche inerte.
      expect(find.byType(ClocheNotifications), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('« Voir tout » ouvre l\'historique, le retour ramene a '
        'l\'Accueil', (WidgetTester tester) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          accueil: Valeur(accueilDemo()),
          historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
        ),
        depart: Routes.eleve,
      );
      final Finder lien = _voirToutSeances();
      await tester.scrollUntilVisible(
        lien,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(lien);
      await stabiliserTest(tester);

      expect(lieu(routeur), Routes.eleveAdulteSeances);
      expect(find.byType(HistoriqueSeancesAdultePage), findsOneWidget);
      expect(find.text(t.adulte.historique.titre), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
      for (final SeancePasseeAdulte s
          in DonneesAdulteDemo.historiqueSeances()) {
        await tester.scrollUntilVisible(
          find.text(s.dateRendue),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(s.dateRendue), findsOneWidget);
      }
      // Une seule absence dans l'historique, comme dans les donnees.
      expect(find.text(t.adulte.accueil.absence), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliserTest(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
    });

    testWidgets('contre-epreuve, production : sans source, /eleve garde '
        'l\'accueil de l\'eleve', (WidgetTester tester) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(),
        depart: Routes.eleve,
      );
      expect(lieu(routeur), Routes.eleve);
      expect(find.byType(AccueilElevePage), findsOneWidget);
      expect(find.byType(AccueilAdultePage), findsNothing);
    });

    testWidgets('contre-epreuve, production : /eleve/adulte par adresse dit '
        '« indisponible », sans « Reessayer » ni lien', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(),
        depart: Routes.eleveAdulte,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => _nature(w, NatureEtat.indisponible),
        ),
        findsOneWidget,
      );
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(find.text(t.adulte.accueil.dernieresSeances), findsNothing);
      // Aucune ligne de squelette ne reste au-dessus de l'etat.
      expect(find.byType(Skeleton), findsNothing);
      expect(find.text(t.tuteur.accueil.voirTout), findsNothing);
    });

    testWidgets('contre-epreuve : sans destination, aucun « Voir tout » des '
        'dernieres seances (D9)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: surchargesAccueilAdulte(accueil: Valeur(accueilDemo())),
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const AccueilAdultePage(),
            ),
          ),
        ),
      );
      await stabiliserTest(tester);
      expect(find.text(t.adulte.accueil.dernieresSeances), findsOneWidget);
      expect(_voirToutSeances(), findsNothing);
    });
  });

  group('Accueil adulte : etats sur la route reelle', () {
    testWidgets('chargement : squelette en grille Bento, aucune donnee', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          accueil: const Attente<AccueilAdulteVM>(),
        ),
        depart: Routes.eleveAdulte,
      );
      expect(find.byType(SqueletteAccueilAdulte), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SqueletteAccueilAdulte),
          matching: find.byType(GrilleBento),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SqueletteAccueilAdulte),
          matching: find.byType(Skeleton),
        ),
        findsNWidgets(5),
      );
      expect(find.text(DonneesAdulteDemo.ligneParcours), findsNothing);
    });

    testWidgets('bureau : le squelette met seance et « Avant » cote a cote', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        taille: const Size(1440, 1000),
        surcharges: surchargesAccueilAdulte(
          accueil: const Attente<AccueilAdulteVM>(),
        ),
        depart: Routes.eleveAdulte,
      );
      final List<Rect> blocs = <Rect>[
        for (final Element e
            in find
                .descendant(
                  of: find.byType(SqueletteAccueilAdulte),
                  matching: find.byType(Skeleton),
                )
                .evaluate())
          (e.renderObject! as RenderBox).localToGlobal(Offset.zero) &
              (e.renderObject! as RenderBox).size,
      ];
      expect(blocs[1].left, greaterThan(blocs[0].left));
      expect(blocs[1].top, moreOrLessEquals(blocs[0].top));
      // « Mon parcours » prend toute la largeur, sous elles.
      expect(blocs[2].width, greaterThan(blocs[0].width));
    });

    testWidgets('vide : aucune classe, etat subi sans bouton', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          accueil: const Valeur(AccueilAdulteVM(prenom: 'Mamadou')),
        ),
        depart: Routes.eleve,
      );
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(find.text(t.adulte.accueil.aucuneClasse), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('erreur (K-59) : ce qui manque, la cause, « Reessayer »', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          accueil: const Echec<AccueilAdulteVM>(),
        ),
        depart: Routes.eleveAdulte,
      );
      expect(find.text(t.adulte.accueil.echec), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsOneWidget);
      expect(find.text(DonneesAdulteDemo.ligneParcours), findsNothing);
    });

    testWidgets('hors ligne : l\'echec se dit « hors ligne »', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          accueil: const Echec<AccueilAdulteVM>(),
          horsLigne: true,
        ),
        depart: Routes.eleveAdulte,
      );
      expect(
        find.byWidgetPredicate((Widget w) => _nature(w, NatureEtat.horsLigne)),
        findsOneWidget,
      );
      expect(find.text(t.adulte.accueil.echec), findsNothing);
    });
  });

  group('Historique : etats sur la route reelle', () {
    testWidgets('chargement : squelette de liste', (WidgetTester tester) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          historique: const Attente<List<SeancePasseeAdulte>>(),
        ),
        depart: Routes.eleveAdulteSeances,
      );
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.text(t.adulte.historique.titre), findsOneWidget);
    });

    testWidgets('vide : phrase et detail, sans bouton', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          historique: const Valeur(<SeancePasseeAdulte>[]),
        ),
        depart: Routes.eleveAdulteSeances,
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(t.adulte.historique.vide), findsOneWidget);
      expect(find.text(t.adulte.historique.videDetail), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('erreur (K-59) : « Reessayer » relit l\'historique', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          historique: const Echec<List<SeancePasseeAdulte>>(),
        ),
        depart: Routes.eleveAdulteSeances,
      );
      expect(find.text(t.adulte.historique.echec), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsOneWidget);
    });

    testWidgets('hors ligne', (WidgetTester tester) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(
          historique: const Echec<List<SeancePasseeAdulte>>(),
          horsLigne: true,
        ),
        depart: Routes.eleveAdulteSeances,
      );
      expect(
        find.byWidgetPredicate((Widget w) => _nature(w, NatureEtat.horsLigne)),
        findsOneWidget,
      );
    });

    testWidgets('production : indisponible, rien d\'invente', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        surcharges: surchargesAccueilAdulte(),
        depart: Routes.eleveAdulteSeances,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => _nature(w, NatureEtat.indisponible),
        ),
        findsOneWidget,
      );
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(find.text(t.adulte.accueil.absence), findsNothing);
    });
  });

  // Mesure avec les vraies polices du depot.
  group('aucun mot coupe : 320 x2 et 1440, LTR et RTL', () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, Size taille, double echelle)
        in <(String, Size, double)>[
          ('320 x2', const Size(320, 5200), 2),
          ('1440', const Size(1440, 1600), 1),
        ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('Accueil $nom ${sens.name}', (WidgetTester tester) async {
          await monterAccueilAdulteReel(
            tester,
            taille: taille,
            echelle: echelle,
            direction: sens,
            surcharges: surchargesAccueilAdulte(accueil: Valeur(accueilDemo())),
            depart: Routes.eleve,
          );
          expect(find.byType(AccueilAdultePage), findsOneWidget);
          expect(_voirToutSeances(), findsOneWidget);
          verifierEcranSansMotCoupe(tester);
          verifierUnSeulBoutonPlein(tester);
          expect(tester.takeException(), isNull);
        });

        testWidgets('Historique $nom ${sens.name}', (
          WidgetTester tester,
        ) async {
          await monterAccueilAdulteReel(
            tester,
            taille: taille,
            echelle: echelle,
            direction: sens,
            surcharges: surchargesAccueilAdulte(
              historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
            ),
            depart: Routes.eleveAdulteSeances,
          );
          expect(find.byType(HistoriqueSeancesAdultePage), findsOneWidget);
          verifierEcranSansMotCoupe(tester);
          expect(tester.takeException(), isNull);
        });

        testWidgets('Etats $nom ${sens.name}', (WidgetTester tester) async {
          for (final String depart in <String>[
            Routes.eleveAdulte,
            Routes.eleveAdulteSeances,
          ]) {
            await monterAccueilAdulteReel(
              tester,
              taille: taille,
              echelle: echelle,
              direction: sens,
              surcharges: surchargesAccueilAdulte(
                accueil: const Echec<AccueilAdulteVM>(),
                historique: const Echec<List<SeancePasseeAdulte>>(),
              ),
              depart: depart,
            );
            verifierEcranSansMotCoupe(tester);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

/// Laisse passer la navigation et les fondus.
Future<void> stabiliserTest(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
