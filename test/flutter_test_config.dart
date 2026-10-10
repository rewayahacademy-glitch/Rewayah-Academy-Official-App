// Configuration commune a toute la suite `test/` (lue par `flutter test`
// pour chaque fichier de test sous ce dossier).
//
// DUREE-FOND-1 : la garde des ancres de sens a l'execution
// (`test/support/garde_ancres_execution.dart`) tourne a la fin de chaque
// `testWidgets` : aucun ecran exerce par la suite ne rend une ancre U+200E ou
// U+200F ailleurs qu'en tete d'une chaine, quelle que soit la forme du code.

import 'dart:async';

import 'support/garde_ancres_execution.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BindingGardeAncres.installer();
  await testMain();
}
