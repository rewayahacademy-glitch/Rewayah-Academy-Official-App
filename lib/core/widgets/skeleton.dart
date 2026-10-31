import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Un bloc de chargement, a la forme du contenu final.
///
/// Deux regles, portees par le composant et non par la vigilance de qui ecrit
/// l'ecran (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 6) :
///
/// 1. **Rien ne s'affiche avant 200 ms.** Un squelette qui clignote coute plus
///    cher qu'il ne rassure. Le delai est tenu ici, pas dans l'ecran ;
/// 2. **le squelette ressemble a la structure finale** : memes hauteurs, meme
///    nombre de blocs. Un squelette generique deplace le contenu au moment ou
///    il arrive, ce qui est pire que rien. D'ou [Skeleton.texte] et
///    [Skeleton.liste], qui prennent la forme de ce qui arrive.
///
/// Il ne scintille pas et ne pulse pas : **un squelette n'est pas une animation
/// d'attente, c'est la forme de ce qui arrive**
/// (`04-systeme-mouvement.md` section 4). La seule zone qui pulse dans ce
/// produit est le bloc « cours dans moins de 5 minutes » d'`ELV-02`.
///
/// Pour une liste d'administration, [Skeleton.tableDense] pose ses barres au pas
/// des lignes d'une table dense.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class Skeleton extends StatefulWidget {
  /// Cree un bloc unique, d'une hauteur donnee.
  const Skeleton({
    required this.hauteur,
    super.key,
    this.largeur,
    this.differe = true,
  }) : lignes = 1,
       fractionDerniere = 1,
       tableDense = false;

  /// Cree la forme d'un paragraphe : [lignes] lignes, la derniere plus courte.
  ///
  /// C'est ce raccourcissement qui distingue un texte qui charge d'un
  /// rectangle gris.
  const Skeleton.texte({this.lignes = 3, super.key, this.differe = true})
    : hauteur = AppSpacing.md,
      largeur = null,
      fractionDerniere = 0.6,
      tableDense = false;

  /// Cree la forme d'une liste de cartes.
  const Skeleton.liste({this.lignes = 3, super.key, this.differe = true})
    : hauteur = AppSpacing.respiration,
      largeur = null,
      fractionDerniere = 1,
      tableDense = false;

  /// Cree la forme d'une carte d'eleve (ChildCard / Bento).
  const Skeleton.carteEleve({this.lignes = 2, super.key, this.differe = true})
    : hauteur = 112.0,
      largeur = null,
      fractionDerniere = 1,
      tableDense = false;

  /// Cree la forme d'une tuile Bento de taille personnalisee.
  const Skeleton.tuileBento({
    this.hauteur = 120.0,
    this.largeur,
    super.key,
    this.differe = true,
  }) : lignes = 1,
       fractionDerniere = 1,
       tableDense = false;

  /// Cree la forme d'une **table dense** : [lignes] barres, une par ligne de
  /// table, au pas d'une ligne de [DataCollection] (une cible tactile du mode
  /// plus sa marge d'anneau, 56 en standard, 80 en Interface guidee).
  ///
  /// Le squelette a la forme de ce qui arrive : dix lignes de table y tiennent
  /// dans la meme hauteur que dix vraies lignes, et le contenu ne saute pas au
  /// moment ou il remplace le squelette (LISTES-1).
  const Skeleton.tableDense({this.lignes = 10, super.key, this.differe = true})
    : hauteur = AppSpacing.lg,
      largeur = null,
      fractionDerniere = 1,
      tableDense = true;

  /// Cree la forme d'une ligne de calendrier / timeline.
  const Skeleton.ligneTimeline({
    this.lignes = 3,
    super.key,
    this.differe = true,
  }) : hauteur = AppSpacing.xxl,
       largeur = null,
       fractionDerniere = 1,
       tableDense = false;

  /// La hauteur d'un bloc.
  final double hauteur;

  /// La largeur d'un bloc. Par defaut, toute la largeur disponible.
  final double? largeur;

  /// Le nombre de blocs empiles.
  final int lignes;

  /// La largeur du dernier bloc, en fraction de la largeur disponible.
  final double fractionDerniere;

  /// Vrai : les blocs sont poses au pas d'une ligne de table dense, pas au
  /// pas d'un paragraphe ([Skeleton.tableDense]).
  final bool tableDense;

  /// Faux pour afficher immediatement, sans le delai de 200 ms.
  ///
  /// **A reserver a la galerie et aux tests.** Un ecran ne met jamais ce
  /// parametre a faux : le delai est la regle, pas une option.
  final bool differe;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  Timer? _minuteur;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.differe) {
      _visible = true;
      return;
    }
    _minuteur = Timer(AppMouvement.delaiSquelette, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    // Entre deux blocs : un paragraphe respire d'un pas moyen ; une table
    // dense se pose au pas de ses lignes (cible tactile du mode + 8), pour que
    // le contenu qui arrive ne decale rien.
    final double ecart = widget.tableDense
        ? metriques.cibleTactile + AppSpacing.sm - widget.hauteur
        : AppSpacing.md;

    // Le squelette est exclu de l'arbre semantique : un lecteur d'ecran n'a
    // rien a annoncer d'une forme vide. C'est l'ecran qui annonce son
    // chargement, une seule fois.
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < widget.lignes; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == widget.lignes - 1 ? 0 : ecart,
              ),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: i == widget.lignes - 1
                    ? widget.fractionDerniere
                    : 1,
                child: _bloc(palette, metriques),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bloc(AppPalette palette, AppMetriques metriques) {
    return SizedBox(
      height: widget.hauteur,
      width: widget.largeur,
      child: DecoratedBox(
        // La surface enfoncee : c'est le plan des pistes et des zones en
        // attente de contenu (`01-systeme-visuel.md` section 2). Aucun filet :
        // un squelette n'est pas une carte, c'est un trou.
        decoration: palette.surfaceSunken.decoration(
          borderRadius: AppRadius.arrondiEnfantDe(metriques.rayon),
        ),
      ),
    );
  }
}
