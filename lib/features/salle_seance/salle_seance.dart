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
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/theme/app_contour.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
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
import 'bibliotheque_seance.dart';
import 'capsule_seance.dart';
import 'chrome_seance.dart';
import 'commandes_pedagogiques.dart';
import 'composition_salle.dart';
import 'dock_seance.dart';
import 'ecriture_seance.dart';
import 'panneau_eleves.dart';
import 'panneau_seance.dart';
import 'panneau_supports.dart';
import 'rangement_support.dart';
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
        construire: (FocusNode focusCapsule, FocusNode focusCommandes) =>
            Material(
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
                          contenu: _surCommandesEleve(
                            vue: vue,
                            actions: actions,
                            local: local,
                            agrandi: agrandi,
                            contenu: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
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
                                ?_sousSurfaceEleve(
                                  vue,
                                  actions,
                                  gouttiere,
                                  focusCommandes,
                                ),
                              ],
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
      construire: (FocusNode focusCapsule, FocusNode focusCommandes) => Material(
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
                    // TB-10 : les Commandes ouvertes (volet du bureau) se
                    // posent sur la surface seule, au-dessus de la barre
                    // basse (page, zoom local) : elles ne la couvrent pas.
                    contenu: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: _surCommandesEleve(
                            vue: vue,
                            actions: actions,
                            local: local,
                            agrandi: agrandi,
                            marge: gouttiere,
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
                                ?_sousSurfaceEleve(
                                  vue,
                                  actions,
                                  gouttiere,
                                  focusCommandes,
                                ),
                              ],
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
  final Widget Function(FocusNode focusCapsule, FocusNode focusCommandes)
  construire;

  @override
  State<_ContexteEleve> createState() => _ContexteEleveState();
}

class _ContexteEleveState extends State<_ContexteEleve> {
  final FocusNode _focusCapsule = FocusNode(debugLabel: 'capsule-avatar');

  /// TB-10 : le declencheur « Commandes » de l'eleve ; la fermeture du
  /// panneau (Reduire, Echap) y rend le focus.
  final FocusNode _focusCommandes = FocusNode(debugLabel: 'commandes-eleve');

  bool _commandes(VueSeance vue) => vue.panneau == PanneauOuvert.commandes;

  @override
  void didUpdateWidget(_ContexteEleve ancien) {
    super.didUpdateWidget(ancien);
    if (_commandes(ancien.vue) && !_commandes(widget.vue)) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _focusCommandes.context != null) {
          _focusCommandes.requestFocus();
        }
      });
    }
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
    _focusCommandes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      // TB-10 (UX_REVIEW_TB n. 26, plan V2 §18.3) : Echap reduit aussi les
      // Commandes de l'eleve, jamais l'appel. Une seule entree pour la
      // touche (deux cles egales dans la table : la seconde ecraserait la
      // premiere) : le contexte deplie d'abord, les Commandes ensuite.
      if (widget.vue.contexteOuvert ||
          (_commandes(widget.vue) && widget.actions.onCommandes != null))
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (widget.vue.contexteOuvert) {
            widget.actions.onContexte?.call(ContexteOuvert.aucun);
          } else {
            widget.actions.onCommandes?.call();
          }
        },
    },
    child: widget.construire(_focusCapsule, _focusCommandes),
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

/// TB-10 (plan V2 §19.3 point 4) : sous la surface de l'eleve et de la
/// guidee, l'information courte de l'ecriture et le declencheur
/// « Commandes » (ou, pendant l'ecriture, la palette courte : Stylo ou
/// Gomme, Annuler, Terminer). `null` : aucune entree n'a de rappel
/// (Classe Live avant TB-BR), rien n'est rendu.
///
/// Pose sous la surface et non dans la barre de l'appel : il ne couvre
/// rien, et la palette ne se masque pas pendant qu'on ecrit.
Widget? _sousSurfaceEleve(
  VueSeance vue,
  ActionsSeance actions,
  double gouttiere,
  FocusNode focusCommandes,
) {
  if (vue.commandesCompletes ||
      !CommandesPedagogiques.aDesEntrees(vue, actions)) {
    return null;
  }
  // Texte agrandi sur petit ecran : la barre de l'appel se pose par-dessus
  // le bas du contenu ; l'entree reste au-dessus d'elle, jamais dessous.
  // Au-dela de sa part, elle defile : rien n'est coupe.
  // Un quart de l'ecran au plus (la page garde le reste) ; la marge de la
  // barre est hors du defilement : rien ne passe sous elle.
  return Builder(
    builder: (BuildContext contexte) => Padding(
      padding: EdgeInsets.only(
        bottom: CommandesMasquables.recouvrementDe(contexte),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(contexte).height / 4,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.only(
            start: gouttiere,
            end: gouttiere,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: CommandesEleve(
            vue: vue,
            actions: actions,
            focusCommandes: focusCommandes,
          ),
        ),
      ),
    ),
  );
}

/// TB-10, eleve et guidee : les Commandes ouvertes, posees par-dessus la
/// surface dans le cadre de panneau existant ([PanneauSeance]) : feuille du
/// bas au telephone (le haut de la page reste visible), volet au bord de fin
/// ailleurs. « Reduire » et Echap les ferment.
Widget _surCommandesEleve({
  required VueSeance vue,
  required ActionsSeance actions,
  required EtatLocalSeance local,
  required bool agrandi,
  required Widget contenu,
  double marge = AppSpacing.sm,
}) {
  final VoidCallback? reduire = actions.onCommandes;
  if (vue.commandesCompletes || reduire == null) return contenu;
  // La meme pile, ouverte ou non : la surface et l'entree des Commandes
  // restent les memes elements (zoom, deplacement, outil retenu gardes).
  return LayoutBuilder(
    builder: (BuildContext contexte, BoxConstraints c) {
      if (vue.panneau != PanneauOuvert.commandes) {
        return Stack(children: <Widget>[Positioned.fill(child: contenu)]);
      }
      final bool feuille = AppGabarit.de(contexte) == Gabarit.mobile;
      final double recouvert = math.min(
        CommandesMasquables.recouvrementDe(contexte),
        c.maxHeight,
      );
      final Widget panneau = Focus(
        autofocus: true,
        skipTraversal: true,
        child: PanneauSeance(
          titre: t.salle.seance.commandes.titre,
          onFermer: reduire,
          libelleFermer: t.salle.seance.commandes.reduire,
          semantiqueFermer: t.salle.seance.commandes.reduireSemantique,
          forme: feuille ? FormePanneau.feuille : FormePanneau.volet,
          enfant: Padding(
            padding: EdgeInsets.only(bottom: recouvert),
            child: CommandesPedagogiques(
              vue: vue,
              actions: actions,
              zoom: local.zoom,
              agrandi: agrandi,
            ),
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
            // Verification TB-10 : le volet reste dans le cadre de la
            // surface ([marge] : la gouttiere qui borde le support).
            PositionedDirectional(
              end: marge,
              top: 0,
              bottom: AppSpacing.sm,
              width: math.min(largeurPanneauSeance, c.maxWidth - 2 * marge),
              child: panneau,
            ),
        ],
      );
    },
  );
}

/// TB-10 (plan V2 §5, §12, §19.3 ; UX-20) : l'information courte et
/// l'entree des Commandes de l'eleve.
///
/// - Autorisation accordee : « Tu peux ecrire sur le tableau. » (ou la
///   variante adulte), annoncee au lecteur d'ecran ; l'eleve choisit
///   ensuite « Ecrire » dans ses Commandes : aucun geste ne devient un
///   trait sans ce choix.
/// - Droit retire : « Sayyid reprend le tableau. » (ou « Sayyida ... »),
///   l'outil d'ecriture est repose (la palette disparait) ; le trait en
///   cours est resolu par la surface (`CoucheAnnotation.saisie`).
///
/// L'information reste jusqu'a l'ouverture des Commandes (aucune minuterie :
/// un lecteur lent ne la manque pas, WCAG 2.2.1).
class CommandesEleve extends ConsumerStatefulWidget {
  /// Cree l'entree.
  const CommandesEleve({
    required this.vue,
    required this.actions,
    this.focusCommandes,
    super.key = cle,
  });

  /// La cle de l'entree.
  static const Key cle = ValueKey<String>('commandes-eleve');

  /// La cle de l'information courte.
  static const Key cleAvis = ValueKey<String>('commandes-eleve-avis');

  final VueSeance vue;
  final ActionsSeance actions;
  final FocusNode? focusCommandes;

  @override
  ConsumerState<CommandesEleve> createState() => _CommandesEleveState();
}

class _CommandesEleveState extends ConsumerState<CommandesEleve> {
  /// Le droit vient d'etre retire dans cette salle (passage de vrai a faux).
  bool _retrait = false;

  /// L'information a ete vue : les Commandes se sont ouvertes depuis.
  bool _lu = false;

  @override
  void initState() {
    super.initState();
    _lu = widget.vue.panneau == PanneauOuvert.commandes;
    // TB-10 (tour 2) : l'entree peut etre recreee au moment meme du retrait
    // (bascule agrandi, changement de gabarit) : le passage de vrai a faux
    // n'est alors pas vu. Sans droit, un outil retenu est donc repose des
    // la creation, pas seulement au passage.
    if (!widget.vue.peutEcrire) _reposerOutil();
  }

  void _reposerOutil() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      if (ref.read(etatOutilsProvider).outilActif != null) {
        ref.read(etatOutilsProvider.notifier).relacherOutil();
      }
    });
  }

  @override
  void didUpdateWidget(CommandesEleve ancien) {
    super.didUpdateWidget(ancien);
    final bool avant = ancien.vue.peutEcrire;
    final bool apres = widget.vue.peutEcrire;
    if (avant && !apres) {
      _retrait = true;
      _lu = false;
      _reposerOutil();
    } else if (!avant && apres) {
      _retrait = false;
      _lu = false;
    } else if (ancien.vue.ecritureRetiree != widget.vue.ecritureRetiree) {
      _lu = false;
    }
    if (!avant && !apres) _reposerOutil();
    if (widget.vue.panneau == PanneauOuvert.commandes) _lu = true;
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final VoidCallback? basculer = widget.actions.onCommandes;
    final bool ouvert = vue.panneau == PanneauOuvert.commandes;
    final bool ecrit = ecritSurLaSurface(ref, vue);
    final String? retrait = _lu
        ? null
        : vue
              .copyWith(ecritureRetiree: vue.ecritureRetiree || _retrait)
              .avisRetrait;
    final String? avis = _lu
        ? null
        : retrait ?? (ecrit ? null : vue.avisEcriture);
    // TB-10 (tour 2) : texte agrandi ou Mode Accessibilite, l'information
    // courte et le declencheur (icone seule, nom lu et infobulle gardes) se
    // partagent UNE rangee, et la phrase prend le corps court : la page
    // garde la hauteur qu'elle avait avant l'information (320 a 200 %).
    final bool rangee =
        avis != null &&
        !ecrit &&
        basculer != null &&
        !ouvert &&
        (MediaQuery.textScalerOf(context).scale(1) >
                AppContour.seuilTexteAgrandi ||
            AppMetriques.of(context).mode == InterfaceMode.enfant);
    final Widget? entree = basculer == null || ouvert
        ? null
        : ecrit
        ? PaletteEcriture(
            vue: vue,
            onCommandes: basculer,
            focusCommandes: widget.focusCommandes,
          )
        : DeclencheurCommandes(
            onPress: basculer,
            focusNode: widget.focusCommandes,
            iconeSeule: rangee,
          );
    if (rangee) {
      return Row(
        children: <Widget>[
          Expanded(child: _AvisEcriture(texte: avis, compacte: true)),
          Ecart.hSm,
          ?entree,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Verification TB-10 : le retrait (« Sayyid reprend le tableau. »)
        // ne porte pas le crayon de « Vous pouvez ecrire » : sans icone.
        if (avis != null)
          _AvisEcriture(texte: avis, avecIcone: retrait == null),
        if (avis != null && entree != null) Ecart.vSm,
        if (entree != null) Center(heightFactor: 1, child: entree),
      ],
    );
  }
}

/// L'information courte de l'eleve : l'icone d'ecriture et la phrase, dite
/// au lecteur d'ecran des qu'elle change (W-413).
class _AvisEcriture extends StatelessWidget {
  const _AvisEcriture({
    required this.texte,
    this.compacte = false,
    this.avecIcone = true,
  });

  final String texte;

  /// Faux pour le retrait du droit d'ecrire : le crayon dirait le contraire.
  final bool avecIcone;

  /// Rangee du texte agrandi : sans l'icone (le declencheur est a cote), au
  /// corps court.
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Le corps du texte, pas un titre : au texte agrandi, la phrase laisse
    // sa hauteur a la page.
    final Widget phrase = TexteSansCoupure(
      texte,
      style: palette.inkStrong.applyTo(
        (compacte ? textes.bodySmall : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return Semantics(
      key: CommandesEleve.cleAvis,
      liveRegion: true,
      container: true,
      child: compacte
          ? phrase
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (avecIcone) ...<Widget>[
                  ExcludeSemantics(
                    child: IconTheme(
                      data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                      child: Icon(AppIcons.annoter.repos),
                    ),
                  ),
                  Ecart.hSm,
                ],
                Flexible(child: phrase),
              ],
            ),
    );
  }
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

  /// TB-5 (n. 12) : l'enseignant a replie la colonne des Participants. Etat
  /// local, jamais diffuse ; il survit au focus et au redimensionnement.
  bool _participantsReplies = false;

  /// TB-5 (UX-16) : le panneau droit ouvert avant le focus, a retrouver en
  /// le quittant si la largeur le permet.
  PanneauOuvert _avantFocus = PanneauOuvert.aucun;

  /// La largeur, le facteur de texte et le gabarit du dernier rendu : la
  /// composition des rappels (R, Echap, Focus) est celle qu'on voit.
  double _largeur = 0;
  double _facteurTexte = 1;

  bool get _telephone => widget.gabarit == Gabarit.mobile;

  /// La colonne des Participants tient a la largeur actuelle.
  bool get _gaucheTient => CompositionSalle.gaucheTient(
    largeur: _largeur,
    facteurTexte: _facteurTexte,
    telephone: _telephone,
  );

  CompositionSalle _composition({PanneauOuvert? panneau, bool? agrandi}) =>
      CompositionSalle.pour(
        largeur: _largeur,
        facteurTexte: _facteurTexte,
        telephone: _telephone,
        panneau: panneau ?? widget.vue.panneau,
        participantsReplies: _participantsReplies,
        agrandi: agrandi ?? _agrandi,
        contexteOuvert: widget.vue.contexteOuvert,
        participantsDisponibles: _participantsDisponibles,
      );

  /// La salle de l'enseignant a des Participants. En colonne, ils se
  /// replient et se deplient localement ; en panneau temporaire, il faut le
  /// rappel de la page (`onEleves`), comme avant TB-5.
  bool get _participantsDisponibles => widget.vue.voitBoutonsPanneaux;

  /// Le rappel du bouton « Eleves » et de R, ou `null`.
  VoidCallback? get _rappelParticipants =>
      _gaucheTient ? _basculerParticipants : widget.actions.onEleves;

  /// Le bouton « Eleves », R et la « Reduire » de la colonne. La colonne
  /// tient : la replier ou la deplier (etat local) ; sinon le panneau
  /// temporaire de la page, comme avant.
  void _basculerParticipants() {
    if (!_gaucheTient) {
      widget.actions.onEleves?.call();
      return;
    }
    final bool replier = _composition().gauche == PlacePanneau.colonne;
    setState(() => _participantsReplies = replier);
    // Ouverte avant le redimensionnement (panneau temporaire de la page) :
    // la page la ferme aussi, sinon elle reviendrait.
    if (replier && widget.vue.panneau == PanneauOuvert.eleves) {
      widget.actions.onEleves?.call();
    }
    if (replier) {
      // Le focus revient au bouton qui la rouvre (pose au cadre suivant).
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _focusEleves.context != null) {
          _focusEleves.requestFocus();
        }
      });
    }
  }

  /// Le rappel de la page qui bascule un panneau droit.
  VoidCallback? _basculeDroite(PanneauOuvert panneau) => switch (panneau) {
    PanneauOuvert.commandes => widget.actions.onCommandes,
    PanneauOuvert.supports => widget.actions.onSupports,
    PanneauOuvert.ressources => widget.actions.onBibliotheque,
    PanneauOuvert.eleves || PanneauOuvert.aucun => null,
  };

  /// TB-5 (UX-14 a UX-16, plan V2 §18.1) : Focus replie les deux cotes
  /// (le panneau droit se ferme, les Participants se retirent) ; Quitter le
  /// focus restaure la composition d'avant si elle tient en colonnes a la
  /// largeur actuelle. Etat local seulement.
  void _basculerFocus() {
    final VoidCallback? agrandir = widget.actions.onAgrandir;
    if (agrandir == null) return;
    final PanneauOuvert panneau = widget.vue.panneau;
    if (!widget.local.agrandi) {
      _avantFocus = estPanneauDroit(panneau) ? panneau : PanneauOuvert.aucun;
      if (estPanneauDroit(panneau)) _basculeDroite(panneau)?.call();
      agrandir();
      return;
    }
    agrandir();
    final PanneauOuvert? aBasculer = panneauABasculerEnSortie(
      avantFocus: _avantFocus,
      actuel: panneau,
      droiteTient:
          _composition(panneau: _avantFocus, agrandi: false).droite ==
          PlacePanneau.colonne,
    );
    _avantFocus = PanneauOuvert.aucun;
    if (aBasculer != null) _basculeDroite(aBasculer)?.call();
  }

  /// Les rappels de la page, Focus et sa sortie passes par [_basculerFocus].
  ActionsSeance get _actions => widget.actions.onAgrandir == null
      ? widget.actions
      : widget.actions.avecAgrandir(_basculerFocus);

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
    if (widget.vue.panneau == PanneauOuvert.aucun) {
      // TB-5 (§18.3) : aucun panneau ouvert, Echap quitte le focus ; il ne
      // coupe jamais l'appel.
      if (_agrandi) _basculerFocus();
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
      // TB-5 : R replie ou deplie la colonne des Participants, a cote du
      // panneau droit ouvert ; jamais en focus (elle y est repliee).
      RaccourciSalle.eleves =>
        _participantsDisponibles && !_agrandi && _rappelParticipants != null,
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
        _basculerParticipants();
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
      actions: _actions,
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext _, BoxConstraints c) {
      _largeur = c.maxWidth;
      _facteurTexte = MediaQuery.textScalerOf(context).scale(1);
      return _salle(context);
    },
  );

  Widget _salle(BuildContext context) {
    // TB-5 (n. 12, remplace EN-9 « ouvert d'office a droite ») : la
    // composition dit ou se posent les Participants et le panneau droit ;
    // le contexte deplie depuis la capsule s'ouvre dans les Participants
    // (TB-3, CTX-01, CTX-02).
    final CompositionSalle composition = _composition();
    final VueSeance vue = widget.vue;
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
            if (ouvert || _agrandi)
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
                    actions: _actions,
                    local: widget.local,
                    gabarit: widget.gabarit,
                    composition: composition,
                    gaucheTient: _gaucheTient,
                    onParticipants: _rappelParticipants,
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

/// La salle de l'enseignant (CLV-06) : support dominant, Participants,
/// declencheur « Commandes » (TB-4) ; la barre de l'appel Micro, Camera,
/// Quitter est posee par-dessus (TB-2). Plus d'outils permanents ni de
/// pagination sous le support : ils vivent dans les Commandes (plan V2 §4.2,
/// UX_REVIEW_TB n. 10, n. 11).
///
/// TB-5 (UI-02, UI-03 ; plan V2 §6, §19.4) : hors telephone, Participants a
/// gauche, surface au centre, panneau pedagogique a droite seulement s'il est
/// ouvert ; la [composition] dit pour chaque cote colonne, panneau
/// temporaire ou rien. Au telephone, un seul panneau secondaire, en feuille.
class _SalleEnseignant extends StatelessWidget {
  const _SalleEnseignant({
    required this.vue,
    required this.actions,
    required this.local,
    required this.gabarit,
    required this.composition,
    required this.gaucheTient,
    required this.focusEleves,
    required this.focusCommandes,
    required this.focusSupport,
    this.onParticipants,
    this.focusCapsule,
    this.contenuSupport,
    this.agrandi = false,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final Gabarit gabarit;
  final Widget? contenuSupport;

  /// TB-5 : ou se posent les Participants et le panneau droit.
  final CompositionSalle composition;

  /// TB-5 : la colonne des Participants tient a cette largeur ; repliee, son
  /// bouton se pose au bord de debut, au-dessus de la surface.
  final bool gaucheTient;

  /// TB-5 : le bouton « Eleves » et la « Reduire » de la colonne (replier,
  /// deplier) ; `null` : pas de liste, pas de bouton.
  final VoidCallback? onParticipants;

  /// TB-4 : le focus local (Commandes > Focus) replie les Participants ;
  /// capsule, Commandes et barre restent.
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
    // Le support partage la hauteur avec les boutons, il se resserre pour
    // montrer la diapositive entiere.
    final Widget support = Focus(
      focusNode: focusSupport,
      child: ZoneSupport(
        vue: vue,
        zoom: local.zoom,
        serre: true,
        contenu: contenuSupport,
      ),
    );
    // TB-9 : la portee du rangement (depart : la feuille de la surface ;
    // arrivee : la Bibliotheque des Commandes).
    return PorteeRangement(
      child: gabarit == Gabarit.mobile
          ? _telephone(support)
          : _large(context, support),
    );
  }

  /// TB-4 : le declencheur « Commandes », rendu seulement si une entree du
  /// panneau a un rappel (UX_REVIEW_TB §3 bis).
  ///
  /// Commandes ouvertes, il s'efface : le panneau porte deja le titre
  /// « Commandes » et sa « Reduire » (une seule entree visible, revue du
  /// 09/10) ; il revient a la fermeture, ou le focus le retrouve.
  ///
  /// TB-7b (plan V2 §4.2) : panneau ferme pendant l'ecriture, la palette
  /// courte (outil actif, Annuler, Terminer) prend sa place, et « Commandes »
  /// devient le dernier bouton de la palette, ou reparaissent les autres
  /// outils. Une seule rangee : au telephone, la hauteur reste a la page au
  /// moment ou l'on ecrit (une palette posee au-dessus du declencheur la
  /// reduisait de moitie a 320 x2).
  ///
  /// Verification TB-5 (10/10) : en focus hors telephone, le declencheur au
  /// repos monte dans la tete, a cote de la capsule ([auRepos] seul), et la
  /// palette reste sous la surface ([enEcriture] seul, precedee de
  /// [ecartAvant]) : aucune rangee sous la page tant qu'on n'ecrit pas.
  Widget? _declencheur({
    bool auRepos = true,
    bool enEcriture = true,
    double ecartAvant = 0,
  }) {
    final VoidCallback? basculer = actions.onCommandes;
    if (basculer == null ||
        vue.panneau == PanneauOuvert.commandes ||
        !CommandesPedagogiques.aDesEntrees(vue, actions)) {
      return null;
    }
    return Consumer(
      builder: (BuildContext _, WidgetRef ref, Widget? enfant) =>
          !ecritSurLaSurface(ref, vue)
          ? enfant!
          : !enEcriture
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(top: ecartAvant),
              child: PaletteEcriture(
                vue: vue,
                onCommandes: basculer,
                focusCommandes: focusCommandes,
              ),
            ),
      child: auRepos
          ? DeclencheurCommandes(
              onPress: basculer,
              ouvert: vue.panneau == PanneauOuvert.commandes,
              focusNode: focusCommandes,
            )
          : const SizedBox.shrink(),
    );
  }

  /// Le panneau des Participants (Eleves), avec le contexte deplie de la
  /// capsule en tete (TB-3). Colonne : « Reduire » la replie (TB-5, n. 12,
  /// remplace EN-9 « ouvert d'office ») ; volet et feuille : la croix.
  Widget _panneauEleves(FormePanneau forme) {
    final bool colonne = forme == FormePanneau.colonne;
    // Contexte deplie : sa propre « Reduire » (TB-3) le replie ; la colonne
    // n'en ajoute pas une seconde.
    final VoidCallback? reduire = vue.contexteOuvert
        ? (colonne
              ? null
              : () => actions.onContexte?.call(ContexteOuvert.aucun))
        : colonne
        ? onParticipants
        : actions.onEleves;
    return PanneauSeance(
      // Colonne : le bouton « Eleves 1/3 » s'efface devant elle (K-42,
      // style 3) ; le compteur passe dans son en-tete.
      titre: colonne
          ? vue.compteurEleves ?? t.salle.seance.eleves
          : t.salle.seance.eleves,
      onFermer: reduire,
      libelleFermer: colonne ? t.salle.seance.contexte.reduire : null,
      semantiqueFermer: colonne ? vue.libelleReduireContexte : null,
      cleFermer: PanneauSeance.cleReduireParticipants,
      forme: forme,
      enMenu: !colonne,
      ajusteAuContenu: true,
      enfant: PanneauEleves(
        eleves: vue.eleves,
        actions: actions,
        // En colonne, le panneau montre toujours « File de recitation »
        // (maquettes enseignant, EN-9) ; ailleurs, file au repos : pas de
        // bloc, le panneau reste celui de CLV-07.
        recitation:
            colonne ||
                vue.recitation.enCours ||
                vue.recitation.suivants.isNotEmpty
            ? vue.recitation
            : null,
        large: colonne,
        serre: forme == FormePanneau.feuille,
        autorisationEcrire: vue.voitAutorisationEcrire,
        entete: vue.contexteOuvert
            ? SectionContexte(vue: vue, actions: actions)
            : null,
      ),
    );
  }

  /// Le panneau pedagogique (Commandes), Supports ou la Bibliotheque : le
  /// cote droit (TB-5, n. 13 : Supports y passe), ou `null`.
  Widget? _panneauDroit(FormePanneau forme) => switch (vue.panneau) {
    PanneauOuvert.aucun || PanneauOuvert.eleves => null,
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
    // la bibliotheque ». La salle reste ouverte.
    // TB-8 (LIB-01 a LIB-04) : la Bibliotheque unique (R14), apercu
    // personnel puis « Presenter » ; sans rappel Presenter, l'ancien
    // selecteur (Classe Live jusqu'a BR-1).
    PanneauOuvert.ressources => switch (actions.onPresenter) {
      final PresenterSupport presenter => PanneauSeance(
        titre: t.salle.seance.commandes.bibliotheque,
        onFermer: actions.onBibliotheque,
        forme: forme,
        enfant: BibliothequeSeance(
          onPresenter: presenter,
          groupeId: vue.groupeId,
          reprises: reprisesDe(vue),
        ),
      ),
      null => PanneauSeance(
        titre: t.salle.seance.supports,
        onFermer: actions.onBibliotheque,
        forme: forme,
        enfant: SelecteurRessources(supports: vue.supports, actions: actions),
      ),
    },
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

  /// A l'ouverture, le focus entre dans le panneau (si rien d'autre ne le
  /// tient) : Echap le ferme alors depuis le clavier.
  static Widget _focusDedans(Widget panneau) =>
      Focus(autofocus: true, skipTraversal: true, child: panneau);

  /// Le bouton « Eleves 1/3 › », ou `null` (focus, colonne deja posee, pas
  /// de liste).
  Widget? _bouton({required bool etire}) {
    if (agrandi || composition.gauche == PlacePanneau.colonne) return null;
    return _BoutonsPanneaux.ou(
      vue,
      onParticipants,
      etire: etire,
      focusEleves: focusEleves,
    );
  }

  /// Telephone : un seul panneau secondaire, feuille du bas qui laisse voir
  /// le haut du support (images CLV-07-08-10). Le contexte deplie s'ouvre
  /// dans le panneau des Participants (TB-3).
  Widget _telephone(Widget support) {
    const double gouttiere = AppPage.gouttiereMobile;
    final Widget tete = agrandi
        ? _teteFocus()
        : TeteSalleBornee(
            children: <Widget>[
              ChromeSeance(
                vue: vue,
                actions: actions,
                focusCapsule: focusCapsule,
              ),
              BandeauSecours(vue: vue, actions: actions),
            ],
          );
    final Widget? panneau = composition.gauche != PlacePanneau.aucune
        ? _panneauEleves(FormePanneau.feuille)
        : _panneauDroit(FormePanneau.feuille);
    if (panneau != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          tete,
          Ecart.vSm,
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext contexte, BoxConstraints c) => Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: gouttiere,
                      ),
                      child: support,
                    ),
                  ),
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
                            c.maxHeight + CommandesMasquables.margeDe(contexte),
                          ) -
                          CommandesMasquables.margeDe(contexte),
                    ),
                    child: _focusDedans(panneau),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    // TB-5 (plan V2 §6, « mobile immersif : aucun panneau permanent ») :
    // pendant le partage, l'avatar de la capsule ouvre deja les
    // Participants (TB-3) ; la rangee « Eleves » rendrait au support la
    // place qui lui manque a 320 x2 (reste de TB-4).
    final Widget? boutons = vue.voitCapsule ? null : _bouton(etire: true);
    final Widget? declencheur = _declencheur();
    // TB-6 (revue du 09/10) : sans support, la phrase du §12 est l'unique
    // consigne de l'ecran ; elle ne se rogne jamais. Sa hauteur est reservee
    // a la surface d'abord, la tete prend ce qui reste (elle defile alors en
    // fondu, TeteSalleBornee).
    if (!agrandi) {
      return LayoutBuilder(
        builder: (BuildContext contexte, BoxConstraints c) {
          final double reserve = hauteurMinimaleSurface(
            contexte,
            vue,
            largeur: c.maxWidth - 2 * gouttiere,
          );
          if (reserve <= 0) {
            return _pileTelephone(tete, boutons, support, declencheur);
          }
          return CustomMultiChildLayout(
            delegate: _PlaceTelephone(
              surfaceMinimale: reserve,
              ecart: AppSpacing.sm,
            ),
            children: <Widget>[
              LayoutId(id: _PieceTelephone.tete, child: tete),
              if (boutons != null)
                LayoutId(
                  id: _PieceTelephone.boutons,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                    child: boutons,
                  ),
                ),
              LayoutId(
                id: _PieceTelephone.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                  child: support,
                ),
              ),
              if (declencheur != null)
                LayoutId(
                  id: _PieceTelephone.declencheur,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: gouttiere),
                    child: Align(heightFactor: 1, child: declencheur),
                  ),
                ),
            ],
          );
        },
      );
    }
    return _pileTelephone(tete, boutons, support, declencheur);
  }

  /// La pile du telephone sans panneau : tete, rangee « Eleves », surface,
  /// declencheur.
  Widget _pileTelephone(
    Widget tete,
    Widget? boutons,
    Widget support,
    Widget? declencheur,
  ) {
    const double gouttiere = AppPage.gouttiereMobile;
    // Les ecarts entre les rangees se resserrent d'un palier, la place
    // revient au support (image mobile, enseignant).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        tete,
        Ecart.vSm,
        if (boutons != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: boutons,
          ),
          Ecart.vSm,
        ],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: support,
          ),
        ),
        // TB-4 : le declencheur, pres du bas, au-dessus de la zone de la
        // barre de l'appel (posee par-dessus, TB-2) ; centre (planche 1).
        if (declencheur != null) ...<Widget>[
          Ecart.vSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: gouttiere),
            child: Align(child: declencheur),
          ),
        ],
      ],
    );
  }

  /// Tablette et bureau (TB-5, plan V2 §6, §19.4) : Participants a gauche
  /// (colonne si la largeur divisee par le texte le permet), surface au
  /// centre, panneau droit seulement s'il est ouvert. Un panneau qui ne
  /// tient pas en colonne passe par-dessus la surface (volet), sans la
  /// comprimer ; aucune colonne vide.
  Widget _large(BuildContext context, Widget support) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool desktop = gabarit == Gabarit.desktop;
    final PlacePanneau gauche = composition.gauche;
    final PlacePanneau droite = composition.droite;
    final Widget? panneauGauche = gauche == PlacePanneau.aucune
        ? null
        : _panneauEleves(
            gauche == PlacePanneau.colonne
                ? FormePanneau.colonne
                : FormePanneau.volet,
          );
    final Widget? panneauDroit = _panneauDroit(
      droite == PlacePanneau.colonne
          ? FormePanneau.colonne
          : FormePanneau.volet,
    );
    // Un panneau temporaire remplace le bouton « Eleves » et le declencheur
    // (images CLV-07-08-10) ; repliee, la colonne laisse son bouton au bord
    // de debut, a sa place.
    final bool recouvre = composition.recouvre;
    final Widget? boutons = recouvre ? null : _bouton(etire: !gaucheTient);
    // En focus, sous la surface ne reste que la palette pendant l'ecriture ;
    // le declencheur au repos passe dans la tete (verification TB-5).
    final Widget? declencheur = recouvre
        ? null
        : agrandi
        ? _declencheur(auRepos: false, ecartAvant: AppSpacing.md)
        : _declencheur();
    final Widget centre = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (boutons != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: gaucheTient
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: boutons,
                  )
                : boutons,
          ),
        Expanded(
          child: _sousSupport(support, declencheur, ecart: !agrandi),
        ),
      ],
    );
    // Les colonnes, puis les volets par-dessus toute la largeur utile : un
    // panneau temporaire garde sa largeur (image : ≈ 313) et la colonne des
    // Participants reste visible a cote de lui.
    final Widget colonnes = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (gauche == PlacePanneau.colonne &&
            panneauGauche != null) ...<Widget>[
          SizedBox(
            width: largeurColonneSeance,
            child: _focusDedans(panneauGauche),
          ),
          Ecart.hMd,
        ],
        Expanded(child: centre),
        if (droite == PlacePanneau.colonne && panneauDroit != null) ...<Widget>[
          Ecart.hMd,
          SizedBox(
            width: largeurColonneSeance,
            child: _focusDedans(panneauDroit),
          ),
        ],
      ],
    );
    final Widget enMarge = Padding(
      padding: const EdgeInsets.symmetric(horizontal: gouttiere),
      child: colonnes,
    );
    final Widget corps = !recouvre
        ? enMarge
        : LayoutBuilder(
            builder: (BuildContext _, BoxConstraints c) {
              // Volet : au plus la moitie de la largeur, moins un palier.
              final double largeurVolet = math.min(
                largeurPanneauSeance,
                c.maxWidth / 2 - AppSpacing.lg,
              );
              return Stack(
                children: <Widget>[
                  Positioned.fill(child: enMarge),
                  // Le volet descend jusqu'au bas de l'ecran (image).
                  if (gauche == PlacePanneau.temporaire &&
                      panneauGauche != null)
                    PositionedDirectional(
                      start: AppSpacing.sm,
                      top: 0,
                      bottom: 0,
                      width: largeurVolet,
                      child: _focusDedans(panneauGauche),
                    ),
                  if (droite == PlacePanneau.temporaire && panneauDroit != null)
                    PositionedDirectional(
                      end: AppSpacing.sm,
                      top: 0,
                      bottom: 0,
                      width: largeurVolet,
                      child: _focusDedans(panneauDroit),
                    ),
                ],
              );
            },
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // TB-5 (plan V2 §19.4.3, §6 « capsule minimale ») : en focus, l'en-tete
        // se retire comme chez l'eleve ; restent la capsule compacte et l'etat
        // critique.
        if (agrandi) ...<Widget>[
          _teteFocus(
            declencheur: recouvre ? null : _declencheur(enEcriture: false),
          ),
        ] else if (desktop) ...<Widget>[
          ChromeSeance(vue: vue, actions: actions, focusCapsule: focusCapsule),
          BandeauSecours(
            vue: vue,
            actions: actions,
            espaceApres: AppSpacing.md,
          ),
        ] else ...<Widget>[
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
          Ecart.vMd,
        ],
        Expanded(child: corps),
      ],
    );
  }

  /// La cle de la tete du focus (capsule compacte et etat critique).
  static const Key cleTeteFocus = ValueKey<String>('tete-focus');

  /// TB-5 (plan V2 §19.4.3) : en focus, ne subsistent que le contenu, la
  /// capsule compacte, l'acces aux Commandes et la sortie du focus (barre de
  /// l'appel). Ni titre, ni sous-titre, ni mention, ni coin de l'en-tete ;
  /// l'etat critique (reconnexion, echec) reste visible (CL-7 §2.7).
  ///
  /// Hors telephone, le [declencheur] au repos se pose sur la meme rangee,
  /// avant la capsule (bord de fin) : il ne prend plus de rangee sous la
  /// surface, la page grandit (verification TB-5, UX-14).
  Widget _teteFocus({Widget? declencheur}) => Column(
    key: cleTeteFocus,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppPage.gouttiereMobile,
          AppSpacing.sm,
          AppPage.gouttiereMobile,
          AppSpacing.sm,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (declencheur != null) ...<Widget>[declencheur, Ecart.hMd],
              CapsuleSeance(
                vue: vue,
                actions: actions,
                focusAvatar: focusCapsule,
              ),
            ],
          ),
        ),
      ),
      BandeauSecours(vue: vue, actions: actions, espaceApres: AppSpacing.sm),
    ],
  );

  /// Le declencheur « Commandes » sous le support, au bord de fin (plan V2
  /// §4.2 : « bord droit de la surface ») ; la barre de l'appel est posee
  /// par-dessus, plus bas (TB-2).
  ///
  /// [ecart] faux (focus) : la palette porte son propre ecart, rien n'est
  /// reserve sous la surface tant qu'on n'ecrit pas.
  Widget _sousSupport(
    Widget support,
    Widget? declencheur, {
    bool ecart = true,
  }) {
    if (declencheur == null) return support;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: support),
        Padding(
          padding: EdgeInsets.only(top: ecart ? AppSpacing.md : 0),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: declencheur,
          ),
        ),
      ],
    );
  }
}

/// Les pieces de la salle du telephone sans panneau.
enum _PieceTelephone { tete, boutons, surface, declencheur }

/// TB-6 (revue du 09/10) : la pile du telephone quand la surface porte la
/// phrase du §12. Comme la colonne (tete, rangee « Eleves », surface,
/// declencheur, ecarts de [ecart]), mais la surface garde au moins
/// [surfaceMinimale] : la tete, deja bornee a 55 % de l'ecran, cede d'abord
/// sa hauteur (elle defile en elle-meme, en fondu).
class _PlaceTelephone extends MultiChildLayoutDelegate {
  _PlaceTelephone({required this.surfaceMinimale, required this.ecart});

  final double surfaceMinimale;
  final double ecart;

  @override
  void performLayout(Size size) {
    final double l = size.width;
    final BoxConstraints rangee = BoxConstraints(
      minWidth: l,
      maxWidth: l,
      maxHeight: size.height,
    );
    final double hBoutons = hasChild(_PieceTelephone.boutons)
        ? layoutChild(_PieceTelephone.boutons, rangee).height + ecart
        : 0;
    final double hDeclencheur = hasChild(_PieceTelephone.declencheur)
        ? layoutChild(_PieceTelephone.declencheur, rangee).height + ecart
        : 0;
    final double resteTete = math.max(
      0,
      size.height - hBoutons - hDeclencheur - ecart - surfaceMinimale,
    );
    final double hTete = layoutChild(
      _PieceTelephone.tete,
      BoxConstraints(minWidth: l, maxWidth: l, maxHeight: resteTete),
    ).height;
    final double hSurface = math.max(
      0,
      size.height - hTete - ecart - hBoutons - hDeclencheur,
    );
    layoutChild(
      _PieceTelephone.surface,
      BoxConstraints.tightFor(width: l, height: hSurface),
    );
    double y = 0;
    positionChild(_PieceTelephone.tete, Offset(0, y));
    y += hTete + ecart;
    if (hasChild(_PieceTelephone.boutons)) {
      positionChild(_PieceTelephone.boutons, Offset(0, y));
      y += hBoutons;
    }
    positionChild(_PieceTelephone.surface, Offset(0, y));
    y += hSurface + ecart;
    if (hasChild(_PieceTelephone.declencheur)) {
      positionChild(_PieceTelephone.declencheur, Offset(0, y));
    }
  }

  @override
  bool shouldRelayout(_PlaceTelephone ancien) =>
      ancien.surfaceMinimale != surfaceMinimale || ancien.ecart != ecart;
}

/// « Eleves 1/3 › » : enseignant seulement. TB-5 : colonne des Participants
/// repliee, au bord de debut au-dessus de la surface ; ailleurs, sur toute la
/// largeur au-dessus du support. La Bibliotheque est dans les Commandes
/// (TB-4).
class _BoutonsPanneaux extends StatelessWidget {
  const _BoutonsPanneaux({
    required this.compteur,
    required this.onEleves,
    required this.etire,
    this.panneau = PanneauOuvert.aucun,
    this.focusEleves,
  });

  static Widget? ou(
    VueSeance vue,
    VoidCallback? onEleves, {
    required bool etire,
    FocusNode? focusEleves,
  }) {
    final String? compteur = vue.compteurEleves;
    if (!vue.voitBoutonsPanneaux || compteur == null || onEleves == null) {
      return null;
    }
    return _BoutonsPanneaux(
      compteur: compteur,
      onEleves: onEleves,
      etire: etire,
      panneau: vue.panneau,
      focusEleves: focusEleves,
    );
  }

  /// Le panneau ouvert : son bouton se dit selectionne.
  final PanneauOuvert panneau;
  final FocusNode? focusEleves;

  final String compteur;
  final VoidCallback onEleves;
  final bool etire;

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
    );
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
class TeteSalleBornee extends StatefulWidget {
  /// Cree la tete.
  const TeteSalleBornee({required this.children, super.key});

  /// La part maximale de la hauteur de l'ecran. Au-dessus du tiers que
  /// prend deja le bloc d'echec (lui-meme borne et defilant), pour qu'a
  /// 100 % en-tete et bloc restent visibles ensemble.
  static const double part = 0.55;

  /// La cle du defilement de la tete.
  static const Key defilementKey = ValueKey<String>('tete-salle-defile');

  /// La cle du fondu pose au bas de la tete quand elle defile.
  static const Key cleFondu = ValueKey<String>('tete-salle-fondu');

  /// La cle du fondu pose en haut de la tete quand elle a defile.
  static const Key cleFonduHaut = ValueKey<String>('tete-salle-fondu-haut');

  /// L'en-tete, le bandeau, l'appel.
  final List<Widget> children;

  @override
  State<TeteSalleBornee> createState() => _TeteSalleBorneeState();
}

class _TeteSalleBorneeState extends State<TeteSalleBornee> {
  /// La tete a encore du contenu sous son bord bas.
  bool _suite = false;

  /// La tete a deja defile : du contenu est au-dessus de son bord haut.
  bool _avant = false;

  /// TB-11b (tour 3) : le rang de l'enfant qui porte l'etat critique, pose
  /// en premier parce qu'il ne tenait pas a sa place ; `null` sinon.
  int? _enTete;

  /// Le defilement garde sa position quand un fondu se pose ou se retire.
  final GlobalKey _cleDefile = GlobalKey(debugLabel: 'tete-salle');

  bool _mesurer(ScrollMetricsNotification n) {
    _suivre(n.metrics);
    return false;
  }

  bool _defiler(ScrollUpdateNotification n) {
    _suivre(n.metrics);
    return false;
  }

  void _suivre(ScrollMetrics m) {
    final bool suite = m.extentAfter > 0.5;
    final bool avant = m.extentBefore > 0.5;
    if (suite != _suite || avant != _avant) {
      setState(() {
        _suite = suite;
        _avant = avant;
      });
    }
  }

  /// Le rang, dans [TeteSalleBornee.children], de l'enfant qui contient
  /// [cible], ou `null`.
  int? _rang(BuildContext cible) {
    int? rang;
    cible.visitAncestorElements((Element e) {
      final Key? cle = e.widget.key;
      if (cle is _RangTete) {
        rang = cle.value;
        return false;
      }
      return !identical(e.widget, widget);
    });
    return rang;
  }

  /// TB-11b (tours 2 et 3) : l'etat critique ([cible], le bandeau de
  /// secours) se voit toujours en entier, hors du fondu : « une alerte
  /// urgente va toujours en tete, avant tout autre bloc ». S'il ne tient pas
  /// a sa place (texte a 200 %, ecran etroit), il passe en premier dans la
  /// tete et la tete revient a son debut : aucune ligne n'est laissee
  /// coupee a son bord haut (revue du tour 2 : un defilement arrete au
  /// milieu d'une ligne la rognait). L'en-tete suit, sous lui, et se relit
  /// en faisant defiler la tete (fondus bas et haut). S'il se voit deja en
  /// entier, rien ne bouge.
  void montrer(BuildContext cible) {
    final RenderObject? objet = cible.findRenderObject();
    final ScrollableState? defile = Scrollable.maybeOf(cible);
    if (objet is! RenderBox || !objet.hasSize || defile == null) return;
    final RenderObject? cadre = defile.context.findRenderObject();
    if (cadre is! RenderBox || !cadre.hasSize) return;
    final ScrollPosition position = defile.position;
    final Offset haut = objet.localToGlobal(Offset.zero, ancestor: cadre);
    // Le fondu couvre le bas de la tete tant qu'il reste a lire dessous.
    final double fondu = position.extentAfter > 0.5 ? AppSpacing.xxxl : 0;
    final bool entier =
        haut.dy >= -0.5 &&
        haut.dy + objet.size.height <= cadre.size.height - fondu + 0.5;
    if (entier) return;
    final int? rang = _rang(cible);
    if (rang != null && rang != _enTete) setState(() => _enTete = rang);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || !position.hasPixels) return;
      position.jumpTo(position.minScrollExtent);
    });
  }

  /// L'etat critique est parti : la tete reprend son ordre.
  void relacher() {
    if (_enTete != null) setState(() => _enTete = null);
  }

  /// Un fondu de [AppSpacing.xxxl] au bord bas ([versLeBas]) ou haut.
  Widget _fondre(
    Key cle,
    Color fond, {
    required bool versLeBas,
    required Widget child,
  }) => ShaderMask(
    key: cle,
    blendMode: BlendMode.dstIn,
    shaderCallback: (Rect r) => LinearGradient(
      begin: versLeBas ? Alignment.topCenter : Alignment.bottomCenter,
      end: versLeBas ? Alignment.bottomCenter : Alignment.topCenter,
      stops: <double>[
        if (r.height <= 0) 0 else math.max(0, 1 - AppSpacing.xxxl / r.height),
        1,
      ],
      colors: <Color>[fond, fond.withValues(alpha: 0)],
    ).createShader(r),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final List<Widget> enfants = <Widget>[
      for (int i = 0; i < widget.children.length; i++)
        KeyedSubtree(key: _RangTete(i), child: widget.children[i]),
    ];
    final int? enTete = _enTete;
    if (enTete != null && enTete > 0 && enTete < enfants.length) {
      enfants.insert(0, enfants.removeAt(enTete));
    }
    final Widget defile = KeyedSubtree(
      key: _cleDefile,
      child: SingleChildScrollView(
        key: TeteSalleBornee.defilementKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: enfants,
        ),
      ),
    );
    // Revue du 09/10 : quand la tete ne tient pas (texte a 200 %, ecran
    // etroit, place laissee a la phrase du §12), son bas s'efface en fondu :
    // une ligne coupee se lit comme une suite a faire defiler, jamais comme
    // un texte rogne. TB-11b (tour 3) : de meme a son bord haut, des qu'elle
    // a defile.
    final Color fond = AppPalette.of(context).surfaceCanvas.background;
    Widget contenu = defile;
    if (_suite) {
      contenu = _fondre(
        TeteSalleBornee.cleFondu,
        fond,
        versLeBas: true,
        child: contenu,
      );
    }
    if (_avant) {
      contenu = _fondre(
        TeteSalleBornee.cleFonduHaut,
        fond,
        versLeBas: false,
        child: contenu,
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * TeteSalleBornee.part,
      ),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: _defiler,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _mesurer,
          child: contenu,
        ),
      ),
    );
  }
}

/// Le rang d'un enfant de la tete : il garde son etat quand l'ordre change.
class _RangTete extends ValueKey<int> {
  const _RangTete(super.value);
}

class BandeauSecours extends StatefulWidget {
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
  State<BandeauSecours> createState() => _BandeauSecoursState();
}

class _BandeauSecoursState extends State<BandeauSecours> {
  VueSeance get vue => widget.vue;
  ActionsSeance get actions => widget.actions;
  double get gouttiere => widget.gouttiere;
  double get espaceApres => widget.espaceApres;

  /// L'etat dit (bloc d'echec ou bandeau), ou `null`.
  static String? _etat(VueSeance vue) => vue.titreEchec ?? vue.texteBandeau;

  @override
  void initState() {
    super.initState();
    if (_etat(vue) != null) _montrer();
  }

  @override
  void didUpdateWidget(BandeauSecours ancien) {
    super.didUpdateWidget(ancien);
    final String? etat = _etat(vue);
    if (etat != null && etat != _etat(ancien.vue)) _montrer();
    if (etat == null && _etat(ancien.vue) != null) _relacher();
  }

  /// TB-11b (tour 3) : l'etat parti, la tete reprend son ordre.
  void _relacher() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || _etat(vue) != null) return;
      context.findAncestorStateOfType<_TeteSalleBorneeState>()?.relacher();
    });
  }

  /// TB-11b (tour 2) : dans la tete bornee du telephone, un etat qui
  /// apparait n'est jamais laisse sous son bord ni sous son fondu
  /// ([TeteSalleBornee]) ; ailleurs, rien a faire (pas de tete qui defile).
  void _montrer() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || _etat(vue) == null) return;
      context.findAncestorStateOfType<_TeteSalleBorneeState>()?.montrer(
        context,
      );
    });
  }

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
        // ligne (P06.5). TB-11b : l'etat du tableau non plus (l'appel
        // continue) ; son icone dit ce qui manque.
        icone: vue.connexion == ConnexionSeance.reseauFaible
            ? AppIcons.reseau.repos
            : vue.bandeauDitTableau
            ? _iconeTableau(vue)
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
            // L'etat a fini de grandir : sa taille vraie decide du defilement.
            onEnd: _montrer,
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

/// TB-11b : l'icone de l'etat du tableau. Nouvelle encre non partagee : en
/// attente d'envoi ; reprise ou reconnexion du tableau : reconnexion ;
/// notes non sauvegardees : avertissement.
IconData _iconeTableau(VueSeance vue) {
  if (vue.encreNonPartagee) return AppIcons.enAttenteEnvoi.repos;
  if (vue.synchroTableau != SynchroTableau.partage) {
    return AppIcons.reconnexion.repos;
  }
  return AppIcons.avertissement.repos;
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
