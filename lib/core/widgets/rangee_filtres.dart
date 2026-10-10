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
///     defilement neutre (piste et curseur gris, jamais l'accent : elle ne
///     doit pas se lire comme le soulignement d'un onglet, FILTRES-1b) reste
///     visible sous les puces. Elle dit qu'il y a d'autres
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

  /// La couleur du curseur de defilement : a mi-chemin entre le filet
  /// (`borderHairline`, la piste) et le bord fort (`borderStrong`, le bord
  /// d'une puce). Il se distingue de la piste mais reste plus pale que tout
  /// bord de puce : il ne se lit jamais comme un soulignement d'onglet
  /// (FILTRES-1b, reprise ; decide par delegation le 09/10).
  static Color curseurDefilement(AppPalette palette) => Color.lerp(
    palette.borderHairline.asBorderSide().color,
    palette.borderStrong.asBorderSide().color,
    _partCurseur,
  )!;

  /// La part du bord fort dans la couleur du curseur.
  static const double _partCurseur = 0.5;

  @override
  State<RangeeFiltres> createState() => _RangeeFiltresState();
}

/// Une puce **composee** posee dans une [RangeeFiltres] : un widget qui
/// enveloppe une `FilterPill` (une etiquette d'accessibilite, une pastille
/// de personne qu'on touche pour la retirer) et dit s'il porte un filtre en
/// cours. Sans elle, la rangee ne reconnait que `FilterPill` et
/// `MenuFiltre` et n'amenerait pas la puce retenue dans la vue.
abstract interface class PuceFiltre {
  /// Vrai quand la puce porte un filtre en cours.
  bool get retenue;
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

  /// La position de defilement lue au dernier avis : chaque pas redessine
  /// le fondu, dont la largeur suit la puce coupee (COUPE-MOTS-FOND-1).
  double _pixels = 0;

  /// Une cle par puce, pour amener la puce retenue dans la vue.
  final List<GlobalKey> _cles = <GlobalKey>[];

  /// La cle de la zone qui defile : les puces s'y mesurent.
  final GlobalKey _cleVue = GlobalKey();

  /// L'etat du fondu, lu sur la mise en page REELLE au moment de peindre
  /// (COUPE-MOTS-FOND-1) : un bord porte un fondu des qu'il cache une puce,
  /// entiere ou en partie, et ce fondu couvre toute la partie visible de la
  /// puce coupee (au moins [_largeurFondu], au plus la moitie de la vue) :
  /// une puce a moitie visible s'efface, elle ne s'arrete jamais net.
  EtatFonduRangee _etatFondu() {
    const EtatFonduRangee aucun = (
      avant: false,
      apres: false,
      largeurAvant: _largeurFondu,
      largeurApres: _largeurFondu,
    );
    final RenderObject? rendu = _cleVue.currentContext?.findRenderObject();
    if (rendu is! RenderBox || !rendu.hasSize || !mounted) return aucun;
    final double largeur = rendu.size.width;
    double gauche = 0;
    double droite = 0;
    bool cacheGauche = false;
    bool cacheDroite = false;
    // Les puces posees : les enfants de la rangee, lus dans l'arbre de rendu
    // (une cle de puce retiree peut encore pointer sur un element inactif).
    final List<RenderBox> puces = <RenderBox>[];
    void chercher(RenderObject o) {
      if (o is RenderFlex && o.direction == Axis.horizontal) {
        o.visitChildren((RenderObject c) {
          if (c is RenderBox) puces.add(c);
        });
        return;
      }
      o.visitChildren(chercher);
    }

    rendu.visitChildren(chercher);
    for (final RenderBox puce in puces) {
      if (!puce.hasSize || !puce.attached) continue;
      final Rect r = MatrixUtils.transformRect(
        puce.getTransformTo(rendu),
        Offset.zero & puce.size,
      );
      if (r.left < -0.5) {
        cacheGauche = true;
        if (r.right > 0) gauche = math.max(gauche, r.right);
      }
      if (r.right > largeur + 0.5) {
        cacheDroite = true;
        if (r.left < largeur) droite = math.max(droite, largeur - r.left);
      }
    }
    double borne(double visible) =>
        visible.clamp(_largeurFondu, math.max(_largeurFondu, largeur / 2));
    final bool ltr = Directionality.of(context) == TextDirection.ltr;
    return (
      avant: ltr ? cacheGauche : cacheDroite,
      apres: ltr ? cacheDroite : cacheGauche,
      largeurAvant: borne(ltr ? gauche : droite),
      largeurApres: borne(ltr ? droite : gauche),
    );
  }

  @override
  void initState() {
    super.initState();
    // A l'ouverture, le filtre retenu se voit, meme s'il est loin dans la
    // rangee (une page ouverte filtree, un filtre par defaut), et le debut
    // de la vue reste lisible (FILTRES-1b) : la rangee defile du moins
    // possible et s'arrete au debut d'une puce, jamais au milieu d'un
    // libelle.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _placerRetenu(widget.filtres.indexWhere(_retenu));
    });
  }

  @override
  void didUpdateWidget(RangeeFiltres ancien) {
    super.didUpdateWidget(ancien);
    // Un filtre qui vient d'etre retenu (une personne choisie par la
    // recherche, ajoutee en fin de rangee) se voit aussitot.
    final int i = _nouvellementRetenu(ancien.filtres, widget.filtres);
    if (i >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) _placerRetenu(i);
      });
    }
  }

  /// L'indice de la premiere puce retenue dans [apres] qui ne l'etait pas
  /// dans [avant] (ou qui n'y existait pas), ou -1.
  static int _nouvellementRetenu(List<Widget> avant, List<Widget> apres) {
    for (int i = 0; i < apres.length; i++) {
      if (!_retenu(apres[i])) continue;
      if (i >= avant.length || !_retenu(avant[i])) return i;
    }
    return -1;
  }

  /// Place la rangee pour que la puce retenue se voie entiere, hors des
  /// fondus, sans couper la premiere puce visible : la vue commence au debut
  /// d'une puce (le fondu d'avant ne couvre que l'espace qui la precede et
  /// la fin de la puce d'avant, qui dit qu'il y en a d'autres). Rien ne
  /// bouge si la puce retenue se voit deja hors des fondus.
  ///
  /// La seule rangee defile : `Scrollable.ensureVisible` ferait aussi
  /// defiler la page, qui sauterait jusqu'aux filtres.
  void _placerRetenu(int i) {
    if (i < 0 || i >= _cles.length || !_defilement.hasClients) return;
    final ScrollPosition position = _defilement.position;
    RenderObject? rendu(int k) => _cles[k].currentContext?.findRenderObject();
    final RenderObject? cible = rendu(i);
    if (cible == null) return;
    final RenderAbstractViewport vue = RenderAbstractViewport.of(cible);
    double borne(double v) =>
        v.clamp(position.minScrollExtent, position.maxScrollExtent);
    // La puce retenue entiere, sa fin hors du fondu d'apres (sauf au bout).
    final double auMoins = borne(
      vue.getOffsetToReveal(cible, 1).offset + _largeurFondu,
    );
    final double auPlus = borne(vue.getOffsetToReveal(cible, 0).offset);
    if (position.pixels >= auMoins && position.pixels <= auPlus) return;
    // La premiere puce dont le debut, place juste apres le fondu d'avant,
    // laisse la puce retenue entiere : la vue s'arrete au debut d'une puce.
    double cibleDefilement = auPlus;
    for (int k = 0; k <= i; k++) {
      final RenderObject? puce = rendu(k);
      if (puce == null) continue;
      final double debut = borne(
        vue.getOffsetToReveal(puce, 0).offset - (k == 0 ? 0 : _largeurFondu),
      );
      if (debut >= auMoins && debut <= auPlus) {
        cibleDefilement = debut;
        break;
      }
    }
    position.jumpTo(cibleDefilement);
  }

  /// La largeur du fondu de bord ([FonduBordsRangee]).
  static const double _largeurFondu = AppSpacing.xxl;

  /// Vrai pour une puce qui porte un filtre en cours : une `FilterPill`
  /// retenue, un `MenuFiltre` qui porte une valeur, ou une puce composee
  /// (une `FilterPill` enveloppee, par exemple dans un `Semantics`) qui le
  /// declare par [PuceFiltre]. Une puce composee qui ne le declare pas
  /// n'est jamais amenee dans la vue (FILTRES-1b, reprise).
  static bool _retenu(Widget w) => switch (w) {
    final PuceFiltre p => p.retenue,
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
    if (deborde != _deborde ||
        avant != _avant ||
        apres != _apres ||
        m.pixels != _pixels) {
      // Chaque pas de defilement redessine le fondu : sa largeur suit la
      // puce coupee (COUPE-MOTS-FOND-1).
      setState(() {
        _deborde = deborde;
        _avant = avant;
        _apres = apres;
        _pixels = m.pixels;
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
        final AppPalette palette = AppPalette.of(context);
        final Color opaque = palette.surfaceRaised.background;
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: _mesurer,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: _suivre,
            // FILTRES-1b : une barre de defilement **neutre et discrete**,
            // avec sa piste : sous les puces, un trait d'accent, puis un
            // trait gris fonce, se lisaient comme le soulignement d'un
            // onglet actif. La piste sur toute la largeur et un curseur
            // pale (a mi-chemin entre le filet et le bord fort, toujours
            // moins marque que le bord d'une puce) disent « barre de
            // defilement », sans rien designer ; la puce retenue reste la
            // seule marque de selection.
            // Gardee visible des que la rangee deborde : sur ordinateur, la
            // molette ne fait pas defiler une rangee horizontale, et c'est
            // elle qu'on tire a la souris.
            child: RawScrollbar(
              controller: _defilement,
              thumbVisibility: _deborde,
              trackVisibility: _deborde,
              thickness: AppSpacing.xs,
              radius: const Radius.circular(AppSpacing.xs),
              thumbColor: RangeeFiltres.curseurDefilement(palette),
              trackColor: palette.borderHairline.asBorderSide().color,
              trackBorderColor: palette.borderHairline.asBorderSide().color,
              // Le fondu sous la barre : elle reste nette d'un bord a l'autre.
              child: FonduBordsRangee(
                couleur: opaque,
                etat: _etatFondu,
                // Ce qui change le dessin du fondu : un nouvel objet a
                // chaque pas, pour que le masque se redessine.
                repere: (_avant, _apres, _pixels),
                child: SingleChildScrollView(
                  key: _cleVue,
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
class FonduBordsRangee extends StatelessWidget {
  /// Cree le fondu.
  const FonduBordsRangee({
    super.key,
    required this.couleur,
    required this.etat,
    required this.child,
    this.repere,
  });

  /// Une couleur opaque quelconque : seul son canal alpha compte.
  final Color couleur;

  /// L'etat du fondu, lu sur la mise en page reelle (au moment de peindre).
  final EtatFonduRangee Function() etat;

  /// Ce qui, en changeant, redessine le masque (la position de defilement).
  final Object? repere;

  /// La rangee.
  final Widget child;

  /// Vrai : des puces sont cachees avant le debut (fondu au debut).
  bool get avant => etat().avant;

  /// Vrai : des puces sont cachees apres la fin (fondu a la fin).
  bool get apres => etat().apres;

  /// La largeur du fondu au debut.
  double get largeurAvant => etat().largeurAvant;

  /// La largeur du fondu a la fin.
  double get largeurApres => etat().largeurApres;

  @override
  Widget build(BuildContext context) {
    final TextDirection sens = Directionality.of(context);
    final Color transparent = couleur.withValues(alpha: 0);
    // Le masque reste dans l'arbre meme sans fondu (`dst` rend la rangee
    // telle quelle) : l'en retirer recreerait le defilement, revenu au
    // debut. COUPE-MOTS-FOND-1 : l'etat se lit sur les puces posees (a la
    // construction, sur la derniere mise en page ; au moment de peindre, sur
    // la mise en page courante) : un bord qui cache une puce porte toujours
    // son fondu, a la largeur de la partie visible de la puce.
    final EtatFonduRangee pose = etat();
    return ShaderMask(
      blendMode: pose.avant || pose.apres ? BlendMode.dstIn : BlendMode.dst,
      shaderCallback: (Rect zone) {
        final EtatFonduRangee e = etat();
        double part(double largeur) =>
            zone.width <= 0 ? 0 : (largeur / zone.width).clamp(0, 0.5);
        return LinearGradient(
          begin: AlignmentDirectional.centerStart.resolve(sens),
          end: AlignmentDirectional.centerEnd.resolve(sens),
          colors: <Color>[
            if (e.avant) transparent else couleur,
            couleur,
            couleur,
            if (e.apres) transparent else couleur,
          ],
          stops: <double>[0, part(e.largeurAvant), 1 - part(e.largeurApres), 1],
        ).createShader(zone);
      },
      child: child,
    );
  }
}

/// L'etat d'un [FonduBordsRangee] : un fondu a chaque bord qui cache une
/// puce, et sa largeur, dans le sens de lecture.
typedef EtatFonduRangee = ({
  bool avant,
  bool apres,
  double largeurAvant,
  double largeurApres,
});

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
