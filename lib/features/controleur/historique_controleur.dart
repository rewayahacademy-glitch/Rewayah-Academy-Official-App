// Historique du controleur (CTR-05, CTR-06, CT-7) : le modele des rapports
// de mission et le port de lecture.
//
// Un rapport envoye n'est jamais reecrit (C10) : le detail est en lecture,
// seul « Ajouter un complement » l'enrichit (CT-8). Le statut vient du
// serveur, tel quel (doc 08 CTR-05) : Envoye, Complement ajoute, A terminer.
//
// Aucun serveur n'est branche (K-28) : le port par defaut echoue, honnete,
// et la demonstration le remplace. Besoin serveur : `14_controleur/CT-BR.md`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'compte_rendu_controle.dart';
import 'observation_controle.dart';

/// Le statut d'un rapport (doc 08 CTR-05).
enum StatutRapport {
  /// Envoye a l'administration.
  envoye,

  /// Un complement a ete ajoute au rapport envoye.
  complementAjoute,

  /// La visite est transmise, le compte rendu reste a terminer.
  aTerminer,
}

/// Un complement ajoute a un rapport envoye (P-CTR-07) : le rapport parent
/// n'est pas modifie.
@immutable
class ComplementRapport {
  /// Cree le complement.
  const ComplementRapport({
    required this.date,
    required this.texte,
    this.motif,
  });

  /// Date et heure de l'ajout.
  final DateTime date;

  /// Le contenu.
  final String texte;

  /// Le motif, facultatif.
  final String? motif;
}

/// Un rapport de mission, en lecture.
@immutable
class RapportControle {
  /// Cree le rapport.
  const RapportControle({
    required this.id,
    required this.missionId,
    required this.classe,
    required this.enseignant,
    required this.debut,
    required this.dureeObservee,
    required this.statut,
    this.faits,
    this.choix,
    this.observation,
    this.eleve,
    this.presents = const <String>[],
    this.complements = const <ComplementRapport>[],
  });

  /// Identifiant du rapport.
  final String id;

  /// La mission d'origine : son fil d'echanges (P-CTR-06).
  final String missionId;

  /// La Classe observee.
  final String classe;

  /// L'enseignant, nom d'affichage professionnel (C8).
  final String enseignant;

  /// Debut de la seance observee.
  final DateTime debut;

  /// Duree de presence du controleur.
  final Duration dureeObservee;

  /// Statut.
  final StatutRapport statut;

  /// Les faits automatiques de la seance (doc 08 §1.1), nuls s'ils ne sont
  /// pas encore consolides.
  final FaitsVisite? faits;

  /// La reponse du controleur, nulle tant que le compte rendu est a terminer.
  final ChoixCompteRendu? choix;

  /// L'observation structuree, s'il y en a une.
  final ObservationControle? observation;

  /// Le prenom de l'eleve concerne, du roster autorise (C8), s'il y a lieu.
  final String? eleve;

  /// Les eleves presents seulement : prenom et initiale du nom (decision du
  /// directeur C7 = a, 27/09), jamais les absents.
  final List<String> presents;

  /// Les complements, du plus ancien au plus recent.
  final List<ComplementRapport> complements;
}

/// Le port de l'Historique.
abstract interface class PortHistorique {
  /// Les rapports du controleur, du plus recent au plus ancien.
  Future<List<RapportControle>> rapports();
}

/// Le port par defaut, sans serveur : tout echoue, rien n'est simule.
class HistoriqueIndisponible implements PortHistorique {
  /// Cree le port.
  const HistoriqueIndisponible();

  @override
  Future<List<RapportControle>> rapports() async =>
      throw StateError('Aucun serveur branche (BR-1).');
}

/// Le port de l'Historique : neutre par defaut, remplace en demonstration.
final Provider<PortHistorique> portHistoriqueProvider =
    Provider<PortHistorique>((Ref _) => const HistoriqueIndisponible());
