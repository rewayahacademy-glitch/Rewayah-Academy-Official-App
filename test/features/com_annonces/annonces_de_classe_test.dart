// COM-ANN-1 : l'emplacement `AnnoncesDeClasse` rempli (spec section 13.3),
// etat par etat : rien tant que rien n'est a dire (chargement, port neutre,
// aucune annonce), la section et ses cartes sinon, l'echec avec
// « Reessayer », la publication seulement avec la capacite, la lecture
// enregistree ou dite non confirmee, le detail en surface contextuelle.
// Puis dans les VRAIES pages hotes : Espace Classe du tuteur (en tete) et
// Ma classe de l'eleve adulte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/pile_cartes.dart';
import 'package:rewayah_academy/features/classe_tuteur/carte_seance_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_annonces/carte_annonce_classe.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';

import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import 'faux_annonces.dart';
import 'support_annonces.dart';

const String _classe = 'c1';

Future<GoRouter> _monter(
  WidgetTester tester, {
  PortAnnonces? port,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: '/classe',
    routes: <RouteBase>[
      GoRoute(
        path: '/classe',
        builder: (BuildContext _, GoRouterState _) => const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('avant'),
                AnnoncesDeClasse(
                  classeId: _classe,
                  ecartAvant: SizedBox(
                    key: ValueKey<String>('ecart-avant'),
                    height: AppSpacing.section,
                  ),
                ),
                Text('apres'),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.publierAnnoncePour(_classe),
        builder: (BuildContext _, GoRouterState _) =>
            const Text('publier une annonce'),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        if (port != null) portAnnoncesProvider.overrideWithValue(port),
      ],
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

void main() {
  group('AnnoncesDeClasse, etat par etat', () {
    testWidgets('production (port neutre, COM-BR-10) : rien, ni ecart', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.byKey(AnnoncesDeClasse.cleSection), findsNothing);
      expect(find.byKey(const ValueKey<String>('ecart-avant')), findsNothing);
      expect(find.text(t.com.annonces.section), findsNothing);
      // Pas de faux vide ni d'echec.
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucune annonce, lecture seule : rien', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: FauxAnnonces());
      expect(find.byKey(AnnoncesDeClasse.cleSection), findsNothing);
    });

    testWidgets('aucune annonce, capacite de publier : la section, le vide '
        'et « Publier une annonce », qui mene a la publication', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        port: FauxAnnonces(
          capacites: <CapaciteAnnonces>{CapaciteAnnonces.publier},
        ),
      );
      expect(find.byKey(AnnoncesDeClasse.cleSection), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('ecart-avant')), findsOneWidget);
      expect(find.text(t.com.annonces.videPublier), findsOneWidget);
      await tester.tap(find.byKey(AnnoncesDeClasse.clePublier));
      await stabiliser(tester);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.publierAnnoncePour(_classe),
      );
    });

    testWidgets('des annonces sans capacite : les cartes, sans « Publier » '
        'ni « Ouvrir la Classe » (on y est)', (WidgetTester tester) async {
      await _monter(
        tester,
        port: FauxAnnonces(
          parClasse: <String, List<AnnonceClasse>>{
            _classe: <AnnonceClasse>[
              annonceDeTest(),
              annonceDeTest(
                id: 'an2',
                titre: 'Révision avant jeudi',
                texte: 'Révisez avant jeudi.',
                lue: true,
              ),
            ],
          },
        ),
      );
      expect(find.text(t.com.annonces.section), findsOneWidget);
      expect(find.byType(CarteAnnonceClasse), findsNWidgets(2));
      expect(find.byType(PileCartes), findsOneWidget);
      expect(find.byKey(AnnoncesDeClasse.clePublier), findsNothing);
      expect(find.byKey(CarteAnnonceClasse.cleOuvrirClasse), findsNothing);
      // Cartes detachees, 16 au moins entre elles (K-55).
      verifierEcartCartes(
        tester,
        find.byType(CarteAnnonceClasse),
        minimum: AppSpacing.lg,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('echec : la section dit l echec, « Reessayer » relit', (
      WidgetTester tester,
    ) async {
      final FauxAnnonces port = FauxAnnonces(erreur: Exception('refus'));
      await _monter(tester, port: port);
      expect(find.text(t.com.annonces.section), findsOneWidget);
      expect(
        find.text(t.com.socle.composants.etats.erreurTitre),
        findsOneWidget,
      );
      final int avant = port.lectures;
      port
        ..erreur = null
        ..parClasse = <String, List<AnnonceClasse>>{
          _classe: <AnnonceClasse>[annonceDeTest()],
        };
      await tester.tap(find.text(t.com.socle.composants.etats.reessayer));
      await stabiliser(tester);
      expect(port.lectures, greaterThan(avant));
      expect(find.byType(CarteAnnonceClasse), findsOneWidget);
    });

    testWidgets('« Marquer comme lue » enregistre, puis la carte est relue '
        'lue', (WidgetTester tester) async {
      final FauxAnnonces port = FauxAnnonces(
        parClasse: <String, List<AnnonceClasse>>{
          _classe: <AnnonceClasse>[annonceDeTest()],
        },
      );
      await _monter(tester, port: port);
      expect(find.text(t.com.socle.composants.badge.aLire), findsOneWidget);
      await tester.tap(find.byKey(CarteAnnonceClasse.cleMarquerLue));
      await stabiliser(tester);
      expect(port.lues, <String>['an1']);
      expect(find.byKey(CarteAnnonceClasse.cleMarquerLue), findsNothing);
      expect(find.text(t.com.socle.composants.badge.aLire), findsNothing);
    });

    testWidgets('lecture non confirmee : l annonce reste non lue, et le dit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: FauxAnnonces(
          echecLecture: true,
          parClasse: <String, List<AnnonceClasse>>{
            _classe: <AnnonceClasse>[annonceDeTest()],
          },
        ),
      );
      await tester.tap(find.byKey(CarteAnnonceClasse.cleMarquerLue));
      await stabiliser(tester);
      expect(find.text(t.notifications.lectureNonConfirmee), findsOneWidget);
      expect(find.byKey(CarteAnnonceClasse.cleMarquerLue), findsOneWidget);
    });

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : « Lire l annonce en entier » '
          'ouvre le detail en surface contextuelle et enregistre la lecture', (
        WidgetTester tester,
      ) async {
        final FauxAnnonces port = FauxAnnonces(
          parClasse: <String, List<AnnonceClasse>>{
            _classe: <AnnonceClasse>[annonceDeTest()],
          },
        );
        await _monter(tester, port: port, taille: taille);
        await tester.tap(find.byKey(CarteAnnonceClasse.cleLire));
        await stabiliser(tester);
        expect(port.lues, <String>['an1']);
        // La feuille (ou le dialogue sur ordinateur) porte le texte entier.
        final Finder detail = find.byWidgetPredicate(
          (Widget w) => w is CarteAnnonceClasse && w.complete,
        );
        expect(detail, findsOneWidget);
        expect(
          find.descendant(of: detail, matching: find.text(texteLong)),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(
                find.descendant(of: detail, matching: find.text(texteLong)),
              )
              .maxLines,
          isNull,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Dans les vraies pages hotes', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 1000),
    ]) {
      testWidgets('${taille.width.toInt()} : Espace Classe du tuteur, '
          'l annonce en tete de la page', (WidgetTester tester) async {
        await monterTuteurAnnonces(
          tester,
          depart: Routes.classePour(classeA, eleveId: eleveA1),
          taille: taille,
          autres: <Override>[
            portAnnoncesProvider.overrideWithValue(
              FauxAnnonces(
                parClasse: <String, List<AnnonceClasse>>{
                  classeA: <AnnonceClasse>[annonceDeTest(classeId: classeA)],
                },
              ),
            ),
          ],
        );
        expect(find.byType(ClasseTuteurPage), findsOneWidget);
        final Finder carte = find.byKey(const ValueKey<String>('annonce-an1'));
        expect(carte, findsOneWidget);
        expect(find.text(t.com.annonces.section), findsOneWidget);
        expect(find.byKey(CarteAnnonceClasse.cleOuvrirClasse), findsNothing);
        // En tete : avant la carte de seance de la Classe.
        expect(
          tester.getTopLeft(carte).dy,
          lessThan(tester.getTopLeft(find.byType(CarteSeanceClasse)).dy),
        );
        verifierUnSeulBoutonPlein(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Espace Classe du tuteur en production : la page est '
        'inchangee, aucune section d annonces', (WidgetTester tester) async {
      await monterTuteurAnnonces(
        tester,
        depart: Routes.classePour(classeA, eleveId: eleveA1),
      );
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
      expect(find.byType(AnnoncesDeClasse), findsOneWidget);
      expect(find.byKey(AnnoncesDeClasse.cleSection), findsNothing);
    });
  });
}
