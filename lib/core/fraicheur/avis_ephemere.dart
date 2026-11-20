// Un avis court en tete de tous les ecrans, qui se retire de lui-meme.
//
// Premier usage (fiche du 27/10/2026, ligne 7) : « Cette classe n'existe
// plus. » quand la classe dont l'ecran est ouvert est supprimee, avant le
// retour a l'accueil du role. Second usage : « Vous avez recu un nouveau
// message. » (`veille_messages.dart`).
//
// PE-D8 (directeur, 19/11/2026) : il ne prend plus sa place dans une colonne
// au-dessus de l'ecran (il poussait toute la page et faisait rater un
// toucher) ; c'est un `AvisFlottant`, pose par-dessus dans `CoucheAvis`, qui
// se ferme seul, par sa croix ou en le glissant vers le haut.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_mouvement.dart';
import 'avis_flottant.dart';

/// L'avis a montrer, `null` quand il n'y en a aucun.
final NotifierProvider<AvisEphemereControleur, String?> avisEphemereProvider =
    NotifierProvider<AvisEphemereControleur, String?>(
      AvisEphemereControleur.new,
    );

/// Porte l'avis et l'efface apres [AppMouvement.retourLocalMaintien], le
/// temps de maintien d'un retour local.
class AvisEphemereControleur extends Notifier<String?> {
  Timer? _minuteur;

  @override
  String? build() {
    ref.onDispose(() => _minuteur?.cancel());
    return null;
  }

  /// Montre [message] ; un nouvel avis remplace le precedent et repart pour
  /// la duree entiere.
  void dire(String message) {
    _minuteur?.cancel();
    state = message;
    _minuteur = Timer(AppMouvement.retourLocalMaintien, effacer);
  }

  /// Retire l'avis.
  void effacer() {
    _minuteur?.cancel();
    _minuteur = null;
    state = null;
  }
}

/// L'avis flottant : rien tant qu'il n'y a rien a dire.
class BandeauAvisEphemere extends ConsumerWidget {
  /// Cree l'avis.
  const BandeauAvisEphemere({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? avis = ref.watch(avisEphemereProvider);
    return PassageAvis(
      child: avis == null
          ? null
          : AvisFlottant(
              // La cle porte le message : un nouvel avis rejoue l'entree.
              key: ValueKey<String>('avis-ephemere-$avis'),
              message: avis,
              onFermer: ref.read(avisEphemereProvider.notifier).effacer,
            ),
    );
  }
}
