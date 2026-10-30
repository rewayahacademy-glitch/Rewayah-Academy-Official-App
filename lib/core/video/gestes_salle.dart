import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que l'enseignant peut faire a un eleve dans la salle (30/10/2026).
enum GesteSalle {
  /// Couper son micro. L'eleve peut le rouvrir lui-meme.
  couperMicro('couper_micro'),

  /// Couper sa camera. L'eleve peut la rallumer lui-meme.
  couperCamera('couper_camera'),

  /// Le faire sortir de la salle. Il ne revient dans cette seance que
  /// readmis par l'enseignant.
  faireSortir('faire_sortir');

  const GesteSalle(this.code);

  /// Le nom attendu par la fonction `salle-gestes`.
  final String code;
}

/// Un eleve sorti de la seance par l'enseignant, pas encore readmis.
@immutable
class EleveSorti {
  /// Cree une ligne.
  const EleveSorti({required this.profilId, required this.prenom});

  /// Lit une ligne de `eleves_sortis_salle`.
  factory EleveSorti.depuisJson(Map<String, dynamic> json) => EleveSorti(
    profilId: json['profile_id'] as String? ?? '',
    prenom: json['prenom'] as String? ?? '',
  );

  /// Son profil, qui est aussi son identite dans la salle.
  final String profilId;

  /// Son prenom.
  final String prenom;
}

/// Les gestes de l'enseignant sur un eleve.
///
/// **L'ecran ne decide rien** : il propose ces gestes quand le jeton porte
/// `can_moderate` (`CapacitesSalle.peutModerer`), et la base reverifie a
/// chaque appel que l'appelant est l'enseignant effectif de la seance.
abstract interface class PortGestesSalle {
  /// Applique [geste] a l'eleve [eleveId] dans la seance [seanceId].
  Future<void> appliquer(String seanceId, String eleveId, GesteSalle geste);

  /// Readmet l'eleve [eleveId] sorti de la seance [seanceId].
  Future<void> readmettre(String seanceId, String eleveId);

  /// Les eleves sortis de la seance [seanceId], pas encore readmis.
  Future<List<EleveSorti>> sortis(String seanceId);
}

/// L'implementation reelle : la fonction `salle-gestes` pour ce qui passe par
/// le serveur video, deux RPC pour la readmission et la liste.
class GestesSalleSupabase implements PortGestesSalle {
  /// Cree le service.
  const GestesSalleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> appliquer(
    String seanceId,
    String eleveId,
    GesteSalle geste,
  ) async {
    await _client.functions.invoke(
      'salle-gestes',
      body: <String, dynamic>{
        'session_id': seanceId,
        'eleve_id': eleveId,
        'geste': geste.code,
      },
    );
  }

  @override
  Future<void> readmettre(String seanceId, String eleveId) => _client.rpc<void>(
    'readmettre_eleve_salle',
    params: <String, dynamic>{'p_session_id': seanceId, 'p_cible': eleveId},
  );

  @override
  Future<List<EleveSorti>> sortis(String seanceId) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'eleves_sortis_salle',
      params: <String, dynamic>{'p_session_id': seanceId},
    );
    return <EleveSorti>[
      for (final dynamic ligne in lignes)
        if (ligne is Map<String, dynamic>) EleveSorti.depuisJson(ligne),
    ];
  }
}

/// Le service des gestes employe par l'application.
final Provider<PortGestesSalle> portGestesSalleProvider =
    Provider<PortGestesSalle>(
      (Ref ref) => GestesSalleSupabase(Supabase.instance.client),
    );

/// Les eleves sortis d'une seance, relus apres chaque geste.
final FutureProviderFamily<List<EleveSorti>, String> elevesSortisProvider =
    FutureProvider.family<List<EleveSorti>, String>(
      (Ref ref, String seanceId) =>
          ref.watch(portGestesSalleProvider).sortis(seanceId),
    );
