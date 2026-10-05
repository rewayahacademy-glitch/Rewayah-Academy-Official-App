import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_spacing.dart';

/// La rangee de filtres d'un ecran : **une seule rangee** de puces
/// (`FilterPill`, `MenuFiltre`) qui defile horizontalement quand elle ne tient
/// pas (FILTRES-1, decide par delegation le 05/10/2026).
///
/// Ce que la rangee garantit, et que chaque ecran faisait jusque-la a sa
/// facon avec un `Wrap` (deux, trois, quatre lignes de puces a 320 px texte
/// x2, la liste repoussee sous le pli) :
///
///   * **une rangee, jamais deux** : les puces restent alignees, la liste
///     commence toujours a la meme hauteur ;
///   * **des puces de meme hauteur**, contenu centre (K-54) : la rangee prend
///     la hauteur de la plus haute et etire les autres, `FilterPill` et
///     `MenuFiltre` centrent deja leur contenu quand le parent les etire ;
///   * **aucun mot coupe** : chaque puce recoit toute la largeur dont elle a
///     besoin, son libelle tient sur une ligne, ni coupe ni tronque, a 320 px
///     texte x2, en francais comme en arabe ;
///   * **aucun debordement** : ce qui ne tient pas defile, dans le sens de
///     lecture (de droite a gauche en arabe) ;
///   * **rien de cache sans le dire** : des que la rangee deborde, une barre de
///     defilement reste visible sous les puces. Elle dit qu'il y a d'autres
///     filtres, et elle se tire a la souris (sur ordinateur, la molette ne
///     fait pas defiler une rangee horizontale). Au clavier, la puce qui
///     recoit le focus est amenee dans la vue.
///
/// **Ce n'est pas un selecteur de sections.** Changer de section passe par
/// `SelecteurSection` (ONGLETS-1) ; une rangee de filtres porte des valeurs
/// cumulables ou un axe ferme, et chaque puce dit si elle est retenue.
///
/// Les valeurs se **choisissent**, elles ne se saisissent pas : un axe ferme
/// en puces, un axe ouvert en `MenuFiltre` dont les entrees viennent des
/// donnees de l'ecran (classes, roles, types d'evenement).
class RangeeFiltres extends StatefulWidget {
  /// Cree la rangee.
  const RangeeFiltres({required this.filtres, super.key});

  /// Les puces, dans l'ordre de lecture.
  final List<Widget> filtres;

  @override
  State<RangeeFiltres> createState() => _RangeeFiltresState();
}

class _RangeeFiltresState extends State<RangeeFiltres> {
  final ScrollController _defilement = ScrollController();

  /// Vrai quand les puces ne tiennent pas dans la largeur : la barre de
  /// defilement s'affiche et la rangee lui laisse sa place.
  bool _deborde = false;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  bool _mesurer(ScrollMetricsNotification avis) {
    final bool deborde = avis.metrics.maxScrollExtent > 0;
    if (deborde != _deborde) {
      setState(() => _deborde = deborde);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final double largeurMax = contraintes.maxWidth;
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: _mesurer,
          child: Scrollbar(
            controller: _defilement,
            thumbVisibility: _deborde,
            child: SingleChildScrollView(
              controller: _defilement,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.only(
                bottom: _deborde ? AppSpacing.md : 0,
              ),
              // La hauteur de la plus haute puce, donnee a toutes.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final Widget filtre in widget.filtres)
                      _PuceBornee(largeurMax: largeurMax, child: filtre),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Une puce jamais plus large que la rangee : un libelle plus long que
/// l'ecran (« Toutes les classes » a 320 px texte x2) passe a la ligne
/// **entre** ses mots au lieu de cacher sa fin hors de la vue. Seul un mot
/// plus large que la rangee a lui seul elargit sa puce : il n'est pas coupe.
///
/// Les mesures intrinseques sont celles de la puce **posee** a la largeur de
/// la rangee (mise en page a blanc), et non celles que la puce annonce : un
/// `Wrap` annonce une largeur intrinseque qui oublie son `spacing`, et la
/// rangee aurait alors mesure chaque pastille compteur sous le libelle. C'est
/// ce qui permet de donner a toutes les puces la hauteur de la plus haute.
class _PuceBornee extends SingleChildRenderObjectWidget {
  const _PuceBornee({required this.largeurMax, required Widget super.child});

  final double largeurMax;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduPuceBornee(largeurMax);

  @override
  void updateRenderObject(BuildContext context, _RenduPuceBornee rendu) {
    rendu.largeurMax = largeurMax;
  }
}

class _RenduPuceBornee extends RenderProxyBox {
  _RenduPuceBornee(this._largeurMax);

  double _largeurMax;

  set largeurMax(double valeur) {
    if (valeur == _largeurMax) return;
    _largeurMax = valeur;
    markNeedsLayout();
  }

  /// La largeur de la rangee, sauf si un mot de la puce est a lui seul plus
  /// large : un mot n'est jamais coupe, la puce s'elargit alors et la rangee
  /// defile (largeur intrinseque minimale = le plus long mot insecable).
  BoxConstraints get _borne => BoxConstraints(
    maxWidth: math.max(
      _largeurMax,
      child?.getMinIntrinsicWidth(double.infinity) ?? 0,
    ),
  );

  /// La taille de la puce posee librement, bornee a la largeur de la rangee.
  Size get _naturelle => child?.getDryLayout(_borne) ?? Size.zero;

  @override
  double computeMinIntrinsicWidth(double height) => _naturelle.width;

  @override
  double computeMaxIntrinsicWidth(double height) => _naturelle.width;

  @override
  double computeMinIntrinsicHeight(double width) => _naturelle.height;

  @override
  double computeMaxIntrinsicHeight(double width) => _naturelle.height;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    child?.getDryLayout(constraints.enforce(_borne)) ?? Size.zero,
  );

  @override
  void performLayout() {
    final RenderBox? enfant = child;
    if (enfant == null) {
      size = constraints.smallest;
      return;
    }
    enfant.layout(constraints.enforce(_borne), parentUsesSize: true);
    size = constraints.constrain(enfant.size);
  }
}
