import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// L'etat d'interaction d'une zone pressable, a un instant donne.
///
/// Le survol n'existe pas au doigt et le clavier n'existe pas au telephone :
/// un composant ne doit donc jamais faire reposer un etat sur un seul des deux
/// (`docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md` section 5). Les trois voyants sont
/// exposes ensemble pour que le composant qui porte une surface puisse les
/// traiter ensemble.
@immutable
class EtatPression {
  /// Cree un etat d'interaction.
  const EtatPression({
    this.survole = false,
    this.presse = false,
    this.focus = false,
    this.actif = true,
  });

  /// La souris est au dessus. Toujours faux au doigt.
  final bool survole;

  /// Le doigt ou le bouton est enfonce.
  final bool presse;

  /// Le clavier a donne le focus a cette zone.
  final bool focus;

  /// Faux quand la pression est impossible.
  final bool actif;

  @override
  bool operator ==(Object other) =>
      other is EtatPression &&
      other.survole == survole &&
      other.presse == presse &&
      other.focus == focus &&
      other.actif == actif;

  @override
  int get hashCode => Object.hash(survole, presse, focus, actif);
}

/// Force l'etat d'interaction de tous les [Pressable] de son sous-arbre.
///
/// **Reserve a la galerie.** Le survol, la pression et le focus naissent de la
/// souris et du clavier : ils ne se declenchent pas depuis l'exterieur. Sans ce
/// forcage, la galerie ne pourrait pas montrer les dix etats cote a cote, ce
/// que `docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 5 exige, et la seule
/// facon de les voir serait de promener une souris sur chaque composant.
///
/// Il est pose **au dessus** des composants plutot que passe en parametre a
/// chacun : `AppCard`, `BentoTile`, `ActionPrincipale` et les autres n'ont donc
/// aucune prise a propager, et c'est ce qui empeche la prise de se repandre.
///
/// C'en reste une, donc un risque : quelqu'un finirait par s'en servir dans un
/// ecran pour peindre un survol qui n'existe pas.
/// `tool/verifier_jetons.dart` echoue si ce type apparait ailleurs que dans ce
/// fichier et dans `lib/features/_dev/`.
class PressionForcee extends InheritedWidget {
  /// Force un etat d'interaction sur tout le sous-arbre.
  const PressionForcee({required this.etat, required super.child, super.key});

  /// L'etat impose.
  final EtatPression etat;

  /// L'etat impose par l'ancetre le plus proche, s'il y en a un.
  static EtatPression? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PressionForcee>()?.etat;

  @override
  bool updateShouldNotify(PressionForcee ancien) => ancien.etat != etat;
}

/// Le seul point d'entree du retour tactile de l'application.
///
/// Echelle 0.98, 100 ms, retour haptique moyen. **Aucun `onTap` nu ailleurs
/// dans le code** : `tool/verifier_jetons.dart` echoue si un autre fichier de
/// `lib/` en declare un
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 2).
///
/// Une seule implementation garantit que deux boutons de deux ecrans differents
/// ne repondent jamais differemment au doigt.
///
/// **Le lot C lui ajoute les deux entrees qui manquaient au Web** : le survol
/// de la souris et l'anneau de focus du clavier
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 1). Ils sont rendus ici et
/// non dans chaque composant, pour la meme raison que la pression : deux
/// anneaux de focus dessines a deux endroits finiraient par ne plus se
/// ressembler.
class Pressable extends StatefulWidget {
  /// Cree une zone pressable au contenu fixe.
  const Pressable({
    required Widget this.child,
    required this.onPress,
    super.key,
    this.libelleSemantique,
    this.actif = true,
    this.respecterCibleTactile = true,
    this.arrondiFocus,
    this.autofocus = false,
    this.focusNode,
  }) : constructeur = null;

  /// Cree une zone pressable dont le contenu suit l'etat d'interaction.
  ///
  /// A employer par tout composant qui porte une surface : c'est ainsi qu'une
  /// carte s'eleve au survol et qu'une ligne change de fond, sans que chacune
  /// reimplemente l'ecoute de la souris.
  const Pressable.selon({
    required Widget Function(BuildContext context, EtatPression etat)
    this.constructeur,
    required this.onPress,
    super.key,
    this.libelleSemantique,
    this.actif = true,
    this.respecterCibleTactile = true,
    this.arrondiFocus,
    this.autofocus = false,
    this.focusNode,
  }) : child = null;

  /// Le contenu rendu, quand il ne depend pas de l'etat.
  final Widget? child;

  /// Le contenu rendu, quand il depend de l'etat.
  final Widget Function(BuildContext context, EtatPression etat)? constructeur;

  /// L'action declenchee. `null` desactive la pression.
  final VoidCallback? onPress;

  /// Libelle lu par les technologies d'assistance.
  final String? libelleSemantique;

  /// Faux pour rendre le contenu sans le rendre pressable.
  final bool actif;

  /// Applique la cible tactile minimale du mode courant. A ne mettre a faux
  /// que pour un element deja plus grand que la cible, jamais pour la reduire.
  final bool respecterCibleTactile;

  /// L'arrondi de l'anneau de focus. Par defaut, celui du mode courant.
  ///
  /// A renseigner quand la zone n'a pas la forme d'une carte : une pilule prend
  /// `AppRadius.arrondiFull`, un bouton `AppRadius.arrondiSm`.
  final BorderRadius? arrondiFocus;

  /// Prend le focus des l'apparition. Reserve au premier champ d'une feuille.
  final bool autofocus;

  /// Le noeud de focus, fourni quand l'appelant doit rendre le focus a cette
  /// zone (le bouton qui a ouvert un panneau, a sa fermeture).
  final FocusNode? focusNode;

  /// Duree de l'animation de pression : le retour tactile du budget de
  /// mouvement, jamais une valeur posee ici (`app_mouvement.dart`).
  static const Duration duree = AppMouvement.retourTactile;

  /// Echelle atteinte au doigt pose.
  static const double echelleEnfoncee = 0.98;

  /// Epaisseur de l'anneau de focus. Deux points : c'est le minimum visible
  /// sur un ecran de telephone d'entree de gamme.
  static const double epaisseurFocus = 2;

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

  bool _survole = false;
  bool _presse = false;
  bool _focus = false;

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
    setState(() => _presse = true);
    if (!AppMouvement.mouvementReduit(context)) {
      unawaited(_controleur.reverse());
    }
  }

  void _relacher() {
    if (_presse) {
      setState(() => _presse = false);
    }
    if (!AppMouvement.mouvementReduit(context)) {
      unawaited(_controleur.forward());
    }
  }

  void _declencher() {
    if (!_pressable) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    widget.onPress!.call();
  }

  /// Le declenchement au clavier.
  ///
  /// Sans lui, l'anneau de focus se poserait sur une zone que la touche Entree
  /// ne saurait pas activer : un focus visible qui ne mene a rien est pire
  /// qu'un focus absent.
  void _activerAuClavier() {
    if (!_pressable) {
      return;
    }
    // Le retour tactile complet, aller puis retour, pour que la zone reponde
    // au clavier comme elle repond au doigt.
    if (!AppMouvement.mouvementReduit(context)) {
      unawaited(
        _controleur.reverse().then((void _) {
          if (mounted) {
            _controleur.forward();
          }
        }),
      );
    }
    _declencher();
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final EtatPression etat =
        PressionForcee.de(context) ??
        EtatPression(
          survole: _survole && _pressable,
          presse: _presse,
          focus: _focus && _pressable,
          actif: _pressable,
        );

    Widget contenu = ScaleTransition(
      scale: AppMouvement.mouvementReduit(context)
          ? const AlwaysStoppedAnimation<double>(1)
          : _controleur,
      child: widget.child ?? widget.constructeur!(context, etat),
    );

    // The ring is outside the hit target: no layout shift and no clipping.
    if (etat.focus) {
      contenu = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          contenu,
          PositionedDirectional(
            start: -AppSpacing.xs,
            end: -AppSpacing.xs,
            top: -AppSpacing.xs,
            bottom: -AppSpacing.xs,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.arrondiFocus ?? metriques.arrondi,
                  border: Border.fromBorderSide(
                    palette.inkAccent.asBorderSide(
                      width: Pressable.epaisseurFocus,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

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
      child: FocusableActionDetector(
        enabled: _pressable,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        mouseCursor: _pressable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (bool survole) {
          if (survole != _survole) {
            setState(() => _survole = survole);
          }
        },
        onShowFocusHighlight: (bool focus) {
          if (focus != _focus) {
            setState(() => _focus = focus);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent _) {
              _activerAuClavier();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enfoncer,
          onTapUp: (TapUpDetails _) => _relacher(),
          onTapCancel: _relacher,
          onTap: _pressable ? _declencher : null,
          child: contenu,
        ),
      ),
    );
  }
}
