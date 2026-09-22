import 'package:flutter/foundation.dart';

import '../../core/tc_bibliotheque/content_range.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_etat_partage/shared_content_state.dart';
import '../../core/tc_outils/port_dock_hote.dart';
import '../../core/tc_realtime/port_realtime_pedagogique.dart';
import '../salle/vue_salle.dart';

/// Ce que le moteur Mushaf, tel qu'il est rendu en classe, sait faire.
///
/// **Declare, jamais deduit d'un fichier de ressource** : la Bibliotheque est
/// vide en production (`CatalogueLocal()`), et le Coran est rendu par le
/// moteur C, dont les capacites sont celles de son code. `annotatable`,
/// `supportsStylus` et le masquage n'y sont pas : le renderer ne les rend pas.
const Set<CapaciteRessource> capacitesCoranEnClasse = <CapaciteRessource>{
  CapaciteRessource.pageable,
  CapaciteRessource.searchable,
  CapaciteRessource.zoomable,
  CapaciteRessource.selectable,
  CapaciteRessource.focusable,
  CapaciteRessource.presentableInClass,
};

/// L'hote du Teaching Dock dans la Classe Live.
///
/// **Il declare ce que la Classe presente et ce qui est selectionne** ; le dock
/// publie l'etat des outils, que l'hote observe. Aucun des deux n'appelle une
/// methode de l'autre pour changer son affichage (`PortDockHote`).
///
/// **Il ne declare que ce qu'il rend.** Le jeton peut accorder
/// `peutPiloterSupport` et `peutAnnoter` ; l'hote les retire pour le dock,
/// parce que le Mushaf rendu en classe ne peint ni masquage, ni pointeur, ni
/// trait. Un outil sans effet visible est un bouton qui ne peut pas aboutir,
/// donc un bouton absent (`lib/CLAUDE.md`). Le pilotage reel du support --
/// page, mode, support -- passe par la rangee basse du support, pas par le
/// dock.
///
/// ponytail: plafond connu et voie de sortie nommee. Le jour ou le renderer
/// rend le masquage (mode verset : verset remplace par un bloc semantique
/// « verset masque ») et le pointeur, [capacites] rendra les drapeaux du jeton
/// tels quels. Aucun autre fichier ne change.
class HoteDockClasse implements PortDockHote {
  /// Cree l'hote.
  ///
  /// Trois lectures **a l'usage** : le dock relit l'hote a chaque construction,
  /// et un hote qui capturerait ces valeurs a sa creation decrirait une classe
  /// d'il y a une minute.
  HoteDockClasse({
    required this.sessionId,
    required ValueGetter<SharedContentState?> etatPartage,
    required ValueGetter<ContentRange?> selection,
    required ValueGetter<VueSalle> salle,
    required Future<void> Function() ouvrirBibliotheque,
    this.groupeId,
    this.profilId,
  }) : _etatPartage = etatPartage, // ignore: prefer_initializing_formals
       _selection = selection, // ignore: prefer_initializing_formals
       _salle = salle, // ignore: prefer_initializing_formals
       // ignore: prefer_initializing_formals
       _ouvrirBibliotheque = ouvrirBibliotheque;

  /// La seance.
  final String sessionId;

  /// Le groupe, quand il est connu. Sans lui, aucun travail ne peut etre pose.
  final String? groupeId;

  /// Le profil qui manipule les outils.
  final String? profilId;

  final ValueGetter<SharedContentState?> _etatPartage;
  final ValueGetter<ContentRange?> _selection;
  final ValueGetter<VueSalle> _salle;
  final Future<void> Function() _ouvrirBibliotheque;

  /// Ouvre la Bibliotheque de la Classe, en panneau ou en feuille. La salle
  /// reste connectee.
  @override
  Future<void> ouvrirBibliotheque() => _ouvrirBibliotheque();

  @override
  ContexteDock contexte() => ContexteDock(
    groupeId: groupeId,
    sessionId: sessionId,
    profilId: profilId,
  );

  @override
  SupportPresente? supportActif() {
    final SharedContentState? etat = _etatPartage();
    if (etat == null) {
      return null;
    }
    return SupportPresente(
      resourceId: etat.resourceId,
      resourceVersionId: etat.resourceVersionId,
      capacites: capacitesCoranEnClasse,
      modeAffichage: etat.displayMode,
    );
  }

  @override
  SelectionSupport? selectionCourante() {
    final ContentRange? plage = _selection();
    if (plage == null) {
      return null;
    }
    return SelectionSupport(plage: plage, ancrageSemantique: plage.debut);
  }

  /// Les capacites projetees, **lues du jeton** par `VueSalle`, puis reduites a
  /// ce que cet hote rend.
  @override
  CapacitesPedagogiques? capacites() {
    final VueSalle salle = _salle();
    return CapacitesPedagogiques(
      peutPiloterSupport: false,
      peutAnnoter: false,
      peutEmettreNudge: false,
      estObservateurSilencieux: !salle.peutParler && !salle.peutPresenter,
    );
  }
}
