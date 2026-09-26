// La salle de seance unique (plan de code section 2).
//
// Un gabarit, parametre par la `VueSeance` du role effectif : plein ecran,
// sans barre d'application (I-8). Dispositions par `Gabarit` : compacte
// (< 600), moyenne (600-1199), large (>= 1200).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
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
import 'rail_seance.dart';
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
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Le rendu reel du support partage (Classe Live :
  /// `ContexteClasseLive.support`). `null` : la salle rend elle-meme
  /// `vue.support` (demonstration).
  final Widget? contenuSupport;

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
          child: _FocusPanneaux(
            vue: vue,
            actions: actions,
            local: local,
            gabarit: gabarit,
            contenuSupport: contenuSupport,
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
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final Gabarit gabarit;
  final Widget? contenuSupport;

  @override
  State<_FocusPanneaux> createState() => _FocusPanneauxState();
}

class _FocusPanneauxState extends State<_FocusPanneaux> {
  final FocusNode _focusEleves = FocusNode(debugLabel: 'bouton-eleves');
  final FocusNode _focusSupports = FocusNode(debugLabel: 'bouton-supports');

  @override
  void didUpdateWidget(_FocusPanneaux ancien) {
    super.didUpdateWidget(ancien);
    final PanneauOuvert avant = ancien.vue.panneau;
    if (avant == PanneauOuvert.aucun ||
        widget.vue.panneau != PanneauOuvert.aucun) {
      return;
    }
    final FocusNode bouton = avant == PanneauOuvert.eleves
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
    super.dispose();
  }

  void _fermer() {
    switch (widget.vue.panneau) {
      case PanneauOuvert.eleves:
        widget.actions.onEleves?.call();
      case PanneauOuvert.supports:
        widget.actions.onSupports?.call();
      case PanneauOuvert.aucun:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ouvert =
        widget.vue.voitBoutonsPanneaux &&
        widget.vue.panneau != PanneauOuvert.aucun;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (ouvert) const SingleActivator(LogicalKeyboardKey.escape): _fermer,
      },
      child: _SalleEnseignant(
        vue: widget.vue,
        actions: widget.actions,
        local: widget.local,
        gabarit: widget.gabarit,
        contenuSupport: widget.contenuSupport,
        focusEleves: _focusEleves,
        focusSupports: _focusSupports,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    const double gouttiere = AppPage.gouttiereMobile;
    final bool outils = vue.voitOutils && actions.onOutil != null;
    // Telephone et desktop : le support partage la hauteur avec les boutons
    // et les outils, il se resserre pour montrer la diapositive entiere.
    final Widget support = ZoneSupport(
      vue: vue,
      zoom: local.zoom,
      serre: true,
      contenu: contenuSupport,
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
              ),
            ),
          ],
        );
    }
  }

  /// Desktop : le rail enseignant a gauche, s'il a un rappel.
  Widget _avecRail(Widget contenu) {
    final ValueChanged<String>? naviguer = actions.onNaviguer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (vue.voitRail(gabarit) && naviguer != null)
          RailSeance(onNaviguer: naviguer, groupeId: vue.groupeId),
        Expanded(child: contenu),
      ],
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
        titre: t.salle.seance.eleves,
        onFermer: actions.onEleves,
        forme: forme,
        // Image CLV-07 desktop : menu « … » et colonne ajustee a la liste.
        enMenu: true,
        ajusteAuContenu: true,
        enfant: PanneauEleves(
          eleves: vue.eleves,
          actions: actions,
          // File au repos (personne, personne a suivre) : pas de bloc, le
          // panneau reste celui de CLV-07.
          recitation:
              vue.recitation.enCours || vue.recitation.suivants.isNotEmpty
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
    final Widget? carteOutils = outils
        // Images CLV-07 et CLV-08 : aucun outil selectionne.
        ? OutilsEnseignement(
            onOutil: actions.onOutil,
            forme: FormeOutils.carte,
            initial: null,
          )
        : null;
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
                SizedBox(width: largeurColonneSeance, child: panneau),
                Ecart.hMd,
                Expanded(child: support),
                Ecart.hMd,
                SizedBox(
                  width: largeurColonneDroiteSeance,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ?boutons,
                      if (carteOutils != null) ...<Widget>[
                        Ecart.vLg,
                        carteOutils,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // La barre basse part juste apres le bas du panneau (image : ≈ 580
        // a 1440 de large), la ou la colonne elargie laisse sa place.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            gouttiere + largeurPanneauSeance,
            AppSpacing.xl,
            gouttiere,
            AppSpacing.lg,
          ),
          // Pres du bas du gabarit desktop (1200 a 1400), la rangee se
          // reduit d'un bloc plutot que de deborder, comme sur CLV-08.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
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
    if (actions.onEleves == null && actions.onSupports == null) return null;
    return _BoutonsPanneaux(
      compteur: compteur,
      onEleves: actions.onEleves,
      onSupports: actions.onSupports,
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
      actionsContratB: true,
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
