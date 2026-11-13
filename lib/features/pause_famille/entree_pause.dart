// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : l'entree « Demander une pause
// d'un mois », une ligne sous la carte de suivi : chez le tuteur pour l'enfant
// choisi, chez l'eleve adulte pour lui-meme. Jamais chez un enfant : il n'est
// pas celui qui demande (le serveur refuse aussi).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';

/// La ligne d'entree vers la demande de pause.
class EntreePause extends ConsumerWidget {
  /// Cree l'entree. [eleveId] nul : l'eleve adulte connecte, pour lui-meme.
  const EntreePause({this.eleveId, super.key});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('entree-pause');

  /// L'enfant du tuteur ; nul pour l'eleve adulte.
  final String? eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portPausesProvider) == null) {
      return const SizedBox.shrink();
    }
    final String? enfant = eleveId;
    if (enfant == null) {
      // Sans enfant donne : l'eleve connecte, seulement s'il est adulte. Une
      // session illisible (ecran monte sans source de session) ne montre rien.
      bool adulte;
      try {
        adulte = ref.watch(sessionProvider).barreEleveAdulte;
      } on Object {
        adulte = false;
      }
      if (!adulte) return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: LienFleche(
        key: ligneKey,
        libelle: t.pause.entree,
        alignerEnDebut: true,
        onPress: () => unawaited(
          context.push(
            enfant == null ? Routes.elevePause : Routes.tuteurPause(enfant),
          ),
        ),
      ),
    );
  }
}
