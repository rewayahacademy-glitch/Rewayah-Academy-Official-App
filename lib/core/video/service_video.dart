import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'video_session_provider.dart';

/// Pourquoi une salle refuse d'ouvrir.
///
/// Le backend, lui, ne distingue pas : il repond « acces a la salle refuse »
/// sans dire si la seance existe, si elle a commence, ou si l'appelant est
/// simplement en avance -- un participant qui tente une salle qui n'est pas la
/// sienne n'a pas a l'apprendre. Cette enumeration ne sert donc qu'a separer ce
/// que le client PEUT distinguer sans rien reveler : un refus, une panne de
/// configuration, et une coupure reseau.
enum MotifRefusSalle {
  /// La video n'est pas encore branchee sur ce deploiement.
  videoNonConfiguree,

  /// Le fournisseur retenu n'a pas de trousseau utilisable.
  fournisseurIndisponible,

  /// L'acces est refuse : pas inscrit, hors fenetre, ou seance close.
  acces,

  /// Le reseau ou le backend n'a pas repondu.
  reseau,
}

/// L'echec d'une entree en salle.
class EchecSalle implements Exception {
  /// Cree un echec.
  const EchecSalle(this.motif);

  /// Ce qui a empeche l'entree.
  final MotifRefusSalle motif;

  @override
  String toString() => 'EchecSalle($motif)';
}

/// L'acces a la salle, et la sortie volontaire.
abstract interface class ServiceVideo {
  /// Demande au backend le droit d'entrer dans une seance.
  Future<AccesSalle> acces(String seanceId);

  /// Annonce un depart **volontaire**, avant de se deconnecter.
  ///
  /// C'est la seule ecriture de presence confiee au client, et c'est elle qui
  /// empeche `sortie` de se confondre avec `deconnectee` : les deux produisent
  /// le meme evenement `left` cote LiveKit, seule la source les distingue.
  Future<void> annoncerSortie(String seanceId);
}

/// L'implementation reelle.
class ServiceVideoSupabase implements ServiceVideo {
  /// Cree le service.
  const ServiceVideoSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<AccesSalle> acces(String seanceId) async {
    final FunctionResponse reponse;
    try {
      reponse = await _client.functions.invoke(
        'create-room-token',
        body: <String, dynamic>{'session_id': seanceId},
      );
    } on FunctionException catch (e) {
      throw EchecSalle(_motifDe(e.status, e.details));
    } catch (_) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }

    final Object? corps = reponse.data;
    if (corps is! Map<String, dynamic>) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }
    return AccesSalle.depuisJson(corps);
  }

  /// Traduit le refus du backend, sans jamais inventer une raison qu'il n'a
  /// pas donnee.
  MotifRefusSalle _motifDe(int statut, Object? details) {
    if (statut == 503) {
      final String message = details is Map<String, dynamic>
          ? (details['error'] as String? ?? '')
          : details?.toString() ?? '';
      return message.contains('non configuree')
          ? MotifRefusSalle.videoNonConfiguree
          : MotifRefusSalle.fournisseurIndisponible;
    }
    if (statut == 401 || statut == 403) {
      return MotifRefusSalle.acces;
    }
    return MotifRefusSalle.reseau;
  }

  @override
  Future<void> annoncerSortie(String seanceId) async {
    // Un echec ici ne doit jamais empecher de quitter la salle : au pire la
    // sortie sera lue comme une deconnexion, ce qui est desagreable mais pas
    // faux. Retenir l'usager dans une salle parce qu'une ecriture a echoue le
    // serait, lui.
    try {
      await _client.rpc<void>(
        'quitter_salle',
        params: <String, dynamic>{'p_session_id': seanceId},
      );
    } catch (e) {
      debugPrint('annonce de sortie impossible : $e');
    }
  }
}

/// Le service video employe par l'application.
final Provider<ServiceVideo> serviceVideoProvider = Provider<ServiceVideo>(
  (Ref ref) => ServiceVideoSupabase(Supabase.instance.client),
);
