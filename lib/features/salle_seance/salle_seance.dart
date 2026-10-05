// La salle de seance unique (plan de code section 2).
//
// Un gabarit, parametre par la `VueSeance` du role effectif : plein ecran,
// sans barre d'application (I-8). Dispositions par `Gabarit` : compacte
// (< 600), moyenne (600-1199), large (>= 1200).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/commandes_masquables.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/offline_banner.dart';
import 'actions_seance.dart';
import 'barre_support.dart';
import 'capsule_seance.dart';
import 'chrome_seance.dart';
import 'commandes_pedagogiques.dart';
import 'dock_seance.dart';
import 'panneau_eleves.dart';
import 'panneau_seance.dart';
import 'panneau_supports.dart';
import 'selecteur_ressources.dart';
import 'vue_seance.dart';
import 'zone_support.dart';

/// L'etat local de l'appareil : il ne publie rien vers les autres.
@immutable
class EtatLocalSeance {
  const EtatLocalSeance({
    this.microOuvert = true,
    this.cameraAllumee = true,
    this.zoom = 1,
    this.agrandi = false,
  });

  final bool microOuvert;
  final bool cameraAllumee;

  /// Le zoom local du support (1 = 100 %).
  final double zoom;

  /// Le support occupe l'ecran : l'en-tete se retire (Agrandir).
  final bool agrandi;
}

/// La salle : en-tete, support dominant, vignette, dock et barre basse.
class SalleSeance extends StatelessWidget {
  const SalleSeance({
    required this.vue,
    required this.actions,
    this.local = const EtatLocalSeance(),
    this.contenuSupport,
    this.raccourcisClavier,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// EN-KB (E19) : les raccourcis M, V, R, B de la salle enseignant sur
  /// bureau. `null` : la preference locale de `/compte/reglages` quand un
  /// `ProviderScope` l'entoure, sinon inactifs.
  final bool? raccourcisClavier;

  /// Le rendu reel du support partage (Classe Live :
  /// `ContexteClasseLive.support`). `null` : la salle rend elle-meme
  /// `vue.support` (demonstration).
  final Widget? contenuSupport;

  /// Construit la salle enseignant avec l'etat des raccourcis : la valeur
  /// explicite, sinon la preference locale (suivie), sinon inactifs (salle
  /// montee sans `ProviderScope`, comme dans les tests d'ecran).
  Widget _avecPreferenceRaccourcis(
    BuildContext context,
    Widget Function(bool raccourcis) construire,
  ) {
    final bool? explicite = raccourcisClavier;
    if (explicite != null) return construire(explicite);
    if (context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() ==
        null) {
      return construire(false);
    }
    return Consumer(
      builder: (BuildContext _, WidgetRef ref, Widget? _) => construire(
        ref.watch(
          preferencesLocalesProvider.select(
            (PreferencesLocales p) => p.raccourcisSalle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Gabarit gabarit = AppGabarit.de(context);
    final bool large = gabarit == Gabarit.desktop;
    if (vue.role == RoleSeance.enseignant) {
      // TB-2 : la barre de l'appel est en bas de l'ecran, au-dessus de la
      // feuille ouverte (UX-07) ; c'est elle qui garde la marge du systeme.
      return Material(
        color: palette.surfaceCanvas.background,
        child: SafeArea(
          child: _avecPreferenceRaccourcis(
            context,
            (bool raccourcis) => _FocusPanneaux(
              vue: vue,
              actions: actions,
              local: local,
              gabarit: gabarit,
              contenuSupport: contenuSupport,
              raccourcis: raccourcis,
            ),
          ),
        ),
      );
    }
    // Sans support, rien a agrandir : l'etat local est ignore.
    final bool agrandi = local.agrandi && vue.support != null;
    // Gouttiere : 16 au telephone et en web etroit (images), 32 en desktop.
    final double gouttiere = large
        ? AppPage.gouttiereDesktop
        : AppPage.gouttiereMobile;
    // MA-CMD-1 (directeur, 02/10/2026) : en Mode Accessibilite, telephone et
    // web etroit, l'en-tete tient sur une ligne et les commandes, icones
    // seules, sont posees en bas par-dessus le support, masquables d'une
    // touche (CommandesMasquables) : le support et la video gardent l'ecran.
    if (vue.role == RoleSeance.guidee && !large) {
      return _ContexteEleve(
        vue: vue,
        actions: actions,
        construire: (FocusNode focusCapsule) => Material(
          color: palette.surfaceCanvas.background,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!agrandi)
                  ChromeSeance(
                    vue: vue,
                    actions: actions,
                    compacte: true,
                    focusCapsule: focusCapsule,
                  ),
                BandeauSecours(
                  vue: vue,
                  actions: actions,
                  gouttiere: gouttiere,
                ),
                if (!agrandi) ?_appel(vue, gouttiere),
                Expanded(
                  child: _visioRevelee(
                    vue: vue,
                    contenu: _surContexteEleve(
                      vue: vue,
                      actions: actions,
                      contenu: Padding(
                        padding: EdgeInsets.fromLTRB(
                          gouttiere,
                          AppSpacing.xs,
                          gouttiere,
                          AppSpacing.xs,
                        ),
                        child: ZoneSupport(
                          vue: vue,
                          zoom: local.zoom,
                          contenu: contenuSupport,
                        ),
                      ),
                    ),
                    barre: Padding(
                      padding: EdgeInsets.fromLTRB(
                        gouttiere,
                        0,
                        gouttiere,
                        AppSpacing.sm,
                      ),
                      child: DockSeance(
                        vue: vue,
                        actions: actions,
                        microOuvert: local.microOuvert,
                        cameraAllumee: local.cameraAllumee,
                        agrandi: agrandi,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Plein cadre, sans coquille de page : ni titre d'ecran, ni colonne
    // bornee (CONTENT > CHROME). Le fond reste celui du theme (clair et
    // sombre), comme sur les images, et non le registre inverse.
    return _ContexteEleve(
      vue: vue,
      actions: actions,
      construire: (FocusNode focusCapsule) => Material(
        color: palette.surfaceCanvas.background,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (agrandi) ...<Widget>[
                // Mode agrandi : l'en-tete se retire, l'etat critique reste
                // visible (CL-7 §2.7).
                BandeauSecours(
                  vue: vue,
                  actions: actions,
                  gouttiere: gouttiere,
                ),
                Ecart.vLg,
              ] else if (large) ...<Widget>[
                ChromeSeance(
                  vue: vue,
                  actions: actions,
                  focusCapsule: focusCapsule,
                ),
                BandeauSecours(
                  vue: vue,
                  actions: actions,
                  gouttiere: gouttiere,
                  espaceApres: AppSpacing.lg,
                ),
                ?_appel(vue, gouttiere),
              ] else ...<Widget>[
                TeteSalleBornee(
                  children: <Widget>[
                    ChromeSeance(
                      vue: vue,
                      actions: actions,
                      focusCapsule: focusCapsule,
                    ),
                    BandeauSecours(
                      vue: vue,
                      actions: actions,
                      gouttiere: gouttiere,
                    ),
                    ?_appel(vue, gouttiere),
                  ],
                ),
                Ecart.vLg,
              ],
              // TB-2 (VIS-01) : la barre de l'appel est posee par-dessus, en bas,
              // dans CommandesMasquables ; le support garde sa marge de lecture
              // (hauteur mesuree de la barre), masquee ou non.
              Expanded(
                child: _visioRevelee(
                  vue: vue,
                  contenu: _surContexteEleve(
                    vue: vue,
                    actions: actions,
                    contenu: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: gouttiere,
                            ),
                            child: ZoneSupport(
                              vue: vue,
                              zoom: local.zoom,
                              contenu: contenuSupport,
                            ),
                          ),
                        ),
                        if (large && _BarreBasse.utile(vue))
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: gouttiere,
                              end: gouttiere,
                              top: AppSpacing.xl,
                            ),
                            child: _BarreBasse(
                              vue: vue,
                              actions: actions,
                              local: local,
                            ),
                          ),
                      ],
                    ),
                  ),
                  barre: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: gouttiere,
                      end: gouttiere,
                      top: large ? AppSpacing.xl : AppSpacing.lg,
                      bottom: large ? AppSpacing.xl : AppSpacing.md,
                    ),
                    child: Center(
                      heightFactor: 1,
                      child: DockSeance(
                        vue: vue,
                        actions: actions,
                        microOuvert: local.microOuvert,
                        cameraAllumee: local.cameraAllumee,
                        // Bureau : « Reduire » vit deja dans le zoom local.
                        agrandi:
                            agrandi && !(large && vue.voitZoomLocal(gabarit)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TB-3 (CTX-01, CTX-02), eleve et guidee : Echap reduit le contexte deplie
/// depuis la capsule, et le focus revient a l'avatar de la capsule.
class _ContexteEleve extends StatefulWidget {
  const _ContexteEleve({
    required this.vue,
    required this.actions,
    required this.construire,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final Widget Function(FocusNode focusCapsule) construire;

  @override
  State<_ContexteEleve> createState() => _ContexteEleveState();
}

class _ContexteEleveState extends State<_ContexteEleve> {
  final FocusNode _focusCapsule = FocusNode(debugLabel: 'capsule-avatar');

  @override
  void didUpdateWidget(_ContexteEleve ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.vue.contexteOuvert && !widget.vue.contexteOuvert) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _focusCapsule.context != null) {
          _focusCapsule.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusCapsule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      if (widget.vue.contexteOuvert)
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            widget.actions.onContexte?.call(ContexteOuvert.aucun),
    },
    child: widget.construire(_focusCapsule),
  );
}

/// TB-3, eleve et guidee : le contexte deplie, pose par-dessus la surface
/// dans le cadre de panneau existant ([PanneauSeance]) : feuille du bas au
/// telephone (le haut du support reste visible), volet ailleurs. Il reste
/// au-dessus de la barre de l'appel (la surface garde sa marge de lecture).
Widget _surContexteEleve({
  required VueSeance vue,
  required ActionsSeance actions,
  required Widget contenu,
}) {
  if (!vue.contexteOuvert) return contenu;
  return LayoutBuilder(
    builder: (BuildContext contexte, BoxConstraints c) {
      final Gabarit gabarit = AppGabarit.de(contexte);
      final bool feuille = gabarit == Gabarit.mobile;
      final ValueChanged<ContexteOuvert>? reduire = actions.onContexte;
      // Texte agrandi sur petit ecran : la barre de l'appel, retenue tant
      // que le contexte est ouvert, se pose par-dessus le contenu. La
      // feuille garde sa tete et une rangee au-dessus d'elle, et sa liste
      // defile jusqu'au-dessus de la barre : rien ne reste recouvert.
      final double recouvert = math.min(
        CommandesMasquables.recouvrementDe(contexte),
        c.maxHeight,
      );
      final Widget panneau = Focus(
        autofocus: true,
        skipTraversal: true,
        child: PanneauSeance(
          titre: t.salle.seance.contexte.titre,
          onFermer: reduire == null
              ? null
              : () => reduire(ContexteOuvert.aucun),
          forme: feuille ? FormePanneau.feuille : FormePanneau.volet,
          enfant: ListView(
            key: const ValueKey<String>('panneau-contexte'),
            padding: EdgeInsets.only(bottom: AppSpacing.md + recouvert),
            children: <Widget>[SectionContexte(vue: vue, actions: actions)],
          ),
        ),
      );
      return Stack(
        children: <Widget>[
          Positioned.fill(child: contenu),
          if (feuille)
            Positioned.fill(
              top: supportVisiblePour(contexte, c.maxHeight - recouvert),
              child: panneau,
            )
          else
            PositionedDirectional(
              start: AppSpacing.sm,
              top: 0,
              bottom: AppSpacing.sm,
              width: math.min(
                largeurPanneauSeance,
                c.maxWidth - 2 * AppSpacing.sm,
              ),
              child: panneau,
            ),
        ],
      );
    },
  );
}

/// Le clavier des panneaux Eleves, Supports et Commandes : Echap ferme le
/// panneau ouvert ; a la fermeture (croix, « Reduire », menu ou Echap), le
/// focus revient au bouton qui l'avait ouvert.
class _FocusPanneaux extends StatefulWidget {
  const _FocusPanneaux({
    required this.vue,
    required this.actions,
    required this.local,
    required this.gabarit,
    this.contenuSupport,
    this.raccourcis = false,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final Gabarit gabarit;
  final Widget? contenuSupport;

  /// EN-KB : les raccourcis M, V, R, B sont permis (preference locale).
  final bool raccourcis;

  @override
  State<_FocusPanneaux> createState() => _FocusPanneauxState();
}

class _FocusPanneauxState extends State<_FocusPanneaux> {
  final FocusNode _focusEleves = FocusNode(debugLabel: 'bouton-eleves');

  /// TB-4 : le declencheur « Commandes ». La Bibliotheque s'ouvre depuis les
  /// Commandes : sa fermeture y rend aussi le focus.
  final FocusNode _focusCommandes = FocusNode(
    debugLabel: 'declencheur-commandes',
  );

  /// TB-3 : l'avatar de la capsule, ou revient le focus quand le contexte
  /// se reduit (« Reduire », croix ou Echap).
  final FocusNode _focusCapsule = FocusNode(debugLabel: 'capsule-avatar');
  // Hors de l'ordre Tab : la zone n'est pas interactive (UX_REVIEW_04 n. 17 f) ;
  // `requestFocus` y pose toujours le focus.
  final FocusNode _focusSupport = FocusNode(
    debugLabel: 'support',
    skipTraversal: true,
  );

  /// EN-12 (micro), decision du directeur du 27/09 : l'etat du micro obtenu
  /// (« Micro ouvert » ou « Micro coupe »), montre brievement et lu par le
  /// lecteur d'ecran, que le geste vienne du dock ou de la touche M.
  String? _retourMicro;

  @override
  void didUpdateWidget(_FocusPanneaux ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.local.microOuvert != widget.local.microOuvert) {
      _retourMicro = widget.local.microOuvert
          ? t.salle.microOuvert
          : t.salle.microCoupe;
      // Lu une seule fois : le bandeau visible est exclu des semantiques.
      _annoncer(_retourMicro!);
    }
    if (ancien.vue.contexteOuvert && !widget.vue.contexteOuvert) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _focusCapsule.context != null) {
          _focusCapsule.requestFocus();
        }
      });
      return;
    }
    final PanneauOuvert avant = ancien.vue.panneau;
    if (avant == PanneauOuvert.aucun ||
        widget.vue.panneau != PanneauOuvert.aucun) {
      return;
    }
    // Une ressource choisie (EN-10) : le focus va au nouveau support, pas
    // au bouton Supports (UX_REVIEW_04 n° 17 f).
    // Le signal est la ressource choisie quand on la connait, sinon l'objet.
    final String? avantId = ancien.vue.support?.ressourceId;
    final String? apresId = widget.vue.support?.ressourceId;
    final bool supportChange =
        widget.vue.support != null &&
        (avantId != null && apresId != null
            ? avantId != apresId
            : !identical(ancien.vue.support, widget.vue.support));
    final FocusNode bouton = supportChange
        ? _focusSupport
        : avant == PanneauOuvert.eleves
        ? _focusEleves
        : _focusCommandes;
    // Le bouton est remonte au cadre suivant (telephone, web etroit).
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && bouton.context != null) bouton.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusEleves.dispose();
    _focusCommandes.dispose();
    _focusSupport.dispose();
    _focusCapsule.dispose();
    super.dispose();
  }

  void _fermer() {
    // TB-3 : le contexte deplie est le panneau le plus recent ; Echap le
    // reduit, la capsule revient.
    if (widget.vue.contexteOuvert) {
      widget.actions.onContexte?.call(ContexteOuvert.aucun);
      return;
    }
    switch (widget.vue.panneau) {
      case PanneauOuvert.eleves:
        widget.actions.onEleves?.call();
      case PanneauOuvert.supports:
        widget.actions.onSupports?.call();
      case PanneauOuvert.ressources:
        widget.actions.onBibliotheque?.call();
      case PanneauOuvert.commandes:
        widget.actions.onCommandes?.call();
      case PanneauOuvert.aucun:
        break;
    }
  }

  /// Vrai quand un champ de texte tient le focus : aucune lettre n'est
  /// alors un raccourci (E19, jamais pendant une saisie).
  static bool _saisieEnCours() {
    final BuildContext? focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null) return false;
    return focus.widget is EditableText ||
        focus.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Le raccourci peut-il agir maintenant ? Salle enseignant sur bureau,
  /// preference active, hors saisie, et le bouton correspondant existe.
  bool _permis(RaccourciSalle raccourci) {
    final VueSeance vue = widget.vue;
    final ActionsSeance actions = widget.actions;
    if (!widget.raccourcis ||
        widget.gabarit != Gabarit.desktop ||
        vue.role != RoleSeance.enseignant ||
        _saisieEnCours()) {
      return false;
    }
    final PanneauOuvert panneau = vue.panneau;
    return switch (raccourci) {
      // Micro bloque : le bouton ouvre une feuille ; la lettre ne fait rien.
      RaccourciSalle.micro =>
        actions.onMicro != null &&
            vue.commandesPublicationActives &&
            !vue.microBloque,
      // E19 : V ne fait que couper la camera, jamais l'allumer.
      RaccourciSalle.camera =>
        actions.onCamera != null &&
            vue.commandesPublicationActives &&
            widget.local.cameraAllumee,
      // Sur bureau, le panneau Eleves est deja la quand rien d'autre n'est
      // ouvert : R le ramene depuis Supports ou le selecteur.
      RaccourciSalle.eleves =>
        vue.voitBoutonsPanneaux &&
            actions.onEleves != null &&
            (panneau == PanneauOuvert.supports ||
                panneau == PanneauOuvert.ressources ||
                panneau == PanneauOuvert.commandes),
      RaccourciSalle.bibliotheque =>
        vue.voitBoutonsPanneaux &&
            actions.onBibliotheque != null &&
            panneau != PanneauOuvert.ressources,
    };
  }

  void _executer(RaccourciSalle raccourci) {
    final ActionsSeance actions = widget.actions;
    switch (raccourci) {
      case RaccourciSalle.micro:
        // L'annonce de l'etat obtenu (ouvert ou coupe) suit le changement
        // d'etat du micro (`didUpdateWidget`), comme pour le dock.
        actions.onMicro?.call();
      case RaccourciSalle.camera:
        actions.onCamera?.call();
        _annoncer(t.salle.cameraCoupee);
      case RaccourciSalle.eleves:
        actions.onEleves?.call();
      case RaccourciSalle.bibliotheque:
        actions.onBibliotheque?.call();
    }
  }

  /// La hauteur du retour du micro : au-dessus du dock et de ses libelles,
  /// et, hors bureau, au-dessus du declencheur « Commandes » pose sur le
  /// dock.
  double _hauteurRetourMicro(BuildContext context) {
    final double dessusDock =
        diametreBoutonAppel(context) + AppSpacing.respiration;
    return widget.gabarit == Gabarit.desktop
        ? dessusDock
        : dessusDock + AppSpacing.respiration + AppSpacing.lg;
  }

  /// La barre de l'appel de l'enseignant : pilule centree sur bureau,
  /// panneau sur toute la largeur ailleurs.
  Widget _barreEnseignant(VueSeance vue) {
    const double gouttiere = AppPage.gouttiereMobile;
    final Widget dock = DockSeance(
      vue: vue,
      actions: widget.actions,
      microOuvert: widget.local.microOuvert,
      cameraAllumee: widget.local.cameraAllumee,
      // TB-4 : en focus, « Reduire » reste dans la barre (TB18), en plus de
      // « Quitter le focus » des Commandes.
      agrandi: _agrandi,
    );
    if (widget.gabarit == Gabarit.desktop) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          gouttiere,
          AppSpacing.md,
          gouttiere,
          AppSpacing.lg,
        ),
        child: Center(heightFactor: 1, child: dock),
      );
    }
    final double ecartDock = widget.gabarit == Gabarit.mobile
        ? AppSpacing.sm
        : AppSpacing.md;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        gouttiere,
        ecartDock,
        gouttiere,
        ecartDock,
      ),
      child: dock,
    );
  }

  void _annoncer(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// TB-4 : le focus local de l'enseignant (Commandes > Focus), etat local
  /// existant ; sans support, rien a agrandir.
  bool get _agrandi => widget.local.agrandi && widget.vue.support != null;

  @override
  Widget build(BuildContext context) {
    // EN-9 : sur bureau, le panneau Eleves est ouvert d'office (a droite du
    // support), jamais derriere le bouton « Eleves ». TB-4 : le focus local
    // replie ce panneau pose d'office (plan V2 §18.3).
    // TB-3 (CTX-01, CTX-02) : le contexte deplie depuis la capsule s'ouvre
    // dans le panneau de personnes existant (Eleves), a tous les gabarits.
    final VueSeance base =
        widget.vue.contexteOuvert && widget.vue.voitBoutonsPanneaux
        ? widget.vue.copyWith(panneau: PanneauOuvert.eleves)
        : widget.vue;
    final VueSeance vue =
        widget.gabarit == Gabarit.desktop &&
            !_agrandi &&
            base.voitBoutonsPanneaux &&
            base.panneau == PanneauOuvert.aucun
        ? base.copyWith(panneau: PanneauOuvert.eleves)
        : base;
    final bool ouvert =
        widget.vue.voitBoutonsPanneaux &&
        (widget.vue.panneau != PanneauOuvert.aucun ||
            widget.vue.contexteOuvert);
    // EN-KB (E19) : les lettres sont posees sur le sous-arbre de la salle,
    // jamais globales ; l'action refuse (et laisse passer la touche) hors
    // bureau, preference coupee, ou pendant une saisie.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyM): IntentRaccourciSalle(
          RaccourciSalle.micro,
        ),
        SingleActivator(LogicalKeyboardKey.keyV): IntentRaccourciSalle(
          RaccourciSalle.camera,
        ),
        SingleActivator(LogicalKeyboardKey.keyR): IntentRaccourciSalle(
          RaccourciSalle.eleves,
        ),
        SingleActivator(LogicalKeyboardKey.keyB): IntentRaccourciSalle(
          RaccourciSalle.bibliotheque,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          IntentRaccourciSalle: _ActionRaccourciSalle(
            permis: _permis,
            executer: _executer,
          ),
        },
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            if (ouvert)
              const SingleActivator(LogicalKeyboardKey.escape): _fermer,
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                // TB-2 (VIS-01) : la barre de l'appel par-dessus la salle, au-
                // dessus des panneaux et de la feuille (UX-07). Maintenue
                // quand un panneau est ouvert par l'enseignant (pas le
                // panneau Eleves pose d'office sur bureau, EN-9).
                child: _visioRevelee(
                  vue: widget.vue,
                  contenu: _SalleEnseignant(
                    vue: vue,
                    actions: widget.actions,
                    local: widget.local,
                    gabarit: widget.gabarit,
                    contenuSupport: widget.contenuSupport,
                    focusEleves: _focusEleves,
                    focusCommandes: _focusCommandes,
                    focusSupport: _focusSupport,
                    focusCapsule: _focusCapsule,
                    agrandi: _agrandi,
                  ),
                  barre: _barreEnseignant(vue),
                ),
              ),
              // Le retour du micro : discret, au-dessus du dock, sans
              // fenetre ni geste ; il ne retient aucun toucher.
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: _hauteurRetourMicro(context),
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    // Centre et a la largeur du texte : une etiquette
                    // breve, pas un bandeau d'une rive a l'autre.
                    child: Center(
                      child: IntrinsicWidth(
                        child: LocalFeedback(
                          key: const ValueKey<String>('retour-micro'),
                          message: _retourMicro,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les raccourcis clavier de la salle enseignant (E19, EN-KB).
enum RaccourciSalle {
  /// M : bascule le micro.
  micro,

  /// V : coupe la camera, ne l'allume jamais.
  camera,

  /// R : le panneau Eleves (roster).
  eleves,

  /// B : le selecteur de ressources (bibliotheque, EN-10).
  bibliotheque,
}

/// L'intention d'un raccourci de la salle.
class IntentRaccourciSalle extends Intent {
  const IntentRaccourciSalle(this.raccourci);

  final RaccourciSalle raccourci;
}

/// L'action des raccourcis : desactivee, elle laisse la touche au reste de
/// l'application (un champ de texte la recoit alors normalement).
class _ActionRaccourciSalle extends Action<IntentRaccourciSalle> {
  _ActionRaccourciSalle({required this.permis, required this.executer});

  final bool Function(RaccourciSalle raccourci) permis;
  final void Function(RaccourciSalle raccourci) executer;

  @override
  bool isEnabled(IntentRaccourciSalle intent) => permis(intent.raccourci);

  @override
  Object? invoke(IntentRaccourciSalle intent) {
    executer(intent.raccourci);
    return null;
  }
}

/// La salle de l'enseignant (CLV-06) : support dominant, bouton Eleves,
/// declencheur « Commandes » (TB-4) ; la barre de l'appel Micro, Camera,
/// Quitter est posee par-dessus (TB-2). Plus d'outils permanents ni de
/// pagination sous le support : ils vivent dans les Commandes (plan V2 §4.2,
/// UX_REVIEW_TB n. 10, n. 11).
class _SalleEnseignant extends StatelessWidget {
  const _SalleEnseignant({
    required this.vue,
    required this.actions,
    required this.local,
    required this.gabarit,
    required this.focusEleves,
    required this.focusCommandes,
    required this.focusSupport,
    this.focusCapsule,
    this.contenuSupport,
    this.agrandi = false,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final Gabarit gabarit;
  final Widget? contenuSupport;

  /// TB-4 : le focus local (Commandes > Focus) replie le bouton Eleves et
  /// le panneau pose d'office ; capsule, Commandes et barre restent.
  final bool agrandi;

  /// TB-3 : le noeud de l'avatar de la capsule (retour du focus).
  final FocusNode? focusCapsule;

  /// Les noeuds du bouton Eleves et du declencheur Commandes (retour du
  /// focus).
  final FocusNode focusEleves;
  final FocusNode focusCommandes;

  /// Le noeud du support : il recoit le focus apres le choix d'une ressource.
  final FocusNode focusSupport;

  @override
  Widget build(BuildContext context) {
    const double gouttiere = AppPage.gouttiereMobile;
    // Telephone et desktop : le support partage la hauteur avec les boutons,
    // il se resserre pour montrer la diapositive entiere.
    final Widget support = Focus(
      focusNode: focusSupport,
      child: ZoneSupport(
        vue: vue,
        zoom: local.zoom,
        serre: true,
        contenu: contenuSupport,
      ),
    );
    final Widget? boutons = agrandi
        ? null
        : _BoutonsPanneaux.ou(vue, actions, gabarit, focusEleves: focusEleves);
    final Widget? declencheur = _declencheur();
    final Widget? panneau = _panneau();
    if (panneau != null) {
      return gabarit == Gabarit.desktop
          ? _desktopAvecPanneau(
              panneau: panneau,
              support: support,
              declencheur: declencheur,
            )
          : _etroitAvecPanneau(panneau: panneau, support: support);
    }
    switch (gabarit) {
      case Gabarit.desktop:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChromeSeance(
              vue: vue,
              actions: actions,
              focusCapsule: focusCapsule,
            ),
            BandeauSecours(
              vue: vue,
              actions: actions,
              espaceApres: AppSpacing.md,
            ),
            if (boutons != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  gouttiere,
                  0,
                  gouttiere,
                  AppSpacing.md,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: boutons,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: _sousSupport(support, declencheur),
              ),
            ),
          ],
        );
      case Gabarit.tablette:
      case Gabarit.mobile:
        final bool mobile = gabarit == Gabarit.mobile;
        // Telephone : les ecarts entre les rangees se resserrent d'un
        // palier, la place revient au support (image mobile, enseignant).
        final Widget ecart = mobile ? Ecart.vSm : Ecart.vMd;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TeteSalleBornee(
              children: <Widget>[
                ChromeSeance(
                  vue: vue,
                  actions: actions,
                  focusCapsule: focusCapsule,
                ),
                BandeauSecours(vue: vue, actions: actions),
              ],
            ),
            ecart,
            if (boutons != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: boutons,
              ),
              ecart,
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: support,
              ),
            ),
            // TB-4 : le declencheur, pres du bas, au-dessus de la zone de la
            // barre de l'appel (posee par-dessus, TB-2) ; centre au
            // telephone (planche 1), au bord de fin sur tablette (§4.2).
            if (declencheur != null) ...<Widget>[
              ecart,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: Align(
                  alignment: mobile
                      ? Alignment.center
                      : AlignmentDirectional.centerEnd,
                  child: declencheur,
                ),
              ),
            ],
          ],
        );
    }
  }

  /// TB-4 : le declencheur « Commandes », rendu seulement si une entree du
  /// panneau a un rappel (UX_REVIEW_TB §3 bis).
  Widget? _declencheur() {
    final VoidCallback? basculer = actions.onCommandes;
    if (basculer == null || !CommandesPedagogiques.aDesEntrees(vue, actions)) {
      return null;
    }
    return DeclencheurCommandes(
      onPress: basculer,
      ouvert: vue.panneau == PanneauOuvert.commandes,
      focusNode: focusCommandes,
    );
  }

  /// Le panneau ouvert, ou `null`. Enseignant seulement : ce widget n'est
  /// construit que pour `RoleSeance.enseignant`, et la vue le confirme.
  Widget? _panneau() {
    if (!vue.voitBoutonsPanneaux) return null;
    final FormePanneau forme = FormePanneau.pour(gabarit);
    final Widget? panneau = switch (vue.panneau) {
      PanneauOuvert.aucun => null,
      PanneauOuvert.eleves => PanneauSeance(
        // Sur bureau, le bouton « Eleves 1/3 » s'efface devant le panneau
        // ouvert (K-42, style 3) : le compteur passe dans son en-tete.
        titre: forme == FormePanneau.colonne
            ? vue.compteurEleves ?? t.salle.seance.eleves
            : t.salle.seance.eleves,
        // EN-9 : sur bureau, le panneau Eleves reste ouvert a droite du
        // support ; il ne se ferme pas. TB-3 : ouvert par la capsule, la
        // croix reduit le contexte (la capsule revient).
        onFermer: forme == FormePanneau.colonne
            ? null
            : vue.contexteOuvert
            ? () => actions.onContexte?.call(ContexteOuvert.aucun)
            : actions.onEleves,
        forme: forme,
        enMenu: forme != FormePanneau.colonne,
        ajusteAuContenu: true,
        enfant: PanneauEleves(
          eleves: vue.eleves,
          actions: actions,
          // Sur bureau, le panneau droit montre toujours « File de
          // recitation » (maquettes enseignant, EN-9) ; ailleurs, file au
          // repos : pas de bloc, le panneau reste celui de CLV-07.
          recitation:
              forme == FormePanneau.colonne ||
                  vue.recitation.enCours ||
                  vue.recitation.suivants.isNotEmpty
              ? vue.recitation
              : null,
          large: forme == FormePanneau.colonne,
          serre: forme == FormePanneau.feuille,
          entete: vue.contexteOuvert
              ? SectionContexte(vue: vue, actions: actions)
              : null,
        ),
      ),
      PanneauOuvert.supports => PanneauSeance(
        titre: t.salle.seance.supports,
        onFermer: actions.onSupports,
        forme: forme,
        enfant: PanneauSupports(
          supports: vue.supports,
          actions: actions,
          forme: forme,
        ),
      ),
      // EN-10 : le selecteur de ressources (04 §19), ouvert par « Voir toute
      // la bibliotheque » ; feuille sur mobile, panneau sur bureau. La salle
      // reste ouverte.
      PanneauOuvert.ressources => PanneauSeance(
        titre: t.salle.seance.supports,
        onFermer: actions.onBibliotheque,
        forme: forme,
        enfant: SelecteurRessources(supports: vue.supports, actions: actions),
      ),
      // TB-4 (CMD-01) : « Commandes », ferme par « Reduire » (plan V2 §20).
      PanneauOuvert.commandes => PanneauSeance(
        titre: t.salle.seance.commandes.titre,
        onFermer: actions.onCommandes,
        libelleFermer: t.salle.seance.commandes.reduire,
        semantiqueFermer: t.salle.seance.commandes.reduireSemantique,
        forme: forme,
        enfant: CommandesPedagogiques(
          vue: vue,
          actions: actions,
          zoom: local.zoom,
          agrandi: agrandi,
        ),
      ),
    };
    if (panneau == null) return null;
    // A l'ouverture, le focus entre dans le panneau (si rien d'autre ne le
    // tient) : Echap le ferme alors depuis le clavier.
    return Focus(autofocus: true, skipTraversal: true, child: panneau);
  }

  /// Desktop, panneau ouvert. Supports (CLV-08) : panneau a gauche, support
  /// au centre, bouton Eleves a droite. Eleves (EN-9) et Commandes (TB-4) :
  /// support a gauche, panneau a droite (« bord droit », plan V2 §4.2).
  Widget _desktopAvecPanneau({
    required Widget panneau,
    required Widget support,
    required Widget? declencheur,
  }) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool supports = vue.panneau == PanneauOuvert.supports;
    final Widget? boutons = agrandi
        ? null
        : _BoutonsPanneaux.ou(
            vue,
            actions,
            gabarit,
            etire: true,
            serre: true,
            enColonne: supports,
            focusEleves: focusEleves,
          );
    final Widget centre = _sousSupport(support, declencheur);
    if (supports) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChromeSeance(vue: vue, actions: actions, focusCapsule: focusCapsule),
          BandeauSecours(vue: vue, actions: actions),
          Ecart.vSm,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: gouttiere),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(width: largeurColonneSupportsSeance, child: panneau),
                  Ecart.hMd,
                  Expanded(child: centre),
                  if (boutons != null) ...<Widget>[
                    Ecart.hMd,
                    SizedBox(
                      width: largeurColonneDroiteSeance,
                      child: Column(children: <Widget>[boutons]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChromeSeance(vue: vue, actions: actions, focusCapsule: focusCapsule),
        BandeauSecours(vue: vue, actions: actions),
        Ecart.vSm,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: centre),
                Ecart.hMd,
                SizedBox(
                  width: largeurColonneSeance,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (boutons != null) ...<Widget>[boutons, Ecart.vMd],
                      Expanded(child: panneau),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bureau : le declencheur « Commandes » sous le support, au bord de fin
  /// (plan V2 §4.2 : « bord droit de la surface ») ; la barre de l'appel est
  /// posee par-dessus, plus bas (TB-2).
  Widget _sousSupport(Widget support, Widget? declencheur) {
    if (declencheur == null) return support;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: support),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: declencheur,
          ),
        ),
      ],
    );
  }

  /// Web etroit et telephone, panneau ouvert : le panneau recouvre le
  /// support (volet, ou feuille du bas qui laisse voir le haut du support et
  /// la vignette). Les boutons et le declencheur se retirent : le panneau
  /// les remplace (images CLV-07-08-10). TB-4 : le volet des Commandes est
  /// au bord de fin (« panneau droit », plan V2 §6), les autres au debut.
  Widget _etroitAvecPanneau({
    required Widget panneau,
    required Widget support,
  }) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool mobile = gabarit == Gabarit.mobile;
    final bool aLaFin = vue.panneau == PanneauOuvert.commandes;
    // TB-2 : le dock est dans la barre de l'appel, sous le panneau.
    final Widget dessous = Padding(
      padding: const EdgeInsets.symmetric(horizontal: gouttiere),
      child: support,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TeteSalleBornee(
          children: <Widget>[
            ChromeSeance(
              vue: vue,
              actions: actions,
              focusCapsule: focusCapsule,
            ),
            BandeauSecours(vue: vue, actions: actions),
          ],
        ),
        mobile ? Ecart.vSm : Ecart.vMd,
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints c) {
              // Volet : au plus la moitie de la largeur, moins un palier, pour
              // laisser au dock toute sa place a droite (image : ≈ 313).
              final double largeurVolet = math.min(
                largeurPanneauSeance,
                c.maxWidth / 2 - AppSpacing.lg,
              );
              return Stack(
                children: <Widget>[
                  Positioned.fill(child: dessous),
                  if (mobile)
                    Positioned.fill(
                      // COUPE-MOTS-1 : sous un en-tete haut (titre a 200 %),
                      // le support visible cede sa place a la feuille.
                      // TB-2 : la feuille s'arrete au-dessus de la barre de
                      // l'appel (UX-07) ; elle garde sa hauteur d'avant, le
                      // support visible au-dessus cede la hauteur de la barre.
                      top: math.max(
                        0,
                        supportVisiblePour(
                              contexte,
                              c.maxHeight +
                                  CommandesMasquables.margeDe(contexte),
                            ) -
                            CommandesMasquables.margeDe(contexte),
                      ),
                      child: panneau,
                    )
                  else
                    // Le volet descend jusqu'au bas de l'ecran (image).
                    PositionedDirectional(
                      start: aLaFin ? null : AppSpacing.sm,
                      end: aLaFin ? AppSpacing.sm : null,
                      top: 0,
                      bottom: 0,
                      width: largeurVolet,
                      child: panneau,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// « Eleves 1/3 › » : enseignant seulement. Desktop : a droite au-dessus du
/// support ; ailleurs, sur toute la largeur au-dessus du support. La
/// Bibliotheque est dans les Commandes (TB-4).
class _BoutonsPanneaux extends StatelessWidget {
  const _BoutonsPanneaux({
    required this.compteur,
    required this.onEleves,
    required this.etire,
    this.panneau = PanneauOuvert.aucun,
    this.focusEleves,
    this.serre = false,
    this.enColonne = false,
  });

  static Widget? ou(
    VueSeance vue,
    ActionsSeance actions,
    Gabarit gabarit, {
    bool? etire,
    bool serre = false,
    bool enColonne = false,
    FocusNode? focusEleves,
  }) {
    final String? compteur = vue.compteurEleves;
    if (!vue.voitBoutonsPanneaux || compteur == null) return null;
    final VoidCallback? eleves = actions.onEleves;
    if (eleves == null) return null;
    // Bureau, panneau Eleves ouvert : il dit deja l'etat et le compteur (son
    // en-tete), le bouton ne le repete pas (K-42, style 3). R et Echap
    // restent.
    if (gabarit == Gabarit.desktop && vue.panneau == PanneauOuvert.eleves) {
      return null;
    }
    return _BoutonsPanneaux(
      compteur: compteur,
      onEleves: eleves,
      etire: etire ?? gabarit != Gabarit.desktop,
      panneau: vue.panneau,
      focusEleves: focusEleves,
      serre: serre,
      enColonne: enColonne,
    );
  }

  /// Le panneau ouvert : son bouton se dit selectionne.
  final PanneauOuvert panneau;
  final FocusNode? focusEleves;

  final String compteur;
  final VoidCallback onEleves;
  final bool etire;

  /// Desktop, panneau ouvert : colonne droite etroite (CLV-07).
  final bool serre;

  /// Desktop, panneau Supports : pleine largeur de la colonne (CLV-08).
  final bool enColonne;

  @override
  Widget build(BuildContext context) {
    final Widget bouton = BoutonPanneau(
      key: const ValueKey<String>('bouton-eleves'),
      icone: AppIcons.eleves,
      libelle: compteur,
      onPress: onEleves,
      ouvert: panneau == PanneauOuvert.eleves,
      focusNode: focusEleves,
      etire: etire,
      serre: serre,
    );
    if (enColonne) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[bouton],
      );
    }
    return Row(
      mainAxisSize: etire ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[if (etire) Expanded(child: bouton) else bouton],
    );
  }
}

/// Un bouton compact de la salle : icone, libelle, chevron ›.
class BoutonPanneau extends StatelessWidget {
  const BoutonPanneau({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.ouvert = false,
    this.focusNode,
    this.etire = false,
    this.serre = false,
    this.libelleSemantique,
    super.key,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback onPress;

  /// Le nom lu, s'il dit plus que [libelle] (il le contient, W-253) ;
  /// `null` : le libelle.
  final String? libelleSemantique;

  /// Son panneau est ouvert : dit « selectionne » aux lecteurs d'ecran.
  final bool ouvert;

  /// Le noeud de focus, rendu au bouton quand son panneau se ferme.
  final FocusNode? focusNode;

  /// Largeur imposee (telephone, web etroit) : le chevron va au bout.
  final bool etire;

  /// Icones et ecarts resserres (colonne droite desktop, CLV-07).
  final bool serre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Widget texte = Text(
      libelle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: palette.inkStrong.applyTo(
        Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
      ),
    );
    // La carte pressable du core (K-54) : surface, filet, cible tactile et
    // centrage vertical viennent d'`AppCard`, jamais d'un fond peint ici.
    return Semantics(
      selected: ouvert,
      child: AppCard(
        onPress: onPress,
        libelleSemantique: libelleSemantique ?? libelle,
        focusNode: focusNode,
        marge: etire ? AppSpacing.md : AppSpacing.lg,
        // Le libelle est deja porte par la semantique de la carte : exclure
        // celle du contenu visuel evite une double lecture
        // (« Eleves 1/3 » lu deux fois).
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconTheme(
                data: palette.inkAccent.asIconTheme(
                  size: serre ? AppSpacing.xl : AppSpacing.xxl,
                ),
                child: Icon(icone.repos),
              ),
              if (serre) Ecart.hSm else Ecart.hMd,
              if (etire) Expanded(child: texte) else texte,
              if (serre) Ecart.hXs else if (etire) Ecart.hSm else Ecart.hLg,
              IconTheme(
                data: palette.inkMuted.asIconTheme(
                  size: serre ? AppSpacing.lg : AppSpacing.xl,
                ),
                child: Icon(AppIcons.chevron.repos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop : indicateur a gauche, zoom local a droite. TB-2 : le dock est
/// dans la barre de l'appel, posee par-dessus en bas (VIS-01).
class _BarreBasse extends StatelessWidget {
  const _BarreBasse({
    required this.vue,
    required this.actions,
    required this.local,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Vrai si la rangee a quelque chose a montrer.
  static bool utile(VueSeance vue) =>
      (vue.support != null && vue.voitIndicateurPage(Gabarit.desktop)) ||
      vue.voitZoomLocal(Gabarit.desktop);

  @override
  Widget build(BuildContext context) {
    const Gabarit gabarit = Gabarit.desktop;
    final SupportSeance? support = vue.support;
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: support != null && vue.voitIndicateurPage(gabarit)
                ? IndicateurPage(page: support.page, pages: support.pages)
                : const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: vue.voitZoomLocal(gabarit)
                ? ZoomLocal(
                    zoom: local.zoom,
                    onMoins: actions.onZoomMoins,
                    onPlus: actions.onZoomPlus,
                    onAgrandir: actions.onAgrandir,
                    agrandi: local.agrandi,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Les etats de connexion sous l'en-tete de la salle (lot CL-7, P05, P06) :
/// le bandeau non bloquant (reseau faible, reconnexion), puis le retour bref
/// « Connexion retablie. ». Tout vient de [VueSeance.connexion] : la salle ne
/// detecte rien elle-meme (BR-1).
///
/// Bandeau, retour bref et bloc d'erreur suivent les marges de la page
/// (contrat A : gouttiere 16 / 32 du gabarit), au-dessus du support et
/// jamais sous le rail enseignant. [espaceApres] : l'ecart du gabarit entre
/// l'etat et le support quand le gabarit n'en pose pas lui-meme (eleve
/// desktop), pour que rien ne touche le support. Apparition en
/// `AppMouvement.apparition`, zero sous reduction du mouvement.
///
/// Reconnexion impossible ou hors ligne confirme (T-S3) : `EtatSysteme` en
/// bloc a la place du bandeau, la salle reste montee ; largeur bornee
/// (contrat D), alignee au bord start du support.
/// La tete de la salle au telephone et en web etroit (en-tete, bandeau de
/// secours, appel), bornee a [part] de la hauteur de l'ecran. Le titre ne
/// tronque plus et ne se reduit plus sous son sous-titre (COUPE-MOTS-1) : a
/// 200 %, sur un ecran etroit, cette tete peut depasser la place. Elle
/// defile alors en elle-meme, rien n'est rogne, et le support et le dock
/// gardent leur place. Sinon, rien ne change (hauteur naturelle).
class TeteSalleBornee extends StatelessWidget {
  /// Cree la tete.
  const TeteSalleBornee({required this.children, super.key});

  /// La part maximale de la hauteur de l'ecran. Au-dessus du tiers que
  /// prend deja le bloc d'echec (lui-meme borne et defilant), pour qu'a
  /// 100 % en-tete et bloc restent visibles ensemble.
  static const double part = 0.55;

  /// La cle du defilement de la tete.
  static const Key defilementKey = ValueKey<String>('tete-salle-defile');

  /// L'en-tete, le bandeau, l'appel.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * part,
    ),
    child: SingleChildScrollView(
      key: defilementKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    ),
  );
}

class BandeauSecours extends StatelessWidget {
  const BandeauSecours({
    required this.vue,
    required this.actions,
    this.gouttiere = AppPage.gouttiereMobile,
    this.espaceApres = 0,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;

  /// La gouttiere du gabarit.
  final double gouttiere;

  /// L'ecart sous un etat visible, s'il manque au gabarit.
  final double espaceApres;

  @override
  Widget build(BuildContext context) {
    final String? texte = vue.texteBandeau;
    final String? titreEchec = vue.titreEchec;
    final bool visible =
        texte != null || titreEchec != null || vue.texteRetabli != null;
    final Widget etat;
    if (titreEchec != null) {
      etat = Align(
        alignment: AlignmentDirectional.topStart,
        // Hauteur bornee : un tiers de l'ecran, un cinquieme quand le texte
        // est agrandi (au-dela de 150 %, en-tete et dock grandissent aussi).
        // Au-dela, le bloc defile en lui-meme et le support garde sa place
        // (W2 1.4.10).
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppPage.largeurFormulaire,
            maxHeight:
                MediaQuery.sizeOf(context).height /
                (MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 5 : 3),
          ),
          child: SingleChildScrollView(
            child: _BlocEchec(vue: vue, actions: actions, titre: titreEchec),
          ),
        ),
      );
    } else if (texte != null) {
      etat = OfflineBanner.message(
        key: const ValueKey<String>('bandeau-secours'),
        message: texte,
        sousTexte: vue.sousTexteBandeau,
        // Reseau faible : la room reste connectee, jamais l'icone hors
        // ligne (P06.5).
        icone: vue.connexion == ConnexionSeance.reseauFaible
            ? AppIcons.reseau.repos
            : null,
        encadre: true,
      );
    } else {
      etat = const SizedBox(width: double.infinity);
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: gouttiere,
        end: gouttiere,
        bottom: visible ? espaceApres : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AnimatedSize(
            duration: AppMouvement.duree(context, AppMouvement.apparition),
            curve: AppMouvement.entree,
            alignment: AlignmentDirectional.topStart,
            child: etat,
          ),
          LocalFeedback(
            key: const ValueKey<String>('retour-retablie'),
            message: vue.texteRetabli,
          ),
        ],
      ),
    );
  }
}

/// Le bloc d'erreur de connexion (P05.8) : titre exact par role, sans
/// phrase ; `Reessayer` au bord trailing, la sortie au bord leading (en
/// echec, et hors ligne en guidee), qui repasse par la confirmation
/// existante. Rien n'est rendu sans son geste.
class _BlocEchec extends StatelessWidget {
  const _BlocEchec({
    required this.vue,
    required this.actions,
    required this.titre,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final String titre;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? quitter = actions.onQuitter;
    return EtatSysteme(
      key: const ValueKey<String>('bloc-echec-connexion'),
      nature: vue.connexion == ConnexionSeance.horsLigne
          ? NatureEtat.horsLigne
          : NatureEtat.reconnexion,
      titre: titre,
      phrase: '',
      libelleAction: t.salle.secours.reessayer,
      onAction: actions.onReessayerConnexion,
      libelleSecondaire: vue.libelleQuitterEchec,
      onSecondaire: vue.echecPermetQuitter && quitter != null
          ? () => confirmerQuitterSeance(
              context,
              quitter,
              cahier: vue.quitterOuvreCahier,
            )
          : null,
    );
  }
}

/// L'appel discret recu par l'eleve (EN-9, E16) : une ligne d'etat annoncee
/// poliment (region vivante), sans fenetre, sans son ni focus vole.
Widget? _appel(VueSeance vue, double gouttiere) {
  final String? texte = vue.texteAppel;
  if (texte == null) return null;
  return Padding(
    key: const ValueKey<String>('appel-discret'),
    padding: EdgeInsetsDirectional.fromSTEB(
      gouttiere,
      AppSpacing.sm,
      gouttiere,
      0,
    ),
    child: Builder(
      builder: (BuildContext context) {
        final AppPalette palette = AppPalette.of(context);
        return Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: palette.surfaceOverlay.decoration(
              borderRadius: AppRadius.arrondiMd,
              side: palette.borderHairline.asBorderSide(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                texte,
                style: palette.inkStrong.applyTo(
                  Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// TB-2 (VIS-01, plan V2 §4.1, §18) : la barre de l'appel (Micro, Camera,
/// Quitter) dans [CommandesMasquables], pour l'eleve, la guidee et
/// l'enseignant, a tous les gabarits : revelee au toucher (non consomme),
/// a la souris, au Tab (« Commandes de l'appel ») ; retenue au survol, au
/// focus, panneau ouvert ou erreur critique ([VueSeance.visioMaintenue]),
/// lecteur d'ecran ; posee par-dessus le contenu, qui garde une marge egale
/// a sa hauteur mesuree : rien ne bouge quand elle se masque.
Widget _visioRevelee({
  required VueSeance vue,
  required Widget contenu,
  required Widget barre,
}) => CommandesMasquables(
  contenu: contenu,
  commandes: barre,
  maintenir: vue.visioMaintenue,
  margeLecture: true,
  libelleEntree: t.salle.seance.commandesAppel,
);
