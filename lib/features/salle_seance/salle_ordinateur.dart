// Plan de composition du 26/10/2026, valide par le directeur a 08:40
// (docs/current/maquettes/salle/PLAN-SALLE-COMPOSITION-2026-10-26.md §2) :
// la salle de l'enseignant sur ordinateur, a 840 points et plus.
//
// « Rien ne vient au milieu » : la page du Coran ou le tableau occupe le
// centre ; a gauche la video de l'enseignant et ses Eleves, a droite la
// Bibliotheque, en bas les commandes nommees, toujours au meme endroit. Le
// focus (bouton du centre, touche F) retire le haut et les deux panneaux ;
// la barre du bas reste. Remplace sur ordinateur la loi K4 du 25/10 (tout en
// surimpression) : la decision du directeur du 26/10 est la plus recente.
//
// Rien de neuf sous le capot : la page est [pageSalle] (celle du
// telephone), la scene [ZoneSupport], la video [VignetteVideo], les Eleves
// [PanneauEleves], les Commandes [CommandesPedagogiques], les commandes
// d'appel [DockSeance] et [BoutonAppel].

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/local_feedback.dart';
import 'actions_seance.dart';
import 'barre_outils_salle.dart';
import 'barre_support.dart' show NomsFocus, nomsFocus;
import 'commandes_pedagogiques.dart';
import 'dock_seance.dart';
import 'media_salle.dart';
import 'outils_enseignement.dart';
import 'panneau_bibliotheque_salle.dart';
import 'panneau_eleves.dart';
import 'panneau_seance.dart' show largeurPanneauSeance;
import 'pilule_etat_salle.dart';
import 'salle_seance.dart'
    show BandeauSecours, EtatLocalSeance, RaccourcisPleinEcran;
import 'telephone_plein_ecran.dart';
import 'vignette_video.dart' show MesuresVignette, VignetteVideo;
import 'vue_seance.dart';
import 'zone_support.dart' show ZoneSupport, surfaceAMontrer;

/// Vrai quand `/salle` montre la composition a trois panneaux : enseignant,
/// fenetre de 840 points et plus (plan §2). En dessous, la composition du
/// telephone ([TelephonePleinEcran]).
bool salleOrdinateur(BuildContext context, VueSeance vue) =>
    pleinEcranSalle(context) &&
    vue.role == RoleSeance.enseignant &&
    MediaQuery.sizeOf(context).width >= AppGabarit.seuilEtendu;

/// La largeur du panneau de gauche : la video de l'enseignant et ses Eleves
/// (300, plan §2).
const double largeurPanneauGauche =
    AppSpacing.respiration * 4 + AppSpacing.section + AppSpacing.xs;

/// La largeur du panneau de droite : la Bibliotheque (320, plan §2).
const double largeurPanneauDroit = largeurPanneauSeance;

/// La salle de l'enseignant sur ordinateur.
class SalleOrdinateur extends StatefulWidget {
  const SalleOrdinateur({
    required this.vue,
    required this.actions,
    required this.local,
    this.raccourcis = false,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Les raccourcis M, V, R, B et F (preference locale).
  final bool raccourcis;

  /// Les cles des zones (tests, captures).
  static const Key cleHaut = ValueKey<String>('salle-ordinateur-haut');
  static const Key cleGauche = ValueKey<String>('salle-ordinateur-gauche');
  static const Key cleCentre = ValueKey<String>('salle-ordinateur-centre');
  static const Key cleDroite = ValueKey<String>('salle-ordinateur-droite');
  static const Key cleBas = ValueKey<String>('salle-ordinateur-bas');
  static const Key cleFocus = ValueKey<String>('salle-ordinateur-focus');

  @override
  State<SalleOrdinateur> createState() => _EtatSalleOrdinateur();
}

class _EtatSalleOrdinateur extends State<SalleOrdinateur> {
  static const String _cleEleves = 'salle-ordinateur-eleves';
  static const String _cleBibliotheque = 'salle-ordinateur-bibliotheque';

  /// L'etat d'un panneau, garde le temps de la seance (stockage de la
  /// route, comme le coin de la vignette).
  bool _lire(String cle, bool defaut) =>
      PageStorage.maybeOf(context)?.readState(context, identifier: cle)
          as bool? ??
      defaut;

  void _basculer(String cle, bool defaut) => _poser(cle, !_lire(cle, defaut));

  void _poser(String cle, bool ouvert) {
    PageStorage.maybeOf(context)?.writeState(context, ouvert, identifier: cle);
    setState(() {});
  }

  /// Bibliotheque demandee (tuile ou touche B). Revue de la PR 61 : quand les
  /// Commandes occupent la droite, elles se ferment et la Bibliotheque
  /// s'ouvre, au lieu d'un drapeau bascule sans effet visible.
  void _bibliotheque() {
    if (widget.vue.panneau == PanneauOuvert.commandes) {
      widget.actions.onCommandes?.call();
      _poser(_cleBibliotheque, true);
    } else {
      _basculer(_cleBibliotheque, _bibliothequeDefaut);
    }
  }

  /// La Bibliotheque est ouverte d'office quand la page garde au moins la
  /// moitie de la largeur (1200 et plus) ; sinon B ou le bouton l'ouvre.
  bool get _bibliothequeDefaut =>
      MediaQuery.sizeOf(context).width >= AppGabarit.seuilDesktop;

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final EtatLocalSeance local = widget.local;
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final bool focus = local.agrandi;
    final bool eleves = _lire(_cleEleves, true);
    final bool bibliotheque = _lire(_cleBibliotheque, _bibliothequeDefaut);
    final bool peutBibliotheque = widget.actions.onBibliotheque != null;
    final ActionsSeance actions = widget.actions.avecPanneaux(
      onEleves: () => _basculer(_cleEleves, true),
      onBibliotheque: peutBibliotheque ? _bibliotheque : null,
    );
    final bool commandes = vue.panneau == PanneauOuvert.commandes;
    final Widget? droite = focus
        ? null
        : commandes
        ? _PanneauCommandes(vue: vue, actions: actions, local: local)
        : bibliotheque && peutBibliotheque
        ? PanneauBibliothequeSalle(
            supports: media?.supports ?? const <SupportBibliotheque>[],
            onFermer: () => _basculer(_cleBibliotheque, _bibliothequeDefaut),
          )
        : null;
    final AppPalette palette = AppPalette.of(context);
    final Widget salle = Material(
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!focus) ...<Widget>[
                _Haut(vue: vue, actions: actions),
                Ecart.vLg,
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: <Widget>[
                    if (!focus)
                      SizedBox(
                        key: SalleOrdinateur.cleGauche,
                        width: largeurPanneauGauche,
                        child: _PanneauGauche(
                          vue: vue,
                          actions: actions,
                          eleves: eleves,
                        ),
                      ),
                    Expanded(
                      child: _Centre(vue: vue, actions: actions, local: local),
                    ),
                    if (droite != null)
                      SizedBox(
                        key: SalleOrdinateur.cleDroite,
                        width: largeurPanneauDroit,
                        child: _Panneau(child: droite),
                      ),
                  ],
                ),
              ),
              // Plan §3 : quand l'enseignant ecrit, la barre d'outils au-dessus
              // des commandes, tout visible.
              Consumer(
                builder: (BuildContext _, WidgetRef ref, Widget? _) =>
                    barreOutilsVisible(ref, vue)
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Center(child: BarreOutilsSalle(vue: vue)),
                      )
                    : const SizedBox.shrink(),
              ),
              Ecart.vLg,
              _Bas(
                vue: vue,
                actions: actions,
                local: local,
                eleves: eleves,
                bibliotheque: bibliotheque && !commandes,
              ),
            ],
          ),
        ),
      ),
    );
    if (!widget.raccourcis) return salle;
    return RaccourcisPleinEcran(
      vue: vue,
      actions: actions,
      local: local,
      onEleves: actions.onEleves,
      child: salle,
    );
  }
}

/// Le fond commun des panneaux de cote : surface surelevee, filet, rayon.
class _Panneau extends StatelessWidget {
  const _Panneau({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiLg,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// Le haut : le nom de la Classe, « Sayyida Prenom », et la pilule d'etat
/// (« Visite de controle possible. ») au bord de fin.
class _Haut extends StatelessWidget {
  const _Haut({required this.vue, required this.actions});

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget? alerte = PorteeMediaSalle.de(context)?.alerte;
    final String classe = vue.nomClasse.isEmpty
        ? t.salle.seance.titre
        : vue.nomClasse;
    // « Sayyida Amina » : le nom de l'annuaire de la seance, deja titre
    // (sans titre connu, le prenom seul, jamais « Le professeur »).
    final String enseignant = vue.nomEnseignant;
    return Column(
      key: SalleOrdinateur.cleHaut,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          spacing: AppSpacing.lg,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    classe,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  if (enseignant.isNotEmpty)
                    Text(
                      enseignant,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: PiluleEtatSalle(vue: vue),
              ),
            ),
          ],
        ),
        BandeauSecours(vue: vue, actions: actions, gouttiere: 0),
        ?alerte,
      ],
    );
  }
}

/// Le panneau de gauche : la video de l'enseignant, fixee, puis « Eleves »
/// (une carte par eleve, qui se deplie sur place).
class _PanneauGauche extends StatelessWidget {
  const _PanneauGauche({
    required this.vue,
    required this.actions,
    required this.eleves,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final bool eleves;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? message = PorteeMediaSalle.de(context)?.messageEleves;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // La video garde au plus [_partVideo] de la hauteur : sur un
          // ordinateur de 768, les cartes des eleves restent visibles.
          Center(
            child: VignetteVideo(
              vue: vue,
              largeur: math.min(
                c.maxWidth,
                c.maxHeight * _partVideo * MesuresVignette.ratio,
              ),
            ),
          ),
          if (eleves) ...<Widget>[
            Ecart.vLg,
            Expanded(
              child: _Panneau(
                key: const ValueKey<String>('salle-ordinateur-eleves'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      t.salle.seance.compteurEleves(
                        connectes: vue.connectes,
                        inscrits: vue.inscrits,
                      ),
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                    LocalFeedback(message: message),
                    Ecart.vSm,
                    Expanded(
                      child: PanneauEleves(
                        eleves: vue.eleves,
                        actions: actions,
                        recitation: vue.recitation,
                        autorisationEcrire: vue.voitAutorisationEcrire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// La part de la hauteur du panneau que prend la video de l'enseignant.
  static const double _partVideo = 0.3;
}

/// Le centre : le titre de la page (« Coran · Page 24 »), le zoom et le
/// focus, puis la page, le tableau ou la scene.
class _Centre extends StatelessWidget {
  const _Centre({
    required this.vue,
    required this.actions,
    required this.local,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final SupportPageFixe? support = vue.supportPresente;
    final bool scene =
        media?.scene != null &&
        ((media?.scenePremierPlan ?? false) || surfaceAMontrer(vue) == null);
    final String? titre = scene
        ? null
        : support != null
        ? t.salle.seance.bibliotheque.titreCoranPage(page: support.page)
        : vue.tableauOuvert
        ? t.salle.seance.commandes.affichageTableau
        : null;
    final VoidCallback? agrandir = actions.onAgrandir;
    final NomsFocus noms = nomsFocus(context, agrandi: local.agrandi);
    return Column(
      key: SalleOrdinateur.cleCentre,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          spacing: AppSpacing.sm,
          children: <Widget>[
            Expanded(
              child: titre == null
                  ? const SizedBox.shrink()
                  : Text(
                      titre,
                      style: palette.inkStrong.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
            ),
            if (support != null &&
                !scene &&
                (actions.onZoomPlus != null || actions.onZoomMoins != null))
              PiluleZoomSalle(actions: actions, horizontale: true),
            // Lot salle 3 (directeur, 25/10/2026) : un support ouvert se
            // ferme ; la croix « Ranger dans la bibliotheque ».
            if (vue.voitRanger && actions.onRanger != null)
              BoutonIcone(
                key: const ValueKey<String>('salle-ranger-support'),
                forme: FormeBoutonIcone.appel,
                icone: AppIcons.fermer,
                diametre: diametreBoutonAppel(context),
                libelle: t.salle.seance.rangement.ranger,
                infobulle: t.salle.seance.rangement.ranger,
                onPress: actions.onRanger,
              ),
            if (agrandir != null)
              BoutonIcone(
                key: SalleOrdinateur.cleFocus,
                forme: FormeBoutonIcone.appel,
                icone: noms.icone,
                diametre: diametreBoutonAppel(context),
                libelle: noms.semantique,
                infobulle: noms.libelle,
                selectionne: local.agrandi,
                onPress: agrandir,
              ),
          ],
        ),
        Ecart.vSm,
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints c) {
              final Widget? page = scene
                  ? null
                  : pageSalle(
                      contexte,
                      vue: vue,
                      zoom: local.zoom,
                      ecran: c.biggest,
                      telephone: false,
                    );
              return ClipRRect(
                borderRadius: AppRadius.arrondiLg,
                child: page == null
                    ? ZoneSupport(vue: vue, zoom: local.zoom)
                    : Center(child: page),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Les Commandes ouvertes par « Plus », dans le panneau de droite (jamais au
/// milieu).
class _PanneauCommandes extends StatelessWidget {
  const _PanneauCommandes({
    required this.vue,
    required this.actions,
    required this.local,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey<String>('salle-ordinateur-commandes'),
    child: CommandesPedagogiques(
      vue: vue,
      actions: actions,
      zoom: local.zoom,
      agrandi: local.agrandi,
    ),
  );
}

/// La tuile nommee d'un outil de l'enseignant (Pointeur, Ecrire) : la barre
/// de l'ordinateur et l'onglet Outils du tiroir du telephone (plan du
/// 26/10/2026). [outil] : l'outil retenu.
Widget tuileOutilSalle(
  WidgetRef ref, {
  required ActionsSeance actions,
  required OutilDock? outil,
  required OutilEnseignement o,
}) => BoutonAppel(
  key: ValueKey<String>('salle-outil-${o.name}'),
  // « Ecrire » arme le stylo : son icone, et non celle du tableau, qui est la
  // meme (`annoter`) et se tient a cote dans la barre.
  icone: o == OutilEnseignement.ecrire
      ? AppIcons.stylet
      : iconeOutilEnseignement(o),
  libelle: libelleOutilEnseignement(o),
  nom: libelleOutilEnseignement(o),
  retenu: outil == outilDock(o),
  selectionne: outil == outilDock(o),
  onPress: () {
    if (depotAnnotationsDisponible(ref)) {
      ref.read(etatOutilsProvider.notifier).choisirOutil(outilDock(o));
    }
    actions.onOutil?.call(o);
  },
);

/// La barre des commandes, deux groupes, chaque bouton nomme : au debut
/// Eleves, Pointeur, Ecrire, Tableau, Plus ; a la fin Micro, Camera,
/// Bibliotheque, Quitter.
class _Bas extends ConsumerWidget {
  const _Bas({
    required this.vue,
    required this.actions,
    required this.local,
    required this.eleves,
    required this.bibliotheque,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final bool eleves;
  final bool bibliotheque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OutilDock? outil = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif),
    );
    final VoidCallback? livres = actions.onBibliotheque;
    final VoidCallback? lesEleves = actions.onEleves;
    final VoidCallback? commandes = actions.onCommandes;
    final bool outils = actions.onOutil != null;
    Widget boutonOutil(OutilEnseignement o) =>
        tuileOutilSalle(ref, actions: actions, outil: outil, o: o);

    final Widget gauche = DockSeance(
      key: const ValueKey<String>('salle-commandes-gauche'),
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      nommee: true,
      commandes: const <CommandeDock>[CommandeDock.tableau],
      avant: <Widget>[
        if (lesEleves != null)
          BoutonAppel(
            key: const ValueKey<String>('salle-eleves'),
            icone: AppIcons.eleves,
            libelle: t.salle.seance.eleves,
            nom: t.salle.seance.eleves,
            retenu: eleves,
            selectionne: eleves,
            onPress: lesEleves,
          ),
        if (outils) ...<Widget>[
          boutonOutil(OutilEnseignement.pointeur),
          if (vue.ecritureProposee) boutonOutil(OutilEnseignement.ecrire),
        ],
      ],
      plus: commandes != null && CommandesPedagogiques.aDesEntrees(vue, actions)
          ? BoutonPlusAppel(
              onPress: commandes,
              ouvert: vue.panneau == PanneauOuvert.commandes,
              nom: t.tc.outils.trait.plus,
            )
          : null,
    );
    final Widget droite = DockSeance(
      key: const ValueKey<String>('salle-commandes-droite'),
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      agrandi: local.agrandi,
      nommee: true,
      commandes: const <CommandeDock>[
        CommandeDock.micro,
        CommandeDock.camera,
        CommandeDock.quitter,
      ],
      avantQuitter: <Widget>[
        if (livres != null)
          BoutonAppel(
            key: const ValueKey<String>('salle-bibliotheque'),
            icone: AppIcons.bibliotheque,
            libelle: t.salle.seance.commandes.bibliotheque,
            nom: t.salle.seance.commandes.bibliotheque,
            retenu: bibliotheque,
            selectionne: bibliotheque,
            onPress: livres,
          ),
      ],
    );
    // Maquette du directeur du 26/10/2026 (barre precisee par le pilote) :
    // UNE barre sombre sur toute la largeur, deux groupes de tuiles, un filet
    // entre eux. Decision du directeur du 26/10/2026 : une tuile se place du
    // cote du panneau qu'elle ouvre (Eleves au debut, Bibliotheque a la fin).
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      key: SalleOrdinateur.cleBas,
      decoration: palette.surfaceInverse.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: IntrinsicHeight(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: gauche,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: VerticalDivider(
                  key: const ValueKey<String>('salle-barre-filet'),
                  width: 1,
                  thickness: 1,
                  color: palette.surfaceInverse.onBackground.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: droite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
