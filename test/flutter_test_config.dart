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
import 'package:rewayah_academy/core/theme/polices_differees.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';
import 'package:rewayah_academy/core/widgets/scene_attente.dart';
import 'package:rewayah_academy/features/tc_mushaf/routes_tc_c.dart';

import 'support/garde_ancres_execution.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BindingGardeAncres.installer();
  // Scene d'attente de la salle (11/11/2026) : ses ondes tournent tant que
  // l'attente dure ; dans la suite, elles restent posees, sinon aucun
  // `pumpAndSettle` d'un ecran qui attend ne rendrait la main. Le test du
  // composant rallume la boucle pour la verifier.
  SceneAttente.boucle = false;
  // VISAGES (12/11/2026) : la lumiere de l'orateur ondule tant que la
  // personne parle ; dans la suite, ses vagues restent posees (meme raison).
  HaloLumiere.boucleVoix = false;
  // Polices differees (PR 265) : `flutter test` ne charge que les familles de
  // la section `fonts` du fichier de configuration. Les polices du Coran,
  // deplacees dans `assets`, sont chargees ici depuis leur asset. La police
  // arabe d'interface, elle, n'est chargee que lorsque l'arabe est applique,
  // comme dans l'application : `BindingGardeAncres.pump`.
  await chargerPolicesDifferees(familles: policesApresPremiereImage);
  for (final (String cle, Future<void> Function() charger) in <MorceauDiffere>[
    ...morceauxDifferesRouteur,
    ...morceauxDifferesTcC,
  ]) {
    await PageDifferee.precharger(cle, charger);
  }
  await testMain();
}
