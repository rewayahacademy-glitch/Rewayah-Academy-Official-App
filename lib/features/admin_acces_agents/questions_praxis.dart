// PX-SUIVI : « Questions de Praxis », dans la section Praxis. Quand Praxis ne
// sait pas, il demande a l'equipe : la question (resumee par lui, jamais le
// texte de la personne) arrive ici. La direction repond ; Praxis revient vers la
// personne a son prochain passage. La question reste visible, « Sans reponse »,
// tant qu'elle n'a pas de reponse.
//
// Les cinq etats : chargement (squelette), contenu (la liste), vide, erreur
// (phrase vraie et « Reessayer »), hors ligne (l'etat commun). Repondre est un
// geste sensible : il attend le serveur (double verification, une seule reponse).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/agent/questions_praxis.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../mfa_controleur/double_verification.dart';

/// Les cles de test et de garde du bloc.
abstract final class ClesQuestionsPraxis {
  /// Le bloc entier.
  static const Key bloc = ValueKey<String>('praxis-questions');

  /// La phrase « aucune question ».
  static const Key vide = ValueKey<String>('praxis-questions-vide');

  /// Le champ de la reponse, dans la feuille.
  static const Key champReponse = ValueKey<String>('praxis-question-reponse');

  /// « Envoyer a Praxis », dans la feuille.
  static const Key envoyer = ValueKey<String>('praxis-question-envoyer');

  /// « Ouvrir la conversation », dans la feuille.
  static const Key conversation = ValueKey<String>('praxis-question-fil');
}

/// Le bloc « Questions de Praxis ».
class QuestionsPraxis extends ConsumerStatefulWidget {
  /// Cree le bloc.
  const QuestionsPraxis({super.key});

  @override
  ConsumerState<QuestionsPraxis> createState() => _QuestionsPraxisEtat();
}

class _QuestionsPraxisEtat extends ConsumerState<QuestionsPraxis> {
  String? _message;
  String? _erreur;

  // HEURES-PROFIL H2 : a l'heure du profil.
  String _quand(DateTime instant) {
    final DateTime date = chezMoi(instant);
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${heureChezMoi(instant)}';
  }

  Future<void> _repondre(QuestionPraxis q) async {
    final String? texte = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.praxis.questions.feuilleTitre,
      constructeur: (BuildContext contexte) => _FeuilleReponse(
        question: q,
        onOuvrirConversation: () {
          Navigator.of(contexte).pop();
          context.push(Routes.adminFilPour(q.filId));
        },
        onEnvoyer: (String r) => Navigator.of(contexte).pop(r),
      ),
    );
    if (texte == null || !mounted) return;
    String? message;
    String? erreur;
    try {
      final ResultatQuestion r = await avecDoubleVerification<ResultatQuestion>(
        context,
        ref,
        () => ref
            .read(serviceQuestionsPraxisProvider)
            .repondre(id: q.id, texte: texte),
      );
      if (r.fait) {
        message = t.admin.praxis.questions.repondue;
      } else {
        erreur = switch (r.erreur) {
          'deja_repondue' => t.admin.praxis.questions.erreurDejaRepondue,
          'inconnue' => t.admin.praxis.questions.erreurInconnue,
          _ => t.admin.praxis.questions.erreurEnvoi,
        };
      }
    } on Object catch (e) {
      erreur = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.questions.erreurEnvoi;
    }
    // La liste est relue dans tous les cas : l'ecran dit ce que la base dit.
    ref.invalidate(questionsPraxisProvider);
    if (!mounted) return;
    setState(() {
      _message = message;
      _erreur = erreur;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(monHorlogeProvider);
    final AsyncValue<List<QuestionPraxis>> lues = ref.watch(
      questionsPraxisProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final int ouvertes = lues.hasValue
        ? lues.requireValue.where((QuestionPraxis q) => q.ouverte).length
        : 0;
    return Column(
      key: ClesQuestionsPraxis.bloc,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: t.admin.praxis.questions.titre,
          compteur: lues.hasValue ? ouvertes : null,
        ),
        Ecart.vSm,
        Text(t.admin.praxis.questions.intro, style: textes.bodyMedium),
        Ecart.vLg,
        LocalFeedback(message: _message),
        if (_erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          Ecart.vLg,
        ],
        _corps(context, lues),
      ],
    );
  }

  Widget _corps(BuildContext context, AsyncValue<List<QuestionPraxis>> lues) {
    // Riverpod 3 relance un fournisseur en echec : on lit hasValue, hasError et
    // isLoading, jamais le type de l'AsyncValue.
    if (lues.hasError && !lues.hasValue) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      if (horsLigne) {
        return EtatSansDonnees(
          quoi: t.admin.praxis.questions.horsLigne,
          onAction: () => ref.invalidate(questionsPraxisProvider),
        );
      }
      return EmptyState(
        message: t.admin.praxis.questions.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(questionsPraxisProvider),
      );
    }
    if (!lues.hasValue) return const Skeleton.liste();
    final List<QuestionPraxis> questions = lues.requireValue;
    if (questions.isEmpty) {
      return KeyedSubtree(
        key: ClesQuestionsPraxis.vide,
        child: EmptyState(
          message: t.admin.praxis.questions.vide,
          invitation: t.admin.praxis.questions.videDetail,
          icone: AppIcons.rienAAfficher,
          registre: RegistreVide.bonneNouvelle,
        ),
      );
    }
    return DataCollection<QuestionPraxis>(
      defileSeule: false,
      defileAvecLaPage: true,
      lignes: questions,
      colonnes: <ColonneDonnees<QuestionPraxis>>[
        ColonneDonnees<QuestionPraxis>(
          titre: t.admin.praxis.questions.colonneQuand,
          role: RoleColonne.identifiante,
          tabulaire: true,
          texte: (QuestionPraxis q) => _quand(q.poseeLe),
        ),
        ColonneDonnees<QuestionPraxis>(
          titre: t.admin.praxis.questions.colonneQuestion,
          flex: 3,
          texte: (QuestionPraxis q) => q.question,
        ),
        ColonneDonnees<QuestionPraxis>(
          titre: t.admin.praxis.questions.colonneStatut,
          texte: _statut,
          rendu: (BuildContext _, QuestionPraxis q) =>
              StatusPill(libelle: _statut(q), ton: _ton(q)),
        ),
        ColonneDonnees<QuestionPraxis>(
          titre: t.admin.praxis.questions.colonneReponse,
          role: RoleColonne.aPart,
          flex: 3,
          texte: (QuestionPraxis q) => q.reponse ?? '',
        ),
      ],
      actionsLigne: (BuildContext contexte, QuestionPraxis q) => MenuActions(
        points: true,
        libelle: t.admin.praxis.questions.actions,
        actions: <EntreeAction>[
          if (q.ouverte)
            EntreeAction(
              libelle: t.admin.praxis.questions.actionRepondre,
              onChoix: () => unawaited(_repondre(q)),
            ),
          EntreeAction(
            libelle: t.admin.praxis.questions.actionConversation,
            onChoix: () => contexte.push(Routes.adminFilPour(q.filId)),
          ),
        ],
      ),
    );
  }

  String _statut(QuestionPraxis q) => q.ouverte
      ? t.admin.praxis.questions.statutOuverte
      : q.transmise
      ? t.admin.praxis.questions.statutTransmise
      : t.admin.praxis.questions.statutRepondue;

  TonEtat _ton(QuestionPraxis q) => q.ouverte
      ? TonEtat.avertissement
      : q.transmise
      ? TonEtat.succes
      : TonEtat.neutre;
}

/// La feuille de reponse : la question de Praxis, le champ, un seul bouton plein.
class _FeuilleReponse extends StatefulWidget {
  const _FeuilleReponse({
    required this.question,
    required this.onEnvoyer,
    required this.onOuvrirConversation,
  });

  final QuestionPraxis question;
  final ValueChanged<String> onEnvoyer;
  final VoidCallback onOuvrirConversation;

  @override
  State<_FeuilleReponse> createState() => _FeuilleReponseEtat();
}

class _FeuilleReponseEtat extends State<_FeuilleReponse> {
  final TextEditingController _reponse = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _reponse.dispose();
    super.dispose();
  }

  void _envoyer() {
    final String texte = _reponse.text.trim();
    if (texte.isEmpty) {
      setState(() => _erreur = t.admin.praxis.questions.reponseVide);
      return;
    }
    widget.onEnvoyer(texte);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.admin.praxis.questions.laQuestion, style: textes.titleSmall),
        Ecart.vXs,
        Text(widget.question.question, style: textes.bodyMedium),
        Ecart.vMd,
        LienFleche(
          key: ClesQuestionsPraxis.conversation,
          libelle: t.admin.praxis.questions.actionConversation,
          onPress: widget.onOuvrirConversation,
        ),
        Ecart.vLg,
        // Plusieurs lignes : `ChampEtiquete` passe alors par `ZoneSaisie`, qui ne
        // porte ni `erreur` ni `cleChamp`. La cle est posee sur le conteneur, et
        // l'erreur se dit sous le champ, par l'encre d'erreur de la page.
        KeyedSubtree(
          key: ClesQuestionsPraxis.champReponse,
          child: ChampEtiquete(
            libelle: t.admin.praxis.questions.champReponse,
            controller: _reponse,
            maxLines: 5,
            aide: t.admin.praxis.questions.aideReponse,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(1500),
            ],
            onChanged: (String _) {
              if (_erreur != null) setState(() => _erreur = null);
            },
          ),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: ClesQuestionsPraxis.envoyer,
          libelle: t.admin.praxis.questions.envoyer,
          onPress: _envoyer,
        ),
      ],
    );
  }
}
