// Les messages non lus d'une candidature, dans la liste de la direction
// (MESSAGES-CANDIDAT, CAND-Q06) : un message que personne ne voit ne sert a
// rien. Lus par la messagerie metier existante (`fils()`), jamais par un second
// circuit : le serveur ne rend a la direction que les fils de son cote
// (CAND-Q07), donc le compte ne dit rien d'un autre cote.
//
// Sans compte a montrer (capacite indisponible, lecture qui echoue, aucun
// message), rien n'est rendu : la liste reste celle d'avant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/veille_messages.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../com_messages/port_messages_metier.dart';

/// Les messages non lus de chaque candidature (identifiant -> nombre), pour les
/// fils que la direction lit. Relue a chaque ouverture de la liste et a
/// chaque signal de la veille des messages.
final FutureProvider<Map<String, int>> nonLusParCandidatureProvider =
    FutureProvider.autoDispose<Map<String, int>>((Ref ref) async {
      // MESSAGERIE-TEMPS-REEL (14/11/2026) : relue a chaque message recu ou
      // lecture faite, sans rouvrir la liste.
      ref.watch(
        etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.rang),
      );
      try {
        final List<ResumeFil> fils = await ref
            .watch(portMessagesMetierProvider)
            .fils();
        return <String, int>{
          for (final ResumeFil f in fils)
            if (f.objet.type == TypeObjetLie.candidature &&
                f.attention.nonLus > 0)
              f.objet.id: f.attention.nonLus,
        };
      } on CapaciteIndisponible {
        return const <String, int>{};
      }
    }, retry: (int retryCount, Object error) => null);

/// La marque « n messages non lus » d'une candidature, ou rien.
class MarqueMessagesNonLus extends ConsumerWidget {
  /// Cree la marque de la candidature [candidatureId].
  const MarqueMessagesNonLus({required this.candidatureId, super.key});

  /// La candidature.
  final String candidatureId;

  /// La cle de la marque, pour les tests.
  static Key cle(String id) => ValueKey<String>('candidature-non-lus-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int n =
        ref.watch(nonLusParCandidatureProvider).value?[candidatureId] ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: BadgeNonLu(
          key: cle(candidatureId),
          indicateur: IndicateurAttention(nonLus: n),
        ),
      ),
    );
  }
}
