// GUIDE-INTERACTIONS (directeur, 20/11/2026, 23 h 50 : « c'est une UI
// ancienne ça. Regarde les maquettes […] sur les styles globaux et les
// animations ») : la barre d'avis d'une partie du guide, dans le langage
// VIVANT du parcours (PARCOURS-ENSEIGNANT/PLAN §13.1, maquette vivante).
//
// - Une seule capsule a courbe continue porte les deux avis ; le rayon de
//   chaque moitie retenue vaut le rayon de la capsule moins sa marge
//   (`AppRadius.interieur`, regle des coins du directeur, 19/11).
// - Tout ce qui se touche s'enfonce et revient en ressort (`ToucherVivant`).
// - Le nombre change en roulant (`NombreRouleaux`), sur l'objet lui-meme ;
//   jamais un bandeau qui pousse la page.
// - L'icone donnee bat une fois (1 -> 1,25 -> 1), puis tout se tait ; rien ne
//   tourne en boucle ; sous « Reduire les effets », aucun battement.
// - « Commenter » est une capsule de la meme famille, avec le nombre de ses
//   propres commentaires.
import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/mouvement/mouvement.dart';
import '../../../core/theme/app_color_pair.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/vivant/nombre_rouleaux.dart';
import '../../../core/vivant/toucher_vivant.dart';
import 'port_interactions_guide.dart';

const double _rayon = AppRadius.lg;
const double _marge = AppSpacing.xs;

/// La barre d'avis et de commentaire d'une partie.
class BarreAvis extends StatelessWidget {
  /// Cree la barre.
  const BarreAvis({
    required this.ligne,
    required this.mesCommentaires,
    required this.onAvis,
    required this.onCommenter,
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

  /// Le lecteur ouvre son fil.
  final VoidCallback onCommenter;

  /// Les cles des trois touches, pour les tests.
  final Key? cleJaime, clePasClair, cleCommenter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final l = t.recrutement.lettre;
    Widget avis(bool large) => _Capsule(
      large: large,
      enfants: <Widget>[
        _Moitie(
          key: cleJaime,
          icone: AppIcons.coeur,
          libelle: l.jaime,
          nombre: ligne.jaime,
          retenue: ligne.monAvis == AvisGuide.jaime,
          semantique: l.jaimeLecteur(n: ligne.jaime),
          large: large,
          onPress: () => onAvis(AvisGuide.jaime),
        ),
        SizedBox(
          height: AppSpacing.xxl,
          child: VerticalDivider(
            width: AppSpacing.xs,
            thickness: 1,
            color: palette.borderHairline.asIconTheme().color,
          ),
        ),
        _Moitie(
          key: clePasClair,
          icone: AppIcons.info,
          libelle: l.pasClair,
          nombre: ligne.pasClair,
          retenue: ligne.monAvis == AvisGuide.pasClair,
          semantique: l.pasClairLecteur(n: ligne.pasClair),
          large: large,
          onPress: () => onAvis(AvisGuide.pasClair),
        ),
      ],
    );
    Widget commenter(bool large) => _Capsule(
      large: large,
      enfants: <Widget>[
        _Moitie(
          key: cleCommenter,
          icone: AppIcons.discussion,
          libelle: l.commenter,
          nombre: mesCommentaires,
          montrerZero: false,
          retenue: false,
          large: large,
          semantique: mesCommentaires > 0
              ? '${l.commenter}. ${l.commentaires(n: mesCommentaires)}'
              : l.commenter,
          onPress: onCommenter,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        // Au telephone (ou en texte agrandi), chaque capsule prend la largeur
        // de la colonne et ses moities se partagent la place : rien ne deborde,
        // aucun mot ne se coupe.
        final bool etroit =
            c.maxWidth < AppPage.largeurEtatVide * 1.5 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (etroit) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: <Widget>[avis(true), commenter(true)],
          );
        }
        return Row(
          children: <Widget>[avis(false), Ecart.hSm, commenter(false)],
        );
      },
    );
  }
}

/// La capsule : une surface a courbe continue, a filet fin.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.enfants, this.large = false});

  final List<Widget> enfants;

  /// Vrai : la capsule prend toute la largeur, ses moities se la partagent.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Material(
      color: palette.surfaceRaised.background,
      shape: AppRadius.coinContinu(
        _rayon,
        bordure: palette.borderHairline.asBorderSide(width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_marge),
        child: Row(
          mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            for (final Widget e in enfants)
              if (large && e is _Moitie) Expanded(child: e) else e,
          ],
        ),
      ),
    );
  }
}

/// Une moitie de capsule : une icone, un mot, un nombre qui roule.
class _Moitie extends StatefulWidget {
  const _Moitie({
    required this.icone,
    required this.libelle,
    required this.nombre,
    required this.retenue,
    required this.semantique,
    required this.onPress,
    this.montrerZero = true,
    this.large = false,
    super.key,
  });

  final AppIcon icone;
  final String libelle;
  final int nombre;
  final bool retenue;
  final String semantique;
  final VoidCallback onPress;
  final bool montrerZero;
  final bool large;

  @override
  State<_Moitie> createState() => _EtatMoitie();
}

class _EtatMoitie extends State<_Moitie> with SingleTickerProviderStateMixin {
  late final AnimationController _battement = AnimationController(
    vsync: this,
    duration: Mouvement.moyen,
  );

  @override
  void didUpdateWidget(_Moitie ancien) {
    super.didUpdateWidget(ancien);
    // Un avis donne : l'icone bat une fois. Retire : elle se pose sans bruit.
    if (widget.retenue && !ancien.retenue && !Mouvement.reduit(context)) {
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
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair douce = palette.washAccent;
    final Color encre = widget.retenue
        ? douce.onBackground
        : palette.inkStrong.asIconTheme().color!;
    final TextStyle style = (textes.labelLarge ?? const TextStyle()).copyWith(
      color: encre,
    );
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
    ).animate(CurvedAnimation(parent: _battement, curve: Mouvement.entree));
    return ToucherVivant(
      onPress: widget.onPress,
      libelleSemantique: widget.semantique,
      arrondiFocus: BorderRadius.circular(AppRadius.interieur(_rayon, _marge)),
      child: AnimatedContainer(
        duration: Mouvement.court,
        curve: Mouvement.entree,
        constraints: const BoxConstraints(minHeight: AppSpacing.section),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: ShapeDecoration(
          color: widget.retenue
              ? douce.background
              : palette.surfaceRaised.background,
          shape: AppRadius.coinContinu(AppRadius.interieur(_rayon, _marge)),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: widget.large ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ScaleTransition(
                scale: echelle,
                child: Icon(
                  widget.icone.resoudre(selectionne: widget.retenue),
                  size: AppSpacing.xl,
                  color: encre,
                ),
              ),
              Ecart.hSm,
              if (widget.large)
                Flexible(child: Text(widget.libelle, style: style))
              else
                Text(widget.libelle, style: style),
              if (widget.montrerZero || widget.nombre > 0) ...<Widget>[
                Ecart.hSm,
                NombreRouleaux(widget.nombre, style: style),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
