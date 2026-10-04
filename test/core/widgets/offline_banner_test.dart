// T-S2 du lot CL-7 : l'extension additive d'`OfflineBanner`. Le bandeau
// historique garde son texte et son fournisseur ; `OfflineBanner.message`
// rend le texte fourni sans lire le reseau de l'appareil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';

import '../../capture/outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget bandeau, {
  required bool horsLigne,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(body: bandeau),
      surcharges: <Override>[
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('const OfflineBanner() garde son texte hors ligne', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const OfflineBanner(), horsLigne: true);
    expect(find.text(t.reseau.horsLigne), findsOneWidget);
  });

  testWidgets('const OfflineBanner() ne rend rien en ligne', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const OfflineBanner(), horsLigne: false);
    expect(find.text(t.reseau.horsLigne), findsNothing);
  });

  testWidgets('OfflineBanner.message ignore le fournisseur', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const OfflineBanner.message(
        message: 'Le réseau est faible.',
        sousTexte: 'Le son reste prioritaire.',
      ),
      horsLigne: false,
    );
    expect(find.text('Le réseau est faible.'), findsOneWidget);
    expect(find.text('Le son reste prioritaire.'), findsOneWidget);
    expect(find.text(t.reseau.horsLigne), findsNothing);

    // Appareil hors ligne : le texte fourni reste seul.
    await _monter(
      tester,
      const OfflineBanner.message(message: 'Reconnexion de la séance…'),
      horsLigne: true,
    );
    expect(find.text('Reconnexion de la séance…'), findsOneWidget);
    expect(find.text(t.reseau.horsLigne), findsNothing);
  });

  testWidgets('OfflineBanner.message est une region vivante', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const OfflineBanner.message(message: 'Réseau faible.'),
      horsLigne: false,
    );
    final Iterable<Semantics> regions = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text('Réseau faible.'),
            matching: find.byType(Semantics),
          ),
        )
        .where((Semantics s) => s.properties.liveRegion ?? false);
    expect(regions, isNotEmpty);
  });

  // EA-HORS-LIGNE-1 : le bandeau est partage par toutes les coquilles ; il
  // ne promet rien qu'une page pourrait dementir (« Rien n'est envoye » sur
  // l'invitation du conjoint). Il dit le fait, et seulement lui.
  test('le bandeau ne promet aucun envoi', () {
    final String texte = t.reseau.horsLigne.toLowerCase();
    for (final String promesse in <String>['envoi', 'attendra', 'partira']) {
      expect(texte, isNot(contains(promesse)));
    }
  });

  // EA-HORS-LIGNE-1b : « Tout reste consultable » etait faux sur le scanner
  // de connexion, sur un ecran jamais charge, et partout ailleurs : aucune
  // page ne lit le cache persistant. Seul ce qui est deja affiche le reste.
  test('le bandeau ne promet que ce qui est deja affiche', () {
    final String texte = t.reseau.horsLigne.toLowerCase();
    expect(texte, isNot(contains('tout')));
    expect(texte, contains('déjà affiché'));
    expect(texte, contains('consultable'));
  });
}
