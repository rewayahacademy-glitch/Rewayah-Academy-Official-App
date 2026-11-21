// GUIDE-INTERACTIONS (directeur, 20/11/2026 : « malgre les reseaux sociaux
// remplis de ces types d'interactions tu me sors quelque chose de 1990 ?
// […] Pourquoi diable ces contours ? ») : la rangee de reactions d'une partie
// du guide, a la maniere des reseaux sociaux.
//
// - Aucun contour, aucune capsule : une icone et son nombre, poses sur la
//   page, comme sous une publication.
// - Le coeur donne se remplit, eclate d'un anneau de six points, depasse et se
//   pose (ressort) ; le nombre roule (`NombreRouleaux`) ; tout se tait apres.
// - Tout ce qui se touche s'enfonce et revient (`ToucherVivant`).
// - Sous « Reduire les effets » : ni eclat ni rebond, le changement reste
//   lisible (icone pleine, couleur, nombre).
// - Un nombre nul ne s'ecrit pas : le mot le remplace (« J'aime »,
//   « Pas clair », « Commenter »), comme sur les reseaux.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/mouvement/mouvement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/vivant/nombre_rouleaux.dart';
import '../../../core/vivant/toucher_vivant.dart';
import 'port_interactions_guide.dart';

/// La rangee de reactions d'une partie.
class BarreAvis extends StatelessWidget {
  /// Cree la rangee.
  const BarreAvis({
    required this.ligne,
    required this.mesCommentaires,
    required this.onAvis,
    this.onCommenter,
    this.cleJaime,
    this.clePasClair,
    this.cleCommenter,
    super.key,
  });

  /// Les totaux de la partie et l'avis du lecteur.
  final AvisPartie ligne;

  /// Le nombre de commentaires du lecteur sur la partie.
  final int mesCommentaires;

  /// Le lecteur touche un avis.
  final ValueChanged<AvisGuide> onAvis;

  /// Le lecteur ouvre son fil ; nul tant que la direction ne lit pas encore
  /// les commentaires (le serveur le dit) : pas de touche « Commenter ».
  final VoidCallback? onCommenter;

  /// Les cles des trois touches, pour les tests.
  final Key? cleJaime, clePasClair, cleCommenter;

  @override
  Widget build(BuildContext context) {
    final l = t.recrutement.lettre;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        // Choix de formulaire, pas un filtre : les reactions d'une partie.
        _Reaction(
          key: cleJaime,
          icone: AppIcons.coeur,
          mot: l.jaime,
          nombre: ligne.jaime,
          donnee: ligne.monAvis == AvisGuide.jaime,
          eclat: true,
          semantique: l.jaimeLecteur(n: ligne.jaime),
          onPress: () => onAvis(AvisGuide.jaime),
        ),
        _Reaction(
          key: clePasClair,
          icone: AppIcons.info,
          mot: l.pasClair,
          nombre: ligne.pasClair,
          donnee: ligne.monAvis == AvisGuide.pasClair,
          semantique: l.pasClairLecteur(n: ligne.pasClair),
          onPress: () => onAvis(AvisGuide.pasClair),
        ),
        if (onCommenter case final VoidCallback commenter)
          _Reaction(
            key: cleCommenter,
            icone: AppIcons.discussion,
            mot: l.commenter,
            nombre: mesCommentaires,
            donnee: false,
            semantique: mesCommentaires > 0
                ? '${l.commenter}. ${l.commentaires(n: mesCommentaires)}'
                : l.commenter,
            onPress: commenter,
          ),
      ],
    );
  }
}

/// Une reaction : une icone, puis son nombre (ou son mot quand il est nul).
class _Reaction extends StatefulWidget {
  const _Reaction({
    required this.icone,
    required this.mot,
    required this.nombre,
    required this.donnee,
    required this.semantique,
    required this.onPress,
    this.eclat = false,
    super.key,
  });

  final AppIcon icone;
  final String mot;
  final int nombre;
  final bool donnee;
  final String semantique;
  final VoidCallback onPress;

  /// Vrai pour le coeur : il eclate quand on le donne.
  final bool eclat;

  @override
  State<_Reaction> createState() => _EtatReaction();
}

class _EtatReaction extends State<_Reaction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Mouvement.maximum,
  );

  @override
  void didUpdateWidget(_Reaction ancien) {
    super.didUpdateWidget(ancien);
    if (widget.donnee && !ancien.donnee && !Mouvement.reduit(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Color repos = palette.inkMuted.asIconTheme().color!;
    final Color vive = palette.inkAccent.asIconTheme().color!;
    final Color encre = widget.donnee ? vive : repos;
    final TextStyle style = (textes.labelLarge ?? const TextStyle()).copyWith(
      color: encre,
    );
    // Le pop : petit, gonfle, depasse, se pose (ressort court, puis rien).
    final Animation<double> echelle = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 0.7),
          weight: 15,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.7, end: 1.3),
          weight: 35,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.3, end: 0.92),
          weight: 25,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.92, end: 1),
          weight: 25,
        ),
      ],
    ).animate(_pop);
    return ToucherVivant(
      onPress: widget.onPress,
      libelleSemantique: widget.semantique,
      arrondiFocus: AppRadius.arrondiFull,
      enfoncement: 0.9,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.titreEcran),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: AppSpacing.xxxl,
                child: AnimatedBuilder(
                  animation: _pop,
                  builder: (BuildContext _, Widget? icone) => CustomPaint(
                    painter: widget.eclat
                        ? _Eclat(progres: _pop.value, couleur: vive)
                        : null,
                    child: Center(
                      child: Transform.scale(
                        scale: echelle.value,
                        child: icone,
                      ),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: Mouvement.court,
                    child: Icon(
                      widget.icone.resoudre(selectionne: widget.donnee),
                      key: ValueKey<bool>(widget.donnee),
                      size: AppSpacing.xxl,
                      color: encre,
                    ),
                  ),
                ),
              ),
              Ecart.hXs,
              if (widget.nombre > 0)
                NombreRouleaux(widget.nombre, style: style)
              else
                Flexible(child: Text(widget.mot, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}

/// L'eclat du coeur : un anneau de six points qui s'ecarte et s'efface.
class _Eclat extends CustomPainter {
  _Eclat({required this.progres, required this.couleur});

  final double progres;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    if (progres <= 0.15 || progres >= 1) return;
    final double k = (progres - 0.15) / 0.85;
    final Offset centre = size.center(Offset.zero);
    final double rayon = size.shortestSide * (0.35 + 0.45 * k);
    final Paint p = Paint()..color = couleur.withValues(alpha: 1 - k);
    for (int i = 0; i < 6; i++) {
      final double a = i * math.pi / 3 - math.pi / 2;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * rayon,
        AppSpacing.xs * (1 - k * 0.6) / 2 + 0.5,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_Eclat ancien) =>
      ancien.progres != progres || ancien.couleur != couleur;
}
