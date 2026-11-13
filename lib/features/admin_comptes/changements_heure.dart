// HORLOGE-ET-LIEU, correction I7 (13/11/2026) : les changements d'heure a venir,
// par fuseau des familles et des enseignants (combien de personnes, quelle date,
// quel decalage). Depuis que toutes les classes sont a l'heure de La Mecque,
// `transitions_fuseau_a_venir` (par classe) est vide : cet ecran lit les
// fuseaux des PERSONNES. Quand il n'y en a pas, il le dit : jamais un ecran vide.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/lieu/lieu_direction.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart' show dateLongueHistorique;

/// Le bloc des changements d'heure a venir.
class BlocChangementsHeure extends ConsumerWidget {
  /// Cree le bloc.
  const BlocChangementsHeure({super.key});

  /// Cle du bloc.
  static const Key cle = ValueKey<String>('changements-heure-a-venir');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChangementHeureAVenir>> lecture = ref.watch(
      changementsHeureProvider,
    );
    final l = t.lieu;
    if (lecture.isLoading && !lecture.hasValue) {
      return const SizedBox.shrink();
    }
    if (lecture.hasError && !lecture.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: BandeauAttention(
          key: cle,
          titre: l.changementsTitre,
          message: l.changementsErreur,
        ),
      );
    }
    final List<ChangementHeureAVenir> liste =
        lecture.value ?? const <ChangementHeureAVenir>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BandeauAttention(
        key: cle,
        titre: l.changementsTitre,
        ton: TonEtat.neutre,
        message: liste.isEmpty
            ? l.changementsAucun(jours: '$joursChangementsHeure')
            : liste
                  .map(
                    (ChangementHeureAVenir c) => l.changementsLigne(
                      date: dateLongueHistorique(c.transition),
                      ville: villeDuFuseauLibelle(c.fuseau),
                      familles: '${c.familles}',
                      enseignants: '${c.enseignants}',
                      avant: libelleDecalageUtc(c.decalageAvant),
                      apres: libelleDecalageUtc(c.decalageApres),
                    ),
                  )
                  .join('\n'),
      ),
    );
  }
}
