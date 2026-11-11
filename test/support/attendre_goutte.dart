// GOUTTE D'HUILE DES PROFILS (11/11/2026) : au toucher d'un profil, le cou entre
// les ronds et la chute du nouveau contenu se jouent ensemble (plus d'aspiration
// de l'ancien contenu) et durent 360 ms au plus, sous `AppMouvement.plafond`.
// Un test qui cherche le contenu du nouveau profil attend la fin
// REELLE du mouvement (l'etat de la goutte, jamais une duree ecrite en dur) : si
// les durees changent, le test suit, il n'est pas affaibli.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/goutte_profils.dart';

/// Avance le temps, image par image, tant qu'un cou ou une chute est en cours
/// sous une `GoutteProfils`. Sans portee a l'ecran, ne fait rien.
Future<void> attendreGoutteFinie(WidgetTester tester) async {
  for (int i = 0; i < 300; i++) {
    final Finder portees = find.byType(ContenuGoutte);
    if (portees.evaluate().isEmpty) return;
    final BuildContext contexte = tester.element(portees.first);
    if (GoutteProfils.goutteDe(contexte) == null &&
        GoutteProfils.chuteDe(contexte) == null) {
      // Une image de plus : la phase de repos est posee.
      await tester.pump(const Duration(milliseconds: 16));
      return;
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('la goutte des profils ne finit jamais');
}
