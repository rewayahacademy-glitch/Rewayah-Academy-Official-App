// GUIDE-COMMENTAIRES (directeur, 21/11/2026 : « il faut ouvrir la page des
// commentaires cote admin ») : le contrat de la page de la direction qui lit
// les commentaires du guide de l'enseignant et y repond.
//
// Forme JSON rendue par `commentaires_guide_direction()` :
//   {"parties": [{"code": "p4", "titre": "La paie", "jaime": 12,
//                 "pas_clair": 3,
//                 "fils": [{"lecteur_id": "...", "lecteur": "Prenom Nom",
//                           "messages": [{"id": "...", "corps": "...",
//                                         "cree_le": "ISO 8601",
//                                         "auteur": "lecteur" | "direction"
//                                                   | "praxis",
//                                         "parent_id": "..." | null}]}]}]}
// Les parties viennent du serveur triees par « Pas clair » decroissant.
// `repondre_commentaire_guide(p_commentaire, p_corps)` rend le message cree.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';

/// Qui a ecrit un message du fil.
enum AuteurMessageGuide {
  /// Le lecteur du guide.
  lecteur,

  /// La direction.
  direction,

  /// Praxis.
  praxis;

  /// Lit une valeur du serveur.
  static AuteurMessageGuide depuis(Object? brut) => switch (brut) {
    'lecteur' => AuteurMessageGuide.lecteur,
    'direction' => AuteurMessageGuide.direction,
    'praxis' => AuteurMessageGuide.praxis,
    _ => throw const FormatException('guide : auteur inconnu'),
  };
}

/// Un message d'un fil.
class MessageGuide {
  /// Cree le message.
  const MessageGuide({
    required this.id,
    required this.corps,
    required this.creeLe,
    required this.auteur,
  });

  /// Lit un message du serveur.
  factory MessageGuide.depuisJson(Map<String, dynamic> brut) => MessageGuide(
    id: brut['id'] as String,
    corps: brut['corps'] as String,
    creeLe: DateTime.parse(brut['cree_le'] as String),
    auteur: AuteurMessageGuide.depuis(brut['auteur']),
  );

  /// L'identifiant.
  final String id;

  /// Le texte.
  final String corps;

  /// La date.
  final DateTime creeLe;

  /// L'auteur.
  final AuteurMessageGuide auteur;
}

/// Le fil d'un lecteur sur une partie.
class FilGuide {
  /// Cree le fil.
  const FilGuide({required this.lecteur, required this.messages});

  /// Lit un fil du serveur.
  factory FilGuide.depuisJson(Map<String, dynamic> brut) => FilGuide(
    lecteur: brut['lecteur'] as String,
    messages: <MessageGuide>[
      for (final Object? m in brut['messages'] as List<dynamic>)
        MessageGuide.depuisJson(m! as Map<String, dynamic>),
    ],
  );

  /// Le nom du lecteur.
  final String lecteur;

  /// Les messages, dans l'ordre.
  final List<MessageGuide> messages;

  /// Vrai quand le dernier message vient du lecteur : il attend une reponse.
  bool get attendReponse =>
      messages.isNotEmpty && messages.last.auteur == AuteurMessageGuide.lecteur;
}

/// Une partie du guide, ses totaux et ses fils.
class PartieGuideDirection {
  /// Cree la partie.
  const PartieGuideDirection({
    required this.code,
    required this.titre,
    required this.jaime,
    required this.pasClair,
    required this.fils,
  });

  /// Lit une partie du serveur.
  factory PartieGuideDirection.depuisJson(Map<String, dynamic> brut) =>
      PartieGuideDirection(
        code: brut['code'] as String,
        titre: brut['titre'] as String,
        jaime: (brut['jaime'] as num).toInt(),
        pasClair: (brut['pas_clair'] as num).toInt(),
        fils: <FilGuide>[
          for (final Object? f in brut['fils'] as List<dynamic>)
            FilGuide.depuisJson(f! as Map<String, dynamic>),
        ],
      );

  /// Le code de la partie (`p1` a `p14`).
  final String code;

  /// Le titre de la partie, en francais.
  final String titre;

  /// Le nombre de « J'aime ».
  final int jaime;

  /// Le nombre de « Pas clair ».
  final int pasClair;

  /// Les fils des lecteurs.
  final List<FilGuide> fils;
}

/// Le port de la page de la direction.
abstract interface class PortCommentairesGuide {
  /// Les parties, triees par « Pas clair » decroissant.
  Future<List<PartieGuideDirection>> lire();

  /// Repond a [commentaire] dans le fil de son lecteur.
  Future<MessageGuide> repondre({
    required String commentaire,
    required String corps,
  });
}

/// Tant que le serveur n'est pas branche.
class PortCommentairesGuideIndisponible implements PortCommentairesGuide {
  /// Cree le port.
  const PortCommentairesGuideIndisponible();

  static const CapaciteIndisponible _absent = CapaciteIndisponible(
    'GUIDE-COMMENTAIRES',
  );

  @override
  Future<List<PartieGuideDirection>> lire() =>
      Future<List<PartieGuideDirection>>.error(_absent);

  @override
  Future<MessageGuide> repondre({
    required String commentaire,
    required String corps,
  }) => Future<MessageGuide>.error(_absent);
}

/// Le port en service ; l'adaptateur Supabase le remplace.
final Provider<PortCommentairesGuide> portCommentairesGuideProvider =
    Provider<PortCommentairesGuide>(
      (Ref _) => const PortCommentairesGuideIndisponible(),
    );

/// La lecture des parties, relue apres chaque reponse.
final FutureProvider<List<PartieGuideDirection>> commentairesGuideProvider =
    FutureProvider<List<PartieGuideDirection>>(
      (Ref ref) => ref.watch(portCommentairesGuideProvider).lire(),
    );
