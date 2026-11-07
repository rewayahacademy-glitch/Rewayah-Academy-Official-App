// FN-111 (parcours 3, piege 3.1, 31/10/2026) : un lien de connexion ouvert sur
// un autre appareil ou dans un autre navigateur arrivait sur « Se connecter »
// sans un mot. La page le dit maintenant, en tete, et dit quoi faire.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/lien_ailleurs.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

final Uri _lien = Uri.parse(
  'https://app.rewayahacademy.com/?code=8f1c2d3e-0000-4000-8000-000000000001#/connexion',
);

Future<void> _monter(
  WidgetTester tester, {
  required Uri adresse,
  Size taille = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    hote(
      ConnexionPage(urlRetour: adresse),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        demoAuthActiveProvider.overrideWithValue(false),
        environnementConnexionProvider.overrideWithValue('production'),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('lienOuvertAilleurs', () {
    test('un code sans cle de verification : ouvert ailleurs', () {
      expect(lienOuvertAilleurs(_lien, verificateur: null), isTrue);
      expect(lienOuvertAilleurs(_lien, verificateur: '  '), isTrue);
    });

    test('un code avec sa cle : le meme navigateur, rien a dire', () {
      expect(
        lienOuvertAilleurs(_lien, verificateur: '"abc/magiclink"'),
        isFalse,
      );
    });

    test("le code d'une invitation d'enseignant n'est pas un lien", () {
      final Uri invitation = Uri.parse(
        'https://app.rewayahacademy.com/?mode=creer&invitation=1&code=RA7K2#/connexion',
      );
      expect(lienOuvertAilleurs(invitation, verificateur: null), isFalse);
    });

    test('un retour en echec est dit par la recuperation', () {
      final Uri echec = Uri.parse(
        'https://app.rewayahacademy.com/?code=x&error=access_denied&error_code=otp_expired',
      );
      expect(lienOuvertAilleurs(echec, verificateur: null), isFalse);
    });

    test('sans code, ou code vide : rien', () {
      expect(
        lienOuvertAilleurs(
          Uri.parse('https://app.rewayahacademy.com/#/connexion'),
          verificateur: null,
        ),
        isFalse,
      );
      expect(
        lienOuvertAilleurs(
          Uri.parse('https://app.rewayahacademy.com/?code=#/connexion'),
          verificateur: null,
        ),
        isFalse,
      );
    });

    test('lit la cle de verification dans la memoire de cet appareil', () {
      addTearDown(() => effacerMemoireAppareil(clefVerificateurLien));
      expect(lienOuvertAilleursIci(_lien), isTrue);
      ecrireMemoireAppareil(clefVerificateurLien, '"abc/magiclink"');
      expect(lienOuvertAilleursIci(_lien), isFalse);
    });
  });

  group('page Se connecter', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('lien ouvert ailleurs : le bandeau le dit, en tete '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        await _monter(tester, adresse: _lien, taille: taille);
        expect(
          find.byKey(const ValueKey<String>('connexion-lien-ailleurs')),
          findsOneWidget,
        );
        expect(find.text(t.connexion.lienAilleursTitre), findsOneWidget);
        expect(find.text(t.connexion.lienAilleursPhrase), findsOneWidget);
        // Le bandeau precede le titre de la page.
        final double bandeau = tester
            .getTopLeft(find.text(t.connexion.lienAilleursTitre))
            .dy;
        final double titre = tester.getTopLeft(find.text(t.connexion.titre)).dy;
        expect(bandeau, lessThan(titre));
        verifierUnSeulBoutonPlein(tester);
      });
    }

    testWidgets('arrivee ordinaire : aucun bandeau', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: Uri.parse('https://app.rewayahacademy.com/#/connexion'),
      );
      expect(find.text(t.connexion.lienAilleursTitre), findsNothing);
    });
  });
}
