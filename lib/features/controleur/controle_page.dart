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
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../accueil_famille/bloc_seance.dart' show heureDeLAppareil;
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
  const ControleControleurPage({super.key});

  /// La cle du bouton d'entree.
  static const Key commencerKey = ValueKey<String>('ctr01-commencer');

  /// La largeur utile de la colonne.
  static const double largeurMax = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MissionControle?> mission = ref.watch(
      missionControleProvider,
    );
    final Widget corps = switch (mission) {
      AsyncData<MissionControle?>(:final MissionControle? value) =>
        _Mission(mission: value),
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
    return PageShell(
      titre: t.controleur.controle.titre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeurMax),
          child: ApparitionDouce(child: corps),
        ),
      ),
    );
  }
}

class _Mission extends StatelessWidget {
  const _Mission({required this.mission});

  final MissionControle? mission;

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
    return _CarteMission(mission: m);
  }
}

class _CarteMission extends StatelessWidget {
  const _CarteMission({required this.mission});

  final MissionControle mission;

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
      t.controleur.controle.eleves(nombre: mission.nombreEleves),
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
          Row(
            children: <Widget>[
              AvatarTile(prenom: mission.enseignant, diametre: 40),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mission.enseignant,
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                    Text(details, style: doux),
                  ],
                ),
              ),
            ],
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
                        onPress: () => _commencer(context),
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
