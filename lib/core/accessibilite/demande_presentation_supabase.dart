// NON-BRANCHE (tolere n° 1 et 18, 08/11/2026, feu vert du pilote) : la
// demande de presentation standard du mineur, sur le serveur.
// Une RPC de la migration 0080 : `demander_presentation_standard()`.
// Le serveur porte la garde (eleve mineur actif d'un foyer actif ; 42501
// sinon) et l'idempotence (une demande deja en attente n'est pas recreee) ;
// il notifie le tuteur.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_demande_presentation.dart';

/// La demande envoyee par Supabase.
class DemandePresentationSupabase implements PortDemandePresentation {
  /// Cree l'adaptateur.
  const DemandePresentationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> demanderPresentationStandard() async {
    await _client.rpc<Object?>('demander_presentation_standard');
  }
}

/// Le port employe par l'application. Nul sans serveur (tests, page montee
/// seule) : la ligne de demande ne s'affiche pas, rien n'est simule.
/// L'application reelle le surcharge par l'adaptateur Supabase (`main.dart`).
final Provider<PortDemandePresentation?> portDemandePresentationProvider =
    Provider<PortDemandePresentation?>((Ref _) => null);
