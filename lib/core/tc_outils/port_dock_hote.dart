import 'package:flutter/foundation.dart';

import 'ancrage_annotation.dart';
import 'ports_externes/content_position.dart';
import 'ports_externes/content_range.dart';
import 'ports_externes/library_resource.dart';
import 'ports_externes/port_realtime_pedagogique.dart'
    show CapacitesPedagogiques, ModeAffichagePartage;

/// Les sept outils du Teaching Dock, dans l'ordre de la spec (section 8).
enum OutilDock {
  /// Ouvre la Bibliotheque de l'hote. **Une seule Bibliotheque** (D-20) : le
  /// dock ne la possede pas, il la demande.
  bibliotheque,

  /// Met une plage au centre et reduit le chrome.
  focus,

  /// Associe une intention pedagogique a une plage.
  marquer,

  /// Cache une plage pour la recitation, avec revelation controlee.
  masquer,

  /// Ecrit sur la couche d'annotation.
  stylet,

  /// Indication ephemere, non persistante.
  pointeur,

  /// Cree un travail a preparer depuis la selection.
  revision,
}

/// Le support que l'hote presente en ce moment.
@immutable
class SupportPresente {
  /// Declare le support courant.
  const SupportPresente({
    required this.resourceId,
    required this.capacites,
    required this.modeAffichage,
    this.resourceVersionId,
    this.blocs = CarteDesBlocs.vide,
    this.ancrageCadre,
  });

  /// La ressource presentee.
  final String resourceId;

  /// La version presentee, quand elle est connue.
  final String? resourceVersionId;

  /// Ce que le support sait faire. **La seule source du comportement offert.**
  final Set<CapaciteRessource> capacites;

  /// Comment il est rendu : page figee, verset reflowable, focus.
  final ModeAffichagePartage modeAffichage;

  /// La geometrie courante des blocs ancrables, pour poser et resoudre les
  /// annotations. Vide tant que l'hote ne la fournit pas : la couche
  /// d'annotation ne peint alors rien, plutot qu'au mauvais endroit.
  final CarteDesBlocs blocs;

  /// Ce que le cadre affiche, en termes **spatiaux** : la page courante, ou une
  /// fraction du support. C'est l'ancrage de repli d'un trait pose la ou aucun
  /// bloc de texte ne se trouve -- une fleche dans la marge, une accolade entre
  /// deux lignes.
  ///
  /// `null` quand l'hote ne sait pas nommer spatialement ce qu'il montre : on
  /// ne devine alors pas, et un trait hors bloc n'est simplement pas pose.
  final ContentPosition? ancrageCadre;

  /// Vrai quand la mise en page peut se recomposer sous les annotations.
  bool get estReflowable => modeAffichage != ModeAffichagePartage.page;
}

/// Ce que l'hote sait de la classe autour du support.
///
/// Trois faits, et aucun de plus : le dock n'a pas besoin d'en savoir
/// davantage, et surtout pas de la moindre donnee de famille.
@immutable
class ContexteDock {
  /// Declare le contexte courant.
  const ContexteDock({this.groupeId, this.sessionId, this.profilId});

  /// Le groupe, quand le support est ouvert dans un groupe. Sans lui, aucun
  /// travail a preparer ne peut etre pose : une assignation appartient a un
  /// groupe.
  final String? groupeId;

  /// La seance, quand le support est ouvert en classe. `null` hors classe :
  /// les couches d'annotation sont alors personnelles.
  final String? sessionId;

  /// Le profil qui manipule les outils. Auteur des couches, emetteur des
  /// evenements.
  final String? profilId;

  /// Vrai quand le support est ouvert dans une classe en cours.
  bool get enClasse => sessionId != null;
}

/// Ce que l'utilisateur a selectionne dans le support.
@immutable
class SelectionSupport {
  /// Declare une selection.
  const SelectionSupport({
    required this.plage,
    this.ancrageSemantique,
    this.ancrageSpatial,
  });

  /// La plage selectionnee. C'est elle que Focus, Marquer, Masquer et Revision
  /// prennent pour objet.
  final ContentRange plage;

  /// L'ancrage semantique le plus fin que l'hote sache donner pour cette
  /// selection : le mot, a defaut l'ayah, a defaut la section.
  final ContentPosition? ancrageSemantique;

  /// L'ancrage spatial correspondant : la page, ou une fraction du support.
  final ContentPosition? ancrageSpatial;
}

/// Le contrat par lequel un ecran accueille le Teaching Dock.
///
/// **Produit par Agent D, implemente par l'hote** -- le moteur Mushaf d'Agent C,
/// la Classe Live d'Agent E, ou la Bibliotheque d'Agent B. C'est par lui que le
/// dock s'insere sans qu'Agent D n'ecrive une ligne dans l'ecran d'un autre.
///
/// Le sens de lecture est important : l'hote **declare** ce qu'il presente et
/// ce qui est selectionne ; le dock **publie** l'etat des outils
/// (`etat_outils.dart`), que l'hote observe pour appliquer le focus, le
/// masquage et le trace. Aucun des deux n'appelle une methode de l'autre pour
/// changer son affichage : c'est ce qui evite les rappels croises et les
/// boucles de reconstruction.
///
/// La seule exception est la Bibliotheque : le dock porte le bouton, l'hote
/// ouvre le panneau, parce que **la Bibliotheque n'existe qu'une fois** et
/// qu'elle n'appartient pas a Agent D.
abstract class PortDockHote {
  /// Le groupe, la seance et le profil courants.
  ContexteDock contexte();

  /// Le support presente en ce moment. `null` quand il n'y en a aucun.
  SupportPresente? supportActif();

  /// La selection courante dans ce support. `null` quand rien n'est
  /// selectionne.
  SelectionSupport? selectionCourante();

  /// Les capacites projetees pour l'appelant, telles que l'hote les a lues du
  /// jeton serveur. `null` hors seance : le dock retombe alors sur les seuls
  /// outils qui ne dependent pas d'une classe.
  CapacitesPedagogiques? capacites();

  /// Ouvre la Bibliotheque de l'hote, en panneau ou en feuille selon sa
  /// largeur. La salle reste connectee : ouvrir la Bibliotheque n'est pas
  /// quitter le cours.
  Future<void> ouvrirBibliotheque();
}

/// Quels outils ont un sens, ici et maintenant.
///
/// **Un bouton qui ne peut pas aboutir n'est pas rendu** (`lib/CLAUDE.md`) : un
/// outil dont la capacite manque n'est pas grise, il est absent. La liste est
/// calculee une fois, a partir de trois sources et de rien d'autre : ce que le
/// support sait faire, ce que le jeton autorise, et ce qui est selectionne.
List<OutilDock> outilsDisponibles({
  SupportPresente? support,
  SelectionSupport? selection,
  CapacitesPedagogiques? capacites,
  ContexteDock contexte = const ContexteDock(),
}) {
  // Un observateur silencieux -- tuteur, controleur, admin incognito -- ne
  // recoit aucun outil, pas meme la Bibliotheque : il regarde une classe, il
  // n'y travaille pas (spec section 11).
  if (capacites != null && capacites.estObservateurSilencieux) {
    return const <OutilDock>[];
  }

  final bool peutAnnoter = capacites?.peutAnnoter ?? false;
  final bool peutPiloter = capacites?.peutPiloterSupport ?? false;
  final Set<CapaciteRessource> offertes =
      support?.capacites ?? const <CapaciteRessource>{};
  final bool avecSelection = selection != null;

  return <OutilDock>[
    // La Bibliotheque est toujours la : c'est par elle qu'on ouvre un support
    // quand il n'y en a pas encore.
    OutilDock.bibliotheque,
    if (support != null &&
        avecSelection &&
        offertes.contains(CapaciteRessource.focusable))
      OutilDock.focus,
    if (support != null &&
        avecSelection &&
        peutAnnoter &&
        offertes.contains(CapaciteRessource.annotatable))
      OutilDock.marquer,
    if (support != null && avecSelection && peutPiloter) OutilDock.masquer,
    if (support != null &&
        peutAnnoter &&
        offertes.contains(CapaciteRessource.annotatable) &&
        offertes.contains(CapaciteRessource.supportsStylus))
      OutilDock.stylet,
    if (support != null && peutPiloter) OutilDock.pointeur,
    // Un travail a preparer appartient a un groupe : sans groupe, l'outil
    // n'aurait nulle part ou poser ce qu'il cree.
    if (support != null &&
        avecSelection &&
        contexte.groupeId != null &&
        offertes.contains(CapaciteRessource.assignable))
      OutilDock.revision,
  ];
}
