// Notifications du tuteur (lot E, sous-paquet 3), sur le VRAI routeur : la
// cloche de l'en-tete est TOUCHEE depuis l'Accueil (definition de « fait »,
// registre section 5 bis), a 390 et a 1440. Donnees : doubles de test, aucun
// Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../../router/support_routeur.dart';
import '../historique/support_historique.dart';

/// Des notifications en memoire, avec un compteur de lectures.
class FauxNotifications implements PortNotifications {
  FauxNotifications({
    this.rendues = const <NotificationTuteur>[],
    this.erreur,
    this.delai,
  });

  List<NotificationTuteur> rendues;
  Exception? erreur;
  Duration? delai;
  int lectures = 0;

  @override
  Future<List<NotificationTuteur>> liste() async {
    lectures++;
    if (delai case final Duration d) {
      await Future<void>.delayed(d);
    }
    if (erreur case final Exception e) {
      throw e;
    }
    return rendues;
  }

  @override
  Future<NotificationTuteur?> detail(String id) async =>
      rendues.where((NotificationTuteur n) => n.id == id).firstOrNull;
}

final DateTime _hier = DateTime.now().subtract(const Duration(days: 1));

List<NotificationTuteur> _deux() => <NotificationTuteur>[
  NotificationTuteur(
    id: 'n1',
    titre: 'Compte rendu de la séance disponible',
    date: _hier,
    destination: Routes.tuteurSuivi,
  ),
  NotificationTuteur(
    id: 'n2',
    titre: 'Message de l’académie',
    date: _hier.subtract(const Duration(days: 2)),
    // Un lien externe n'est jamais suivi : le port le rend nul.
    destination: 'https://exemple.org',
  ),
];

Future<GoRouter> _monter(
  WidgetTester tester, {
  PortNotifications? port,
  Size taille = const Size(390, 844),
  bool horsLigne = false,
}) => monterHistorique(
  tester,
  taille: taille,
  horsLigne: horsLigne,
  autres: <Override>[
    if (port != null) portNotificationsProvider.overrideWithValue(port),
  ],
);

int _indexActif(WidgetTester tester) =>
    tester.widget<NavShell>(find.byType(NavShell)).indexActif ?? -1;

Future<void> _toucherCloche(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(t.commun.entete.notifications).first);
  await stabiliser(tester);
}

void main() {
  group('Notifications du tuteur', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets(
        'production : la cloche TOUCHEE ouvre « pas encore disponibles », '
        'le retour ramene a l Accueil (${taille.width.toInt()})',
        (WidgetTester tester) async {
          final GoRouter routeur = await _monter(tester, taille: taille);
          expect(find.byType(AccueilFamillePage), findsOneWidget);

          await _toucherCloche(tester);

          expect(lieu(routeur), Routes.tuteurNotifications);
          expect(find.byType(NotificationsPage), findsOneWidget);
          // COM-F-Q5 : la cloche est la seule entree active, aucun onglet.
          expect(_indexActif(tester), -1);
          expect(find.text(t.notifications.indisponibleTitre), findsOneWidget);
          // Une capacite absente ne se reessaie pas, et n'est pas un vide.
          expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
          expect(find.text(t.notifications.videTitre), findsNothing);
          final EtatSysteme etat = tester.widget<EtatSysteme>(
            find.byType(EtatSysteme),
          );
          expect(etat.nature, NatureEtat.indisponible);
          expect(etat.dependance, 'DB-CPT-04');
          // La cloche n'a pas de point : aucune source de non-lus.
          expect(find.bySemanticsLabel(RegExp('non lue')), findsNothing);
          // Barre (ou barre laterale) toujours la.
          expect(find.byType(NavShell), findsOneWidget);

          await tester.tap(find.byType(DisqueRetour));
          await stabiliser(tester);
          expect(lieu(routeur), Routes.tuteurAccueil);
          expect(find.byType(AccueilFamillePage), findsOneWidget);
        },
      );
    }

    testWidgets('simulation : une ligne par notification, la plus recente en '
        'tete ; la ligne a destination interne l ouvre', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        port: FauxNotifications(rendues: _deux()),
      );
      await _toucherCloche(tester);

      final Finder n1 = find.byKey(const ValueKey<String>('notification-n1'));
      final Finder n2 = find.byKey(const ValueKey<String>('notification-n2'));
      expect(n1, findsOneWidget);
      expect(n2, findsOneWidget);
      expect(tester.getTopLeft(n1).dy, lessThan(tester.getTopLeft(n2).dy));
      expect(find.text('Compte rendu de la séance disponible'), findsOneWidget);
      expect(find.text(t.historique.fuseauListe), findsOneWidget);
      // La ligne sans destination (lien externe rejete) ouvre son detail :
      // aucune ligne inerte (revue COM-R, R-06 ; contre-preuve : elle
      // n'etait pas une cible).
      expect(tester.widget<LigneNotification>(n2).onPress, isNotNull);

      await tester.tap(n1);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurSuivi);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
    });

    testWidgets('vide : aucune notification, sans bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: FauxNotifications());
      await _toucherCloche(tester);
      expect(find.text(t.notifications.videTitre), findsOneWidget);
      expect(find.text(t.notifications.videPhrase), findsOneWidget);
    });

    testWidgets('echec : Reessayer relit', (WidgetTester tester) async {
      final FauxNotifications port = FauxNotifications(
        erreur: Exception('refus'),
      );
      await _monter(tester, port: port);
      await _toucherCloche(tester);
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
      final int avant = port.lectures;
      port
        ..erreur = null
        ..rendues = _deux();
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await stabiliser(tester);
      expect(port.lectures, greaterThan(avant));
      expect(
        find.byKey(const ValueKey<String>('notification-n1')),
        findsOneWidget,
      );
    });

    testWidgets('chargement : la forme de la liste', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: FauxNotifications(
          rendues: _deux(),
          delai: const Duration(seconds: 2),
        ),
      );
      await _toucherCloche(tester);
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await stabiliser(tester);
      expect(
        find.byKey(const ValueKey<String>('notification-n1')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : le bandeau le dit, un seul (D-FUS-3)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, horsLigne: true);
      await _toucherCloche(tester);
      // D-FUS-3 (05/10, choix a) : seul le bandeau des Communications.
      expect(find.text(t.reseau.horsLigne), findsNothing);
      expect(find.text(t.com.socle.composants.etats.horsLigne), findsOneWidget);
      expect(find.text(t.notifications.indisponibleTitre), findsOneWidget);
    });

    test('le port de production est indisponible (DB-CPT-04)', () async {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await expectLater(
        c.read(portNotificationsProvider).liste(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });
}
