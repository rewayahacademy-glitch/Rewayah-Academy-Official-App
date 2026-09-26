import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart' show PositionLecture;
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/presence/service_presence.dart';

/// Ce que l'ecran du cahier de transmission (`ENS-04`) montre, a un instant
/// donne.
///
/// Cinq etats, et non quatre : `vide` et `erreur` disent deux choses
/// differentes. « Aucun constat n'a pu etre deduit pour cette seance » est une
/// lecture qui a abouti sans rien trouver, et le cahier reste deposable ; « je
/// n'ai pas pu lire le brouillon » est une panne, et l'enseignant doit pouvoir
/// reessayer. Les confondre ferait passer une panne pour une seance sans
/// eleves.
enum EtatCahier {
  /// La lecture du brouillon n'a pas encore rendu.
  chargement,

  /// Le constat prerempli est la : c'est le chemin nominal des 45 secondes.
  constat,

  /// La lecture a abouti, mais elle ne rend ni presence ni evenement.
  vide,

  /// La lecture a echoue. Le depot reste possible sans prerempli : un cahier
  /// tardif vaut mieux qu'un cahier perdu.
  erreur,

  /// Un cahier existe deja pour cette seance. Il se lit, il ne se redepose pas.
  dejaDepose,
}

/// La projection pure du cahier : elle decide l'etat de l'ecran et l'ordre des
/// lignes, sans monter un widget.
///
/// Meme forme que `VuePresence.depuis`, `VueSalle.depuis` et
/// `VueSuiviFoyer.depuis` : c'est la convention du depot, et c'est ce qui rend
/// le principe anti-burnout mesurable sans ecran -- les exceptions d'abord, le
/// reste ensuite, et « tout est nominal » comme fait verifiable.
///
/// Elle ne calcule **aucune duree** : `BrouillonCahier.dureeMinutes` est
/// calculee par la base, et c'est la duree du cahier. Le depot en connait quatre
/// autres facons (`fin - debut`, `entre_le -> derniere_trace_le`,
/// `minutesInterruption`, `started_at -> ended_at`) : en recalculer une ici
/// ferait un cinquieme chiffre pour la meme seance.
@immutable
class VueCahier {
  const VueCahier._({
    required this.etat,
    required this.exceptions,
    required this.nominaux,
    this.brouillon,
  });

  /// Calcule ce qu'il faut montrer d'une lecture de brouillon.
  ///
  /// [lecture] se lit par `hasValue` / `hasError`, **jamais par son type
  /// d'execution** : Riverpod 3 relance un provider en echec de lui-meme et
  /// l'etat repasse par `AsyncLoading` en conservant `hasError`. Un `switch` sur
  /// le type rendrait l'ecran instable sans qu'aucune donnee ait change.
  factory VueCahier.depuis({required AsyncValue<BrouillonCahier?> lecture}) {
    if (!lecture.hasValue) {
      return VueCahier._(
        etat: lecture.hasError ? EtatCahier.erreur : EtatCahier.chargement,
        exceptions: const <ParticipantBrouillon>[],
        nominaux: const <ParticipantBrouillon>[],
      );
    }

    final BrouillonCahier? brouillon = lecture.requireValue;
    if (brouillon == null) {
      // Une seance introuvable n'est pas une panne : le cahier reste deposable,
      // et l'ecran dit que le constat n'a pas pu etre deduit.
      return const VueCahier._(
        etat: EtatCahier.vide,
        exceptions: <ParticipantBrouillon>[],
        nominaux: <ParticipantBrouillon>[],
      );
    }

    final List<ParticipantBrouillon> exceptions = _parNom(brouillon.exceptions);
    final List<ParticipantBrouillon> nominaux = _parNom(
      brouillon.participants
          .where((ParticipantBrouillon p) => !p.estUneException)
          .toList(growable: false),
    );

    if (brouillon.dejaDepose) {
      return VueCahier._(
        etat: EtatCahier.dejaDepose,
        brouillon: brouillon,
        exceptions: exceptions,
        nominaux: nominaux,
      );
    }

    final bool sansRien =
        brouillon.participants.isEmpty && brouillon.evenements.isEmpty;
    return VueCahier._(
      etat: sansRien ? EtatCahier.vide : EtatCahier.constat,
      brouillon: brouillon,
      exceptions: exceptions,
      nominaux: nominaux,
    );
  }

  /// L'etat de l'ecran.
  final EtatCahier etat;

  /// Le brouillon lu. Nul en chargement, en erreur, et quand la seance est
  /// introuvable.
  final BrouillonCahier? brouillon;

  /// **Les seules lignes qui demandent un regard**, par nom.
  final List<ParticipantBrouillon> exceptions;

  /// Les lignes qui valent « Continuer », par nom.
  final List<ParticipantBrouillon> nominaux;

  /// Vrai quand rien ne demande l'attention de l'enseignant : un seul geste
  /// suffit, et c'est le chemin des 45 secondes.
  bool get toutEstNominal => brouillon?.toutEstNominal ?? false;

  /// Tous les eleves de la seance, les exceptions en tete.
  ///
  /// L'ordre est celui de l'ecran : ce que l'enseignant doit regarder arrive
  /// avant ce qu'il n'a pas a toucher.
  List<ParticipantBrouillon> get participants => <ParticipantBrouillon>[
    ...exceptions,
    ...nominaux,
  ];

  /// Vrai quand un depot a encore un sens.
  ///
  /// Faux en chargement -- on ne valide pas un constat qu'on n'a pas lu -- et
  /// faux quand le cahier est deja depose : la cle d'idempotence rend le
  /// doublon inoffensif, mais l'ecran n'a pas a le provoquer.
  bool get peutDeposer =>
      etat != EtatCahier.chargement && etat != EtatCahier.dejaDepose;

  /// Tri stable par nom affiche, comme `tableauDePresence` : l'ordre ne depend
  /// **jamais** de l'etat de presence. Une ligne qui remonterait entre deux
  /// regards ferait toucher un eleve a la place d'un autre.
  static List<ParticipantBrouillon> _parNom(
    List<ParticipantBrouillon> lignes,
  ) => lignes.toList()
    ..sort(
      (ParticipantBrouillon a, ParticipantBrouillon b) => a.membre.libelle
          .toLowerCase()
          .compareTo(b.membre.libelle.toLowerCase()),
    );
}

/// Traduit une ligne de brouillon en ligne de presence affichable.
///
/// Le cahier ne pose **aucune echelle d'assiduite a lui** : il reutilise les
/// quatorze etats derives par `etat_presence()`, `VuePresence.depuis` et
/// `LignePresence`. Poser ses propres cases « present / absent / en retard »
/// ecraserait la distinction `inconnu` / `absente` que deux migrations et deux
/// fichiers Dart protegent (invariant J3).
///
/// `consolide` vaut `false` parce que le brouillon ne porte pas cette colonne :
/// l'ecran ne l'affiche donc pas (`afficherConsolide: false`), plutot que
/// d'affirmer qu'aucune decision humaine n'a fige l'etat.
PresenceParticipant ligneDePresence({
  required ParticipantBrouillon participant,
  required BrouillonCahier brouillon,
}) => PresenceParticipant(
  seanceId: brouillon.seanceId,
  profilId: participant.membre.studentId,
  role: 'student',
  prenom: participant.membre.libelle,
  identifiantImmuable: participant.membre.identifiantImmuable,
  etat: participant.presence,
  consolide: false,
  entreLe: participant.entreLe,
  derniereTraceLe: participant.derniereTraceLe,
  debutSeance: brouillon.debut,
);

/// Les trois pastilles de statut du cahier (planche 4 : Presents, Absents,
/// En retard), comptees sur l'etat de presence deja derive, jamais ressaisi.
///
/// Une presence `inconnu` n'est comptee nulle part : elle n'est pas une
/// absence (invariant J3), elle reste une ligne « A regarder ».
@immutable
class StatutsCahier {
  const StatutsCahier._({
    required this.presents,
    required this.absents,
    required this.enRetard,
  });

  /// Compte les statuts des participants.
  factory StatutsCahier.depuis(List<ParticipantBrouillon> participants) {
    int presents = 0;
    int absents = 0;
    int enRetard = 0;
    for (final ParticipantBrouillon p in participants) {
      switch (p.presence) {
        case EtatPresence.presente ||
            EtatPresence.reconnectee ||
            EtatPresence.finalisee:
          presents++;
        case EtatPresence.absente || EtatPresence.excusee:
          absents++;
        case EtatPresence.enRetard:
          enRetard++;
        default:
          break;
      }
    }
    return StatutsCahier._(
      presents: presents,
      absents: absents,
      enRetard: enRetard,
    );
  }

  /// Eleves presents.
  final int presents;

  /// Eleves absents.
  final int absents;

  /// Eleves en retard.
  final int enRetard;
}

/// La position de reprise proposee (doc 04 §20.1) : la position de lecture
/// commune des eleves, quand ils en ont une et qu'elle est la meme pour tous.
///
/// Des positions differentes ne donnent **aucune** proposition : la machine
/// ne choisit pas a la place de l'enseignant (K-45, point 4).
PositionLecture? repriseProposee(List<ParticipantBrouillon> participants) {
  PositionLecture? commune;
  for (final ParticipantBrouillon p in participants) {
    final PositionLecture? position = p.position;
    if (position == null) continue;
    if (commune == null) {
      commune = position;
    } else if (commune.sourate != position.sourate ||
        commune.verset != position.verset) {
      return null;
    }
  }
  return commune;
}

/// L'horloge du cahier, pour dater « Corrige le ... » (K-45, point 5).
/// Surchargee par la demonstration et les tests.
final Provider<DateTime Function()> horlogeCahierProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);
