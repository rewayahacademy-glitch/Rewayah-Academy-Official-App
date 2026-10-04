// L'observation structuree du controleur (CTR-03A, CT-5, doc 08 P-CTR-05) :
// nature, domaine, personne concernee, texte. Brouillon en memoire seulement
// (C12) : rien n'est persiste, rien ne part avant « Envoyer le compte rendu ».
//
// Le roster autorise est neutre par defaut : aucun eleve, aucun appel serveur
// (K-28). La source reelle (BR-1, `14_controleur/CT-BR.md`) se branche dans
// `main.dart` ; la demonstration le surcharge.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

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

/// Un eleve du roster autorise : un identifiant pedagogique et le prenom
/// seul (C8). Jamais de photo, jamais de nom de famille.
@immutable
class EleveRoster {
  /// Cree l'entree.
  const EleveRoster({required this.id, required this.prenom});

  /// L'identifiant pedagogique, jamais affiche ni saisi.
  final String id;

  /// Le prenom.
  final String prenom;
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

/// Le roster autorise de la visite de la seance donnee, lu PAR SEANCE
/// (CTRL-SEANCE-1) : l'observation de la Classe A ne propose jamais les
/// prenoms de la Classe B. **Neutre par defaut** : aucun eleve.
final FutureProviderFamily<List<EleveRoster>, String> rosterControleProvider =
    FutureProvider.family<List<EleveRoster>, String>(
      (Ref _, String _) async => const <EleveRoster>[],
    );
