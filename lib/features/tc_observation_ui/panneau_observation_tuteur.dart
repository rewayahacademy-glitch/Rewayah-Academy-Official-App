import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/vue_budget_observation.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_observation_tuteur.dart';

/// En deca de ce reste, le compte a rebours passe au ton d'avertissement.
///
/// Un seuil d'**affichage**, pas une regle : il ne raccourcit ni n'allonge
/// quoi que ce soit, il prepare seulement le tuteur a la fin de sa visite. Sans
/// lui, la salle se fermerait sur un chiffre encore calme.
const Duration seuilFinProcheObservation = Duration(seconds: 30);

/// Ce que le tuteur voit pendant sa visite.
///
/// **Presentation seule, aucun provider.** Le panneau recoit une
/// [VueObservationTuteur] deja calculee : c'est ce qui rend l'invariant « aucun
/// roster complet » verifiable par un test de widget aussi bien que par un test
/// de fonction pure.
///
/// Le support partage est un **emplacement**, pas une implementation : c'est la
/// Classe Live qui sait afficher le Coran ou un PDF, et une seconde surface de
/// rendu serait une seconde Bibliotheque. Tant que l'hote n'en fournit pas, le
/// panneau le dit en clair.
class PanneauObservationTuteur extends StatelessWidget {
  /// Cree le panneau.
  const PanneauObservationTuteur({
    required this.vue,
    required this.onQuitter,
    super.key,
    this.supportPartage,
    this.videoEnseignant,
    this.videoEnfant,
    this.budgetIncertain = false,
    this.videoIndisponible = false,
  });

  /// Ce qui est expose au tuteur.
  final VueObservationTuteur vue;

  /// La sortie volontaire.
  final VoidCallback onQuitter;

  /// Le support partage, fourni par l'hote. `null` = pas encore branche.
  final Widget? supportPartage;

  /// L'image de l'enseignant, deja montee par le moteur de salle.
  ///
  /// **Un widget, jamais une piste.** L'hote appelle `renduVideo(identite)` et
  /// passe le resultat : c'est ainsi que la portabilite de l'ADR-001 survit au
  /// rendu, et c'est ce qui laisse ce panneau sans provider ni SDK.
  final Widget? videoEnseignant;

  /// L'image de l'enfant du tuteur. `null` quand sa camera est fermee.
  ///
  /// C'est la raison meme de la visite : le parent vient voir si son enfant
  /// participe. Une vignette de nom seul ne repond pas a cette question.
  final Widget? videoEnfant;

  /// Vrai quand la derniere lecture de budget a echoue.
  final bool budgetIncertain;

  /// Vrai quand la salle video n'a pas pu s'ouvrir.
  ///
  /// Meme idiome que [budgetIncertain] : une ligne discrete, pas un ecran de
  /// remplacement. La visite continue de se consommer cote serveur, et un
  /// panneau sans compte a rebours ni bouton « Quitter » empecherait le tuteur
  /// de la refermer.
  final bool videoIndisponible;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Compteur(vue: vue),
        if (budgetIncertain) ...<Widget>[
          Ecart.vSm,
          Text(t.tc.observation.visite.budgetIncertain, style: discret),
        ],
        if (videoIndisponible) ...<Widget>[
          Ecart.vSm,
          Text(t.tc.observation.visite.videoIndisponible, style: discret),
        ],
        Ecart.vLg,
        supportPartage ??
            EmptyState(
              message: t.tc.observation.visite.supportIndisponible,
              icone: AppIcons.coran,
              registre: RegistreVide.subi,
            ),
        Ecart.vLg,
        _Vignette(
          etiquette: t.tc.observation.visite.enseignant,
          prenom: vue.enseignant?.nom,
          video: videoEnseignant,
        ),
        Ecart.vMd,
        _Vignette(
          etiquette: t.tc.observation.visite.monEnfant,
          prenom: vue.monEnfant?.nom,
          absent: t.tc.observation.visite.enfantAbsent,
          video: videoEnfant,
        ),
        Ecart.vLg,
        // Le rappel des interdictions est permanent, pas conditionnel : le
        // tuteur n'a aucune commande de media a l'ecran, et un ecran sans
        // commande ne dit pas de lui-meme pourquoi.
        Text(t.tc.observation.visite.mediaFerme, style: discret),
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.tc.observation.visite.quitter,
          onPress: onQuitter,
          niveau: NiveauAction.secondaire,
        ),
      ],
    );
  }
}

/// Le compte a rebours discret du budget restant.
class _Compteur extends StatelessWidget {
  const _Compteur({required this.vue});

  final VueObservationTuteur vue;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final VueBudgetObservation? budget = vue.budget;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(t.tc.observation.visite.titre, style: textes.titleMedium),
        ),
        if (budget != null) ...<Widget>[
          Ecart.hSm,
          Text(
            t.tc.observation.visite.visites(
              rang: budget.rangVisite,
              total: budget.visitesMax,
            ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.hSm,
          StatusPill(
            libelle: t.tc.observation.visite.restant(
              secondes: budget.secondesRestantes,
            ),
            ton: budget.restantAffiche <= seuilFinProcheObservation
                ? TonEtat.avertissement
                : TonEtat.accent,
          ),
        ],
      ],
    );
  }
}

/// Une des deux seules vignettes que la visite expose.
class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.etiquette,
    required this.prenom,
    this.absent,
    this.video,
  });

  final String etiquette;
  final String? prenom;

  /// L'image de cette personne, quand elle en publie une.
  ///
  /// Elle **s'ajoute** au nom, elle ne le remplace pas : un cadre video sans
  /// legende obligerait le tuteur a deviner qui il regarde, et la retenue de la
  /// visite tient justement a ce que chaque vignette soit nommee.
  final Widget? video;

  /// Ce qui se dit quand la personne n'est pas la. `null` = ne rien dire.
  ///
  /// L'absence de l'enfant se dit -- c'est la raison meme de la visite. Celle
  /// de l'enseignant ne se dit pas ici : un cours sans enseignant a deja son
  /// message, et le tuteur n'a rien a en faire depuis une fenetre de deux
  /// minutes.
  final String? absent;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? nom = prenom;

    if (nom == null) {
      final String? message = absent;
      if (message == null) {
        return const SizedBox.shrink();
      }
      return AppCard(
        child: Text(
          message,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      );
    }

    final Widget ligne = Row(
      children: <Widget>[
        AvatarTile(prenom: nom),
        Ecart.hMd,
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                etiquette,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              Text(nom, style: textes.titleMedium),
            ],
          ),
        ),
      ],
    );

    final Widget? image = video;
    if (image == null) {
      return AppCard(child: ligne);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: AppMetriques.of(context).arrondi,
            // `AspectRatio` plutot qu'une hauteur fixe : le panneau se lit sur
            // un telephone de 390 points comme sur un bureau, et un cadre video
            // a hauteur figee y serait tantot ecrase, tantot demesure.
            child: AspectRatio(aspectRatio: _formatVideo, child: image),
          ),
          Ecart.vSm,
          ligne,
        ],
      ),
    );
  }

  /// Le format d'un cadre video, celui que les cameras produisent.
  static const double _formatVideo = 16 / 9;
}
