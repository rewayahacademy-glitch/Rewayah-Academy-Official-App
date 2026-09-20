import 'package:flutter/widgets.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/empty_state.dart';

/// Une enveloppe que la Classe Live pose, et qu'un autre agent remplit.
///
/// **C'est l'AMENDEMENT 2 de `TEACHING_CORE_CONTRACTS.md`, applique.** Trois
/// surfaces manquent a la Classe Live, et aucune des trois ne peut etre stubee :
///
/// - le **support pedagogique** : rendu par le moteur Mushaf d'Agent C ou par le
///   lecteur d'Agent B, dont la chaine de types (`LibraryResource`,
///   `ResourceVersion`, `PageMushafVM`, `PortLayoutMushaf`) est ouverte ;
/// - le **Teaching Dock** : `PortDockHote` est **nomme** au contrat (section 17,
///   tableau des ports) mais **aucune signature n'en est donnee**. On ne copie
///   pas une classe abstraite qui n'existe pas ;
/// - le **ClassLibraryPicker** : declare comme « surface reutilisable » d'Agent
///   B, sans signature non plus.
///
/// Un slot porte donc **un identifiant de contexte et un constructeur de
/// contenu**, rien d'autre. Tant que le contenu est `null`, la Classe Live rend
/// un etat **explicite** -- jamais un blanc, jamais une commande grisee qui
/// n'aboutirait pas.
///
/// Les demandes de signature sont en section 4 de
/// `docs/teaching-core/TC_CONTRACT_REQUEST_E.md`.
@immutable
class SlotClasse {
  /// Cree un slot.
  const SlotClasse({
    required this.sessionId,
    required this.groupeId,
    this.resourceId,
    this.contenu,
  });

  /// La seance en cours. Tout slot de classe en depend.
  final String sessionId;

  /// Le groupe dont la seance est l'etat temporaire.
  final String groupeId;

  /// La ressource concernee, quand le slot en designe une.
  ///
  /// `null` sur le slot de support signifie **aucun support presente**, et c'est
  /// ce seul fait qui fait basculer la composition de l'ecran (spec 9.1).
  final String? resourceId;

  /// Ce que l'agent proprietaire rend. `null` tant qu'il n'est pas branche.
  final WidgetBuilder? contenu;

  /// Vrai quand quelqu'un remplit ce slot.
  bool get rempli => contenu != null;
}

/// Le support pedagogique presente a la classe.
///
/// **Il domine l'ecran des qu'il existe** (spec section 9.1), et il vient de la
/// Bibliotheque -- la seule, celle d'Agent B, la meme hors classe et en classe
/// (decision D-20). La Classe Live ne rend aucun support elle-meme : elle lui
/// donne la place.
class SurfaceSupport extends StatelessWidget {
  /// Pose la surface du support.
  const SurfaceSupport({required this.slot, super.key});

  /// Le slot a rendre.
  final SlotClasse slot;

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? contenu = slot.contenu;
    if (contenu != null) {
      return contenu(context);
    }
    // Aucun support n'est presente : on le dit, et on dit ce qu'il faut faire.
    // `RegistreVide.subi` serait faux ici -- l'enseignant PEUT agir, il lui
    // manque seulement la Bibliotheque.
    return EmptyState(
      message: t.tc.classe.support.aucun,
      invitation: t.tc.classe.support.aucunDetail,
      registre: RegistreVide.subi,
    );
  }
}

/// L'hote du Teaching Dock d'Agent D.
///
/// **Flottant, et seulement au-dessus d'un support** : un dock pose sur une
/// scene video n'aurait rien a outiller. La decision est prise par
/// `VueClasseLive.dockFlottant`, jamais ici.
///
/// Il ne rend **rien** tant qu'Agent D n'est pas branche -- pas meme un cadre
/// vide : un dock en attente occuperait la place du Coran pour ne rien offrir.
/// C'est la seule surface de ce fichier qui se tait, et c'est voulu.
class HoteDock extends StatelessWidget {
  /// Pose l'hote du dock.
  const HoteDock({required this.slot, super.key});

  /// Le slot a rendre.
  final SlotClasse slot;

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? contenu = slot.contenu;
    return contenu == null ? const SizedBox.shrink() : contenu(context);
  }
}

/// La Bibliotheque ouverte **dans** la classe.
///
/// **Coquille d'Agent E.** La vraie surface, celle qui lit le catalogue, est
/// `SurfaceBibliotheque` d'Agent B
/// (`lib/features/tc_catalogue/surface_bibliotheque.dart`) -- deux lots ont
/// choisi le meme nom independamment. Renomme au cablage des slots (plan
/// d'integration Teaching Core section 5.5) pour lever la collision : c'est
/// toujours la coquille qui change de nom, jamais l'implementation reelle.
///
/// **La room reste connectee** (decision D-20) : cette surface s'ouvre comme un
/// panneau ou une feuille par-dessus la Classe Live, jamais comme une
/// navigation. Rien ici n'appelle le routeur, et c'est verifiable d'un `grep`.
class EmplacementBibliothequeEnClasse extends StatelessWidget {
  /// Pose la surface de la Bibliotheque en classe.
  const EmplacementBibliothequeEnClasse({required this.slot, super.key});

  /// Le slot a rendre.
  final SlotClasse slot;

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? contenu = slot.contenu;
    if (contenu != null) {
      return contenu(context);
    }
    return EmptyState(
      message: t.tc.classe.support.bibliothequeAbsente,
      invitation: t.tc.classe.support.bibliothequeAbsenteDetail,
      registre: RegistreVide.subi,
    );
  }
}
