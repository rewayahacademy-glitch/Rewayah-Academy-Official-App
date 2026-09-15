import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../support/harnais.dart';

Future<FauxServiceAuth> _monter(WidgetTester tester) async {
  final FauxServiceAuth auth = FauxServiceAuth();
  await tester.pumpWidget(
    hote(
      const ConnexionPage(),
      surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
    ),
  );
  return auth;
}

void main() {
  group('courrielPlausible', () {
    // Volontairement permissif : le seul verdict qui compte est celui du
    // serveur de courriel. Ce controle sert a ne pas envoyer une requete pour
    // une saisie manifestement incomplete.
    test('accepte des adresses ordinaires', () {
      for (final String valide in <String>[
        'a@b.co',
        'fatou.diallo@example.test',
        'moussa+cours@sous.domaine.fr',
      ]) {
        expect(courrielPlausible(valide), isTrue, reason: valide);
      }
    });

    test('refuse ce qui ne peut pas etre une adresse', () {
      for (final String invalide in <String>[
        '',
        'sans-arobase.fr',
        'deux@@arobases.fr',
        'espace dans@adresse.fr',
        'sanspoint@domaine',
        'point.final@domaine.',
      ]) {
        expect(courrielPlausible(invalide), isFalse, reason: invalide);
      }
    });
  });

  group('TUT-00 : la connexion', () {
    testWidgets('le bouton reste inerte tant que l adresse est incomplete', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await _monter(tester);

      await tester.enterText(find.byType(TextField), 'fatou');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, isEmpty);
    });

    testWidgets('une adresse valide declenche l envoi et change d etat', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await _monter(tester);

      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, <String>['fatou@example.test']);
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
    });

    testWidgets('l ecran de confirmation ne se ferme pas tout seul', (
      WidgetTester tester,
    ) async {
      // Rien ne se ferme sur minuterie dans ce produit : l'utilisateur va
      // chercher son courriel et revient quand il veut.
      await _monter(tester);
      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(minutes: 5));
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
    });

    testWidgets('un echec d envoi se dit, et laisse reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await _monter(tester);
      auth.erreurAJeter = StateError('reseau');

      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.erreurEnvoi), findsOneWidget);
      expect(find.text(t.connexion.lienEnvoye), findsNothing);
    });

    testWidgets('aucun champ de mot de passe n existe sur cet ecran', (
      WidgetTester tester,
    ) async {
      // La compilation de production reste sans mot de passe. Le parcours de
      // demonstration est couvert explicitement par les tests ci-dessous.
      await _monter(tester);
      final Iterable<TextField> champs = tester.widgetList<TextField>(
        find.byType(TextField),
      );
      expect(champs, hasLength(1));
      expect(champs.single.obscureText, isFalse);
    });

    testWidgets('le mode mot de passe porte une hierarchie mobile sobre', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        hote(
          const ConnexionPage(demoAuth: true),
          surcharges: <Override>[
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final AppCard carte = tester.widget<AppCard>(
        find.byKey(const ValueKey<String>('connexion-carte')),
      );
      expect(carte.dominante, isTrue);

      final ActionPrincipale connexion = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.seConnecter),
      );
      final ActionPrincipale lien = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.envoyerLien),
      );
      final ActionPrincipale google = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.avecGoogle),
      );
      final ActionPrincipale eleve = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.eleveConnexion.entrerCode),
      );

      expect(connexion.niveau, NiveauAction.principale);
      expect(lien.niveau, NiveauAction.tertiaire);
      expect(google.niveau, NiveauAction.secondaire);
      expect(eleve.niveau, NiveauAction.tertiaire);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le mode demonstration accepte email et mot de passe', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await tester.pumpWidget(
        hote(
          const ConnexionPage(demoAuth: true),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        ' fatou@example.test ',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-mot-de-passe')),
        'essai-local',
      );
      await tester.pump();
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.seConnecter),
      );
      expect(bouton.onPress, isNotNull);
      bouton.onPress!();
      await tester.pumpAndSettle();

      expect(
        auth.connexionsMotDePasse,
        <({String courriel, String motDePasse})>[
          (courriel: 'fatou@example.test', motDePasse: 'essai-local'),
        ],
      );
    });

    testWidgets('le mode demonstration affiche une erreur recuperable', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth()
        ..erreurAJeter = StateError('refuse');
      await tester.pumpWidget(
        hote(
          const ConnexionPage(demoAuth: true),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        'fatou@example.test',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-mot-de-passe')),
        'essai-local',
      );
      await tester.pump();
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.seConnecter),
      );
      expect(bouton.onPress, isNotNull);
      bouton.onPress!();
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.erreurConnexion), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        findsOneWidget,
      );
    });
  });
}
