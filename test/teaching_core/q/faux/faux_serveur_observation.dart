// Faux serveur d'observation : la borne de quota, la ou elle doit etre.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// POURQUOI UN SERVEUR ET PAS UN PORT. La decision D-14 est categorique : la
// borne est SERVEUR. Verification du lien tuteur-enfant, de la seance, du
// groupe, de la policy et du quota **avant le token**. Un double qui ferait
// porter la decision au client testerait exactement ce qu'il faut interdire.
// Celui-ci tient donc l'etat, decide seul, et ferme lui-meme l'intervalle.

import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';

import '../../fixtures/fixtures_observation.dart';

/// Le compte a rebours que le CLIENT affiche.
///
/// Il est trafiquable a volonte -- c'est tout l'interet : il ne doit servir a
/// rien d'autre qu'a l'affichage.
class CompteARebourdClient {
  /// Cree un compte a rebours d'affichage.
  CompteARebourdClient(this.restantAffiche);

  /// Le temps restant tel que l'ecran le montre.
  Duration restantAffiche;

  /// Trafique le compte a rebours, comme le ferait un client modifie.
  void trafiquer(Duration nouveau) => restantAffiche = nouveau;
}

/// Le serveur d'observation, seul detenteur de la verite.
class FauxServeurObservation {
  /// Cree un serveur avec une politique et un lien tuteur-enfant.
  FauxServeurObservation({
    required this.politique,
    this.lienTuteurValide = true,
    this.seanceActive = true,
    this.dansLaFenetre = true,
  });

  /// La politique effective, resolue academie -> groupe -> desactivation.
  final GuardianObservationPolicy politique;

  /// Le lien tuteur-enfant est-il etabli.
  bool lienTuteurValide;

  /// La seance est-elle active.
  bool seanceActive;

  /// Sommes-nous dans la fenetre d'acces.
  bool dansLaFenetre;

  int _visitesFaites = 0;
  Duration _tempsConsomme = Duration.zero;
  GuardianSessionVisit? _visiteOuverte;
  DateTime? _ouverteA;

  /// Le journal des visites fermees, requetable.
  final List<GuardianSessionVisit> journal = <GuardianSessionVisit>[];

  /// Le budget courant, tel que le serveur le calcule.
  BudgetObservation budget() {
    final Duration restant = politique.maxTotalObservationTime - _tempsConsomme;
    final MotifRefusObservation? motif = _motifRefus();
    return BudgetObservation(
      policyVersion: politique.policyVersion,
      visitesUtilisees: _visitesFaites,
      visitesMax: politique.maxVisitsPerSession,
      tempsConsomme: _tempsConsomme,
      tempsTotalMax: politique.maxTotalObservationTime,
      restant: restant.isNegative ? Duration.zero : restant,
      peutEntrer: motif == null,
      motifRefus: motif,
    );
  }

  MotifRefusObservation? _motifRefus() {
    if (!politique.observationActivee) {
      return MotifRefusObservation.policyDesactivee;
    }
    if (!lienTuteurValide) return MotifRefusObservation.lienTuteurAbsent;
    if (!seanceActive) return MotifRefusObservation.seanceNonActive;
    if (!dansLaFenetre) return MotifRefusObservation.horsFenetre;
    if (_visitesFaites >= politique.maxVisitsPerSession) {
      return MotifRefusObservation.quotaVisitesAtteint;
    }
    if (_tempsConsomme >= politique.maxTotalObservationTime) {
      return MotifRefusObservation.tempsEpuise;
    }
    return null;
  }

  /// Demande d'entree. **Le client n'a aucun mot a dire ici.**
  ///
  /// Le compte a rebours d'affichage n'est meme pas un parametre : il ne
  /// participe pas a la decision, et c'est ce que le test Q-03 prouve.
  ResultatEntreeObservation entrer({
    required String sessionId,
    required String groupeId,
    required String observateurProfilId,
    required RoleObservateur role,
    required DateTime maintenantUtc,
    String? enfantConcerneId,
  }) {
    final MotifRefusObservation? motif = _motifRefus();
    if (motif != null) {
      return ResultatEntreeObservation(
        autorise: false,
        motifRefus: motif,
        budget: budget(),
      );
    }
    _visitesFaites++;
    _ouverteA = maintenantUtc;
    final GuardianSessionVisit visite = GuardianSessionVisit(
      id: 'visite-$_visitesFaites',
      sessionId: sessionId,
      groupeId: groupeId,
      observateurProfilId: observateurProfilId,
      role: role,
      enfantConcerneId: enfantConcerneId,
      enteredAtUtc: maintenantUtc,
      visitNumber: _visitesFaites,
      policyVersion: politique.policyVersion,
    );
    _visiteOuverte = visite;
    return ResultatEntreeObservation(
      autorise: true,
      visite: visite,
      budget: budget(),
    );
  }

  /// Ferme l'intervalle. **C'est le serveur qui ecrit la duree**, jamais le
  /// client (CONTRACTS section 14, invariant 2).
  ///
  /// La duree creditee est bornee par le plafond effectif : meme un client
  /// qui resterait au-dela ne consomme jamais plus que ce que la politique
  /// autorise, et la visite se termine alors pour [FinDeVisite.quotaAtteint].
  GuardianSessionVisit? sortir({required DateTime maintenantUtc}) {
    final GuardianSessionVisit? ouverte = _visiteOuverte;
    final DateTime? depuis = _ouverteA;
    if (ouverte == null || depuis == null) return null;
    final Duration brute = maintenantUtc.difference(depuis);
    final Duration plafond = plafondEffectifDeVisite(politique, _tempsConsomme);
    final bool plafonnee = brute > plafond;
    final Duration creditee = plafonnee ? plafond : brute;
    _tempsConsomme += creditee;
    final GuardianSessionVisit fermee = GuardianSessionVisit(
      id: ouverte.id,
      sessionId: ouverte.sessionId,
      groupeId: ouverte.groupeId,
      observateurProfilId: ouverte.observateurProfilId,
      role: ouverte.role,
      enfantConcerneId: ouverte.enfantConcerneId,
      enteredAtUtc: ouverte.enteredAtUtc,
      leftAtUtc: depuis.add(creditee),
      durationSeconds: creditee,
      visitNumber: ouverte.visitNumber,
      policyVersion: ouverte.policyVersion,
      finDeVisite: plafonnee
          ? FinDeVisite.quotaAtteint
          : FinDeVisite.sortieVolontaire,
    );
    journal.add(fermee);
    _visiteOuverte = null;
    _ouverteA = null;
    return fermee;
  }
}
