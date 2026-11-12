import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'lieu_priere.dart';
import 'pause_prevue.dart';

/// La priere, lue sur le serveur (PRIERE-1).
///
/// **Un seul calcul, celui du serveur.** Les heures de priere se calculent en
/// SQL (`private.priere_calculer`) ; l'application ne calcule plus rien. Les
/// quatre roles lisent le meme chiffre, et la position de l'enseignant reste
/// entre lui et la direction.
abstract interface class ServicePriere {
  /// La pause de priere placee dans une seance. `null` : aucune priere
  /// n'entre pendant la seance, ou l'enseignant n'a pas de lieu. Lue par
  /// l'enseignant de la seance, les eleves de la classe, leur tuteur et la
  /// direction ; le serveur refuse tout autre.
  Future<PausePrevue?> pausePrevue(String seanceId);

  /// Le lieu et les reglages de l'enseignant connecte, ou, pour la direction,
  /// d'un enseignant. `null` : pas de lieu pose.
  Future<LieuPriere?> lieu({String? enseignantId});

  /// Les cinq heures du jour local de l'enseignant (lui, ou la direction pour
  /// un enseignant). Vide quand il n'a pas de lieu.
  Future<List<HeurePriere>> horairesDuJour({
    String? enseignantId,
    DateTime? jour,
  });

  /// L'enseignant ajuste une priere, de -30 a +30 minutes.
  Future<void> ajuster(Priere priere, int minutes);

  /// La direction pose le lieu d'un enseignant.
  Future<void> definirLieu(DefinitionLieu definition);

  /// La direction retire le lieu d'un enseignant.
  Future<void> retirerLieu(String enseignantId);

  /// La direction : les enseignants et l'etat de leur lieu.
  Future<List<EnseignantPriere>> enseignants();

  /// La direction : ce que les creneaux d'une classe croisent sur 12 mois.
  Future<List<LectureCreneauPriere>> lectureClasse(String groupeId);

  /// La direction : les comptes dont le fuseau, le pays et le lieu different.
  Future<List<IncoherencePriere>> incoherences();
}

/// L'implementation reelle, par les fonctions du serveur.
class ServicePriereSupabase implements ServicePriere {
  /// Cree le service.
  const ServicePriereSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PausePrevue?> pausePrevue(String seanceId) async {
    // Un cours dont la seance n'existe pas encore (reperes locaux) n'a pas de
    // pause : rien a demander au serveur.
    if (seanceId.startsWith('cours-sans-seance:')) {
      return null;
    }
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'pause_prevue_seance',
      params: <String, dynamic>{'p_session_id': seanceId},
    );
    if (lignes.isEmpty) {
      return null;
    }
    return PausePrevue.depuisJson(
      seanceId,
      Map<String, dynamic>.from(lignes.first as Map<dynamic, dynamic>),
    );
  }

  @override
  Future<LieuPriere?> lieu({String? enseignantId}) async {
    final Object? json = await _client.rpc<Object?>(
      'priere_reglages_lire',
      params: <String, dynamic>{'p_enseignant_id': enseignantId},
    );
    return json is Map<dynamic, dynamic>
        ? LieuPriere.depuisJson(Map<String, dynamic>.from(json))
        : null;
  }

  @override
  Future<List<HeurePriere>> horairesDuJour({
    String? enseignantId,
    DateTime? jour,
  }) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'priere_horaires_jour',
      params: <String, dynamic>{
        'p_enseignant_id': enseignantId,
        'p_jour': jour == null ? null : _date(jour),
      },
    );
    return <HeurePriere>[
      for (final Object? ligne in lignes)
        if (ligne is Map<dynamic, dynamic>)
          ?HeurePriere.depuisJson(Map<String, dynamic>.from(ligne)),
    ];
  }

  @override
  Future<void> ajuster(Priere priere, int minutes) => _client.rpc<void>(
    'priere_ajuster',
    params: <String, dynamic>{
      'p_priere': priere.valeurSql,
      'p_minutes': minutes,
    },
  );

  @override
  Future<void> definirLieu(DefinitionLieu d) => _client.rpc<void>(
    'priere_lieu_definir',
    params: <String, dynamic>{
      'p_enseignant_id': d.enseignantId,
      'p_lieu': d.lieu,
      'p_latitude': d.latitude,
      'p_longitude': d.longitude,
      'p_fuseau': d.fuseau,
      'p_methode': d.methode?.valeurSql,
      'p_ecole_asr': d.ecoleAsr?.valeurSql,
      'p_assiste_vendredi': d.assisteVendredi,
      'p_vendredi_debut': d.vendrediDebut,
      'p_vendredi_fin': d.vendrediFin,
    },
  );

  @override
  Future<void> retirerLieu(String enseignantId) => _client.rpc<void>(
    'priere_lieu_retirer',
    params: <String, dynamic>{'p_enseignant_id': enseignantId},
  );

  @override
  Future<List<EnseignantPriere>> enseignants() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'priere_enseignants_liste',
    );
    return <EnseignantPriere>[
      for (final Object? ligne in lignes)
        if (ligne is Map<dynamic, dynamic>)
          EnseignantPriere.depuisJson(Map<String, dynamic>.from(ligne)),
    ];
  }

  @override
  Future<List<LectureCreneauPriere>> lectureClasse(String groupeId) async {
    final Object? json = await _client.rpc<Object?>(
      'priere_lecture_classe',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    if (json is! Map<dynamic, dynamic>) {
      return const <LectureCreneauPriere>[];
    }
    final Object? creneaux = json['creneaux'];
    return <LectureCreneauPriere>[
      if (creneaux is List<dynamic>)
        for (final Object? c in creneaux)
          if (c is Map<dynamic, dynamic>)
            LectureCreneauPriere.depuisJson(Map<String, dynamic>.from(c)),
    ];
  }

  @override
  Future<List<IncoherencePriere>> incoherences() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'priere_incoherences_enseignants',
    );
    return <IncoherencePriere>[
      for (final Object? ligne in lignes)
        if (ligne is Map<dynamic, dynamic>)
          IncoherencePriere.depuisJson(Map<String, dynamic>.from(ligne)),
    ];
  }
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Le service de priere employe par l'application.
final Provider<ServicePriere> servicePriereProvider = Provider<ServicePriere>(
  (Ref ref) => ServicePriereSupabase(Supabase.instance.client),
);

/// La pause de priere placee dans une seance.
final FutureProviderFamily<PausePrevue?, String> pausePrevueProvider =
    FutureProvider.family<PausePrevue?, String>(
      (Ref ref, String seanceId) =>
          ref.watch(servicePriereProvider).pausePrevue(seanceId),
    );

/// Le lieu et les reglages de priere de l'enseignant connecte.
final FutureProvider<LieuPriere?> monLieuPriereProvider =
    FutureProvider<LieuPriere?>(
      (Ref ref) => ref.watch(servicePriereProvider).lieu(),
    );

/// Les cinq heures du jour de l'enseignant connecte.
final FutureProvider<List<HeurePriere>> mesHorairesPriereProvider =
    FutureProvider<List<HeurePriere>>(
      (Ref ref) => ref.watch(servicePriereProvider).horairesDuJour(),
    );
