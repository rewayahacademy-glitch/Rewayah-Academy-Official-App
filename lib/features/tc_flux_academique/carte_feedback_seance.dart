import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tc_parcours/libelles_tc_parcours.dart';
import '../../core/tc_parcours/port_feedback.dart';
import '../../core/tc_parcours/session_feedback.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/choice_card_group.dart';

/// Le micro-feedback d'une seance (spec section 12.1).
///
/// **La carte n'existe pas la plupart du temps, et c'est la regle.**
/// L'echantillonnage est configurable et non systematique : quand
/// `PortFeedback.questionPour` rend `null`, ce widget rend un espace **nul**,
/// pas un emplacement vide ni un squelette. Un eleve a qui l'on demande son
/// avis apres chaque cours cesse de le donner.
///
/// **Un tap, termine.** Aucun champ de commentaire, aucune validation, aucune
/// deuxieme etape. La question change d'une fois sur l'autre -- cinq volets en
/// rotation -- et une question ne revient qu'apres que les autres ont ete
/// posees : c'est `RotationFeedback` qui le garantit, pas cet ecran.
///
/// Les trois visages de la maquette sont rendus par des **mots**. Le depot
/// interdit l'emoji dans le code comme dans les libelles
/// (`tool/verifier_jetons.dart`), et un mot se lit a voix haute pour
/// l'Interface guidee, ce qu'un caractere pictographique ne fait pas.
class CarteFeedbackSeance extends ConsumerStatefulWidget {
  /// Cree la carte de feedback d'une seance.
  const CarteFeedbackSeance({required this.sessionId, super.key});

  /// La seance sur laquelle on demande un avis.
  final String sessionId;

  @override
  ConsumerState<CarteFeedbackSeance> createState() =>
      _CarteFeedbackSeanceState();
}

class _CarteFeedbackSeanceState extends ConsumerState<CarteFeedbackSeance> {
  bool _repondu = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<QuestionFeedback?> lecture = ref.watch(
      questionFeedbackProvider(widget.sessionId),
    );

    // Ni chargement, ni erreur visibles : un avis facultatif ne merite ni
    // squelette ni message d'echec. Ce qui ne peut pas etre demande n'est
    // simplement pas demande.
    final QuestionFeedback? question = lecture.hasValue
        ? lecture.requireValue
        : null;
    if (question == null) {
      return const SizedBox.shrink();
    }

    if (_repondu) {
      return AppCard(
        child: Text(LibellesParcours.feedbackMerci, style: textes.bodyMedium),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(question.intitule, style: textes.titleSmall),
          Ecart.vMd,
          ChoiceCardGroup(
            // Une seule reponse, et aucune saisie libre : « pas de commentaire
            // obligatoire » se tient mieux en n'offrant pas de champ du tout.
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final ReponseFeedback reponse in ReponseFeedback.values)
                OptionChoix(
                  valeur: reponse.valeurSql,
                  libelle: question.libelles[reponse] ?? reponse.valeurSql,
                ),
            ],
            onChange: (ReponseChoix choix) => unawaited(
              _repondre(question, _reponseDepuisChoix(choix)),
            ),
          ),
        ],
      ),
    );
  }

  /// Depose la reponse. Un seul geste, et la carte se retire.
  Future<void> _repondre(
    QuestionFeedback question,
    ReponseFeedback? reponse,
  ) async {
    if (reponse == null || _repondu) {
      return;
    }
    // L'ecran remercie d'abord : le depot est un detail de plomberie, et un
    // eleve n'a pas a attendre le reseau pour savoir que son tap a ete pris.
    setState(() => _repondu = true);
    try {
      await ref
          .read(portFeedbackProvider)
          .soumettre(
            sessionId: widget.sessionId,
            questionId: question.id,
            reponse: reponse,
          );
    } on EchecFeedback {
      // Un avis facultatif perdu ne produit aucun message d'erreur : on ne
      // transforme pas une amabilite en corvee a recommencer.
    }
  }
}

/// Traduit la reponse de `ChoiceCardGroup` en [ReponseFeedback].
///
/// `ChoiceCardGroup` parle en chaines et accepte une selection multiple : la
/// conversion refuse tout ce qui n'est pas exactement un choix, plutot que de
/// prendre le premier venu. Un `null` ne depose rien.
ReponseFeedback? _reponseDepuisChoix(ReponseChoix choix) {
  if (choix.valeurs.length != 1) {
    return null;
  }
  return ReponseFeedback.depuisSql(choix.valeurs.first);
}
