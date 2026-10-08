// COM-RC (R-25) : dans le composer d'une publication de la Communaute,
// Ctrl+Entree (Cmd+Entree) publie depuis un champ ; Entree seule garde le
// saut de ligne et ne publie rien. Rejoue sur `de2bdb64`, le raccourci
// n'existait pas : le garde n'etait jamais appele.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/port_garde_promotion.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import 'banc_communaute.dart';

void main() {
  for (final (String nom, LogicalKeyboardKey modificateur) cas
      in <(String, LogicalKeyboardKey)>[
        ('Ctrl', LogicalKeyboardKey.controlLeft),
        ('Cmd', LogicalKeyboardKey.metaLeft),
      ]) {
    testWidgets('1440 : ${cas.$1}+Entree publie, Entree seule non', (
      WidgetTester tester,
    ) async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      await monterCommunaute(
        tester,
        taille: const Size(1440, 900),
        autres: <Override>[portGardePromotionProvider.overrideWithValue(garde)],
      );
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      await taper(
        tester,
        find.byKey(
          ComposerPublication.cleCategorie(DonneesCommunauteDemo.pedagogie.id),
        ),
      );
      final BrouillonMarqueDemo marque = DonneesCommunauteDemo.brouillonAffilie;
      await tester.enterText(
        find.byKey(ComposerPublication.cleTitre),
        marque.titre,
      );
      await tester.enterText(
        find.byKey(ComposerPublication.cleTexte),
        marque.texte,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(garde.verifies, isEmpty, reason: 'Entree seule ne publie pas');

      await tester.sendKeyDownEvent(cas.$2);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(cas.$2);
      await tester.pumpAndSettle();
      expect(garde.verifies, hasLength(1), reason: 'le raccourci publie');
      expect(tester.takeException(), isNull);
      await demonter(tester);
    });
  }
}
