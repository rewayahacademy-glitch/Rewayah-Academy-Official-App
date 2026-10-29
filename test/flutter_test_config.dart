// Configuration commune a toute la suite `test/` (lue par `flutter test`
// pour chaque fichier de test sous ce dossier).
//
// DUREE-FOND-1 : la garde des ancres de sens a l'execution
// (`test/support/garde_ancres_execution.dart`) tourne a la fin de chaque
// `testWidgets` : aucun ecran exerce par la suite ne rend une ancre U+200E ou
// U+200F ailleurs qu'en tete d'une chaine, quelle que soit la forme du code.
//
// Lot ouverture rapide (29/10/2026) : les ecrans en import differe sont
// precharges une fois, avant les tests. Sans cela, un test qui pompe une
// image apres la navigation verrait la zone vide du chargement.

import 'dart:async';

import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/page_differee.dart';
import 'package:rewayah_academy/features/tc_mushaf/routes_tc_c.dart';

import 'support/garde_ancres_execution.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BindingGardeAncres.installer();
  for (final (String cle, Future<void> Function() charger) in <MorceauDiffere>[
    ...morceauxDifferesRouteur,
    ...morceauxDifferesTcC,
  ]) {
    await PageDifferee.precharger(cle, charger);
  }
  await testMain();
}
