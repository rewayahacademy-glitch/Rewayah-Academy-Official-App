import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'filter_pill.dart';
import 'menu_filtre.dart';

/// La rangee de filtres d'un ecran : **une seule rangee** de puces
/// (`FilterPill`, `MenuFiltre`) qui montre **trois puces au plus**, puis une
/// puce « Plus » qui ouvre les autres dans une feuille (L4-07) ; ce qui ne
/// tient pas defile horizontalement en dernier recours (FILTRES-1, decide par
/// delegation le 05/10/2026).
///
/// **Trois puces, puis « Plus »** (L4-07, ERRATUM-2026-10-16 point 2) : onze
/// puces sur une rangee en cachaient cinq a 1366 et dix a 390, avec une
/// barre de defilement de 12 sous les puces. La rangee en montre trois au
/// plus ; si trois puces ne tiennent pas dans la largeur (texte agrandi,
/// telephone), elle en montre autant qu'il en tient, une au moins, et range
/// le reste sous « Plus ». La puce « Plus » dit combien de filtres caches
/// sont retenus (« Plus, 2 ») : rien n'est cache sans le dire. La feuille
/// est celle du produit (`AppBottomSheet` : feuille sur telephone, boite
/// bornee a `AppPage.largeurDialogue` au-dela). Une feuille n'est pas une
/// seconde rangee : la regle « une rangee, jamais deux » tient.
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
  const RangeeFiltres({required this.filtres, this.replier = true, super.key});

  /// Les puces, dans l'ordre de lecture.
  final List<Widget> filtres;

  /// Vrai (par defaut) pour un **filtre de liste** : trois puces au plus,
  /// puis « Plus » (L4-07). Faux pour un **choix ferme de formulaire** (la
  /// frequence du tirage, L4-04) : chaque valeur doit rester visible, la
  /// rangee n'a pas de « Plus » et defile si elle ne tient pas.
  final bool replier;

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

  /// Une cle par puce, pour amener la puce retenue dans la vue.
  final List<GlobalKey> _cles = <GlobalKey>[];

  /// Le nombre de puces posees dans la rangee a la derniere mise en page :
  /// les autres sont rangees sous « Plus ». Annonce par le rendu
  /// ([RenduRangeeFiltres]) ; la rangee se reconstruit a l'image suivante pour
  /// retirer les puces cachees du parcours au clavier.
  late int _visibles = widget.filtres.length;

  /// Change a chaque nouvelle liste de filtres : la feuille « Plus » ouverte
  /// se met a jour quand on y choisit une valeur.
  final ValueNotifier<int> _version = ValueNotifier<int>(0);

  bool _miseAJourPrevue = false;

  /// Le nombre de puces posees a la derniere mise en page, lu tout de suite
  /// (sans attendre la reconstruction de [_visibles]) pour placer la rangee.
  late int _posees = widget.filtres.length;

  /// La cle de la puce « Plus » du moment, pour l'amener dans la vue.
  final GlobalKey _clePlus = GlobalKey(debugLabel: 'RangeeFiltres.plus');

  void _annoncerVisibles(int n) {
    _posees = n;
    if (n == _visibles || _miseAJourPrevue) return;
    _miseAJourPrevue = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _miseAJourPrevue = false;
      if (mounted && n != _visibles) {
        setState(() => _visibles = n);
        // « Plus » vient d'apparaitre (la rangee ne montre plus toutes ses
        // puces) : s'il porte le filtre retenu, il se voit.
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          if (mounted) _placerRetenu(widget.filtres.indexWhere(_retenu));
        });
      }
    });
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
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _version.value++;
    });
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
    if (i < 0 || !_defilement.hasClients) return;
    final int n = math.min(widget.filtres.length, _cles.length);
    // Une puce rangee sous « Plus » n'est pas dans la rangee : c'est
    // « Plus », qui porte le compte, qui se voit alors.
    final bool sousPlus = i >= _posees;
    if (sousPlus && _posees >= n) return;
    final int cible = sousPlus ? n : i;
    final ScrollPosition position = _defilement.position;
    RenderObject? rendu(int k) =>
        (k == n ? _clePlus : _cles[k]).currentContext?.findRenderObject();
    final RenderObject? puceCible = rendu(cible);
    if (puceCible == null) return;
    final RenderAbstractViewport vue = RenderAbstractViewport.of(puceCible);
    double borne(double v) =>
        v.clamp(position.minScrollExtent, position.maxScrollExtent);
    // La puce retenue entiere, sa fin hors du fondu d'apres (sauf au bout).
    final double auMoins = borne(
      vue.getOffsetToReveal(puceCible, 1).offset + _largeurFondu,
    );
    final double auPlus = borne(vue.getOffsetToReveal(puceCible, 0).offset);
    if (position.pixels >= auMoins && position.pixels <= auPlus) return;
    // La premiere puce dont le debut, place juste apres le fondu d'avant,
    // laisse la puce retenue entiere : la vue s'arrete au debut d'une puce.
    double cibleDefilement = auPlus;
    for (int k = 0; k <= cible; k++) {
      // Les puces rangees sous « Plus » n'ont pas de place dans la rangee.
      if (k >= _posees && k < n) continue;
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

  /// Les nombres de filtres retenus que la puce « Plus » peut annoncer, un
  /// par valeur distincte, selon le nombre de puces montrees : si `k` puces
  /// sont montrees, « Plus » compte les retenues parmi les autres.
  static List<int> _comptesPlus(List<bool> retenues) {
    final Set<int> comptes = <int>{};
    for (int k = 1; k < retenues.length; k++) {
      comptes.add(retenues.skip(k).where((bool r) => r).length);
    }
    return comptes.toList()..sort();
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
    _version.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _lire(ScrollMetrics m) {
    final bool deborde = m.maxScrollExtent > 0;
    final bool avant = m.pixels > m.minScrollExtent + 0.5;
    final bool apres = m.pixels < m.maxScrollExtent - 0.5;
    // Seuls les changements d'etat reconstruisent la rangee : le fondu,
    // lui, suit chaque pas de defilement en se redessinant seul
    // ([RenduFonduBordsRangee] ecoute le controleur, COUPE-MOTS-FOND-1).
    if (deborde != _deborde || avant != _avant || apres != _apres) {
      setState(() {
        _deborde = deborde;
        _avant = avant;
        _apres = apres;
      });
    }
  }

  /// La puce « Plus » qui annonce [compte] filtres retenus parmi ceux qu'elle
  /// range ; [exclue] quand ce n'est pas la variante du moment (elle reste
  /// dans l'arbre, masquee, et ne prend pas le focus).
  Widget _variantePlus(BuildContext context, int compte, bool exclue) {
    return ExcludeFocus(
      excluding: exclue,
      // La variante du moment porte la cle qui sert a l'amener dans la vue.
      child: KeyedSubtree(
        key: exclue ? null : _clePlus,
        child: FilterPill(
          key: ValueKey<String>('rangee-filtres-plus-$compte'),
          libelle: compte == 0
              ? t.commun.filtres.plus
              : t.commun.filtres.plusAvec(n: compte),
          retenue: compte > 0,
          onPress: () => _ouvrirFeuille(context),
        ),
      ),
    );
  }

  /// Ouvre la feuille des filtres ranges sous « Plus ».
  Future<void> _ouvrirFeuille(BuildContext context) {
    final int depuis = _visibles;
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: t.commun.filtres.titreFeuille,
      constructeur: (BuildContext _) => ListenableBuilder(
        listenable: _version,
        builder: (BuildContext _, Widget? _) => LayoutBuilder(
          builder: (BuildContext _, BoxConstraints contraintes) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (int i = depuis; i < widget.filtres.length; i++)
                _PuceBornee(
                  largeurMax: contraintes.maxWidth,
                  child: widget.filtres[i],
                ),
            ],
          ),
        ),
      ),
    );
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
        final List<bool> retenues = <bool>[
          for (final Widget w in widget.filtres) _retenu(w),
        ];
        final List<int> comptes = widget.replier
            ? _comptesPlus(retenues)
            : const <int>[];
        final int visibles = math.min(_visibles, retenues.length);
        final int compteCache = visibles < retenues.length
            ? retenues.skip(visibles).where((bool r) => r).length
            : -1;
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
                // Le fondu se redessine a chaque pas, sans reconstruire.
                defilement: _defilement,
                child: SingleChildScrollView(
                  controller: _defilement,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsetsDirectional.only(
                    bottom: _deborde ? AppSpacing.md : 0,
                  ),
                  // La hauteur de la plus haute puce, donnee a toutes.
                  child: _RangeeAdaptative(
                    nbPuces: widget.filtres.length,
                    retenues: retenues,
                    comptes: comptes,
                    largeurMax: largeurMax,
                    replier: widget.replier,
                    surVisibles: _annoncerVisibles,
                    children: <Widget>[
                      for (int i = 0; i < widget.filtres.length; i++)
                        _PuceBornee(
                          key: _cle(i),
                          largeurMax: largeurMax,
                          // Une puce rangee sous « Plus » ne prend plus le
                          // focus du clavier.
                          child: ExcludeFocus(
                            excluding: i >= visibles,
                            child: widget.filtres[i],
                          ),
                        ),
                      for (final int c in comptes)
                        _variantePlus(context, c, c != compteCache),
                    ],
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
class FonduBordsRangee extends SingleChildRenderObjectWidget {
  /// Cree le fondu.
  const FonduBordsRangee({
    required this.couleur,
    required this.defilement,
    required Widget super.child,
    super.key,
  });

  /// Une couleur opaque quelconque : seul son canal alpha compte.
  final Color couleur;

  /// Le defilement de la rangee : chaque pas redessine le masque, sans
  /// reconstruire la rangee (COUPE-MOTS-FOND-1).
  final Listenable defilement;

  @override
  RenduFonduBordsRangee createRenderObject(BuildContext context) =>
      RenduFonduBordsRangee(couleur, Directionality.of(context), defilement);

  @override
  void updateRenderObject(
    BuildContext context,
    RenduFonduBordsRangee renderObject,
  ) {
    renderObject
      ..couleur = couleur
      ..sens = Directionality.of(context)
      ..defilement = defilement;
  }
}

/// Le rendu de [FonduBordsRangee] : l'etat du fondu se lit sur les puces
/// POSEES, au moment de peindre (la mise en page est alors celle de l'image
/// en cours, jamais la precedente), et le masque se pose sur un calque
/// `ShaderMaskLayer` (COUPE-MOTS-FOND-1). Un bord porte un fondu des qu'il
/// cache une puce, entiere ou en partie, et ce fondu couvre toute la partie
/// visible de la puce coupee (au moins [largeurMinimale], au plus la moitie
/// de la vue) : une puce a moitie visible s'efface, elle ne s'arrete jamais
/// net.
class RenduFonduBordsRangee extends RenderProxyBox {
  /// Cree le rendu.
  RenduFonduBordsRangee(this._couleur, this._sens, this._defilement);

  /// La largeur minimale d'un fondu.
  static const double largeurMinimale = _RangeeFiltresState._largeurFondu;

  Color _couleur;
  set couleur(Color valeur) {
    if (valeur == _couleur) return;
    _couleur = valeur;
    markNeedsPaint();
  }

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) return;
    _sens = valeur;
    markNeedsPaint();
  }

  Listenable _defilement;
  set defilement(Listenable valeur) {
    if (identical(valeur, _defilement)) return;
    if (attached) _defilement.removeListener(markNeedsPaint);
    _defilement = valeur;
    if (attached) _defilement.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  /// L'etat du fondu tel qu'il a ete PEINT en dernier (lu par les gardes,
  /// sans relancer de mesure).
  EtatFonduRangee get etatPeint => _etatPeint;
  EtatFonduRangee _etatPeint = _aucun;

  static const EtatFonduRangee _aucun = (
    avant: false,
    apres: false,
    largeurAvant: largeurMinimale,
    largeurApres: largeurMinimale,
  );

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _defilement.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _defilement.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  /// L'etat du fondu, lu sur les puces posees sous ce rendu.
  EtatFonduRangee _mesurer() {
    final RenderBox? enfant = child;
    if (enfant == null || !hasSize) return _aucun;
    final double largeur = size.width;
    double gauche = 0;
    double droite = 0;
    bool cacheGauche = false;
    bool cacheDroite = false;
    // Les puces : les enfants de la premiere rangee horizontale.
    final List<RenderBox> puces = <RenderBox>[];
    void chercher(RenderObject o) {
      if (o is RenduRangeeFiltres) {
        puces.addAll(o.montres);
        return;
      }
      if (o is RenderFlex && o.direction == Axis.horizontal) {
        o.visitChildren((RenderObject c) {
          if (c is RenderBox) puces.add(c);
        });
        return;
      }
      o.visitChildren(chercher);
    }

    chercher(enfant);
    for (final RenderBox puce in puces) {
      if (!puce.hasSize) continue;
      final Rect r = MatrixUtils.transformRect(
        puce.getTransformTo(this),
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
        visible.clamp(largeurMinimale, math.max(largeurMinimale, largeur / 2));
    final bool ltr = _sens == TextDirection.ltr;
    return (
      avant: ltr ? cacheGauche : cacheDroite,
      apres: ltr ? cacheDroite : cacheGauche,
      largeurAvant: borne(ltr ? gauche : droite),
      largeurApres: borne(ltr ? droite : gauche),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final EtatFonduRangee e = _mesurer();
    _etatPeint = e;
    final Color transparent = _couleur.withValues(alpha: 0);
    final Rect zone = Offset.zero & size;
    double part(double largeur) =>
        zone.width <= 0 ? 0 : (largeur / zone.width).clamp(0, 0.5);
    // Le calque reste pose meme sans fondu (`dst` rend la rangee telle
    // quelle) : la composition ne change pas d'un pas a l'autre.
    layer ??= ShaderMaskLayer();
    layer!
      ..shader = LinearGradient(
        begin: AlignmentDirectional.centerStart.resolve(_sens),
        end: AlignmentDirectional.centerEnd.resolve(_sens),
        colors: <Color>[
          if (e.avant) transparent else _couleur,
          _couleur,
          _couleur,
          if (e.apres) transparent else _couleur,
        ],
        stops: <double>[0, part(e.largeurAvant), 1 - part(e.largeurApres), 1],
      ).createShader(zone)
      ..maskRect = offset & size
      ..blendMode = e.avant || e.apres ? BlendMode.dstIn : BlendMode.dst;
    context.pushLayer(layer!, super.paint, offset);
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

/// La rangee elle-meme (L4-07) : les puces, puis les variantes de la puce
/// « Plus » (une par nombre de filtres retenus qu'elle peut annoncer).
///
/// Le rendu choisit combien de puces tiennent (au plus
/// [RenduRangeeFiltres.puces], et au moins une), pose la variante de « Plus » qui
/// dit le bon compte, et **masque** le reste : ni peint, ni touche, ni lu par
/// le lecteur d'ecran. La hauteur est celle de la plus
/// haute puce montree, donnee a toutes (K-54).
class _RangeeAdaptative extends MultiChildRenderObjectWidget {
  const _RangeeAdaptative({
    required this.nbPuces,
    required this.retenues,
    required this.comptes,
    required this.largeurMax,
    required this.replier,
    required this.surVisibles,
    required super.children,
  });

  /// Le nombre de puces (les enfants suivants sont les variantes de « Plus »).
  final int nbPuces;

  /// Pour chaque puce, vrai si elle porte un filtre en cours.
  final List<bool> retenues;

  /// Le compte annonce par chaque variante de « Plus », dans l'ordre des
  /// enfants qui suivent les puces.
  final List<int> comptes;

  /// La largeur de la rangee.
  final double largeurMax;

  /// Faux : toutes les puces sont montrees, sans « Plus ».
  final bool replier;

  /// Appele, a la mise en page, avec le nombre de puces montrees.
  final ValueChanged<int> surVisibles;

  @override
  RenderObject createRenderObject(BuildContext context) => RenduRangeeFiltres(
    nbPuces,
    retenues,
    comptes,
    largeurMax,
    surVisibles,
    Directionality.of(context),
    replier,
  );

  @override
  void updateRenderObject(BuildContext context, RenduRangeeFiltres rendu) {
    rendu
      ..nbPuces = nbPuces
      ..retenues = retenues
      ..comptes = comptes
      ..largeurMax = largeurMax
      ..surVisibles = surVisibles
      ..replier = replier
      ..sens = Directionality.of(context);
  }
}

class _DonneesRangee extends ContainerBoxParentData<RenderBox> {
  /// Vrai quand l'enfant est range sous « Plus » (ou n'est pas la variante
  /// de « Plus » du moment).
  bool masque = false;
}

/// Le rendu de la rangee de puces d'une [RangeeFiltres] (L4-07) : pose les
/// puces qui tiennent (trois au plus) puis la puce « Plus », et masque le
/// reste. Public pour que les gardes de rendu (`rangeesSansFondu`) lisent les
/// puces POSEES, et non celles rangees sous « Plus ».
class RenduRangeeFiltres extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesRangee>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesRangee> {
  RenduRangeeFiltres(
    this._nbPuces,
    this._retenues,
    this._comptes,
    this._largeurMax,
    this.surVisibles,
    this._sens,
    this._replier,
  );

  /// Le nombre de puces montrees au plus : trois, puis « Plus ».
  static const int puces = 3;

  ValueChanged<int> surVisibles;

  int _nbPuces;
  set nbPuces(int v) {
    if (v == _nbPuces) return;
    _nbPuces = v;
    markNeedsLayout();
  }

  List<bool> _retenues;
  set retenues(List<bool> v) {
    if (listEquals(v, _retenues)) return;
    _retenues = v;
    markNeedsLayout();
  }

  List<int> _comptes;
  set comptes(List<int> v) {
    if (listEquals(v, _comptes)) return;
    _comptes = v;
    markNeedsLayout();
  }

  double _largeurMax;
  set largeurMax(double v) {
    if (v == _largeurMax) return;
    _largeurMax = v;
    markNeedsLayout();
  }

  TextDirection _sens;
  set sens(TextDirection v) {
    if (v == _sens) return;
    _sens = v;
    markNeedsLayout();
  }

  bool _replier;
  set replier(bool v) {
    if (v == _replier) return;
    _replier = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonneesRangee) {
      child.parentData = _DonneesRangee();
    }
  }

  /// Les enfants montres (puces posees et « Plus »), dans l'ordre de lecture.
  Iterable<RenderBox> get montres sync* {
    RenderBox? enfant = firstChild;
    while (enfant != null) {
      final _DonneesRangee donnees = enfant.parentData! as _DonneesRangee;
      if (!donnees.masque) yield enfant;
      enfant = donnees.nextSibling;
    }
  }

  /// Le choix : combien de puces, et quelle variante de « Plus » (-1 sans
  /// « Plus »), d'apres la taille des enfants donnee par [taille].
  ({int k, int variante}) _choisir(Size Function(RenderBox) taille) {
    final List<RenderBox> enfants = getChildrenAsList();
    final int n = math.min(_nbPuces, enfants.length);
    if (n == 0) return (k: 0, variante: -1);
    // Choix ferme : toutes les puces, sans « Plus » ; la rangee defile.
    if (!_replier) return (k: n, variante: -1);
    final List<double> largeurs = <double>[
      for (int i = 0; i < n; i++) taille(enfants[i]).width,
    ];
    double largeurDe(int k) {
      double somme = 0;
      for (int i = 0; i < k; i++) {
        somme += largeurs[i];
      }
      return somme + math.max(0, k - 1) * AppSpacing.sm;
    }

    ({int k, int variante}) dernierRecours = (k: 1, variante: -1);
    for (int k = math.min(puces, n); k >= 1; k--) {
      if (k == n) {
        // Toutes les puces, sans « Plus » : il suffit qu'elles tiennent.
        if (largeurDe(k) <= _largeurMax + 0.5) return (k: k, variante: -1);
        dernierRecours = (k: k, variante: -1);
        continue;
      }
      final int retenues = <bool>[for (int i = k; i < n; i++) _retenues[i]]
          .where((bool r) => r)
          .length;
      final int v = _comptes.indexOf(retenues);
      if (v < 0 || n + v >= enfants.length) continue;
      final double plus = taille(enfants[n + v]).width;
      dernierRecours = (k: k, variante: v);
      if (largeurDe(k) + AppSpacing.sm + plus <= _largeurMax + 0.5) {
        return (k: k, variante: v);
      }
    }
    return dernierRecours;
  }

  static Size _sec(RenderBox b) => b.getDryLayout(const BoxConstraints());

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final List<RenderBox> enfants = getChildrenAsList();
    final ({int k, int variante}) choix = _choisir(_sec);
    double largeur = 0;
    double hauteur = 0;
    int montres = 0;
    for (int i = 0; i < enfants.length; i++) {
      if (i >= choix.k && i != _nbPuces + choix.variante) continue;
      if (choix.variante < 0 && i >= _nbPuces) continue;
      final Size s = _sec(enfants[i]);
      largeur += s.width + (montres > 0 ? AppSpacing.sm : 0);
      hauteur = math.max(hauteur, s.height);
      montres++;
    }
    return constraints.constrain(Size(largeur, hauteur));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      getDryLayout(const BoxConstraints()).width;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      getDryLayout(const BoxConstraints()).width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(const BoxConstraints()).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      getDryLayout(const BoxConstraints()).height;

  @override
  void performLayout() {
    final List<RenderBox> enfants = getChildrenAsList();
    final ({int k, int variante}) choix = _choisir(_sec);
    final int plus = choix.variante < 0 ? -1 : _nbPuces + choix.variante;
    final List<RenderBox> posees = <RenderBox>[
      for (int i = 0; i < enfants.length; i++)
        if (i < choix.k || i == plus) enfants[i],
    ];
    double hauteur = 0;
    for (final RenderBox e in posees) {
      hauteur = math.max(hauteur, _sec(e).height);
    }
    // Les puces montrees ont la meme hauteur ; les autres sont masquees.
    for (final RenderBox e in enfants) {
      final _DonneesRangee donnees = e.parentData! as _DonneesRangee;
      donnees.masque = !posees.contains(e);
      if (donnees.masque) {
        // Pose a sa taille naturelle, comme un `Offstage` : jamais un libelle
        // ecrase a zero (un mot « coupe » pour qui mesure l'arbre). Ni peint,
        // ni touche, ni lu par le lecteur d'ecran.
        e.layout(const BoxConstraints());
        donnees.offset = Offset.zero;
      } else {
        e.layout(
          BoxConstraints(minHeight: hauteur, maxHeight: hauteur),
          parentUsesSize: true,
        );
      }
    }
    double largeur = 0;
    for (final RenderBox e in posees) {
      largeur += e.size.width + (e == posees.first ? 0 : AppSpacing.sm);
    }
    size = constraints.constrain(Size(largeur, hauteur));
    double x = 0;
    for (final RenderBox e in posees) {
      final _DonneesRangee donnees = e.parentData! as _DonneesRangee;
      donnees.offset = Offset(
        _sens == TextDirection.ltr ? x : largeur - x - e.size.width,
        0,
      );
      x += e.size.width + AppSpacing.sm;
    }
    surVisibles(choix.k);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final RenderBox e in montres) {
      final _DonneesRangee donnees = e.parentData! as _DonneesRangee;
      context.paintChild(e, donnees.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox e in montres.toList().reversed) {
      final _DonneesRangee donnees = e.parentData! as _DonneesRangee;
      final bool touche = result.addWithPaintOffset(
        offset: donnees.offset,
        position: position,
        hitTest: (BoxHitTestResult r, Offset p) => e.hitTest(r, position: p),
      );
      if (touche) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    montres.forEach(visitor);
  }
}
