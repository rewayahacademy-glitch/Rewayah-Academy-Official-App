// LETTRE-CANDIDATS, lot 2 (directeur, 20/11/2026, 23 h) : le contrat des
// interactions du guide de l'enseignant, a part du contrat de lecture
// (`port_lettre.dart`) a la demande du pilote : la lecture se livre d'abord.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';

// --- Interactions du guide (directeur, 20/11/2026, 23 h) -------------------
//
// « je veux que les gens puissent y commenter directement, ces commentaires
// doivent etre vus par l'admin et par Praxis qui peut y repondre ; on peut
// aussi laisser des likes [et des dislikes] ; ces interactions sont
// publiques, sauf les commentaires. »
//
// Forme JSON rendue par `lire_interactions_guide()` :
//   {"parties": [{"code": "p1", "jaime": 12, "pas_clair": 3,
//                 "mon_avis": "jaime" | "pas_clair" | null}],
//    "commentaires": [{"id": "...", "partie": "p4", "corps": "...",
//                      "cree_le": "ISO 8601",
//                      "auteur": "moi" | "direction" | "praxis",
//                      "parent_id": "..." | null}]}
// `commentaires` : seulement les fils de l'appelant, reponses comprises.
// `commentaires_ouverts` (21/11/2026) : faux tant que la direction ne lit pas
// les commentaires ; absent, vrai.
// `donner_avis_guide(p_partie, p_avis)` rend la ligne de la partie a jour ;
// `commenter_guide(p_partie, p_corps)` rend le commentaire cree.

/// L'avis d'un lecteur sur une partie.
enum AvisGuide {
  /// « J'aime ».
  jaime,

  /// « Pas clair » : le passage est a reformuler.
  pasClair;

  /// La valeur echangee avec le serveur.
  String get cle => this == AvisGuide.jaime ? 'jaime' : 'pas_clair';

  /// Lit une valeur du serveur ; nulle pour « aucun avis ».
  static AvisGuide? depuis(Object? brut) => switch (brut) {
    null => null,
    'jaime' => AvisGuide.jaime,
    'pas_clair' => AvisGuide.pasClair,
    _ => throw const FormatException('guide : avis inconnu'),
  };
}

/// Les totaux publics d'une partie, et l'avis du lecteur.
class AvisPartie {
  /// Cree la ligne.
  const AvisPartie({
    required this.code,
    required this.jaime,
    required this.pasClair,
    this.monAvis,
  });

  /// Lit une ligne du serveur.
  factory AvisPartie.depuisJson(Map<String, dynamic> brut) => AvisPartie(
    code: brut['code'] as String,
    jaime: (brut['jaime'] as num).toInt(),
    pasClair: (brut['pas_clair'] as num).toInt(),
    monAvis: AvisGuide.depuis(brut['mon_avis']),
  );

  /// Le code de la partie.
  final String code;

  /// Le nombre de « J'aime ».
  final int jaime;

  /// Le nombre de « Pas clair ».
  final int pasClair;

  /// L'avis du lecteur, nul s'il n'en a donne aucun.
  final AvisGuide? monAvis;

  /// La ligne apres que le lecteur a choisi [avis] (nul : retire son avis),
  /// calculee ici pour l'afficher tout de suite (DECISION-FLUIDITE).
  AvisPartie avec(AvisGuide? avis) {
    int j = jaime, p = pasClair;
    if (monAvis == AvisGuide.jaime) j--;
    if (monAvis == AvisGuide.pasClair) p--;
    if (avis == AvisGuide.jaime) j++;
    if (avis == AvisGuide.pasClair) p++;
    return AvisPartie(code: code, jaime: j, pasClair: p, monAvis: avis);
  }
}

/// Qui a ecrit un commentaire.
enum AuteurCommentaire {
  /// Le lecteur lui-meme.
  moi,

  /// La direction.
  direction,

  /// Praxis, l'assistant de l'academie.
  praxis,
}

/// Un commentaire du fil d'un lecteur.
class CommentaireGuide {
  /// Cree le commentaire.
  const CommentaireGuide({
    required this.id,
    required this.partie,
    required this.corps,
    required this.creeLe,
    required this.auteur,
    this.parentId,
  });

  /// Lit un commentaire du serveur.
  factory CommentaireGuide.depuisJson(Map<String, dynamic> brut) =>
      CommentaireGuide(
        id: brut['id'] as String,
        partie: brut['partie'] as String,
        corps: brut['corps'] as String,
        creeLe: DateTime.parse(brut['cree_le'] as String),
        auteur: switch (brut['auteur']) {
          'moi' => AuteurCommentaire.moi,
          'direction' => AuteurCommentaire.direction,
          'praxis' => AuteurCommentaire.praxis,
          _ => throw const FormatException('guide : auteur inconnu'),
        },
        parentId: brut['parent_id'] as String?,
      );

  /// L'identifiant.
  final String id;

  /// Le code de la partie commentee.
  final String partie;

  /// Le texte.
  final String corps;

  /// La date de creation.
  final DateTime creeLe;

  /// L'auteur.
  final AuteurCommentaire auteur;

  /// Le commentaire auquel celui-ci repond, nul pour un premier commentaire.
  final String? parentId;
}

/// Ce que rend `lire_interactions_guide()`.
class InteractionsGuide {
  /// Cree l'ensemble.
  const InteractionsGuide({
    required this.avis,
    required this.commentaires,
    this.commentairesOuverts = true,
  });

  /// Lit la reponse du serveur.
  factory InteractionsGuide.depuisJson(Map<String, dynamic> brut) =>
      InteractionsGuide(
        avis: <String, AvisPartie>{
          for (final Object? p in brut['parties'] as List<dynamic>)
            (p! as Map<String, dynamic>)['code'] as String:
                AvisPartie.depuisJson(p as Map<String, dynamic>),
        },
        commentaires: <CommentaireGuide>[
          for (final Object? c in brut['commentaires'] as List<dynamic>)
            CommentaireGuide.depuisJson(c! as Map<String, dynamic>),
        ],
        commentairesOuverts: brut['commentaires_ouverts'] as bool? ?? true,
      );

  /// Les totaux par code de partie.
  final Map<String, AvisPartie> avis;

  /// Les fils du lecteur, dans l'ordre de creation.
  final List<CommentaireGuide> commentaires;

  /// Faux tant que la direction n'a aucun ecran pour lire les commentaires et
  /// y repondre (21/11/2026) : le serveur le dit, l'ecran ne propose alors ni
  /// « Commenter » ni le fil, jamais une promesse de reponse qu'on ne tient pas.
  final bool commentairesOuverts;
}

/// Le port des interactions du guide.
abstract interface class PortInteractionsGuide {
  /// Les totaux et les fils du lecteur.
  Future<InteractionsGuide> lire();

  /// Donne [avis] sur [partie] (nul : retire l'avis) ; rend la ligne a jour.
  Future<AvisPartie> donnerAvis({required String partie, AvisGuide? avis});

  /// Ecrit un commentaire sur [partie] ; rend le commentaire cree.
  Future<CommentaireGuide> commenter({
    required String partie,
    required String corps,
  });
}

/// Tant que le serveur n'est pas branche : les interactions n'apparaissent
/// pas (la lecture reste possible).
class PortInteractionsIndisponible implements PortInteractionsGuide {
  /// Cree le port.
  const PortInteractionsIndisponible();

  static const CapaciteIndisponible _absent = CapaciteIndisponible(
    'GUIDE-INTERACTIONS',
  );

  @override
  Future<InteractionsGuide> lire() => Future<InteractionsGuide>.error(_absent);

  @override
  Future<AvisPartie> donnerAvis({required String partie, AvisGuide? avis}) =>
      Future<AvisPartie>.error(_absent);

  @override
  Future<CommentaireGuide> commenter({
    required String partie,
    required String corps,
  }) => Future<CommentaireGuide>.error(_absent);
}

/// Le port des interactions en service ; l'adaptateur Supabase le remplace.
final Provider<PortInteractionsGuide> portInteractionsProvider =
    Provider<PortInteractionsGuide>(
      (Ref _) => const PortInteractionsIndisponible(),
    );

/// La longueur maximale d'un commentaire, que le serveur verifie aussi.
const int longueurMaxCommentaire = 2000;
