// ENTREE-ORDRE (PLAN-LOTS rang 22 0, constat du directeur du 05/11/2026) :
// pour un nouveau profil, le questionnaire passe avant l'adresse e-mail et la
// connexion.
//
// Le site public envoie « S'inscrire », « Commencer mon inscription » et
// « Se connecter » au meme `/connexion` nu (`site-public/build_site.py`,
// `APP_LINKS`) : l'application decide seule. Un visiteur dont l'appareil n'a
// jamais connu de compte arrive sur le questionnaire ; quelqu'un qui revient
// garde la connexion :
// - l'appareil a deja ouvert une session (repere [clefCompteConnu]) ;
// - « J'ai deja un compte » (`?mode=connexion`, [adresseConnexionDemandee]) ;
// - un lien de connexion recu par e-mail (code ou jeton dans l'adresse) ;
// - toute adresse qui porte un contexte (`retour=`, invitation, code).
//
// Aucun ecran nouveau : le questionnaire (`/commencer`) et la connexion
// existent ; seul l'ordre est retabli.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/routes.dart';
import '../../core/session/session_state.dart';
import '../inscription/questionnaire/memoire_appareil.dart';

/// La clef du repere « un compte a deja ouvert une session sur cet appareil »
/// dans la memoire de l'appareil (`localStorage` sur le web).
const String clefCompteConnu = 'rewayah.entree.compte_connu';

/// La valeur du parametre `mode` qui dit « j'ai deja un compte » : la
/// connexion s'ouvre, meme sur un appareil neuf.
const String parametreModeConnexion = 'connexion';

/// L'adresse de la connexion demandee expressement (« J'ai deja un compte »).
String get adresseConnexionDemandee => Uri(
  path: Routes.connexion,
  queryParameters: <String, String>{'mode': parametreModeConnexion},
).toString();

/// Les parametres qu'un lien de connexion recu par e-mail ou un retour de
/// Google pose dans l'adresse (flux PKCE : `code` ; lien a jeton :
/// `token_hash` ; echec : `error`). Dans le fragment (`#access_token=`) pour
/// le flux implicite.
const Set<String> _parametresLien = <String>{
  'code',
  'token_hash',
  'error',
  'error_code',
  'error_description',
};

/// Vrai quand [adresse] (l'adresse d'ouverture de l'application, `Uri.base`
/// sur le web) porte un lien de connexion : la connexion se garde, meme sur un
/// appareil qui n'a jamais connu de compte. Fonction pure.
bool lienDeConnexionDansAdresse(Uri adresse) {
  if (adresse.queryParameters.keys.any(_parametresLien.contains)) {
    return true;
  }
  final String fragment = adresse.fragment;
  return fragment.contains('access_token=') ||
      fragment.contains('error_description=');
}

/// Ou mene `/connexion` ouverte sans contexte : au questionnaire quand
/// l'appareil ne connait aucun compte et qu'aucun lien de connexion n'est en
/// cours ; sinon nulle part (la connexion reste). Fonction pure.
///
/// Une adresse qui porte un parametre (`mode=connexion`, `retour=`,
/// `invitation`, `code`...) garde toujours la connexion : elle vient d'un
/// geste precis, jamais d'un visiteur nouveau. `mode=creer` est decide avant,
/// par `redirectionCreationCompte`.
String? redirectionVisiteurNouveau(
  Uri adresse, {
  required bool compteConnu,
  required bool lienRecu,
}) {
  if (compteConnu || lienRecu || adresse.queryParameters.isNotEmpty) {
    return null;
  }
  return Routes.commencer;
}

/// Le repere « compte connu » de cet appareil.
class CompteConnu extends Notifier<bool> {
  @override
  bool build() => lireMemoireAppareil(clefCompteConnu) != null;

  /// Une session vient de s'ouvrir sur cet appareil : la prochaine entree
  /// garde la connexion. Rien a faire si le repere est deja pose.
  void retenir() {
    if (state) {
      return;
    }
    ecrireMemoireAppareil(clefCompteConnu, '1');
    state = true;
  }
}

/// Vrai quand cet appareil a deja ouvert une session ([CompteConnu]).
final NotifierProvider<CompteConnu, bool> compteConnuProvider =
    NotifierProvider<CompteConnu, bool>(CompteConnu.new);

/// Vrai quand l'application s'est ouverte sur un lien de connexion
/// ([lienDeConnexionDansAdresse] sur `Uri.base`). Lu une fois : l'adresse
/// d'ouverture ne change pas pendant la vie de l'application.
final Provider<bool> lienRecuProvider = Provider<bool>(
  (Ref ref) => lienDeConnexionDansAdresse(Uri.base),
);

/// Les portes d'une session ouverte (un compte existe, quel que soit son
/// etat) : l'appareil connait desormais un compte.
const Set<PorteAcces> _portesAvecCompte = <PorteAcces>{
  PorteAcces.inscription,
  PorteAcces.attente,
  PorteAcces.suspendu,
  PorteAcces.actif,
};

/// Pose le repere « compte connu » quand [session] porte un compte. Appele a
/// chaque changement de session, par le routeur.
void retenirCompteSiSession(Ref ref, SessionState session) {
  if (_portesAvecCompte.contains(session.porte)) {
    ref.read(compteConnuProvider.notifier).retenir();
  }
}
