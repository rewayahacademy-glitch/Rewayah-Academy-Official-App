// PE-A8 (parcours de l'enseignant, 20/11/2026 ; retours terrain R25) : « Vouliez-vous dire gmail.com ? ».
//
// Des dizaines d'invitations ne sont jamais arrivees : l'adresse avait ete
// tapee avec une faute dans le domaine (gmail.coma, gamil.com, gmail.co,
// geml.com...). Cette fonction **propose** le domaine courant le plus proche
// d'un domaine mal ecrit ; elle ne corrige jamais rien d'elle-meme. L'ecran
// montre la proposition, la personne l'accepte d'un toucher ou l'ignore, et
// l'envoi n'est jamais bloque.
//
// Une seule fonction pour toute l'application (formulaire du candidat,
// connexion, fin du questionnaire des familles) : `PropositionCourriel`
// (`lib/core/widgets/proposition_courriel.dart`) l'affiche.
//
// Ce qu'elle ne fait pas : elle ne dit pas qu'une adresse existe, elle ne
// valide pas la forme de l'adresse (le serveur le fait), et elle ne propose
// rien pour un domaine qu'elle connait deja (tres courant ou reel connu), ni
// pour un domaine trop eloigne des dix domaines tres courants (une adresse
// d'universite ou d'entreprise reste telle quelle). En cas de doute, rien.
library;

/// Les domaines tres courants, les SEULS que l'on propose, dans l'ordre de
/// preference en cas d'egalite (le plus repandu chez les candidats d'abord).
/// Une faute sur un autre domaine (msn.com, gmx.fr...) ne recoit aucune
/// proposition : en cas de doute, rien (pilote, 20/11/2026, relecture de la
/// PR 660).
const List<String> domainesProposes = <String>[
  'gmail.com',
  'yahoo.com',
  'hotmail.com',
  'outlook.com',
  'icloud.com',
  'yahoo.fr',
  'hotmail.fr',
  'outlook.fr',
  'live.com',
  'live.fr',
];

/// Des domaines REELS, proches d'un domaine tres courant ou d'usage courant :
/// tapes tels quels, ils ne recoivent jamais de proposition (« email.com »
/// n'est pas une faute de « gmail.com », ni « mtn.com » de « msn.com »).
/// Avec [domainesProposes], ce sont les domaines connus.
const Set<String> domainesReels = <String>{
  'email.com',
  'mail.com',
  'ymail.com',
  'rocketmail.com',
  'googlemail.com',
  'gmx.com',
  'gmx.net',
  'gmx.fr',
  'gmx.de',
  'me.com',
  'mac.com',
  'msn.com',
  'aol.com',
  'aim.com',
  'cloud.com',
  'mtn.com',
  'gail.com',
  'inbox.com',
  'usa.com',
  'post.com',
  'myself.com',
  'consultant.com',
  'gmail.ru',
  'mail.ru',
  'yandex.com',
  'yandex.ru',
  'proton.me',
  'protonmail.com',
  'orange.fr',
  'free.fr',
  'sfr.fr',
  'laposte.net',
  'wanadoo.fr',
  'hotmail.co.uk',
  'yahoo.co.uk',
  'live.co.uk',
};

/// L'adresse corrigee que l'on propose pour [adresse], ou `null` quand il n'y
/// a rien a proposer : adresse sans « @ », domaine connu ([domainesProposes],
/// [domainesReels]), domaine qui n'est pas a une ou deux fautes d'un domaine
/// tres courant. La partie avant « @ » n'est jamais touchee ; seul le
/// domaine change.
///
/// Exemples : `ali@gmial.com` -> `ali@gmail.com` ; `ali@gmail.con` ->
/// `ali@gmail.com` ; `ali@hotmial.com` -> `ali@hotmail.com` ;
/// `ali@yaho.com` -> `ali@yahoo.com` ; `ali@gmail` -> `ali@gmail.com` ;
/// `ali@gmail.com` -> `null` ; `ali@email.com` -> `null` ;
/// `ali@univ-paris.fr` -> `null`.
String? proposerCourriel(String adresse) {
  final String saisie = adresse.trim();
  final int arobase = saisie.lastIndexOf('@');
  if (arobase <= 0 || arobase == saisie.length - 1) {
    return null;
  }
  final String local = saisie.substring(0, arobase);
  final String domaine = saisie.substring(arobase + 1).toLowerCase();
  if (domaine.length < 2 || domaine.contains(' ') || local.contains('@')) {
    return null;
  }
  if (domainesProposes.contains(domaine) || domainesReels.contains(domaine)) {
    return null;
  }
  // Sans extension (« gmail ») : le domaine tres courant de ce nom.
  if (!domaine.contains('.')) {
    for (final String candidat in domainesProposes) {
      if (_nom(candidat) == domaine) return '$local@$candidat';
    }
  }
  String? meilleur;
  int distanceMeilleure = 1 << 30;
  for (final String candidat in domainesProposes) {
    // Meme nom, autre extension de pays bien formee (« orange.sn »,
    // « yahoo.co.jp », « outlook.sa ») : un vrai domaine, pas une faute.
    // Une seule faute dans l'extension (« gmail.con », « yahoo.fe ») reste
    // proposee.
    if (domaine.contains('.') &&
        _nom(domaine) == _nom(candidat) &&
        distanceDomaines(_extension(domaine), _extension(candidat)) > 1) {
      continue;
    }
    final int d = distanceDomaines(domaine, candidat);
    if (d < distanceMeilleure) {
      distanceMeilleure = d;
      meilleur = candidat;
    }
  }
  if (meilleur == null || distanceMeilleure > _seuil(meilleur)) {
    return null;
  }
  return '$local@$meilleur';
}

/// Ce qui precede le dernier point (« yahoo.co » pour « yahoo.co.uk »).
String _nom(String domaine) {
  final int i = domaine.lastIndexOf('.');
  return i < 0 ? domaine : domaine.substring(0, i);
}

/// Ce qui suit le dernier point (« uk » pour « yahoo.co.uk »).
String _extension(String domaine) {
  final int i = domaine.lastIndexOf('.');
  return i < 0 ? '' : domaine.substring(i + 1);
}

/// La distance acceptee pour proposer [domaine] : deux fautes pour un domaine
/// long (« gamil.coma »), une seule pour un domaine court (« gmx.fr »), pour
/// ne pas confondre deux vrais domaines courts.
int _seuil(String domaine) => domaine.length >= 9 ? 2 : 1;

/// La distance d'edition entre deux domaines (insertion, suppression,
/// substitution, et inversion de deux lettres voisines : « gmial » est a une
/// faute de « gmail »).
int distanceDomaines(String a, String b) {
  final int n = a.length;
  final int m = b.length;
  final List<List<int>> d = List<List<int>>.generate(
    n + 1,
    (int i) => List<int>.filled(m + 1, 0),
  );
  for (int i = 0; i <= n; i++) {
    d[i][0] = i;
  }
  for (int j = 0; j <= m; j++) {
    d[0][j] = j;
  }
  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      final int cout = a[i - 1] == b[j - 1] ? 0 : 1;
      int v = d[i - 1][j] + 1;
      if (d[i][j - 1] + 1 < v) v = d[i][j - 1] + 1;
      if (d[i - 1][j - 1] + cout < v) v = d[i - 1][j - 1] + cout;
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          d[i - 2][j - 2] + 1 < v) {
        v = d[i - 2][j - 2] + 1;
      }
      d[i][j] = v;
    }
  }
  return d[n][m];
}
