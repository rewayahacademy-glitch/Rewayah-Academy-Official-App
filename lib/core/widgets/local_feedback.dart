import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_elevation.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';

/// Le retour local d'une action : court, pose pres de ce qui a change.
///
/// **Jamais une boite de dialogue de succes** : une boite demande un geste pour
/// dire qu'un geste a reussi (`docs/design/02-regles-ux.md` section 7). Et
/// jamais au centre de l'ecran : il se pose sous la zone qui vient de changer,
/// et il n'empeche jamais de continuer.
///
/// Le motif de mouvement est celui de `04-systeme-mouvement.md` section 3 :
/// apparition en 200 ms avec une translation de 12 vers le haut, maintien de
/// 3 secondes, disparition en 160 ms. Sous reduction du mouvement, la
/// translation vaut zero et il ne reste que le fondu.
///
/// L'annulation est **preferee a une confirmation** pour tout ce qui est
/// reversible : confirmer coute un geste a chaque fois, annuler n'en coute un
/// que lorsqu'on s'est trompe (`02-regles-ux.md` section 5).
class LocalFeedback extends StatefulWidget {
  /// Cree un retour local.
  const LocalFeedback({
    required this.message,
    super.key,
    this.libelleAnnuler,
    this.onAnnuler,
    this.persistant = false,
  });

  /// Le message. `null` n'affiche rien.
  ///
  /// Changer ce message rejoue l'apparition : c'est ainsi qu'un ecran signale
  /// deux creneaux poses coup sur coup sans avoir a piloter d'animation.
  final String? message;

  /// Le libelle du bouton d'annulation.
  final String? libelleAnnuler;

  /// L'annulation. Sans elle, aucun bouton n'est rendu.
  final VoidCallback? onAnnuler;

  /// Vrai pour que le retour reste tant que le message ne change pas.
  ///
  /// Un seul cas dans le produit : le rapport mis en file hors ligne, qui
  /// reste affiche tant que la file n'est pas videe
  /// (`02-regles-ux.md` section 7).
  final bool persistant;

  @override
  State<LocalFeedback> createState() => _LocalFeedbackState();
}

class _LocalFeedbackState extends State<LocalFeedback> {
  Timer? _minuteur;
  String? _affiche;

  @override
  void initState() {
    super.initState();
    _prendre(widget.message);
  }

  @override
  void didUpdateWidget(LocalFeedback ancien) {
    super.didUpdateWidget(ancien);
    if (widget.message != ancien.message) {
      _prendre(widget.message);
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  void _prendre(String? message) {
    _minuteur?.cancel();
    _affiche = message;
    if (message == null || widget.persistant) {
      return;
    }
    _minuteur = Timer(AppMouvement.retourLocalMaintien, () {
      if (mounted) {
        setState(() => _affiche = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? message = _affiche;

    return AnimatedSwitcher(
      // Les durees ne passent pas par `AppMouvement.duree` : sous reduction du
      // mouvement, le retour local est « inchange, sans translation »
      // (`04-systeme-mouvement.md` section 5). C'est la seule ligne du tableau
      // qui garde ses durees pleines ; seule la translation ci-dessous tombe a
      // zero.
      duration: AppMouvement.apparition,
      reverseDuration: AppMouvement.micro,
      switchInCurve: AppMouvement.entree,
      switchOutCurve: AppMouvement.sortie,
      transitionBuilder: (Widget enfant, Animation<double> avancement) {
        final double translation = AppMouvement.translation(
          context,
          AppMouvement.translationRetourLocal,
        );
        // Le decalage est en pixels et non en fraction de hauteur : c'est ce
        // que dit le motif, et un bandeau de deux lignes ne doit pas entrer de
        // deux fois plus loin qu'un bandeau d'une ligne. D'ou l'AnimatedBuilder
        // plutot qu'un SlideTransition.
        return FadeTransition(
          opacity: avancement,
          child: AnimatedBuilder(
            animation: avancement,
            builder: (BuildContext _, Widget? corps) => Transform.translate(
              offset: Offset(0, (1 - avancement.value) * translation),
              child: corps,
            ),
            child: enfant,
          ),
        );
      },
      child: message == null
          ? const SizedBox.shrink()
          : _Bandeau(
              // La cle porte le message : sans elle, deux retours successifs
              // seraient vus comme le meme widget et l'apparition ne
              // rejouerait pas.
              key: ValueKey<String>(message),
              message: message,
              libelleAnnuler: widget.libelleAnnuler,
              onAnnuler: widget.onAnnuler,
            ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.message,
    required this.libelleAnnuler,
    required this.onAnnuler,
    super.key,
  });

  final String message;
  final String? libelleAnnuler;
  final VoidCallback? onAnnuler;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: AppElevation.avecFilet(
          // Registre doux : un retour local informe, il n'agit pas. L'aplat
          // sature reste reserve a l'action principale.
          surface: palette.washAccent,
          filet: palette.borderHairline,
          arrondi: AppRadius.arrondiSm,
          // Il flotte au dessus du contenu : niveau 2.
          ombres: AppElevation.niveau2,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                message,
                style: palette.washAccent.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            if (libelleAnnuler != null && onAnnuler != null) ...<Widget>[
              Ecart.hMd,
              ActionPrincipale(
                libelle: libelleAnnuler!,
                onPress: onAnnuler,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
