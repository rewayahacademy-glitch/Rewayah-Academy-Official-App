import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'guardian_session_visit.dart';

/// Les visites d'un observateur sur une seance, pour un enfant.
///
/// **Une seule source** : `guardian_session_visit`, lu sous RLS. L'historique
/// tuteur et la consultation admin groupent les memes lignes de la meme
/// facon ([grouperObservations]), sans second journal.
@immutable
class ObservationsSeance {
  /// Cree le groupe de visites.
  const ObservationsSeance({
    required this.seanceId,
    required this.visites,
    this.enfantId,
    this.groupeId,
  });

  /// La seance observee.
  final String seanceId;

  /// L'enfant concerne. `null` pour une visite administrative.
  final String? enfantId;

  /// La classe de la seance, telle que la visite l'a journalisee.
  final String? groupeId;

  /// Les visites, dans l'ordre de leur rang.
  final List<GuardianSessionVisit> visites;

  /// Le nombre de visites.
  int get nombreVisites => visites.length;

  /// La duree totale, **ecrite par le serveur**.
  ///
  /// `null` des qu'une visite n'a pas de sortie ou pas de duree : l'ecran dit
  /// « Duree non confirmee », il ne recolle jamais deux horodatages.
  Duration? get dureeTotaleConfirmee {
    Duration total = Duration.zero;
    for (final GuardianSessionVisit visite in visites) {
      final Duration? duree = visite.durationSeconds;
      if (visite.leftAtUtc == null || duree == null) {
        return null;
      }
      total += duree;
    }
    return total;
  }
}

/// Groupe des lignes de `guardian_session_visit` par (seance, enfant).
///
/// **Une ligne incomplete est ecartee, jamais completee** : la lecture passe
/// par `GuardianSessionVisit.lire`, qui rend `null` plutot qu'une visite de
/// 1970. Les groupes sont rendus de la seance la plus recente a la plus
/// ancienne (premiere entree), les visites par rang.
List<ObservationsSeance> grouperObservations(
  Iterable<Map<String, dynamic>> lignes,
) {
  final Map<(String, String?), List<GuardianSessionVisit>> parCle =
      <(String, String?), List<GuardianSessionVisit>>{};
  for (final Map<String, dynamic> ligne in lignes) {
    final GuardianSessionVisit? visite = GuardianSessionVisit.lire(ligne);
    if (visite == null) {
      continue;
    }
    parCle
        .putIfAbsent((
          visite.sessionId,
          visite.enfantConcerneId,
        ), () => <GuardianSessionVisit>[])
        .add(visite);
  }

  final List<ObservationsSeance> groupes = <ObservationsSeance>[
    for (final MapEntry<(String, String?), List<GuardianSessionVisit>> entree
        in parCle.entries)
      ObservationsSeance(
        seanceId: entree.key.$1,
        enfantId: entree.key.$2,
        groupeId: entree.value.first.groupeId,
        visites: List<GuardianSessionVisit>.unmodifiable(
          entree.value..sort(
            (GuardianSessionVisit a, GuardianSessionVisit b) =>
                a.visitNumber.compareTo(b.visitNumber),
          ),
        ),
      ),
  ];
  DateTime premiere(ObservationsSeance s) => s.visites
      .map((GuardianSessionVisit v) => v.enteredAtUtc)
      .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
  return groupes..sort(
    (ObservationsSeance a, ObservationsSeance b) =>
        premiere(b).compareTo(premiere(a)),
  );
}

/// L'historique des observations de la personne connectee (contrat K4).
abstract interface class PortHistoriqueObservations {
  /// Les visites de l'appelant (RLS : observateur = soi), groupees par
  /// (seance, enfant), filtrees par enfant et par periode (premiere entree).
  Future<List<ObservationsSeance>> mesObservations({
    String? enfantId,
    DateTimeRange? periode,
  });

  /// Les visites de l'appelant sur une seance, pour un enfant.
  Future<ObservationsSeance?> detail({
    required String seanceId,
    String? enfantId,
  });
}

/// Les filtres de la consultation admin des observations.
@immutable
class FiltreObservationsAdmin {
  /// Cree un filtre.
  const FiltreObservationsAdmin({
    this.tuteurId,
    this.eleveId,
    this.groupeId,
    this.periode,
    this.seulementOuvertes = false,
  });

  /// L'observateur.
  final String? tuteurId;

  /// L'enfant concerne.
  final String? eleveId;

  /// La classe.
  final String? groupeId;

  /// La periode (premiere entree).
  final DateTimeRange? periode;

  /// Seulement les visites sans sortie.
  final bool seulementOuvertes;
}

/// La consultation admin des observations (RLS admin, pagination par curseur).
abstract interface class PortHistoriqueObservationsAdmin {
  /// Une page de resultats et le curseur de la suivante (`null` : fin).
  Future<({List<ObservationsSeance> lignes, String? curseur})> rechercher(
    FiltreObservationsAdmin filtre, {
    String? curseur,
  });
}

/// L'historique tuteur tant que son adaptateur n'est pas livre.
///
/// La source existe (`guardian_session_visit`, SELECT accorde, RLS
/// observateur = soi) : l'adaptateur reel
/// `lib/core/tc_observation/historique_observations_supabase.dart` est ecrit
/// par le **lot E** (`00_OWNERSHIP.md` section 3), qui remplace alors
/// l'implementation du provider ci-dessous. D'ici la : indisponible, jamais une
/// liste locale.
class HistoriqueObservationsIndisponible implements PortHistoriqueObservations {
  /// Cree l'implementation.
  const HistoriqueObservationsIndisponible();

  @override
  Future<List<ObservationsSeance>> mesObservations({
    String? enfantId,
    DateTimeRange? periode,
  }) => Future<List<ObservationsSeance>>.error(
    const CapaciteIndisponible('LOT-E'),
  );

  @override
  Future<ObservationsSeance?> detail({
    required String seanceId,
    String? enfantId,
  }) => Future<ObservationsSeance?>.error(const CapaciteIndisponible('LOT-E'));
}

/// La consultation admin tant que son adaptateur n'est pas livre (lot E).
///
/// Aucune recherche serveur dediee n'existe (DB-OBS-11) ; la lecture directe
/// sous RLS admin est possible et appartient au lot E.
class HistoriqueObservationsAdminIndisponible
    implements PortHistoriqueObservationsAdmin {
  /// Cree l'implementation.
  const HistoriqueObservationsAdminIndisponible();

  @override
  Future<({List<ObservationsSeance> lignes, String? curseur})> rechercher(
    FiltreObservationsAdmin filtre, {
    String? curseur,
  }) => Future<({List<ObservationsSeance> lignes, String? curseur})>.error(
    const CapaciteIndisponible('LOT-E'),
  );
}

/// L'historique tuteur employe par l'application.
final Provider<PortHistoriqueObservations> portHistoriqueObservationsProvider =
    Provider<PortHistoriqueObservations>(
      (Ref ref) => const HistoriqueObservationsIndisponible(),
    );

/// La consultation admin employee par l'application.
final Provider<PortHistoriqueObservationsAdmin>
portHistoriqueObservationsAdminProvider =
    Provider<PortHistoriqueObservationsAdmin>(
      (Ref ref) => const HistoriqueObservationsAdminIndisponible(),
    );
