import 'package:flutter/material.dart';

import '../i18n/sens_texte.dart';
import '../i18n/strings.g.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// La mention permanente de la salle de cours.
///
/// **Ce constructeur ne prend aucun parametre, et c'est le coeur de l'ADR-011.**
///
/// Tout le monde sait que la visite de controle est possible ; personne ne sait
/// qu'elle a lieu. Une mention qui apparaitrait a l'entree d'un controleur
/// detruirait l'invisibilite en une seconde. Elle affiche donc en continu, pour
/// l'enseignant comme pour l'eleve, la meme ligne inchangee, que le controleur
/// soit present ou non.
///
/// Aucun parametre de visibilite, de texte ou de variante n'existe ici : si un
/// tel parametre existait dans l'API, quelqu'un finirait par s'en servir. Un
/// seul composant, partage entre toutes les vues de la salle, garantit qu'il
/// ne peut jamais afficher un texte different selon l'ecran.
///
/// Rendu (invariant I-1 de la vague Classe, 26/09/2026) : un point rouge plein
/// de 8 px ([PointEnregistrement]) suivi d'un petit texte en encre
/// secondaire, **sans fond, sans bordure, sans icone**, aligne au debut.
///
/// `tool/verifier_jetons.dart` echoue si ce constructeur gagne un parametre.
class PermanentNotice extends StatelessWidget {
  /// Cree la mention. Sans parametre, definitivement.
  ///
  /// L'absence de `key` est volontaire, comme celle de tout le reste : ce
  /// constructeur ne doit exposer aucune prise. La regle de lint est donc
  /// ecartee ici, et seulement ici.
  // ignore: use_key_in_widget_constructors
  const PermanentNotice();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      liveRegion: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PointEnregistrement(),
          Ecart.hSm,
          Flexible(
            child: Text(
              t.salle.bandeauPermanent,
              // DOCK-X2-1 (bidi) : la phrase garde le sens de SA langue ; en
              // francais dans une interface de droite a gauche, son point
              // final reste a la fin (« possible. », pas « .controle »).
              textDirection: sensDuTexte(t.salle.bandeauPermanent),
              // Le bloc reste cale sur le cote du point, au sens de
              // l'interface (a droite en droite a gauche).
              textAlign: alignementDebut(context),
              style: palette.inkMuted.applyTo(
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le point rouge de l'enregistrement : un disque plein de 8 px, encre
/// d'alerte des points de statut.
///
/// [clignote] : pendant une visite annoncee, l'opacite fait l'aller-retour
/// 100 % vers 40 % sur [AppMouvement.pulsation] (cycle complet d'environ
/// 2,4 s). Avec le mouvement reduit, le point reste fixe : l'information
/// (la notice) est portee par le texte, jamais par l'animation seule.
class PointEnregistrement extends StatefulWidget {
  /// Cree le point.
  const PointEnregistrement({this.clignote = false, super.key});

  /// Le point clignote doucement (visite en cours, hors guidee).
  final bool clignote;

  /// Diametre du point.
  static const double diametre = AppSpacing.sm;

  @override
  State<PointEnregistrement> createState() => _PointEnregistrementState();
}

class _PointEnregistrementState extends State<PointEnregistrement>
    with SingleTickerProviderStateMixin {
  AnimationController? _controleur;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchroniser();
  }

  @override
  void didUpdateWidget(covariant PointEnregistrement ancien) {
    super.didUpdateWidget(ancien);
    _synchroniser();
  }

  void _synchroniser() {
    final bool anime =
        widget.clignote && !AppMouvement.mouvementReduit(context);
    if (anime && _controleur == null) {
      _controleur =
          AnimationController(
              vsync: this,
              duration: AppMouvement.pulsation,
              lowerBound: 0.4,
            )
            ..value = 1
            ..repeat(reverse: true);
    } else if (!anime && _controleur != null) {
      _controleur!.dispose();
      _controleur = null;
    }
  }

  @override
  void dispose() {
    _controleur?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget point = SizedBox.square(
      dimension: PointEnregistrement.diametre,
      child: DecoratedBox(
        decoration: AppPalette.of(context).pointsStatut.alerte.pastille(),
      ),
    );
    final AnimationController? controleur = _controleur;
    return controleur == null
        ? point
        : FadeTransition(opacity: controleur, child: point);
  }
}
