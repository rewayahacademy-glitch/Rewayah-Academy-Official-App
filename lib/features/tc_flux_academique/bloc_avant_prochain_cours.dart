import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tc_parcours/libelles_tc_parcours.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/tc_parcours/ports_externes/slot_action.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// Le bloc « Avant le prochain cours » de l'Espace Groupe (spec section 4.3).
///
/// **Ce bloc remplit un slot, il ne construit pas l'Espace Groupe.** La page,
/// son ordre et sa structure appartiennent a Agent A ; le lot H fournit son
/// contenu par `PortTravailAVenir`. Agent Z pose ce widget dans le slot
/// `avantProchainCours` de `GroupHomeVM`.
///
/// **Trois actions au maximum, et le plafond est tenu en amont** : c'est
/// `TravailAVenir` qui borne, pas l'ecran. Un widget qui tronquerait lui-meme
/// masquerait un defaut de contrat au lieu de le rendre visible.
///
/// Son etat vide est un **etat normal**, pas une panne : un groupe sans travail
/// a preparer est un groupe qui va bien. Il le dit d'une phrase et ne propose
/// aucun bouton -- il n'y a rien a faire, et offrir une action serait inviter a
/// inventer une tache.
class BlocAvantProchainCours extends ConsumerWidget {
  /// Cree le bloc pour un groupe, et eventuellement pour un eleve.
  const BlocAvantProchainCours({
    required this.groupeId,
    this.studentId,
    this.onAction,
    super.key,
  });

  /// Le groupe dont on lit le travail a venir.
  final String groupeId;

  /// L'eleve concerne. `null` = le groupe entier.
  final String? studentId;

  /// Ce que l'hote fait d'une action choisie.
  ///
  /// `null` rend le bloc **lisible mais inerte** : c'est l'etat d'integration,
  /// tant qu'Agent Z n'a pas branche la Bibliotheque et le support.
  final void Function(SlotAction action)? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SlotAction>> lecture = ref.watch(
      travailAVenirProvider((groupeId: groupeId, studentId: studentId)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(titre: LibellesParcours.avantTitre),
        Ecart.vMd,
        _corps(context, ref, lecture),
      ],
    );
  }

  /// Les quatre etats, lus par `hasValue` / `hasError`.
  ///
  /// Jamais par le type d'execution de l'`AsyncValue` : Riverpod 3 relance un
  /// provider en echec de lui-meme et l'etat repasse par `AsyncLoading` en
  /// conservant `hasError`. Un `switch` sur le type rendrait le bloc instable
  /// sans qu'aucune donnee ait change.
  Widget _corps(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SlotAction>> lecture,
  ) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    if (!lecture.hasValue) {
      if (lecture.hasError) {
        // Un travail a venir illisible n'est pas un travail absent : on ne
        // remplace jamais une panne par « rien a preparer ».
        return Text(
          LibellesParcours.avantRienDetail,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        );
      }
      return const Skeleton.liste(lignes: 2);
    }

    final List<SlotAction> actions = lecture.requireValue;
    if (actions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(LibellesParcours.avantRien, style: textes.bodyMedium),
          Ecart.vXs,
          Text(
            LibellesParcours.avantRienDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final SlotAction action in actions) ...<Widget>[
          _Action(action: action, onAction: onAction),
          Ecart.vSm,
        ],
      ],
    );
  }
}

/// Une action du bloc.
///
/// L'intention pedagogique se dit par un **mot** dans une pastille, jamais par
/// une couleur seule : `StatusPill` refuse par construction une pastille sans
/// libelle (invariant J7). La couleur derive de l'intention, jamais l'inverse
/// -- et la derivation appartient a Agent D, pas a cet ecran : le lot H se
/// contente du ton neutre, et Agent Z branchera `couleur_intention.dart` a
/// l'integration.
class _Action extends StatelessWidget {
  const _Action({required this.action, this.onAction});

  final SlotAction action;
  final void Function(SlotAction action)? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final void Function(SlotAction)? rappel = onAction;

    return AppCard(
      onPress: rappel == null ? null : () => rappel(action),
      libelleSemantique: action.libelle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (action.intention != null) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(
                libelle: LibellesParcours.intention(action.intention!),
                ton: TonEtat.neutre,
              ),
            ),
            Ecart.vSm,
          ],
          Text(action.libelle, style: textes.bodyLarge),
        ],
      ),
    );
  }
}
