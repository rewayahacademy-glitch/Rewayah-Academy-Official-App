// FN-111 (parcours 3, piege 3.1, 31/10/2026) : un lien de connexion ouvert
// sur un autre appareil, ou dans un autre navigateur, que celui ou il a ete
// demande arrivait sur « Se connecter » sans un mot.
//
// Le lien porte un code a usage unique (`?code=`, flux PKCE). Le client ne
// l'echange contre une session qu'avec la cle de verification posee, au
// moment de la demande, dans le stockage du navigateur qui a demande le lien.
// Ailleurs, la cle manque : l'echange echoue avant tout appel au serveur
// (`Code verifier could not be found in local storage`), l'adresse garde son
// `?code=`, et l'erreur part sur un flux que personne n'ecoute encore.
//
// On le dit donc depuis ce qui reste visible : un code dans l'adresse, sans
// cle de verification sur cet appareil, et aucune session ouverte (la page de
// connexion ne s'affiche que sans session).

import '../inscription/questionnaire/memoire_appareil.dart';

/// La cle sous laquelle le client d'authentification range la cle de
/// verification du flux PKCE sur le web : `supabase.auth.token-code-verifier`
/// (gotrue 2.x), prefixee `flutter.` par le stockage des preferences.
const String clefVerificateurLien = 'flutter.supabase.auth.token-code-verifier';

/// Les parametres d'un retour en echec, deja traites par la recuperation.
const Set<String> _parametresEchec = <String>{
  'error',
  'error_code',
  'error_description',
};

/// Vrai quand [adresse] porte un code de lien de connexion que cet appareil
/// ne peut pas echanger : aucune cle de verification ([verificateur] nul ou
/// vide). Fonction pure.
///
/// L'invitation d'un enseignant (`?mode=creer&invitation=1&code=...`) porte
/// aussi un `code` : c'est le code de l'invitation, jamais un lien de
/// connexion. Un retour en echec (`error=`) est dit par la recuperation.
bool lienOuvertAilleurs(Uri adresse, {required String? verificateur}) {
  final Map<String, String> champs = adresse.queryParameters;
  final String? code = champs['code'];
  if (code == null || code.trim().isEmpty) {
    return false;
  }
  if (champs.containsKey('invitation') ||
      champs.keys.any(_parametresEchec.contains)) {
    return false;
  }
  return verificateur == null || verificateur.trim().isEmpty;
}

/// [lienOuvertAilleurs] sur la memoire de cet appareil.
bool lienOuvertAilleursIci(Uri adresse) => lienOuvertAilleurs(
  adresse,
  verificateur: lireMemoireAppareil(clefVerificateurLien),
);
