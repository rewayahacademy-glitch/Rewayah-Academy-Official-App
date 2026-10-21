// La note en etoiles (avis) : cinq cibles de 48 en saisie, une phrase en
// lecture, jamais la couleur seule.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/note_etoiles.dart';

import '../../support/harnais.dart';

void main() {
  testWidgets('saisie : cinq cibles de 48, la note touchee est rendue', (
    tester,
  ) async {
    int note = 0;
    await tester.pumpWidget(
      hote(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Scaffold(
            body: NoteEtoiles(
              valeur: note,
              onChange: (int n) => setState(() => note = n),
            ),
          ),
        ),
      ),
    );
    for (int n = 1; n <= 5; n++) {
      final Size taille = tester.getSize(find.byKey(NoteEtoiles.etoileKey(n)));
      expect(taille.width, greaterThanOrEqualTo(48));
      expect(taille.height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.byKey(NoteEtoiles.etoileKey(3)));
    await tester.pump();
    expect(note, 3);
    // Toucher la note retenue ne la relache pas.
    await tester.tap(find.byKey(NoteEtoiles.etoileKey(3)));
    await tester.pump();
    expect(note, 3);
  });

  testWidgets('lecture : une phrase, aucune etoile ne se touche', (
    tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.pumpWidget(hote(const Scaffold(body: NoteEtoiles(valeur: 4))));
    expect(find.bySemanticsLabel(t.avis.form.note.lue(n: 4)), findsOneWidget);
    expect(find.byType(GestureDetector), findsNothing);
    h.dispose();
  });
}
