import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../agent/session_agent.dart';
import '../domain/enums.dart';
import 'claims_jwt.dart';
import 'session_state.dart';
import 'source_session.dart';

/// La source de session d'une **observation** par un agent IA (ADR-025).
///
/// Elle remplace [SourceSessionSupabase] et ne touche jamais a
/// `client.auth` : une session d'agent n'est pas une session gotrue. Il n'y a
/// ni connexion, ni deconnexion, ni flux d'evenements d'authentification --
/// seulement un jeton signe, renouvele par le porteur tant que le jeton
/// d'observation vit.
///
/// Tout ce qu'elle produit vient du jeton lui-meme, exactement comme pour une
/// session humaine : le role et le foyer sont les claims que lisent les
/// policies, et `sub` est **la personne observee**. C'est ce qui fait que le
/// routeur envoie l'agent sur l'accueil du bon parcours sans qu'une seule ligne
/// de navigation soit ecrite pour lui.
class SourceSessionAgent implements SourceSession {
  /// Cree la source a partir du porteur et du client deja initialise.
  SourceSessionAgent(this._porteur, this._client);

  final PorteurSessionAgent _porteur;
  final SupabaseClient _client;

  @override
  Stream<SessionState> etats() async* {
    yield await _resoudre();
  }

  @override
  Future<void> rafraichir() async {
    // Rien a rafraichir : le porteur redemande un jeton de lui-meme des que
    // l'actuel approche de son terme. Et un agent ne cree pas de profil, donc
    // le cas qui justifie `rafraichir()` pour un humain -- le role absent du
    // jeton juste apres l'inscription -- ne peut pas se produire ici.
  }

  Future<SessionState> _resoudre() async {
    final RemiseAgent? remise = _porteur.derniere;
    if (remise == null || !remise.valideA(DateTime.now())) {
      return const SessionState.deconnecte();
    }

    final ClaimsJwt claims = ClaimsJwt.depuisJeton(remise.jetonAcces);
    final String? profileId = claims.sujet;
    if (profileId == null || profileId.isEmpty) {
      return const SessionState.deconnecte();
    }

    final _ProfilObserve profil = await _lireProfil(profileId);

    return SessionState(
      resolue: true,
      profileId: profileId,
      role: AppRole.depuisSql(claims.role),
      householdId: claims.householdId,
      accountStatus: profil.statut,
      interfaceMode: profil.mode,
      lectureProfil: profil.lecture,
      observation: Observation(
        identiteMasquee: remise.identiteMasquee,
        jetonExpireLe: remise.jetonExpireLe,
      ),
    );
  }

  /// La seule ligne de `profiles` qu'un agent masquant peut lire : celle de la
  /// personne observee (policy `profiles_agent_select` de `0014`).
  Future<_ProfilObserve> _lireProfil(String profileId) async {
    try {
      final Map<String, dynamic>? ligne = await _client
          .from('profiles')
          // Cle nommee : deux cles relient student_profiles a profiles (0052).
          .select(
            'account_status, '
            'student_profiles!student_profiles_profile_id_fkey(interface_mode)',
          )
          .eq('id', profileId)
          .maybeSingle();

      if (ligne == null) {
        return const _ProfilObserve(
          null,
          InterfaceMode.standard,
          LectureProfil.echouee,
        );
      }

      final Object? eleve = ligne['student_profiles'];
      final String? mode = eleve is Map<String, dynamic>
          ? eleve['interface_mode'] as String?
          : null;

      return _ProfilObserve(
        AccountStatus.depuisSql(ligne['account_status'] as String?),
        InterfaceMode.depuisSql(mode),
        LectureProfil.presente,
      );
    } on Object {
      // Meme regle que pour une session humaine : on ne devine pas. Une lecture
      // refusee ou tombee ferme, elle n'ouvre rien. Un jeton revoque entre le
      // demarrage et cette requete passe precisement par ici.
      return const _ProfilObserve(
        null,
        InterfaceMode.standard,
        LectureProfil.echouee,
      );
    }
  }
}

class _ProfilObserve {
  const _ProfilObserve(this.statut, this.mode, this.lecture);

  final AccountStatus? statut;
  final InterfaceMode mode;
  final LectureProfil lecture;
}
