import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'roster_classe_vm.dart';

/// La file de recitation du cours en cours.
///
/// **Un seul controleur, non parametre par seance, et c'est exact** : il n'y a
/// qu'une salle connectee a la fois -- `moteurSalleProvider` est un Provider
/// racine, donc une seule `Room`. Une famille par seance suggererait deux cours
/// simultanes, ce que le produit ne permet pas.
///
/// Il vit **au niveau applicatif**, comme le cours lui-meme : revenir au Groupe
/// puis a la Classe ne remet pas la file a zero. C'est la meme raison qui fait
/// vivre `ControleurSessionPersistante` hors des ecrans.
///
/// **Rien ici ne touche au support.** La file ne porte que des identifiants
/// d'academie : changer d'eleve ne peut pas, structurellement, deplacer la page,
/// le focus, le stylet ou le support presente (spec section 10.3). Le professeur
/// corrige en parlant a son micro.
///
/// TC-Z-SUIVI : `t.tc.classe.recitation.titre`/`.suivants`/`.personne`/
/// `.arreter` (et `.actif` via `reciteEnCeMoment`) n'ont encore aucun widget --
/// seule la pastille par ligne du roster (`t.tc.classe.recitation.pastille`,
/// voir `roster_classe.dart`) est branchee. Le bloc dedie "qui recite, qui est
/// ensuite, arreter la file" reste a construire.
class ControleurRecitation extends Notifier<FileRecitation> {
  @override
  FileRecitation build() => FileRecitation.vide;

  /// Donne la parole a un eleve.
  void donnerLaParoleA(String academyId) =>
      state = state.donnerLaParoleA(academyId);

  /// Rend la file au repos : plus personne ne recite.
  void arreter() => state = state.sansActif;

  /// Remplace la file d'attente, sans toucher a qui recite.
  void poserLaFile(List<String> academyIds) =>
      state = state.avecFile(academyIds);

  /// Oublie tout. Appele a la sortie du cours, jamais a la sortie d'un ecran.
  void reinitialiser() => state = FileRecitation.vide;
}

/// La file de recitation courante.
final NotifierProvider<ControleurRecitation, FileRecitation>
recitationProvider = NotifierProvider<ControleurRecitation, FileRecitation>(
  ControleurRecitation.new,
);
