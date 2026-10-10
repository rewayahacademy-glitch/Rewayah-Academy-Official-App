import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'historique_observations_admin_supabase.dart';
import 'port_historique_observations.dart';

/// Adaptateur de production de l'historique admin, sous RLS
/// `guardian_session_visit`.
final Provider<PortHistoriqueObservationsAdmin>
portHistoriqueObservationsAdminProvider =
    Provider<PortHistoriqueObservationsAdmin>(
      (Ref _) => HistoriqueObservationsAdminSupabase(
        () => Supabase.instance.client,
      ),
    );
