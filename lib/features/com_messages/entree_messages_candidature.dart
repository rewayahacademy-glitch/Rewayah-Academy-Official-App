// L'entree des messages dans le portail du candidat (MESSAGES-CANDIDAT,
// CAND-Q06) : « Ecrire a l'Administration » et le badge des messages non lus
// de SA candidature, par l'entree des Messages metier existante
// (`EntreeMessagesContexte`, aucun second circuit).
//
// Elle lit l'identifiant de la candidature (`maCandidatureIdProvider`), puis
// laisse l'entree dire le reste : conversations, non lus, ouverture, et ses
// etats (chargement, erreur, hors ligne, capacite indisponible). Tant que
// l'identifiant n'est pas lu, ou si le serveur ne l'ouvre pas, rien n'est
// rendu : une page sans messagerie reste celle d'avant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/ma_candidature_fil.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'entree_messages_contexte.dart';
import 'port_messages_metier.dart';

/// L'entree des messages du candidat, posee sous l'etat de sa candidature.
class EntreeMessagesCandidature extends ConsumerWidget {
  /// Cree l'entree. [ecartAvant] se pose avant le contenu, s'il y en a un.
  const EntreeMessagesCandidature({super.key, this.ecartAvant});

  /// L'ecart a poser avant l'entree, jamais rendu tant qu'elle est vide.
  final Widget? ecartAvant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> id = ref.watch(maCandidatureIdProvider);
    if (id.hasError && id.error is! CapaciteIndisponible) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ?ecartAvant,
          VueEtatCommunication(
            etat: horsLigne
                ? EtatCommunication.horsLigne
                : EtatCommunication.erreur,
            onReessayer: () => ref.invalidate(maCandidatureIdProvider),
          ),
        ],
      );
    }
    final String? v = id.hasValue ? id.value : null;
    if (v == null) return const SizedBox.shrink();
    return EntreeMessagesContexte(
      type: TypeObjetLie.candidature,
      objetId: v,
      ecartAvant: ecartAvant,
    );
  }
}
