import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import '../accessibilite/texte_sans_coupure.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'entete_page.dart';
import 'offline_banner.dart';

/// Hauteur disponible sous laquelle la tete d'une page defilante defile avec
/// le corps (vue tres basse, zoom 400 %) au lieu de rester fixe.
const double _hauteurTeteFixe = 360;

/// Le gabarit de page du produit. **Tout ecran passe par lui.**
///
/// Ce qu'il tient, et qu'aucun ecran ne refait
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 2) :
///
/// - le fond creme, qui vient du theme ;
/// - la **gouttiere du gabarit courant** : 16 sur mobile, 24 sur tablette, 32
///   sur desktop (contrat A). Aucun ecran ne compare une largeur a un nombre, c'est
///   `AppGabarit` qui le fait, en un seul endroit ;
/// - la **largeur bornee a 1200**, au dela de laquelle la colonne se centre.
///   Un ecran mobile etire sur 1400 pixels donne une colonne perdue au milieu
///   d'un desert (`05-regles-responsive.md` section 2) ;
/// - le bandeau hors ligne, en tete et sans gouttiere, parce qu'un bandeau de
///   pleine largeur se lit comme un etat de l'application et non de la page ;
/// - l'**en-tete** : le titre, et, quand il y en a, le disque retour, un
///   sous-titre et les actions a droite. Les actions viennent de la page
///   ([actionsEntete]) et de la coquille du role ([ActionsEnteteCoquille] :
///   la cloche et la bascule de theme du tuteur) ;
/// - la zone d'action **collee en bas**, qui flotte au dessus du contenu et
///   porte donc le niveau 2 d'elevation.
///
/// Il ne porte volontairement **ni les etats de donnees ni la navigation** :
/// les premiers viennent de `Skeleton` et d'`EmptyState`, la seconde de
/// `NavShell`. Un gabarit qui saurait tout finirait par etre la seule chose que
/// personne n'ose modifier.
///
/// **Zone sure** : le corps est en `SafeArea`, et c'est la coquille qui retire
/// de son `MediaQuery` l'encart deja consomme par sa barre ou sa colonne
/// (`NavShell`) : aucun encart n'est applique deux fois.
class PageShell extends StatelessWidget {
  /// Cree une page.
  const PageShell({
    required this.child,
    super.key,
    this.titre,
    this.sousTitre,
    this.onRetour,
    this.actionsEntete = const <Widget>[],
    this.entete,
    this.actions,
    this.defilante = true,
    this.actionsCoquille = true,
    this.focusTitre,
  });

  /// Le focus du titre, pour qu'une page y ramene le lecteur (voir
  /// [EntetePage.focusTitre]).
  final FocusNode? focusTitre;

  /// Le corps de la page.
  final Widget child;

  /// Le titre d'ecran. **Ne se souhaite pas la bienvenue** : « Aujourd'hui »,
  /// pas « Bienvenue sur votre tableau de bord »
  /// (`02-regles-ux.md` section 9).
  final String? titre;

  /// Une ligne sous le titre, en encre attenuee.
  final String? sousTitre;

  /// Le retour d'une page de niveau 2 ou d'une tache focalisee : sans lui,
  /// aucun disque retour n'est rendu.
  final VoidCallback? onRetour;

  /// Les actions propres a la page, a droite du titre, **avant** celles de la
  /// coquille.
  final List<Widget> actionsEntete;

  /// Ce qui suit immediatement le titre et ne defile pas : un onglet, un
  /// selecteur d'enfant, une ligne de contexte.
  final Widget? entete;

  /// La zone d'action collee en bas. C'est la qu'habite l'action principale
  /// d'un ecran de saisie.
  final Widget? actions;

  /// Faux quand le corps gere son propre defilement, par exemple une liste
  /// paresseuse ou une grille de semaine defilante horizontalement.
  final bool defilante;

  /// Faux pour une tache focalisee (ajout de profil, admission par etapes) :
  /// ni cloche ni bascule de theme de la coquille, la page ne garde que ses
  /// propres [actionsEntete] (demande B-3 ; planche V6, la rangee d'etape est
  /// la premiere ligne). Voir `PageEtape`.
  final bool actionsCoquille;

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final Gabarit gabarit = AppGabarit.de(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<Widget> actionsTete = <Widget>[
      ...actionsEntete,
      if (actionsCoquille) ...ActionsEnteteCoquille.de(context),
    ];
    final VoidCallback? retour =
        onRetour ??
        (actionsCoquille ? ActionsEnteteCoquille.retourDe(context) : null);
    final bool enteteRiche =
        retour != null || sousTitre != null || actionsTete.isNotEmpty;

    // La tete ne defile pas : le titre d'ecran, puis l'en-tete (un onglet, le
    // selecteur d'enfant de `TUT-01`, une ligne de contexte). C'est une zone
    // distincte de la zone defilante, au meme titre que la zone d'action
    // collee en bas (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 2).
    final List<Widget> tete = <Widget>[
      if (titre != null) ...<Widget>[
        // 48 au dessus d'un titre d'ecran, c'est le rythme de page
        // (`01-systeme-visuel.md` section 6). En mode enfant, la marge de
        // respiration prend le relais. Un en-tete a actions (cloche, disque
        // retour) porte deja sa cible de 48 : il ne prend que 24.
        SizedBox(
          height: metriques.estEnfant
              ? AppSpacing.respiration
              : enteteRiche
              ? AppSpacing.xxl
              : AppSpacing.titreEcran,
        ),
        if (enteteRiche)
          EntetePage(
            titre: titre!,
            sousTitre: sousTitre,
            onRetour: retour,
            actions: actionsTete,
            focusTitre: focusTitre,
          )
        else
          // COUPE-MOTS-1 : un titre de page passe a la ligne entre ses mots,
          // jamais dans un mot (« Aujourd'hu / i » a 320 px, 200 %).
          titreFocalisable(
            focusTitre,
            TexteSansCoupure(
              titre!,
              style: textes.headlineLarge ?? const TextStyle(),
            ),
          ),
        Ecart.vXxl,
      ] else if (enteteRiche) ...<Widget>[
        // Sans titre, la page garde son disque retour et les actions de la
        // coquille : une ligne, retour au debut, actions a la fin.
        Ecart.vLg,
        Row(
          children: <Widget>[
            if (retour != null) DisqueRetour(onPress: retour),
            const Spacer(),
            for (final Widget action in actionsTete) ...<Widget>[
              Ecart.hXs,
              action,
            ],
          ],
        ),
        Ecart.vLg,
      ] else
        Ecart.vXxl,
      if (entete != null) ...<Widget>[entete!, Ecart.vXl],
    ];

    // Un `Column` donne a ses enfants non flexibles une hauteur **non bornee**.
    // Envelopper le contenu de l'ecran pour lui ajouter une respiration de bas
    // de page cassait donc tout ecran qui gere son propre defilement avec un
    // `Expanded` : la mesure echouait, et en build release, ou les assertions
    // sont retirees, le corps disparaissait sans une ligne d'erreur ni un appel
    // reseau en echec. Cinq ecrans de production etaient dans ce cas
    // (`ADM-07`, `ADM-04`, `CTR-01`, le suivi eleve et `TUT-06`), et la dette
    // etait deja ecrite dans la fiche `TUT-00b` du catalogue sans avoir jamais
    // ete payee.
    //
    // En mode non defilant, le contenu devient l'enfant direct de l'`Expanded`
    // ci-dessous et recoit donc une hauteur bornee. La respiration n'a de sens
    // que dans le cas defilant, ou c'est le contenu qui pousse le bas de page.
    final Widget corps = defilante
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              child,
              // La respiration de bas de page : sans elle, le dernier element
              // colle au bord de l'ecran ou passe sous la zone d'action.
              Ecart.vSection,
            ],
          )
        : child;

    // A texte agrandi (au-dela de 130 %), la tete (titre sur plusieurs lignes,
    // phrase d'introduction) peut prendre toute la hauteur d'un telephone et
    // ne laisser aucune place a la zone qui defile (MA15) : elle defile alors
    // avec le contenu. En taille normale, rien ne change.
    final bool teteDefile =
        defilante && MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const OfflineBanner(),
            Expanded(
              child: _Colonne(
                gouttiere: gabarit.gouttiere,
                // AD-11 (1.4.10) : sur une vue tres basse (1280x1024 a
                // 400 %, soit 256 de haut), la tete fixe ne laisse plus de
                // place au corps et deborde ; la page defilante fait alors
                // defiler la tete avec le corps. Un corps non defilant (liste
                // paresseuse) y recoit la hauteur laissee sous la tete
                // (PAGESHELL-200-1), ou, si la tete en laisse moins de la
                // moitie, la hauteur de la vue : la tete defile, puis la
                // liste occupe tout l'ecran. Jamais moins que ce qu'il
                // signale lui manquer (`ColonneCorps`, PAGESHELL-200-1b).
                // Meme regle sur mobile a 200 % de texte : la tete (titre,
                // sous-titre, onglets) y prend presque toute la hauteur et
                // ne laissait au corps qu'une bande (390x844, 44 de
                // debordement, ligne de la file hors d'atteinte).
                // Le clavier virtuel ne compte pas dans ce seuil : il est
                // passager, et basculer la structure a son ouverture
                // remontait le corps (la revue et le motif de 02D, ouvert
                // dessus, a 320x640 avec un clavier de 300). Lu sur la vue :
                // le Scaffold de la coquille retire le clavier du MediaQuery
                // de son corps.
                // MA-RC B1 : une page defilante a texte agrandi (au-dela de
                // 130 %) fait aussi defiler sa tete, sur tout gabarit.
                child: _Bascule(
                  teteDefilante: (double hauteur) =>
                      teteDefile ||
                      hauteur +
                              View.of(context).viewInsets.bottom /
                                  View.of(context).devicePixelRatio <
                          _hauteurTeteFixe ||
                      (gabarit == Gabarit.mobile &&
                          MediaQuery.textScalerOf(context).scale(1) >= 2),
                  tete: tete,
                  corps: corps,
                  defilante: defilante,
                ),
              ),
            ),
            if (actions != null)
              _ZoneAction(gouttiere: gabarit.gouttiere, child: actions!),
          ],
        ),
      ),
    );
  }
}

/// Les actions d'en-tete qu'une **coquille de role** pose sur chacune de ses
/// pages : la cloche des notifications, et, a partir de la tablette, la
/// bascule clair / sombre (manifeste visuel Tuteur V1 section 4.2).
///
/// Posee par la coquille au-dessus de ses branches, lue par [PageShell] :
/// aucun ecran n'a a savoir qu'elles existent, et un role sans cloche n'en
/// recoit aucune. Hors de toute coquille, la liste est vide.
class ActionsEnteteCoquille extends InheritedWidget {
  /// Pose les actions pour tout le sous-arbre.
  const ActionsEnteteCoquille({
    required this.actions,
    required super.child,
    super.key,
    this.onRetour,
  });

  /// Les actions, dans l'ordre de lecture (la cloche en dernier).
  final List<Widget> actions;

  /// Le retour que la coquille pose sur chacune de ses pages quand la page
  /// n'en donne pas (l'admin : retour vers l'Accueil, spec section 26 ter).
  /// Nul par defaut : le tuteur n'en pose aucun.
  final VoidCallback? onRetour;

  /// Les actions posees au-dessus de [context], ou une liste vide.
  static List<Widget> de(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ActionsEnteteCoquille>()
          ?.actions ??
      const <Widget>[];

  /// Le retour pose au-dessus de [context], ou nul.
  static VoidCallback? retourDe(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ActionsEnteteCoquille>()
      ?.onRetour;

  @override
  bool updateShouldNotify(ActionsEnteteCoquille ancien) =>
      !listEquals(actions, ancien.actions) || onRetour != ancien.onRetour;
}

/// La bascule entre la tete fixe (`Column(tete, Expanded(corps))`) et le
/// defilement global (`SingleChildScrollView(Column(tete, corps))`).
///
/// AD-RC M4 : la tete et le corps changent de parent a chaque bascule
/// (rotation, redimensionnement, texte a 200 %). Sans cle, leur etat local
/// (saisie, focus, position d'une liste) etait recree. Chacun porte donc une
/// `GlobalKey` tenue par ce `State` : Flutter deplace le sous-arbre au lieu de
/// le reconstruire. Une seule branche est rendue a la fois, chaque cle n'est
/// donc jamais a deux endroits de l'arbre.
class _Bascule extends StatefulWidget {
  const _Bascule({
    required this.teteDefilante,
    required this.tete,
    required this.corps,
    required this.defilante,
  });

  /// Vrai quand, pour la hauteur disponible, la tete doit defiler avec le
  /// corps.
  final bool Function(double hauteur) teteDefilante;
  final List<Widget> tete;
  final Widget corps;
  final bool defilante;

  @override
  State<_Bascule> createState() => _BasculeState();
}

class _BasculeState extends State<_Bascule> {
  final GlobalKey _cleTete = GlobalKey(debugLabel: 'PageShell.tete');
  final GlobalKey _cleCorps = GlobalKey(debugLabel: 'PageShell.corps');

  /// Ce que les `ColonneCorps` du corps signalent leur manquer
  /// (PAGESHELL-200-1b).
  final _ManqueCorps _manque = _ManqueCorps();

  /// AD-M4-DEFIL : le defileur d'une page defilante, recree a chaque bascule
  /// avec la position de l'ancien. Le meme decalage garde le meme contenu
  /// sous la tete dans les deux branches : en tete fixe, le haut du corps
  /// visible est a l'offset du corps ; en defilement global, le corps est
  /// pose sous la tete et defile du meme offset.
  ScrollController? _defileur;

  /// La branche du dernier rendu : nul avant le premier.
  bool? _teteDefilait;

  ScrollController _defileurPour(bool teteDefile) {
    final ScrollController? ancien = _defileur;
    if (ancien != null && _teteDefilait == teteDefile) {
      return ancien;
    }
    final double offset = ancien != null && ancien.hasClients
        ? ancien.offset
        : ancien?.initialScrollOffset ?? 0;
    _teteDefilait = teteDefile;
    if (ancien != null) {
      // L'ancien defileur reste attache jusqu'a la fin de cette image.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        ancien.dispose();
      });
    }
    return _defileur = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _defileur?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La tete garde sa mise en page d'avant : une colonne etiree de hauteur
    // minimale rend ses enfants comme s'ils etaient ceux de la colonne
    // exterieure.
    final Widget tete = KeyedSubtree(
      key: _cleTete,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.tete,
      ),
    );
    final Widget corps = KeyedSubtree(
      key: _cleCorps,
      child: _PorteeManque(manque: _manque, child: widget.corps),
    );

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final bool teteDefile = widget.teteDefilante(contraintes.maxHeight);
        final ScrollController? defileur = widget.defilante
            ? _defileurPour(teteDefile)
            : null;
        return teteDefile
            ? SingleChildScrollView(
                // Un corps non defilant (liste paresseuse) garde le defileur
                // principal de la page dans les deux branches : sur mobile,
                // sa liste reste attachee au meme controleur et garde sa
                // position.
                controller: defileur,
                primary: widget.defilante ? null : false,
                child: widget.defilante
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[tete, corps],
                      )
                    // PAGESHELL-200-1 : le corps non defilant recoit la
                    // hauteur reellement disponible sous la tete, pas toute
                    // celle de la vue. Sinon il depassait de la hauteur de
                    // la tete et son bas (la barre de la salle d'observation
                    // a 200 % sur telephone) passait sous la zone sure au
                    // premier affichage.
                    : _TeteEtCorps(
                        hauteurVue: contraintes.maxHeight,
                        manque: _manque,
                        children: <Widget>[tete, corps],
                      ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  tete,
                  Expanded(
                    child: widget.defilante
                        ? SingleChildScrollView(
                            controller: defileur,
                            child: corps,
                          )
                        : corps,
                  ),
                ],
              );
      },
    );
  }
}

/// La tete puis le corps non defilant, en defilement global
/// (PAGESHELL-200-1, PAGESHELL-200-1b).
///
/// Le corps recoit `max(minimum utile, vue - tete)` :
///
/// - **vue - tete** : au premier affichage, la page tient dans la vue et le
///   bas du corps (une barre de commandes, une zone de saisie) reste dans la
///   zone sure ;
/// - quand la tete laisse moins de la moitie de la vue (zoom a 400 % sur une
///   vue tres basse, AD-11), un corps aussi ecrase serait inutilisable : il
///   recoit alors toute la hauteur de la vue, la tete defile, puis le corps
///   occupe l'ecran ;
/// - **le minimum utile** : ce que les [ColonneCorps] du corps signalent leur
///   manquer. Une salle dont le bandeau et la barre agrandis ne tiennent pas
///   dans `vue - tete` (telephone en paysage a 200 % sous les barres du
///   systeme, 320x568 a 200 %) recoit la hauteur qui lui manque : la page
///   defile d'autant, la barre se rejoint au lieu de deborder hors d'atteinte.
///
/// La hauteur de la tete n'est connue qu'a sa mise en page, et le manque du
/// corps qu'a la sienne : un `Column` ne sait faire ni l'un ni l'autre dans
/// une hauteur non bornee, d'ou ce rendu a deux enfants.
class _TeteEtCorps extends MultiChildRenderObjectWidget {
  const _TeteEtCorps({
    required this.hauteurVue,
    required this.manque,
    required super.children,
  }) : assert(children.length == 2, 'une tete et un corps');

  /// La hauteur de la vue qui defile.
  final double hauteurVue;

  /// Ce que les colonnes du corps signalent leur manquer.
  final _ManqueCorps manque;

  @override
  _RenduTeteEtCorps createRenderObject(BuildContext context) =>
      _RenduTeteEtCorps(hauteurVue, manque);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduTeteEtCorps renderObject,
  ) {
    renderObject
      ..hauteurVue = hauteurVue
      ..manque = manque;
  }
}

class _ParentDataTeteEtCorps extends ContainerBoxParentData<RenderBox> {}

class _RenduTeteEtCorps extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentDataTeteEtCorps>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentDataTeteEtCorps> {
  _RenduTeteEtCorps(this._hauteurVue, this._manque);

  /// Au plus ce nombre de mises en page du corps par passe : une colonne
  /// signale son manque, une colonne imbriquee le sien a la passe suivante.
  static const int _passesMax = 4;

  double _hauteurVue;
  set hauteurVue(double valeur) {
    if (valeur == _hauteurVue) {
      return;
    }
    _hauteurVue = valeur;
    markNeedsLayout();
  }

  _ManqueCorps _manque;
  set manque(_ManqueCorps valeur) {
    if (identical(valeur, _manque)) {
      return;
    }
    if (identical(_manque.rendu, this)) {
      _manque.rendu = null;
    }
    _manque = valeur;
    if (attached) {
      _manque.rendu = this;
    }
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _manque.rendu = this;
  }

  @override
  void detach() {
    if (identical(_manque.rendu, this)) {
      _manque.rendu = null;
    }
    super.detach();
  }

  /// La hauteur donnee au corps sous une tete de hauteur [tete], avant ce
  /// que le corps signale lui manquer.
  double _hauteurCorps(double tete) {
    if (!_hauteurVue.isFinite) {
      return 0;
    }
    final double reste = _hauteurVue - tete;
    return reste >= _hauteurVue / 2 ? reste : _hauteurVue;
  }

  RenderBox get _tete => firstChild!;
  RenderBox get _corps => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentDataTeteEtCorps) {
      child.parentData = _ParentDataTeteEtCorps();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _tete.getMinIntrinsicWidth(double.infinity),
    _corps.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _tete.getMaxIntrinsicWidth(double.infinity),
    _corps.getMaxIntrinsicWidth(double.infinity),
  );

  // Les mesures sans mise en page ignorent le manque du corps : il n'est
  // connu qu'en le mettant en page.
  @override
  double computeMinIntrinsicHeight(double width) {
    final double tete = _tete.getMinIntrinsicHeight(width);
    return tete + _hauteurCorps(tete);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double tete = _tete.getMaxIntrinsicHeight(width);
    return tete + _hauteurCorps(tete);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final double tete = _tete
        .getDryLayout(BoxConstraints.tightFor(width: constraints.maxWidth))
        .height;
    return constraints.constrain(
      Size(constraints.maxWidth, tete + _hauteurCorps(tete)),
    );
  }

  @override
  void performLayout() {
    final double largeur = constraints.maxWidth;
    _tete.layout(BoxConstraints.tightFor(width: largeur), parentUsesSize: true);
    final double tete = _tete.size.height;
    final double base = _hauteurCorps(tete);
    double corps = base;
    _manque.enMiseEnPage = true;
    try {
      for (int passe = 1; ; passe++) {
        _corps.layout(BoxConstraints.tight(Size(largeur, corps)));
        final double manque = _manque.valeur;
        if (manque <= _ManqueCorps.tolerance || passe == _passesMax) {
          break;
        }
        corps += manque;
      }
    } finally {
      _manque
        ..enMiseEnPage = false
        ..supplement = corps - base;
    }
    (_tete.parentData! as _ParentDataTeteEtCorps).offset = Offset.zero;
    (_corps.parentData! as _ParentDataTeteEtCorps).offset = Offset(0, tete);
    size = constraints.constrain(Size(largeur, tete + corps));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// Ce que les [ColonneCorps] d'un corps non defilant signalent leur manquer
/// (PAGESHELL-200-1b). Un par `PageShell`.
class _ManqueCorps {
  /// En deca, un ecart est un arrondi, pas un debordement.
  static const double tolerance = 0.5;

  /// L'ecart de chaque colonne entre son besoin et sa hauteur : positif, il
  /// lui manque de la hauteur ; negatif, elle en a de trop.
  final Map<RenderObject, double> _ecarts = <RenderObject, double>{};

  /// Le rendu de la tete et du corps en defilement global, quand il est
  /// monte. Nul en tete fixe : le manque n'y est pas pris en compte.
  _RenduTeteEtCorps? rendu;

  /// Vrai pendant que [rendu] met le corps en page : il lit le manque juste
  /// apres, rien a relancer.
  bool enMiseEnPage = false;

  /// Ce que [rendu] a donne au corps en plus de `vue - tete` a sa derniere
  /// mise en page.
  double supplement = 0;

  /// Le plus grand manque signale : la hauteur a ajouter au corps.
  double get valeur => _ecarts.values.fold<double>(0, math.max);

  /// Enregistre l'[ecart] de [source] entre son besoin et sa hauteur.
  ///
  /// Une colonne remise en page seule (son bandeau change de hauteur sans
  /// que la page bouge) ne peut pas redemander la mise en page de la page
  /// pendant la sienne : la page est relancee a la fin de l'image, quand il
  /// manque de la hauteur ou qu'un supplement donne n'est peut-etre plus
  /// utile. Rend vrai quand cette relance doit combler un manque.
  bool signaler(RenderObject source, double ecart) {
    final double ancien = _ecarts[source] ?? 0;
    _ecarts[source] = ecart;
    if (enMiseEnPage ||
        (ecart - ancien).abs() <= tolerance ||
        (ecart <= tolerance && supplement <= tolerance)) {
      return false;
    }
    return _relancer() && ecart > tolerance;
  }

  /// [source] quitte l'arbre : son manque ne compte plus.
  void oublier(RenderObject source) {
    final double? ancien = _ecarts.remove(source);
    if (ancien != null && !enMiseEnPage && supplement > tolerance) {
      _relancer();
    }
  }

  /// Redemande la mise en page de [rendu] a la fin de l'image. Faux s'il
  /// n'est pas monte.
  bool _relancer() {
    final _RenduTeteEtCorps? cible = rendu;
    if (cible == null || !cible.attached) {
      return false;
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (cible.attached) {
        cible.markNeedsLayout();
      }
    });
    return true;
  }
}

/// Donne aux [ColonneCorps] du corps le [_ManqueCorps] de leur `PageShell`.
class _PorteeManque extends InheritedWidget {
  const _PorteeManque({required this.manque, required super.child});

  final _ManqueCorps manque;

  @override
  bool updateShouldNotify(_PorteeManque ancien) =>
      !identical(manque, ancien.manque);
}

/// Une colonne de corps non defilant qui dit a `PageShell` la hauteur qui
/// lui manque (PAGESHELL-200-1b).
///
/// Ses enfants sans flex gardent leur hauteur naturelle (un bandeau, une
/// barre de commandes) ; ses enfants flexibles se partagent le reste, sans
/// descendre ensemble sous [minimumEtire]. Quand la hauteur recue n'y suffit
/// pas, la colonne signale a la page ce qui lui manque, et la page, quand sa
/// tete defile avec le corps, donne au corps cette hauteur en plus : la page
/// defile au lieu de couper le bas de la colonne.
///
/// Hors `PageShell`, ou en tete fixe, c'est un `Column` ordinaire.
class ColonneCorps extends Column {
  /// Cree la colonne.
  const ColonneCorps({
    required super.children,
    super.key,
    super.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.minimumEtire = 0,
  });

  /// La hauteur sous laquelle les enfants flexibles, ensemble, ne sont plus
  /// utiles.
  final double minimumEtire;

  @override
  RenderFlex createRenderObject(BuildContext context) => _RenduColonneCorps(
    context.dependOnInheritedWidgetOfExactType<_PorteeManque>()?.manque,
    minimumEtire,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: getEffectiveTextDirection(context),
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
    clipBehavior: clipBehavior,
    spacing: spacing,
  );

  @override
  void updateRenderObject(BuildContext context, RenderFlex renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenduColonneCorps)
      ..manque = context
          .dependOnInheritedWidgetOfExactType<_PorteeManque>()
          ?.manque
      ..minimumEtire = minimumEtire;
  }
}

class _RenduColonneCorps extends RenderFlex {
  _RenduColonneCorps(
    this._manque,
    this._minimumEtire, {
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.clipBehavior,
    super.spacing,
  }) : super(direction: Axis.vertical);

  _ManqueCorps? _manque;
  set manque(_ManqueCorps? valeur) {
    if (identical(valeur, _manque)) {
      return;
    }
    _manque?.oublier(this);
    _manque = valeur;
    markNeedsLayout();
  }

  double _minimumEtire;
  set minimumEtire(double valeur) {
    if (valeur == _minimumEtire) {
      return;
    }
    _minimumEtire = valeur;
    markNeedsLayout();
  }

  /// Vrai quand la page est relancee a la fin de cette image pour combler
  /// le manque : la colonne ne le signale pas comme un debordement.
  bool _relancePrevue = false;

  @override
  void performLayout() {
    super.performLayout();
    final _ManqueCorps? manque = _manque;
    if (manque == null) {
      return;
    }
    double besoin = 0;
    bool flexible = false;
    int enfants = 0;
    for (RenderBox? enfant = firstChild; enfant != null;) {
      final FlexParentData donnees = enfant.parentData! as FlexParentData;
      if ((donnees.flex ?? 0) > 0) {
        flexible = true;
      } else {
        besoin += enfant.size.height;
      }
      enfants++;
      enfant = donnees.nextSibling;
    }
    if (flexible) {
      besoin += _minimumEtire;
    }
    if (enfants > 1) {
      besoin += spacing * (enfants - 1);
    }
    _relancePrevue = manque.signaler(this, besoin - size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_relancePrevue) {
      defaultPaint(context, offset);
      return;
    }
    super.paint(context, offset);
  }

  @override
  void detach() {
    _manque?.oublier(this);
    super.detach();
  }
}

/// La colonne de contenu : gouttiere du gabarit, largeur bornee, centree.
class _Colonne extends StatelessWidget {
  const _Colonne({required this.gouttiere, required this.child});

  final double gouttiere;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurMaxContenu),
        child: Padding(
          // Directionnel : en arabe, la gouttiere de debut est a droite.
          padding: EdgeInsetsDirectional.symmetric(horizontal: gouttiere),
          child: child,
        ),
      ),
    );
  }
}

/// La zone d'action collee en bas de la page.
class _ZoneAction extends StatelessWidget {
  const _ZoneAction({required this.gouttiere, required this.child});

  final double gouttiere;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(top: palette.borderHairline.asBorderSide()),
        // Une barre collee flotte au dessus du contenu : niveau 2.
        boxShadow: AppElevation.niveau2(palette.ombre),
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppPage.largeurMaxContenu,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gouttiere,
              AppSpacing.lg,
              gouttiere,
              AppSpacing.lg,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
