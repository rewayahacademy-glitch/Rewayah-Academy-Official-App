import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../theme/app_delais.dart';
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

  /// Redemande un jeton d'acces, et donc un nouvel etat.
  ///
  /// Necessaire juste apres la creation du profil : le role et le foyer sont
  /// injectes dans le jeton par le hook de la base, donc le jeton emis avant la
  /// creation ne les porte pas encore. Sans ce rafraichissement, un compte tout
  /// juste inscrit resterait sans role jusqu'a sa prochaine connexion.
  Future<void> rafraichir();
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

  @override
  Future<void> rafraichir() async {
    if (_client.auth.currentSession == null) {
      return;
    }
    await _client.auth.refreshSession();
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
      lectureProfil: profil.lecture,
    );
  }

  Future<_ProfilLu> _lireProfil(String profileId) async {
    try {
      // Borne : sans elle, une requete sans reponse laissait l'ecran de
      // demarrage indefiniment (C01 section 4).
      final Map<String, dynamic>? ligne = await _client
          .from('profiles')
          // La cle est nommee : student_profiles porte deux cles vers profiles
          // (profile_id et titulaire_profile_id, 0052) et un embed sans nom
          // echoue en PGRST201, ce qui fermait tout compte sur le portail.
          .select(
            'account_status, '
            'student_profiles!student_profiles_profile_id_fkey(interface_mode)',
          )
          .eq('id', profileId)
          .maybeSingle()
          .timeout(AppDelais.requeteMax);

      // Aucune ligne, mais la requete a abouti : le compte existe et son profil
      // reste a creer. C'est une inscription a terminer, pas un dossier a
      // attendre.
      if (ligne == null) {
        return const _ProfilLu(
          null,
          InterfaceMode.standard,
          LectureProfil.absente,
        );
      }

      final Object? eleve = ligne['student_profiles'];
      final String? mode = eleve is Map<String, dynamic>
          ? eleve['interface_mode'] as String?
          : null;

      return _ProfilLu(
        AccountStatus.depuisSql(ligne['account_status'] as String?),
        InterfaceMode.depuisSql(mode),
        LectureProfil.presente,
      );
    } on PostgrestException {
      // Lecture refusee ou indisponible. **Ne se confond pas avec l'absence** :
      // un echec ferme sur le portail d'attente, une absence ouvre
      // l'inscription. Les melanger laisserait un compte suspendu s'en
      // refabriquer un.
      return const _ProfilLu(
        null,
        InterfaceMode.standard,
        LectureProfil.echouee,
      );
    } on TypeError {
      // Une ligne illisible : le serveur a repondu, autrement qu'attendu.
      return const _ProfilLu(
        null,
        InterfaceMode.standard,
        LectureProfil.echouee,
      );
    } on Object {
      // Aucune reponse exploitable du serveur : reseau coupe, delai depasse,
      // transport en echec. On ferme aussi, mais sur l'etat hors ligne, qui
      // n'ouvre rien et le dit (mandat Tuteur V1 section 8, X21).
      return const _ProfilLu(
        null,
        InterfaceMode.standard,
        LectureProfil.injoignable,
      );
    }
  }
}

class _ProfilLu {
  const _ProfilLu(this.statut, this.mode, this.lecture);

  final AccountStatus? statut;
  final InterfaceMode mode;
  final LectureProfil lecture;
}
