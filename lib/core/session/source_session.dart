import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'claims_jwt.dart';
import 'session_state.dart';

/// D'ou vient l'etat de session.
///
/// Une interface, et non un appel direct a Supabase, pour que le routeur et
/// ses tests puissent tourner sans reseau ni backend.
abstract interface class SourceSession {
  /// Les etats de session successifs. Le premier element arrive des que la
  /// session courante est resolue.
  Stream<SessionState> etats();
}

/// La source reelle : Supabase.
class SourceSessionSupabase implements SourceSession {
  /// Cree la source a partir d'un client Supabase.
  SourceSessionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<SessionState> etats() async* {
    yield await _resoudre(_client.auth.currentSession);

    await for (final AuthState evenement in _client.auth.onAuthStateChange) {
      yield await _resoudre(evenement.session);
    }
  }

  Future<SessionState> _resoudre(Session? session) async {
    if (session == null) {
      return const SessionState.deconnecte();
    }

    // Le role et le foyer viennent du jeton, jamais d'une requete : c'est la
    // meme source que celle lue par les policies RLS.
    final ClaimsJwt claims = ClaimsJwt.depuisJeton(session.accessToken);
    final String profileId = session.user.id;

    // Le statut de compte n'est pas dans le jeton (le hook n'injecte que role
    // et household_id) : il demande une lecture, autorisee par la policy
    // `profiles_self_select`.
    final _ProfilLu profil = await _lireProfil(profileId);

    return SessionState(
      resolue: true,
      profileId: profileId,
      role: AppRole.depuisSql(claims.role),
      householdId: claims.householdId,
      accountStatus: profil.statut,
      interfaceMode: profil.mode,
    );
  }

  Future<_ProfilLu> _lireProfil(String profileId) async {
    try {
      final Map<String, dynamic>? ligne = await _client
          .from('profiles')
          .select('account_status, student_profiles(interface_mode)')
          .eq('id', profileId)
          .maybeSingle();

      if (ligne == null) {
        return const _ProfilLu(null, InterfaceMode.standard);
      }

      final Object? eleve = ligne['student_profiles'];
      final String? mode = eleve is Map<String, dynamic>
          ? eleve['interface_mode'] as String?
          : null;

      return _ProfilLu(
        AccountStatus.depuisSql(ligne['account_status'] as String?),
        InterfaceMode.depuisSql(mode),
      );
    } on PostgrestException {
      // Lecture refusee ou indisponible : on ne devine pas un statut. Un
      // statut nul se traite comme une attente cote PorteAcces, donc on ferme
      // plutot que d'ouvrir.
      return const _ProfilLu(null, InterfaceMode.standard);
    }
  }
}

class _ProfilLu {
  const _ProfilLu(this.statut, this.mode);

  final AccountStatus? statut;
  final InterfaceMode mode;
}
