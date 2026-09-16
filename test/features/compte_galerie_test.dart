import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/_dev/galerie/compte_galerie.dart';

import '../support/harnais.dart';

void main() {
  testWidgets('la galerie Compte expose les fixtures R3', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hote(const CompteGaleriePage()));

    expect(find.text('Profil personnel incomplet'), findsWidgets);
    expect(find.text('Administration et capacites'), findsOneWidget);
    expect(find.text('Tuteur avec plusieurs enfants'), findsOneWidget);
    expect(find.text('Etat vide'), findsOneWidget);
    expect(find.text('Etat erreur'), findsOneWidget);
    expect(find.text('Etat chargement'), findsOneWidget);
    expect(find.text('Etat hors ligne'), findsOneWidget);
    expect(find.text('STUD-AD-000001'), findsOneWidget);
  });

  testWidgets('la fixture admin reste une projection en lecture seule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hote(const CompteGaleriePage()));
    await tester.tap(find.text('Administration et capacites'));
    await tester.pump();

    expect(
      find.text(
        'Fixture de lecture seule. La session porte une autorisation admin; aucune ligne ne peut attribuer un role.',
      ),
      findsOneWidget,
    );
    expect(find.text('Jamais depuis le client'), findsOneWidget);
  });
}
