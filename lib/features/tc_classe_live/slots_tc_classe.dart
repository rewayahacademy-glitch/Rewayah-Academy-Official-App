import 'package:flutter/widgets.dart';

import '../tc_catalogue/surface_bibliotheque.dart';
import 'bibliotheque_en_classe.dart';
import 'support_coran_classe.dart';

/// Une enveloppe que la Classe Live pose, et qu'un contenu remplit.
///
/// **Depuis le lot 2, chaque slot a un contenu reel par defaut** : le support
/// est le Coran suivi par l'etat partage ([SupportCoranClasse]), la
/// Bibliotheque est celle d'Agent B precedee du Coran
/// ([BibliothequeEnClasse]). [contenu] reste un point d'injection : un test
/// ou un futur support d'un autre type le remplit, et la coque ne le sait
/// pas.
@immutable
class SlotClasse {
  /// Cree un slot.
  const SlotClasse({
    required this.sessionId,
    this.groupeId,
    this.resourceId,
    this.contenu,
  });

  /// La seance en cours. Tout slot de classe en depend.
  final String sessionId;

  /// Le groupe dont la seance est l'etat temporaire, quand il est connu.
  final String? groupeId;

  /// La ressource concernee, quand le slot en designe une.
  ///
  /// `null` sur le slot de support signifie **aucun support presente**, et c'est
  /// ce seul fait qui fait basculer la composition de l'ecran (spec 9.1).
  final String? resourceId;

  /// Un contenu impose. `null` = le contenu reel par defaut.
  final WidgetBuilder? contenu;

  /// Vrai quand un contenu est impose.
  bool get rempli => contenu != null;
}

/// Le support pedagogique presente a la classe.
///
/// **Il domine l'ecran des qu'il existe** (spec section 9.1). La Classe Live ne
/// rend aucun support elle-meme : elle lui donne la place, et
/// [SupportCoranClasse] suit l'etat partage de la seance.
class SurfaceSupport extends StatelessWidget {
  /// Pose la surface du support.
  const SurfaceSupport({
    required this.slot,
    required this.peutPiloter,
    super.key,
  });

  /// Le slot a rendre.
  final SlotClasse slot;

  /// Le jeton autorise a piloter le support.
  final bool peutPiloter;

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? contenu = slot.contenu;
    if (contenu != null) {
      return contenu(context);
    }
    return SupportCoranClasse(
      sessionId: slot.sessionId,
      peutPiloter: peutPiloter,
    );
  }
}

/// La Bibliotheque ouverte **dans** la classe.
///
/// **La room reste connectee** (decision D-20) : cette surface s'ouvre comme un
/// panneau ou une feuille par-dessus la Classe Live, jamais comme une
/// navigation. Rien ici n'appelle le routeur, et c'est verifiable d'un `grep`.
class EmplacementBibliothequeEnClasse extends StatelessWidget {
  /// Pose la surface de la Bibliotheque en classe.
  const EmplacementBibliothequeEnClasse({
    required this.slot,
    required this.enPanneau,
    required this.onPresenterCoran,
    required this.onChoisir,
    super.key,
  });

  /// Le slot a rendre.
  final SlotClasse slot;

  /// Vrai dans le panneau lateral, faux dans une feuille.
  final bool enPanneau;

  /// Presente le Coran au groupe.
  final VoidCallback onPresenterCoran;

  /// Un support du catalogue a ete choisi.
  final ChoixRessource onChoisir;

  @override
  Widget build(BuildContext context) {
    final WidgetBuilder? contenu = slot.contenu;
    if (contenu != null) {
      return contenu(context);
    }
    return BibliothequeEnClasse(
      groupeId: slot.groupeId,
      enPanneau: enPanneau,
      onPresenterCoran: onPresenterCoran,
      onChoisir: onChoisir,
    );
  }
}
