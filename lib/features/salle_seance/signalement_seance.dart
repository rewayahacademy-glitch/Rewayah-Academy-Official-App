// « Signaler un besoin » depuis la salle (EN-9b) : la feuille d'EN-4
// (`ouvrirSignalement`, ENS-12), nourrie des donnees de seance par un petit
// convertisseur. Rien d'autre n'est tire de la seance : ni indicateur, ni
// projection (la feuille n'en a pas besoin pour le signalement).

import 'package:flutter/widgets.dart';

import '../../core/enseignant/modeles_enseignant.dart';
import '../fiche_groupe/fiche_eleve_enseignant.dart';
import 'vue_seance.dart';

/// L'eleve de la seance, tel que la feuille d'EN-4 l'attend. L'identifiant
/// d'academie quand il est connu ; sinon (demonstration), le prenom.
EleveFiche eleveFicheDepuisSeance(EleveSeance eleve, VueSeance vue) {
  final String id = eleve.id ?? eleve.prenom;
  return EleveFiche(
    membre: MembreSeance(
      studentId: id,
      identifiantImmuable: id,
      prenom: eleve.prenom,
    ),
    classe: vue.nomClasse,
  );
}

/// Ouvre « Signaler un besoin » (ENS-12) pour un eleve de la seance.
Future<void> signalerDepuisSeance(
  BuildContext context,
  EleveSeance eleve,
  VueSeance vue,
) => ouvrirSignalement(context, eleveFicheDepuisSeance(eleve, vue));
