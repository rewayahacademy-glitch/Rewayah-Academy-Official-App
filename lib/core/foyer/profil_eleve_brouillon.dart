import 'package:flutter/foundation.dart';

/// Pour qui le profil eleve est cree.
///
/// Les trois choix sont **montres** a l'ecran, un seul est creable
/// aujourd'hui : le serveur ne sait creer qu'un profil `minor` rattache au
/// foyer. Un proche adulte (DB-FOY-02) et le titulaire lui-meme (DB-FOY-01)
/// restent visibles et expliques, jamais simules par un profil d'enfant.
enum PourQui {
  /// Un enfant ou un mineur du foyer. Seul choix creable aujourd'hui.
  enfantOuMineur,

  /// Un adulte proche, eleve a part entiere. Indisponible (DB-FOY-02).
  procheAdulte,

  /// Le titulaire du compte lui-meme. Indisponible (DB-FOY-01).
  moiMeme,
}

/// Les champs du formulaire, dans l'ordre de l'ecran.
enum ChampProfilEleve {
  /// Le choix « pour qui ».
  pourQui,

  /// Le prenom.
  prenom,

  /// Le nom de famille, exige par le serveur, jamais affiche a l'enseignant.
  nom,

  /// L'age, en annees.
  age,
}

/// Ce qui ne va pas dans un champ. Le libelle vit dans l'ecran, en i18n.
enum ErreurChamp {
  /// Le champ est vide.
  requis,

  /// La valeur sort des bornes rendues.
  horsBornes,
}

/// Les bornes d'age acceptees par le formulaire.
///
/// **La borne serveur fait foi** : `creer_profil_enfant()` accepte 3 a 99 ans
/// et refuse le reste (`age hors bornes`). Aucune source serveur ne rend
/// encore les bornes a l'ecran (dependances DB-TRV-05 et DB-ADM-05).
@immutable
class BornesAge {
  /// Cree des bornes, incluses.
  const BornesAge({required this.min, required this.max})
    : assert(min <= max, 'une borne basse ne depasse pas la borne haute');

  /// La borne **deja en production** dans `ajouter_enfant_page.dart` (3 a 18
  /// ans), reprise ici pour qu'Admission et Foyer n'en ecrivent pas chacun une
  /// seconde. Ce n'est pas une regle nouvelle : elle disparait le jour ou le
  /// serveur rend les bornes (DB-ADM-05).
  static const BornesAge clientActuelle = BornesAge(min: 3, max: 18);

  /// Age minimal, inclus.
  final int min;

  /// Age maximal, inclus.
  final int max;

  /// Vrai quand [age] est dans les bornes.
  bool contient(int age) => age >= min && age <= max;

  @override
  bool operator ==(Object other) =>
      other is BornesAge && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// Le brouillon d'un profil eleve, avant creation.
///
/// **En memoire seulement** : ce sont les donnees d'un mineur, et un brouillon
/// ecrit sur le disque d'un appareil partage y survivrait a l'abandon du
/// formulaire. La date de naissance est reservee a DB-ADM-05 ; seul l'age est
/// demande, comme aujourd'hui.
@immutable
class BrouillonProfilEleve {
  /// Cree un brouillon.
  const BrouillonProfilEleve({
    this.pourQui = PourQui.enfantOuMineur,
    this.prenom = '',
    this.nom = '',
    this.age,
  });

  /// Pour qui.
  final PourQui pourQui;

  /// Prenom saisi, tel quel. Nettoye des espaces a l'envoi.
  final String prenom;

  /// Nom saisi, tel quel. Nettoye des espaces a l'envoi.
  final String nom;

  /// Age saisi. `null` tant qu'il n'est pas lisible.
  final int? age;

  /// Le meme brouillon, avec d'autres valeurs. Pour effacer l'age, voir
  /// [sansAge].
  BrouillonProfilEleve copyWith({
    PourQui? pourQui,
    String? prenom,
    String? nom,
    int? age,
  }) => BrouillonProfilEleve(
    pourQui: pourQui ?? this.pourQui,
    prenom: prenom ?? this.prenom,
    nom: nom ?? this.nom,
    age: age ?? this.age,
  );

  /// Le meme brouillon, sans age : le champ a ete vide ou n'est plus lisible.
  BrouillonProfilEleve sansAge() =>
      BrouillonProfilEleve(pourQui: pourQui, prenom: prenom, nom: nom);

  /// Les erreurs par champ, dans l'ordre de l'ecran. Vide : le brouillon est
  /// envoyable.
  ///
  /// Le choix [pourQui] n'est pas une erreur de saisie : un choix non creable
  /// se decide par `PortCreationProfilEleve.peutCreer`, et l'ecran l'explique.
  Map<ChampProfilEleve, ErreurChamp> valider(BornesAge bornes) {
    final Map<ChampProfilEleve, ErreurChamp> erreurs =
        <ChampProfilEleve, ErreurChamp>{};
    if (prenom.trim().isEmpty) {
      erreurs[ChampProfilEleve.prenom] = ErreurChamp.requis;
    }
    if (nom.trim().isEmpty) {
      erreurs[ChampProfilEleve.nom] = ErreurChamp.requis;
    }
    final int? ageSaisi = age;
    if (ageSaisi == null) {
      erreurs[ChampProfilEleve.age] = ErreurChamp.requis;
    } else if (!bornes.contient(ageSaisi)) {
      erreurs[ChampProfilEleve.age] = ErreurChamp.horsBornes;
    }
    return erreurs;
  }

  @override
  bool operator ==(Object other) =>
      other is BrouillonProfilEleve &&
      other.pourQui == pourQui &&
      other.prenom == prenom &&
      other.nom == nom &&
      other.age == age;

  @override
  int get hashCode => Object.hash(pourQui, prenom, nom, age);
}
