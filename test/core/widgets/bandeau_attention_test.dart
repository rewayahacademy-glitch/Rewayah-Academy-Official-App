// N2 (03/11/2026) : le titre du bandeau est seul en-tete ; son lien reste un
// bouton atteignable. Avant, le drapeau d'en-tete remontait au noeud du
// bandeau entier et, sur le web, le lien disparaissait dans le titre.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';

void main() {
  testWidgets('le titre seul est en-tete, le lien est un bouton a part', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    var touche = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: Scaffold(
          body: BandeauAttention(
            titre: 'Titre du bandeau',
            message: 'Message du bandeau',
            action: LienFleche(
              libelle: 'Voir la suite',
              onPress: () => touche++,
            ),
          ),
        ),
      ),
    );
    final SemanticsNode titre = tester.getSemantics(
      find.text('Titre du bandeau'),
    );
    expect(titre.flagsCollection.isHeader, isTrue);
    expect(titre.label, isNot(contains('Message du bandeau')));
    expect(titre.label, isNot(contains('Voir la suite')));
    final SemanticsNode bandeau = tester.getSemantics(
      find.byType(BandeauAttention),
    );
    expect(bandeau.flagsCollection.isHeader, isFalse);
    // Le lien est un bouton a part, nomme par son seul libelle ; le bandeau
    // garde son message, sans le lien.
    final SemanticsNode lien = tester.getSemantics(find.byType(LienFleche));
    expect(lien.label, 'Voir la suite');
    expect(
      lien.flagsCollection.isButton || lien.flagsCollection.isLink,
      isTrue,
    );
    expect(bandeau.label, isNot(contains('Voir la suite')));
    expect(bandeau.flagsCollection.isButton, isFalse);
    await tester.tap(find.byType(LienFleche));
    await tester.pumpAndSettle();
    expect(touche, 1);
    poignee.dispose();
  });
}
