import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_metriques.dart';

/// Le seul point d'entree du retour tactile de l'application.
///
/// Echelle 0.96, 120 ms, retour haptique moyen. **Aucun `onTap` nu ailleurs
/// dans le code** : `tool/verifier_jetons.dart` echoue si un autre fichier de
/// `lib/` en declare un
/// (`docs/architecture/etape-2-core-flutter.md` section 2).
///
/// Une seule implementation garantit que deux boutons de deux ecrans differents
/// ne repondent jamais differemment au doigt.
class Pressable extends StatefulWidget {
  /// Cree une zone pressable.
  const Pressable({
    required this.child,
    required this.onPress,
    super.key,
    this.libelleSemantique,
    this.actif = true,
    this.respecterCibleTactile = true,
  });

  /// Le contenu rendu.
  final Widget child;

  /// L'action declenchee. `null` desactive la pression.
  final VoidCallback? onPress;

  /// Libelle lu par les technologies d'assistance.
  final String? libelleSemantique;

  /// Faux pour rendre le contenu sans le rendre pressable.
  final bool actif;

  /// Applique la cible tactile minimale du mode courant. A ne mettre a faux
  /// que pour un element deja plus grand que la cible, jamais pour la reduire.
  final bool respecterCibleTactile;

  /// Duree de l'animation de pression.
  static const Duration duree = Duration(milliseconds: 120);

  /// Echelle atteinte au doigt pose.
  static const double echelleEnfoncee = 0.96;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: Pressable.duree,
    lowerBound: Pressable.echelleEnfoncee,
    upperBound: 1,
    value: 1,
  );

  bool get _pressable => widget.actif && widget.onPress != null;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _enfoncer(TapDownDetails _) {
    if (!_pressable) {
      return;
    }
    unawaited(_controleur.reverse());
  }

  void _relacher() {
    unawaited(_controleur.forward());
  }

  void _declencher() {
    if (!_pressable) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    widget.onPress!.call();
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    Widget contenu = ScaleTransition(scale: _controleur, child: widget.child);

    if (widget.respecterCibleTactile) {
      contenu = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: metriques.cibleTactile,
          minHeight: metriques.cibleTactile,
        ),
        child: contenu,
      );
    }

    return Semantics(
      button: _pressable,
      enabled: _pressable,
      label: widget.libelleSemantique,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enfoncer,
        onTapUp: (TapUpDetails _) => _relacher(),
        onTapCancel: _relacher,
        onTap: _pressable ? _declencher : null,
        child: contenu,
      ),
    );
  }
}
