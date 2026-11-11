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
// Demandes du directeur du 11/11/2026 (lot SALLE-ORDINATEUR), qui prevalent
// sur le plan du 26/10 pour ces points : la video de l'enseignant vit EN TETE
// du panneau des Eleves (elle part avec lui, elle ne flotte plus) ; le haut
// est une seule rangee sur toute la largeur (la Classe au debut, le titre du
// support et ses outils au centre, la pilule d'etat a la fin) ; la page prend
// toute la hauteur entre cette rangee et la barre du bas.
//
// CORAN-GRAND (directeur, 11/11/2026 : « Sur PC, il faut que le Coran soit
// grand » ; « la barre sur un cote d'abord »), qui prevaut sur ce qui precede
// pour la disposition : plus de rangee du haut ni de barre du bas. La barre
// des commandes est une colonne sur le bord de debut (memes cinq groupes, de
// haut en bas), avec en tete la Classe, le titre du support et l'ile ; le
// zoom, ranger et focus sont dans les marges de la page, au-dessus de ses
// fleches. La page prend toute la hauteur de l'ecran (aux marges pres). Le
// focus retire les deux panneaux et les noms de la colonne.
//
// Rien de neuf sous le capot : la page est [pageSalle] (celle du
// telephone), la scene [ZoneSupport], la video [VignetteVideo], les Eleves
// [PanneauEleves], les Commandes [CommandesPedagogiques], les commandes
// d'appel [DockSeance] et [BoutonAppel].

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/widgets/commande_salle.dart'
    show SurfaceTuilesSalle, TuileCommandeSalle;
import '../../core/widgets/local_feedback.dart';
import '../tc_mushaf/page_madina_15.dart' show ratioHauteurPageMadina15;
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
import 'vignette_video.dart' show VignetteVideo;
import 'vue_seance.dart';
import 'zone_support.dart' show ZoneSupport, coteFlechesSalle, surfaceAMontrer;

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
class SalleOrdinateur extends ConsumerStatefulWidget {
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
  static const Key cleGauche = ValueKey<String>('salle-ordinateur-gauche');
  static const Key cleCentre = ValueKey<String>('salle-ordinateur-centre');
  static const Key cleDroite = ValueKey<String>('salle-ordinateur-droite');

  /// CORAN-GRAND (11/11/2026) : la barre sombre des commandes, en colonne
  /// sur le bord de debut. [cleBas] reste son ancien nom (tests voisins).
  static const Key cleCommandes = ValueKey<String>(
    'salle-ordinateur-commandes-colonne',
  );
  static const Key cleBas = cleCommandes;

  /// La tete de la colonne : la Classe, le titre du support, l'ile.
  static const Key cleTete = ValueKey<String>('salle-ordinateur-tete');
  static const Key cleFocus = ValueKey<String>('salle-ordinateur-focus');

  /// Directeur, 11/11/2026 : la video de l'enseignant, en tete du panneau
  /// des Eleves. CORAN-GRAND : ranger et focus dans la marge de fin de la
  /// page ([cleSupport]) ; la Classe et le titre du support en tete de la
  /// colonne des commandes.
  static const Key cleVideo = ValueKey<String>('salle-ordinateur-video');
  static const Key cleSupport = ValueKey<String>('salle-ordinateur-support');
  static const Key cleTitreSupport = ValueKey<String>(
    'salle-ordinateur-titre-support',
  );
  static const Key cleClasse = ValueKey<String>('salle-ordinateur-classe');

  @override
  ConsumerState<SalleOrdinateur> createState() => _EtatSalleOrdinateur();
}

class _EtatSalleOrdinateur extends ConsumerState<SalleOrdinateur> {
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
    final Widget? alerte = media?.alerte;
    final bool ecrire = barreOutilsVisible(ref, vue);
    final Widget? gauche = !focus && eleves
        ? _PanneauGauche(vue: vue, actions: actions)
        : null;
    final Widget salle = Material(
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // CORAN-GRAND (directeur, 11/11/2026) : la barre des commandes est
          // une colonne sur le bord de debut ; plus rien au-dessus ni
          // au-dessous de la page, qui prend toute la hauteur.
          //
          // GRILLE-COMMANDES : la colonne est PEINTE EN DERNIER (enfants
          // et sens inverses : les places ne changent pas), pour que l'ile
          // depliee passe par-dessus le panneau voisin au lieu de se plier
          // sur quatre lignes dans la colonne. Le lecteur d'ecran et la
          // touche Tab suivent la place a l'ecran : la colonne d'abord.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            textDirection: Directionality.of(context) == TextDirection.ltr
                ? TextDirection.rtl
                : TextDirection.ltr,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!focus) ...<Widget>[
                      BandeauSecours(vue: vue, actions: actions, gouttiere: 0),
                      ?alerte,
                    ],
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: <Widget>[
                          // Directeur, 11/11/2026 : la video de l'enseignant
                          // est dans le panneau des Eleves ; panneau ferme ou
                          // focus, elle part avec lui.
                          //
                          // CORAN-GRAND : quand l'enseignant ecrit, la palette
                          // prend la place du panneau des Eleves (garde en
                          // vie, cache), contre la page : la page ne perd pas
                          // un point. Panneau ferme, elle prend sa propre
                          // place, comme avant (lot BARRE-ORDINATEUR).
                          if (gauche != null)
                            SizedBox(
                              key: SalleOrdinateur.cleGauche,
                              width: largeurPanneauGauche,
                              child: ecrire
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        Visibility(
                                          visible: false,
                                          maintainState: true,
                                          child: gauche,
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.topStart,
                                          child: BarreOutilsSalle(vue: vue),
                                        ),
                                      ],
                                    )
                                  : gauche,
                            )
                          else if (ecrire)
                            Align(
                              alignment: AlignmentDirectional.topStart,
                              child: BarreOutilsSalle(vue: vue),
                            ),
                          Expanded(
                            child: _Centre(
                              vue: vue,
                              actions: actions,
                              local: local,
                            ),
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
                  ],
                ),
              ),
              _Colonne(
                vue: vue,
                actions: actions,
                local: local,
                focus: focus,
                eleves: eleves,
                panneauEleves: gauche != null,
                bibliotheque: bibliotheque && !commandes,
                raccourcis: widget.raccourcis,
              ),
            ],
          ),
        ),
      ),
    );
    if (!widget.raccourcis) return salle;
    // BARRE-ORDINATEUR (11/11/2026) : P, E et T font ce que font Pointeur,
    // Ecrire et Tableau ; Echap repose l'outil tenu. Poses AU-DESSUS des
    // raccourcis M, V, R, B, F de la salle (le focus est sur leur noeud) :
    // une touche que la salle ne prend pas remonte jusqu'ici.
    return _RaccourcisOutils(
      vue: vue,
      actions: actions,
      child: RaccourcisPleinEcran(
        vue: vue,
        actions: actions,
        local: local,
        onEleves: actions.onEleves,
        child: salle,
      ),
    );
  }
}

/// Vrai quand un champ de texte tient le focus : aucune lettre n'est alors
/// un raccourci (la regle E19 de la salle, jamais pendant une saisie).
bool _saisieEnCours() {
  final BuildContext? focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  return focus.widget is EditableText ||
      focus.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Les raccourcis des tuiles de la page (BARRE-ORDINATEUR, 11/11/2026) :
/// P (Pointeur), E (Ecrire), T (Tableau), Echap (reposer l'outil tenu).
/// Chacun n'agit que si sa tuile est rendue (un geste qui ne peut pas
/// aboutir ne fait rien), jamais pendant une saisie.
class _RaccourcisOutils extends ConsumerWidget {
  const _RaccourcisOutils({
    required this.vue,
    required this.actions,
    required this.child,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool outils = actions.onOutil != null;
    // Une touche refusee n'est pas prise : elle reste au champ de texte ou
    // a la feuille qui l'attend.
    bool permis(ToucheOutil touche) {
      if (_saisieEnCours()) return false;
      return switch (touche) {
        ToucheOutil.pointeur => outils && vue.voitOutils,
        ToucheOutil.ecrire => outils && vue.ecritureProposee,
        ToucheOutil.tableau => actions.onTableau != null,
        ToucheOutil.reposer => ref.read(etatOutilsProvider).outilActif != null,
      };
    }

    void executer(ToucheOutil touche) {
      switch (touche) {
        case ToucheOutil.pointeur:
          basculerOutilSalle(ref, actions, OutilEnseignement.pointeur);
        case ToucheOutil.ecrire:
          basculerOutilSalle(ref, actions, OutilEnseignement.ecrire);
        case ToucheOutil.tableau:
          actions.onTableau?.call();
        case ToucheOutil.reposer:
          ref.read(etatOutilsProvider.notifier).relacherOutil();
      }
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyP): _IntentOutil(
          ToucheOutil.pointeur,
        ),
        SingleActivator(LogicalKeyboardKey.keyE): _IntentOutil(
          ToucheOutil.ecrire,
        ),
        SingleActivator(LogicalKeyboardKey.keyT): _IntentOutil(
          ToucheOutil.tableau,
        ),
        SingleActivator(LogicalKeyboardKey.escape): _IntentOutil(
          ToucheOutil.reposer,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _IntentOutil: _ActionOutil(permis: permis, executer: executer),
        },
        child: child,
      ),
    );
  }
}

/// Les touches des tuiles de la page.
enum ToucheOutil {
  /// P : prend ou repose le Pointeur.
  pointeur,

  /// E : prend ou repose Ecrire.
  ecrire,

  /// T : ouvre ou ferme le tableau pour la classe.
  tableau,

  /// Echap : repose l'outil tenu.
  reposer,
}

class _IntentOutil extends Intent {
  const _IntentOutil(this.touche);

  final ToucheOutil touche;
}

class _ActionOutil extends Action<_IntentOutil> {
  _ActionOutil({required this.permis, required this.executer});

  final bool Function(ToucheOutil) permis;
  final void Function(ToucheOutil) executer;

  @override
  bool isEnabled(_IntentOutil intent) => permis(intent.touche);

  @override
  Object? invoke(_IntentOutil intent) {
    executer(intent.touche);
    return null;
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

/// Le titre du support (« Coran · Page 24 », « Tableau ») ; `null` quand la
/// scene video prend le centre ou que rien n'est montre.
String? _titreSupport(BuildContext context, VueSeance vue) {
  if (_sceneAuPremierPlan(context, vue)) return null;
  final SupportPageFixe? support = vue.supportPresente;
  if (support != null) {
    return t.salle.seance.bibliotheque.titreCoranPage(page: support.page);
  }
  return vue.tableauOuvert ? t.salle.seance.commandes.affichageTableau : null;
}

/// CORAN-GRAND (directeur, 11/11/2026) : les outils du support qui ne sont
/// pas le zoom (ranger le support, focus), l'un sous l'autre, dans la marge
/// de fin de la page, au-dessus de la fleche de page (un outil se pose pres
/// de l'objet sur lequel il agit) ; `null` quand aucun ne peut servir.
Widget? _outilsSupport(
  BuildContext context, {
  required VueSeance vue,
  required ActionsSeance actions,
  required EtatLocalSeance local,
  bool zoom = false,
}) {
  final VoidCallback? agrandir = actions.onAgrandir;
  final bool ranger = vue.voitRanger && actions.onRanger != null;
  // GRILLE-COMMANDES (directeur, 11/11/2026) : le zoom rejoint les autres
  // outils de la page, dans la meme pile, les memes boutons ronds. Plus de
  // pilule blanche a part, avec une case vide quand un seul sens est permis.
  final VoidCallback? plus = zoom ? actions.onZoomPlus : null;
  final VoidCallback? moins = zoom ? actions.onZoomMoins : null;
  final bool aZoom = plus != null || moins != null;
  if (agrandir == null && !ranger && !aZoom) return null;
  final NomsFocus noms = nomsFocus(context, agrandi: local.agrandi);
  final double diametre = diametreBoutonAppel(context);
  return Semantics(
    container: true,
    explicitChildNodes: true,
    label: _titreSupport(context, vue),
    child: Column(
      key: SalleOrdinateur.cleSupport,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        // Lot salle 3 (directeur, 25/10/2026) : un support ouvert se
        // ferme ; la croix « Ranger dans la bibliotheque ».
        if (ranger)
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
        if (aZoom)
          Column(
            key: const ValueKey<String>('salle-zoom'),
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: <Widget>[
              // Au dernier palier, « plus » s'efface et garde sa place :
              // « moins » ne saute pas sous le doigt (jamais grise).
              if (plus != null)
                BoutonIcone(
                  key: const ValueKey<String>('salle-zoom-plus'),
                  forme: FormeBoutonIcone.appel,
                  icone: AppIcons.zoomPlus,
                  diametre: diametre,
                  libelle: t.salle.seance.zoomPlus,
                  infobulle: t.salle.seance.zoomPlus,
                  onPress: plus,
                )
              else
                SizedBox.square(dimension: diametre),
              if (moins != null)
                BoutonIcone(
                  key: const ValueKey<String>('salle-zoom-moins'),
                  forme: FormeBoutonIcone.appel,
                  icone: AppIcons.zoomMoins,
                  diametre: diametre,
                  libelle: t.salle.seance.zoomMoins,
                  infobulle: t.salle.seance.zoomMoins,
                  onPress: moins,
                ),
            ],
          ),
      ],
    ),
  );
}

/// La hauteur de [nombre] outils de [_outilsSupport] et de leurs ecarts.
double _hauteurOutilsSupport(BuildContext context, {int nombre = 2}) =>
    nombre * diametreBoutonAppel(context) + (nombre - 1) * AppSpacing.sm;

/// Vrai quand la scene video prend le centre (aucune page, ou la scene mise
/// au premier plan).
bool _sceneAuPremierPlan(BuildContext context, VueSeance vue) {
  final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
  return media?.scene != null &&
      ((media?.scenePremierPlan ?? false) || surfaceAMontrer(vue) == null);
}

/// Le panneau de gauche, une seule liste (directeur, 11/11/2026) : en tete la
/// video de l'enseignant, a la largeur du panneau, au rayon des cartes des
/// eleves ; puis « Eleves 2/3 » ; puis une carte par eleve, qui se deplie
/// sur place. La video defile avec la liste : elle en fait partie.
class _PanneauGauche extends StatelessWidget {
  const _PanneauGauche({required this.vue, required this.actions});

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? message = PorteeMediaSalle.de(context)?.messageEleves;
    return _Panneau(
      key: const ValueKey<String>('salle-ordinateur-eleves'),
      child: PanneauEleves(
        eleves: vue.eleves,
        actions: actions,
        recitation: vue.recitation,
        autorisationEcrire: vue.voitAutorisationEcrire,
        tete: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext contexte, BoxConstraints c) =>
                  VignetteVideo(
                    key: SalleOrdinateur.cleVideo,
                    vue: vue,
                    largeur: c.maxWidth,
                    ratio: ratioVideoDuPanneau(
                      largeur: c.maxWidth,
                      hauteurEcran: MediaQuery.sizeOf(contexte).height,
                    ),
                  ),
            ),
            Ecart.vLg,
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
          ],
        ),
      ),
    );
  }
}

/// Le rapport largeur sur hauteur de la video de l'enseignant dans le panneau
/// des Eleves (4:3) : plus haute qu'une carte d'eleve, a la largeur du
/// panneau.
const double ratioVideoPanneau = 4 / 3;

/// Le rapport de la video de l'enseignant dans le panneau des Eleves, pour un
/// panneau de [largeur] sur un ecran haut de [hauteurEcran].
///
/// 4:3 quand l'ecran est assez haut ; sur un ecran bas, la video ne prend
/// jamais plus du sixieme de la hauteur : « l'enseignant a plus besoin de voir
/// les profils de ses eleves que le sien » (directeur, 11/11/2026). Sans cette
/// borne, a 1024 x 768 en texte agrandi, la video poussait une carte d'eleve
/// hors du panneau.
double ratioVideoDuPanneau({
  required double largeur,
  required double hauteurEcran,
}) {
  final double hauteur = math.min(
    largeur / ratioVideoPanneau,
    hauteurEcran / 6,
  );
  return hauteur <= 0 ? ratioVideoPanneau : largeur / hauteur;
}

/// Le centre : la page, le tableau ou la scene.
///
/// CORAN-GRAND (directeur, 11/11/2026 : « Sur PC, il faut que le Coran soit
/// grand ») : plus rien au-dessus ni au-dessous de la page ; elle prend
/// toute la hauteur de l'ecran (aux marges pres). Ses grandes fleches restent
/// a cote d'elle, a mi-hauteur ; au-dessus d'elles, dans ces memes marges,
/// le zoom (cote debut) et ranger, focus (cote fin). Quand la largeur manque
/// (panneaux ouverts sur un ecran etroit), la page se compose plus basse,
/// centree, pour que ses fleches tiennent toujours a cote : elle n'est
/// jamais coupee, aucun panneau ne se ferme a la place de l'enseignant.
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
    final bool scene = _sceneAuPremierPlan(context, vue);
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final SupportPageFixe? support = vue.supportPresente;
    final Widget? outils = _outilsSupport(
      context,
      vue: vue,
      actions: actions,
      local: local,
    );
    final bool peutZoomer =
        support != null &&
        !scene &&
        (actions.onZoomPlus != null || actions.onZoomMoins != null);
    return LayoutBuilder(
      key: SalleOrdinateur.cleCentre,
      builder: (BuildContext contexte, BoxConstraints c) {
        if (!scene && support != null) {
          final bool fleches =
              media?.onPagePrecedente != null || media?.onPageSuivante != null;
          final double h = math.max(
            0,
            math.min(
              c.maxHeight,
              // Arrondi vers le bas : la boite et ses fleches tiennent
              // toujours (sans quoi un arrondi les ferait disparaitre).
              ((c.maxWidth - 2 * margeFlechePage) * ratioHauteurPageMadina15)
                  .floorToDouble(),
            ),
          );
          final Size place = Size(c.maxWidth, h);
          final Size boite = boitePageAvecFleches(
            place,
            telephone: false,
            avecFleches: true,
          );
          final Widget? page = pageSalle(
            contexte,
            vue: vue,
            zoom: local.zoom,
            // Sans fleches, les marges restent reservees aux outils.
            ecran: fleches
                ? place
                : Size(math.max(0, c.maxWidth - 2 * margeFlechePage), h),
            telephone: false,
          );
          if (page != null) {
            // La place libre au-dessus d'une fleche de page (centree).
            final double voie = (h - coteFlechesSalle) / 2 - AppSpacing.sm;
            // Les outils de la page, une seule pile au coin de fin : ranger,
            // focus, puis le zoom quand la hauteur le permet (Ctrl + molette
            // et le pincement restent).
            final Widget? pile =
                peutZoomer &&
                    voie >= _hauteurOutilsSupport(contexte, nombre: 4)
                ? _outilsSupport(
                    contexte,
                    vue: vue,
                    actions: actions,
                    local: local,
                    zoom: true,
                  )
                : voie >= _hauteurOutilsSupport(contexte)
                ? outils
                : null;
            return Center(
              child: SizedBox(
                width: boite.width + 2 * coteFlechesSalle,
                height: h,
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: ClipRRect(
                        borderRadius: AppRadius.arrondiLg,
                        child: page,
                      ),
                    ),
                    if (pile != null)
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        width: coteFlechesSalle,
                        child: Center(child: pile),
                      ),
                  ],
                ),
              ),
            );
          }
        }
        // Le tableau ou la scene : les outils dans une marge de fin.
        final Widget contenu = LayoutBuilder(
          builder: (BuildContext ctx, BoxConstraints cc) {
            final Widget? page = scene
                ? null
                : pageSalle(
                    ctx,
                    vue: vue,
                    zoom: local.zoom,
                    ecran: cc.biggest,
                    telephone: false,
                  );
            return ClipRRect(
              borderRadius: AppRadius.arrondiLg,
              child: page == null
                  ? ZoneSupport(vue: vue, zoom: local.zoom)
                  : Center(child: page),
            );
          },
        );
        if (outils == null) return contenu;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Expanded(child: contenu),
            SizedBox(
              width: coteFlechesSalle,
              child: Align(alignment: Alignment.topCenter, child: outils),
            ),
          ],
        );
      },
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

/// Prend l'outil [o] (Pointeur, Ecrire), ou le repose s'il etait tenu : la
/// tuile de la barre et sa touche (P, E) font la meme chose.
void basculerOutilSalle(
  WidgetRef ref,
  ActionsSeance actions,
  OutilEnseignement o,
) {
  if (depotAnnotationsDisponible(ref)) {
    ref.read(etatOutilsProvider.notifier).choisirOutil(outilDock(o));
  }
  actions.onOutil?.call(o);
}

/// La tuile nommee d'un outil de l'enseignant (Pointeur, Ecrire), dans la
/// barre de l'ordinateur. [outil] : l'outil tenu.
///
/// BARRE-ORDINATEUR (11/11/2026) : l'outil tenu est le SEUL aplat lilas de la
/// barre, dit par trois signaux : l'aplat, l'icone pleine, l'etat
/// « selectionne » lu (et l'infobulle « Pointeur en main »). [raccourci] : la
/// touche, montree dans l'infobulle.
Widget tuileOutilSalle(
  WidgetRef ref, {
  required ActionsSeance actions,
  required OutilDock? outil,
  required OutilEnseignement o,
  String? raccourci,
}) {
  final bool tenu = outil == outilDock(o);
  final String nom = libelleOutilEnseignement(o);
  return BoutonAppel(
    key: ValueKey<String>('salle-outil-${o.name}'),
    // « Ecrire » arme le stylo : son icone, et non celle du tableau.
    icone: o == OutilEnseignement.ecrire
        ? AppIcons.stylet
        : iconeOutilEnseignement(o),
    libelle: tenu ? t.salle.barre.outilTenu(outil: nom) : nom,
    nom: nom,
    retenu: tenu,
    selectionne: tenu,
    iconePleine: tenu,
    raccourci: raccourci,
    onPress: () => basculerOutilSalle(ref, actions, o),
  );
}

/// La colonne des commandes de l'ordinateur, sur le bord de debut.
///
/// CORAN-GRAND (directeur, 11/11/2026 : « la barre sur un cote d'abord »,
/// prevaut sur la barre du bas du lot BARRE-ORDINATEUR pour la seule
/// disposition) : les memes cinq groupes, dans le meme ordre, de haut en
/// bas, les memes tuiles, etats, raccourcis et infobulles ; « Quitter »,
/// seul rouge, tout en bas. Au-dessus de la barre sombre, sur le fond de la
/// salle : le nom de la Classe, le titre du support, puis l'ile, au coin de
/// debut, hors de la page.
///
/// - au debut (en haut) : « Ma voix et mon image » (Micro, Camera), « Ma
///   classe » (Eleves), « Sur la page » (Pointeur, Ecrire) ;
/// - a la fin (en bas) : « Le support » (Bibliotheque, Tableau), « Sortir »
///   (Reduire, Quitter).
///
/// La colonne ne defile jamais. Quand la hauteur manque, elle se replie dans
/// cet ordre : le titre du support part, puis le nom de la Classe, puis les
/// noms des tuiles (il reste les icones, leur infobulle et ce que lit le
/// lecteur d'ecran ; la colonne retrecit, la page y gagne). En focus, elle
/// ne garde que les icones et l'ile.
///
/// Pointeur et Ecrire gardent leur place quand ils ne peuvent pas servir
/// (aucune page ni tableau) : la place reste, vide, rien ne glisse.
class _Colonne extends ConsumerWidget {
  const _Colonne({
    required this.vue,
    required this.actions,
    required this.local,
    required this.focus,
    required this.eleves,
    required this.panneauEleves,
    required this.bibliotheque,
    required this.raccourcis,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final bool focus;
  final bool eleves;

  /// Le panneau des Eleves est a l'ecran, a cote de la colonne : l'ile
  /// depliee peut passer par-dessus (elle n'y couvre que le haut de la video
  /// de l'enseignant, quelques secondes).
  final bool panneauEleves;
  final bool bibliotheque;

  /// Les raccourcis clavier sont actifs : chaque tuile montre sa touche.
  final bool raccourcis;

  /// Les cles des groupes (tests, captures).
  static const Key cleVoix = ValueKey<String>('salle-barre-voix');
  static const Key cleClasse = ValueKey<String>('salle-barre-classe');
  static const Key clePage = ValueKey<String>('salle-barre-page');
  static const Key cleSupport = ValueKey<String>('salle-barre-support');
  static const Key cleSortir = ValueKey<String>('salle-barre-sortir');

  /// La hauteur d'un filet entre deux groupes, ses marges comprises.
  static const double _filet = 2 * AppSpacing.sm + 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OutilDock? outil = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif),
    );
    final VoidCallback? livres = actions.onBibliotheque;
    final VoidCallback? lesEleves = actions.onEleves;
    final bool outils = actions.onOutil != null;
    String? touche(String lettre) => raccourcis ? lettre : null;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    bool dock(CommandeDock c) => vue.commandesDock.contains(c);
    final bool tableau =
        actions.onTableau != null && dock(CommandeDock.tableau);

    // Les noms des tuiles, groupe par groupe (la mesure de la colonne).
    final List<List<String>> nomsDebut = <List<String>>[
      <String>[
        if (actions.onMicro != null && dock(CommandeDock.micro)) t.salle.micro,
        if (actions.onCamera != null && dock(CommandeDock.camera))
          t.salle.camera,
      ],
      if (lesEleves != null) <String>[t.salle.seance.eleves],
      if (outils)
        <String>[t.salle.seance.outils.pointeur, t.salle.seance.outils.ecrire],
      <String>[
        if (livres != null) t.salle.seance.commandes.bibliotheque,
        if (tableau) t.salle.seance.commandes.affichageTableau,
      ],
    ].where((List<String> g) => g.isNotEmpty).toList();
    final List<List<String>> nomsFin = <List<String>>[
      <String>[
        if (actions.onRetour != null && vue.role != RoleSeance.guidee)
          t.salle.sortie.reduireNom,
        if (actions.onQuitter != null && dock(CommandeDock.quitter))
          t.salle.quitter,
      ],
    ].where((List<String> g) => g.isNotEmpty).toList();
    final List<String> tousNoms = <String>[
      for (final List<String> g in <List<String>>[...nomsDebut, ...nomsFin])
        ...g,
    ];

    double hauteurBarre(bool avecNom) {
      final double tuile = TuileCommandeSalle.hauteurColonne(
        context,
        tousNoms,
        avecNom: avecNom,
      );
      double total = 2 * AppSpacing.sm + AppSpacing.sm;
      for (final List<List<String>> moitie in <List<List<String>>>[
        nomsDebut,
        nomsFin,
      ]) {
        for (final List<String> g in moitie) {
          total += g.length * tuile + (g.length - 1) * AppSpacing.sm;
        }
        if (moitie.length > 1) total += (moitie.length - 1) * _filet;
      }
      return total;
    }

    final String? titre = _titreSupport(context, vue);
    final TextStyle styleTitre = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    double hauteurTexte(String texte, TextStyle style, double largeur) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: texte, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: largeur);
      final double h = peintre.height;
      peintre.dispose();
      return h.ceilToDouble();
    }

    // Un groupe nomme : le lecteur d'ecran dit son nom avant ses tuiles.
    Widget groupe(Key cle, String nom, List<Widget> tuiles) => Semantics(
      key: cle,
      container: true,
      explicitChildNodes: true,
      label: nom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: tuiles,
      ),
    );
    // La place d'une tuile qui ne peut pas servir maintenant : sa taille,
    // rien a voir, rien a toucher, rien a lire.
    Widget place(bool visible, Widget tuile) => Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: tuile,
    );
    final Widget filet = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(
        height: 1,
        thickness: 1,
        color: palette.surfaceInverse.onBackground.withValues(alpha: 0.3),
      ),
    );
    Widget dockSeance(List<CommandeDock> commandes) => DockSeance(
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      nommee: true,
      colonne: true,
      raccourcis: raccourcis,
      commandes: commandes,
    );

    final List<Widget> debut = <Widget>[
      groupe(cleVoix, t.salle.barre.groupes.voix, <Widget>[
        dockSeance(const <CommandeDock>[
          CommandeDock.micro,
          CommandeDock.camera,
        ]),
      ]),
      if (lesEleves != null)
        groupe(cleClasse, t.salle.barre.groupes.classe, <Widget>[
          BoutonAppel(
            key: const ValueKey<String>('salle-eleves'),
            icone: AppIcons.eleves,
            libelle: t.salle.seance.eleves,
            nom: t.salle.seance.eleves,
            ouvert: eleves,
            selectionne: eleves,
            iconePleine: eleves,
            raccourci: touche('R'),
            onPress: lesEleves,
          ),
        ]),
      if (outils)
        groupe(clePage, t.salle.barre.groupes.page, <Widget>[
          place(
            vue.voitOutils,
            tuileOutilSalle(
              ref,
              actions: actions,
              outil: outil,
              o: OutilEnseignement.pointeur,
              raccourci: touche('P'),
            ),
          ),
          place(
            vue.ecritureProposee,
            tuileOutilSalle(
              ref,
              actions: actions,
              outil: outil,
              o: OutilEnseignement.ecrire,
              raccourci: touche('E'),
            ),
          ),
        ]),
      groupe(cleSupport, t.salle.barre.groupes.support, <Widget>[
        if (livres != null)
          BoutonAppel(
            key: const ValueKey<String>('salle-bibliotheque'),
            icone: AppIcons.bibliotheque,
            libelle: t.salle.seance.commandes.bibliotheque,
            nom: t.salle.seance.commandes.bibliotheque,
            ouvert: bibliotheque,
            selectionne: bibliotheque,
            iconePleine: bibliotheque,
            raccourci: touche('B'),
            onPress: livres,
          ),
        if (tableau) dockSeance(const <CommandeDock>[CommandeDock.tableau]),
      ]),
    ];
    final List<Widget> fin = <Widget>[
      groupe(cleSortir, t.salle.barre.groupes.sortir, <Widget>[
        // « Reduire » se pose avant Quitter (SORTIE-SALLE, inchange) ; la
        // sortie du focus n'y est pas : elle reste contre la page (touche F).
        dockSeance(const <CommandeDock>[CommandeDock.quitter]),
      ]),
    ];
    List<Widget> avecFilets(List<Widget> groupes) => <Widget>[
      for (int i = 0; i < groupes.length; i++) ...<Widget>[
        if (i > 0) filet,
        groupes[i],
      ],
    ];

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        // Le repli, du plus complet au plus sobre ; le premier qui tient :
        // (noms des tuiles, titre du support).
        final List<(bool, bool)> replis = focus
            ? const <(bool, bool)>[(false, false)]
            : const <(bool, bool)>[
                (true, true),
                (true, false),
                (false, true),
                (false, false),
              ];
        // La colonne est au moins assez large pour l'ile repliee sur une
        // ligne : marges, anneau et temps restant du chrono, point d'etat
        // (et le point de la mention).
        final TextPainter temps = TextPainter(
          text: TextSpan(text: '00:00', style: textes.labelMedium),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final double largeurIle =
            (3 * AppSpacing.md +
                    AppSpacing.xl +
                    2 * AppSpacing.sm +
                    temps.width +
                    (vue.texteMention != null ? 2 * AppSpacing.sm : 0))
                .ceilToDouble();
        temps.dispose();
        // GRILLE-COMMANDES : la place de l'ile est FIXE (une ligne, l'ile
        // repliee). Depliee, elle ne pousse rien et ne se plie plus dans la
        // largeur de la colonne : elle passe par-dessus ce qui est a cote.
        final double ile =
            2 * AppSpacing.sm +
            MediaQuery.textScalerOf(context).scale(AppSpacing.xl);
        bool avecNom = false;
        bool avecTitre = false;
        double largeur = TuileCommandeSalle.largeurMin + 2 * AppSpacing.sm;
        for (final (bool nom, bool ti) in replis) {
          final double l = math.max(
            largeurIle,
            TuileCommandeSalle.largeurColonne(context, tousNoms, avecNom: nom) +
                2 * AppSpacing.sm,
          );
          final bool montreTitre = ti && titre != null;
          final double tete =
              (montreTitre
                  ? hauteurTexte(titre, styleTitre, l) + AppSpacing.xs
                  : 0) +
              ile +
              AppSpacing.sm;
          avecNom = nom;
          avecTitre = montreTitre;
          largeur = l;
          if (tete + hauteurBarre(nom) <= c.maxHeight) break;
        }
        // Jusqu'ou l'ile depliee peut s'etendre : par-dessus le panneau des
        // Eleves quand il est la ; sinon dans la marge de la page (la place
        // de sa fleche), jamais sur la page.
        final double largeurIleDepliee =
            largeur +
            AppSpacing.lg +
            (panneauEleves ? largeurPanneauGauche : coteFlechesSalle);
        return SizedBox(
          width: largeur,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              KeyedSubtree(
                key: SalleOrdinateur.cleTete,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (avecTitre && titre != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          titre,
                          key: SalleOrdinateur.cleTitreSupport,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styleTitre,
                        ),
                      ),
                    SizedBox(
                      height: ile,
                      child: OverflowBox(
                        alignment: AlignmentDirectional.topStart,
                        minWidth: 0,
                        maxWidth: largeurIleDepliee,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          widthFactor: 1,
                          heightFactor: 1,
                          child: PiluleEtatSalle(
                            vue: vue,
                            avecChrono: true,
                            largeurMax: largeurIleDepliee,
                            aLaLigne: true,
                            onPause: actions.onPause,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Ecart.vSm,
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext _, BoxConstraints cb) {
                    final bool noms =
                        avecNom && hauteurBarre(true) <= cb.maxHeight;
                    return DecoratedBox(
                      key: SalleOrdinateur.cleCommandes,
                      decoration: palette.surfaceInverse.decoration(
                        borderRadius: AppRadius.arrondiLg,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: SurfaceTuilesSalle(
                          surface: palette.surfaceInverse,
                          sansNom: !noms,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              KeyedSubtree(
                                key: const ValueKey<String>(
                                  'salle-commandes-gauche',
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: avecFilets(debut),
                                ),
                              ),
                              Ecart.vSm,
                              const Spacer(),
                              KeyedSubtree(
                                key: const ValueKey<String>(
                                  'salle-commandes-droite',
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: avecFilets(fin),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
