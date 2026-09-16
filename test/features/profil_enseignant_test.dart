import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../support/harnais.dart';

void main() {
  group('ENS-05 : Profil Enseignant', () {
    testWidgets('affiche le titre du profil enseignant', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hote(const ProfilEnseignantPage()));
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.profil.titre), findsOneWidget);
    });
  });
}
