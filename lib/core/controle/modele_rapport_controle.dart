import 'package:flutter/foundation.dart';

import 'modele_observation_controle.dart';
import 'modele_visite.dart';

enum StatutRapport { envoye, complementAjoute, aTerminer }

/// Complément ajouté à un rapport envoyé; le rapport initial reste immuable.
@immutable
class ComplementRapport {
  const ComplementRapport({
    required this.date,
    required this.texte,
    this.motif,
    this.auteur,
  });

  final DateTime date;
  final String texte;
  final String? motif;
  final String? auteur;
}

/// Rapport d'une mission de contrôle.
@immutable
class RapportControle {
  const RapportControle({
    required this.id,
    required this.missionId,
    required this.classe,
    required this.enseignant,
    required this.debut,
    required this.dureeObservee,
    required this.statut,
    this.seanceId,
    this.faits,
    this.choix,
    this.observation,
    this.eleve,
    this.presents = const <String>[],
    this.complements = const <ComplementRapport>[],
    this.paysEnseignant,
  });

  final String id;
  final String missionId;
  final String? seanceId;
  final String classe;
  final String enseignant;
  final String? paysEnseignant;
  final DateTime debut;
  final Duration dureeObservee;
  final StatutRapport statut;
  final FaitsVisite? faits;
  final ChoixCompteRendu? choix;
  final ObservationControle? observation;
  final String? eleve;
  final List<String> presents;
  final List<ComplementRapport> complements;

  RapportControle avecComplement(ComplementRapport c) => RapportControle(
    id: id,
    missionId: missionId,
    seanceId: seanceId,
    classe: classe,
    enseignant: enseignant,
    debut: debut,
    dureeObservee: dureeObservee,
    statut: StatutRapport.complementAjoute,
    faits: faits,
    choix: choix,
    observation: observation,
    eleve: eleve,
    presents: presents,
    complements: List<ComplementRapport>.unmodifiable(<ComplementRapport>[
      ...complements,
      c,
    ]),
  );
}
