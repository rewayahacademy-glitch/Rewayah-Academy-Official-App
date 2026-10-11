import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

/// Nom affiché d'un élève : prénom et initiale du nom uniquement.
String prenomEtInitiale(String prenom, String? nom) {
  final String p = prenom.trim().replaceAll(RegExp(r'\s+'), ' ');
  final String n = (nom ?? '').trim();
  if (n.isEmpty) return p;
  return '$p ${n.characters.first.toUpperCase()}.';
}

enum NatureObservation { pointPositif, aSuivre, interventionAdmin }

enum DomaineObservation {
  pedagogie,
  interaction,
  gestionClasse,
  respectCadre,
  climat,
  autre,
}

enum PersonneConcernee { enseignant, classeEntiere, elevePrecis, aucun }

/// Élève autorisé dans le roster d'une visite, sans nom complet ni photo.
@immutable
class EleveRoster {
  const EleveRoster({required this.id, required this.prenom, this.initialeNom});

  final String id;
  final String prenom;
  final String? initialeNom;

  String get nomAffiche => prenomEtInitiale(prenom, initialeNom);
}

/// Observation structurée jointe au rapport d'une visite.
@immutable
class ObservationControle {
  const ObservationControle({
    required this.important,
    required this.nature,
    required this.domaine,
    required this.personne,
    required this.texte,
    this.eleveId,
  });

  final bool important;
  final NatureObservation nature;
  final DomaineObservation domaine;
  final PersonneConcernee personne;
  final String? eleveId;
  final String texte;
}
