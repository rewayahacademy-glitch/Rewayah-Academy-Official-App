import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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
    super.key,
  });

  final VueSeance vue;

  /// La largeur que la pilule ne depasse pas.
  final double largeurMax;

  /// La cle de la pilule elle-meme (tests, captures).
  final Key cle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.piluleSalle.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: largeurMax,
        minHeight: AppSpacing.xxxl + AppSpacing.xs,
      ),
      child: DecoratedBox(
        key: cle,
        decoration: palette.piluleSalle.decoration(
          borderRadius: AppRadius.arrondiFull,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: AppSpacing.sm,
                child: DecoratedBox(
                  decoration:
                      (vue.connexion.etablie
                              ? palette.pointsStatut.succes
                              : palette.pointsStatut.attention)
                          .pastille(),
                ),
              ),
              Ecart.hSm,
              Text(vue.texteConnexion, style: style, maxLines: 1),
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
          ),
        ),
      ),
    );
  }
}
