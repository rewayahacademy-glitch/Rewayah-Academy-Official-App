import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'video_session_provider.dart';

/// La politique de camera d'un eleve, relue pendant la seance.
///
/// K4 n° 13 (pilote, 30/10/2026) : le jeton LiveKit d'un eleve fige
/// `can_publish_video` a l'entree, d'apres `student_profiles.camera_policy`.
/// Quand le tuteur ouvre (ou ferme) la camera pendant la seance, le jeton ne
/// suit pas : l'image de l'eleve ne part jamais, ou continue de partir. La
/// salle relit donc la politique et, si elle ne correspond plus au jeton,
/// redemande un jeton a `create-room-token` (la base reste seule juge).
abstract interface class PolitiqueCamera {
  /// Vrai si la politique de [eleveId] autorise la camera, faux sinon ;
  /// `null` quand elle n'a pas pu etre lue.
  Future<bool?> cameraAutorisee(String eleveId);
}

/// La lecture reelle, sous RLS (`student_profiles_family` : le foyer).
class PolitiqueCameraSupabase implements PolitiqueCamera {
  /// Cree la lecture.
  const PolitiqueCameraSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<bool?> cameraAutorisee(String eleveId) async {
    final Map<String, dynamic>? ligne = await _client
        .from('student_profiles')
        .select('camera_policy')
        .eq('profile_id', eleveId)
        .maybeSingle();
    if (ligne == null) return null;
    return ligne['camera_policy'] == 'allowed';
  }
}

/// La lecture employee par l'application.
final Provider<PolitiqueCamera> politiqueCameraProvider =
    Provider<PolitiqueCamera>(
      (Ref ref) => PolitiqueCameraSupabase(Supabase.instance.client),
    );

/// L'intervalle de relecture de la politique, pendant la seance.
const Duration intervallePolitiqueCamera = Duration(seconds: 30);

/// Vrai quand le jeton [acces] d'un eleve ne correspond plus a la politique
/// lue : il faut un nouveau jeton. Une politique illisible ne change rien.
bool jetonCameraPerime(AccesSalle acces, {required bool? cameraAutorisee}) =>
    acces.role == 'student' &&
    cameraAutorisee != null &&
    cameraAutorisee != acces.capacites.peutPublierVideo;
