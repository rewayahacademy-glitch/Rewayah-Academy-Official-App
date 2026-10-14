// Les dix-sept etats du message vocal (spec Communications V1, section 11.2)
// et la machine pure qui fait passer l'enregistrement de l'un a l'autre.
//
// La machine ne connait ni widget, ni micro, ni minuterie : elle recoit
// l'heure de l'appelant a chaque evenement. Les durees sont donc exactes et
// testables avec une horloge fixe, et la regle centrale se lit ici :
// **aucun vocal ne part a l'arret** (section 11.3). Arreter, ou atteindre
// 3:00, mene a la pre-ecoute ; seul `envoyer()` mene a l'envoi, et seul le
// bouton « Envoyer » l'appelle.

import 'port_enregistreur_vocal.dart';

/// Les dix-sept etats du message vocal, dans l'ordre de la spec (11.2).
///
/// Les treize premiers sont ceux du composer ([MachineEnregistrementVocal]),
/// les quatre derniers ceux du lecteur d'un vocal (recu, ou pre-ecoute).
enum EtatVocal {
  /// 1. Repos : « Enregistrer un message vocal ».
  repos,

  /// 2. Permission micro requise : le composer explique avant que la
  /// plateforme ne pose la question.
  permissionRequise,

  /// 3. Permission refusee : « Le microphone n'est pas autorise pour
  /// Rewayah. », puis « Fermer » (aucun paquet n'ouvre les reglages).
  permissionRefusee,

  /// 4. Enregistrement en cours.
  enregistrement,

  /// 5. Enregistrement en pause, la duree gardee.
  pause,

  /// 6. Reprise : l'enregistrement repart apres une pause.
  reprise,

  /// 7. Limite proche : il reste trente secondes au plus.
  limiteProche,

  /// 8. 3:00 atteint : l'enregistrement s'est arrete seul et passe en
  /// pre-ecoute (R-COM-04), sans rien envoyer.
  limiteAtteinte,

  /// 9. Pre-ecoute : duree, ecoute, « Supprimer », « Envoyer ».
  preEcoute,

  /// 10. Supprimer : la suppression demande confirmation.
  supprimer,

  /// 11. Envoyer : l'envoi est accuse, le composer le dit et redevient
  /// disponible pour un autre vocal.
  envoye,

  /// 12. Envoi en cours.
  envoi,

  /// 13. Echec d'envoi : « non confirme », le vocal garde, « Reessayer ».
  echecEnvoi,

  /// 14. Vocal recu, pas encore ecoute.
  vocalRecu,

  /// 15. Lecture en cours.
  lecture,

  /// 16. Lecture en pause.
  pauseLecture,

  /// 17. Fin de lecture.
  finLecture,
}

/// Les etats ou le micro enregistre.
const Set<EtatVocal> etatsEnregistrementVocal = <EtatVocal>{
  EtatVocal.enregistrement,
  EtatVocal.reprise,
  EtatVocal.limiteProche,
};

/// Les etats ou un vocal enregistre attend la decision de la personne.
const Set<EtatVocal> etatsPreEcouteVocal = <EtatVocal>{
  EtatVocal.preEcoute,
  EtatVocal.limiteAtteinte,
};

/// L'etat du lecteur d'un vocal, deduit de l'etat de sa lecture.
EtatVocal etatDuLecteur(EtatLectureAudio lecture) {
  if (lecture.termine) return EtatVocal.finLecture;
  if (lecture.enLecture) return EtatVocal.lecture;
  if (lecture.position > Duration.zero) return EtatVocal.pauseLecture;
  return EtatVocal.vocalRecu;
}

/// La machine du composer vocal : etat, duree, transitions.
///
/// Chaque methode qui n'a pas de sens dans l'etat courant leve
/// [StateError] : un bouton qui l'appellerait ne devrait pas etre rendu.
class MachineEnregistrementVocal {
  /// Cree la machine, au repos.
  MachineEnregistrementVocal({
    this.dureeMax = dureeMaxVocal,
    this.seuilLimiteProche = seuilLimiteProcheVocal,
  }) : assert(
         seuilLimiteProche < dureeMax,
         'La limite proche precede la limite.',
       );

  /// La duree maximale (3:00 en V1).
  final Duration dureeMax;

  /// La duree a partir de laquelle la limite est annoncee proche.
  final Duration seuilLimiteProche;

  EtatVocal _etat = EtatVocal.repos;
  EtatVocal _avantSuppression = EtatVocal.preEcoute;
  Duration _cumul = Duration.zero;
  DateTime? _debutSegment;

  /// L'etat courant.
  EtatVocal get etat => _etat;

  /// Vrai pendant que le micro enregistre.
  bool get enregistre => etatsEnregistrementVocal.contains(_etat);

  /// Vrai quand un enregistrement est commence (en cours ou en pause).
  bool get enCours => enregistre || _etat == EtatVocal.pause;

  /// La duree enregistree a [maintenant], bornee a [dureeMax].
  Duration ecoule(DateTime maintenant) {
    final DateTime? debut = _debutSegment;
    final Duration total = debut == null
        ? _cumul
        : _cumul + maintenant.difference(debut);
    if (total < Duration.zero) return Duration.zero;
    return total > dureeMax ? dureeMax : total;
  }

  /// Ce qui reste avant la limite, a [maintenant].
  Duration restant(DateTime maintenant) => dureeMax - ecoule(maintenant);

  /// La duree du vocal arrete (pre-ecoute, envoi, echec).
  Duration get duree => _cumul;

  void _exiger(bool condition, String evenement) {
    if (!condition) {
      throw StateError('$evenement impossible depuis ${_etat.name}.');
    }
  }

  /// L'autorisation doit etre demandee : le composer l'explique d'abord.
  void exigerPermission() {
    _exiger(_etat == EtatVocal.repos || _etat == EtatVocal.envoye, 'Demande');
    _etat = EtatVocal.permissionRequise;
  }

  /// Le microphone est refuse.
  void refuserPermission() {
    _exiger(
      _etat == EtatVocal.repos ||
          _etat == EtatVocal.envoye ||
          _etat == EtatVocal.permissionRequise,
      'Refus',
    );
    _etat = EtatVocal.permissionRefusee;
  }

  /// Retour au repos sans enregistrement (« Annuler », « Fermer »).
  void fermer() {
    _exiger(
      _etat == EtatVocal.permissionRequise ||
          _etat == EtatVocal.permissionRefusee,
      'Fermeture',
    );
    _etat = EtatVocal.repos;
  }

  /// L'enregistrement commence a [maintenant].
  void demarrer(DateTime maintenant) {
    _exiger(
      _etat == EtatVocal.repos ||
          _etat == EtatVocal.envoye ||
          _etat == EtatVocal.permissionRequise,
      'Demarrage',
    );
    _cumul = Duration.zero;
    _debutSegment = maintenant;
    _etat = EtatVocal.enregistrement;
  }

  /// L'enregistrement se met en pause a [maintenant].
  void mettreEnPause(DateTime maintenant) {
    _exiger(enregistre, 'Pause');
    _cumul = ecoule(maintenant);
    _debutSegment = null;
    _etat = EtatVocal.pause;
  }

  /// L'enregistrement reprend a [maintenant].
  void reprendre(DateTime maintenant) {
    _exiger(_etat == EtatVocal.pause, 'Reprise');
    _debutSegment = maintenant;
    _etat = _cumul >= seuilLimiteProche
        ? EtatVocal.limiteProche
        : EtatVocal.reprise;
  }

  /// Le temps passe : vrai si la limite est atteinte a [maintenant] (le
  /// composer doit alors arreter l'enregistrement, [arreter] avec
  /// `limite: true`). Passe en limite proche au seuil.
  bool tic(DateTime maintenant) {
    if (!enregistre) return false;
    final Duration e = ecoule(maintenant);
    if (e >= dureeMax) return true;
    if (e >= seuilLimiteProche) _etat = EtatVocal.limiteProche;
    return false;
  }

  /// L'enregistrement s'arrete a [maintenant] et passe en pre-ecoute (ou en
  /// « 3:00 atteint » si [limite]). **Rien n'est envoye.** Rend la duree.
  Duration arreter(DateTime maintenant, {bool limite = false}) {
    _exiger(enCours, 'Arret');
    _cumul = ecoule(maintenant);
    _debutSegment = null;
    _etat = limite || _cumul >= dureeMax
        ? EtatVocal.limiteAtteinte
        : EtatVocal.preEcoute;
    return _cumul;
  }

  /// La personne demande a supprimer : confirmation d'abord.
  void demanderSuppression() {
    _exiger(
      _etat == EtatVocal.pause ||
          etatsPreEcouteVocal.contains(_etat) ||
          _etat == EtatVocal.echecEnvoi,
      'Suppression',
    );
    _avantSuppression = _etat;
    _etat = EtatVocal.supprimer;
  }

  /// « Garder » : retour a l'etat d'avant la demande.
  void garder() {
    _exiger(_etat == EtatVocal.supprimer, 'Garde');
    _etat = _avantSuppression;
  }

  /// Vrai si la suppression confirmee porte sur un enregistrement en pause
  /// (a abandonner) plutot que sur un vocal arrete (a effacer).
  bool get suppressionEnPause =>
      _etat == EtatVocal.supprimer && _avantSuppression == EtatVocal.pause;

  /// Vrai si un vocal rendu par l'enregistreur apres [arreter] est encore
  /// attendu : la pre-ecoute est ouverte, ou sa suppression est seulement
  /// demandee (« Garder » y ramene). Faux sinon (supprime, autre
  /// enregistrement commence) : le vocal rendu doit alors etre efface.
  bool get vocalAttendu =>
      etatsPreEcouteVocal.contains(_etat) ||
      (_etat == EtatVocal.supprimer &&
          etatsPreEcouteVocal.contains(_avantSuppression));

  /// La suppression est confirmee : retour au repos, plus rien de garde.
  void confirmerSuppression() {
    _exiger(_etat == EtatVocal.supprimer, 'Suppression confirmee');
    _remettreAZero();
    _etat = EtatVocal.repos;
  }

  /// « Envoyer » : seul chemin vers l'envoi.
  void envoyer() {
    _exiger(
      etatsPreEcouteVocal.contains(_etat) || _etat == EtatVocal.echecEnvoi,
      'Envoi',
    );
    _etat = EtatVocal.envoi;
  }

  /// L'envoi n'a pas ete accuse : le vocal est garde.
  void echouer() {
    _exiger(_etat == EtatVocal.envoi, 'Echec');
    _etat = EtatVocal.echecEnvoi;
  }

  /// L'envoi est accuse.
  void confirmerEnvoi() {
    _exiger(_etat == EtatVocal.envoi, 'Accuse');
    _remettreAZero();
    _etat = EtatVocal.envoye;
  }

  /// L'enregistrement n'a pas pu demarrer : retour au repos.
  void annulerDemarrage() {
    _remettreAZero();
    _etat = EtatVocal.repos;
  }

  void _remettreAZero() {
    _cumul = Duration.zero;
    _debutSegment = null;
  }
}
