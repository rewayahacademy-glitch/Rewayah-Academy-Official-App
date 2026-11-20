// ACCUEIL-CANDIDAT (directeur, 20/11/2026) : l'avatar de Praxis sur l'accueil
// du candidat. Le SEUL endroit du lot qui emploie le dessin actuel
// (`PraxisVivant`, `lib/core/vivant/`, employe sans le modifier) : changer de
// dessin plus tard se fait ici, et nulle part ailleurs.
//
// Eveille quand il a quelque chose a dire : le dessin s'endort (yeux fermes)
// apres un temps sans geste. Ici, il vit un moment (souffle, clins), puis se
// pose IMMOBILE, YEUX OUVERTS, avant que le sommeil ne vienne ; une phrase
// nouvelle le reveille pour un nouveau moment. Sous « Reduire les effets »,
// il est pose d'emblee, immobile, yeux ouverts. Ainsi l'animation finit
// toujours (aucune image produite pour rien, PLAN §13.1 regle 5) et il ne
// s'endort jamais devant le candidat.
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/vivant/praxis_vivant.dart';

/// L'humeur de l'avatar, dans les mots du lot.
enum HumeurPraxisCandidat {
  /// Au repos.
  calme,

  /// Un blocage a signaler (piece refusee) : serieux, jamais triste.
  soucieux,
}

/// L'avatar de Praxis, en petit, pour l'accueil du candidat.
class AvatarPraxisCandidat extends StatefulWidget {
  /// Cree l'avatar. [sujet] : ce qu'il signale ; quand il change, il se
  /// reveille pour un nouveau moment.
  const AvatarPraxisCandidat({
    required this.sujet,
    super.key,
    this.humeur = HumeurPraxisCandidat.calme,
    this.taille = AvatarPraxisCandidat.tailleDefaut,
  });

  /// Ce qu'il signale (la phrase dite a cote).
  final String sujet;

  /// Son humeur.
  final HumeurPraxisCandidat humeur;

  /// Sa largeur.
  final double taille;

  /// La largeur ici : 64 (120 sur les autres ecrans).
  static const double tailleDefaut = AppSpacing.section;

  /// Combien de temps il vit avant de se poser, yeux ouverts : en dessous du
  /// temps au bout duquel le dessin s'endort.
  static const Duration momentEveille = Duration(seconds: 12);

  /// La cle du dessin pose (immobile, yeux ouverts), pour les tests.
  static const Key clePose = ValueKey<String>('praxis-candidat-pose');

  /// La cle du dessin vivant, pour les tests.
  static const Key cleVivant = ValueKey<String>('praxis-candidat-vivant');

  @override
  State<AvatarPraxisCandidat> createState() => _EtatAvatarPraxisCandidat();
}

class _EtatAvatarPraxisCandidat extends State<AvatarPraxisCandidat> {
  Timer? _minuterie;
  bool _pose = false;

  @override
  void initState() {
    super.initState();
    _eveiller();
  }

  @override
  void didUpdateWidget(AvatarPraxisCandidat ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.sujet != widget.sujet || ancien.humeur != widget.humeur) {
      setState(_eveiller);
    }
  }

  void _eveiller() {
    _minuterie?.cancel();
    _pose = false;
    _minuterie = Timer(AvatarPraxisCandidat.momentEveille, () {
      if (mounted) setState(() => _pose = true);
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HumeurPraxis humeur = switch (widget.humeur) {
      HumeurPraxisCandidat.calme => HumeurPraxis.calme,
      HumeurPraxisCandidat.soucieux => HumeurPraxis.soucieux,
    };
    // Pose : le dessin rendu « effets reduits » se fige yeux ouverts, sans
    // souffle ; une cle neuve le pose d'emblee.
    final bool pose = _pose || EffetsReduits.de(context);
    return ExcludeSemantics(
      child: EffetsReduits(
        actifs: pose,
        child: PraxisVivant(
          key: pose
              ? AvatarPraxisCandidat.clePose
              : AvatarPraxisCandidat.cleVivant,
          taille: widget.taille,
          // Pose a sa place : a cette taille, une chute passerait sur la
          // ligne d'etapes.
          tombe: false,
          humeur: humeur,
        ),
      ),
    );
  }
}
