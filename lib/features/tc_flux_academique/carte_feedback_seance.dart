import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/tc_parcours/port_feedback.dart';
import '../../core/tc_parcours/session_feedback.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
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

  /// La phrase dite quand la reponse n'est pas partie.
  static const Key nonPartieKey = ValueKey<String>('feedback-non-partie');

  /// L'action « Reessayer ».
  static const Key reessayerKey = ValueKey<String>('feedback-reessayer');

  @override
  ConsumerState<CarteFeedbackSeance> createState() =>
      _CarteFeedbackSeanceState();
}

class _CarteFeedbackSeanceState extends ConsumerState<CarteFeedbackSeance> {
  bool _repondu = false;

  /// La reponse dont l'envoi a echoue (DECISION-FLUIDITE §1, action
  /// instantanee) : la carte revient a la question, dit en une phrase que la
  /// reponse n'est pas partie et propose « Reessayer » avec la meme reponse.
  ReponseFeedback? _nonPartie;

  /// Vrai quand un identifiant de question inconnu a deja ete journalise.
  bool _inconnuDit = false;

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
    // NON-BRANCHE-LIVRAISON 5 : le texte suit l'identifiant envoye par le
    // serveur, dans la langue de l'ecran ; le sens des valeurs est celui du
    // serveur (0065). Un identifiant inconnu ne montre aucune carte : jamais
    // le texte francais du serveur dans une autre langue.
    final TextesQuestionFeedback? libelles = TextesQuestionFeedback.pour(
      question.id,
      tutoiement: AppMetriques.of(context).mode == InterfaceMode.enfant,
    );
    if (libelles == null) {
      if (!_inconnuDit) {
        _inconnuDit = true;
        journalDev('Retour eclair : question inconnue (${question.id})');
      }
      return const SizedBox.shrink();
    }

    if (_repondu) {
      return AppCard(
        child: Text(t.tc.parcours.feedback.merci, style: textes.bodyMedium),
      );
    }

    final ReponseFeedback? nonPartie = _nonPartie;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(libelles.intitule, style: textes.titleSmall),
          Ecart.vMd,
          if (nonPartie != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                t.tc.parcours.feedback.nonPartie,
                key: CarteFeedbackSeance.nonPartieKey,
                style: AppPalette.of(context).inkAlert
                    .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IntrinsicWidth(
                child: ActionPrincipale(
                  key: CarteFeedbackSeance.reessayerKey,
                  libelle: t.commun.reessayer,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => unawaited(_repondre(question, nonPartie)),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ChoiceCardGroup(
            // Une seule reponse, et aucune saisie libre : « pas de commentaire
            // obligatoire » se tient mieux en n'offrant pas de champ du tout.
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final ReponseFeedback reponse in ReponseFeedback.values)
                OptionChoix(
                  valeur: reponse.valeurSql,
                  libelle: libelles.reponse(reponse),
                ),
            ],
            onChange: (ReponseChoix choix) =>
                unawaited(_repondre(question, _reponseDepuisChoix(choix))),
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
    // Action instantanee (DECISION-FLUIDITE §1) : l'ecran remercie d'abord,
    // l'eleve n'attend pas le reseau pour savoir que son tap a ete pris.
    setState(() {
      _repondu = true;
      _nonPartie = null;
    });
    try {
      await ref
          .read(portFeedbackProvider)
          .soumettre(
            sessionId: widget.sessionId,
            questionId: question.id,
            reponse: reponse,
          );
    } on EchecFeedback catch (e) {
      // Une reponse deja deposee (double tap, rejeu) est un succes : le
      // merci reste. Un envoi perdu revient a l'etat d'avant, avec une
      // phrase courte et « Reessayer » (jamais un merci mensonger).
      if (e.motif == MotifEchecFeedback.ecriture && mounted) {
        setState(() {
          _repondu = false;
          _nonPartie = reponse;
        });
      }
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

/// Les mots d'une question du Retour eclair, choisis par son identifiant
/// serveur (`feedback_questions.id`, migration 0065). Le sens de chaque
/// valeur est celui du serveur : pour « rythme », `difficile` = trop lent et
/// `tres_bien` = trop rapide.
@immutable
class TextesQuestionFeedback {
  const TextesQuestionFeedback._({
    required this.intitule,
    required this.difficile,
    required this.bien,
    required this.tresBien,
  });

  /// Les mots de la question [id], ou `null` quand l'identifiant est
  /// inconnu. [tutoiement] : l'Interface guidee tutoie l'enfant
  /// (mots-rewayah).
  static TextesQuestionFeedback? pour(String id, {required bool tutoiement}) {
    final f = t.tc.parcours.feedback;
    return switch (id) {
      'comprehension' => TextesQuestionFeedback._(
        intitule: tutoiement
            ? f.comprehension.intituleTu
            : f.comprehension.intitule,
        difficile: f.comprehension.difficile,
        bien: f.comprehension.bien,
        tresBien: f.comprehension.tresBien,
      ),
      'rythme' => TextesQuestionFeedback._(
        intitule: f.rythme.intitule,
        difficile: f.rythme.difficile,
        bien: f.rythme.bien,
        tresBien: f.rythme.tresBien,
      ),
      'participation' => TextesQuestionFeedback._(
        intitule: tutoiement
            ? f.participation.intituleTu
            : f.participation.intitule,
        difficile: f.participation.difficile,
        bien: f.participation.bien,
        tresBien: f.participation.tresBien,
      ),
      _ => null,
    };
  }

  /// La question.
  final String intitule;

  /// Les trois reponses, dans le sens du serveur.
  final String difficile;
  final String bien;
  final String tresBien;

  /// Le mot d'une reponse.
  String reponse(ReponseFeedback r) => switch (r) {
    ReponseFeedback.difficile => difficile,
    ReponseFeedback.bien => bien,
    ReponseFeedback.tresBien => tresBien,
  };
}
