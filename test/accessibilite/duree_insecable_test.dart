// DUREE-INSECABLE-1 : une duree ne se scinde jamais sur deux lignes.
//
// « Cours dans 3 h / 28 », « 2 h / 59 », « 45 / min » a 320 px et texte x2
// (carte de seance `CarteSession`, Accueil famille, Accueil Mode
// Accessibilite). Le formatage partage des durees (`LibellesGroupe`) pose des
// espaces insecables entre le nombre et son unite ; la phrase passe a la
// ligne AVANT la duree, jamais dedans.
//
// Mesure en vraies polices : chaque duree rendue occupe une seule ligne
// (`mesurerDurees`, `test/support/aucun_mot_coupe.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/journee.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/timeline_row.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_accessibilite.dart';
import 'package:rewayah_academy/features/classe_tuteur/bloc_observation_classe.dart'
    show dureeVisite;
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart'
    show dureeLisible;
import 'package:rewayah_academy/features/tc_classe_live/entete_classe.dart'
    show libelleTempsRestant;
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../router/support_routeur.dart' show stabiliser;
import '../support/aucun_mot_coupe.dart';
import '../teaching_core/fixtures/fixtures_horloge.dart';

/// Les espaces ou une ligne peut se couper.
final RegExp _espaceSecable = RegExp('[ \t\n]');

/// La duree contenue dans [texte], telle que rendue.
String _duree(String texte) {
  final RegExpMatch? m = motifDuree.firstMatch(texte);
  expect(m, isNotNull, reason: 'Aucune duree dans « $texte »');
  return m!.group(0)!;
}

void main() {
  group('Le formatage partage des durees', () {
    for (final Duration d in const <Duration>[
      Duration(hours: 3, minutes: 28),
      Duration(hours: 2, minutes: 59),
      Duration(hours: 2),
      Duration(minutes: 45),
      Duration(minutes: 5),
    ]) {
      test('${d.inMinutes} min : aucun espace secable dans la duree', () {
        for (final String texte in <String>[
          LibellesGroupe.dureeLisible(d),
          LibellesGroupe.compteARebours(d),
          LibellesGroupe.tempsRestant(d),
          t.classe.entree.coursDans(duree: LibellesGroupe.dureeLisible(d)),
        ]) {
          expect(
            _duree(texte).contains(_espaceSecable),
            isFalse,
            reason: '« $texte » peut se couper dans sa duree',
          );
        }
      });
    }

    test('3 h 28 : la phrase reste secable AVANT la duree, pas dedans', () {
      final String texte = LibellesGroupe.compteARebours(
        const Duration(hours: 3, minutes: 28),
      );
      // « Cours dans » peut passer a la ligne avant « 3 h 28 », jamais
      // apres « 3 h ».
      expect(texte, 'Cours dans 3\u00A0h\u00A028');
    });

    test('insecable : seules les durees sont touchees', () {
      expect(
        LibellesGroupe.insecable('Cours dans 3 h 28'),
        'Cours dans 3\u00A0h\u00A028',
      );
      expect(LibellesGroupe.insecable('Dans 45 min'), 'Dans 45\u00A0min');
      expect(LibellesGroupe.insecable('Reste 2 h'), 'Reste 2\u00A0h');
      expect(LibellesGroupe.insecable('Séance en direct'), 'Séance en direct');
    });
  });

  group('Les autres formateurs de durees passent par insecable', () {
    test('historique : dureeLisible', () {
      for (final Duration d in const <Duration>[
        Duration(seconds: 48),
        Duration(minutes: 2),
        Duration(seconds: 102),
        Duration(hours: 1),
        Duration(minutes: 65),
      ]) {
        final String texte = dureeLisible(d);
        expect(texte.contains(_espaceSecable), isFalse, reason: texte);
      }
    });

    test('observation de classe : dureeVisite', () {
      for (final Duration d in const <Duration>[
        Duration(seconds: 40),
        Duration(minutes: 2),
        Duration(seconds: 80),
      ]) {
        final String texte = dureeVisite(d);
        expect(texte.contains(_espaceSecable), isFalse, reason: texte);
      }
    });

    testWidgets('journee de l enseignant : TimelineRow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Scaffold(
              body: TimelineRow(
                entree: EntreeJournee.pause(
                  debut: DateTime(2026, 10, 4, 10),
                  fin: DateTime(2026, 10, 4, 10, 45),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('45\u00A0min'), findsOneWidget);
    });

    test('en-tete de la classe : libelleTempsRestant', () {
      for (final Duration avantFin in const <Duration>[
        Duration(minutes: 45),
        Duration(hours: 1, minutes: 20),
      ]) {
        final String? texte = libelleTempsRestant(
          horlogeSeance(
            maintenant: debutSeanceAvantDst.add(dureeSeance).subtract(avantFin),
          ),
        );
        expect(texte, isNotNull);
        expect(_duree(texte!).contains(_espaceSecable), isFalse, reason: texte);
      }
    });
  });

  group('TexteSansCoupure : une duree insecable est un seul mot', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('la mesure ne coupe pas aux espaces insecables', (
      WidgetTester tester,
    ) async {
      late double duree;
      late double nombre;
      late double phrase;
      late double cours;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext context) {
              const TextScaler x2 = TextScaler.linear(2);
              duree = largeurMotLePlusLong(
                context,
                '3\u00A0h\u00A028',
                null,
                x2,
              );
              nombre = largeurMotLePlusLong(context, '28', null, x2);
              phrase = largeurMotLePlusLong(
                context,
                'Cours dans 3\u00A0h\u00A028',
                null,
                x2,
              );
              cours = largeurMotLePlusLong(context, 'Cours', null, x2);
              return const SizedBox();
            },
          ),
        ),
      );
      // « 3 h 28 » insecable est mesure d'un bloc, plus large que « 28 »
      // seul ; dans la phrase, c'est lui le mot le plus long, pas « Cours ».
      expect(duree, greaterThan(nombre * 2));
      expect(phrase, duree);
      expect(phrase, greaterThan(cours));
    });

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} : l echelle est bornee pour que la duree '
          'entiere tienne', (WidgetTester tester) async {
        const String texte = 'Cours dans 3\u00A0h\u00A028';
        late double motDuree;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: sens,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Builder(
                  builder: (BuildContext context) {
                    motDuree = largeurMotLePlusLong(
                      context,
                      '3\u00A0h\u00A028',
                      null,
                      const TextScaler.linear(1),
                    );
                    // Plus etroit que la duree a x2, assez large a x1,7.
                    return SizedBox(
                      width: motDuree * 1.7 + 4,
                      child: const TexteSansCoupure(texte),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        final Text rendu = tester.widget<Text>(find.text(texte));
        expect(motDuree, greaterThan(0));
        expect(rendu.textScaler!.scale(10), lessThan(20));
        final ({List<String> mesurees, List<String> coupees}) r = mesurerDurees(
          tester,
          find.byType(TexteSansCoupure),
        );
        expect(r.mesurees, hasLength(1));
        expect(r.coupees, isEmpty);
      });
    }
  });

  group('Une duree tient sur une ligne (vraies polices)', () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      for (final Duration d in const <Duration>[
        Duration(hours: 3, minutes: 28),
        Duration(hours: 2, minutes: 59),
        Duration(minutes: 45),
      ]) {
        testWidgets('${sens.name}, ${d.inMinutes} min, texte x2, de 120 a '
            '320 px', (WidgetTester tester) async {
          final String texte = LibellesGroupe.compteARebours(d);
          for (double largeur = 120; largeur <= 320; largeur += 4) {
            await tester.pumpWidget(
              TranslationProvider(
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: MaterialApp(
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    home: Directionality(
                      textDirection: sens,
                      child: Scaffold(
                        body: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: SizedBox(width: largeur, child: Text(texte)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final ({List<String> mesurees, List<String> coupees}) r =
                mesurerDurees(tester, find.byType(Scaffold));
            expect(r.mesurees, hasLength(1));
            expect(r.coupees, isEmpty, reason: 'a $largeur px');
          }
        });
      }
    }
  });

  group('Accueil Mode Accessibilite et CarteSession, 320 px texte x2', () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} : chaque duree sur une ligne, aucun mot '
          'coupe dans la carte de seance', (WidgetTester tester) async {
        const Size taille = Size(320, 3000);
        tester.view.physicalSize = taille;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final GoRouter routeur = GoRouter(
          initialLocation: adresseDemoAccessibilite(
            EleveDemoAccessibilite.mariam,
          ),
          routes: routesDemoAccessibilite('local'),
        );
        addTearDown(routeur.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MediaQuery(
                data: const MediaQueryData(
                  size: taille,
                  textScaler: TextScaler.linear(2),
                ),
                child: MaterialApp.router(
                  routerConfig: routeur,
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  locale: AppLocale.fr.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  builder: (BuildContext _, Widget? app) =>
                      Directionality(textDirection: sens, child: app!),
                ),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.eleve.accueil),
          ),
        );
        await stabiliser(tester);
        expect(find.byType(AccueilAccessibilite), findsOneWidget);
        final Finder carte = find.byType(CarteSession);
        expect(carte, findsOneWidget);
        verifierDureesSurUneLigne(tester, carte);
        verifierAucunMotCoupe(tester, carte);
        verifierDureesSurUneLigne(tester, find.byType(AccueilAccessibilite));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
