// CLOCHE-C (directeur, 21/11/2026) : la cloche ouvre un panneau (ordinateur)
// ou une feuille (telephone) ; la page complete s'atteint par « Voir tout ».
// Les tests qui allaient a la page par la cloche passent par ce lien.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/notifications/cloche/contenu_cloche.dart';

/// Touche « Voir tout » dans le panneau ou la feuille de la cloche ouverte,
/// puis laisse la page s'installer.
Future<void> toucherVoirTout(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final Finder lien = find.byKey(ContenuCloche.cleVoirTout);
  expect(lien, findsOneWidget, reason: 'la cloche ouvre son panneau');
  await tester.ensureVisible(lien);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(lien);
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
