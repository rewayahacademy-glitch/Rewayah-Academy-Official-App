import 'routes.dart';

/// Les destinations qu'un parametre `retour` ne designe jamais.
///
/// La salle et la classe ne s'ouvrent que par un billet ephemere (ADR-005) :
/// y revenir par une URL rejouerait une entree que le serveur n'a pas
/// accordee. L'entree d'agent porte un jeton dans son URL : la designer comme
/// retour ferait circuler ce jeton dans un second parametre.
const Set<String> _destinationsInterdites = <String>{
  Routes.salle,
  // L'ancienne classe n'a plus de route ; son adresse reste refusee comme
  // retour, par prudence.
  '/tc/classe',
  Routes.agentEntree,
};

/// Au-dela, une chaine n'est pas un chemin de l'application : c'est une charge.
const int _longueurMax = 1024;

/// Le chemin interne autorise comme destination de retour, sinon `null`.
///
/// **Une barriere d'entree, pas une commodite.** Un `retour` arrive d'une URL,
/// donc de n'importe qui : accepter tel quel ce qu'il contient ouvrirait une
/// redirection vers un site tiers apres connexion. Le chemin retenu doit :
///
/// - commencer par un seul `/` (`//hote` et `/\hote` sont des adresses
///   externes pour un navigateur) ;
/// - n'avoir ni schema, ni hote, ni fragment, ni caractere de controle ;
/// - n'avoir aucun segment `.` ou `..`, ni segment vide, ni `/` encode dans un
///   segment (`%2F`), qui changeraient la destination apres decodage ;
/// - ne designer ni la salle, ni la classe, ni l'entree d'agent, quelle que
///   soit la casse ou l'encodage.
///
/// Le chemin rendu est la chaine recue, inchangee. Il ne vaut **aucune
/// autorisation** : la redirection du routeur et la RLS decident ensuite si la
/// personne peut y aller.
String? cheminRetourValide(String? brut) {
  if (brut == null || brut.isEmpty || brut.length > _longueurMax) {
    return null;
  }
  if (!brut.startsWith('/') || brut.startsWith('//') || brut.contains(r'\')) {
    return null;
  }
  if (brut.codeUnits.any((int c) => c <= 0x20 || c == 0x7f)) {
    return null;
  }

  final Uri? uri = Uri.tryParse(brut);
  if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
    return null;
  }

  // Les segments se lisent sur la chaine BRUTE, pas sur `uri.pathSegments` :
  // `Uri.parse` retire deja les `.` et les `..`, et un `/tuteur/../x` passerait
  // pour `/x` ici tout en arrivant tel quel au routeur.
  final String cheminBrut = brut.split('?').first;
  final List<String> segments = <String>[];
  if (cheminBrut != '/') {
    for (final String brutDeSegment in cheminBrut.substring(1).split('/')) {
      final String segment;
      try {
        segment = Uri.decodeComponent(brutDeSegment);
      } on FormatException {
        // Un encodage invalide (`%ff` isole) ne se devine pas.
        return null;
      } on ArgumentError {
        return null;
      }
      if (segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.contains('/') ||
          segment.contains(r'\')) {
        return null;
      }
      segments.add(segment);
    }
  }

  final String chemin = '/${segments.join('/')}'.toLowerCase();
  for (final String interdite in _destinationsInterdites) {
    if (chemin == interdite || chemin.startsWith('$interdite/')) {
      return null;
    }
  }
  return brut;
}
