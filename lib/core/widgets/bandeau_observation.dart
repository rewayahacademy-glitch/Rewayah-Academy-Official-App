import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../session/session_state.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Le bandeau d'une session d'observation par un agent IA (ADR-025).
///
/// **Il ne protege rien, et c'est important de le savoir en le lisant.** La
/// lecture seule est imposee par les privileges du role Postgres `agent_ro` :
/// un agent recevrait le meme refus en rejouant la requete a la main, bandeau
/// ou pas. Ce composant existe pour une autre raison, tout aussi serieuse :
/// **une observation qui ne se voit pas est une observation cachee.** Quelqu'un
/// qui regarde l'ecran par-dessus l'epaule d'un agent doit savoir en une
/// seconde qu'il ne regarde pas une session ordinaire.
///
/// Il dit trois choses, et pas une de plus :
///
///   * que c'est une observation en lecture seule ;
///   * si les prenoms sont masques, parce que l'ecran affiche alors des
///     identifiants la ou un humain attend des prenoms, et qu'un lecteur qui
///     l'ignore croirait a un defaut d'affichage ;
///   * quand le jeton expire, pour que la fin de session ne se decouvre pas sur
///     un ecran soudain vide.
///
/// Il reprend le registre doux du bandeau hors ligne, pour la meme raison :
/// une zone pleine par ecran est reservee a l'action principale
/// (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 3), et ce bandeau est permanent.
/// Il ne lit pas la session lui-meme : `app.dart`, qui le pose, l'observe deja.
/// Deux lectures du meme fait finiraient par se contredire a l'ecran, et un
/// composant qui depend d'un conteneur d'etat ne se montre pas en galerie.
class BandeauObservation extends StatelessWidget {
  /// Cree le bandeau pour ce contexte d'observation.
  const BandeauObservation({required this.observation, super.key});

  /// Ce que la session d'observation porte.
  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washWarning;

    final StringBuffer texte = StringBuffer(t.agent.bandeau);
    if (observation.identiteMasquee) {
      texte.write(' . ');
      texte.write(t.agent.bandeauMasque);
    }
    final DateTime? fin = observation.jetonExpireLe;
    if (fin != null) {
      texte.write(' . ');
      texte.write(
        t.agent.bandeauExpire(
          heure:
              '${fin.hour.toString().padLeft(2, '0')}:'
              '${fin.minute.toString().padLeft(2, '0')}',
        ),
      );
    }

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paire.background,
          border: Border(bottom: palette.borderStrong.asBorderSide()),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                IconTheme(
                  data: IconThemeData(
                    color: paire.onBackground,
                    size: AppSpacing.xl,
                  ),
                  child: Icon(AppIcons.controleQualite.repos),
                ),
                Ecart.hSm,
                Expanded(
                  child: Text(
                    texte.toString(),
                    style: paire.applyTo(
                      Theme.of(context).textTheme.bodySmall ??
                          const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
