// COM-RC tour 2, lot E (hors lot C constate) : a 320 x 640, texte x2, la
// colonne du flux de la Communaute debordait de 37 (bandeau des regles,
// categories, entree de la recherche et entree du composer, tous fixes
// autour de la liste). Ils defilent maintenant avec le flux. Mesure avec la
// police des tests, celle du constat du lot C.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/regles_communaute.dart';

import 'banc_communaute.dart';

void main() {
  for (final bool arabe in <bool>[false, true]) {
    testWidgets('320 x 640, texte x2${arabe ? ', arabe' : ''} : le flux ne '
        'deborde pas, l entree du composer s atteint en defilant', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 1aa1ffd6, « A RenderFlex overflowed by 37 pixels »
      // dans la colonne de FluxPublications.
      await monterCommunaute(
        tester,
        taille: const Size(320, 640),
        echelleTexte: 2,
        arabe: arabe,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(BandeauRegles.cle), findsOneWidget);
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      expect(find.byType(ComposerPublication), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
