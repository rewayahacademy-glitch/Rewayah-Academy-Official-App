// LETTRE-CANDIDATS (directeur, 20/11/2026 : « seulement les enseignants et
// les candidats qui ont complete les consentements […] Ca doit se faire
// aussi cote serveur ») : le contrat de lecture de la lettre.
//
// Le texte de la lettre n'est PAS dans l'application compilee : il vient du
// serveur, qui ne le rend qu'a qui a le droit de le lire. Ce fichier fixe la
// forme de la reponse ; l'adaptateur Supabase (lot du pilote, fonction
// `public.lire_lettre_candidats(p_langue text)`) la remplit.
//
// Forme JSON rendue par le serveur, a la lettre :
//
//   acces vrai :
//     {"acces": true, "version": "2026-11-20", "langue": "fr",
//      "parties": [{"code": "p1", "titre": "...", "corps": "..."}, ...]}
//   acces faux :
//     {"acces": false, "raison": "accords" | "role" | "compte",
//      "manques": ["contrat", "conduite", "cadre"]}
//
// `parties` : dans l'ordre de lecture, quatorze aujourd'hui ; `corps` dans la
// forme simple que lit `texte_lettre.dart`. `manques` : seulement pour la
// raison `accords`, dans l'ordre contrat, conduite, cadre. Aucun texte de la
// lettre quand l'acces est refuse.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../../core/capacites/capacite_indisponible.dart';

/// Une partie de la lettre.
class PartieLettre {
  /// Cree la partie.
  const PartieLettre({
    required this.code,
    required this.titre,
    required this.corps,
  });

  /// Lit une partie rendue par le serveur.
  factory PartieLettre.depuisJson(Map<String, dynamic> brut) => PartieLettre(
    code: brut['code'] as String,
    titre: brut['titre'] as String,
    corps: brut['corps'] as String,
  );

  /// Le code stable de la partie (`p1` a `p14`).
  final String code;

  /// Le titre, sans numero.
  final String titre;

  /// Le corps.
  final String corps;
}

/// Ce qu'un candidat doit encore accepter pour lire la lettre.
enum AccordManquant {
  /// Le contrat d'enseignant.
  contrat,

  /// Le code de conduite.
  conduite,

  /// L'engagement religieux, quand il est publie.
  cadre,
}

/// Pourquoi le serveur refuse la lecture.
enum RaisonRefusLettre {
  /// Des accords manquent (candidat enseignant).
  accords,

  /// Le compte n'est ni enseignant ni candidat enseignant.
  role,

  /// Le compte est suspendu ou illisible.
  compte,
}

/// Ce que rend le serveur.
class LectureLettre {
  /// La lettre, lisible.
  const LectureLettre.ouverte({
    required this.parties,
    required this.version,
    required this.langue,
  }) : acces = true,
       raison = null,
       manques = const <AccordManquant>[];

  /// La lecture refusee, sans aucun texte.
  const LectureLettre.refusee({
    required RaisonRefusLettre this.raison,
    this.manques = const <AccordManquant>[],
  }) : acces = false,
       parties = const <PartieLettre>[],
       version = null,
       langue = null;

  /// Lit la reponse du serveur. Une forme inattendue leve une
  /// [FormatException] : la page dit alors qu'elle n'a pas pu s'ouvrir.
  factory LectureLettre.depuisJson(Map<String, dynamic> brut) {
    if (brut['acces'] == true) {
      final List<PartieLettre> parties = (brut['parties'] as List<dynamic>)
          .map(
            (Object? p) => PartieLettre.depuisJson(p! as Map<String, dynamic>),
          )
          .toList();
      if (parties.isEmpty) {
        throw const FormatException('lettre : aucune partie');
      }
      return LectureLettre.ouverte(
        parties: parties,
        version: brut['version'] as String? ?? '',
        langue: brut['langue'] as String? ?? '',
      );
    }
    final RaisonRefusLettre raison = switch (brut['raison']) {
      'accords' => RaisonRefusLettre.accords,
      'role' => RaisonRefusLettre.role,
      'compte' => RaisonRefusLettre.compte,
      _ => throw const FormatException('lettre : raison inconnue'),
    };
    final List<AccordManquant> manques = <AccordManquant>[
      for (final Object? m
          in (brut['manques'] as List<dynamic>?) ?? <Object?>[])
        switch (m) {
          'contrat' => AccordManquant.contrat,
          'conduite' => AccordManquant.conduite,
          'cadre' => AccordManquant.cadre,
          _ => throw const FormatException('lettre : accord inconnu'),
        },
    ];
    return LectureLettre.refusee(raison: raison, manques: manques);
  }

  /// Vrai quand la lettre est lisible.
  final bool acces;

  /// La raison du refus, nulle quand l'acces est ouvert.
  final RaisonRefusLettre? raison;

  /// Les accords qui manquent (raison `accords`).
  final List<AccordManquant> manques;

  /// Les parties, dans l'ordre de lecture ; vides quand l'acces est refuse.
  final List<PartieLettre> parties;

  /// La version du texte rendu.
  final String? version;

  /// La langue du texte rendu.
  final String? langue;
}

/// Le port de lecture de la lettre.
abstract interface class PortLettre {
  /// La lettre dans [langue] (`fr`, `en`, `ar`), ou le refus du serveur.
  Future<LectureLettre> lire({required String langue});
}

/// Tant que l'adaptateur Supabase n'est pas branche : la capacite est
/// indisponible, la page le dit. Aucun texte de repli dans l'application.
class PortLettreIndisponible implements PortLettre {
  /// Cree le port.
  const PortLettreIndisponible();

  @override
  Future<LectureLettre> lire({required String langue}) =>
      Future<LectureLettre>.error(const CapaciteIndisponible('LETTRE-SERVEUR'));
}

/// Le port en service ; l'adaptateur Supabase remplace la valeur par defaut.
final Provider<PortLettre> portLettreProvider = Provider<PortLettre>(
  (Ref _) => const PortLettreIndisponible(),
);

/// La lettre dans une langue.
final FutureProviderFamily<LectureLettre, String> lettreProvider =
    FutureProvider.family<LectureLettre, String>(
      (Ref ref, String langue) =>
          ref.watch(portLettreProvider).lire(langue: langue),
    );

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
  const InteractionsGuide({required this.avis, required this.commentaires});

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
      );

  /// Les totaux par code de partie.
  final Map<String, AvisPartie> avis;

  /// Les fils du lecteur, dans l'ordre de creation.
  final List<CommentaireGuide> commentaires;
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
