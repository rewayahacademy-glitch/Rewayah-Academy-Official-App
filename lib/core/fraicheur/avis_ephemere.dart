// Un avis court en tete de tous les ecrans, qui se retire de lui-meme.
//
// Premier usage (fiche du 27/10/2026, ligne 7) : « Cette classe n'existe
// plus. » quand la classe dont l'ecran est ouvert est supprimee, avant le
// retour a l'accueil du role. Le registre est celui du bandeau hors ligne
// (`OfflineBanner.message`), comme `BandeauNouvelleVersion` : il prend sa
// place dans la colonne de `RewayahApp`, il ne recouvre rien.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/app_icons.dart';
import '../theme/app_mouvement.dart';
import '../widgets/offline_banner.dart';

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

/// Le bandeau de l'avis : rien tant qu'il n'y a rien a dire.
class BandeauAvisEphemere extends ConsumerWidget {
  /// Cree le bandeau.
  const BandeauAvisEphemere({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? avis = ref.watch(avisEphemereProvider);
    if (avis == null) {
      return const SizedBox.shrink();
    }
    return OfflineBanner.message(message: avis, icone: AppIcons.info.repos);
  }
}
