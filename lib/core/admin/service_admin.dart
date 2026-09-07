import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../matching/service_matching.dart';

/// Les six compteurs de `ADM-01`.
///
/// **Le zero est une valeur comme une autre**, jamais une raison de masquer un
/// compteur : un compteur qui disparait a zero fait douter s'il a ete charge ou
/// s'il est reellement nul.
@immutable
class IndicateursAdmin {
  /// Cree un releve.
  const IndicateursAdmin({
    required this.dossiersEnAttente,
    required this.foyersSansEnseignant,
    required this.rapportsManquants,
    required this.incidents24h,
    required this.comptesEchus,
    required this.demandesEnAttente,
  });

  /// Lit la ligne rendue par `indicateurs_admin()`.
  factory IndicateursAdmin.depuisJson(Map<String, dynamic> json) {
    int lire(String cle) => (json[cle] as num?)?.toInt() ?? 0;
    return IndicateursAdmin(
      dossiersEnAttente: lire('dossiers_en_attente'),
      foyersSansEnseignant: lire('foyers_sans_enseignant'),
      rapportsManquants: lire('rapports_manquants'),
      incidents24h: lire('incidents_24h'),
      comptesEchus: lire('comptes_echus'),
      demandesEnAttente: lire('demandes_en_attente'),
    );
  }

  /// Dossiers d'identite en attente de validation.
  final int dossiersEnAttente;

  /// Foyers dont au moins un eleve n'a pas d'enseignant.
  final int foyersSansEnseignant;

  /// Seances terminees sans cahier de transmission.
  final int rapportsManquants;

  /// Seances en echec ou en absence sur les dernieres 24 heures.
  final int incidents24h;

  /// Comptes provisoires dont l'acces est echu (ADR-014).
  final int comptesEchus;

  /// Demandes des quatre parties en attente de decision (ADR-017).
  final int demandesEnAttente;
}

/// Le centre de commande et la file des demandes.
abstract interface class ServiceAdmin {
  /// Les six compteurs, en une seule lecture.
  Future<IndicateursAdmin> indicateurs();

  /// La file de `ADM-06`, anciennete d'abord.
  Future<List<Demande>> demandesEnAttente();

  /// Tranche une demande. Un refus exige un motif, comme pour un dossier.
  ///
  /// L'effet metier est applique **en base** : l'affectation se clot, la regle
  /// se pose, le plafond change. L'ecran ne fait que rendre le verdict.
  Future<void> decider({
    required String demandeId,
    required bool accepte,
    String? motif,
  });
}

/// L'implementation reelle.
class ServiceAdminSupabase implements ServiceAdmin {
  /// Cree le service.
  const ServiceAdminSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<IndicateursAdmin> indicateurs() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'indicateurs_admin',
    );
    if (reponse.isEmpty) {
      throw StateError('aucun indicateur rendu');
    }
    return IndicateursAdmin.depuisJson(reponse.first as Map<String, dynamic>);
  }

  @override
  Future<List<Demande>> demandesEnAttente() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'demandes_en_attente',
    );
    return reponse
        .map(
          (dynamic ligne) => Demande.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> decider({
    required String demandeId,
    required bool accepte,
    String? motif,
  }) => _client.rpc<void>(
    'decider_demande',
    params: <String, dynamic>{
      'p_request_id': demandeId,
      'p_accepte': accepte,
      'p_motif': motif,
    },
  );
}

/// Le service d'administration employe par l'application.
final Provider<ServiceAdmin> serviceAdminProvider = Provider<ServiceAdmin>(
  (Ref ref) => ServiceAdminSupabase(Supabase.instance.client),
);

/// Les six compteurs de `ADM-01`.
final FutureProvider<IndicateursAdmin> indicateursProvider =
    FutureProvider<IndicateursAdmin>(
      (Ref ref) => ref.watch(serviceAdminProvider).indicateurs(),
    );

/// La file de `ADM-06`.
final FutureProvider<List<Demande>> demandesProvider =
    FutureProvider<List<Demande>>(
      (Ref ref) => ref.watch(serviceAdminProvider).demandesEnAttente(),
    );
