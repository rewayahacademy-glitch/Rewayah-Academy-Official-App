// Q-12 : la navigation Groupe / Accueil / Bibliotheque ne provoque aucun
// disconnect.
//
// Spec section 9.4 et section 15 (« la session reste coherente apres
// reconnect/background »), decision D-24 (« naviguer dans Rewayah ne doit
// pas, a lui seul, couper la classe Live active »).
//
// CE QUI REND CE TEST NON VIDE. Le montage contient l ANTI-PATRON du depot :
// `EcranQuiPossedeLaRoom` appelle `moteur.quitter()` dans son `dispose`,
// exactement comme `_SallePageEtat` le fait aujourd hui (salle_page.dart:122).
// Un des tests l exerce et constate la coupure. Sans lui, « zero deconnexion »
// pourrait tout aussi bien venir d un double incapable d en compter une.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

import 'faux/faux_moteur_salle.dart';
import 'support/hote_navigation.dart';

/// Le parcours de la spec : on part de la classe et on en fait le tour.
const List<String> _parcours = <String>[
  CheminsTc.groupes,
  CheminsTc.accueil,
  CheminsTc.bibliotheque,
  CheminsTc.classe,
];

void main() {
  late FauxMoteurSalle moteur;
  late FauxAnnonceSortie annonce;
  late FauxSessionPersistante session;

  setUp(() {
    moteur = FauxMoteurSalle();
    annonce = FauxAnnonceSortie();
    session = FauxSessionPersistante(
      moteur: moteur,
      annonce: annonce,
      courante: const SessionEnCoursDouble(
        sessionId: 'seance-1',
        groupeId: 'grp-plein',
        libelleGroupe: 'Les Lanternes',
      ),
    );
  });

  tearDown(() async {
    await session.liberer();
    await moteur.liberer();
  });

  group('Q-12 : naviguer ne coupe jamais la classe', () {
    testWidgets('Classe -> Groupe -> Accueil -> Bibliotheque -> Classe', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = routeurDeTest(depart: CheminsTc.classe);
      addTearDown(routeur.dispose);

      await tester.pumpWidget(appDeTest(session: session, routeur: routeur));
      await tester.pumpAndSettle();
      expect(find.text('Classe'), findsOneWidget);

      for (final String destination in _parcours) {
        routeur.go(destination);
        await tester.pumpAndSettle();
        expect(
          moteur.deconnexions,
          0,
          reason: 'la navigation vers $destination a coupe la salle',
        );
      }

      expect(moteur.etatCourant, EtatSalle.connecte);
      expect(moteur.liberations, 0);
      expect(session.courante, isNotNull);
    });

    testWidgets('un aller-retour complet, deux fois, coute zero deconnexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = routeurDeTest();
      addTearDown(routeur.dispose);

      await tester.pumpWidget(appDeTest(session: session, routeur: routeur));
      await tester.pumpAndSettle();

      for (int tour = 0; tour < 2; tour++) {
        for (final String destination in _parcours) {
          routeur.go(destination);
          await tester.pumpAndSettle();
        }
      }

      expect(moteur.deconnexions, 0);
      expect(annonce.gestes, isEmpty);
    });

    testWidgets('la barre « Seance toujours en direct » suit sur chaque ecran', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = routeurDeTest();
      addTearDown(routeur.dispose);

      await tester.pumpWidget(appDeTest(session: session, routeur: routeur));
      await tester.pumpAndSettle();

      for (final String destination in _parcours) {
        routeur.go(destination);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('barre-cours-en-cours')),
          findsOneWidget,
          reason: 'pas de retour possible depuis $destination',
        );
        expect(find.text('Seance toujours en direct - Les Lanternes'), findsOneWidget);
      }
    });
  });

  group('Q-12 : le test sait reconnaitre une vraie coupure', () {
    testWidgets('un ecran qui possede la room la coupe en se demontant', (
      WidgetTester tester,
    ) async {
      // C est l anti-patron, reproduit expres. S il ne se voyait pas ici, les
      // « zero deconnexion » ci-dessus ne prouveraient rien.
      final GoRouter routeur = routeurDeTest(
        depart: CheminsTc.classe,
        moteurFautif: moteur,
      );
      addTearDown(routeur.dispose);

      await tester.pumpWidget(appDeTest(session: session, routeur: routeur));
      await tester.pumpAndSettle();
      expect(find.text('Classe (fautive)'), findsOneWidget);
      expect(moteur.deconnexions, 0);

      routeur.go(CheminsTc.groupes);
      await tester.pumpAndSettle();

      expect(
        moteur.deconnexions,
        1,
        reason:
            'le compteur sait detecter une coupure : les tests precedents '
            'mesurent donc quelque chose de reel',
      );
    });
  });

  group('Q-12 : seule la sortie volontaire coupe, et dans le bon ordre', () {
    testWidgets('quitter annonce au serveur AVANT de couper le moteur', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = routeurDeTest(depart: CheminsTc.classe);
      addTearDown(routeur.dispose);

      await tester.pumpWidget(appDeTest(session: session, routeur: routeur));
      await tester.pumpAndSettle();

      await session.quitter();

      // L ordre porte de l information : le webhook LiveKit deduplique un
      // depart deja ecrit par `user_action` dans une fenetre de 30 s. Inverser
      // les deux gestes ferait perdre la distinction sortie volontaire /
      // deconnexion subie.
      expect(annonce.gestes, <String>['annonce', 'quitter']);
      expect(moteur.deconnexions, 1);
      expect(session.courante, isNull);
    });

    testWidgets('une annonce qui echoue n empeche pas de sortir', (
      WidgetTester tester,
    ) async {
      // Comportement deja retenu par `ServiceVideo.annoncerSortie`, qui avale
      // volontairement l echec : une trace perdue n est pas une sortie
      // empechee. Inacceptable en revanche pour fermer un quota d observation
      // -- voir Q-03, ou la fermeture est serveur.
      final GoRouter routeur = routeurDeTest(depart: CheminsTc.classe);
      addTearDown(routeur.dispose);
      annonce.echoue = true;

      await tester.pumpWidget(appDeTest(session: session, routeur: routeur));
      await tester.pumpAndSettle();

      await session.quitter();

      expect(moteur.deconnexions, 1);
      expect(session.courante, isNull);
      expect(annonce.gestes, <String>['annonce', 'quitter']);
    });
  });
}
