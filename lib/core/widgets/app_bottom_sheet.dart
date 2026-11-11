import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../accessibilite/effacement_barre_basse.dart';
import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/app_transitions.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'entete_page.dart' show DisqueRetour;
import 'pressable.dart';

/// La forme d'une surface modale, selon le gabarit.
enum FormeModale {
  /// Telephone : la feuille de bas d'ecran, pleine largeur, au pouce.
  feuille,

  /// Tablette : la meme feuille, bornee a [AppPage.largeurDialogue] et
  /// centree. Jamais une feuille de telephone etiree sur 800 points.
  feuilleBornee,

  /// Bureau : une boite de dialogue centree, meme contenu, meme largeur
  /// bornee, sans poignee de glissement (il n'y a pas de doigt).
  dialogue,
}

/// La feuille de bas d'ecran du produit.
///
/// **Seul point d'entree d'une surface modale.** Sur telephone, une feuille se
/// prend au pouce ; sur tablette, la meme feuille est bornee en largeur ; sur
/// bureau, elle devient une boite de dialogue centree (contrat K5 du chantier
/// Tuteur V1 : pas de feuille mobile etiree). Le contenu, les actions et leur
/// ordre ne changent pas d'une forme a l'autre : seul le gabarit decide
/// ([formePour]).
///
/// DEFIL-FEUILLE (03/11/2026, `DECISION-DEFILEMENT-2026-11-01.md`, regles 1
/// a 3) : le titre et le corps defilent ensemble, dans la seule barre de
/// defilement de la surface. Un contenu qui tient dans l'ecran donne une
/// surface a sa hauteur, comme avant. Un contenu qui ne tient pas fait prendre
/// a la surface toute la hauteur que lui laisse la route (feuille plein ecran
/// au telephone, pleine hauteur bornee en largeur a la tablette, boite pleine
/// hauteur de la fenetre au bureau, marges du gabarit) : elle **est** alors
/// l'ecran, et rien ne defile dans un cadre pose au milieu. Seule une barre
/// fine reste en haut : la poignee, et la croix « Fermer » quand elle existe.
/// La zone [actions], deja collee au pied, y reste.
///
/// Le motif de mouvement est celui de `docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md`
/// section 3 : 280 ms a l'ouverture, 200 ms a la fermeture, voile a 0,32
/// d'opacite, et **la feuille suit le doigt pendant le glissement**. Elle ne se
/// referme que si la vitesse ou la distance depasse le seuil : une feuille qui
/// se referme sur un effleurement est une feuille qu'on n'ose plus toucher.
class AppBottomSheet extends StatefulWidget {
  /// Cree le contenu d'une feuille.
  ///
  /// Rendu directement plutot que par [ouvrir] dans la galerie : c'est le seul
  /// moyen de montrer ses etats sans ouvrir une vraie modale.
  const AppBottomSheet({
    required this.titre,
    required this.child,
    super.key,
    this.actions,
    this.forme = FormeModale.feuille,
    this.libelleFermer,
  });

  /// Le titre de la feuille, en une phrase.
  final String titre;

  /// Le corps de la feuille.
  final Widget child;

  /// La zone d'action, collee en bas de la feuille.
  final Widget? actions;

  /// ADM-UX (03/11/2026, UX-014, WCAG 2.1.2) : quand il est donne, une croix
  /// « Fermer » se pose a cote du titre (la meme que la surface de lecture) ;
  /// elle ferme comme Echap, par `Navigator.maybePop`. Nul : rien ne change.
  final String? libelleFermer;

  /// La forme rendue. [ouvrir] la choisit d'apres le gabarit ; la galerie la
  /// fixe pour montrer les trois.
  final FormeModale forme;

  /// La forme qui convient a un gabarit.
  static FormeModale formePour(Gabarit gabarit) => switch (gabarit) {
    Gabarit.mobile => FormeModale.feuille,
    Gabarit.tablette => FormeModale.feuilleBornee,
    Gabarit.desktop => FormeModale.dialogue,
  };

  /// Largeur de la poignee de glissement.
  static const double largeurPoignee = AppSpacing.section;

  /// Hauteur de la poignee de glissement.
  static const double hauteurPoignee = AppSpacing.xs;

  /// La cle de la croix « Fermer » (tests).
  static const ValueKey<String> cleFermer = ValueKey<String>('feuille-fermer');

  /// Ouvre une feuille modale et rend ce que sa fermeture renvoie.
  ///
  /// `Echap` la ferme, comme le veut la regle du clavier
  /// (`05-regles-responsive.md` section 5). C'est bien le comportement par
  /// defaut d'une route modale -- `ModalRoute` associe `DismissIntent` a
  /// `Navigator.maybePop()` (framework, `widgets/routes.dart`) -- mais il a
  /// fallu le lot de remise au vert pour que ce soit vrai ici, et la cause
  /// merite d'etre ecrite parce qu'elle ne se devine pas.
  ///
  /// **La feuille se depopait sans jamais se retirer de l'ecran.** Cette
  /// methode fournissait son propre `transitionAnimationController`. Or
  /// `ModalBottomSheetRoute` pose alors `willDisposeAnimationController =
  /// false` : le controleur appartient a l'appelant. Et l'appelant, ici, le
  /// detruisait par `.whenComplete(animation.dispose)`, c'est-a-dire quand la
  /// future de la feuille se complete -- **au pop, pas au retrait**. Le
  /// controleur mourait donc au milieu de l'animation de sortie, la route
  /// n'atteignait jamais l'etat qui la fait retirer de l'overlay, et la
  /// feuille restait affichee sur une route deja depopee. `Echap` faisait
  /// exactement ce qu'il fallait, et rien ne bougeait.
  ///
  /// Le remede supprime le controleur au lieu d'en ajouter : `AnimationStyle`
  /// porte aussi bien les durees que les courbes, et `showModalBottomSheet`
  /// construit alors le controleur lui-meme -- et le detruit lui-meme, au bon
  /// moment. **Ne jamais repasser de `transitionAnimationController` ici** :
  /// ce serait reprendre la propriete du controleur, donc le bug.
  ///
  /// **Sur bureau, une boite de dialogue** (voir [FormeModale]) : meme titre,
  /// meme corps, memes actions dans le meme ordre, fermee par `Echap`, par le
  /// voile ou par ses actions, et rendant la meme valeur. Sur tablette, la
  /// feuille est bornee a [AppPage.largeurDialogue].
  ///
  /// Le voile est `palette.voile` (noir a 32 % en clair, 56 % en sombre) : il
  /// derivait de `surfaceInverse`, qui est **clair** dans le theme sombre et
  /// voilait donc l'ecran de blanc (defaut releve par l'audit C02 et la phase
  /// 0b du chantier Tuteur V1).
  static Future<T?> ouvrir<T>(
    BuildContext context, {
    required String titre,
    required Widget Function(BuildContext context) constructeur,
    Widget Function(BuildContext context)? actions,
    String? libelleFermer,
  }) {
    final AppPalette palette = AppPalette.of(context);
    // WEB-BUREAU (B9, P2 ; M3 bottom sheets : « Use bottom sheets in compact
    // and medium », « at expanded … swapped for a side sheet ») : a partir de
    // la classe etendue (840), jamais de feuille du bas ; la boite bornee a
    // 560 (`largeurDialogue`), comme sur ordinateur.
    final ClasseLargeur classe = AppGabarit.classe(
      MediaQuery.sizeOf(context).width,
    );
    final FormeModale forme =
        classe == ClasseLargeur.etendue || classe == ClasseLargeur.large
        ? FormeModale.dialogue
        : formePour(AppGabarit.de(context));

    if (forme == FormeModale.dialogue) {
      return showDialog<T>(
        context: context,
        barrierColor: palette.voile,
        animationStyle: const AnimationStyle(
          curve: AppMouvement.entree,
          duration: AppMouvement.feuilleOuverture,
          reverseCurve: AppMouvement.sortie,
          reverseDuration: AppMouvement.feuilleFermeture,
        ),
        // TRANSITIONS : une fenetre au-dessus, zoom leger et fondu.
        builder: (BuildContext contexte) => AppTransitions.zoomDeFenetre(
          contexte,
          _CadreDialogue(
            child: AppBottomSheet(
              titre: titre,
              forme: FormeModale.dialogue,
              actions: actions?.call(contexte),
              libelleFermer: libelleFermer,
              child: constructeur(contexte),
            ),
          ),
        ),
      );
    }

    // BANDE-BARRE : sous la barre flottante de `NavShell`, la feuille monte
    // depuis le bord de l'ecran ; la barre s'efface le temps qu'elle reste
    // ouverte.
    final VoidCallback? rendreBarre = EffacementBarreBasse.de(context)
        ?.effacerPourUneFeuille();
    final Future<T?> resultat = showModalBottomSheet<T>(
      context: context,
      // La feuille peut depasser la moitie de l'ecran : une confirmation
      // destructive qui explique sa consequence prend la place qu'il faut.
      isScrollControlled: true,
      useSafeArea: true,
      // Les durees et les courbes du budget de mouvement, jamais celles de
      // Material : 280 ms a l'ouverture, 200 ms a la fermeture -- la sortie
      // plus courte que l'entree d'environ un tiers -- et ce qui entre
      // s'installe doucement quand ce qui sort part plus vite
      // (`04-systeme-mouvement.md` section 2).
      sheetAnimationStyle: const AnimationStyle(
        curve: AppMouvement.entree,
        duration: AppMouvement.feuilleOuverture,
        reverseCurve: AppMouvement.sortie,
        reverseDuration: AppMouvement.feuilleFermeture,
      ),
      backgroundColor: palette.surfaceRaised.background,
      // Le voile du theme, sombre dans les deux themes (voir plus haut).
      barrierColor: palette.voile,
      // Tablette : la feuille garde sa forme mais ne s'etire plus.
      constraints: forme == FormeModale.feuilleBornee
          ? const BoxConstraints(maxWidth: AppPage.largeurDialogue)
          : null,
      // L'ombre et le filet viennent d'AppElevation, sur la surface elle-meme
      // (voir `build`) : le `Material` de la feuille ne fait que clipper les
      // coins.
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.arrondiFeuille,
      ),
      // Le clavier : une route modale n'evite pas les `viewInsets` d'elle-meme.
      // Sans ce retrait, a 390 le clavier recouvrait le champ et les actions
      // d'une feuille de saisie (HL-A-4) ; le corps defile, titre et actions
      // restent au-dessus du clavier.
      builder: (BuildContext contexte) => Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.viewInsetsOf(contexte).bottom,
        ),
        child: _GardeGlissement(
          child: AppBottomSheet(
            titre: titre,
            forme: forme,
            actions: actions?.call(contexte),
            libelleFermer: libelleFermer,
            child: constructeur(contexte),
          ),
        ),
      ),
    );
    if (rendreBarre == null) return resultat;
    return resultat.whenComplete(rendreBarre);
  }

  /// Ouvre une surface de LECTURE modale (visionneuse de piece, AD-7).
  ///
  /// Sous [AppGabarit.seuilEtendu] (classes compacte et moyenne), c'est un
  /// plein ecran : disque retour au debut, titre, sous-titre, corps extensible,
  /// pied. A partir de 840, une boite de dialogue bornee a
  /// [AppPage.largeurLecture], tenue a 32 des bords. Le voile ne ferme pas
  /// (`barrierDismissible: false`) ; `Echap` et le retour systeme passent par
  /// `Navigator.maybePop`. Durees gelees 180 / 120, nulles en reduction de
  /// mouvement. [ouvrir] reste inchange.
  static Future<T?> ouvrirLecture<T>(
    BuildContext context, {
    required String titre,
    required String libelleFermer,
    required Widget Function(BuildContext context) constructeur,
    String? sousTitre,
    Widget Function(BuildContext context)? actions,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final bool pleinEcran =
        MediaQuery.sizeOf(context).width < AppGabarit.seuilEtendu;
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: palette.voile,
      useSafeArea: false,
      animationStyle: AnimationStyle(
        curve: AppMouvement.entree,
        duration: AppMouvement.duree(context, AppMouvement.feuilleOuverture),
        reverseCurve: AppMouvement.sortie,
        reverseDuration: AppMouvement.duree(
          context,
          AppMouvement.feuilleFermeture,
        ),
      ),
      builder: (BuildContext contexte) {
        final Widget surface = _SurfaceLecture(
          titre: titre,
          sousTitre: sousTitre,
          libelleFermer: libelleFermer,
          pleinEcran: pleinEcran,
          actions: actions?.call(contexte),
          child: constructeur(contexte),
        );
        if (pleinEcran) {
          return Material(type: MaterialType.transparency, child: surface);
        }
        return AppTransitions.zoomDeFenetre(
          contexte,
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppPage.largeurLecture,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: surface,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetEtat();
}

class _AppBottomSheetEtat extends State<AppBottomSheet> {
  /// m15 (AD-NETTOYAGE) : le corps garde son etat (saisie, focus) quand la
  /// feuille bascule entre le corps defilant seul et la feuille entiere
  /// defilante (rotation, texte a 200 %). Sans cle, le corps changeait de
  /// parent et son etat partait.
  final GlobalKey _cleCorps = GlobalKey();

  /// Le defilement unique de la surface (titre et corps).
  final ScrollController _defilement = ScrollController();

  /// Vrai quand le contenu ne tient pas : la croix « Fermer » quitte alors le
  /// titre (qui defile) pour la barre fine du haut, toujours visible.
  bool _deborde = false;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  /// Relit le debordement apres la mise en page. Le passage est a sens
  /// unique : une fois que le contenu a deborde, la croix reste dans la barre
  /// fine jusqu'a la fermeture. Sans cela, un titre long pouvait osciller :
  /// sorti du titre, la croix lui rend de la largeur, il tient sur moins de
  /// lignes, le contenu tient de nouveau, la croix y revient, et ainsi de
  /// suite.
  void _mesurer() {
    if (_deborde || !mounted || !_defilement.hasClients) return;
    final ScrollPosition position = _defilement.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent > 0) {
      setState(() => _deborde = true);
      // DEFIL-FEUILLE-bis : au bureau, la boite qui deborde devient la
      // fenetre entiere (voir `_CadreDialogue`).
      _CadreDebordement.signaler(context);
    }
  }

  void _mesurerApres() {
    // La croix change de place quand le contenu deborde ; au bureau, la boite
    // entiere change de forme (DEFIL-FEUILLE-bis) : la mesure vaut aussi sans
    // croix.
    if (_deborde ||
        (widget.libelleFermer == null &&
            widget.forme != FormeModale.dialogue)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _mesurer());
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool dialogue = widget.forme == FormeModale.dialogue;
    final Widget corps = KeyedSubtree(key: _cleCorps, child: widget.child);
    // Meme seuil que la tete defilante de PageShell.
    final bool basse = MediaQuery.sizeOf(context).height < 360;
    // La boite de dialogue prend la surface des superpositions (plus claire
    // que la carte en sombre) et arrondit ses quatre coins : elle n'est
    // ancree a aucun bord.
    final AppColorPair surface = dialogue
        ? palette.surfaceOverlay
        : palette.surfaceRaised;
    // DEFIL-FEUILLE-bis : la boite devenue la fenetre n'a plus de voile ou
    // cliquer pour fermer ; elle porte toujours la croix « Fermer ».
    final bool pleineFenetre = dialogue && _deborde && !basse;
    final Widget? croix = _croix(context, palette, parDefaut: pleineFenetre);
    final bool croixEnBarre = croix != null && _deborde && !basse;
    final Widget titre = _titre(surface, textes);
    final Widget tete = croix == null || croixEnBarre
        ? titre
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: titre),
              Ecart.hMd,
              croix,
            ],
          );
    _mesurerApres();

    // DEFIL-FEUILLE-bis (03/11/2026, DECISION-DEFILEMENT regle 1) : au bureau,
    // une boite trop haute ne defile plus au milieu de l'ecran. Elle devient
    // la fenetre entiere, comme la feuille du telephone : une seule barre de
    // defilement, au bord de la fenetre ; le titre defile avec le corps, dans
    // la largeur de lecture d'une boite ; la barre fine (la croix) reste en
    // haut, les actions au pied, a leur place.
    if (pleineFenetre) {
      return _pleineFenetre(surface, croix, tete, corps);
    }

    return DecoratedBox(
      // Un filet ET une ombre, composes en une fois : une feuille est une
      // surface elevee, et une surface elevee ne porte jamais l'un sans
      // l'autre (`01-systeme-visuel.md` section 2). Niveau 3 pour les deux
      // formes : c'est le niveau de « ce qui recouvre » (`app_elevation.dart`).
      decoration: AppElevation.avecFilet(
        surface: surface,
        filet: palette.borderHairline,
        ombre: palette.ombre,
        arrondi: dialogue ? AppRadius.arrondiLg : AppRadius.arrondiFeuille,
        ombres: AppElevation.niveau3(palette.ombre),
      ),
      child: Padding(
        padding: EdgeInsets.all(dialogue ? AppSpacing.xxl : metriques.marge),
        child: _defilerSiBasse(
          basse,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // La poignee dit que la feuille se glisse. Elle est decorative :
              // le glissement double toujours un bouton ou la touche Echap,
              // aucun geste n'est le seul chemin (`06-accessibilite.md` section 2).
              // Une boite de dialogue ne se glisse pas : pas de poignee.
              // La barre fine du haut : la poignee, et la croix quand le
              // contenu deborde (elle ne cache aucune ligne : le corps
              // commence dessous).
              if (!dialogue || croixEnBarre) ...<Widget>[
                _barreFine(palette, dialogue, croixEnBarre ? croix : null),
                Ecart.vLg,
              ],
              if (basse) ...<Widget>[tete, Ecart.vLg, corps] else
                Flexible(
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (ScrollMetricsNotification _) {
                      _mesurerApres();
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _defilement,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[tete, Ecart.vLg, corps],
                      ),
                    ),
                  ),
                ),
              if (widget.actions != null) ...<Widget>[
                Ecart.vXxl,
                widget.actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// La boite devenue la fenetre (DEFIL-FEUILLE-bis).
  Widget _pleineFenetre(
    AppColorPair surface,
    Widget? croix,
    Widget tete,
    Widget corps,
  ) {
    Widget colonne(Widget enfant) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
        child: enfant,
      ),
    );
    return ColoredBox(
      color: surface.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (croix != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: croix,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _defilement,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              child: colonne(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[tete, Ecart.vLg, corps],
                ),
              ),
            ),
          ),
          if (widget.actions != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: colonne(widget.actions!),
            ),
        ],
      ),
    );
  }

  Widget _titre(AppColorPair surface, TextTheme textes) => Semantics(
    header: true,
    child: TexteSansCoupure(
      widget.titre,
      style: surface.applyTo(textes.headlineSmall ?? const TextStyle()),
    ),
  );

  Widget? _croix(
    BuildContext context,
    AppPalette palette, {
    bool parDefaut = false,
  }) {
    final String? libelle =
        widget.libelleFermer ?? (parDefaut ? t.commun.fermer : null);
    if (libelle == null) return null;
    return Tooltip(
      message: libelle,
      excludeFromSemantics: true,
      child: Pressable(
        key: AppBottomSheet.cleFermer,
        onPress: () => unawaited(Navigator.of(context).maybePop()),
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiFull,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: AppTouchTarget.standard,
            child: Center(
              child: IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
                child: Icon(AppIcons.effacer.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// La barre fine du haut : la poignee (feuille) et, quand le contenu
  /// deborde, la croix « Fermer » a la fin.
  Widget _barreFine(AppPalette palette, bool dialogue, Widget? croix) {
    final Widget? poignee = dialogue
        ? null
        : ExcludeSemantics(
            child: SizedBox(
              width: AppBottomSheet.largeurPoignee,
              height: AppBottomSheet.hauteurPoignee,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.borderResting.asBorderSide().color,
                  borderRadius: AppRadius.arrondiFull,
                ),
              ),
            ),
          );
    if (croix == null) return Center(child: poignee);
    return SizedBox(
      height: AppTouchTarget.standard,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ?poignee,
          Align(alignment: AlignmentDirectional.centerEnd, child: croix),
        ],
      ),
    );
  }

  /// AD-11 (1.4.10) : sur une vue tres basse (1280x1024 a 400 %, 256 de
  /// haut), titre et actions fixes ne laissent plus de place au corps et la
  /// feuille debordait ; toute la feuille defile alors d'un bloc.
  static Widget _defilerSiBasse(bool basse, Widget colonne) =>
      basse ? SingleChildScrollView(child: colonne) : colonne;
}

/// Retient le glissement d'une feuille qu'une `PopScope` interdit de fermer.
///
/// Le glissement de `BottomSheet` ferme par `Navigator.pop`, qui ignore
/// `PopScope` : une feuille de saisie (motif de refus, AD-8) se refermait sur
/// un glisser et le texte partait sans la question d'abandon (HL-A-4). Quand
/// la route refuse de se fermer ([RoutePopDisposition.doNotPop]), ce
/// recognizer gagne l'arene avant celui de la feuille et un glisser vers le
/// bas passe par `Navigator.maybePop` -- le meme chemin qu'`Echap` -- ce qui
/// laisse la `PopScope` poser sa question. Sinon il ne participe pas et la
/// feuille suit le doigt comme avant.
class _GardeGlissement extends StatelessWidget {
  const _GardeGlissement({required this.child});

  final Widget child;

  /// Part de la hauteur a descendre pour fermer (`BottomSheet` : 0,5).
  static const double _seuilDescente = 0.5;

  /// Vitesse (px/s) au-dela de laquelle un geste ferme (`BottomSheet` : 700).
  static const double _vitesseGeste = 700;

  @override
  Widget build(BuildContext context) {
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    double descente = 0;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        _GlissementRetenu:
            GestureRecognizerFactoryWithHandlers<_GlissementRetenu>(
              () => _GlissementRetenu(route),
              (_GlissementRetenu r) => r
                ..route = route
                ..onStart = ((DragStartDetails _) => descente = 0)
                ..onUpdate = ((DragUpdateDetails d) => descente += d.delta.dy)
                ..onEnd = (DragEndDetails d) {
                  // AD-NETTOYAGE-2 (n7) : memes seuils que `BottomSheet` :
                  // une descente d'au moins la moitie de la feuille, ou un
                  // geste rapide. Un simple effleurement ne pose plus la
                  // question d'abandon.
                  final double hauteur = context.size?.height ?? 0;
                  if ((hauteur > 0 && descente >= hauteur * _seuilDescente) ||
                      (d.primaryVelocity ?? 0) > _vitesseGeste) {
                    unawaited(Navigator.of(context).maybePop());
                  }
                },
            ),
      },
      child: child,
    );
  }
}

class _GlissementRetenu extends VerticalDragGestureRecognizer {
  _GlissementRetenu(this.route);

  ModalRoute<Object?>? route;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      route?.popDisposition == RoutePopDisposition.doNotPop &&
      super.isPointerAllowed(event);
}

/// Le cadre de la boite de dialogue de bureau : centree, bornee a
/// [AppPage.largeurDialogue], tenue a distance des bords, jamais plus haute que
/// la fenetre (le corps defile dans [AppBottomSheet]).
class _CadreDialogue extends StatefulWidget {
  const _CadreDialogue({required this.child});

  final Widget child;

  @override
  State<_CadreDialogue> createState() => _CadreDialogueEtat();
}

class _CadreDialogueEtat extends State<_CadreDialogue> {
  /// DEFIL-FEUILLE-bis : vrai quand le contenu de la boite ne tient pas ; la
  /// boite prend alors toute la fenetre. A sens unique, comme la mesure de
  /// la feuille.
  final ValueNotifier<bool> _deborde = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _deborde.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Un `Material` transparent : le texte et les controles du corps
    // trouvent leur ancetre Material sans qu'aucune couleur ni ombre
    // Material ne s'ajoute a celles d'AppElevation.
    final Widget surface = Material(
      type: MaterialType.transparency,
      child: _CadreDebordement(deborde: _deborde, child: widget.child),
    );
    // AD-11 (2.4.11) : le clavier virtuel, comme la feuille (HL-A-4). Sans ce
    // retrait, a 1440x900 les actions de 02D (Annuler, 582 a 634) passaient
    // sous un clavier de 300. Nul sans clavier : rendu inchange.
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _deborde,
        // Le corps garde sa place dans l'arbre quand la forme change : la
        // meme surface, seuls ses bords changent.
        child: surface,
        // La meme suite de widgets dans les deux formes, seules les mesures
        // changent : le corps garde son etat (saisie, message d'erreur) au
        // passage a la fenetre entiere. Changer de parents le reconstruirait.
        builder: (BuildContext _, bool deborde, Widget? enfant) => SafeArea(
          child: Padding(
            padding: deborde
                ? EdgeInsets.zero
                : const EdgeInsets.all(AppSpacing.xxxl),
            child: Center(
              child: ConstrainedBox(
                constraints: deborde
                    ? const BoxConstraints.expand()
                    : const BoxConstraints(maxWidth: AppPage.largeurDialogue),
                child: enfant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le signal « le contenu ne tient pas » de la feuille vers son cadre de
/// bureau (DEFIL-FEUILLE-bis). Hors d'une boite de dialogue, absent : rien
/// ne change.
class _CadreDebordement extends InheritedWidget {
  const _CadreDebordement({required this.deborde, required super.child});

  final ValueNotifier<bool> deborde;

  static void signaler(BuildContext context) {
    final _CadreDebordement? cadre = context
        .getInheritedWidgetOfExactType<_CadreDebordement>();
    cadre?.deborde.value = true;
  }

  @override
  bool updateShouldNotify(_CadreDebordement ancien) =>
      ancien.deborde != deborde;
}

/// La surface de lecture de [AppBottomSheet.ouvrirLecture] : plein ecran
/// (disque retour au debut) ou dialogue borne (croix a la fin). Le corps
/// occupe toute la hauteur restante.
class _SurfaceLecture extends StatelessWidget {
  const _SurfaceLecture({
    required this.titre,
    required this.sousTitre,
    required this.libelleFermer,
    required this.pleinEcran,
    required this.actions,
    required this.child,
  });

  final String titre;
  final String? sousTitre;
  final String libelleFermer;
  final bool pleinEcran;
  final Widget? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair surface = pleinEcran
        ? palette.surfaceRaised
        : palette.surfaceOverlay;
    void fermer() => unawaited(Navigator.of(context).maybePop());

    final Widget entete = Row(
      children: <Widget>[
        if (pleinEcran) ...<Widget>[
          DisqueRetour(onPress: fermer, libelleSemantique: libelleFermer),
          Ecart.hMd,
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: TexteSansCoupure(
                  titre,
                  style: surface.applyTo(
                    textes.headlineSmall ?? const TextStyle(),
                  ),
                ),
              ),
              if (sousTitre != null) ...<Widget>[
                Ecart.vSm,
                Text(
                  sousTitre!,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!pleinEcran) ...<Widget>[
          Ecart.hMd,
          Tooltip(
            message: libelleFermer,
            excludeFromSemantics: true,
            child: Pressable(
              onPress: fermer,
              libelleSemantique: libelleFermer,
              arrondiFocus: AppRadius.arrondiFull,
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: AppTouchTarget.standard,
                  child: Center(
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
                      child: Icon(AppIcons.effacer.repos),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    final Widget colonne = Padding(
      padding: EdgeInsetsDirectional.all(
        pleinEcran ? metriques.marge : AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          entete,
          Ecart.vLg,
          Expanded(child: child),
          if (actions != null) ...<Widget>[Ecart.vLg, actions!],
        ],
      ),
    );

    // Le voile ne ferme pas (`barrierDismissible: false`), ce qui desactive
    // aussi le `DismissIntent` de la route : Echap est donc rebranche ici,
    // sur la meme fermeture que la croix.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              fermer();
              return null;
            },
          ),
        },
        child: pleinEcran
            ? ColoredBox(
                color: surface.background,
                child: SafeArea(child: colonne),
              )
            : _decorer(palette, surface, colonne),
      ),
    );
  }

  Widget _decorer(AppPalette palette, AppColorPair surface, Widget colonne) {
    return DecoratedBox(
      decoration: AppElevation.avecFilet(
        surface: surface,
        filet: palette.borderHairline,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiLg,
        ombres: AppElevation.niveau3(palette.ombre),
      ),
      child: colonne,
    );
  }
}
