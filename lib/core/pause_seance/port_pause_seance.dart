// LIVE-PAUSE-01 : la pause programmee d'une classe (decision F3, 27/09/2026).
//
// L'enseignant programme a l'avance une pause sur SA classe (la priere, par
// exemple) : a quel moment de la seance, et combien de minutes. Le reglage
// reste valable de seance en seance jusqu'a ce qu'il le change. En seance, le
// systeme dit si la pause a ete prise ou non.
//
// **Frontend seul.** Aucun adaptateur Supabase ici : la production rend
// `CapaciteIndisponible`, l'ecran le dit en clair et ne pose aucune fausse
// bascule. Le contrat serveur est ecrit dans
// `docs/current/CONTRAT_PORT_PAUSE_SEANCE.md`.
//
// **Jamais une preuve de presence.** Une pause compte du temps de seance, pas
// une personne : aucun type d'ici ne porte un identifiant d'eleve ni un
// horodatage d'entree. Rien cote famille dans ce lot.
//
// **Un widget lit une capacite, jamais un role** : `peutModifier` et
// `peutPiloter` viennent de la lecture serveur ; absents, les commandes ne sont
// pas rendues (jamais un bouton grise).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import '../config/env.dart';
import 'pause_seance_demonstration.dart';

/// Les bornes du reglage : valeurs du contrat, jamais choisies par un ecran.
abstract final class BornesPause {
  /// Le moment le plus tot, en minutes apres T0.
  static const int apresMin = 5;

  /// Le moment le plus tard, en minutes apres T0.
  static const int apresMax = 120;

  /// Le pas du moment.
  static const int apresPas = 5;

  /// La duree la plus courte, en minutes.
  static const int dureeMin = 5;

  /// La duree la plus longue, en minutes.
  static const int dureeMax = 30;

  /// Le pas de la duree.
  static const int dureePas = 5;
}

/// Le reglage d'une classe : valable de seance en seance, versionne.
@immutable
class ReglagePause {
  /// Cree le reglage.
  const ReglagePause({
    required this.actif,
    required this.apresMinutes,
    required this.dureeMinutes,
    required this.version,
    required this.peutModifier,
  }) : assert(apresMinutes >= BornesPause.apresMin),
       assert(apresMinutes <= BornesPause.apresMax),
       assert(dureeMinutes >= BornesPause.dureeMin),
       assert(dureeMinutes <= BornesPause.dureeMax);

  /// La pause est programmee sur les seances de la classe.
  final bool actif;

  /// Le moment, en minutes apres T0.
  final int apresMinutes;

  /// La duree, en minutes.
  final int dureeMinutes;

  /// La version du reglage, rendue par le serveur : l'ecriture la renvoie
  /// (`versionAttendue`) pour refuser d'ecraser un reglage plus recent.
  final String version;

  /// La capacite de modifier ce reglage, lue du serveur (l'enseignant de la
  /// classe). Faux : le reglage se lit, sans commande.
  final bool peutModifier;

  /// Une copie modifiee.
  ReglagePause copyWith({bool? actif, int? apresMinutes, int? dureeMinutes}) =>
      ReglagePause(
        actif: actif ?? this.actif,
        apresMinutes: apresMinutes ?? this.apresMinutes,
        dureeMinutes: dureeMinutes ?? this.dureeMinutes,
        version: version,
        peutModifier: peutModifier,
      );

  @override
  bool operator ==(Object other) =>
      other is ReglagePause &&
      other.actif == actif &&
      other.apresMinutes == apresMinutes &&
      other.dureeMinutes == dureeMinutes &&
      other.version == version &&
      other.peutModifier == peutModifier;

  @override
  int get hashCode =>
      Object.hash(actif, apresMinutes, dureeMinutes, version, peutModifier);
}

/// Ou en est la pause d'une seance.
enum StatutPause {
  /// Aucune pause n'est programmee pour cette seance.
  nonPrevue,

  /// Programmee, pas encore commencee.
  programmee,

  /// En cours.
  enCours,

  /// Prise : commencee puis terminee.
  prise,

  /// Non prise : la seance est finie sans que la pause ait eu lieu.
  nonPrise,
}

/// L'etat de la pause d'une seance, horodate cote serveur.
@immutable
class PauseSeance {
  /// Cree l'etat.
  const PauseSeance({
    required this.statut,
    required this.dureePrevueMinutes,
    this.debutPrevuUtc,
    this.debutUtc,
    this.finUtc,
    this.peutPiloter = false,
  });

  /// Pas de pause pour cette seance.
  const PauseSeance.nonPrevue()
    : statut = StatutPause.nonPrevue,
      dureePrevueMinutes = BornesPause.dureeMin,
      debutPrevuUtc = null,
      debutUtc = null,
      finUtc = null,
      peutPiloter = false;

  /// Le statut.
  final StatutPause statut;

  /// La duree prevue, en minutes (le reglage au moment de la seance).
  final int dureePrevueMinutes;

  /// Le debut prevu (T0 + le moment du reglage), en UTC.
  final DateTime? debutPrevuUtc;

  /// Le debut reel, horodate par le serveur, en UTC.
  final DateTime? debutUtc;

  /// La fin reelle, horodatee par le serveur, en UTC.
  final DateTime? finUtc;

  /// La capacite de demarrer et de terminer la pause, lue du serveur.
  final bool peutPiloter;

  /// La reprise attendue d'une pause en cours : son debut plus sa duree.
  DateTime? get repriseUtc => statut == StatutPause.enCours && debutUtc != null
      ? debutUtc!.add(Duration(minutes: dureePrevueMinutes))
      : null;

  /// La duree reelle d'une pause prise, ou `null`.
  Duration? get dureeReelle =>
      statut == StatutPause.prise && debutUtc != null && finUtc != null
      ? finUtc!.difference(debutUtc!)
      : null;

  @override
  bool operator ==(Object other) =>
      other is PauseSeance &&
      other.statut == statut &&
      other.dureePrevueMinutes == dureePrevueMinutes &&
      other.debutPrevuUtc == debutPrevuUtc &&
      other.debutUtc == debutUtc &&
      other.finUtc == finUtc &&
      other.peutPiloter == peutPiloter;

  @override
  int get hashCode => Object.hash(
    statut,
    dureePrevueMinutes,
    debutPrevuUtc,
    debutUtc,
    finUtc,
    peutPiloter,
  );
}

/// Le reglage a ete modifie depuis la lecture : relire avant de recommencer.
class ReglagePauseObsolete implements Exception {
  /// Cree l'exception.
  const ReglagePauseObsolete();

  @override
  String toString() => 'ReglagePauseObsolete()';
}

/// Le port de la pause programmee.
abstract interface class PortPauseSeance {
  /// Le reglage de la classe [groupeId] (lu par son enseignant).
  Future<ReglagePause> reglage(String groupeId);

  /// Enregistre le reglage. [versionAttendue] est celle de la lecture ; une
  /// version perimee leve [ReglagePauseObsolete]. [cleIdempotence] rend
  /// l'envoi rejouable : la meme cle avec la meme demande rend le meme
  /// resultat.
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  });

  /// L'etat de la pause de la seance [seanceId].
  Future<PauseSeance> etat(String seanceId);

  /// Demarre la pause : le serveur horodate le debut. Sans effet si elle est
  /// deja en cours (meme cle, meme resultat).
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  });

  /// Termine la pause : le serveur horodate la fin.
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  });
}

/// Le port de production tant que le serveur ne sert rien : chaque methode
/// leve `CapaciteIndisponible`, jamais un faux succes.
class PauseSeanceIndisponible implements PortPauseSeance {
  /// Cree l'implementation.
  const PauseSeanceIndisponible();

  /// La dependance nommee (trace et tests, jamais affichee).
  static const String dependance = 'PAUSE-BR-01';

  Future<T> _indisponible<T>() =>
      Future<T>.error(const CapaciteIndisponible(dependance));

  @override
  Future<ReglagePause> reglage(String groupeId) => _indisponible();

  @override
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  }) => _indisponible();

  @override
  Future<PauseSeance> etat(String seanceId) => _indisponible();

  @override
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  }) => _indisponible();

  @override
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  }) => _indisponible();
}

/// Choisit le port selon le mode de compilation : en production, aucune
/// source n'existe ; la demonstration ne sort que sous `PLAYGROUND=true`, que
/// le deploiement force a `false`.
PortPauseSeance portPauseSeanceSelon({required bool demo}) =>
    demo ? PauseSeanceDemonstration() : const PauseSeanceIndisponible();

/// Le port de pause employe par l'application.
final Provider<PortPauseSeance> portPauseSeanceProvider =
    Provider<PortPauseSeance>(
      (Ref ref) => portPauseSeanceSelon(demo: Env.playgroundActif),
    );

/// Le reglage de pause d'une classe.
final FutureProviderFamily<ReglagePause, String> reglagePauseProvider =
    FutureProvider.family<ReglagePause, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portPauseSeanceProvider).reglage(groupeId),
    );

/// L'etat de la pause d'une seance.
final FutureProviderFamily<PauseSeance, String> pauseSeanceProvider =
    FutureProvider.family<PauseSeance, String>(
      (Ref ref, String seanceId) =>
          ref.watch(portPauseSeanceProvider).etat(seanceId),
    );
