import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/fonction_indisponible.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/learning_assignment.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/port_assignations.dart';
import '../../core/tc_outils/port_dock_hote.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_outil.dart';
import '../../core/widgets/local_feedback.dart';
import 'barre_stylet.dart';
import 'feuille_choix.dart';

/// Le Teaching Dock : sept outils, flottants, jamais devant le texte.
///
/// ```
/// [ Bibliotheque ] [ Focus ] [ Marquer ] [ Masquer ] [ Stylet ] [ Pointeur ] [ Revision ]
/// ```
///
/// **Il ne s'installe pas de force.** Le dock ne connait pas l'ecran qui
/// l'accueille : il lit [PortDockHote] et publie l'etat des outils. L'hote --
/// le moteur Mushaf, la Classe Live, la Bibliotheque -- reste maitre de son
/// rendu. C'est ce qui permet a Agent D de livrer un dock sans ecrire une ligne
/// dans l'ecran d'un autre agent.
///
/// **Il ne couvre jamais le contenu actif** : c'est [HoteDuDock] qui l'y oblige,
/// en mesurant le dock et en reservant exactement sa place.
///
/// **Aucune commande vocale** (D-10). Le professeur parle avec son micro
/// normal ; les outils se prennent au doigt ou au stylet.
class TeachingDock extends ConsumerStatefulWidget {
  /// Cree le dock d'un hote.
  const TeachingDock({required this.hote, super.key, this.onEvenement});

  /// L'ecran qui accueille le dock.
  final PortDockHote hote;

  /// Ce que le dock a a dire au reste de la classe. L'hote le branche sur
  /// `DiffusionOutils` ; sans lui, les outils restent locaux.
  final void Function(EvenementOutil evenement)? onEvenement;

  @override
  ConsumerState<TeachingDock> createState() => _TeachingDockState();
}

class _TeachingDockState extends ConsumerState<TeachingDock> {
  static const Uuid _generateur = Uuid();

  String? _message;
  LearningAssignment? _dernierTravail;

  /// Le message calme d'une fonction dont le serveur n'est pas branche
  /// (SALLE-ROBUSTE). Le compteur change la cle du retour local : sans lui, un
  /// second appui sur le meme outil ne le reafficherait pas.
  String? _indisponible;
  int _nombreIndisponible = 0;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final SupportPresente? support = widget.hote.supportActif();
    final SelectionSupport? selection = widget.hote.selectionCourante();
    final ContexteDock contexte = widget.hote.contexte();
    final List<OutilDock> outils = outilsDisponibles(
      support: support,
      selection: selection,
      capacites: widget.hote.capacites(),
      contexte: contexte,
    );

    // Un observateur silencieux n'a aucun outil : le dock disparait, il ne se
    // grise pas. Un dock inerte inviterait a le toucher.
    if (outils.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool vertical = etat.position != PositionDock.bas;
    // [RESPONSIVE]
    // Les libelles n'apparaissent qu'a partir du tiroir permanent : en dessous,
    // sept libelles cote a cote feraient un dock plus large que l'ecran, donc
    // un dock qui defile, donc des outils qu'il faut chercher.
    final bool avecLibelle =
        AppGabarit.de(context) == Gabarit.desktop && !vertical;

    final List<Widget> boutons = <Widget>[
      // La poignee en tete : c'est la premiere chose qu'atteint le pouce, et
      // c'est le seul bouton qui doit rester joignable meme quand la bande
      // defile.
      BoutonOutil(
        icone: AppIcons.poigneeDock,
        libelle: t.tc.outils.dock.deplacer,
        avecLibelle: avecLibelle,
        onPress: () => ref
            .read(etatOutilsProvider.notifier)
            .deplacerDock(_suivante(etat.position)),
      ),
      for (final OutilDock outil in outils)
        BoutonOutil(
          icone: _icone(outil),
          libelle: libelleOutilDock(outil),
          retenu: _estRetenu(outil, etat),
          avecLibelle: avecLibelle,
          onPress: () => _declencher(outil, etat, support, selection, contexte),
        ),
    ];

    final Widget bande = DecoratedBox(
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceOverlay,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiLg,
        ombres: AppElevation.niveau2(palette.ombre),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: SingleChildScrollView(
          // Le dock reste tenable quand la place manque : sept outils a 72
          // points de cible ne tiennent pas sur un telephone en portrait, et
          // un debordement rouge serait pire qu'un defilement.
          scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
          child: vertical
              ? Column(mainAxisSize: MainAxisSize.min, children: boutons)
              : Row(mainAxisSize: MainAxisSize.min, children: boutons),
        ),
      ),
    );

    // Aucun libelle de groupe sur le dock lui-meme : chaque bouton porte deja
    // le sien, et un libelle de conteneur poserait un second nom par dessus,
    // que les technologies d'assistance liraient a la place.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        if (_indisponible != null)
          LocalFeedback(
            key: ValueKey<int>(_nombreIndisponible),
            message: _indisponible,
          ),
        if (_message != null)
          LocalFeedback(
            message: _message,
            libelleAnnuler: t.tc.outils.trait.annuler,
            onAnnuler: _annulerDernierTravail,
          ),
        if (etat.styletArme) ...<Widget>[
          BarreStylet(onAnnuler: _annulerDernierGeste),
          Ecart.vSm,
        ],
        bande,
      ],
    );
  }

  bool _estRetenu(OutilDock outil, EtatOutils etat) => switch (outil) {
    OutilDock.focus => etat.focus != null,
    OutilDock.masquer => !etat.masquage.estVide,
    _ => etat.outilActif == outil,
  };

  void _declencher(
    OutilDock outil,
    EtatOutils etat,
    SupportPresente? support,
    SelectionSupport? selection,
    ContexteDock contexte,
  ) {
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);
    switch (outil) {
      case OutilDock.bibliotheque:
        unawaited(widget.hote.ouvrirBibliotheque());
      case OutilDock.focus:
        if (etat.focus != null) {
          controleur.quitterFocus();
          _emettre(const EvenementFocus(plage: null));
          return;
        }
        if (selection == null) {
          return;
        }
        controleur.mettreAuFocus(selection.plage);
        _emettre(EvenementFocus(plage: selection.plage));
      case OutilDock.marquer:
        unawaited(_marquer(etat, support, selection));
      case OutilDock.masquer:
        if (selection == null) {
          return;
        }
        // Un deuxieme appui sur une plage deja masquee la revele : c'est le
        // geste de la recitation, masquer puis decouvrir, et il ne demande pas
        // un second bouton.
        final bool dejaMasquee = etat.masquage.plages.contains(selection.plage);
        if (dejaMasquee) {
          controleur.reveler(selection.plage);
        } else {
          controleur.masquer(selection.plage);
        }
        _emettre(
          EvenementMasquage(plan: ref.read(etatOutilsProvider).masquage),
        );
      case OutilDock.stylet:
        // Sans serveur d'annotations, un trait dessine ne serait conserve
        // nulle part : le stylet ne s'arme pas, et le dit.
        if (ref.read(portAnnotationsProvider) is PortIndisponible) {
          _direIndisponible();
          return;
        }
        controleur.choisirOutil(outil);
      case OutilDock.pointeur:
        controleur.choisirOutil(outil);
      case OutilDock.revision:
        unawaited(_poserTravail(etat, support, selection, contexte));
    }
  }

  Future<void> _marquer(
    EtatOutils etat,
    SupportPresente? support,
    SelectionSupport? selection,
  ) async {
    if (support == null || selection == null) {
      return;
    }
    if (ref.read(portAnnotationsProvider) is PortIndisponible) {
      _direIndisponible();
      return;
    }
    final IntentionPedagogique? intention =
        await FeuilleChoix.ouvrirIntention(
          context,
          titre: t.tc.outils.marquer.titre,
          aide: t.tc.outils.marquer.aide,
          intentionInitiale: etat.intention,
        );
    if (intention == null || !mounted) {
      return;
    }
    ref.read(etatOutilsProvider.notifier).choisirIntention(intention);

    final ContexteDock contexte = widget.hote.contexte();
    final PortAnnotations annotations = ref.read(portAnnotationsProvider);
    final AnnotationLayer? couche = await annotations.couche(
      resourceId: support.resourceId,
      sessionId: contexte.sessionId,
      portee: etat.portee,
    );
    if (couche == null) {
      return;
    }
    final MarqueurSemantique marqueur = MarqueurSemantique(
      id: _generateur.v4(),
      plage: selection.plage,
      intention: intention,
    );
    try {
      await annotations.poserMarqueur(couche.id, marqueur);
    } on FonctionIndisponible {
      if (mounted) {
        _direIndisponible();
      }
      return;
    }
    _emettre(
      EvenementMarqueur.pose(coucheId: couche.id, marqueur: marqueur),
    );
    // Aucun retour local : le marqueur apparait sur le passage marque. Une
    // reussite visuellement evidente ne declenche aucune notification.
  }

  Future<void> _poserTravail(
    EtatOutils etat,
    SupportPresente? support,
    SelectionSupport? selection,
    ContexteDock contexte,
  ) async {
    final String? groupeId = contexte.groupeId;
    if (support == null || selection == null || groupeId == null) {
      return;
    }
    if (ref.read(portAssignationsProvider) is PortIndisponible) {
      _direIndisponible();
      return;
    }
    final IntentionPedagogique? intention =
        await FeuilleChoix.ouvrirIntention(
          context,
          titre: t.tc.outils.revision.titre,
          aide: t.tc.outils.revision.aide,
          intentionInitiale: etat.intention,
        );
    if (intention == null || !mounted) {
      return;
    }
    final LearningAssignment travail;
    try {
      travail = await ref
          .read(portAssignationsProvider)
          .creerDepuisSelection(
            groupId: groupeId,
            resourceId: support.resourceId,
            resourceVersionId: support.resourceVersionId,
            contentRange: selection.plage,
            purpose: intention,
          );
    } on FonctionIndisponible {
      if (mounted) {
        _direIndisponible();
      }
      return;
    }
    if (!mounted) {
      return;
    }
    // Un travail pose ne se voit nulle part sur le support : celui-la merite un
    // retour local. Et il propose d'annuler plutot que de faire confirmer.
    setState(() {
      _dernierTravail = travail;
      _message = t.tc.outils.revision.posee;
    });
  }

  /// Dit calmement qu'une fonction n'est pas encore disponible.
  void _direIndisponible() {
    setState(() {
      _indisponible = t.tc.indisponible;
      _nombreIndisponible++;
    });
  }

  void _annulerDernierTravail() {
    final LearningAssignment? travail = _dernierTravail;
    if (travail == null) {
      return;
    }
    unawaited(
      ref
          .read(portAssignationsProvider)
          .changerStatut(travail.id, StatutAssignation.annule),
    );
    setState(() {
      _dernierTravail = null;
      _message = null;
    });
  }

  void _annulerDernierGeste() {
    final SupportPresente? support = widget.hote.supportActif();
    if (support == null) {
      return;
    }
    final ContexteDock contexte = widget.hote.contexte();
    final EtatOutils etat = ref.read(etatOutilsProvider);
    final PortAnnotations annotations = ref.read(portAnnotationsProvider);
    unawaited(() async {
      final AnnotationLayer? couche = await annotations.couche(
        resourceId: support.resourceId,
        sessionId: contexte.sessionId,
        portee: etat.portee,
      );
      if (couche == null || couche.estVide) {
        return;
      }
      final TraitVectoriel? dernier = couche.traits.isEmpty
          ? null
          : couche.traits.last;
      await annotations.annulerDernier(couche.id);
      if (dernier != null) {
        _emettre(
          EvenementTraitRetire(coucheId: couche.id, traitId: dernier.id),
        );
      }
    }());
  }

  void _emettre(EvenementOutil evenement) =>
      widget.onEvenement?.call(evenement);

  static PositionDock _suivante(PositionDock position) => switch (position) {
    PositionDock.bas => PositionDock.droite,
    PositionDock.droite => PositionDock.gauche,
    PositionDock.gauche => PositionDock.bas,
  };

  static AppIcon _icone(OutilDock outil) => switch (outil) {
    OutilDock.bibliotheque => AppIcons.bibliotheque,
    OutilDock.focus => AppIcons.focus,
    OutilDock.marquer => AppIcons.marqueur,
    OutilDock.masquer => AppIcons.masquer,
    OutilDock.stylet => AppIcons.stylet,
    OutilDock.pointeur => AppIcons.pointeur,
    OutilDock.revision => AppIcons.revision,
  };
}

/// L'hote d'un dock : le contenu d'abord, le dock ensuite, sans recouvrement.
///
/// **« Il ne doit jamais couvrir le texte actif »** (spec section 8). La regle
/// n'est pas tenue par un reglage de marge ecrit a la main -- elle serait fausse
/// le jour ou le dock grandit, change de langue ou passe en Interface guidee.
/// Elle est tenue par une **mesure** : le dock est rendu, on releve sa taille
/// reelle, et le contenu recoit exactement cette place en marge. Le dock flotte
/// donc au dessus d'une zone vide, jamais au dessus du support.
class HoteDuDock extends ConsumerStatefulWidget {
  /// Compose un contenu et son dock.
  const HoteDuDock({required this.contenu, required this.dock, super.key});

  /// Le support et tout ce que l'hote affiche.
  final Widget contenu;

  /// Le dock, en general un [TeachingDock].
  final Widget dock;

  @override
  ConsumerState<HoteDuDock> createState() => _HoteDuDockState();
}

class _HoteDuDockState extends ConsumerState<HoteDuDock> {
  final GlobalKey _cleDock = GlobalKey();
  Size _taille = Size.zero;

  @override
  Widget build(BuildContext context) {
    final PositionDock position = ref.watch(
      etatOutilsProvider.select((EtatOutils etat) => etat.position),
    );
    WidgetsBinding.instance.addPostFrameCallback(_relever);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(padding: _marge(position), child: widget.contenu),
        ),
        _place(position, KeyedSubtree(key: _cleDock, child: widget.dock)),
      ],
    );
  }

  /// Releve la taille reelle du dock, une fois qu'il est rendu.
  ///
  /// `setState` n'est appele que lorsque la taille **change** : sans cette
  /// garde, une reconstruction par image entrainerait la suivante, et le dock
  /// tournerait en boucle.
  void _relever(Duration _) {
    final RenderObject? rendu = _cleDock.currentContext?.findRenderObject();
    if (rendu is! RenderBox || !rendu.hasSize) {
      return;
    }
    if (rendu.size != _taille && mounted) {
      setState(() => _taille = rendu.size);
    }
  }

  EdgeInsetsGeometry _marge(PositionDock position) => switch (position) {
    PositionDock.bas => EdgeInsetsDirectional.only(
      bottom: _taille.height + AppSpacing.md,
    ),
    PositionDock.gauche => EdgeInsetsDirectional.only(
      start: _taille.width + AppSpacing.md,
    ),
    PositionDock.droite => EdgeInsetsDirectional.only(
      end: _taille.width + AppSpacing.md,
    ),
  };

  Widget _place(PositionDock position, Widget dock) => switch (position) {
    PositionDock.bas => PositionedDirectional(
      start: AppSpacing.sm,
      end: AppSpacing.sm,
      bottom: AppSpacing.sm,
      child: Align(alignment: AlignmentDirectional.bottomCenter, child: dock),
    ),
    PositionDock.gauche => PositionedDirectional(
      start: AppSpacing.sm,
      top: AppSpacing.sm,
      bottom: AppSpacing.sm,
      child: Align(alignment: AlignmentDirectional.centerStart, child: dock),
    ),
    PositionDock.droite => PositionedDirectional(
      end: AppSpacing.sm,
      top: AppSpacing.sm,
      bottom: AppSpacing.sm,
      child: Align(alignment: AlignmentDirectional.centerEnd, child: dock),
    ),
  };
}
