// MA-6 : apres la seance, en Mode Accessibilite. On ouvre la VRAIE route de
// demonstration /demo/accessibilite au moment « apres » : l'ecran « apres la
// seance » (resultat, un seul bouton dominant, travail, support, prochaine
// seance, aide), sans « Tres bien ! » ni message de l'enseignante ; on tape
// l'action principale (« Retour a la Classe ») : on arrive sur Ma classe.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_eleve/apres_seance_accessibilite.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import '../../router/support_routeur.dart' show stabiliser;

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  EleveDemoAccessibilite eleve,
  double echelle,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoAccessibilite(
      eleve,
      moment: MomentDemoAccessibilite.apres,
    ),
    routes: routesDemoAccessibilite('local'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp.router(
            routerConfig: routeur,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  for (final (Size taille, double echelle) in <(Size, double)>[
    (const Size(390, 844), 1),
    (const Size(390, 844), 2),
    (const Size(1440, 900), 1),
  ]) {
    for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
      final bool mineur = DonneesAccessibiliteDemo.mineur(eleve);
      testWidgets(
        'MA-6 : ${eleve.name}, ${taille.width.toInt()}, texte x$echelle : '
        'apres la seance, puis « Retour a la Classe »',
        (WidgetTester tester) async {
          await _monter(tester, taille, eleve, echelle);
          expect(find.byType(ApresSeanceAccessibilite), findsOneWidget);
          expect(find.text(t.salle.fin.titreGuidee), findsOneWidget);
          // Tutoiement selon l'age.
          expect(
            find.text(t.accessibilite.tutoiement.finPhrase),
            mineur ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(t.salle.fin.phrase),
            mineur ? findsNothing : findsOneWidget,
          );
          // Un seul bouton dominant ; aucun jugement, aucun message.
          expect(find.byType(ActionPrincipale), findsOneWidget);
          expect(find.textContaining('Très bien'), findsNothing);
          expect(find.textContaining('Message de'), findsNothing);
          // Ordre : resultat, travail, support, prochaine seance, aide.
          final List<Finder> ordre = <Finder>[
            find.byKey(ApresSeanceAccessibilite.cleRetourClasse),
            find.text(LibellesGroupe.avantProchainCours),
            find.text(t.accessibilite.apres.revoirSupport),
            find.text(t.accessibilite.accueil.prochaineSeance),
            find.text(t.accessibilite.accueil.aide),
          ];
          for (int i = 1; i < ordre.length; i++) {
            expect(ordre[i], findsOneWidget);
            expect(
              tester.getTopLeft(ordre[i]).dy,
              greaterThan(tester.getTopLeft(ordre[i - 1]).dy),
            );
          }

          final Finder retour = find.byKey(
            ApresSeanceAccessibilite.cleRetourClasse,
          );
          await tester.ensureVisible(retour);
          await tester.tap(retour);
          await stabiliser(tester);
          expect(find.byType(ApresSeanceAccessibilite), findsNothing);
          expect(
            tester.widget<NavShell>(find.byType(NavShell)).indexActif,
            EcranAccessibiliteDemo.indexMaClasse,
          );
          expect(find.byType(EspaceGroupePage), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
