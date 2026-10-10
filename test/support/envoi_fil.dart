// SUPERPOS-1 (decide par delegation le 05/10), repris dans le fil des
// Communications par JONCTION-LIGNES-1 : l'envoi d'un fil de discussion est
// une icone DANS le champ (`ZoneSaisie`), rendue des qu'il y a un texte ;
// champ vide, il n'est jamais grise ni inerte, sa place reste reservee dans
// le champ (`ZoneSaisie.placeEnvoiKey`) et l'explication est ecrite dessous.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';

/// L'envoi du fil : le bouton quand il est rendu (texte saisi), sinon sa
/// place reservee dans le champ. Pour mesurer ou il se pose (a l'ecran,
/// atteignable, a cote du micro), pas pour le toucher champ vide.
Finder envoiDuFil() {
  final Finder bouton = find.byKey(FilDiscussion.envoyerKey);
  if (bouton.evaluate().isNotEmpty) return bouton;
  return find.descendant(
    of: find.byKey(FilDiscussion.champKey),
    matching: find.byKey(ZoneSaisie.placeEnvoiKey),
  );
}

/// Ce que le toucher de l'envoi atteint : le bouton quand il est rendu,
/// sinon le champ qui porte sa place reservee.
Finder cibleEnvoiDuFil() {
  final Finder bouton = find.byKey(FilDiscussion.envoyerKey);
  return bouton.evaluate().isNotEmpty
      ? bouton
      : find.byKey(FilDiscussion.champKey);
}
