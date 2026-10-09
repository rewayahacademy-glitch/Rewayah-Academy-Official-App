import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import '../accessibilite/texte_sans_coupure.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
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

  /// Le titre simple (sans retour, sous-titre ni action), pour les tests et
  /// les captures.
  static const Key titreSimpleKey = ValueKey<String>('page-shell-titre-simple');

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
    //
    // PAGESHELL-200-1e : le bandeau de la coquille (l'alerte urgente de la
    // direction, ALERTE-1b) est pose AU-DESSUS de la page, fige, par la
    // coquille ; la page le sait ([ActionsEnteteCoquille.sousBandeauDe]) et
    // sa tete reste fixe dessous, tant qu'elle laisse au corps au moins la
    // moitie de la place restante (voir [_Bascule]).
    final bool sousBandeau = ActionsEnteteCoquille.sousBandeauDe(context);
    final bool compact = EnteteCompact.actif(context);
    final TextStyle styleTitreSimple =
        textes.headlineLarge ?? const TextStyle();
    final List<Widget> tete = <Widget>[
      if (titre != null) ...<Widget>[
        // 48 au dessus d'un titre d'ecran, c'est le rythme de page
        // (`01-systeme-visuel.md` section 6). En mode enfant, la marge de
        // respiration prend le relais. Un en-tete a actions (cloche, disque
        // retour) porte deja sa cible de 48 : il ne prend que 24.
        // PAGESHELL-200-1e (decide par delegation le 09/10) : sous un
        // bandeau fige, la respiration de l'Interface guidee (64, plus les 8
        // du bandeau : environ 70 de vide) cede le pas au rythme de
        // l'interface standard ; le bandeau tient deja le haut de l'ecran.
        SizedBox(
          height: metriques.estEnfant && !sousBandeau
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
          // PAGESHELL-200-1e : a texte agrandi (ou vue basse), le titre
          // simple suit l'echelle compacte HIER-1 de `EntetePage`
          // ([EnteteCompact.echelleTitre]) : un palier au-dessus d'un titre
          // de section agrandi, jamais sous la taille du theme.
          titreFocalisable(
            focusTitre,
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: compact
                    ? EnteteCompact.echelleTitre(context, styleTitreSimple)
                    : MediaQuery.textScalerOf(context),
              ),
              child: TexteSansCoupure(
                titre!,
                key: PageShell.titreSimpleKey,
                style: styleTitreSimple,
                nomsComposesEntiers: compact,
              ),
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
                // signale lui manquer (`ColonneCorps`, `DefileurCorps`,
                // PAGESHELL-200-1b et 1c) ; une colonne a qui il manque de
                // la hauteur sous une tete fixe fait passer la page en
                // defilement global (PAGESHELL-200-1c).
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
                // PAGESHELL-200-1e : un bandeau fige au-dessus de la page ne
                // fait plus defiler la tete ; la hauteur lue ici est celle
                // qui reste sous lui, et [_Bascule] mesure la tete.
                child: _Bascule(
                  sousBandeau: sousBandeau,
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
    this.sousBandeau = false,
  });

  /// Les actions, dans l'ordre de lecture (la cloche en dernier).
  final List<Widget> actions;

  /// Vrai quand la coquille pose, au-dessus de chacune de ses pages et hors
  /// de leur zone qui defile, un bandeau fige : l'alerte urgente de la
  /// direction (ALERTE-1b). La page ne le rend pas ; elle en tient compte
  /// (PAGESHELL-200-1e) : sa tete reste fixe sous lui tant qu'elle laisse au
  /// corps au moins la moitie de la place restante, et l'Interface guidee
  /// n'y ajoute pas sa respiration de haut d'ecran.
  final bool sousBandeau;

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

  /// Vrai quand un bandeau fige est pose au-dessus de la page de [context].
  static bool sousBandeauDe(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ActionsEnteteCoquille>()
          ?.sousBandeau ??
      false;

  @override
  bool updateShouldNotify(ActionsEnteteCoquille ancien) =>
      !listEquals(actions, ancien.actions) ||
      onRetour != ancien.onRetour ||
      sousBandeau != ancien.sousBandeau;
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
    required this.sousBandeau,
  });

  /// Vrai sous un bandeau fige de la coquille (PAGESHELL-200-1e) : la tete
  /// fixe doit laisser au corps au moins la moitie de la place restante.
  final bool sousBandeau;

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

  /// PAGESHELL-200-1c : la vue (contraintes et echelle du texte) pour
  /// laquelle le corps non defilant a signale, en tete fixe, une hauteur
  /// qui lui manque : une colonne qui deborde (667x375 sans zone sure, a
  /// 200 % : 45 px, 213 en Interface guidee) ou un support qui n'a plus sa
  /// hauteur lisible (667x375 a 100 % en Interface guidee : une fenetre de
  /// 39 px). La page y passe en defilement global : la tete defile et le
  /// corps recoit la hauteur qui lui manque. Une autre vue reessaie la tete
  /// fixe. A vue egale, un corps qui tient de nouveau sous la tete fixe (un
  /// etat de reconnexion qui se referme, la salle remplacee par le resultat
  /// de la visite) en reprend d'abord la geometrie dans la meme image : le
  /// corps recoit `vue - tete` et la page ne defile plus
  /// ([_RenduTeteEtCorps.performLayout]). PAGESHELL-200-1d : la bascule est
  /// ensuite reevaluee ([_revenirTeteFixe]) : la page reprend la tete fixe
  /// a la fin de l'image, une fois les animations en cours terminees.
  (BoxConstraints, double)? _vueForcee;

  /// La vue du dernier rendu.
  (BoxConstraints, double)? _vueCourante;

  /// PAGESHELL-200-1e : la hauteur de la tete a sa derniere mise en page,
  /// nulle avant la premiere. La meme dans les deux branches : la tete y
  /// recoit la meme largeur et une hauteur libre.
  double? _hauteurTete;

  /// La hauteur de la vue du dernier rendu.
  double _hauteurVue = 0;

  /// La decision « tete trop haute pour rester fixe » du dernier rendu.
  bool _teteHauteAuRendu = false;

  /// Vrai quand une reevaluation est deja demandee pour cette image.
  bool _reevaluationDemandee = false;

  /// Le debut du report en cours du retour a la tete fixe
  /// (PAGESHELL-200-1e, reserve 2 de la revue PAGESHELL-200-1d).
  Duration? _debutReport;

  /// PAGESHELL-200-1e : vrai quand la tete, fixe, ne laisserait pas assez de
  /// place au corps dans une vue de [hauteur] ; la tete defile alors avec le
  /// corps.
  ///
  /// - **Sous un bandeau fige** (l'alerte urgente de la direction) : la tete
  ///   reste fixe sous lui tant qu'elle laisse au corps au moins la moitie de
  ///   la place restante (la regle du bandeau lui-meme, borne a la moitie de
  ///   la vue, et celle de `_hauteurCorps`). Au-dela (Interface guidee a
  ///   390x844 sur le Journal, vue basse), elle defile, le bandeau non.
  /// - **Ailleurs** : la tete reste fixe tant qu'elle laisse au corps au
  ///   moins une cible tactile ; avant, une tete plus haute que la vue
  ///   debordait (Journal en Interface guidee a 390x684 : 22 de
  ///   debordement en bas).
  ///
  /// Decide par delegation le 09/10.
  bool _teteHaute(double hauteur) {
    final double? tete = _hauteurTete;
    if (tete == null || !hauteur.isFinite) {
      return false;
    }
    final double limite = widget.sousBandeau
        ? hauteur / 2
        : hauteur - AppTouchTarget.standard;
    return tete > limite + _ManqueCorps.tolerance;
  }

  /// La tete vient d'etre mise en page a [hauteur] : si la decision du
  /// dernier rendu n'est plus la bonne, la bascule est reevaluee a la fin
  /// de l'image (la tete et le corps ne changent pas de parent pendant une
  /// mise en page).
  void _surHauteurTete(double hauteur) {
    _hauteurTete = hauteur;
    if (_reevaluationDemandee || _teteHaute(_hauteurVue) == _teteHauteAuRendu) {
      return;
    }
    _reevaluationDemandee = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _reevaluationDemandee = false;
      if (mounted && _teteHaute(_hauteurVue) != _teteHauteAuRendu) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _manque
      ..surManqueTeteFixe = _forcerDefilement
      ..surTientTeteFixe = _revenirTeteFixe;
  }

  /// PAGESHELL-200-1d : a vue egale, le corps force tient de nouveau sous la
  /// tete fixe (fin d'une reconnexion, ligne d'etat retiree) : la page
  /// reprend la tete fixe. Tant qu'une animation tourne (une boite de
  /// dialogue qui se referme, une transition de page), la bascule attend la
  /// fin de l'image suivante : deplacer la tete et le corps (cles globales)
  /// pendant la fermeture d'une boite de dialogue casse l'arbre semantique
  /// de Flutter. D'ici la, la page garde la geometrie de la tete fixe.
  ///
  /// PAGESHELL-200-1e (reserve 2 de la revue PAGESHELL-200-1d) : le report
  /// est borne. Une animation qui tourne sans fin (une pulsation, un
  /// indicateur indetermine) le prolongeait indefiniment ; la bascule se fait
  /// au plus tard [AppMouvement.plafond] apres la premiere demande, le
  /// plafond de toute animation du produit (une boite de dialogue s'est
  /// refermee bien avant).
  void _revenirTeteFixe() {
    if (!mounted || _vueForcee == null || _vueCourante != _vueForcee) {
      _debutReport = null;
      return;
    }
    if (_manque.valeur() > _ManqueCorps.tolerance) {
      // Une source remise en page apres la verification (deplacee avec le
      // corps) dit qu'il lui manque encore de la hauteur.
      _debutReport = null;
      return;
    }
    final SchedulerBinding planificateur = SchedulerBinding.instance;
    if (planificateur.transientCallbackCount > 0) {
      final Duration maintenant = planificateur.currentFrameTimeStamp;
      final Duration debut = _debutReport ??= maintenant;
      if (maintenant - debut < AppMouvement.plafond) {
        // Aucune image demandee ici : les animations en cours en produisent.
        planificateur.addPostFrameCallback((Duration _) => _revenirTeteFixe());
        return;
      }
    }
    _debutReport = null;
    setState(() => _vueForcee = null);
  }

  void _forcerDefilement() {
    final (BoxConstraints, double)? courante = _vueCourante;
    if (!mounted ||
        widget.defilante ||
        courante == null ||
        courante == _vueForcee) {
      return;
    }
    setState(() => _vueForcee = courante);
  }

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
    _manque
      ..surManqueTeteFixe = null
      ..surTientTeteFixe = null;
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
      child: _MesureTete(
        surHauteur: _surHauteurTete,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.tete,
        ),
      ),
    );
    final Widget corps = KeyedSubtree(
      key: _cleCorps,
      child: _PorteeManque(manque: _manque, child: widget.corps),
    );

    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final (BoxConstraints, double) vue = (contraintes, echelle);
        _vueCourante = vue;
        _hauteurVue = contraintes.maxHeight;
        final bool teteHaute = _teteHaute(contraintes.maxHeight);
        _teteHauteAuRendu = teteHaute;
        final bool teteDefilante =
            widget.teteDefilante(contraintes.maxHeight) || teteHaute;
        final bool forcee = !widget.defilante && vue == _vueForcee;
        // Force seulement : une page dont la tete defile de toute facon
        // garde la regle de `_hauteurCorps`.
        _manque.forcee = forcee && !teteDefilante;
        final bool teteDefile = teteDefilante || forcee;
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
            // PAGESHELL-200-1e : la tete, puis le corps dans la hauteur qui
            // reste. Comme `Column(tete, Expanded(corps))`, sans le
            // debordement de l'image ou la tete s'avere trop haute (la
            // bascule passe alors en defilement global a la fin de l'image).
            : _TeteFixe(
                children: <Widget>[
                  tete,
                  if (widget.defilante)
                    SingleChildScrollView(controller: defileur, child: corps)
                  else
                    corps,
                ],
              );
      },
    );
  }
}

/// Mesure la tete de la page et la signale a [_Bascule] (PAGESHELL-200-1e).
class _MesureTete extends SingleChildRenderObjectWidget {
  const _MesureTete({required this.surHauteur, required super.child});

  final ValueChanged<double> surHauteur;

  @override
  _RenduMesureTete createRenderObject(BuildContext context) =>
      _RenduMesureTete(surHauteur);

  @override
  void updateRenderObject(BuildContext context, _RenduMesureTete renderObject) {
    renderObject.surHauteur = surHauteur;
  }
}

class _RenduMesureTete extends RenderProxyBox {
  _RenduMesureTete(this.surHauteur);

  ValueChanged<double> surHauteur;

  @override
  void performLayout() {
    super.performLayout();
    surHauteur(size.height);
  }
}

/// La tete fixe, puis le corps dans la hauteur qui reste (PAGESHELL-200-1e).
///
/// La geometrie de `Column(tete, Expanded(corps))` (tete a sa hauteur
/// naturelle sur toute la largeur, corps dans le reste), sans son
/// avertissement de debordement : quand la tete s'avere plus haute que la
/// place qu'elle doit laisser au corps, [_Bascule] passe en defilement
/// global a la fin de l'image ; d'ici la, ce qui depasse est coupe.
class _TeteFixe extends MultiChildRenderObjectWidget {
  const _TeteFixe({required super.children})
    : assert(children.length == 2, 'une tete et un corps');

  @override
  _RenduTeteFixe createRenderObject(BuildContext context) => _RenduTeteFixe();
}

class _RenduTeteFixe extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentDataTeteEtCorps>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentDataTeteEtCorps> {
  RenderBox get _tete => firstChild!;
  RenderBox get _corps => lastChild!;

  final LayerHandle<ClipRectLayer> _coupe = LayerHandle<ClipRectLayer>();

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

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tete.getMinIntrinsicHeight(width) + _corps.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tete.getMaxIntrinsicHeight(width) + _corps.getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  /// Vrai quand la tete depasse la vue a la derniere mise en page.
  bool _deborde = false;

  @override
  void performLayout() {
    final Size vue = constraints.biggest;
    _tete.layout(
      BoxConstraints.tightFor(width: vue.width),
      parentUsesSize: true,
    );
    final double tete = _tete.size.height;
    _corps.layout(
      BoxConstraints.tight(Size(vue.width, math.max(0, vue.height - tete))),
    );
    _deborde = tete > vue.height;
    (_tete.parentData! as _ParentDataTeteEtCorps).offset = Offset.zero;
    (_corps.parentData! as _ParentDataTeteEtCorps).offset = Offset(
      0,
      math.min(tete, vue.height),
    );
    size = vue;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_deborde) {
      _coupe.layer = null;
      defaultPaint(context, offset);
      return;
    }
    _coupe.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      oldLayer: _coupe.layer,
    );
  }

  @override
  void dispose() {
    _coupe.layer = null;
    super.dispose();
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
///   S'y ajoute ce que ses [DefileurCorps] cachent de leur minimum utile
///   (PAGESHELL-200-1c), que la page defile deja ou non : la salle montre
///   son en-tete et son support a sa hauteur lisible, jamais une fenetre de
///   48 px ou de 13 px, et la page defile pour le reste.
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
  static const int _passesMax = 6;

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
    double base = _hauteurCorps(tete);
    double corps = base;
    _manque.enMiseEnPage = true;
    try {
      // PAGESHELL-200-1c : en defilement global force (la tete fixe ne
      // laissait pas au corps ce qu'il lui faut), le corps est d'abord mis
      // en page a la hauteur que la tete fixe lui donnerait. S'il y tient
      // de nouveau (son contenu a rapetisse), il la garde : tete et corps
      // remplissent la vue, la page ne defile plus, comme sous une tete
      // fixe.
      final double teteFixe = _hauteurVue - tete;
      if (_manque.forcee && teteFixe.isFinite && teteFixe > 0) {
        _corps.layout(BoxConstraints.tight(Size(largeur, teteFixe)));
        if (_manque.valeur() <= _ManqueCorps.tolerance) {
          base = corps = teteFixe;
          _manque.tientTeteFixe();
        }
      }
      for (int passe = 1; ; passe++) {
        _corps.layout(BoxConstraints.tight(Size(largeur, corps)));
        final double manque = _manque.valeur();
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

  /// Appele a la fin de l'image quand il manque de la hauteur au corps en
  /// tete fixe : la page passe en defilement global (PAGESHELL-200-1c).
  VoidCallback? surManqueTeteFixe;

  /// Vrai quand la page est en defilement global parce que le corps
  /// manquait de hauteur sous la tete fixe.
  bool forcee = false;

  /// Vrai quand ce passage est deja demande pour cette image.
  bool _basculeDemandee = false;

  /// Appele a la fin de l'image quand, en defilement global force, le corps
  /// tient de nouveau sous la tete fixe (PAGESHELL-200-1d).
  VoidCallback? surTientTeteFixe;

  /// Vrai quand le retour a la tete fixe est deja demande pour cette image.
  bool _retourDemande = false;

  /// Demande le retour a la tete fixe a la fin de l'image.
  void tientTeteFixe() {
    if (_retourDemande || surTientTeteFixe == null) {
      return;
    }
    _retourDemande = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _retourDemande = false;
      surTientTeteFixe?.call();
    });
  }

  /// Le plus grand manque signale : la hauteur a ajouter au corps.
  double valeur() {
    double plus = 0;
    for (final double ecart in _ecarts.values) {
      plus = math.max(plus, ecart);
    }
    return plus;
  }

  /// Enregistre l'[ecart] de [source] entre son besoin et sa hauteur.
  ///
  /// Une colonne remise en page seule (son bandeau change de hauteur sans
  /// que la page bouge) ne peut pas redemander la mise en page de la page
  /// pendant la sienne : la page est relancee a la fin de l'image, quand il
  /// manque de la hauteur ou qu'un supplement donne n'est peut-etre plus
  /// utile. Rend vrai quand cette relance doit combler un manque.
  ///
  /// En tete fixe, toute source a qui il manque de la hauteur fait passer
  /// la page en defilement global, quelle que soit la taille du texte : une
  /// colonne qui deborde, une zone etiree sous son minimum, un defileur
  /// imbrique qui cache son minimum utile (PAGESHELL-200-1c ; a 100 % en
  /// Interface guidee, 667x375 ne montrait qu'une fenetre de 39 px ou le
  /// support n'etait meme pas construit). La page defile alors pour le
  /// reste, barre comprise.
  bool signaler(RenderObject source, double ecart) {
    final double ancien = _ecarts[source] ?? 0;
    _ecarts[source] = ecart;
    if (rendu == null) {
      return ecart > tolerance && _basculer();
    }
    // En defilement global force, tout changement relance la page : un
    // corps qui rapetisse peut y reprendre la geometrie de la tete fixe.
    if (enMiseEnPage ||
        (ecart - ancien).abs() <= tolerance ||
        (ecart <= tolerance && supplement <= tolerance && !forcee)) {
      return false;
    }
    return _relancer() && ecart > tolerance;
  }

  /// [source] quitte l'arbre : son manque ne compte plus.
  void oublier(RenderObject source) {
    final double? ancien = _ecarts.remove(source);
    if (ancien != null && !enMiseEnPage && (supplement > tolerance || forcee)) {
      _relancer();
    }
  }

  /// Demande le defilement global a la fin de l'image. Faux hors
  /// `PageShell`.
  bool _basculer() {
    final VoidCallback? rappel = surManqueTeteFixe;
    if (rappel == null) {
      return false;
    }
    if (!_basculeDemandee) {
      _basculeDemandee = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _basculeDemandee = false;
        surManqueTeteFixe?.call();
      });
    }
    return true;
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
/// En tete fixe, une colonne a qui il manque de la hauteur (enfants qui
/// debordent, zone etiree sous [minimumEtire]) fait passer la page en
/// defilement global, ou elle recoit ce qui lui manque (PAGESHELL-200-1c).
/// Hors `PageShell`, c'est un `Column` ordinaire.
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
    if (enfants > 1) {
      besoin += spacing * (enfants - 1);
    }
    final double minimum = flexible ? _minimumEtire : 0;
    _relancePrevue = manque.signaler(this, besoin + minimum - size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_relancePrevue) {
      defaultPaint(context, offset);
      return;
    }
    super.paint(context, offset);
  }

  // Deplacee d'une branche a l'autre (tete fixe, defilement global), la
  // source a oublie son manque en quittant l'arbre : elle le redit meme
  // quand ses contraintes n'ont pas change (PAGESHELL-200-1c).
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    markNeedsLayout();
  }

  @override
  void detach() {
    _manque?.oublier(this);
    super.detach();
  }
}

/// Un defileur imbrique dans un corps non defilant, qui dit a `PageShell`
/// ce qu'il cache de son minimum utile (PAGESHELL-200-1c).
///
/// Le minimum utile est tout le contenu du defileur. La page donne au corps
/// la hauteur qu'il faut pour que ce contenu tienne dans le defileur, que la
/// page defile deja ou non (sous une tete fixe, elle passe d'abord en
/// defilement global) : une salle montre son en-tete, son support a hauteur
/// lisible et ses vignettes, et c'est la page qui defile pour le reste. Avant,
/// ce minimum etait une cible tactile : une fenetre de 48 px ou l'on ne
/// voyait que le haut de l'en-tete. PAGESHELL-200-1d : il n'y a plus de
/// repere qui arretait le minimum avant les vignettes ; elles restaient
/// cachees dans le defileur imbrique (142 px a 390x844 a 200 % en Interface
/// guidee), la page defilee jusqu'au bout ne les montrait pas.
///
/// [builder] recoit le controleur a donner au **seul** defileur vertical
/// qu'il construit. Hors `PageShell`, c'est un defileur ordinaire.
class DefileurCorps extends StatefulWidget {
  /// Cree le defileur.
  const DefileurCorps({required this.builder, super.key});

  /// Construit le defileur avec le controleur donne.
  final Widget Function(BuildContext context, ScrollController defileur)
  builder;

  @override
  State<DefileurCorps> createState() => _DefileurCorpsEtat();
}

class _DefileurCorpsEtat extends State<DefileurCorps> {
  final ScrollController _defileur = ScrollController();
  final GlobalKey _cleSignal = GlobalKey(debugLabel: 'DefileurCorps.signal');

  @override
  void dispose() {
    _defileur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        // Le contenu change de hauteur sans que la page bouge (une ligne
        // d'etat apparait) : le defileur se remet en page seul, la mesure
        // est relue a la fin de l'image.
        onNotification: (ScrollMetricsNotification avis) {
          if (avis.depth == 0) {
            (_cleSignal.currentContext?.findRenderObject()
                    as _RenduSignalDefileur?)
                ?.signaler();
          }
          return false;
        },
        child: _SignalDefileur(
          key: _cleSignal,
          manque: context
              .dependOnInheritedWidgetOfExactType<_PorteeManque>()
              ?.manque,
          defileur: _defileur,
          child: widget.builder(context, _defileur),
        ),
      );
}

class _SignalDefileur extends SingleChildRenderObjectWidget {
  const _SignalDefileur({
    required this.manque,
    required this.defileur,
    required super.child,
    super.key,
  });

  final _ManqueCorps? manque;
  final ScrollController defileur;

  @override
  _RenduSignalDefileur createRenderObject(BuildContext context) =>
      _RenduSignalDefileur(manque, defileur);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduSignalDefileur renderObject,
  ) {
    renderObject
      ..manque = manque
      ..defileur = defileur;
  }
}

class _RenduSignalDefileur extends RenderProxyBox {
  _RenduSignalDefileur(this._manque, this.defileur);

  ScrollController defileur;

  _ManqueCorps? _manque;
  set manque(_ManqueCorps? valeur) {
    if (identical(valeur, _manque)) {
      return;
    }
    _manque?.oublier(this);
    _manque = valeur;
    markNeedsLayout();
  }

  /// Ce que le defileur cache de son minimum utile : tout ce qui depasse.
  double get _cache {
    if (!defileur.hasClients || defileur.positions.length != 1) {
      return 0;
    }
    final ScrollPosition position = defileur.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return 0;
    }
    return position.maxScrollExtent - position.minScrollExtent;
  }

  void signaler() {
    if (attached) {
      _manque?.signaler(this, _cache);
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    signaler();
  }

  // Deplacee d'une branche a l'autre (tete fixe, defilement global), la
  // source a oublie son manque en quittant l'arbre : elle le redit meme
  // quand ses contraintes n'ont pas change (PAGESHELL-200-1c).
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    markNeedsLayout();
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
