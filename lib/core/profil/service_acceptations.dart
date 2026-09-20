import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/domain/enums.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';

/// Une piece signee une fois, telle que `contract_acceptances` la conserve.
///
/// Pourquoi ce contrat existe : `deciderRedirection` ferme tout le sous-arbre
/// `/attente/*` des qu'un compte devient actif. Un enseignant valide ne peut
/// donc plus relire ni son contrat ni ses accuses, alors que le protocole exige
/// que les informations contractuelles restent lisibles en permanence. La
/// donnee etait deja lisible en base -- la policy `contract_acceptances_self_read`
/// autorise le titulaire depuis la migration `0004` -- il manquait seulement de
/// quoi l'afficher.
class Acceptation {
  /// Cree une acceptation.
  const Acceptation({
    required this.sorte,
    required this.version,
    required this.accepteeLe,
  });

  /// Construit l'acceptation depuis une ligne Supabase.
  ///
  /// Rend `null` sur une sorte inconnue plutot que de replier sur une valeur
  /// plausible : afficher « contrat enseignant » sur une ligne qu'on n'a pas su
  /// lire serait affirmer une signature.
  static Acceptation? depuisJson(Map<String, dynamic> json) {
    final SorteContrat? sorte = _sorte(json['contract_kind']);
    final Object? quand = json['accepted_at'];
    final DateTime? accepteeLe = quand is String
        ? DateTime.tryParse(quand)?.toLocal()
        : null;
    if (sorte == null || accepteeLe == null) {
      return null;
    }
    final Object? version = json['version'];
    return Acceptation(
      sorte: sorte,
      version: version is String ? version : '',
      accepteeLe: accepteeLe,
    );
  }

  /// La sorte signee, telle que la contrainte SQL l'autorise.
  final SorteContrat sorte;

  /// La version du texte signe. L'unicite en base porte sur le triplet
  /// profil / sorte / version : changer la version redemande la signature.
  final String version;

  /// Quand la signature a eu lieu, en heure locale.
  final DateTime accepteeLe;

  static SorteContrat? _sorte(Object? valeur) {
    for (final SorteContrat sorte in SorteContrat.values) {
      if (sorte.valeurSql == valeur) {
        return sorte;
      }
    }
    return null;
  }
}

/// Contrat de lecture des pieces signees par la personne connectee.
///
/// Lecture seule, sans exception : aucune methode d'ecriture n'est declaree ici,
/// et c'est voulu. La seule ecriture legitime de `contract_acceptances` passe
/// par `ServiceDossier.accepterContrat`, dans le tunnel d'entree, et un trigger
/// rend la ligne immuable ensuite.
abstract interface class ServiceAcceptations {
  /// Les pieces signees par un profil, de la plus recente a la plus ancienne.
  Future<List<Acceptation>> acceptations(String profilId);
}

/// Lecture Supabase, sans migration ni RPC : la policy suffit.
class ServiceAcceptationsSupabase implements ServiceAcceptations {
  /// Cree le service a partir d'un client Supabase.
  const ServiceAcceptationsSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Acceptation>> acceptations(String profilId) async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('contract_acceptances')
        .select('contract_kind, version, accepted_at')
        .eq('profile_id', profilId)
        .order('accepted_at', ascending: false);

    return <Acceptation>[
      for (final Map<String, dynamic> ligne in lignes)
        if (Acceptation.depuisJson(ligne) case final Acceptation lue) lue,
    ];
  }
}

/// Le service d'acceptations employe par l'application.
final Provider<ServiceAcceptations> serviceAcceptationsProvider =
    Provider<ServiceAcceptations>(
      (Ref ref) => ServiceAcceptationsSupabase(Supabase.instance.client),
    );

/// Les pieces signees par la personne connectee.
///
/// Le `profileId` se lit dans la session et nulle part ailleurs : c'est la
/// seule source du profil courant cote client.
final FutureProvider<List<Acceptation>> acceptationsProvider =
    FutureProvider<List<Acceptation>>((Ref ref) {
      final String? profilId = ref.watch(
        sessionProvider.select((SessionState session) => session.profileId),
      );
      if (profilId == null) {
        return const <Acceptation>[];
      }
      return ref.watch(serviceAcceptationsProvider).acceptations(profilId);
    });
