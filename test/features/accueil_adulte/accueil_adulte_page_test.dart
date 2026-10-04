// EA-2 : l'accueil de l'eleve adulte, atteint depuis la VRAIE coquille adulte
// en tapant la VRAIE destination « Accueil » (K-07), puis ses etats.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart'
    show EcranPreparationEleveDemo, routesDemoClasse, surchargesEleveDemo;
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';

/// Aucune action avant le prochain cours.
class _AucunTravail implements PortTravailAVenir {
  const _AucunTravail();

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => const <SlotAction>[];
}

void main() {
  Widget app({required Widget child, List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: child,
          ),
        ),
      );

  Future<void> monterCoquille(
    WidgetTester tester,
    String depart, {
    double echelle = 1,
    TextDirection? direction,
  }) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAdulte('dev'),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            // Sans echelle ni sens demandes, l'application reste telle quelle.
            builder: echelle == 1 && direction == null
                ? null
                : (BuildContext c, Widget? app) => MediaQuery(
                    data: MediaQuery.of(c)
                        .copyWith(textScaler: TextScaler.linear(echelle)),
                    child: Directionality(
                      textDirection: direction ?? TextDirection.ltr,
                      child: app!,
                    ),
                  ),
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('la destination Accueil de la coquille ouvre le vrai accueil', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.monEspace));
    expect(find.byType(AccueilAdultePage), findsNothing);

    await tester.tap(find.text(t.adulte.nav.accueil).first);
    await tester.pumpAndSettle();

    expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(
      find.text(t.adulte.accueil.salutation(prenom: 'Mamadou')),
      findsOneWidget,
    );
    expect(find.text(t.adulte.accueil.prochaineSeance), findsOneWidget);
    expect(find.byType(CarteSession), findsOneWidget);
    // Avant le prochain cours : trois actions au plus, celles des donnees.
    expect(find.byType(EmplacementAvantProchainCours), findsOneWidget);
    for (final a in DonneesClasseDemo.actions) {
      expect(find.text(a.libelle), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byType(BlocBibliotheque),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(DonneesAdulteDemo.ligneParcours), findsOneWidget);
    // K-42 point 4 : chaque seance passee, sa date puis une seule ligne ; la
    // Classe et l'enseignant ne sont pas repetes.
    final Finder dernieres = find.byKey(
      const ValueKey<String>('accueil-adulte-dernieres'),
    );
    for (final SeancePasseeAdulte s in DonneesAdulteDemo.dernieresSeances()) {
      expect(
        find.descendant(of: dernieres, matching: find.text(s.dateRendue)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: dernieres,
        matching: find.text(DonneesClasseDemo.classe),
      ),
      findsNothing,
    );
    // Une seule absence porte une pastille ; une presence n'en porte pas.
    expect(
      find.widgetWithText(StatusPill, t.adulte.accueil.absence),
      findsOneWidget,
    );
    expect(find.text(t.adulte.accueil.ressources), findsOneWidget);
  });

  // Mesure avec les vraies polices du depot : la police de test par defaut
  // donne a chaque glyphe la largeur d'un carre.
  group('polices du depot', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('390 : la salutation tient sur une ligne, sans photo', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
      final Finder titre = find.text(
        t.adulte.accueil.salutation(prenom: 'Mamadou'),
      );
      final double police = tester.widget<Text>(titre).style!.fontSize!;
      expect(tester.getSize(titre).height, lessThan(police * 2));
      expect(find.byType(PhotoEleve), findsNothing);
    });
  });

  testWidgets('bureau : seance et « Avant » cote a cote, a la meme hauteur', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    final Offset seance = tester.getTopLeft(
      find.byKey(const ValueKey<String>('accueil-adulte-prochaine-seance')),
    );
    final Offset avant = tester.getTopLeft(
      find.byType(EmplacementAvantProchainCours),
    );
    expect(avant.dx, greaterThan(seance.dx));
    expect(avant.dy, moreOrLessEquals(seance.dy));
  });

  testWidgets('porte ouverte : le bouton de l\'emplacement mene a la '
      'preparation', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = GoRouter(
      initialLocation: adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        seance: EtatDemoClasse.fenetreOuverte,
      ),
      routes: <RouteBase>[
        ...routesDemoAdulte('dev'),
        ...routesDemoClasse('dev'),
      ],
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
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder bouton = find.descendant(
      of: find.byType(EmplacementEntreeVue),
      matching: find.byType(ActionPrincipale),
    );
    expect(bouton, findsOneWidget);
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.byType(EcranPreparationEleveDemo), findsOneWidget);
    expect(find.byType(AccueilAdultePage), findsNothing);
  });

  testWidgets('vue du second adulte : jamais la Classe du titulaire, '
      'l\'accueil est indisponible (EA-BR-13, EA-5)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(
      find.text(t.adulte.accueil.salutation(prenom: 'Mamadou')),
      findsNothing,
    );
    expect(find.byType(CarteSession), findsNothing);
    expect(find.text(DonneesAdulteDemo.ligneParcours), findsNothing);
  });

  testWidgets(
    'hors ligne : la ligne d\'etat de l\'emplacement, pas de bouton',
    (WidgetTester tester) async {
      taille(tester, const Size(390, 844));
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.accueil,
          seance: EtatDemoClasse.horsLigne,
        ),
      );
      expect(find.text(t.classe.entree.horsLigne), findsOneWidget);
      expect(find.text(t.classe.entree.rejoindre), findsNothing);
    },
  );

  bool estHorsLigne(Widget w) =>
      w is EtatSysteme && w.nature == NatureEtat.horsLigne;

  testWidgets('reseau coupe (revue EA-R M5) : depuis la liste de la vraie '
      'route, l\'Accueil dit « hors ligne », la cloche reste', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, Routes.demoAdulte);
    final Finder lien = find.byKey(const ValueKey<String>('lien-reseau-coupe'));
    expect(find.text(t.adulte.demo.reseauCoupe), findsOneWidget);
    await tester.ensureVisible(lien);
    await tester.tap(lien);
    await tester.pumpAndSettle();

    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(find.byWidgetPredicate(estHorsLigne), findsOneWidget);
    expect(find.text(t.commun.etats.horsLigne.titre), findsOneWidget);
    expect(find.text(t.commun.etats.echecServeur.titre), findsNothing);
    expect(find.byType(CarteSession), findsNothing);
    expect(find.byType(ClocheNotifications), findsOneWidget);
  });

  testWidgets('sans « reseau=coupe » : l\'Accueil est inchange, aucun etat '
      'hors ligne', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    expect(
      adresseDemoAdulte(EcranDemoAdulte.accueil),
      isNot(contains('reseau')),
    );
    expect(find.byWidgetPredicate(estHorsLigne), findsNothing);
    expect(
      find.text(t.adulte.accueil.salutation(prenom: 'Mamadou')),
      findsOneWidget,
    );
    expect(find.byType(CarteSession), findsOneWidget);
  });

  testWidgets('hors ligne et capacite absente : reste indisponible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.byWidgetPredicate(estHorsLigne), findsNothing);
  });

  testWidgets('chargement : le squelette de la carte de seance', (
    WidgetTester tester,
  ) async {
    final Completer<AccueilAdulteVM> jamais = Completer<AccueilAdulteVM>();
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          accueilAdulteProvider.overrideWith((Ref _) => jamais.future),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(SqueletteCarteSession), findsOneWidget);
    // L'en-tete garde sa place : la cloche est deja posee.
    expect(find.byType(ClocheNotifications), findsOneWidget);
    expect(find.byType(CarteSession), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('erreur : « Reessayer », et rien d\'invente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          accueilAdulteProvider.overrideWith(
            (Ref _) => Future<AccueilAdulteVM>.error(StateError('reseau')),
          ),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.commun.reessayer), findsWidgets);
    expect(find.byType(CarteSession), findsNothing);
  });

  testWidgets('sans source serveur : indisponible, sans « Reessayer »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(child: const AccueilAdultePage()));
    await tester.pumpAndSettle();
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsNothing);
    expect(find.byType(CarteSession), findsNothing);
  });

  testWidgets('vide : aucune classe, un etat subi sans bouton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      app(
        overrides: <Override>[
          accueilAdulteProvider.overrideWith(
            (Ref _) async => const AccueilAdulteVM(prenom: 'Mamadou'),
          ),
        ],
        child: const AccueilAdultePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.accueil.aucuneClasse), findsOneWidget);
    expect(find.byType(CarteSession), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('accueil-adulte-dernieres')),
      findsNothing,
    );
  });

  // BENTO-3 : la grille Bento de DASH_STRATEGIE.md §3.7.
  group('BENTO-3 : grille Bento', () {
    testWidgets('vrai routeur : depuis /demo/adulte, le lien Accueil tape '
        'ouvre l\'accueil sur la grille Bento', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late GoRouter routeur;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ...surchargesRouteur(
              FausseSourceSession(sessionActive(AppRole.guardian)),
            ),
          ],
          child: TranslationProvider(
            child: Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? _) {
                routeur = ref.read(routeurProvider);
                return MaterialApp.router(
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  routerConfig: routeur,
                );
              },
            ),
          ),
        ),
      );
      await stabiliser(tester);
      routeur.go(Routes.demoAdulte);
      await tester.pumpAndSettle();
      expect(find.byType(AccueilAdultePage), findsNothing);
      final Finder lien = find.byKey(
        const ValueKey<String>('lien-ecran-accueil'),
      );
      await tester.ensureVisible(lien);
      await tester.pumpAndSettle();
      await tester.tap(lien);
      await tester.pumpAndSettle();
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AccueilAdultePage),
          matching: find.byType(GrilleBento),
        ),
        findsOneWidget,
      );
      expect(find.byType(CarteSession), findsOneWidget);
    });

    Rect rect(WidgetTester tester, Finder f) => tester.getRect(f.first);
    final Finder seance = find.byKey(
      const ValueKey<String>('accueil-adulte-prochaine-seance'),
    );
    final Finder avant = find.byType(EmplacementAvantProchainCours);
    final Finder parcours = find.byKey(
      const ValueKey<String>('accueil-adulte-parcours'),
    );
    final Finder dernieres = find.byKey(
      const ValueKey<String>('accueil-adulte-dernieres'),
    );
    final Finder ressources = find.byType(BlocBibliotheque);

    for (final double largeur in const <double>[390, 768]) {
      testWidgets('${largeur.toInt()} px : une tuile par bande, dans l\'ordre '
          'de §3.7', (WidgetTester tester) async {
        taille(tester, Size(largeur, 3000));
        await monterCoquille(
          tester,
          adresseDemoAdulte(EcranDemoAdulte.accueil),
        );
        final List<Rect> r = <Rect>[
          for (final Finder f in <Finder>[
            seance,
            avant,
            parcours,
            dernieres,
            ressources,
          ])
            rect(tester, f),
        ];
        for (int i = 1; i < r.length; i++) {
          // Chaque tuile sous la precedente, avec au moins l'ecart de 16.
          expect(r[i].top, greaterThanOrEqualTo(r[i - 1].bottom));
        }
      });
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('1440 px, ${sens.name} : seance puis « Avant » cote a cote, '
          'parcours dessous, puis dernieres seances et ressources', (
        WidgetTester tester,
      ) async {
        taille(tester, const Size(1440, 3000));
        await monterCoquille(
          tester,
          adresseDemoAdulte(EcranDemoAdulte.accueil),
          direction: sens,
        );
        final bool ltr = sens == TextDirection.ltr;
        bool apres(Rect a, Rect b) =>
            ltr ? b.left >= a.right : b.right <= a.left;
        final Rect s = rect(tester, seance);
        final Rect a = rect(tester, avant);
        final Rect p = rect(tester, parcours);
        final Rect d = rect(tester, dernieres);
        final Rect b = rect(tester, ressources);
        expect(apres(s, a), isTrue, reason: '« Avant » apres la seance');
        expect(a.top, moreOrLessEquals(s.top, epsilon: 1));
        expect(p.top, greaterThan(math.max(s.bottom, a.bottom)));
        expect(d.top, greaterThan(p.bottom));
        expect(apres(d, b), isTrue, reason: 'ressources apres les seances');
        // Meme bande : la liste des seances commence avant la fin des
        // ressources.
        expect(d.top, lessThan(b.bottom));
      });
    }

    // Tuiles absentes (revue BENTO-3-R) : la Classe de demonstration, sans
    // « Avant le prochain cours », avec ou sans parcours et seances passees.
    Future<void> monterSans(
      WidgetTester tester, {
      required bool parcoursEtDernieres,
    }) async {
      taille(tester, const Size(1440, 3000));
      await tester.pumpWidget(
        app(
          overrides: <Override>[
            ...surchargesEleveDemo(
              EtatDemoClasse.aVenir,
              travail: const _AucunTravail(),
            ),
            accueilAdulteProvider.overrideWith(
              (Ref _) async => AccueilAdulteVM(
                prenom: 'Mamadou',
                groupeId: DonneesClasseDemo.groupeId,
                ligneParcours: parcoursEtDernieres
                    ? DonneesAdulteDemo.ligneParcours
                    : null,
                dernieresSeances: parcoursEtDernieres
                    ? DonneesAdulteDemo.dernieresSeances()
                    : const <SeancePasseeAdulte>[],
              ),
            ),
          ],
          child: const AccueilAdultePage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EmplacementAvantProchainCours), findsNothing);
      expect(find.byType(CarteSession), findsOneWidget);
    }

    testWidgets('1440 px sans « Avant » : la seance seule dans sa bande, '
        'puis parcours, puis dernieres seances et ressources', (
      WidgetTester tester,
    ) async {
      await monterSans(tester, parcoursEtDernieres: true);
      expect(find.byType(GrilleBento), findsOneWidget);
      // La carte de seance ferme la tuile Prochaine seance.
      final Rect s = rect(tester, find.byType(CarteSession));
      final Rect p = rect(tester, parcours);
      final Rect d = rect(tester, dernieres);
      final Rect b = rect(tester, ressources);
      expect(p.top, greaterThan(s.bottom));
      expect(d.top, greaterThan(p.bottom));
      // Dernieres seances et ressources dans la meme bande.
      expect(d.top, lessThan(b.bottom));
      expect(b.top, lessThan(d.bottom));
    });

    testWidgets('D14 : seance et ressources seules, pas de Bento, une '
        'colonne', (WidgetTester tester) async {
      await monterSans(tester, parcoursEtDernieres: false);
      expect(find.byType(GrilleBento), findsNothing);
      expect(
        rect(tester, ressources).top,
        greaterThan(rect(tester, seance).bottom),
      );
    });

    group('aucun mot coupe', () {
      // Les mesures de texte n'ont de sens qu'avec les vraies polices.
      setUpAll(chargerPolicesDuDepot);

      for (final (double, double) cas in const <(double, double)>[
        (320, 2),
        (768, 1),
        (768, 2),
        (1440, 1),
        (1440, 2),
      ]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
              '${sens.name}', (WidgetTester tester) async {
            taille(tester, Size(cas.$1, 4000));
            await monterCoquille(
              tester,
              adresseDemoAdulte(EcranDemoAdulte.accueil),
              echelle: cas.$2,
              direction: sens,
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(GrilleBento), findsOneWidget);
            verifierAucunMotCoupe(tester, find.byType(GrilleBento));
          });
        }
      }
    });
  });
}
