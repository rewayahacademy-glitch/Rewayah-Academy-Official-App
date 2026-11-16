/// L'adresse ou le lien de connexion (courriel ou Google) ramene la personne,
/// avec la marque de ce qu'elle venait faire (POSTULER-ICI, directeur,
/// 16/11/2026).
///
/// **Pourquoi.** Le courriel d'invitation d'un candidat mene a
/// `/connexion?mode=creer&candidature=1`. La marque « je viens postuler » est
/// gardee dans la memoire de l'appareil ; or le lien de connexion s'ouvre
/// souvent dans un autre navigateur, une autre application ou un autre
/// appareil, ou cette memoire est vide : la personne tombait sur « Pour qui
/// creez-vous ce compte ? » sans chemin evident vers l'enseignement. La marque
/// voyage donc aussi dans l'adresse de retour.
///
/// - Sans marque dans l'adresse courante : l'origine seule, comme avant.
/// - `candidature=1` et `invitation=1` sont gardes tels quels.
/// - Le code d'une invitation d'enseignant voyage sous `code_invitation`, **pas
///   sous `code`** : le flux PKCE de Supabase ajoute son propre `code` a
///   l'adresse de retour.
/// - Rien d'autre ne voyage : ni adresse de courriel, ni nom.
library;

/// Le parametre qui porte le code d'une invitation d'enseignant au retour.
const String parametreCodeInvitationRetour = 'code_invitation';

/// L'adresse de retour pour la page courante [courante] (parametres lus dans
/// la requete et dans celle du fragment, car l'application route sur
/// `/#/...`), ou `null` hors du web. [origine] est l'origine servie.
String? adresseRetourConnexion({
  required Uri courante,
  required String? origine,
}) {
  if (origine == null) return null;
  final Map<String, String> p = <String, String>{
    ...courante.queryParameters,
    ...?Uri.tryParse(courante.fragment)?.queryParameters,
  };
  final Map<String, String> marque = <String, String>{
    if (p['candidature'] == '1') 'candidature': '1',
    if (p['invitation'] == '1') ...<String, String>{
      'invitation': '1',
      if (_codePlausible(p['code']) case final String c)
        parametreCodeInvitationRetour: c,
    },
  };
  if (marque.isEmpty) return origine;
  return Uri.parse(origine)
      .replace(path: '/', queryParameters: marque)
      .toString();
}

/// Un code plausible (lettres, chiffres, espaces, tirets ; 20 signes au plus).
String? _codePlausible(String? brut) {
  if (brut == null) return null;
  final String c = brut.trim();
  if (c.isEmpty || c.length > 20) return null;
  return RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(c) ? c : null;
}
