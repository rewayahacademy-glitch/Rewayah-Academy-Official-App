// L'observation structuree du controleur (CTR-03A, CT-5, doc 08 P-CTR-05) :
// nature, domaine, personne concernee, texte. Brouillon en memoire seulement
// (C12) : rien n'est persiste, rien ne part avant « Envoyer le compte rendu ».
//
// Le roster autorise est neutre par defaut : aucun eleve, aucun appel serveur
// (K-28). La source reelle (BR-1, `14_controleur/CT-BR.md`) se branche dans
// `main.dart` ; la demonstration le surcharge.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le nom d'un eleve tel que le controleur le lit (decision du directeur
/// C7 = a, 27/09) : le prenom et l'initiale du nom, « Mariam S. ». Une seule
/// fonction pour la liste de l'observation et pour l'Historique.
///
/// [nom] peut etre le nom ou deja son initiale : seule sa premiere lettre
/// (graphème entier, arabe compris) est gardee, en majuscule, suivie d'un
/// point. Un nom compose (« Ben Salah », « El-Amrani ») ne donne qu'une
/// initiale. Sans nom, le prenom seul. Les espaces en trop sont retires.
String prenomEtInitiale(String prenom, String? nom) {
  final String p = prenom.trim().replaceAll(RegExp(r'\s+'), ' ');
  final String n = (nom ?? '').trim();
  if (n.isEmpty) return p;
  return '$p ${n.characters.first.toUpperCase()}.';
}

/// Etape 1 : la nature de l'observation.
enum NatureObservation {
  /// Point positif.
  pointPositif,

  /// A suivre.
  aSuivre,

  /// Intervention Admin souhaitee : texte obligatoire.
  interventionAdmin,
}

/// Etape 2 : le domaine.
enum DomaineObservation {
  /// Pedagogie.
  pedagogie,

  /// Interaction avec les eleves.
  interaction,

  /// Gestion de la classe.
  gestionClasse,

  /// Respect du cadre.
  respectCadre,

  /// Comportement / climat.
  climat,

  /// Autre.
  autre,
}

/// Etape 3 : la personne concernee.
enum PersonneConcernee {
  /// L'enseignant de la seance.
  enseignant,

  /// La Classe entiere.
  classeEntiere,

  /// Un eleve choisi dans le roster autorise.
  elevePrecis,

  /// Aucun participant precis.
  aucun,
}

/// Un eleve du roster autorise : un identifiant pedagogique, le prenom et
/// l'initiale du nom (decision du directeur C7 = a, 27/09 ; minimum C8).
/// Jamais de photo, jamais le nom de famille entier.
@immutable
class EleveRoster {
  /// Cree l'entree.
  const EleveRoster({required this.id, required this.prenom, this.initialeNom});

  /// L'identifiant pedagogique, jamais affiche ni saisi.
  final String id;

  /// Le prenom.
  final String prenom;

  /// L'initiale du nom, donnee par le serveur ; nulle s'il n'en donne pas.
  final String? initialeNom;

  /// Le libelle affiche : « Prenom N. » ([prenomEtInitiale]).
  String get nomAffiche => prenomEtInitiale(prenom, initialeNom);
}

/// Une observation complete, prete a joindre au rapport de la visite.
@immutable
class ObservationControle {
  /// Cree l'observation.
  const ObservationControle({
    required this.important,
    required this.nature,
    required this.domaine,
    required this.personne,
    required this.texte,
    this.eleveId,
  });

  /// Vrai si le controleur a choisi « Signaler un point important ».
  final bool important;

  /// La nature.
  final NatureObservation nature;

  /// Le domaine.
  final DomaineObservation domaine;

  /// La personne concernee.
  final PersonneConcernee personne;

  /// L'eleve, seulement pour [PersonneConcernee.elevePrecis].
  final String? eleveId;

  /// Le texte libre, vide s'il est facultatif et omis.
  final String texte;
}

/// Le texte est obligatoire pour une intervention de l'administration et pour
/// un point important ; facultatif sinon (choix provisoire, question 3).
bool texteObligatoire({
  required bool important,
  required NatureObservation? nature,
}) => important || nature == NatureObservation.interventionAdmin;

/// Le roster autorise de la visite. **Neutre par defaut** : aucun eleve.
final FutureProvider<List<EleveRoster>> rosterControleProvider =
    FutureProvider<List<EleveRoster>>((Ref _) async => const <EleveRoster>[]);
