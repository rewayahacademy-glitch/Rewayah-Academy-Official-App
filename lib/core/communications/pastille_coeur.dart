// IMAGES-MESSAGERIE : la pastille de coeur d'une bulle (plan du directeur du
// 16/11/2026). Une petite pastille avec l'icone coeur Phosphor, jamais un
// emoji ; coeur plein et couleur de marque quand la personne a donne le sien.
// Le compte s'ecrit dans un fil de plus de deux personnes. Une legere
// animation a la pose, coupee quand les animations sont reduites.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// La pastille de coeur, posee au coin bas de la bulle.
class PastilleCoeur extends StatefulWidget {
  /// Cree la pastille.
  const PastilleCoeur({
    required this.coeurs,
    required this.aimeParMoi,
    super.key,
    this.avecCompte = false,
  });

  /// Le nombre de coeurs.
  final int coeurs;

  /// J'ai donne le mien.
  final bool aimeParMoi;

  /// Vrai dans un fil de plus de deux personnes : le nombre s'ecrit.
  final bool avecCompte;

  @override
  State<PastilleCoeur> createState() => _PastilleCoeurState();
}

class _PastilleCoeurState extends State<PastilleCoeur>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pose = AnimationController(
    vsync: this,
    duration: Mouvement.moyen,
  );

  @override
  void didUpdateWidget(PastilleCoeur ancien) {
    super.didUpdateWidget(ancien);
    if (widget.aimeParMoi && !ancien.aimeParMoi && !Mouvement.reduit(context)) {
      _pose.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    final bool plein = widget.aimeParMoi;
    final Color encre = plein
        ? palette.inkAccent.asIconTheme().color!
        : palette.inkMuted.asIconTheme().color!;
    final String phrase = plein
        ? (widget.avecCompte && widget.coeurs > 1
              ? '${t.com.messages.images.aimeParVous}, '
                    '${t.com.messages.images.aimes(n: widget.coeurs)}'
              : t.com.messages.images.aimeParVous)
        : t.com.messages.images.aimes(n: widget.coeurs);
    // Un battement : 1 -> 1,25 -> 1 (courbe symetrique).
    final Animation<double> echelle = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 1.25),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.25, end: 1),
          weight: 1,
        ),
      ],
    ).animate(CurvedAnimation(parent: _pose, curve: Mouvement.entree));
    return Semantics(
      label: phrase,
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          borderRadius: AppRadius.arrondiFull,
          border: Border.fromBorderSide(
            palette.borderStrong.asBorderSide(width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ScaleTransition(
                scale: echelle,
                child: Icon(
                  AppIcons.coeur.resoudre(selectionne: plein),
                  size: AppSpacing.lg,
                  color: encre,
                ),
              ),
              if (widget.avecCompte && widget.coeurs > 0) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${widget.coeurs}',
                  style: palette.inkStrong.applyTo(corps),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
