import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/avatar_nom.dart';
import 'encre_salle.dart';
import 'vue_classe_live.dart';

/// La scene video de la Classe Live.
///
/// **Elle n'est jamais le sujet quand un support est presente.** Son poids est
/// decide par `VueClasseLive.poidsVideo`, jamais ici : scene quand rien n'est
/// presente, bande a cote du support sur tablette et bureau, vignette sur
/// telephone (spec sections 9.1 et 9.2).
///
/// **L'ecran ne recoit pas une piste, il recoit un widget deja monte.** C'est
/// ainsi que la portabilite de l'ADR-001 survit au rendu : aucun import de
/// `livekit_client` ici, et changer de moteur ne rouvrirait pas cet ecran.
///
/// **Duplication assumee et declaree.** `lib/features/salle/salle_page.dart`
/// porte deja une galerie equivalente -- `_Scene`, `_Galerie`, `_Cadre` -- mais
/// ces trois classes sont **privees a ce fichier**, qui est de surcroit nomme
/// INTERDIT a Agent E. Elles sont donc inaccessibles, pas seulement
/// inconvenables. La demande de promotion vers `lib/core/widgets/` est en
/// section 5 de `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_E.md` ; tant qu'elle
/// n'est pas faite, deux galeries existent et peuvent diverger.
class SceneClasse extends StatelessWidget {
  /// Cree la scene.
  const SceneClasse({
    required this.participants,
    required this.poids,
    super.key,
  });

  /// Les participants a montrer, dans l'ordre de lecture decide par `VueSalle`.
  final List<ParticipantSalle> participants;

  /// La place que la video prend sur cet ecran.
  final PoidsVideo poids;

  /// La hauteur en dessous de laquelle une tuile ne montre plus rien d'utile.
  static const double _hauteurPlancher = AppSpacing.respiration * 2;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return Center(
        child: Text(
          t.tc.classe.scene.vide,
          textAlign: TextAlign.center,
          style: styleDuFond(context, Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    // En vignette, un seul visage : le telephone garde le support en plein
    // ecran, et plus d'un cadre le rognerait. Le premier de la liste est celui
    // que `VueSalle` a place en tete -- l'eleve pour l'enseignant, l'enseignant
    // pour l'eleve.
    if (poids == PoidsVideo.vignette) {
      return _Cadre(
        key: ValueKey<String>(participants.first.identite),
        participant: participants.first,
        compact: true,
      );
    }

    final int total = participants.length;
    // Une bande a cote du support est etroite : une colonne, et elle defile.
    final int colonnes = poids == PoidsVideo.bande
        ? 1
        : switch (total) {
            1 => 1,
            2 || 3 || 4 => 2,
            _ => 3,
          };
    final int rangees = (total + colonnes - 1) ~/ colonnes;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double largeur =
            (contraintes.maxWidth - AppSpacing.sm * (colonnes - 1)) / colonnes;
        final double disponible = contraintes.hasBoundedHeight
            ? (contraintes.maxHeight - AppSpacing.sm * (rangees - 1)) / rangees
            : _hauteurPlancher;
        final double hauteur = disponible < _hauteurPlancher
            ? _hauteurPlancher
            : disponible;

        return GridView.count(
          crossAxisCount: colonnes,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: largeur / hauteur,
          // Tant que tout tient, la galerie ne defile pas : un geste vertical
          // dans une salle doit rester sans effet, sous peine de faire croire
          // qu'on a raccroche.
          physics: disponible < _hauteurPlancher
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (final ParticipantSalle personne in participants)
              _Cadre(
                key: ValueKey<String>(personne.identite),
                participant: personne,
                compact: hauteur <= _hauteurPlancher,
              ),
          ],
        );
      },
    );
  }
}

/// Le cadre d'un participant : son image si elle existe, son nom sinon.
class _Cadre extends ConsumerWidget {
  const _Cadre({required this.participant, required this.compact, super.key});

  final ParticipantSalle participant;

  /// Vrai dans un cadre trop court pour porter une legende sous l'avatar.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final Widget? image = ref
        .watch(moteurSalleProvider)
        .renduVideo(participant.identite);

    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: metriques.arrondi,
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Stack(
          children: <Widget>[
            // VIDEO-TUILE-1 : sans image, la tuile partagee (cercle et nom
            // centre dessous) ; l'etiquette du bas reste sur une video reelle.
            Positioned.fill(
              child: image ?? _SansImage(participant: participant),
            ),
            if (image != null)
              PositionedDirectional(
                start: AppSpacing.sm,
                bottom: AppSpacing.sm,
                end: AppSpacing.sm,
                // Une seule lecture pour les technologies d'assistance : le nom,
                // puis ce qui manque.
                child: MergeSemantics(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          participant.nom,
                          overflow: TextOverflow.ellipsis,
                          style: palette.surfaceSunken.applyTo(
                            textes.labelMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                      if (!participant.micro) ...<Widget>[
                        Ecart.hXs,
                        Text(
                          t.tc.classe.commandes.microCoupe,
                          style: palette.surfaceSunken.applyTo(
                            textes.labelSmall ?? const TextStyle(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui occupe un cadre sans image : la tuile partagee (VIDEO-TUILE-1).
class _SansImage extends StatelessWidget {
  const _SansImage({required this.participant});

  final ParticipantSalle participant;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return TuileSansImage(
      prenom: participant.nom,
      nom: participant.nom,
      libelleSansImage: t.tc.classe.scene.sansImage,
      libelleMicroCoupe: participant.micro
          ? null
          : t.tc.classe.commandes.microCoupe,
      couleurIcone: palette.surfaceSunken.onBackground,
      styleNom: palette.surfaceSunken.applyTo(
        textes.labelMedium ?? const TextStyle(),
      ),
    );
  }
}
