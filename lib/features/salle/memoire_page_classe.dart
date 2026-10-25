// Lot salle 2 (directeur, 25/10/2026, transmis par le pilote) : la salle se
// souvient de la derniere page du Coran presentee par classe, et y revient a
// l'ouverture suivante, pour l'enseignant (les eleves suivent l'enseignant).
//
// LIMITE, dite au pilote : la memoire vit sur l'appareil, le temps que
// l'application reste ouverte. Rien de serveur ne garde la page d'une classe
// (`session_shared_content` est par seance et attend une ressource de
// bibliotheque pour le mushaf), et le stockage local de l'application n'est
// pas durable sur le web (`StockagePreferencesMemoire`). Quitter puis
// rouvrir la salle dans la meme fenetre retrouve la page ; recharger la page
// du navigateur ou changer d'appareil la perd. La memoire par classe cote
// serveur demande une migration (table et RPC), a decider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La derniere page du Coran presentee, par classe, sur cet appareil.
class MemoirePageClasse {
  final Map<String, int> _pages = <String, int>{};

  /// La derniere page presentee dans la classe [groupeId], ou `null`.
  int? lire(String groupeId) => _pages[groupeId];

  /// Retient [page] pour la classe [groupeId] (1 a 604).
  void ecrire(String groupeId, int page) {
    if (page < 1 || page > 604) return;
    _pages[groupeId] = page;
  }
}

/// La memoire des pages, une pour la vie de l'application.
final Provider<MemoirePageClasse> memoirePageClasseProvider =
    Provider<MemoirePageClasse>((Ref _) => MemoirePageClasse());
