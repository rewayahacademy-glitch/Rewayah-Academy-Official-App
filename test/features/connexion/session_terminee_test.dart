// Demande du directeur (01/11/2026) : une session coupee par le serveur
// (deux connexions, un autre compte ouvert ici ou ailleurs) se dit clairement
// sur « Se connecter », et ne se dit plus apres une nouvelle connexion.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    hote(
      const ConnexionPage(),
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
  tearDown(() => sessionTermineeParLeServeur.value = false);

  testWidgets('session terminee par le serveur : le bandeau le dit', (
    WidgetTester tester,
  ) async {
    sessionTermineeParLeServeur.value = true;
    await _monter(tester);
    expect(find.text(t.connexion.sessionTermineeTitre), findsOneWidget);
    expect(find.text(t.connexion.sessionTermineePhrase), findsOneWidget);
  });

  testWidgets('arrivee ordinaire : aucun bandeau', (WidgetTester tester) async {
    await _monter(tester);
    expect(find.text(t.connexion.sessionTermineeTitre), findsNothing);
  });
}
