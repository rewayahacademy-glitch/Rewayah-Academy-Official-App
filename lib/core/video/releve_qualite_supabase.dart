// Lot RESEAU-PREUVE (11/11/2026) : l'adaptateur Supabase du releve de
// qualite. Une RPC de la migration 20261123700100 : `noter_qualite_lien`. Le
// serveur porte les gardes (participant de la seance, sa propre ligne, rythme,
// etats prevus) ; rien n'est decide ici.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'releve_qualite.dart';

/// Le code que le serveur rend quand il refuse d'ecrire (pas participant,
/// hors de la seance, ligne d'un autre).
const String codeReleveRefuse = '42501';

/// Le code que le serveur rend quand la fonction n'existe pas : le releve
/// n'est pas installe sur ce serveur. **C'est l'interrupteur du releve** :
/// tant que la direction n'a pas installe la migration, l'appareil fait un
/// seul appel par entree en salle, recoit ce code, et se tait.
const String codeReleveAbsent = 'PGRST202';

/// Le meme fait, dit par la base elle-meme (fonction inconnue).
const String codeFonctionInconnue = '42883';

/// Vrai quand ce code d'erreur veut dire « n'ecris plus rien pour cette
/// entree en salle » (refus, ou releve non installe) ; faux pour une panne,
/// qui se retente.
bool releveAArreter(String? code) =>
    code == codeReleveRefuse ||
    code == codeReleveAbsent ||
    code == codeFonctionInconnue;

/// Le releve de qualite ecrit sur Supabase.
class ReleveQualiteSupabase implements PortReleveQualite {
  /// Cree l'adaptateur.
  const ReleveQualiteSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ReponseReleve> noter({
    required String seanceId,
    required String profilId,
    required EtatReleve etat,
    required bool microOuvert,
  }) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'noter_qualite_lien',
        params: <String, Object?>{
          'p_session_id': seanceId,
          'p_profile_id': profilId,
          'p_etat': etat.name,
          'p_micro_ouvert': microOuvert,
        },
      );
      return reponseReleveDepuis(reponse);
    } on PostgrestException catch (e) {
      if (releveAArreter(e.code)) return ReponseReleve.refusee;
      rethrow;
    }
  }
}

/// Lit la reponse de `noter_qualite_lien` : `true`, la ligne est ecrite ;
/// toute autre valeur, le serveur l'a ignoree.
ReponseReleve reponseReleveDepuis(Object? reponse) =>
    reponse == true ? ReponseReleve.ecrite : ReponseReleve.ignoree;
