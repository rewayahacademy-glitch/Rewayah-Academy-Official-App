// NON-BRANCHE-LIVRAISON 5 (08/11/2026) : le Retour eclair, cote enseignant.
//
// Les eleves repondent, apres certaines seances, a une question courte
// (`CarteFeedbackSeance`). L'enseignant ne lit jamais une reponse : il lit
// l'agregat de comprehension de sa Classe, et seulement au-dessus du seuil
// du serveur (`tendance_feedback_comprehension`, migration 0065). Rien a
// faire pour lui : c'est une lecture.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_parcours/port_feedback.dart';
import '../../core/tc_parcours/session_feedback.dart';
import '../../core/widgets/groupe_reglages.dart';

/// La tendance de comprehension d'une Classe. Pendant la lecture, rien ;
/// sous le seuil, une phrase le dit ; un echec se dit comme une panne et se
/// relit au toucher, jamais comme « pas assez de retours ».
class BlocTendanceFeedback extends ConsumerWidget {
  /// Cree le bloc.
  const BlocTendanceFeedback({required this.groupeId, super.key});

  /// La Classe.
  final String groupeId;

  /// La cle du bloc quand la tendance est visible.
  static const Key visibleKey = ValueKey<String>('tendance-feedback-visible');

  /// La cle du bloc sous le seuil.
  static const Key sousSeuilKey = ValueKey<String>(
    'tendance-feedback-sous-seuil',
  );

  /// La cle du bloc en echec.
  static const Key echecKey = ValueKey<String>('tendance-feedback-echec');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = t.tc.parcours.feedback;
    final AsyncValue<TendanceFeedback> lue = ref.watch(
      tendanceFeedbackProvider(groupeId),
    );
    if (lue.isLoading && !lue.hasValue && !lue.hasError) {
      return const SizedBox.shrink();
    }
    if (lue.hasError && !lue.hasValue) {
      return GroupeReglages(
        key: echecKey,
        titre: f.tendance.titre,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.suivi,
            libelle: f.tendance.illisible,
            onPress: () => ref.invalidate(tendanceFeedbackProvider(groupeId)),
          ),
        ],
      );
    }
    final TendanceFeedback tendance = lue.requireValue;
    final Map<ReponseFeedback, double>? repartition = tendance.repartition;
    if (!tendance.visibleParEnseignant || repartition == null) {
      return GroupeReglages(
        key: sousSeuilKey,
        titre: f.tendance.titre,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.suivi,
            libelle: f.tendance.sousSeuil,
            legende: f.tendance.anonyme,
          ),
        ],
      );
    }
    String libelle(ReponseFeedback r) => switch (r) {
      ReponseFeedback.difficile => f.comprehension.difficile,
      ReponseFeedback.bien => f.comprehension.bien,
      ReponseFeedback.tresBien => f.comprehension.tresBien,
    };
    return GroupeReglages(
      key: visibleKey,
      titre: f.tendance.titre,
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.suivi,
          libelle: f.comprehension.intitule,
          legende: <String>[
            for (final ReponseFeedback r in ReponseFeedback.values)
              f.tendance.ligne(
                reponse: libelle(r),
                part: '${((repartition[r] ?? 0) * 100).round()}',
              ),
            f.tendance.anonyme,
          ].join('\n'),
        ),
      ],
    );
  }
}
