/// IMM-ACCUEIL-FRONT : la reclamation d'une pre-inscription importee, apres
/// la preuve de l'adresse e-mail (`DECISION-IMMATRICULATION-2026-10-12.md`
/// §5, points 2 a 5).
///
/// Le serveur fait tout : `reclamer_preinscription_apres_preuve()` ne regarde
/// l'import qu'apres la confirmation Auth de l'adresse, rattache le foyer
/// pre-inscrit au compte, cree le profil du tuteur (avec son matricule
/// reserve) et, pour un adulte, sa fiche d'eleve autonome (B2.1). L'appel est
/// idempotent : le rejouer ne cree rien de plus. Le mot d'accueil n'est rendu
/// qu'a la premiere reclamation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La nature d'une personne importee, telle que le serveur la nomme.
enum NaturePersonneImportee {
  /// Le tuteur du foyer (`guardian`).
  tuteur,

  /// Un adulte qui apprend pour lui-meme (`adult`).
  adulte,

  /// Un eleve du foyer, enfant ou mineur (`student`).
  eleve,

  /// Toute autre valeur : l'ecran ne la montre pas.
  autre;

  /// Lit la valeur du serveur.
  static NaturePersonneImportee depuisServeur(Object? valeur) =>
      switch (valeur) {
        'guardian' => tuteur,
        'adult' => adulte,
        'student' => eleve,
        _ => autre,
      };
}

/// Une personne du foyer importe : son prenom, rien de plus.
class PersonneImportee {
  /// Cree la personne.
  const PersonneImportee({
    required this.id,
    required this.prenom,
    required this.nature,
  });

  /// L'identifiant de la ligne de pre-inscription (jamais affiche).
  final String id;

  /// Le prenom importe, tel que la famille l'avait ecrit.
  final String prenom;

  /// Tuteur, adulte ou eleve.
  final NaturePersonneImportee nature;
}

/// Ce que la reclamation a rendu.
class ReclamationPreinscription {
  /// Cree le resultat.
  const ReclamationPreinscription({
    required this.connue,
    this.motAccueil,
    this.personnes = const <PersonneImportee>[],
  });

  /// Aucune pre-inscription pour ce compte (ou adresse non prouvee) : le
  /// parcours d'inscription habituel, inchange.
  const ReclamationPreinscription.inconnue() : this(connue: false);

  /// Vrai quand une pre-inscription confirmee porte l'adresse prouvee du
  /// compte et vient de lui etre rattachee.
  final bool connue;

  /// Le mot personnel saisi ou retouche par la direction (mot de patience
  /// d'abord, sinon mot d'accueil). `null` : aucun, ou deja montre.
  final String? motAccueil;

  /// Les personnes du foyer importe, dans l'ordre de l'import.
  final List<PersonneImportee> personnes;

  /// Les eleves importes, dont le profil se cree depuis l'accueil.
  List<PersonneImportee> get eleves => <PersonneImportee>[
    for (final PersonneImportee p in personnes)
      if (p.nature == NaturePersonneImportee.eleve) p,
  ];
}

/// L'echec de la reclamation : le serveur a repondu par un refus ou une forme
/// inattendue. Rien n'est cree par le client ; l'appel peut se rejouer.
class ReclamationEnEchec implements Exception {
  /// Cree l'echec.
  const ReclamationEnEchec();
}

/// Aucune reponse du serveur (reseau coupe, delai depasse).
class ReclamationInjoignable implements Exception {
  /// Cree l'echec.
  const ReclamationInjoignable();
}

/// La reclamation d'une pre-inscription importee.
abstract interface class PortReclamationPreinscription {
  /// Faux quand aucun serveur ne repond a cet appel (tests, demonstration) :
  /// le parcours habituel s'ouvre sans attendre.
  bool get disponible;

  /// Appelle le serveur. Leve [ReclamationEnEchec] ou
  /// [ReclamationInjoignable] ; jamais d'autre exception.
  Future<ReclamationPreinscription> reclamer();
}

/// Le port par defaut, sans serveur : aucune pre-inscription. Les tests et la
/// demonstration gardent ainsi le parcours habituel ; `main.dart` le remplace
/// par l'adaptateur Supabase.
class ReclamationSansServeur implements PortReclamationPreinscription {
  /// Cree le port.
  const ReclamationSansServeur();

  @override
  bool get disponible => false;

  @override
  Future<ReclamationPreinscription> reclamer() async =>
      const ReclamationPreinscription.inconnue();
}

/// Le port employe par l'application.
final Provider<PortReclamationPreinscription>
portReclamationPreinscriptionProvider = Provider<PortReclamationPreinscription>(
  (Ref ref) => const ReclamationSansServeur(),
);
