import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../support/harnais.dart';

void main() {
  group('ELV-05 : Suivi Élève', () {
    testWidgets('affiche le titre et les éléments principaux de suivi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hote(const SuiviElevePage()));
      await tester.pumpAndSettle();

      expect(find.text(t.eleve.suivi.titre), findsOneWidget);
    });
  });
}
