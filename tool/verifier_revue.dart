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

import 'revue_cartes.dart';

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

void main(List<String> arguments) {
  final Set<String> regles = <String>{
    'libelle-sans-source',
    'bouton-grise',
    'affirmation-reseau',
    'cartes-collees',
    'bouton-recompose',
    'plein-multiple',
    'libelle-ambigu',
    'mot-interne',
    'erreur-sans-action',
    'selecteur-theme-recompose',
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
  if (regles.contains('selecteur-theme-recompose')) {
    violations.addAll(_selecteursThemeRecomposes());
  }
  if (regles.contains('plein-multiple')) {
    violations.addAll(_pleinsMultiples());
  }
  if (regles.contains('nav-a-libelle')) {
    violations.addAll(_navigationsALibelle());
  }
  if (regles.contains('bascule-sans-etat')) {
    violations.addAll(_basculesSansEtat());
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

/// K-55 : des cartes qui se touchent (detecteur dans `revue_cartes.dart`) :
/// deux cartes voisines, une boucle de cartes, un `ListView.builder` de
/// cartes, une carte derivee, une boite peinte a la main, le tout sans
/// `spacing:` ni separateur. `PileCartes` et `CarteGroupee` sont la parade.
List<Violation> _cartesCollees() => <Violation>[
  for (final CasCollage c in tousLesCas())
    Violation(
      c.chemin.replaceAll(r'\', '/'),
      c.ligne,
      'cartes-collees',
      c.extrait,
    ),
];

/// Les composants du core qui peignent eux-memes leur fond : un `Pressable`
/// qui en contient un n'est pas un bouton recompose.
const String _composantsBouton =
    r'AppCard|ActionPrincipale|BentoTile|ChildCard|LienFleche|FilterPill|'
    r'BoutonOutil|ControleSegmente|ChoiceCardGroup|GroupeReglages|SettingRow|'
    r'StatTile|ScheduleOption|StatusPill';

/// Les gestes qui font d'un `GestureDetector` ou d'un `InkWell` un bouton :
/// un detecteur de glissement (`onPan`, un dessin) n'en est pas un.
final RegExp _gesteBouton = RegExp(
  r'\bon(?:Tap|TapDown|TapUp|DoubleTap|LongPress|SecondaryTap)\s*:',
);

/// K-54 / K-56 : un bouton construit dans un ecran au lieu d'un composant du
/// core. Quatre formes, toutes hors `lib/core` :
///
///  1. un bouton ou une puce Material (`TextButton`, `ChoiceChip`,
///     `PopupMenuButton`, `SegmentedButton`...), `InkWell` ;
///  2. un `GestureDetector` qui reagit au toucher (`onTap`...), le detecteur
///     de glissement d'un dessin n'en est pas un ;
///  3. un `Pressable` qui peint lui-meme une surface (`BoxDecoration`,
///     `.decoration(`, `avecFilet`, `DecoratedBox`, `Material`) autour d'un
///     `Text` ou d'une `Icon`, sans composant du core pour la peindre ;
///  4. un `Pressable` dont l'enfant est un `Text` nu : un lien recompose
///     (`LienFleche` le fait, avec sa cible de 48 et son centrage).
List<Violation> _boutonsRecomposes() {
  final List<Violation> v = <Violation>[];
  final RegExp materiel = RegExp(
    r'\b(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|'
    r'MaterialButton|FloatingActionButton|SegmentedButton|ChoiceChip|'
    r'ActionChip|FilterChip|InputChip|RawChip|PopupMenuButton|DropdownButton|'
    r'InkResponse|InkWell|GestureDetector)\s*[(.<]',
  );
  final RegExp pressable = RegExp(r'\bPressable(?:\.selon)?\s*\(');
  final RegExp surfacePeinte = RegExp(
    r'BoxDecoration\(|\.decoration\(|avecFilet\(|DecoratedBox\(|Material\(|'
    r'ColoredBox\(',
  );
  final RegExp composantCore = RegExp(
    '(?<![\\w.])(?:$_composantsBouton)\\s*\\(',
  );
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in materiel.allMatches(t)) {
      final String nom = m.group(1)!;
      if (nom == 'GestureDetector' ||
          nom == 'InkWell' ||
          nom == 'InkResponse') {
        final int ouvre = t.indexOf('(', m.start);
        final int ferme = _fermante(t, ouvre);
        if (ferme < 0 || !_gesteBouton.hasMatch(t.substring(ouvre, ferme))) {
          continue;
        }
      }
      v.add(Violation(f.path, _ligneDe(t, m.start), 'bouton-recompose', nom));
    }
    int rang = 0;
    for (final RegExpMatch m in pressable.allMatches(t)) {
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String corps = t.substring(m.start, ferme);
      final bool etiquette = corps.contains('Text(') || corps.contains('Icon(');
      final bool peint =
          surfacePeinte.hasMatch(corps) &&
          etiquette &&
          !composantCore.hasMatch(corps);
      final bool lienNu = !peint && _enfantEstTexteNu(corps);
      if (peint || lienNu) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'bouton-recompose',
            peint
                ? 'Pressable avec surface et libelle peints dans l\'ecran '
                      'n°${++rang}'
                : 'Pressable avec texte nu (lien recompose) n°${++rang}',
          ),
        );
      }
    }
  }
  return v;
}

/// THEME-SW-1 : le choix du theme est `SelecteurTheme` (un rectangle, trois
/// bascules soleil, systeme, lune). Un ecran qui recompose le choix en cartes,
/// en lignes radio ou en boutons de son cru est une violation.
List<Violation> _selecteursThemeRecomposes() {
  final List<Violation> v = <Violation>[];
  final RegExp recompose = RegExp(
    r'\b(?:RadioGroup|Radio|SegmentedButton|DropdownButton|'
    r'ControleSegmente)<PreferenceTheme>|'
    r'PreferenceTheme\.values',
  );
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in recompose.allMatches(t)) {
      v.add(
        Violation(
          f.path,
          _ligneDe(t, m.start),
          'selecteur-theme-recompose',
          m.group(0)!,
        ),
      );
    }
  }
  return v;
}

/// K-56 : plus d'un bouton plein (`ActionPrincipale` de niveau `principale`,
/// explicite ou par defaut) dans un meme fichier d'ecran. Un ecran n'a qu'un
/// bouton plein : les autres actions sont des boutons secondaires, tertiaires
/// ou des liens (`LienFleche`).
///
/// **Limite assumee** : le controle lit le texte, pas l'arbre rendu. Deux
/// boutons pleins de branches exclusives (`if / else`, `switch`) ou de feuilles
/// differentes dans un meme fichier sont comptes ensemble : l'existant est fige
/// dans le socle apres revue (la signature porte le nombre, un bouton plein de
/// plus fait echouer). Ce qui se joue a l'ecran, deux boutons pleins
/// visibles ensemble, est mesure par `verifierUnSeulBoutonPlein`
/// (`test/support/garde_interface.dart`).
List<Violation> _pleinsMultiples() {
  final List<Violation> v = <Violation>[];
  final RegExp appel = RegExp(r'(?<![\w.])ActionPrincipale\s*\(');
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    int pleins = 0;
    int? premiere;
    for (final RegExpMatch m in appel.allMatches(t)) {
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String? niveau = _argumentDePremierNiveau(
        t.substring(m.start, ferme + 1),
        'niveau',
      );
      if (niveau == null || niveau.contains('principale')) {
        pleins++;
        premiere ??= _ligneDe(t, m.start);
      }
    }
    if (pleins > 1) {
      v.add(
        Violation(
          f.path,
          premiere!,
          'plein-multiple',
          '$pleins boutons pleins',
        ),
      );
    }
  }
  return v;
}

/// La valeur de l'argument nomme [nom] au premier niveau de l'appel [corps] ;
/// null s'il n'y est pas.
String? _argumentDePremierNiveau(String corps, String nom) {
  final int ouvre = corps.indexOf('(');
  if (ouvre < 0) {
    return null;
  }
  int profondeur = 0;
  for (int i = ouvre; i < corps.length; i++) {
    final String c = corps[i];
    if (c == "'" || c == '"') {
      i = _finChaine(corps, i);
      if (i < 0) {
        return null;
      }
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
    } else if (profondeur == 1 &&
        corps.startsWith('$nom:', i) &&
        RegExp(r'[\s(,]').hasMatch(corps[i - 1])) {
      return _argument(corps, i + nom.length + 1).trim();
    }
  }
  return null;
}

/// Vrai quand l'argument `child:` de premier niveau de l'appel [corps] est un
/// `Text` : un `Pressable` qui ne fait que presenter un mot. Un `Text` cache
/// plus loin dans une ligne n'est pas un lien recompose.
bool _enfantEstTexteNu(String corps) {
  final int ouvre = corps.indexOf('(');
  if (ouvre < 0) {
    return false;
  }
  int profondeur = 0;
  for (int i = ouvre; i < corps.length; i++) {
    final String c = corps[i];
    if (c == "'" || c == '"') {
      i = _finChaine(corps, i);
      if (i < 0) {
        return false;
      }
    } else if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
    } else if (profondeur == 1 &&
        corps.startsWith('child:', i) &&
        RegExp(r'[\s(,]').hasMatch(corps[i - 1])) {
      return RegExp(r'^child:\s*(?:const\s+)?Text\(')
          .hasMatch(corps.substring(i));
    }
  }
  return false;
}

/// NAV-FLECHES-1 : une navigation precedent / suivant faite de boutons a
/// libelle (`ActionPrincipale`) au lieu de `BarrePrecedentSuivant` (fleche,
/// position, fleche, la fleche disparait aux bornes).
List<Violation> _navigationsALibelle() {
  final List<Violation> v = <Violation>[];
  final RegExp appel = RegExp(r'(?<![\w.])ActionPrincipale\s*\(');
  final RegExp libelle = RegExp(
    r'libelle:\s*t\.[\w.]*\b(?:page)?(?:Precedent|Suivant|precedent|suivant)e?\b',
  );
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in appel.allMatches(t)) {
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final RegExpMatch? l = libelle.firstMatch(t.substring(m.start, ferme));
      if (l != null) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'nav-a-libelle',
            'ActionPrincipale ${l.group(0)}',
          ),
        );
      }
    }
    // Toute autre forme (LienFleche, Pressable recompose, Text) : une cle de
    // libelle precedent / suivant hors des deux arguments de
    // BarrePrecedentSuivant, ou la fleche de progression hors du composant.
    for (final RegExpMatch m in _cleNavigation.allMatches(t)) {
      final int debutLigne = t.lastIndexOf('\n', m.start) + 1;
      final String avant = t.substring(debutLigne, m.start);
      if (RegExp(r'libelle(?:Precedent|Suivant)\s*:\s*$').hasMatch(avant) ||
          _navigationsVerifiees.contains(m.group(0))) {
        continue;
      }
      v.add(
        Violation(
          f.path,
          _ligneDe(t, m.start),
          'nav-a-libelle',
          'cle de navigation hors BarrePrecedentSuivant : ${m.group(0)}',
        ),
      );
    }
    for (final RegExpMatch m in RegExp(r'AppIcons\.suivant\b').allMatches(t)) {
      v.add(
        Violation(
          f.path,
          _ligneDe(t, m.start),
          'nav-a-libelle',
          'AppIcons.suivant hors BarrePrecedentSuivant',
        ),
      );
    }
  }
  return v;
}

/// Une cle de libelle dont le nom dit precedent ou suivant.
final RegExp _cleNavigation = RegExp(
  r't\.[A-Za-z0-9_.]*\.\w*(?:[Pp]recedent|[Ss]uivant)\w*',
);

/// Les sites verifies a la main, qui portent le mot suivant ou precedent sans
/// etre une navigation de pages (liste de la fiche REVUE-DIRECTEUR-2026-10.md) :
/// etape de formulaire, pagination de liste, devoir de la seance d'avant.
const Set<String> _navigationsVerifiees = <String>{
  't.foyer.ajout.suivant',
  't.dossiers.file.suivants',
  't.dossiers.file.suivantAnnonce',
  't.dossiers.file.suivantsErreur',
  't.enseignant.cahier.devoirPrecedent',
};

/// ETATS-BTN-1 : une commande de la salle a deux etats (micro, camera,
/// agrandir / reduire, son recu, ou toute icone choisie selon l'etat) doit
/// declarer son etat (`bascule:`), sans quoi le disque plein ou en contour et
/// le mot d'etat ne suivent pas.
List<Violation> _basculesSansEtat() {
  final List<Violation> v = <Violation>[];
  final RegExp appel = RegExp(
    r'(?<![\w.])(?:CommandeSalle|BoutonAppel|_Commande)\s*\(',
  );
  // Une icone de bascule connue, OU toute commande dont l'icone change avec
  // l'etat (`x ? AppIcons.a : AppIcons.b`) : c'est le caractere a deux etats
  // qui compte, pas la liste.
  final RegExp icone = RegExp(
    r'AppIcons\.(?:micro|microCoupe|camera|cameraCoupee|agrandir|reduire|'
    r'libelleAudio)\b'
    r'|\?\s*\(?\s*AppIcons\.\w+\s*\)?(?:\.\w+)?\s*:\s*\(?\s*AppIcons\.\w+',
  );
  for (final File f in _sourcesFeatures()) {
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in appel.allMatches(t)) {
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String corps = t.substring(m.start, ferme);
      if (icone.hasMatch(corps) && !corps.contains('bascule:')) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'bascule-sans-etat',
            'commande a deux etats (micro, camera, agrandir, son) sans bascule:',
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
