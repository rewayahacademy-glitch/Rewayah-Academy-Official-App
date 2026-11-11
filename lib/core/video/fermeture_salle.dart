import 'dart:async';

import '../observabilite/journal_dev.dart';
import 'video_session_provider.dart';

/// FERMETURE-SALLE (decision du directeur du 11/11/2026, seconde moitie du
/// defaut SEC-1 de `docs/current/salle/CONSTAT.md`, journal D-018).
///
/// Apres le depart de l'enseignant et un delai de grace, le serveur retire
/// aux eleves le droit de publier ; quand la seance est finie et que
/// l'enseignant n'est plus la, il ferme la salle pour tous.
///
/// **L'application ne decide rien.** Elle remarque seulement deux moments
/// (l'enseignant n'est plus dans la salle alors que le micro de l'eleve est
/// permis ; la fin du depassement autorise est passee) et demande alors au
/// serveur de relire la regle (`create-room-token`, action `verifier_salle`).
/// Le serveur relit lui-meme la salle chez LiveKit et la seance en base, et
/// applique a toute la salle. Une application qui ne demande rien n'y gagne
/// rien : la tache planifiee du serveur fait le meme passage chaque minute.

/// Le role du jeton d'un eleve (metadonnees signees).
const String roleQuiAttend = 'student';

/// Vrai quand le serveur vient de fermer le droit de publier d'un eleve
/// **parce que son enseignant n'est plus dans la salle** : le droit etait
/// ouvert ([avant]), il est ferme et en attente ([apres]), et l'enseignant ne
/// figure pas parmi les participants.
///
/// Une recitation (« Faire reciter ») ferme aussi le micro des camarades,
/// mais elle ne tient que tant que l'enseignant est dans la salle : elle ne
/// se confond donc pas avec ce cas.
bool microFermeSansEnseignant({
  required AccesSalle? avant,
  required AccesSalle apres,
  required bool enseignantPresent,
}) =>
    avant != null &&
    avant.capacites.peutPublier &&
    !apres.capacites.peutPublier &&
    apres.publicationDifferee &&
    !enseignantPresent;

/// La veille de FERMETURE-SALLE : elle demande la verification au serveur aux
/// deux moments decrits en tete de fichier, et jamais autrement.
class VeilleFermeture {
  /// Cree la veille. [verifier] appelle le serveur et rend le temps qui reste
  /// avant l'echeance, en secondes, quand un delai court (`null` sinon) ; ses
  /// erreurs sont rattrapees ici. [maintenant] : l'horloge (tests).
  VeilleFermeture(this._verifier, {DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now;

  final Future<int?> Function(AccesSalle acces) _verifier;
  final DateTime Function() _maintenant;

  /// Le temps laisse au serveur avant la premiere demande : LiveKit a deja
  /// annonce le depart, le webhook a note l'instant.
  static const Duration delaiPremiereDemande = Duration(seconds: 5);

  /// La marge ajoutee au temps que le serveur dit restant.
  static const Duration margeEcheance = Duration(seconds: 2);

  /// L'ecart avant de redemander quand le serveur n'a rien dit (panne,
  /// reponse sans echeance).
  static const Duration ecartSansReponse = Duration(seconds: 30);

  /// L'ecart entre deux demandes apres la fin du depassement autorise, tant
  /// que la salle reste ouverte (l'enseignant y est encore).
  static const Duration ecartApresLaFin = Duration(seconds: 60);

  AccesSalle? _acces;
  bool _sansEnseignant = false;
  DateTime? _finPorteUtc;
  bool _enCours = false;
  Timer? _minuterieAbsence;
  Timer? _minuterieFin;

  /// La fin du depassement autorise (fin prevue + `grace_after_end_minutes`,
  /// servie par le serveur), ou `null` si elle n'est pas connue. Apres elle,
  /// la veille demande la verification, puis la redemande tant que la salle
  /// reste ouverte.
  set finPorteUtc(DateTime? fin) {
    if (fin == _finPorteUtc) return;
    _finPorteUtc = fin;
    _minuterieFin?.cancel();
    _minuterieFin = null;
    _armerFin();
  }

  /// A appeler a chaque changement de la salle ou des droits.
  /// [enseignantPresent] : celui qui conduit la seance figure parmi les
  /// participants.
  void observer({required AccesSalle? acces, required bool enseignantPresent}) {
    _acces = acces;
    final bool sansEnseignant =
        acces != null &&
        acces.role == roleQuiAttend &&
        acces.capacites.peutPublier &&
        !enseignantPresent;
    if (sansEnseignant != _sansEnseignant) {
      _sansEnseignant = sansEnseignant;
      _minuterieAbsence?.cancel();
      _minuterieAbsence = null;
      if (sansEnseignant) {
        _minuterieAbsence = Timer(
          delaiPremiereDemande,
          () => unawaited(_demanderAbsence()),
        );
      }
    }
    if (acces == null) {
      _minuterieFin?.cancel();
      _minuterieFin = null;
    } else {
      _armerFin();
    }
  }

  void _armerFin({Duration? dans}) {
    final DateTime? fin = _finPorteUtc;
    if (fin == null || _acces == null || _minuterieFin != null) return;
    final Duration attente =
        dans ?? fin.difference(_maintenant().toUtc()) + delaiPremiereDemande;
    _minuterieFin = Timer(
      attente.isNegative ? Duration.zero : attente,
      () => unawaited(_demanderFin()),
    );
  }

  Future<void> _demanderAbsence() async {
    _minuterieAbsence = null;
    if (!_sansEnseignant) return;
    final int? reste = await _demander();
    // Le droit ferme arrive par l'evenement de permissions de LiveKit, qui
    // repasse par [observer] et arrete tout. Tant que la situation dure, on
    // redemande : a l'echeance annoncee, ou plus tard si rien n'a ete dit.
    if (_sansEnseignant && _minuterieAbsence == null) {
      _minuterieAbsence = Timer(
        reste == null || reste < 0
            ? ecartSansReponse
            : Duration(seconds: reste) + margeEcheance,
        () => unawaited(_demanderAbsence()),
      );
    }
  }

  Future<void> _demanderFin() async {
    _minuterieFin = null;
    if (_acces == null || _finPorteUtc == null) return;
    await _demander();
    // Salle fermee : LiveKit deconnecte, le moteur sort et [arreter] passe.
    // Encore ouverte (l'enseignant est la) : on redemande plus tard.
    _armerFin(dans: ecartApresLaFin);
  }

  Future<int?> _demander() async {
    final AccesSalle? acces = _acces;
    if (acces == null || _enCours) return null;
    _enCours = true;
    try {
      return await _verifier(acces);
    } catch (e) {
      // Une demande manquee n'arrete rien : la suivante reessaie, et le
      // serveur passe de toute facon chaque minute.
      journalDev('verification de la salle non obtenue : $e');
      return null;
    } finally {
      _enCours = false;
    }
  }

  /// Arrete tout (sortie de la salle). La fin connue de la seance est
  /// oubliee : elle sera redonnee a la prochaine entree.
  void arreter() {
    _minuterieAbsence?.cancel();
    _minuterieAbsence = null;
    _minuterieFin?.cancel();
    _minuterieFin = null;
    _acces = null;
    _sansEnseignant = false;
    _finPorteUtc = null;
  }
}
