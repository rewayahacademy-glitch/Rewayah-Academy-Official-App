import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le signal « les personnes ont change » de l'administration (dette D2,
/// directeur, 07/11/2026 : un profil retire restait affiche jusqu'a la
/// deconnexion).
///
/// Les listes de personnes de l'administration (comptes, compteurs de
/// l'accueil, paiements, remboursements, progression, diagnostics, membres
/// des classes, familles importees, dossiers) sont lues une fois et gardees
/// pour toute la session. Une suppression les invalidait une par une, et
/// seule la liste des comptes l'etait : les autres gardaient la personne
/// jusqu'a la deconnexion. Chacune ecoute desormais ce signal ; une
/// suppression ou une restauration confirmee par le serveur le leve, et
/// toutes sont relues.
///
/// Geste sensible (DECISION-FLUIDITE §1, « supprimer, retirer ») : le signal
/// part **apres** la reponse du serveur, jamais avant.
class PersonnesModifiees extends Notifier<int> {
  @override
  int build() => 0;

  /// Dit que des personnes ont ete supprimees ou restaurees.
  void signaler() => state++;
}

/// Le signal, ecoute par chaque liste de personnes de l'administration.
final NotifierProvider<PersonnesModifiees, int> personnesModifieesProvider =
    NotifierProvider<PersonnesModifiees, int>(PersonnesModifiees.new);
