// La pastille « Praxis propose » d'une candidature dans la file de la direction
// (PX-2) : Praxis a prepare un geste, personne ne l'a encore valide ni ecarte.
// Lue par la meme lecture que le dossier (`direction_praxis_propositions`, les
// cotes de la direction qui lit). Une lecture qui echoue, ou aucune proposition :
// rien n'est rendu, la liste reste celle d'avant (le dossier, lui, relit et
// montre les propositions).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/propositions_praxis.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/status_pill.dart';

/// La pastille « Praxis propose » du dossier [reference], ou rien.
class MarquePropositionsPraxis extends ConsumerWidget {
  /// Cree la marque.
  const MarquePropositionsPraxis({required this.reference, super.key});

  /// La reference de la candidature (`CAND-...`).
  final String reference;

  /// La cle de la marque, pour les tests.
  static Key cle(String reference) =>
      ValueKey<String>('candidature-praxis-propose-$reference');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool propose =
        (ref.watch(propositionsPraxisProvider).value ??
                const <PropositionPraxis>[])
            .any((PropositionPraxis x) => x.reference == reference);
    if (!propose) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: StatusPill(
          key: cle(reference),
          libelle: t.admin.praxis.propositions.pastille,
          ton: TonEtat.accent,
        ),
      ),
    );
  }
}
