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
