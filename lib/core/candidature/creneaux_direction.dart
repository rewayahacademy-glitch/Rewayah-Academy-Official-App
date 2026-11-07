/// SALLE-2-ENTRETIEN (07/11/2026) : les creneaux d'entretien, cote direction,
/// sur V1-b (`20261109200000_v1b_creneaux_entretien.sql`, en production,
/// jamais appele jusqu'ici) : `lister_creneaux_entretien`,
/// `ouvrir_creneau_entretien`, `annuler_creneau_entretien`, et
/// `personnel_entretiens` (le personnel de son cote) pour choisir les
/// personnes qui menent l'entretien.
///
/// Le serveur decide de tout : la portee de genre (un creneau declare son
/// cote), la regle des fondateurs, les bornes du debut et de la duree. Les
/// refus metier arrivent dans la reponse et sont dits tels quels.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'modeles_entretien_direction.dart' show PersonnelEntretien;

/// Ce qui manque quand le serveur n'a pas V1-b.
const String dependanceCreneaux = 'V1-b';

/// L'etat d'un creneau.
enum EtatCreneau {
  /// Ouvert, personne n'a reserve.
  libre,

  /// Reserve par un candidat.
  reserve,

  /// Annule par la direction.
  annule,
}

/// Un creneau ouvert par la direction.
class CreneauDirection {
  /// Cree le creneau.
  const CreneauDirection({
    required this.id,
    required this.cote,
    required this.debut,
    required this.fin,
    required this.langues,
    required this.participants,
    required this.fondateurs,
    required this.etat,
  });

  /// Lit une ligne de `lister_creneaux_entretien`.
  factory CreneauDirection.depuisJson(Map<String, dynamic> j) =>
      CreneauDirection(
        id: j['creneau_id'] as String,
        cote: j['cote'] as String? ?? '',
        debut: DateTime.parse(j['debut'] as String).toLocal(),
        fin: DateTime.parse(j['fin'] as String).toLocal(),
        langues: <String>[
          for (final Object? l
              in (j['langues'] as List<Object?>? ?? <Object?>[]))
            if (l is String) l,
        ],
        participants: (j['participants'] as num?)?.toInt() ?? 0,
        fondateurs: (j['fondateurs'] as num?)?.toInt() ?? 0,
        etat: switch (j['etat']) {
          'reserve' => EtatCreneau.reserve,
          'annule' => EtatCreneau.annule,
          _ => EtatCreneau.libre,
        },
      );

  /// L'identifiant.
  final String id;

  /// Le cote (`male` ou `female`).
  final String cote;

  /// Le debut, heure de l'appareil.
  final DateTime debut;

  /// La fin, heure de l'appareil.
  final DateTime fin;

  /// Les langues (codes).
  final List<String> langues;

  /// Le nombre de personnes qui menent l'entretien.
  final int participants;

  /// Le nombre de fondateurs parmi elles.
  final int fondateurs;

  /// L'etat.
  final EtatCreneau etat;
}

/// Le refus d'une ouverture ou d'une annulation (code du serveur).
class RefusCreneau implements Exception {
  /// Cree le refus.
  const RefusCreneau(this.code);

  /// Le code rendu (`debut_invalide`, `creneau_reserve`...).
  final String code;
}

/// La porte des creneaux, cote direction.
abstract interface class PortCreneauxDirection {
  /// Les creneaux des [jours] prochains jours.
  Future<List<CreneauDirection>> lister({int jours = 30});

  /// Le personnel de son cote.
  Future<List<PersonnelEntretien>> personnel();

  /// Ouvre un creneau. [RefusCreneau] sur un refus metier.
  Future<void> ouvrir({
    required String cote,
    required DateTime debut,
    required int dureeMinutes,
    required List<String> langues,
    required List<String> participants,
  });

  /// Annule un creneau libre. [RefusCreneau] sur un refus metier.
  Future<void> annuler(String creneauId);
}

/// L'adaptateur Supabase.
class CreneauxDirectionSupabase implements PortCreneauxDirection {
  /// Cree l'adaptateur.
  const CreneauxDirectionSupabase(this._client);

  final SupabaseClient _client;

  Future<Object?> _appel(String fonction, [Map<String, dynamic>? p]) async {
    try {
      return await _client.rpc<Object?>(fonction, params: p);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceCreneaux);
      }
      rethrow;
    }
  }

  static void _refus(Object? brut) {
    final Object? erreur = brut is Map ? brut['erreur'] : null;
    if (erreur is String) throw RefusCreneau(erreur);
  }

  @override
  Future<List<CreneauDirection>> lister({int jours = 30}) async {
    final Object? brut = await _appel(
      'lister_creneaux_entretien',
      <String, dynamic>{'p_jours': jours},
    );
    return <CreneauDirection>[
      if (brut is List)
        for (final Object? l in brut)
          if (l is Map)
            CreneauDirection.depuisJson(Map<String, dynamic>.from(l)),
    ];
  }

  @override
  Future<List<PersonnelEntretien>> personnel() async {
    final Object? brut = await _appel('personnel_entretiens');
    return <PersonnelEntretien>[
      if (brut is List)
        for (final Object? l in brut)
          if (l is Map)
            PersonnelEntretien.depuisJson(Map<String, dynamic>.from(l)),
    ];
  }

  @override
  Future<void> ouvrir({
    required String cote,
    required DateTime debut,
    required int dureeMinutes,
    required List<String> langues,
    required List<String> participants,
  }) async => _refus(
    await _appel('ouvrir_creneau_entretien', <String, dynamic>{
      'p_cote': cote,
      'p_debut': debut.toUtc().toIso8601String(),
      'p_duree_minutes': dureeMinutes,
      'p_langues': langues,
      'p_participants': participants,
    }),
  );

  @override
  Future<void> annuler(String creneauId) async => _refus(
    await _appel('annuler_creneau_entretien', <String, dynamic>{
      'p_creneau': creneauId,
    }),
  );
}

/// Le port ; absent avant le branchement (capacite indisponible).
final Provider<PortCreneauxDirection?> portCreneauxDirectionProvider =
    Provider<PortCreneauxDirection?>((Ref _) => null);

/// Les creneaux des 30 prochains jours.
final FutureProvider<List<CreneauDirection>> creneauxDirectionProvider =
    FutureProvider.autoDispose<List<CreneauDirection>>((Ref ref) {
      final PortCreneauxDirection? port = ref.watch(
        portCreneauxDirectionProvider,
      );
      if (port == null) {
        return Future<List<CreneauDirection>>.error(
          const CapaciteIndisponible(dependanceCreneaux),
        );
      }
      return port.lister();
    });

/// Le personnel de son cote.
final FutureProvider<List<PersonnelEntretien>> personnelCreneauProvider =
    FutureProvider.autoDispose<List<PersonnelEntretien>>((Ref ref) {
      final PortCreneauxDirection? port = ref.watch(
        portCreneauxDirectionProvider,
      );
      if (port == null) {
        return Future<List<PersonnelEntretien>>.error(
          const CapaciteIndisponible(dependanceCreneaux),
        );
      }
      return port.personnel();
    });
