import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Le petit point rouge de rappel des cahiers a terminer (decision K-45).
///
/// Toute carte ou tout espace qui regroupe des cahiers a terminer le porte.
/// **Il rappelle, il ne punit pas** : un point de 8, pose a cote du titre, et
/// jamais un aplat ni une icone d'alarme.
///
/// - Il pulse doucement pendant [battements] battements de
///   [AppMouvement.pulsation] (environ quatre secondes), puis reste fixe.
/// - Il est fixe d'emblee quand les animations sont reduites
///   (`MediaQuery.disableAnimations`, WCAG 2.2.2).
/// - Sa couleur est celle de l'alerte du theme (`surfaceAlert`), aucune
///   couleur nouvelle (K-37).
/// - Il n'est pas un texte a lire seul : [libelle] le decrit au lecteur
///   d'ecran, une fois.
///
/// C'est la seule exception a « un seul element pulse a l'ecran »
/// (`AppMouvement.pulsation`) : elle est bornee dans le temps et decidee par
/// le directeur (K-45).
class PointRappel extends StatefulWidget {
  /// Cree le point.
  const PointRappel({required this.libelle, super.key, this.battements = 3});

  /// Ce que le lecteur d'ecran annonce.
  final String libelle;

  /// Combien de battements avant l'arret.
  final int battements;

  /// Le diametre du point.
  static const double diametre = AppSpacing.sm;

  @override
  State<PointRappel> createState() => _PointRappelState();
}

class _PointRappelState extends State<PointRappel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _battement = AnimationController(
    vsync: this,
    duration: AppMouvement.pulsation,
  )..addStatusListener(_suite);
  int _faits = 0;
  bool _decide = false;

  void _suite(AnimationStatus statut) {
    if (statut != AnimationStatus.completed) return;
    _faits++;
    if (_faits < widget.battements) {
      _battement.forward(from: 0);
    } else {
      // Fixe apres quelques secondes : la valeur 0 est le point au repos.
      _battement.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decide) return;
    _decide = true;
    // Mouvement reduit : fixe d'emblee, aucun battement.
    if (!MediaQuery.disableAnimationsOf(context) && widget.battements > 0) {
      _battement.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _battement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color couleur = AppPalette.of(context).surfaceAlert.background;
    return Semantics(
      label: widget.libelle,
      excludeSemantics: true,
      child: SizedBox.square(
        // Le halo garde sa place : le battement ne pousse rien autour.
        dimension: PointRappel.diametre * 2,
        child: AnimatedBuilder(
          animation: _battement,
          builder: (BuildContext _, Widget? point) {
            // 0 au repos, 1 au sommet du battement, 0 a la fin.
            final double intensite = math.sin(math.pi * _battement.value);
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (intensite > 0)
                  Container(
                    key: const ValueKey<String>('point-rappel-halo'),
                    width: PointRappel.diametre * (1 + intensite),
                    height: PointRappel.diametre * (1 + intensite),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: couleur.withValues(alpha: 0.3 * intensite),
                    ),
                  ),
                point!,
              ],
            );
          },
          child: Container(
            key: const ValueKey<String>('point-rappel'),
            width: PointRappel.diametre,
            height: PointRappel.diametre,
            decoration: BoxDecoration(shape: BoxShape.circle, color: couleur),
          ),
        ),
      ),
    );
  }
}
