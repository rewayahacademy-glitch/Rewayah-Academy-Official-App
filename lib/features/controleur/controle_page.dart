import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../accueil_famille/bloc_seance.dart' show heureDeLAppareil;
import 'compte_rendu_controle.dart';
import 'compte_rendu_controle_page.dart' show LigneTransmissionVisite;
import 'mission_controle.dart';

/// `CTR-01` Controle (CT-2) : **une seule** carte de mission, jamais un
/// planning (decision du directeur du 27/09/2026, C1, C3, C14).
///
/// Quatre situations : aucune mission (le texte vide du doc 08), seance pas
/// encore en direct (ligne calme, aucun bouton, R4), seance en direct (un seul
/// bouton dominant « Commencer le controle », au bord de fin de la carte,
/// K-42), mission indisponible (P-CTR-08). La carte « Mon compte » de l'ancien
/// planning est retiree : Compte est une destination de la barre (C13).
///
/// Une seule colonne bornee tant qu'il n'y a pas de bloc « Compte rendu a
/// terminer » : on ne remplit pas le vide (UX_REVIEW_08 CTR-01 d).
class ControleControleurPage extends ConsumerWidget {
  /// Cree l'ecran.
  const ControleControleurPage({
    super.key,
    this.onCommencer,
    this.onReprendreCompteRendu,
  });

  /// L'entree en salle ; par defaut `/salle` avec le billet (ADR-005). La
  /// demonstration la redirige vers sa salle fictive (CT-3).
  final void Function(MissionControle mission)? onCommencer;

  /// Le retour au compte rendu a terminer ; par defaut, sa route (CT-4).
  final VoidCallback? onReprendreCompteRendu;

  /// La cle du bouton d'entree.
  static const Key commencerKey = ValueKey<String>('ctr01-commencer');

  /// La cle de « Reprendre le compte rendu ».
  static const Key reprendreKey = ValueKey<String>('ctr01-reprendre');

  /// La largeur utile de la colonne.
  static const double largeurMax = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MissionControle?> mission = ref.watch(
      missionControleProvider,
    );
    final Widget corps = switch (mission) {
      AsyncData<MissionControle?>(:final MissionControle? value) =>
        _Mission(mission: value, onCommencer: onCommencer),
      AsyncError<MissionControle?>() => EtatSysteme(
        nature: NatureEtat.echecServeur,
        phrase: t.controleur.controle.erreur,
        onAction: () => ref.invalidate(missionControleProvider),
      ),
      _ => Semantics(
        label: t.controleur.controle.chargement,
        child: const Skeleton(hauteur: 180),
      ),
    };
    // Le compte rendu commence et non envoye (CT-4, doc 08 CTR-01).
    final CompteRenduEnSuspens? aTerminer = ref.watch(
      compteRenduATerminerProvider,
    );
    return PageShell(
      titre: t.controleur.controle.titre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeurMax),
          child: ApparitionDouce(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                corps,
                if (aTerminer != null) ...<Widget>[
                  Ecart.vXxl,
                  _BlocATerminer(
                    visite: aTerminer,
                    onReprendre:
                        onReprendreCompteRendu ??
                        () => GoRouter.of(
                          context,
                        ).go(Routes.controleurCompteRendu),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Compte rendu a terminer » : la visite dont la reponse n'est pas partie.
class _BlocATerminer extends StatelessWidget {
  const _BlocATerminer({required this.visite, required this.onReprendre});

  final CompteRenduEnSuspens visite;
  final VoidCallback onReprendre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      surface: palette.surfaceRaised,
      marge: AppSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.controleur.compteRendu.aTerminer,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          Text(
            t.controleur.compteRendu.sousTitre(
              classe: visite.classe,
              heure: heureDeLAppareil(visite.debut),
            ),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          // La visite part sans attendre la reponse (C2) : son etat reste
          // visible ici apres « Plus tard ».
          Ecart.vMd,
          const LigneTransmissionVisite(),
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: ControleControleurPage.reprendreKey,
              libelle: t.controleur.compteRendu.reprendre,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: onReprendre,
            ),
          ),
        ],
      ),
    );
  }
}

class _Mission extends StatelessWidget {
  const _Mission({required this.mission, this.onCommencer});

  final MissionControle? mission;
  final void Function(MissionControle mission)? onCommencer;

  @override
  Widget build(BuildContext context) {
    final MissionControle? m = mission;
    if (m == null) {
      return EmptyState(
        message: t.controleur.controle.vide,
        invitation: t.controleur.controle.videAide,
        registre: RegistreVide.subi,
      );
    }
    if (m.etat == EtatMissionControle.indisponible) {
      // Aucun contenu de la mission ne reste visible (P-CTR-01 point 6,
      // P-CTR-08) : le message generique seul.
      return EmptyState(
        message: t.controleur.controle.indisponible,
        registre: RegistreVide.subi,
      );
    }
    return _CarteMission(mission: m, onCommencer: onCommencer);
  }
}

class _CarteMission extends StatelessWidget {
  const _CarteMission({required this.mission, this.onCommencer});

  final MissionControle mission;
  final void Function(MissionControle mission)? onCommencer;

  bool get _enDirect => mission.etat == EtatMissionControle.enDirect;

  void _commencer(BuildContext context) => GoRouter.of(context).go(
    Routes.salle,
    // Le billet passe par `extra`, jamais par l'URL (ADR-005) ; le serveur
    // reste seul juge de l'entree (BR-1).
    extra: BilletSalle(sessionId: mission.seanceId, emisA: DateTime.now()),
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool compact = AppGabarit.de(context) == Gabarit.mobile;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleLarge ?? const TextStyle(),
    );
    final String details = <String>[
      t.controleur.controle.horaire(
        debut: heureDeLAppareil(mission.debut),
        fin: heureDeLAppareil(mission.finPrevue),
      ),
      t.controleur.controle.duree(minutes: mission.dureePrevue.inMinutes),
      t.controleur.controle.eleves(n: mission.nombreEleves),
    ].join(' · ');

    return AppCard(
      surface: compact ? palette.surfaceRaised : palette.surfaceMiseEnAvant,
      marge: compact ? AppSpacing.lg : AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(t.controleur.controle.mission, style: doux),
          ),
          Ecart.vSm,
          Text(mission.classe, style: fort),
          Ecart.vLg,
          // AVATAR-1 : l'enseignant est un couple avatar + nom du composant
          // partage, avec au plus une ligne de role (horaire, duree, effectif).
          AvatarNom.enLigne(
            prenom: mission.enseignant,
            role: details,
            styleNom: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
            styleRole: doux,
          ),
          Ecart.vLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: 18),
                child: Icon(AppIcons.info.resoudre()),
              ),
              Ecart.hSm,
              Expanded(
                child: Text(t.controleur.controle.incognito, style: doux),
              ),
            ],
          ),
          Ecart.vLg,
          // L'emplacement unique (C14) : sa hauteur est reservee dans les deux
          // etats, et seul le changement d'etat s'annonce (UX_REVIEW_08 a).
          Semantics(
            liveRegion: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: _enDirect
                  ? Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ActionPrincipale(
                        key: ControleControleurPage.commencerKey,
                        libelle: t.controleur.controle.commencer,
                        pleineLargeur: compact,
                        onPress: () => onCommencer == null
                            ? _commencer(context)
                            : onCommencer!(mission),
                      ),
                    )
                  : Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(t.controleur.controle.attente, style: doux),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
