import 'package:flutter/material.dart';

import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'chrono_salle.dart';
import 'mention_seance.dart';
import 'vue_seance.dart';

/// Standard des commandes d'appel (24/10/2026) : la pilule d'etat de la
/// salle, translucide, hauteur 36 : « ● En ligne · Visite de controle
/// possible. » (ADR-011), phrase entiere, jamais coupee ; aucun lien dessous,
/// la mention elle-meme ouvre la lecture. Telephone et ordinateur.
class PiluleEtatSalle extends StatelessWidget {
  const PiluleEtatSalle({
    required this.vue,
    this.largeurMax = double.infinity,
    this.cle = const ValueKey<String>('pilule-etat-salle'),
    this.aLaLigne = false,
    this.surface,
    this.avecChrono = false,
    super.key,
  });

  /// FN-023 : la pilule porte aussi le chrono du temps restant
  /// (LIVE-CHRONO-01), quand la vue a ses bornes. Les salles du 26/10
  /// (ordinateur, telephone de l'enseignant, plein ecran) n'ont pas d'autre
  /// en-tete ; l'ancien `ChromeSeance` rend son chrono lui-meme et laisse
  /// ce drapeau a faux.
  final bool avecChrono;

  /// La surface ou la ligne se pose (la couche sombre du profil, pilote C4) ;
  /// `null` : la pilule translucide de la salle.
  final AppColorPair? surface;

  /// Fiche 1, ligne 5 (carte du profil du telephone) : etroite ou texte
  /// agrandi, la phrase passe a la ligne entre deux mots, jamais dans un mot.
  final bool aLaLigne;

  final VueSeance vue;

  /// La largeur que la pilule ne depasse pas.
  final double largeurMax;

  /// La cle de la pilule elle-meme (tests, captures).
  final Key cle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = surface ?? palette.piluleSalle;
    final TextStyle style = fond.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    final Widget point = SizedBox.square(
      dimension: AppSpacing.sm,
      child: DecoratedBox(
        decoration:
            (vue.connexion.etablie
                    ? palette.pointsStatut.succes
                    : palette.pointsStatut.attention)
                .pastille(),
      ),
    );
    final Widget? chrono = avecChrono && vue.voitChrono
        ? ChronoSalle(
            bornes: vue.chrono!,
            connexion: vue.connexion,
            pause: vue.pause,
            style: style,
            garderCouleur: true,
          )
        : null;
    final Widget ligne = aLaLigne
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                point,
                Text(vue.texteConnexion, style: style),
                if (vue.texteMention != null) ...<Widget>[
                  Text('\u00b7', style: style),
                  MentionSeance(vue: vue, lienSousLaLigne: false),
                ],
              ],
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              point,
              Ecart.hSm,
              // Lot salle 3 : la phrase du repli audio peut passer sur deux
              // lignes, jamais coupee ni debordante.
              Flexible(child: Text(vue.texteConnexion, style: style)),
              if (vue.texteMention != null) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text('\u00b7', style: style),
                ),
                // La phrase entiere, jamais coupee (ADR-011) ; aucun lien
                // dessous, la mention elle-meme ouvre la lecture.
                Flexible(
                  child: MentionSeance(vue: vue, lienSousLaLigne: false),
                ),
              ],
            ],
          );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: largeurMax,
        minHeight: AppSpacing.xxxl + AppSpacing.xs,
      ),
      child: DecoratedBox(
        key: cle,
        decoration: fond.decoration(
          borderRadius: aLaLigne || chrono != null
              ? AppRadius.arrondiMd
              : AppRadius.arrondiFull,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          // FN-023 : le chrono sur sa propre ligne, sous l'etat, aligne sur
          // le texte (apres le point) : il ne se casse jamais au milieu.
          child: chrono == null
              ? ligne
              : Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: aLaLigne ? 0 : AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ligne,
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: AppSpacing.lg,
                          bottom: aLaLigne ? AppSpacing.sm : 0,
                        ),
                        child: chrono,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
