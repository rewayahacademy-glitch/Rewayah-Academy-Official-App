import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
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
      // Le produit n'a pas de mot de passe, nulle part. Un champ qui
      // apparaitrait ici serait le premier.
      await _monter(tester);
      final Iterable<TextField> champs = tester.widgetList<TextField>(
        find.byType(TextField),
      );
      expect(champs, hasLength(1));
      expect(champs.single.obscureText, isFalse);
    });
  });
}
