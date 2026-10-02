// Controles des defauts que chaque revue du 27/09/2026 a retrouves, dans
// toutes les vagues : libelle sans source, bouton grise au lieu d'etre retire,
// message d'echec reseau qui affirme ce que l'app ne sait pas.
//
// Usage : dart run tool/verifier_revue.dart [--regle=nom,...] [--detail]
//         [--corpus=dossier]  (documents hors depot, repetable)
//         [--ecrire-socle]    (sur main seulement : fige l'existant)
//
// Sans --regle, toutes les regles tournent. Le code de sortie vaut 1 des
// qu'une violation est trouvee, comme verifier_jetons.
//
// Ce qui ne se voit pas ici reste a la revue : un libelle dont la source est
// une planche (image) ou une decision orale doit etre declare dans
// tool/libelles_sources.json, avec sa reference.
import 'dart:convert';
import 'dart:io';

/// Une violation : ou, quelle regle, quoi.
class Violation {
  /// Cree une violation.
  Violation(this.chemin, this.ligne, this.regle, this.extrait);

  /// Le fichier, relatif a la racine.
  final String chemin;

  /// La ligne (1 pour une cle i18n : la cle suffit a la retrouver).
  final int ligne;

  /// Le nom de la regle.
  final String regle;

  /// Ce qui a ete trouve.
  final String extrait;

  @override
  String toString() => '  $chemin:$ligne  [$regle]  ${extrait.trim()}';
}

const String _fichierFr = 'assets/i18n/fr.i18n.json';

/// Les libelles dont la source n'est pas un document du depot : planche,
/// decision du directeur, lexique valide. `{"cle.complete": "reference"}`.
const String _fichierSources = 'tool/libelles_sources.json';

/// Un bouton rendu grise : `onPress: null` ou une branche `null` d'un
/// ternaire (lib/CLAUDE.md : un bouton qui ne peut pas aboutir n'est pas
/// rendu, une phrase explique la limite).
final RegExp _argumentAction = RegExp(
  r'(?<![?]\s*)\bon(?:Press|Pressed|Tap)\s*:',
);

/// Une action coupee le temps d'un envoi deja parti : le bouton aboutira, il
/// empeche seulement le double envoi. Ce n'est pas le defaut vise.
final RegExp _envoiEnCours = RegExp(
  r'^!?_?(?:enCours|envoi|envoiEnCours|chargement|retraitEnCours)\b|'
  r'_phase == _Phase\.envoi|is Decision(?:Verification|Envoi)',
);

/// Les violations deja presentes dans `main` au 22/09/2026 (4a7aa2b), une par
/// ligne (`regle|fichier|extrait`) : elles precedent la regle et ne sont pas
/// rouvertes (decision du 26/09 : pas de marche arriere avant HU-1).
const String _fichierSocleRevue = 'tool/revue_socle.txt';

/// Un echec reseau qui affirme un non-envoi : apres une coupure, la reponse
/// a pu se perdre, l'app ne sait pas si l'action a eu lieu (revues CT-4, EA-6).
final RegExp _affirmationReseau = RegExp(
  r"n'a pas (?:été|pu être) (?:envoyé|annulé|transmis|enregistré)e?s?|"
  r"n'est pas partie?|n'ont pas été (?:envoyé|transmis)e?s?",
  caseSensitive: false,
);

/// Les libelles qui, seuls, ne disent ni qui ni quoi (revue du 01/10 :
/// « Cahier », « Objectif », « Declarer une absence » sans dire de qui).
/// Compares au texte entier, normalise : « Cahier de seance » passe.
const Set<String> _libellesAmbigus = <String>{
  'cahier',
  'objectif',
  'objectifs',
  'absence',
  'absences',
  'declarer une absence',
  'déclarer une absence',
  'signaler une absence',
};

/// Un mot interne qu'un client ne doit jamais voir (« admin » : on dit la
/// direction, K-50 / decisions du 27/09). « foyer » chez la direction se
/// controle a la revue : le mot est legitime cote famille.
final RegExp _motInterne = RegExp(r'\badmin\b', caseSensitive: false);

/// Une cle de message d'erreur : un segment commence par `erreur`.
final RegExp _cleErreur = RegExp(r'(?:^|\.)erreur\w*(?:\.|$)');

/// Une phrase qui dit quoi faire (K-59) : un verbe d'action de l'utilisateur.
final RegExp _phraseAction = RegExp(
  r'réessay|reessay|ressay|contact|vérifi|verifi|reconnect|reprenez|'
  r'continu|patient|attend|appuy|touch|revenez|relanc|actualis|écriv|ecriv|'
  r'ouvr|choisi|saisi|remplis|ajout|connect|retent|recharg|revoy|joignez|'
  r'cliquez|essayez|renvoy|prévenez|prevenez|signalez|consultez|passez|'
  r'demandez|recommenc|reprendre|plus tard|indiquez|entrez|renseignez|'
  r'précisez|precisez|sélectionnez|selectionnez|corrigez|activez|'
  r'autorisez|acceptez|accordez|rendez-vous|voir |voyez',
  caseSensitive: false,
);

/// Les cartes du core : deux appels voisins sans espace entre eux sont des
/// cartes collees (K-55).
const String _cartes = r'AppCard|BentoTile|ChildCard|StatTile';

void main(List<String> arguments) {
  final Set<String> regles = <String>{
    'libelle-sans-source',
    'bouton-grise',
    'affirmation-reseau',
    'cartes-collees',
    'bouton-recompose',
    'libelle-ambigu',
    'mot-interne',
    'erreur-sans-action',
    'avatar-recompose',
    'avatar-taille',
  };
  final String? filtre = arguments
      .where((String a) => a.startsWith('--regle='))
      .map((String a) => a.substring('--regle='.length))
      .firstOrNull;
  if (filtre != null) {
    regles.retainAll(filtre.split(','));
  }
  final bool detail = arguments.contains('--detail');

  final List<Violation> violations = <Violation>[];
  final Map<String, String> fr = _aplatir(
    jsonDecode(File(_fichierFr).readAsStringSync()) as Map<String, dynamic>,
  );

  if (regles.contains('libelle-sans-source')) {
    violations.addAll(
      _libellesSansSource(
        fr,
        arguments
            .where((String a) => a.startsWith('--corpus='))
            .map((String a) => a.substring('--corpus='.length))
            .toList(),
      ),
    );
  }
  if (regles.contains('affirmation-reseau')) {
    for (final MapEntry<String, String> e in fr.entries) {
      if (_affirmationReseau.hasMatch(e.value)) {
        violations.add(
          Violation(
            _fichierFr,
            1,
            'affirmation-reseau',
            '${e.key} : ${e.value}',
          ),
        );
      }
    }
  }
  // `bouton-desactive` est le nom du directeur (K-56) : meme controle.
  if (regles.contains('bouton-grise') ||
      (filtre?.split(',').contains('bouton-desactive') ?? false)) {
    violations.addAll(_boutonsGrises());
  }
  if (regles.contains('cartes-collees')) {
    violations.addAll(_cartesCollees());
  }
  if (regles.contains('bouton-recompose')) {
    violations.addAll(_boutonsRecomposes());
  }
  if (regles.contains('avatar-recompose') || regles.contains('avatar-taille')) {
    final List<Violation> avatars = _avatars();
    violations.addAll(avatars.where((Violation a) => regles.contains(a.regle)));
  }
  if (regles.contains('libelle-ambigu')) {
    for (final MapEntry<String, String> e in fr.entries) {
      if (_libellesAmbigus.contains(_normaliser(e.value).trim())) {
        violations.add(
          Violation(_fichierFr, 1, 'libelle-ambigu', '${e.key} : ${e.value}'),
        );
      }
    }
  }
  if (regles.contains('mot-interne')) {
    for (final MapEntry<String, String> e in fr.entries) {
      // Un renvoi slang `@:admin.x` n'est pas du texte visible.
      if (_motInterne.hasMatch(e.value.replaceAll(RegExp(r'@:[\w.]+'), ''))) {
        violations.add(
          Violation(_fichierFr, 1, 'mot-interne', '${e.key} : ${e.value}'),
        );
      }
    }
  }
  if (regles.contains('erreur-sans-action')) {
    for (final MapEntry<String, String> e in fr.entries) {
      // Un titre ou le libelle du bouton d'action ne portent pas la phrase.
      if (_cleErreur.hasMatch(e.key) &&
          !RegExp(r'(?:titre|action)$', caseSensitive: false).hasMatch(e.key) &&
          !_phraseAction.hasMatch(e.value)) {
        violations.add(
          Violation(
            _fichierFr,
            1,
            'erreur-sans-action',
            '${e.key} : ${e.value}',
          ),
        );
      }
    }
  }

  if (arguments.contains('--ecrire-socle')) {
    // Le socle ne change que pour les regles lancees : les autres gardent
    // leurs lignes (`--regle=cartes-collees --ecrire-socle` ne touche pas
    // au socle de `libelle-sans-source`).
    final File socle = File(_fichierSocleRevue);
    final Set<String> lignes = <String>{
      if (socle.existsSync())
        ...socle.readAsLinesSync().where(
          (String l) => l.isNotEmpty && !regles.contains(l.split('|').first),
        ),
      ...violations.map(_signature),
    };
    socle.writeAsStringSync('${(lignes.toList()..sort()).join('\n')}\n');
    stdout.writeln('Socle ecrit : ${violations.length} violation(s).');
    return;
  }
  final File socleRevue = File(_fichierSocleRevue);
  if (socleRevue.existsSync()) {
    final Set<String> connues = socleRevue.readAsLinesSync().toSet();
    violations.removeWhere((Violation v) => connues.contains(_signature(v)));
  }

  final Map<String, int> parRegle = <String, int>{};
  for (final Violation v in violations) {
    parRegle[v.regle] = (parRegle[v.regle] ?? 0) + 1;
  }
  if (violations.isEmpty) {
    stdout.writeln('Revue verifiee : aucune violation (${regles.join(', ')}).');
    return;
  }
  if (detail) {
    violations.forEach(stdout.writeln);
  }
  for (final MapEntry<String, int> e in parRegle.entries) {
    stdout.writeln('${e.key} : ${e.value}');
  }
  stdout.writeln('${violations.length} violation(s)');
  exitCode = 1;
}

/// Une cle dont le texte n'apparait dans aucun
/// document du depot et qui n'est pas declaree dans les sources.
///
/// [corpus] ajoute des dossiers de documents (les documents du directeur,
/// hors du depot) a `docs/`.
List<Violation> _libellesSansSource(
  Map<String, String> fr,
  List<String> corpus,
) {
  final File sources = File(_fichierSources);
  final Set<String> declarees = sources.existsSync()
      ? (jsonDecode(sources.readAsStringSync()) as Map<String, dynamic>).keys
            .toSet()
      : <String>{};
  final String textes = _normaliser(
    <String>['docs', ...corpus]
        .expand((String d) => Directory(d).listSync(recursive: true))
        .whereType<File>()
        .where((File f) => f.path.endsWith('.md'))
        .map((File f) => f.readAsStringSync())
        .join('\n'),
  );

  final List<Violation> v = <Violation>[];
  for (final MapEntry<String, String> e in fr.entries) {
    if (declarees.contains(e.key)) {
      continue;
    }
    // Les morceaux fixes du texte, sans les parametres : chacun doit se lire
    // dans un document. Un texte fait seulement de parametres passe.
    final List<String> morceaux = _normaliser(e.value)
        .split(RegExp(r'\{[^}]*\}|\$\w+'))
        .map((String m) => m.trim())
        .where((String m) => m.length >= 3)
        .toList();
    if (morceaux.isNotEmpty && !morceaux.every(textes.contains)) {
      v.add(
        Violation(
          _fichierFr,
          1,
          'libelle-sans-source',
          '${e.key} : ${e.value}',
        ),
      );
    }
  }
  return v;
}

List<Violation> _boutonsGrises() {
  final List<Violation> v = <Violation>[];
  final Iterable<File> sources = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.endsWith('.g.dart'));
  for (final File f in sources) {
    final String texte = f
        .readAsLinesSync()
        .map((String l) => l.replaceFirst(RegExp(r'//.*$'), ''))
        .join('\n');
    for (final RegExpMatch m in _argumentAction.allMatches(texte)) {
      final String expression = _argument(texte, m.end).trim();
      if (_estGrise(expression)) {
        final int ligne = '\n'.allMatches(texte.substring(0, m.start)).length;
        v.add(
          Violation(
            f.path,
            ligne + 1,
            'bouton-grise',
            '${m.group(0)} ${expression.replaceAll(RegExp(r'\s+'), ' ')}',
          ),
        );
      }
    }
  }
  return v;
}

Iterable<File> _sourcesFeatures() =>
    Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => !f.path.endsWith('.g.dart'))
        .where((File f) => !f.path.contains('_dev'));

String _sansCommentaires(File f) => f
    .readAsLinesSync()
    .map((String l) => l.replaceFirst(RegExp(r'(?<!:)//.*$'), ''))
    .join('\n');

int _ligneDe(String texte, int index) =>
    '\n'.allMatches(texte.substring(0, index)).length + 1;

/// L'index de la parenthese fermante qui correspond a l'ouvrante a [debut].
/// Les chaines simples sont sautees ; -1 si le fichier est mal equilibre.
int _fermante(String t, int debut) {
  int profondeur = 0;
  for (int i = debut; i < t.length; i++) {
    final String c = t[i];
    if (c == "'" || c == '"') {
      i = _finChaine(t, i);
      if (i < 0) {
        return -1;
      }
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
      if (profondeur == 0) {
        return i;
      }
    }
  }
  return -1;
}

int _finChaine(String t, int debut) {
  final String q = t[debut];
  for (int i = debut + 1; i < t.length; i++) {
    if (t[i] == r'\') {
      i++;
    } else if (t[i] == q || t[i] == '\n') {
      return i;
    }
  }
  return -1;
}

/// L'index de la parenthese ouvrante de l'appel qui contient [index] (on
/// saute les crochets et accolades : `Column(children: [ ... ])`).
int _appelParent(String t, int index) {
  int profondeur = 0;
  for (int i = index - 1; i >= 0; i--) {
    final String c = t[i];
    if (c == ')' || c == ']' || c == '}') {
      profondeur++;
    } else if (c == '(' || c == '[' || c == '{') {
      if (profondeur > 0) {
        profondeur--;
      } else if (c == '(') {
        return i;
      }
    }
  }
  return -1;
}

/// K-55 : deux cartes du core consecutives, sans rien entre elles (ni
/// `Ecart`, ni `SizedBox`, ni separateur), dans un parent sans `spacing:`.
/// Un `GroupeReglages` ou une carte unique a lignes fines reste permis.
List<Violation> _cartesCollees() {
  final List<Violation> v = <Violation>[];
  final RegExp debut = RegExp('(?<![\\w.])(?:$_cartes)\\s*\\(');
  final RegExp suite = RegExp('^\\s*,\\s*(?:const\\s+)?(?:$_cartes)\\s*\\(');
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    int rang = 0;
    for (final RegExpMatch m in debut.allMatches(t)) {
      final int ouvre = m.end - 1;
      final int ferme = _fermante(t, ouvre);
      if (ferme < 0 || !suite.hasMatch(t.substring(ferme + 1))) {
        continue;
      }
      final int parent = _appelParent(t, m.start);
      final int finParent = parent < 0 ? -1 : _fermante(t, parent);
      if (finParent > 0 &&
          t.substring(parent, finParent).contains('spacing:')) {
        continue;
      }
      v.add(
        Violation(
          f.path,
          _ligneDe(t, m.start),
          'cartes-collees',
          // L'ordre dans le fichier distingue les cas : la signature du
          // socle ne contient pas la ligne.
          '${t.substring(m.start, ouvre).trim()} n°${++rang}',
        ),
      );
    }
  }
  return v;
}

/// K-54 / K-56 : un bouton construit dans un ecran au lieu d'un composant du
/// core : un bouton Material, ou un `Pressable` qui peint lui-meme un fond
/// arrondi autour d'un `Text`, hors `AppCard` et `ActionPrincipale`.
List<Violation> _boutonsRecomposes() {
  final List<Violation> v = <Violation>[];
  final RegExp materiel = RegExp(
    r'\b(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|'
    r'MaterialButton|InkWell|GestureDetector)\s*[(.]',
  );
  final RegExp pressable = RegExp(r'\bPressable(?:\.selon)?\s*\(');
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in materiel.allMatches(t)) {
      v.add(
        Violation(
          f.path,
          _ligneDe(t, m.start),
          'bouton-recompose',
          m.group(1)!,
        ),
      );
    }
    for (final RegExpMatch m in pressable.allMatches(t)) {
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String corps = t.substring(m.start, ferme);
      if (corps.contains('BoxDecoration(') &&
          corps.contains('borderRadius') &&
          corps.contains('Text(') &&
          !corps.contains('AppCard(') &&
          !corps.contains('ActionPrincipale(')) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'bouton-recompose',
            'Pressable avec fond et libelle peints dans l\'ecran',
          ),
        );
      }
    }
  }
  return v;
}

/// Les composants qui peignent un avatar : seul `AvatarNom` les pose a cote
/// d'un nom (AVATAR-1).
final RegExp _appelAvatar = RegExp(
  r'(?<![\w.])(AvatarTile|PhotoEleve|PhotoEnseignant)\s*\(',
);

/// Les enveloppes qui ne changent ni l'axe ni le texte : on les traverse pour
/// trouver la rangee ou la colonne qui porte l'avatar.
const Set<String> _enveloppesAvatar = <String>{
  'Expanded',
  'Flexible',
  'Padding',
  'ExcludeSemantics',
  'Semantics',
  'MergeSemantics',
  'Center',
  'Align',
  'SizedBox',
  'ConstrainedBox',
};

/// Une taille d'avatar hors jetons : un nombre, un produit, la cible tactile
/// ou une valeur d'espacement. Les jetons sont `AppAvatar.*` et
/// `SelecteurProfils.diametre*` ; un parametre transmis tel quel reste permis.
final RegExp _tailleHorsJeton = RegExp(
  r'^(?:\d+(?:\.\d+)?|.*\*.*|.*cibleTactile.*|AppSpacing\..*|AppTouchTarget\..*)$',
);

/// Le nom de l'appel dont l'ouvrante est a [ouvre] (« Row » pour `Row(`).
String _nomAppel(String t, int ouvre) {
  int i = ouvre - 1;
  while (i >= 0 && RegExp(r'\s').hasMatch(t[i])) {
    i--;
  }
  final int fin = i + 1;
  while (i >= 0 && RegExp(r'[\w.]').hasMatch(t[i])) {
    i--;
  }
  return t.substring(i + 1, fin);
}

/// AVATAR-1 : `avatar-recompose` : un avatar pose dans une `Row`, `Column` ou
/// `Wrap` qui contient aussi un `Text` (un couple avatar + nom recompose dans
/// l'ecran, a la main) ; `avatar-taille` : un diametre qui ne vient pas des
/// jetons `AppAvatar`.
List<Violation> _avatars() {
  final List<Violation> v = <Violation>[];
  final List<File> fichiers = <File>[
    ..._sourcesFeatures(),
    ...Directory('lib/core/widgets')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart')),
  ];
  for (final File f in fichiers) {
    final String chemin = f.path.replaceAll('\\', '/');
    // Le composant lui-meme, et la tuile qu'il pose.
    if (chemin.endsWith('core/widgets/avatar_nom.dart') ||
        chemin.endsWith('core/widgets/avatar_tile.dart')) {
      continue;
    }
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in _appelAvatar.allMatches(t)) {
      final int ouvre = m.end - 1;
      final int ferme = _fermante(t, ouvre);
      if (ferme < 0) {
        continue;
      }
      // La definition d'un composant (`const PhotoEleve({`) n'est pas un appel.
      if (t[ouvre + 1] == '{') {
        continue;
      }
      final String corps = t.substring(ouvre, ferme);
      final RegExpMatch? d = RegExp(
        r'diametre\s*:\s*([^,)]+(?:\([^)]*\))?[^,)]*)',
      ).firstMatch(corps);
      if (d != null && _tailleHorsJeton.hasMatch(d.group(1)!.trim())) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'avatar-taille',
            '${m.group(1)} diametre: ${d.group(1)!.trim()}',
          ),
        );
      }
      int courant = m.start;
      for (int montee = 0; montee < 6; montee++) {
        final int parent = _appelParent(t, courant);
        if (parent < 0) {
          break;
        }
        final String nom = _nomAppel(t, parent);
        if (_enveloppesAvatar.contains(nom)) {
          courant = parent;
          continue;
        }
        if (nom == 'Row' ||
            nom == 'Column' ||
            nom == 'Wrap' ||
            nom == 'Stack') {
          final int finParent = _fermante(t, parent);
          if (finParent > 0) {
            final String autour =
                t.substring(parent, m.start) + t.substring(ferme, finParent);
            if (RegExp(r'\bText\s*\(').hasMatch(autour)) {
              v.add(
                Violation(
                  f.path,
                  _ligneDe(t, m.start),
                  'avatar-recompose',
                  '${m.group(1)} a cote d\'un Text dans un $nom : AvatarNom',
                ),
              );
            }
          }
        }
        break;
      }
    }

    // Un cercle d'initiales recompose a la main : un `BoxShape.circle` dont le
    // sous-arbre pose des initiales (hors composants de l'avatar).
    for (final RegExpMatch m in RegExp(r'BoxShape.circle').allMatches(t)) {
      final int parent = _appelParent(t, m.start);
      if (parent < 0) {
        continue;
      }
      final int finParent = _fermante(t, parent);
      if (finParent < 0) {
        continue;
      }
      final String nom = _nomAppel(t, parent);
      if (nom != 'BoxDecoration') {
        continue;
      }
      final int boite = _appelParent(t, parent);
      final int finBoite = boite < 0 ? -1 : _fermante(t, boite);
      if (finBoite > 0 &&
          RegExp(
            r'initiale',
            caseSensitive: false,
          ).hasMatch(t.substring(boite, finBoite))) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'avatar-recompose',
            'cercle d initiales recompose : AvatarTile ou AvatarNom',
          ),
        );
      }
    }
  }
  return v;
}

/// L'argument d'une action, jusqu'a la virgule ou la parenthese qui le ferme.
String _argument(String texte, int debut) {
  int profondeur = 0;
  for (int i = debut; i < texte.length; i++) {
    final String c = texte[i];
    if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (profondeur == 0) {
        return texte.substring(debut, i);
      }
      profondeur--;
    } else if (c == ',' && profondeur == 0) {
      return texte.substring(debut, i);
    }
  }
  return texte.substring(debut);
}

/// Vrai quand l'action peut valoir `null` : litteral, ou branche d'un
/// ternaire de premier niveau (pas celui d'une fermeture).
bool _estGrise(String e) {
  if (e == 'null') {
    return true;
  }
  if (_envoiEnCours.hasMatch(e)) {
    return false;
  }
  if (e.startsWith('(') ||
      e.contains('=>') && e.indexOf('=>') < e.indexOf('?')) {
    return false;
  }
  return RegExp(r'\?\s*null\s*:').hasMatch(e) ||
      RegExp(r':\s*null$').hasMatch(e);
}

/// Ce qui identifie une violation d'une version a l'autre, sans le numero
/// de ligne, qui bouge a chaque modification du fichier.
String _signature(Violation v) =>
    '${v.regle}|${v.chemin}|${v.extrait.replaceAll(RegExp(r'\s+'), ' ').trim()}';

Map<String, String> _aplatir(Map<String, dynamic> m, [String prefixe = '']) {
  final Map<String, String> r = <String, String>{};
  m.forEach((String k, dynamic valeur) {
    final String cle = prefixe.isEmpty ? k : '$prefixe.$k';
    if (valeur is Map<String, dynamic>) {
      r.addAll(_aplatir(valeur, cle));
    } else if (valeur is String) {
      r[cle] = valeur;
    }
  });
  return r;
}

String _normaliser(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[’‘`]'), "'")
    .replaceAll(RegExp('[«»“”]'), '"')
    .replaceAll(RegExp(r'[  ‑]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ');
