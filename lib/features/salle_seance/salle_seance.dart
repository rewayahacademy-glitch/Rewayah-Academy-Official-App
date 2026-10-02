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

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/pressable.dart';
import 'actions_seance.dart';
import 'barre_support.dart';
import 'chrome_seance.dart';
import 'dock_seance.dart';
import 'outils_enseignement.dart';
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
      // Telephone, panneau ouvert : la feuille descend jusqu'au bord de
      // l'ecran (image) ; elle garde elle-meme la marge du systeme.
      final bool feuilleOuverte =
          gabarit == Gabarit.mobile &&
          vue.voitBoutonsPanneaux &&
          vue.panneau != PanneauOuvert.aucun;
      return Material(
        color: palette.surfaceCanvas.background,
        child: SafeArea(
          bottom: !feuilleOuverte,
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
    // Plein cadre, sans coquille de page : ni titre d'ecran, ni colonne
    // bornee (CONTENT > CHROME). Le fond reste celui du theme (clair et
    // sombre), comme sur les images, et non le registre inverse.
    return Material(
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (agrandi) ...<Widget>[
              // Mode agrandi : l'en-tete se retire, l'etat critique reste
              // visible (CL-7 §2.7).
              BandeauSecours(vue: vue, actions: actions, gouttiere: gouttiere),
              Ecart.vLg,
            ] else ...<Widget>[
              ChromeSeance(vue: vue, actions: actions),
              BandeauSecours(
                vue: vue,
                actions: actions,
                gouttiere: gouttiere,
                espaceApres: large ? AppSpacing.lg : 0,
              ),
              ?_appel(vue, gouttiere),
              if (!large) Ecart.vLg,
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gouttiere),
                child: ZoneSupport(
                  vue: vue,
                  zoom: local.zoom,
                  contenu: contenuSupport,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: gouttiere,
                end: gouttiere,
                top: large ? AppSpacing.xl : AppSpacing.lg,
                bottom: large ? AppSpacing.xl : AppSpacing.md,
              ),
              child: large
                  ? _BarreBasse(vue: vue, actions: actions, local: local)
                  : DockSeance(
                      vue: vue,
                      actions: actions,
                      microOuvert: local.microOuvert,
                      cameraAllumee: local.cameraAllumee,
                      agrandi: agrandi,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le clavier des panneaux Eleves et Supports : Echap ferme le panneau
/// ouvert ; a la fermeture (croix, menu ou Echap), le focus revient au
/// bouton qui l'avait ouvert.
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
  final FocusNode _focusSupports = FocusNode(debugLabel: 'bouton-supports');
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
        : _focusSupports;
    // Le bouton est remonte au cadre suivant (telephone, web etroit).
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && bouton.context != null) bouton.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusEleves.dispose();
    _focusSupports.dispose();
    _focusSupport.dispose();
    super.dispose();
  }

  void _fermer() {
    switch (widget.vue.panneau) {
      case PanneauOuvert.eleves:
        widget.actions.onEleves?.call();
      case PanneauOuvert.supports:
        widget.actions.onSupports?.call();
      case PanneauOuvert.ressources:
        widget.actions.onBibliotheque?.call();
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
                panneau == PanneauOuvert.ressources),
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
  /// et, hors bureau, au-dessus de la rangee d'outils posee sur le dock.
  double _hauteurRetourMicro(BuildContext context) {
    final double dessusDock =
        diametreBoutonAppel(context) + AppSpacing.respiration;
    return widget.gabarit == Gabarit.desktop
        ? dessusDock
        : dessusDock + AppSpacing.respiration + AppSpacing.lg;
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

  @override
  Widget build(BuildContext context) {
    // EN-9 : sur bureau, le panneau Eleves est ouvert d'office (a droite du
    // support), jamais derriere le bouton « Eleves ».
    final VueSeance vue =
        widget.gabarit == Gabarit.desktop &&
            widget.vue.voitBoutonsPanneaux &&
            widget.vue.panneau == PanneauOuvert.aucun
        ? widget.vue.copyWith(panneau: PanneauOuvert.eleves)
        : widget.vue;
    final bool ouvert =
        widget.vue.voitBoutonsPanneaux &&
        widget.vue.panneau != PanneauOuvert.aucun;
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
                child: _SalleEnseignant(
                  vue: vue,
                  actions: widget.actions,
                  local: widget.local,
                  gabarit: widget.gabarit,
                  contenuSupport: widget.contenuSupport,
                  focusEleves: _focusEleves,
                  focusSupports: _focusSupports,
                  focusSupport: _focusSupport,
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

/// La salle de l'enseignant (CLV-06) : rail (desktop), outils, boutons
/// Eleves et Supports, support dominant, pagination active et zoom (desktop),
/// dock Micro, Camera, Reseau, Quitter. Jamais Agrandir.
class _SalleEnseignant extends StatelessWidget {
  const _SalleEnseignant({
    required this.vue,
    required this.actions,
    required this.local,
    required this.gabarit,
    required this.focusEleves,
    required this.focusSupports,
    required this.focusSupport,
    this.contenuSupport,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final Gabarit gabarit;
  final Widget? contenuSupport;

  /// Les noeuds des boutons Eleves et Supports (retour du focus).
  final FocusNode focusEleves;
  final FocusNode focusSupports;

  /// Le noeud du support : il recoit le focus apres le choix d'une ressource.
  final FocusNode focusSupport;

  @override
  Widget build(BuildContext context) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool outils = vue.voitOutils && actions.onOutil != null;
    // Telephone et desktop : le support partage la hauteur avec les boutons
    // et les outils, il se resserre pour montrer la diapositive entiere.
    final Widget support = Focus(
      focusNode: focusSupport,
      child: ZoneSupport(
        vue: vue,
        zoom: local.zoom,
        serre: true,
        contenu: contenuSupport,
      ),
    );
    final Widget? boutons = _BoutonsPanneaux.ou(
      vue,
      actions,
      gabarit,
      focusEleves: focusEleves,
      focusSupports: focusSupports,
    );
    final Widget? panneau = _panneau();
    if (panneau != null) {
      return gabarit == Gabarit.desktop
          ? _avecRail(
              _desktopAvecPanneau(
                context,
                panneau: panneau,
                support: support,
                outils: outils,
              ),
            )
          : _etroitAvecPanneau(panneau: panneau, support: support);
    }
    switch (gabarit) {
      case Gabarit.desktop:
        final SupportSeance? page = vue.support;
        final Widget contenu = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChromeSeance(vue: vue, actions: actions),
            // La rangee d'outils n'a pas d'ecart en tete : 12, comme sous
            // elle.
            BandeauSecours(
              vue: vue,
              actions: actions,
              espaceApres: AppSpacing.md,
            ),
            if (outils || boutons != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  gouttiere,
                  0,
                  gouttiere,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (outils)
                      OutilsEnseignement(
                        onOutil: actions.onOutil,
                        forme: FormeOutils.rangee,
                      ),
                    const Spacer(),
                    ?boutons,
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: support,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                gouttiere,
                AppSpacing.xxl,
                gouttiere,
                AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: page != null && vue.voitPaginationActive(gabarit)
                          ? PaginationSupport(
                              page: page.page,
                              pages: page.pages,
                              onPrecedente: actions.onPagePrecedente,
                              onSuivante: actions.onPageSuivante,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  DockSeance(
                    vue: vue,
                    actions: actions,
                    microOuvert: local.microOuvert,
                    cameraAllumee: local.cameraAllumee,
                    focusSupports: focusSupports,
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: vue.voitZoomLocal(gabarit)
                          ? Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.respiration,
                              ),
                              child: ZoomLocal(
                                zoom: local.zoom,
                                onMoins: actions.onZoomMoins,
                                onPlus: actions.onZoomPlus,
                                avecLibelle: false,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        return _avecRail(contenu);
      case Gabarit.tablette:
      case Gabarit.mobile:
        final bool mobile = gabarit == Gabarit.mobile;
        // Telephone : les ecarts entre les rangees se resserrent d'un
        // palier, la place revient au support (image mobile, enseignant).
        final Widget ecart = mobile ? Ecart.vSm : Ecart.vMd;
        final double ecartDock = mobile ? AppSpacing.sm : AppSpacing.md;
        final Widget milieu = mobile || !outils
            ? support
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: support),
                  Ecart.hMd,
                  OutilsEnseignement(
                    onOutil: actions.onOutil,
                    forme: FormeOutils.colonne,
                  ),
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ChromeSeance(vue: vue, actions: actions),
            BandeauSecours(vue: vue, actions: actions),
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
                child: milieu,
              ),
            ),
            if (mobile && outils) ...<Widget>[
              ecart,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                child: OutilsEnseignement(
                  onOutil: actions.onOutil,
                  forme: FormeOutils.rangee,
                ),
              ),
            ],
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gouttiere,
                ecartDock,
                gouttiere,
                ecartDock,
              ),
              child: DockSeance(
                vue: vue,
                actions: actions,
                microOuvert: local.microOuvert,
                cameraAllumee: local.cameraAllumee,
                focusSupports: focusSupports,
              ),
            ),
          ],
        );
    }
  }

  /// EN-9 : la salle de l'enseignant n'a pas de barre de navigation, meme
  /// sur bureau (le rail reste a la fin de seance, `FinSeanceEnseignant`).
  Widget _avecRail(Widget contenu) => contenu;

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
        // support ; il ne se ferme pas.
        onFermer: forme == FormePanneau.colonne ? null : actions.onEleves,
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
      // la bibliotheque » et par la Bibliotheque du Teaching Dock ; feuille
      // sur mobile, panneau sur bureau. La salle reste ouverte.
      PanneauOuvert.ressources => PanneauSeance(
        titre: t.salle.seance.supports,
        onFermer: actions.onBibliotheque,
        forme: forme,
        enfant: SelecteurRessources(supports: vue.supports, actions: actions),
      ),
    };
    if (panneau == null) return null;
    // A l'ouverture, le focus entre dans le panneau (si rien d'autre ne le
    // tient) : Echap le ferme alors depuis le clavier.
    return Focus(autofocus: true, skipTraversal: true, child: panneau);
  }

  /// Desktop, panneau ouvert (CLV-07, CLV-08) : panneau a gauche, support au
  /// centre, colonne droite (Eleves et Supports, puis carte des outils, Q2) ;
  /// pagination, dock et zoom sous le support seulement.
  Widget _desktopAvecPanneau(
    BuildContext context, {
    required Widget panneau,
    required Widget support,
    required bool outils,
  }) {
    const double gouttiere = AppPage.gouttiereMobile;
    final SupportSeance? page = vue.support;
    // CLV-08 : carte des outils en tete de la colonne droite, puis Eleves et
    // Supports en liste ; sous le support, dock puis pagination et zoom.
    final bool supports = vue.panneau == PanneauOuvert.supports;
    final Widget? boutons = _BoutonsPanneaux.ou(
      vue,
      actions,
      gabarit,
      etire: true,
      serre: true,
      enColonne: supports,
      focusEleves: focusEleves,
      focusSupports: focusSupports,
    );
    final Widget? pagination = page != null && vue.voitPaginationActive(gabarit)
        ? PaginationSupport(
            page: page.page,
            pages: page.pages,
            onPrecedente: actions.onPagePrecedente,
            onSuivante: actions.onPageSuivante,
          )
        : null;
    final Widget dock = DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      focusSupports: focusSupports,
    );
    final Widget? zoom = vue.voitZoomLocal(gabarit)
        ? ZoomLocal(
            zoom: local.zoom,
            onMoins: actions.onZoomMoins,
            onPlus: actions.onZoomPlus,
            avecLibelle: false,
          )
        : null;
    if (supports) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChromeSeance(vue: vue, actions: actions),
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
                  Expanded(child: support),
                  Ecart.hMd,
                  SizedBox(
                    width: largeurColonneDroiteSeance,
                    // Une seule carte haute comme le support : les outils,
                    // puis Eleves et Supports (image CLV-08).
                    child: outils
                        ? OutilsEnseignement(
                            onOutil: actions.onOutil,
                            forme: FormeOutils.carte,
                            initial: null,
                            pied: boutons,
                          )
                        : Column(children: <Widget>[?boutons]),
                  ),
                ],
              ),
            ),
          ),
          // Image CLV-08 : le dock part sous le debut du support, pagination
          // et zoom a sa droite.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              gouttiere + largeurPanneauSeance,
              AppSpacing.xl,
              gouttiere,
              AppSpacing.lg,
            ),
            // A 1200 de large (bas du gabarit desktop), la rangee se reduit
            // d'un bloc plutot que de deborder.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xl,
                children: <Widget>[dock, ?pagination, ?zoom],
              ),
            ),
          ),
        ],
      );
    }
    // EN-9 (salle A, bureau) : deux volets seulement. A gauche, la rangee
    // d'outils puis le support ; a droite, les boutons Eleves et Supports
    // puis le panneau Eleves et la file de recitation, ouverts d'office.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChromeSeance(vue: vue, actions: actions),
        BandeauSecours(vue: vue, actions: actions),
        Ecart.vSm,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (outils) ...<Widget>[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutilsEnseignement(
                            onOutil: actions.onOutil,
                            forme: FormeOutils.rangee,
                          ),
                        ),
                        Ecart.vMd,
                      ],
                      Expanded(child: support),
                    ],
                  ),
                ),
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
        // La barre basse sous le support seulement.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            gouttiere,
            AppSpacing.xl,
            gouttiere + largeurColonneSeance + AppSpacing.md,
            AppSpacing.lg,
          ),
          // Pres du bas du gabarit desktop (1200 a 1400), la rangee se
          // reduit d'un bloc plutot que de deborder, comme sur CLV-08.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: <Widget>[?pagination, dock, ?zoom],
            ),
          ),
        ),
      ],
    );
  }

  /// Web etroit et telephone, panneau ouvert : le panneau recouvre le
  /// support (volet a gauche, ou feuille du bas qui laisse voir le haut du
  /// support et la vignette). Les boutons Eleves et Supports et les outils
  /// se retirent : le panneau les remplace (images CLV-07-08-10).
  Widget _etroitAvecPanneau({
    required Widget panneau,
    required Widget support,
  }) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool mobile = gabarit == Gabarit.mobile;
    final double ecartDock = mobile ? AppSpacing.sm : AppSpacing.md;
    Widget dessous(double largeurVolet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: support,
          ),
        ),
        Padding(
          // Web etroit : le dock se centre a droite du volet (image).
          padding: EdgeInsetsDirectional.fromSTEB(
            mobile ? gouttiere : largeurVolet + AppSpacing.sm + AppSpacing.xs,
            ecartDock,
            mobile ? gouttiere : AppSpacing.sm,
            ecartDock,
          ),
          child: Align(
            child: DockSeance(
              vue: vue,
              actions: actions,
              microOuvert: local.microOuvert,
              cameraAllumee: local.cameraAllumee,
              focusSupports: focusSupports,
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChromeSeance(vue: vue, actions: actions),
        BandeauSecours(vue: vue, actions: actions),
        mobile ? Ecart.vSm : Ecart.vMd,
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints c) {
              // Volet : au plus la moitie de la largeur, moins un palier, pour
              // laisser au dock toute sa place a droite (image : ≈ 313).
              final double largeurVolet = math.min(
                largeurPanneauSeance,
                c.maxWidth / 2 - AppSpacing.lg,
              );
              return Stack(
                children: <Widget>[
                  Positioned.fill(child: dessous(largeurVolet)),
                  if (mobile)
                    Positioned.fill(
                      top: supportVisibleSousFeuille,
                      child: panneau,
                    )
                  else
                    // Le volet descend jusqu'au bas de l'ecran (image).
                    PositionedDirectional(
                      start: AppSpacing.sm,
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

/// « Eleves 1/3 › » et « Supports › » : enseignant seulement. Desktop :
/// deux boutons a droite de la rangee d'outils ; ailleurs, deux boutons de
/// meme largeur au-dessus du support.
class _BoutonsPanneaux extends StatelessWidget {
  const _BoutonsPanneaux({
    required this.compteur,
    required this.onEleves,
    required this.onSupports,
    required this.etire,
    this.panneau = PanneauOuvert.aucun,
    this.focusEleves,
    this.focusSupports,
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
    FocusNode? focusSupports,
  }) {
    final String? compteur = vue.compteurEleves;
    if (!vue.voitBoutonsPanneaux || compteur == null) return null;
    if (actions.onEleves == null) return null;
    // Bureau, panneau Eleves ouvert : il dit deja l'etat et le compteur (son
    // en-tete), le bouton ne le repete pas (K-42, style 3). R et Echap
    // restent.
    if (gabarit == Gabarit.desktop && vue.panneau == PanneauOuvert.eleves) {
      return null;
    }
    return _BoutonsPanneaux(
      compteur: compteur,
      onEleves: actions.onEleves,
      // EN-10 : Supports passe dans le Teaching Dock compact (maquettes,
      // planche 3) ; un seul bouton Supports dans la salle.
      onSupports: null,
      etire: etire ?? gabarit != Gabarit.desktop,
      panneau: vue.panneau,
      focusEleves: focusEleves,
      focusSupports: focusSupports,
      serre: serre,
      enColonne: enColonne,
    );
  }

  /// Le panneau ouvert : son bouton se dit selectionne.
  final PanneauOuvert panneau;
  final FocusNode? focusEleves;
  final FocusNode? focusSupports;

  final String compteur;
  final VoidCallback? onEleves;
  final VoidCallback? onSupports;
  final bool etire;

  /// Desktop, panneau ouvert : colonne droite etroite (CLV-07).
  final bool serre;

  /// Desktop, panneau Supports : l'un sous l'autre, pleine largeur (CLV-08).
  final bool enColonne;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? eleves = onEleves;
    final VoidCallback? supports = onSupports;
    final List<Widget> boutons = <Widget>[
      if (eleves != null)
        BoutonPanneau(
          key: const ValueKey<String>('bouton-eleves'),
          icone: AppIcons.eleves,
          libelle: compteur,
          onPress: eleves,
          ouvert: panneau == PanneauOuvert.eleves,
          focusNode: focusEleves,
          etire: etire,
          serre: serre,
        ),
      if (supports != null)
        BoutonPanneau(
          key: const ValueKey<String>('bouton-supports'),
          icone: AppIcons.supports,
          libelle: t.salle.seance.supports,
          onPress: supports,
          ouvert: panneau == PanneauOuvert.supports,
          focusNode: focusSupports,
          etire: etire,
          serre: serre,
        ),
    ];
    if (enColonne) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: boutons,
      );
    }
    return Row(
      mainAxisSize: etire ? MainAxisSize.max : MainAxisSize.min,
      spacing: AppSpacing.md,
      children: <Widget>[
        for (final Widget b in boutons) etire ? Expanded(child: b) : b,
      ],
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
    super.key,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback onPress;

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
    return Semantics(
      selected: ouvert,
      child: Pressable(
        onPress: onPress,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiMd,
        focusNode: focusNode,
        child: DecoratedBox(
          decoration: palette.surfaceRaised.decoration(
            borderRadius: AppRadius.arrondiMd,
            side: palette.borderHairline.asBorderSide(),
          ),
          child: SizedBox(
            // Telephone et web etroit : plus bas et plus serre (images).
            height: etire
                ? AppSpacing.titreEcran
                : AppSpacing.titreEcran + AppSpacing.xs,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: etire ? AppSpacing.md : AppSpacing.lg,
              ),
              // Le libelle est deja porte par la semantique de Pressable :
              // exclure celle du contenu visuel evite une double lecture
              // (« Eleves 1/3\nEleves 1/3 »).
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
                    if (serre)
                      Ecart.hXs
                    else if (etire)
                      Ecart.hSm
                    else
                      Ecart.hLg,
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
          ),
        ),
      ),
    );
  }
}

/// Desktop : indicateur a gauche, dock au centre, zoom local a droite.
class _BarreBasse extends StatelessWidget {
  const _BarreBasse({
    required this.vue,
    required this.actions,
    required this.local,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

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
        DockSeance(
          vue: vue,
          actions: actions,
          microOuvert: local.microOuvert,
          cameraAllumee: local.cameraAllumee,
          agrandi: local.agrandi && support != null,
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
