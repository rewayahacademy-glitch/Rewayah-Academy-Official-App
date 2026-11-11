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
import 'vignette_video.dart' show VignetteVideo;
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
  static const Key cleHaut = ValueKey<String>('salle-ordinateur-haut');
  static const Key cleGauche = ValueKey<String>('salle-ordinateur-gauche');
  static const Key cleCentre = ValueKey<String>('salle-ordinateur-centre');
  static const Key cleDroite = ValueKey<String>('salle-ordinateur-droite');
  static const Key cleBas = ValueKey<String>('salle-ordinateur-bas');
  static const Key cleFocus = ValueKey<String>('salle-ordinateur-focus');

  /// Directeur, 11/11/2026 : la video de l'enseignant, en tete du panneau
  /// des Eleves ; le support et ses outils, au centre du haut.
  static const Key cleVideo = ValueKey<String>('salle-ordinateur-video');
  static const Key cleSupport = ValueKey<String>('salle-ordinateur-support');
  static const Key cleTitreSupport = ValueKey<String>(
    'salle-ordinateur-titre-support',
  );
  static const Key cleClasse = ValueKey<String>('salle-ordinateur-classe');
  static const Key cleEnseignant = ValueKey<String>(
    'salle-ordinateur-enseignant',
  );

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
    final Widget salle = Material(
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Haut(vue: vue, actions: actions, local: local, focus: focus),
              Ecart.vLg,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: <Widget>[
                    // Directeur, 11/11/2026 : la video de l'enseignant est
                    // dans le panneau des Eleves ; panneau ferme ou focus, elle
                    // part avec lui.
                    if (!focus && eleves)
                      SizedBox(
                        key: SalleOrdinateur.cleGauche,
                        width: largeurPanneauGauche,
                        child: _PanneauGauche(vue: vue, actions: actions),
                      ),
                    // BARRE-ORDINATEUR (11/11/2026) : quand l'enseignant
                    // ecrit, la palette se pose contre la page, du cote
                    // d'Ecrire dans la barre ; la page garde sa hauteur.
                    if (barreOutilsVisible(ref, vue))
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: BarreOutilsSalle(vue: vue),
                      ),
                    Expanded(
                      child: _Centre(vue: vue, local: local),
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
              Ecart.vLg,
              _Bas(
                vue: vue,
                actions: actions,
                local: local,
                eleves: eleves,
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

/// Le haut, une seule rangee sur toute la largeur (directeur, 11/11/2026 :
/// « l'ecran est large et ces elements peuvent se distribuer horizontalement
/// sur toute la largeur ») : au debut, le nom de la Classe et « Sayyida
/// Prenom » ; au centre, le titre du support et ses outils colles a lui
/// (zoom, ranger, focus : un outil se pose pres de l'objet sur lequel il
/// agit) ; a la fin, la pilule d'etat de la seance, posee telle quelle.
///
/// Repli quand la rangee ne tient pas (panneaux ouverts a 1280, texte
/// agrandi) : le nom de l'enseignant part d'abord, puis le nom de la Classe
/// et le titre du support se coupent par des points de suspension ; les
/// outils et la pilule gardent leur taille. En focus, la rangee ne garde que
/// le support et ses outils (la sortie du focus y reste, et dans la barre du
/// bas).
class _Haut extends StatelessWidget {
  const _Haut({
    required this.vue,
    required this.actions,
    required this.local,
    required this.focus,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final bool focus;

  @override
  Widget build(BuildContext context) {
    final Widget? alerte = PorteeMediaSalle.de(context)?.alerte;
    final Widget support = _GroupeSupport(
      vue: vue,
      actions: actions,
      local: local,
    );
    final Widget rangee = LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => Row(
        spacing: AppSpacing.lg,
        children: <Widget>[
          Expanded(
            child: focus
                ? const SizedBox.shrink()
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _IdentiteClasse(vue: vue),
                  ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth * _partCentre),
            child: support,
          ),
          Expanded(
            child: focus
                ? const SizedBox.shrink()
                : Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: PiluleEtatSalle(
                      vue: vue,
                      avecChrono: true,
                      onPause: actions.onPause,
                    ),
                  ),
          ),
        ],
      ),
    );
    return Column(
      key: SalleOrdinateur.cleHaut,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        rangee,
        if (!focus) ...<Widget>[
          BandeauSecours(vue: vue, actions: actions, gouttiere: 0),
          ?alerte,
        ],
      ],
    );
  }

  /// La part de la largeur que le support et ses outils peuvent prendre au
  /// plus : les deux bords se partagent le reste, a parts egales, pour que
  /// le support reste au centre.
  static const double _partCentre = 0.5;
}

/// Le nom de la Classe, puis « Sayyida Prenom » (le nom de l'annuaire de la
/// seance, deja titre ; sans titre connu, le prenom seul).
class _IdentiteClasse extends StatelessWidget {
  const _IdentiteClasse({required this.vue});

  final VueSeance vue;

  /// En dessous de cette largeur (192), le nom de l'enseignant part : c'est
  /// le premier repli de la rangee du haut.
  static const double largeurAvecEnseignant = AppSpacing.respiration * 3;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String classe = vue.nomClasse.isEmpty
        ? t.salle.seance.titre
        : vue.nomClasse;
    final String enseignant = vue.nomEnseignant;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            classe,
            key: SalleOrdinateur.cleClasse,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          if (enseignant.isNotEmpty && c.maxWidth >= largeurAvecEnseignant)
            Text(
              enseignant,
              key: SalleOrdinateur.cleEnseignant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Le titre du support (« Coran · Page 24 », « Tableau ») et ses outils, en
/// un seul groupe : zoom moins et plus, ranger le support, focus.
class _GroupeSupport extends StatelessWidget {
  const _GroupeSupport({
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
    final SupportPageFixe? support = vue.supportPresente;
    final bool scene = _sceneAuPremierPlan(context, vue);
    final String? titre = scene
        ? null
        : support != null
        ? t.salle.seance.bibliotheque.titreCoranPage(page: support.page)
        : vue.tableauOuvert
        ? t.salle.seance.commandes.affichageTableau
        : null;
    final VoidCallback? agrandir = actions.onAgrandir;
    final NomsFocus noms = nomsFocus(context, agrandi: local.agrandi);
    return Row(
      key: SalleOrdinateur.cleSupport,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        if (titre != null)
          Flexible(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Text(
                titre,
                key: SalleOrdinateur.cleTitreSupport,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
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
    );
  }
}

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

/// Le centre : la page, le tableau ou la scene, sur toute la hauteur entre la
/// rangee du haut et la barre du bas (directeur, 11/11/2026 : « Sur PC, il
/// faut que le Coran soit grand »). Le titre et les outils du support sont
/// montes dans la rangee du haut : rien ne prend de hauteur a la page.
class _Centre extends StatelessWidget {
  const _Centre({required this.vue, required this.local});

  final VueSeance vue;
  final EtatLocalSeance local;

  @override
  Widget build(BuildContext context) {
    final bool scene = _sceneAuPremierPlan(context, vue);
    return LayoutBuilder(
      key: SalleOrdinateur.cleCentre,
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

/// La barre des commandes de l'ordinateur.
///
/// BARRE-ORDINATEUR (directeur, 11/11/2026, prevaut sur la barre du plan du
/// 26/10 pour l'ordinateur) : cinq groupes nommes par ce que l'enseignant
/// veut faire, separes d'un filet ; neuf tuiles, chacune a un clic, toujours
/// a la meme place.
///
/// - au debut : « Ma voix et mon image » (Micro, Camera), « Ma classe »
///   (Eleves), « Sur la page » (Pointeur, Ecrire) ;
/// - a la fin : « Le support » (Bibliotheque, Tableau), « Sortir » (Reduire,
///   Quitter).
///
/// Plus de « Plus » sur ordinateur : tout ce qu'il ouvrait est deja a un clic
/// ailleurs (Bibliotheque, Pointeur, Ecrire dans la barre ; zoom, ranger et
/// focus contre le titre du support ; la page qui tourne contre la page ; la
/// palette d'ecriture contre la page). Une tuile du panneau qu'elle ouvre
/// reste de son cote (directeur, 26/10 : Eleves au debut, Bibliotheque a la
/// fin). Pointeur et Ecrire gardent leur place quand ils ne peuvent pas
/// servir (aucune page ni tableau) : la place reste, vide, rien ne glisse.
class _Bas extends ConsumerWidget {
  const _Bas({
    required this.vue,
    required this.actions,
    required this.local,
    required this.eleves,
    required this.bibliotheque,
    required this.raccourcis,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;
  final bool eleves;
  final bool bibliotheque;

  /// Les raccourcis clavier sont actifs : chaque tuile montre sa touche.
  final bool raccourcis;

  /// Les cles des groupes (tests, captures).
  static const Key cleVoix = ValueKey<String>('salle-barre-voix');
  static const Key cleClasse = ValueKey<String>('salle-barre-classe');
  static const Key clePage = ValueKey<String>('salle-barre-page');
  static const Key cleSupport = ValueKey<String>('salle-barre-support');
  static const Key cleSortir = ValueKey<String>('salle-barre-sortir');

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

    // Un groupe nomme : le lecteur d'ecran dit son nom avant ses tuiles.
    Widget groupe(Key cle, String nom, List<Widget> tuiles) => Semantics(
      key: cle,
      container: true,
      explicitChildNodes: true,
      label: nom,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SizedBox(
        height: AppSpacing.section,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: palette.surfaceInverse.onBackground.withValues(alpha: 0.3),
        ),
      ),
    );
    Widget dock(List<CommandeDock> commandes, {Key? key}) => DockSeance(
      key: key,
      vue: vue,
      actions: actions,
      microOuvert: local.microOuvert,
      cameraAllumee: local.cameraAllumee,
      nommee: true,
      raccourcis: raccourcis,
      commandes: commandes,
    );

    final List<Widget> debut = <Widget>[
      groupe(cleVoix, t.salle.barre.groupes.voix, <Widget>[
        dock(const <CommandeDock>[CommandeDock.micro, CommandeDock.camera]),
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
    ];
    final List<Widget> fin = <Widget>[
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
        if (actions.onTableau != null &&
            vue.commandesDock.contains(CommandeDock.tableau))
          dock(const <CommandeDock>[CommandeDock.tableau]),
      ]),
      groupe(cleSortir, t.salle.barre.groupes.sortir, <Widget>[
        // « Reduire » se pose avant Quitter (SORTIE-SALLE, inchange) ; la
        // sortie du focus n'y est plus : elle reste contre le titre du
        // support, en focus aussi (touche F).
        dock(const <CommandeDock>[CommandeDock.quitter]),
      ]),
    ];
    List<Widget> avecFilets(List<Widget> groupes) => <Widget>[
      for (int i = 0; i < groupes.length; i++) ...<Widget>[
        if (i > 0) filet,
        groupes[i],
      ],
    ];
    return DecoratedBox(
      key: SalleOrdinateur.cleBas,
      decoration: palette.surfaceInverse.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppSpacing.lg,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  key: const ValueKey<String>('salle-commandes-gauche'),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: AppSpacing.sm,
                  children: avecFilets(debut),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  key: const ValueKey<String>('salle-commandes-droite'),
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: AppSpacing.sm,
                  children: avecFilets(fin),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
