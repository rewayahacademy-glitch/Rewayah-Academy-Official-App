import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'filter_pill.dart';
import 'menu_filtre.dart';

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

  /// Des puces sont cachees avant le debut (la rangee a defile).
  bool _avant = false;

  /// Des puces sont cachees apres la fin.
  bool _apres = false;

  /// Une cle par puce, pour amener la puce retenue dans la vue.
  final List<GlobalKey> _cles = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    // A l'ouverture, le filtre retenu se voit, meme s'il est loin dans la
    // rangee (une page ouverte filtree, un filtre par defaut).
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      final int i = widget.filtres.indexWhere(_retenu);
      final RenderObject? cible = i < 0 || i >= _cles.length
          ? null
          : _cles[i].currentContext?.findRenderObject();
      // La seule rangee defile : `Scrollable.ensureVisible` ferait aussi
      // defiler la page, qui sauterait jusqu'aux filtres.
      if (cible != null && _defilement.hasClients) {
        // Centree si elle etait cachee ; rien ne bouge si elle se voit deja.
        final RenderAbstractViewport vue = RenderAbstractViewport.of(cible);
        final ScrollPosition position = _defilement.position;
        final double debut = vue.getOffsetToReveal(cible, 0).offset;
        final double fin = vue.getOffsetToReveal(cible, 1).offset;
        if (position.pixels > debut || position.pixels < fin) {
          position.jumpTo(
            vue
                .getOffsetToReveal(cible, 0.5)
                .offset
                .clamp(position.minScrollExtent, position.maxScrollExtent),
          );
        }
      }
    });
  }

  /// Vrai pour une puce qui porte un filtre en cours.
  static bool _retenu(Widget w) => switch (w) {
    final FilterPill p => p.retenue,
    final MenuFiltre<Object?> m => !m.selecteurDeSection && m.valeur != null,
    _ => false,
  };

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  void _lire(ScrollMetrics m) {
    final bool deborde = m.maxScrollExtent > 0;
    final bool avant = m.pixels > m.minScrollExtent + 0.5;
    final bool apres = m.pixels < m.maxScrollExtent - 0.5;
    if (deborde != _deborde || avant != _avant || apres != _apres) {
      setState(() {
        _deborde = deborde;
        _avant = avant;
        _apres = apres;
      });
    }
  }

  GlobalKey _cle(int i) {
    while (_cles.length <= i) {
      _cles.add(GlobalKey());
    }
    return _cles[i];
  }

  bool _mesurer(ScrollMetricsNotification avis) {
    _lire(avis.metrics);
    return false;
  }

  bool _suivre(ScrollUpdateNotification avis) {
    _lire(avis.metrics);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final double largeurMax = contraintes.maxWidth;
        final Color opaque = AppPalette.of(context).surfaceRaised.background;
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: _mesurer,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: _suivre,
            child: Scrollbar(
              controller: _defilement,
              thumbVisibility: _deborde,
              // Le fondu sous la barre : elle reste nette d'un bord a l'autre.
              child: _FonduBords(
                couleur: opaque,
                avant: _avant,
                apres: _apres,
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
                        for (int i = 0; i < widget.filtres.length; i++)
                          _PuceBornee(
                            key: _cle(i),
                            largeurMax: largeurMax,
                            child: widget.filtres[i],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Un fondu sur le bord ou des puces sont cachees : une puce coupee par le
/// bord de l'ecran s'efface au lieu de s'arreter net, et le fondu dit qu'il y
/// en a d'autres de ce cote. Bords pris dans le sens de lecture (le debut est
/// a droite en arabe).
class _FonduBords extends StatelessWidget {
  const _FonduBords({
    required this.couleur,
    required this.avant,
    required this.apres,
    required this.child,
  });

  /// Une couleur opaque quelconque : seul son canal alpha compte.
  final Color couleur;
  final bool avant;
  final bool apres;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextDirection sens = Directionality.of(context);
    final Color transparent = couleur.withValues(alpha: 0);
    // Le masque reste dans l'arbre meme sans fondu (`dst` rend la rangee
    // telle quelle) : l'en retirer recreerait le defilement, revenu au debut.
    return ShaderMask(
      blendMode: avant || apres ? BlendMode.dstIn : BlendMode.dst,
      shaderCallback: (Rect zone) {
        final double f = zone.width <= 0
            ? 0
            : (AppSpacing.xxl / zone.width).clamp(0, 0.5);
        return LinearGradient(
          begin: AlignmentDirectional.centerStart.resolve(sens),
          end: AlignmentDirectional.centerEnd.resolve(sens),
          colors: <Color>[
            if (avant) transparent else couleur,
            couleur,
            couleur,
            if (apres) transparent else couleur,
          ],
          stops: <double>[0, f, 1 - f, 1],
        ).createShader(zone);
      },
      child: child,
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
  const _PuceBornee({
    required this.largeurMax,
    required Widget super.child,
    super.key,
  });

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
