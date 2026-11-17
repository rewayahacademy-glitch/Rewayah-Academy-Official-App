// BE-2b : l'adaptateur Supabase de l'ecran « Equipe ». Il transmet les portes de
// BE-2a-1 (`creer_mission`, `archiver_mission`, `accorder_mission`,
// `retirer_mission`, `lister_*`), celles de BE-2a-2 (`inviter_associe`,
// `revoquer_invitation_associe`, `invitations_associe_admin`) et les lectures de
// BE-2b (`lister_personnes_mission`, `lister_gestes_mission`). Il ne calcule
// rien : le serveur decide. `42501` dit « non autorise » (la double verification
// manque : l'ecran la demande puis rejoue), `PGRST202` / `42883` dit « pas
// encore verse », `22023` dit « parametre refuse » (une cause nommee).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'modeles_equipe.dart';
import 'port_equipe.dart';

/// L'equipe servie par Supabase.
class EquipeSupabase implements PortEquipe {
  /// Cree l'adaptateur sur le client de l'application.
  EquipeSupabase(SupabaseClient client)
    : _appel = ((String f, Map<String, dynamic> p) =>
          client.rpc<Object?>(f, params: p));

  /// Cree l'adaptateur sur un appel injecte (tests).
  EquipeSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String fonction, Map<String, dynamic> params)
  _appel;

  Future<Object?> _rpc(String fonction, [Map<String, dynamic>? params]) async {
    try {
      return await _appel(fonction, params ?? const <String, dynamic>{});
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceEquipe);
      }
      if (e.code == '22023') throw RefusEquipe(causeDepuisMessage(e.message));
      rethrow;
    }
  }

  List<T> _liste<T>(Object? brut, T? Function(Object?) lire) => <T>[
    if (brut is List)
      for (final Object? l in brut)
        if (lire(l) case final T v) v,
  ];

  @override
  Future<List<Mission>> missions() async =>
      _liste<Mission>(await _rpc('lister_missions'), Mission.depuisJson);

  @override
  Future<List<Attribution>> attributions() async => _liste<Attribution>(
    await _rpc('lister_attributions', <String, dynamic>{
      'p_filtre': <String, dynamic>{},
    }),
    Attribution.depuisJson,
  );

  @override
  Future<List<PersonneMission>> personnes() async => _liste<PersonneMission>(
    await _rpc('lister_personnes_mission'),
    PersonneMission.depuisJson,
  );

  @override
  Future<List<String>> gestesOuverts() async {
    final Object? brut = await _rpc('lister_gestes_mission');
    return <String>[
      if (brut is List)
        for (final Object? g in brut)
          if (g is String) g,
    ];
  }

  @override
  Future<List<InvitationAssocie>> invitations() async =>
      _liste<InvitationAssocie>(
        await _rpc('invitations_associe_admin'),
        InvitationAssocie.depuisJson,
      );

  @override
  Future<String> creerMission({
    required String nom,
    required List<String> gestes,
    required String cle,
  }) async {
    final Object? id = await _rpc('creer_mission', <String, dynamic>{
      'p_nom': nom,
      'p_gestes': gestes,
      'p_cle': cle,
    });
    if (id is! String) throw const FormatException('Identifiant attendu.');
    return id;
  }

  @override
  Future<void> archiverMission({
    required String id,
    required String motif,
    required String cle,
  }) async {
    await _rpc('archiver_mission', <String, dynamic>{
      'p_id': id,
      'p_motif': motif,
      'p_cle': cle,
    });
  }

  @override
  Future<String> accorder({
    required String profil,
    required String mission,
    required List<String> langues,
    required List<String> etapes,
    required DateTime? debut,
    required DateTime? fin,
    required String cle,
  }) async {
    final Object? id = await _rpc('accorder_mission', <String, dynamic>{
      'p_profile_id': profil,
      'p_mission_id': mission,
      'p_perimetre': perimetreEnvoye(langues: langues, etapes: etapes),
      'p_debut': debut?.toUtc().toIso8601String(),
      'p_fin': fin?.toUtc().toIso8601String(),
      'p_cle': cle,
    });
    if (id is! String) throw const FormatException('Identifiant attendu.');
    return id;
  }

  @override
  Future<void> retirer({
    required String attribution,
    required String motif,
    required String cle,
  }) async {
    await _rpc('retirer_mission', <String, dynamic>{
      'p_attribution_id': attribution,
      'p_motif': motif,
      'p_cle': cle,
    });
  }

  @override
  Future<ResultatInvitation> inviter({
    required String courriel,
    required String? nom,
    required String cle,
  }) async {
    final ResultatInvitation? r = ResultatInvitation.depuisJson(
      await _rpc('inviter_associe', <String, dynamic>{
        'p_courriel': courriel,
        'p_nom': nom,
        'p_cle': cle,
      }),
    );
    if (r == null) throw const FormatException('Reponse illisible.');
    return r;
  }

  @override
  Future<void> revoquer({
    required String id,
    required String motif,
    required String cle,
  }) async {
    await _rpc('revoquer_invitation_associe', <String, dynamic>{
      'p_id': id,
      'p_motif': motif,
      'p_cle': cle,
    });
  }
}

/// Le perimetre envoye a `accorder_mission` : seulement les listes cochees.
/// Le cote n'y est jamais : le serveur l'ecrit (c'est celui de la personne).
Map<String, dynamic> perimetreEnvoye({
  required List<String> langues,
  required List<String> etapes,
}) => <String, dynamic>{
  if (langues.isNotEmpty) 'langues': langues,
  if (etapes.isNotEmpty) 'etapes': etapes,
};

/// La cause d'un refus `22023`, lue dans les mots que le serveur emploie
/// (jamais montres : seule la cause nommee l'est).
CauseRefusEquipe causeDepuisMessage(String message) {
  final String m = message.toLowerCase();
  if (m.contains('genre du compte inconnu')) {
    return CauseRefusEquipe.genreInconnu;
  }
  if (m.contains('compte de personnel indisponible')) {
    return CauseRefusEquipe.personneIndisponible;
  }
  if (m.contains('attribution active deja presente')) {
    return CauseRefusEquipe.attributionActive;
  }
  if (m.contains('mission inconnue ou archivee')) {
    return CauseRefusEquipe.missionIndisponible;
  }
  if (m.contains('cle d\'accord deja utilisee') ||
      m.contains('cle de mission deja utilisee')) {
    return CauseRefusEquipe.cleDejaUtilisee;
  }
  if (m.contains('geste de mission inconnu')) {
    return CauseRefusEquipe.gestesNonAdmis;
  }
  if (m.contains('parametres de') || m.contains('perimetre invalide')) {
    return CauseRefusEquipe.parametresInvalides;
  }
  return CauseRefusEquipe.autre;
}
