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

void main(List<String> arguments) {
  final Set<String> regles = <String>{
    'libelle-sans-source',
    'bouton-grise',
    'affirmation-reseau',
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
  if (regles.contains('bouton-grise')) {
    violations.addAll(_boutonsGrises());
  }

  if (arguments.contains('--ecrire-socle')) {
    File(_fichierSocleRevue).writeAsStringSync(
      '${(violations.map(_signature).toSet().toList()..sort()).join('\n')}\n',
    );
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
