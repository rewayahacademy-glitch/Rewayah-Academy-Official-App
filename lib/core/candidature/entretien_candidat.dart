/// SALLE-2-ENTRETIEN (plan des trois salles, lot 3, feu vert du 07/11/2026) :
/// l'entretien vu par le candidat, « Faisons connaissance ».
///
/// Le serveur existe deja (V1-b, `20261109200000_v1b_creneaux_entretien.sql`) :
/// - `creneaux_entretien_disponibles()` : les creneaux ouverts de son cote,
///   dans une de ses langues, a plus de 30 minutes ;
/// - `reserver_creneau_entretien(creneau, version, cle)` : le geste
///   `planifier_entretien` du moteur (auteur candidat), qui cree la seance
///   d'entretien et y inscrit le candidat ; les refus metier arrivent dans la
///   reponse (`{"erreur": ...}`) ;
/// - `mon_entretien()` : la date de son entretien, et l'heure ou il ouvre.
///
/// Ni nom ni contact des personnes qui menent l'entretien ne sont lus ici.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'port_ma_candidature.dart' show HorsLigneCandidature;

/// Ce qui manque quand le serveur n'a pas les fonctions de V1-b.
const String dependanceEntretienCandidat = 'V1-b';

/// Un creneau ouvert que le candidat peut reserver.
class CreneauOuvert {
  /// Cree le creneau.
  const CreneauOuvert({
    required this.id,
    required this.debut,
    required this.fin,
    required this.langues,
  });

  /// Lit une ligne de `creneaux_entretien_disponibles()`.
  factory CreneauOuvert.depuisJson(Map<String, dynamic> j) => CreneauOuvert(
    id: j['creneau_id'] as String,
    debut: DateTime.parse(j['debut'] as String).toLocal(),
    fin: DateTime.parse(j['fin'] as String).toLocal(),
    langues: <String>[
      for (final Object? l in (j['langues'] as List<Object?>? ?? <Object?>[]))
        if (l is String) l,
    ],
  );

  /// L'identifiant du creneau.
  final String id;

  /// Le debut, heure de l'appareil.
  final DateTime debut;

  /// La fin, heure de l'appareil.
  final DateTime fin;

  /// Les langues de l'entretien (codes).
  final List<String> langues;
}

/// L'entretien reserve du candidat.
class MonEntretien {
  /// Cree l'entretien.
  const MonEntretien({
    required this.seanceId,
    required this.debut,
    required this.fin,
    required this.ouvertureLe,
    required this.statut,
  });

  /// Lit `mon_entretien()`.
  factory MonEntretien.depuisJson(Map<String, dynamic> j) => MonEntretien(
    seanceId: j['sessionId'] as String,
    debut: DateTime.parse(j['debut'] as String).toLocal(),
    fin: DateTime.parse(j['fin'] as String).toLocal(),
    ouvertureLe: j['ouvertureLe'] is String
        ? DateTime.parse(j['ouvertureLe'] as String).toLocal()
        : null,
    statut: j['statut'] as String? ?? 'planned',
  );

  /// La seance d'entretien (celle que `/salle` ouvre).
  final String seanceId;

  /// Le debut, heure de l'appareil.
  final DateTime debut;

  /// La fin, heure de l'appareil.
  final DateTime fin;

  /// L'heure ou l'on peut rejoindre (10 minutes avant), ou `null`.
  final DateTime? ouvertureLe;

  /// L'etat de la seance cote serveur (`planned`, `live`...).
  final String statut;

  /// Vrai quand le candidat peut rejoindre a [maintenant] : l'ouverture est
  /// passee et la fin ne l'est pas. Le serveur decide encore a l'entree.
  bool ouvertA(DateTime maintenant) =>
      !maintenant.isBefore(ouvertureLe ?? debut) && maintenant.isBefore(fin);
}

/// Le refus d'une reservation, rendu par le serveur.
enum RefusReservation {
  /// Le creneau vient d'etre pris, annule, ou n'est plus tenable.
  creneauIndisponible,

  /// Un entretien est deja planifie pour cette candidature.
  dejaPlanifie,

  /// La candidature a change pendant la lecture (version attendue).
  versionPerimee,

  /// Toute autre raison.
  autre,
}

/// L'issue d'une reservation : l'entretien, ou un refus.
typedef IssueReservation = ({MonEntretien? entretien, RefusReservation? refus});

/// La porte du candidat vers son entretien.
abstract interface class PortEntretienCandidat {
  /// Les creneaux ouverts.
  Future<List<CreneauOuvert>> creneaux();

  /// Reserve [creneau] ; [version] est celle du dossier lu.
  Future<IssueReservation> reserver({
    required String creneau,
    required int version,
    required String cle,
  });

  /// L'entretien reserve, ou `null`.
  Future<MonEntretien?> monEntretien();
}

/// Sans serveur branche : la capacite est dite indisponible.
class EntretienCandidatIndisponible implements PortEntretienCandidat {
  /// Cree le port.
  const EntretienCandidatIndisponible();

  Never _non() => throw const CapaciteIndisponible(dependanceEntretienCandidat);

  @override
  Future<List<CreneauOuvert>> creneaux() async => _non();

  @override
  Future<IssueReservation> reserver({
    required String creneau,
    required int version,
    required String cle,
  }) async => _non();

  @override
  Future<MonEntretien?> monEntretien() async => _non();
}

/// L'adaptateur Supabase.
class EntretienCandidatSupabase implements PortEntretienCandidat {
  /// Cree l'adaptateur.
  const EntretienCandidatSupabase(this._client);

  final SupabaseClient _client;

  Future<Object?> _appel(String fonction, [Map<String, dynamic>? p]) async {
    try {
      return await _client.rpc<Object?>(fonction, params: p);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceEntretienCandidat);
      }
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const HorsLigneCandidature();
    }
  }

  @override
  Future<List<CreneauOuvert>> creneaux() async {
    final Object? brut = await _appel('creneaux_entretien_disponibles');
    return <CreneauOuvert>[
      if (brut is List)
        for (final Object? l in brut)
          if (l is Map) CreneauOuvert.depuisJson(Map<String, dynamic>.from(l)),
    ];
  }

  @override
  Future<IssueReservation> reserver({
    required String creneau,
    required int version,
    required String cle,
  }) async {
    final Object? brut = await _appel(
      'reserver_creneau_entretien',
      <String, dynamic>{
        'p_creneau': creneau,
        'p_version_attendue': version,
        'p_cle_idempotence': cle,
      },
    );
    final Map<String, dynamic> j = brut is Map
        ? Map<String, dynamic>.from(brut)
        : <String, dynamic>{};
    final Object? erreur = j['erreur'];
    if (erreur is String) {
      return (
        entretien: null,
        refus: switch (erreur) {
          'creneau_indisponible' => RefusReservation.creneauIndisponible,
          'entretien_deja_planifie' => RefusReservation.dejaPlanifie,
          // La version attendue ne correspond plus (moteur des
          // candidatures, `candidature_geste_ouvrir`).
          'conflit_candidature' => RefusReservation.versionPerimee,
          _ => RefusReservation.autre,
        },
      );
    }
    // L'entretien reserve se relit : une seule source, `mon_entretien()`.
    return (entretien: await monEntretien(), refus: null);
  }

  @override
  Future<MonEntretien?> monEntretien() async {
    final Object? brut = await _appel('mon_entretien');
    return brut is Map
        ? MonEntretien.depuisJson(Map<String, dynamic>.from(brut))
        : null;
  }
}

/// Le port ; l'application le surcharge avec l'adaptateur Supabase.
final Provider<PortEntretienCandidat> portEntretienCandidatProvider =
    Provider<PortEntretienCandidat>(
      (Ref _) => const EntretienCandidatIndisponible(),
    );

/// L'entretien reserve du candidat.
final FutureProvider<MonEntretien?> monEntretienProvider =
    FutureProvider<MonEntretien?>(
      (Ref ref) => ref.watch(portEntretienCandidatProvider).monEntretien(),
    );

/// Les creneaux ouverts.
final FutureProvider<List<CreneauOuvert>> creneauxOuvertsProvider =
    FutureProvider<List<CreneauOuvert>>(
      (Ref ref) => ref.watch(portEntretienCandidatProvider).creneaux(),
    );
