import 'dart:async';

import 'package:flutter/foundation.dart';
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

/// Vrai quand la derniere session a ete terminee parce que le serveur la
/// refusait (souvent : le meme compte, ou un autre, ouvert ailleurs dans ce
/// navigateur ou sur un autre appareil). L'ecran « Se connecter » le dit
/// clairement (demande du directeur du 01/11/2026), puis l'oublie a la
/// connexion suivante.
final ValueNotifier<bool> sessionTermineeParLeServeur = ValueNotifier<bool>(
  false,
);

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
    await _client.auth.refreshSession().timeout(AppDelais.demarrageMax);
  }

  Future<SessionState> _resoudre(
    Session? session, {
    bool reprise = false,
  }) async {
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

    // Session coupee cote serveur (jeton refuse : prod du 01/11/2026, 18:09
    // UTC, rafale de 401 et ecran « La connexion prend plus de temps que
    // prevu » sans issue). On redemande un jeton une fois ; s'il est refuse
    // aussi, la session est finie : deconnexion locale, l'application revient
    // a « Se connecter » au lieu de tourner en rond.
    if (profil.jetonRefuse) {
      if (!reprise) {
        try {
          final AuthResponse r = await _client.auth.refreshSession().timeout(
            AppDelais.demarrageMax,
          );
          if (r.session != null) {
            return await _resoudre(r.session, reprise: true);
          }
        } on Object {
          // Rafraichissement refuse ou sans reponse : la session est finie.
        }
      }
      sessionTermineeParLeServeur.value = true;
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } on Object {
        // La session locale est effacee meme si le serveur ne repond pas.
      }
      return const SessionState.deconnecte();
    }

    final AppRole? role = AppRole.depuisSql(claims.role);
    if (profil.lecture == LectureProfil.presente) {
      sessionTermineeParLeServeur.value = false;
    }

    return SessionState(
      resolue: true,
      profileId: profileId,
      role: role,
      // Le serveur refuse (42501) tout appel du controleur en `aal1` : l'ecran
      // d'enrolement ou de verification est la seule porte ouverte. Faux pour
      // les autres comptes, et pour une session d'observation d'agent.
      mfaRequise:
          role == AppRole.controller && claims.niveauAssurance != 'aal2',
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
          .timeout(AppDelais.demarrageMax);

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
    } on PostgrestException catch (e) {
      if (jetonRefuse(e)) {
        return const _ProfilLu(
          null,
          InterfaceMode.standard,
          LectureProfil.echouee,
          jetonRefuse: true,
        );
      }
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
  const _ProfilLu(
    this.statut,
    this.mode,
    this.lecture, {
    this.jetonRefuse = false,
  });

  final AccountStatus? statut;
  final InterfaceMode mode;
  final LectureProfil lecture;

  /// Le serveur a refuse le jeton lui-meme (expire, revoque, invalide).
  final bool jetonRefuse;
}

/// Vrai quand PostgREST refuse le JETON (et non la lecture) : JWT expire,
/// invalide ou revoque (codes PGRST301 a PGRST303, statut 401). Une policy
/// qui refuse une ligne rend 42501 ou 403 : ce n'est pas une fin de session.
bool jetonRefuse(PostgrestException e) {
  final String code = e.code ?? '';
  if (code == 'PGRST301' || code == 'PGRST302' || code == 'PGRST303') {
    return true;
  }
  final String texte = '${e.message} ${e.details ?? ''}'.toLowerCase();
  return texte.contains('jwt') &&
      (texte.contains('expired') || texte.contains('invalid'));
}

/// La session que le serveur refuse : un nouveau jeton une fois, sinon fin de
/// session locale. `onAuthStateChange` publie alors la deconnexion et le
/// routeur ramene a « Se connecter » (prod du 01/11/2026 : 401 en boucle).
Future<void> terminerSessionRefusee() async {
  final GoTrueClient auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) return;
  try {
    final AuthResponse r = await auth.refreshSession().timeout(
      AppDelais.demarrageMax,
    );
    if (r.session != null) return;
  } on Object {
    // Rafraichissement refuse ou sans reponse : la session est finie.
  }
  sessionTermineeParLeServeur.value = true;
  try {
    await auth.signOut(scope: SignOutScope.local);
  } on Object {
    // La session locale est effacee meme si le serveur ne repond pas.
  }
}
