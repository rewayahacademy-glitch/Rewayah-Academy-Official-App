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
/// direction, K-50 / decisions du 27/09 ; « groupe » : on dit la classe,
/// lib/CLAUDE.md, regle Classe jamais groupe, CLASSE-FORM-1 D10). « foyer »
/// chez la direction se controle a la revue : le mot est legitime cote
/// famille. Un parametre (`{deGroupe}`) n'est pas du texte visible.
final RegExp _motInterne = RegExp(
  r'\b(?:admin|groupes?)\b',
  caseSensitive: false,
);

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
  r'autorisez|acceptez|accordez|rendez-vous|voir |voyez|'
  // LIB-ERR-1 : « vous pouvez les lancer normalement » dit quoi faire.
  r'lancer|lancez|'
  // DASH-ELV-ERR : le tutoiement des ecrans eleve (« Reessaie »).
  r'réessaie|reessaie',
  caseSensitive: false,
);

void main(List<String> arguments) {
  final Set<String> regles = <String>{
    'libelle-sans-source',
    'bouton-grise',
    'bouton-grise-conditionnel',
    'affirmation-reseau',
    'cartes-collees',
    'bouton-recompose',
    'plein-multiple',
    'libelle-ambigu',
    'mot-interne',
    'erreur-sans-action',
    'nav-recomposee',
    'etat-seance-pastille',
    'selecteur-theme-recompose',
    'avatar-recompose',
    'avatar-taille',
    'onglets-defilants',
    'wrap-filtres',
    'case-recomposee',
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
  if (regles.contains('bouton-grise-conditionnel')) {
    violations.addAll(_boutonsGrisesConditionnels());
  }
  if (regles.contains('cartes-collees')) {
    violations.addAll(_cartesCollees());
  }
  if (regles.contains('onglets-defilants')) {
    violations.addAll(_ongletsDefilants());
  }
  if (regles.contains('wrap-filtres')) {
    violations.addAll(_wrapsDeFiltres());
  }
  if (regles.contains('case-recomposee')) {
    violations.addAll(_casesRecomposees());
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
  if (regles.contains('avatar-recompose') || regles.contains('avatar-taille')) {
    final List<Violation> avatars = _avatars();
    violations.addAll(avatars.where((Violation a) => regles.contains(a.regle)));
  }
  if (regles.contains('etat-seance-pastille')) {
    violations.addAll(_pastillesDEtatPosees());
  }
  if (regles.contains('nav-recomposee')) {
    violations.addAll(_navigationsRecomposees());
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
      if (_motInterne.hasMatch(
        e.value
            .replaceAll(RegExp(r'@:[\w.]+'), '')
            .replaceAll(RegExp(r'\{[^}]*\}'), ''),
      )) {
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

  // Les cas hors de l'etape BOUTONS-GRISES-1 (voie TB, communications,
  // finance, comptable, fichiers reserves) sont comptes a part : listes avec
  // --detail, jamais dans le total ni dans le socle.
  final List<Violation> exclus = violations
      .where((Violation v) => v.regle == 'bouton-grise-conditionnel-exclu')
      .toList();
  violations.removeWhere(exclus.contains);
  if (exclus.isNotEmpty) {
    if (detail) {
      exclus.forEach(stdout.writeln);
    }
    stdout.writeln(
      'bouton-grise-conditionnel (exclus, comptes a part) : ${exclus.length}',
    );
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

/// Tout le code de l'application, hors galerie de developpement.
Iterable<File> _sourcesLib() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => !f.path.endsWith('.g.dart'))
        .where((File f) => !f.path.contains('_dev'));

/// Ce qui fait ressembler une rangee de sections a des diapositives : une
/// barre d'onglets qui defile, ou une rangee horizontale qui defile et porte
/// des pastilles, des puces ou des onglets (ONGLETS-1, revue du 01/10 :
/// `SelecteurSection` est le seul composant de changement de section).
final RegExp _barreOnglets = RegExp(
  r'\bTabBar(?:\.secondary)?\s*\(|isScrollable\s*:\s*true',
);

/// Un defilement horizontal.
final RegExp _defilementHorizontal = RegExp(
  r'scrollDirection\s*:\s*(?:vertical\s*\?[^:]+:\s*)?Axis\.horizontal',
);

/// Ce qu'une rangee de sections porte.
final RegExp _contenuSections = RegExp(
  r'\b(?:FilterPill|ChoiceChip|FilterChip|SegmentedButton|ControleSegmente|'
  r'Tab)\s*[(<]',
);

List<Violation> _ongletsDefilants() {
  final List<Violation> v = <Violation>[];
  for (final File f in _sourcesLib()) {
    final String texte = _sansCommentaires(f);
    for (final RegExpMatch m in _barreOnglets.allMatches(texte)) {
      v.add(
        Violation(
          f.path,
          _ligneDe(texte, m.start),
          'onglets-defilants',
          m.group(0)!,
        ),
      );
    }
    for (final RegExpMatch m in _defilementHorizontal.allMatches(texte)) {
      final String fenetre = texte.substring(
        m.end,
        (m.end + 1500).clamp(0, texte.length),
      );
      if (_contenuSections.hasMatch(fenetre)) {
        v.add(
          Violation(
            f.path,
            _ligneDe(texte, m.start),
            'onglets-defilants',
            'rangee horizontale qui defile avec pastilles ou onglets',
          ),
        );
      }
    }
  }
  return v;
}

/// FILTRES-1 (lib/CLAUDE.md) : une rangee de filtres est `RangeeFiltres`,
/// une seule rangee qui defile ; **jamais un `Wrap` de puces de filtre**
/// (deux, trois lignes de puces a 320 px texte x2, la liste repoussee sous
/// le pli). Une puce de filtre : `FilterPill` ou `MenuFiltre`.
final RegExp _puceFiltre = RegExp(r'\b(?:FilterPill|MenuFiltre)\s*[(<]');

/// Un `Wrap` de puces qui n'est pas une rangee de filtres : un **choix de
/// formulaire** (une valeur a saisir dans une feuille ou un formulaire : la
/// portee d'un jeton, le type d'une classe a creer, un niveau). Il se
/// declare par un commentaire sur la ligne qui le precede, ou la raison
/// s'ecrit (FILTRES-1b) : `// Choix de formulaire, pas un filtre : ...`.
final RegExp _marqueChoixFormulaire = RegExp(
  r'//.*choix de formulaire',
  caseSensitive: false,
);

List<Violation> _wrapsDeFiltres() {
  final List<Violation> v = <Violation>[];
  for (final File f in _sourcesLib()) {
    final String texte = _sansCommentaires(f);
    final List<String> brutes = f.readAsLinesSync();
    for (final RegExpMatch m in RegExp(r'\bWrap\s*\(').allMatches(texte)) {
      final int fin = _fermante(texte, m.end - 1);
      if (fin < 0) continue;
      final int ligne = _ligneDe(texte, m.start);
      if (ligne >= 2 && _marqueChoixFormulaire.hasMatch(brutes[ligne - 2])) {
        continue;
      }
      if (_puceFiltre.hasMatch(texte.substring(m.end, fin))) {
        v.add(
          Violation(
            f.path,
            ligne,
            'wrap-filtres',
            'Wrap de puces de filtre : RangeeFiltres (FILTRES-1)',
          ),
        );
      }
    }
  }
  return v;
}

/// LISTES-1 (23/10/2026) : une case a cocher est `CaseACocher`
/// (`lib/core/widgets/case_a_cocher.dart`), jamais un `Checkbox` ou un
/// `CheckboxListTile` de Material recompose dans une fonctionnalite : ils n'ont
/// ni la cible du mode d'interface, ni l'anneau de focus du produit, ni l'etat
/// partiel.
///
/// Exceptions **datees du 23/10/2026** : les sites qui existaient avant la case
/// partagee, non migres (ecrans hors du lot des listes). Le nombre autorise par
/// fichier ne monte jamais ; on retire la ligne quand le site est migre. Un
/// fichier absent de cette liste n'a droit a aucun `Checkbox`.
const Map<String, int> _casesMaterielAutorisees = <String, int>{
  'lib/features/admin_pedagogie_bibliotheque/attribution/attribution_page.dart':
      2,
  'lib/features/admin_pedagogie_bibliotheque/import/import_page.dart': 1,
  'lib/features/admin_pedagogie_bibliotheque/publication/publication_page.dart':
      2,
  // Candidatures : migree dans la PR 50, portee sur main au lot suivant
  // (pilote, 30/10/2026). La ligne part avec ce lot.
  'lib/features/admin_candidatures/ligne_candidature.dart': 1,
  'lib/features/comptable/paiements/ligne_obligation.dart': 1,
  'lib/features/consentements/texte_observation.dart': 1,
  'lib/features/foyer/recharge_foyer.dart': 1,
};

List<Violation> _casesRecomposees() {
  final List<Violation> v = <Violation>[];
  final RegExp materiel = RegExp(r'\b(Checkbox|CheckboxListTile)\s*\(');
  for (final File f in _sourcesFeatures()) {
    final String chemin = f.path.replaceAll('\\', '/');
    final String t = _sansCommentaires(f);
    int rang = 0;
    final int permis = _casesMaterielAutorisees[chemin] ?? 0;
    for (final RegExpMatch m in materiel.allMatches(t)) {
      if (++rang <= permis) {
        continue;
      }
      v.add(
        Violation(
          chemin,
          _ligneDe(t, m.start),
          'case-recomposee',
          '${m.group(1)} de Material : CaseACocher (LISTES-1)',
        ),
      );
    }
  }
  return v;
}

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

/// Les mots d'etat de seance que seule `PastilleEtatSeance` peut poser :
/// « En direct » et « Annulee » (ON-AIR-1, ANNUL-VIS-1).
final RegExp _motEtatSeance = RegExp(
  r'etat\.enDirect|LibellesGroupe\.enDirect|visite\.enDirect|\bv\.enDirect|'
  r'etat\.annule\b|etat\.seanceAnnulee|pastilleAnnulee|barre\.titre',
);

/// ON-AIR-1 et ANNUL-VIS-1 : une `StatusPill` qui porte le mot « En direct »
/// ou « Annulee » est un composant d'etat de seance recompose a la main. Le
/// seul composant autorise est `PastilleEtatSeance` (lib/core/widgets).
List<Violation> _pastillesDEtatPosees() {
  final List<Violation> v = <Violation>[];
  final RegExp debut = RegExp(r'(?<![\w.])StatusPill\s*\(');
  final Iterable<File> sources =
      <Directory>[Directory('lib/features'), Directory('lib/core/widgets')]
          .expand((Directory d) => d.listSync(recursive: true))
          .whereType<File>()
          .where(
            (File f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.contains('_dev') &&
                !f.path.endsWith('pastille_etat_seance.dart'),
          );
  for (final File f in sources) {
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in debut.allMatches(t)) {
      final int ferme = _fermante(t, m.end - 1);
      if (ferme < 0) {
        continue;
      }
      final String appel = t.substring(m.start, ferme + 1);
      if (_motEtatSeance.hasMatch(appel)) {
        v.add(
          Violation(
            f.path,
            _ligneDe(t, m.start),
            'etat-seance-pastille',
            appel.replaceAll(RegExp(r'\s+'), ' '),
          ),
        );
      }
    }
  }
  return v;
}

/// Le motif d'une barre recomposee : le nom du widget, des blancs eventuels
/// (espaces, retour a la ligne), puis `(` ou `.`. Expose pour le test qui
/// prouve la detection (`\s*` lit des blancs, `s*` ne lisait que des « s »).
final RegExp motifNavRecomposee = RegExp(
  r'(NavigationBar|NavigationRail|NavigationDrawer|BottomNavigationBar|'
  r'BottomAppBar|CupertinoTabBar)\s*[(.]',
);

/// MA-NAV-1 : une barre de navigation n'existe que dans les deux coquilles du
/// core (`NavShell`, `AdminShell`), ou le Mode Accessibilite la presente
/// (cibles de 72, libelle visible, etat actif a trois signaux). Une barre
/// recomposee ailleurs ne suivrait pas la presentation.
List<Violation> _navigationsRecomposees() {
  final List<Violation> v = <Violation>[];
  final RegExp nav = motifNavRecomposee;
  for (final File f in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>()) {
    final String chemin = f.path.replaceAll(r'\', '/');
    if (!chemin.endsWith('.dart') ||
        chemin.endsWith('.g.dart') ||
        chemin.contains('_dev') ||
        chemin.endsWith('lib/core/widgets/nav_shell.dart') ||
        chemin.endsWith('lib/core/widgets/admin_shell.dart')) {
      continue;
    }
    final String t = _sansCommentaires(f);
    for (final RegExpMatch m in nav.allMatches(t)) {
      v.add(
        Violation(chemin, _ligneDe(t, m.start), 'nav-recomposee', m.group(0)!),
      );
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

/// BOUTONS-GRISES-1 : les widgets d'action, ceux dont une action nulle rend
/// un bouton inerte (grise). `AppCard`, `SettingRow` sans action sont du
/// contenu, pas un bouton grise ; `BarrePrecedentSuivant` fait disparaitre
/// la fleche au bord (lib/CLAUDE.md, NAV-FLECHES-1) : hors de la liste.
final RegExp _widgetAction = RegExp(
  r'^(?:ActionPrincipale|LienFleche|BoutonIcone|BoutonOutil|CommandeSalle|'
  r'Pressable|FilterPill|FilledButton|TextButton|OutlinedButton|'
  r'ElevatedButton|IconButton|MenuItemButton|FloatingActionButton|'
  // Un bouton prive qui enveloppe l'un d'eux (`_BoutonZoom`, `_Commande`).
  r'_Bouton\w*|_Commande\w*)'
  r'(?:\.\w+)?$',
);

/// Vrai quand l'appel qui porte l'action est fige `enCours: true` : le
/// bouton montre un travail en cours (telechargement), il ne se grise pas.
bool _enCoursFixe(String t, int position) {
  int profondeur = 0;
  for (int i = position - 1; i >= 0; i--) {
    final String c = t[i];
    if (c == ')' || c == ']' || c == '}') {
      profondeur++;
    } else if (c == '(' || c == '[' || c == '{') {
      if (profondeur == 0) {
        final int ferme = _fermante(t, i);
        return ferme > i &&
            RegExp(r'\benCours\s*:\s*true\b').hasMatch(t.substring(i, ferme));
      }
      profondeur--;
    }
  }
  return false;
}

/// Les chemins hors de cette etape (BOUTONS-GRISES-1) : voie TB (salle,
/// dock), communications, finance, comptable, et les
/// fichiers reserves a d'autres sessions. Leurs cas sont comptes a part
/// (`bouton-grise-conditionnel-exclu`), jamais caches.
const List<String> exclusBoutonsConditionnels = <String>[
  'lib/features/salle/',
  // Fiche 1 de la salle au telephone (26/10/2026) : vignette_video.dart,
  // `Pressable onPress: enGrand`. La vignette n'est un Pressable que si
  // `enGrand` existe (`if (enGrand == null) return vignette;`) : dans la
  // capsule du telephone (`touchable: false`), elle est rendue sans
  // Pressable, jamais grisee ; le detecteur lit la condition sans voir ce
  // retour anticipe.
  'lib/features/salle_seance/',
  'lib/features/salle_enseignant/',
  'lib/features/tc_dock/',
  'lib/features/com_',
  'lib/core/communications/',
  'lib/features/admin_finance/',
  'lib/features/acces_finance/',
  'lib/core/finance/',
  'lib/features/comptable/',
  'lib/core/comptable/',
  'lib/core/widgets/comptable/',
  'lib/core/widgets/data_collection.dart',
  'lib/core/widgets/rangee_filtres.dart',
  'lib/core/widgets/admin_shell.dart',
  'lib/core/widgets/pressable.dart',
  'lib/features/tc_espace_groupe/feuille_carte_classe.dart',
  'lib/features/fiche_groupe/fiche_groupe_page.dart',
  'lib/features/admin_regroupements/',
  'lib/features/admin_groupes/groupes_page.dart',
  // K-64 : vitrine et pages publiques, chantier d'une autre session.
  'lib/features/parcours_offres/',
];

/// Une variable d'action posee nulle sous condition, puis passee au bouton
/// (`final VoidCallback? a = pret ? _envoyer : null;` ... `onPress: a`).
final RegExp _variableActionConditionnelle = RegExp(
  r'\b(?:VoidCallback|void\s+Function\([^)]*\)|'
  r'Future<void>\s+Function\([^)]*\))\?\s+(\w+)\s*=\s*([^;]+);',
);

/// Le nom du constructeur dont l'argument commence a [position] : on remonte
/// jusqu'a la parenthese ouvrante non fermee, puis on lit l'identifiant
/// (`FilledButton.tonal`, `ActionPrincipale`).
String _appelantDe(String t, int position) {
  int profondeur = 0;
  for (int i = position - 1; i >= 0; i--) {
    final String c = t[i];
    if (c == ')' || c == ']' || c == '}') {
      profondeur++;
    } else if (c == '[' || c == '{') {
      if (profondeur == 0) {
        return '';
      }
      profondeur--;
    } else if (c == '(') {
      if (profondeur == 0) {
        final RegExpMatch? nom = RegExp(
          r'([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?)\s*(?:<[^()]*>)?\s*$',
        ).firstMatch(t.substring(0, i));
        return nom?.group(1) ?? '';
      }
      profondeur--;
    }
  }
  return '';
}

/// Vrai quand l'expression d'action vaut `null` selon une condition (ou
/// toujours). Le relais d'un composant du core (`actif ? onPress : null`,
/// son propre champ) n'est pas une decision d'ecran : l'ecran appelant est
/// controle a sa place.
bool estActionConditionnelleNulle(String expression, {bool relais = false}) {
  final String e = expression.trim();
  if (e == 'null') {
    return true;
  }
  if (!_estGriseSeul(e)) {
    return false;
  }
  if (relais &&
      RegExp(r'^[^?]+\?\s*(?:widget\.)?on[A-Z]\w*\s*:\s*null$').hasMatch(e)) {
    return false;
  }
  return true;
}

/// Une condition qui ne dit QUE l'envoi deja parti (`_envoi`, `enCours`,
/// `_phase == _Phase.envoi`) : le bouton aboutira, il empeche seulement le
/// double envoi. Ancree : une condition composee (`horsLigne || _envoi`,
/// `_envoi || brouillon.profilCree`) n'est pas exemptee (revue
/// BOUTONS-GRISES-1 : l'ancienne exemption `_envoiEnCours` avalait toute
/// expression qui commencait par l'envoi ou le contenait).
final RegExp _conditionEnvoiSeule = RegExp(
  r'^!?(?:widget\.)?_?\w*(?:enCours|EnCours|envoi|Envoi|chargement)'
  r'(?:\s*[!=]=\s*[\w.]+)?$|'
  r'^_phase == _Phase\.envoi$|^_?\w+ is Decision(?:Verification|Envoi)$',
);

/// La condition d'un ternaire de premier niveau (le texte avant son `?`),
/// ou `null` quand l'expression n'est pas un ternaire.
String? conditionTernaire(String e) {
  int profondeur = 0;
  for (int i = 0; i < e.length; i++) {
    final String c = e[i];
    if (c == '(' || c == '[' || c == '{') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}') {
      profondeur--;
    } else if (c == '?' && profondeur == 0) {
      final String suivant = i + 1 < e.length ? e[i + 1] : '';
      if (suivant == '.') {
        continue;
      }
      if (suivant == '?') {
        i++;
        continue;
      }
      return e.substring(0, i).trim();
    }
  }
  return null;
}

/// Comme [_estGrise], mais n'exempte l'envoi deja parti que lorsqu'il est la
/// seule condition du ternaire.
bool _estGriseSeul(String e) {
  if (e == 'null') {
    return true;
  }
  if (e.startsWith('(') ||
      e.contains('=>') && e.indexOf('=>') < e.indexOf('?')) {
    return false;
  }
  final bool grise =
      RegExp(r'\?\s*null\s*:').hasMatch(e) ||
      RegExp(r':\s*null$').hasMatch(e);
  if (!grise) {
    return false;
  }
  final String? condition = conditionTernaire(e);
  return condition == null ||
      !_conditionEnvoiSeule.hasMatch(
        condition.replaceAll(RegExp(r'\s+'), ' '),
      );
}

/// Les boutons d'action dont `onPress`, `onPressed` ou `onTap` vaut `null`
/// selon l'etat : la vraie forme d'un bouton grise (BOUTONS-GRISES-1). Lit
/// le ternaire passe en argument, le litteral `null` et la variable
/// d'action posee nulle sous condition. Expose pour le test qui prouve la
/// detection (`test/tool/verifier_revue_boutons_test.dart`).
List<Violation> boutonsGrisesConditionnels(
  String chemin,
  String texte, {
  Map<String, Set<String>> relais = const <String, Set<String>>{},
}) {
  final List<Violation> v = <Violation>[];
  final Set<String> variables = <String>{
    for (final RegExpMatch m in _variableActionConditionnelle.allMatches(texte))
      if (estActionConditionnelleNulle(m.group(2)!)) m.group(1)!,
  };
  final bool relaisCore = chemin.contains('lib/core/widgets/');
  final Set<int> vus = <int>{};
  for (final RegExpMatch m in _argumentAction.allMatches(texte)) {
    final String expression = _argument(texte, m.end).trim();
    final bool nulle =
        estActionConditionnelleNulle(expression, relais: relaisCore) ||
        variables.contains(expression);
    if (!nulle) {
      continue;
    }
    final String appelant = _appelantDe(texte, m.start);
    if (!_widgetAction.hasMatch(appelant) || _enCoursFixe(texte, m.start)) {
      continue;
    }
    vus.add(m.start);
    v.add(
      Violation(
        chemin,
        _ligneDe(texte, m.start),
        exclusBoutonsConditionnels.any(chemin.contains)
            ? 'bouton-grise-conditionnel-exclu'
            : 'bouton-grise-conditionnel',
        '$appelant ${m.group(0)} ${expression.replaceAll(RegExp(r'\s+'), ' ')}',
      ),
    );
  }
  // Le relais : la valeur nulle passee a un widget d'ecran qui la remet telle
  // quelle a un widget d'action (`CarteGroupe(onRejoindre: horsLigne ? null
  // : f)`, puis `ActionPrincipale(onPress: onRejoindre)`). La decision est
  // prise ici, chez l'appelant : c'est ici qu'elle est comptee.
  if (relais.isNotEmpty) {
    for (final RegExpMatch m in _argumentRappel.allMatches(texte)) {
      if (vus.contains(m.start)) {
        continue;
      }
      final String appelant = _appelantDe(texte, m.start);
      final Set<String>? champs = relais[appelant];
      if (champs == null || !champs.contains(m.group(1))) {
        continue;
      }
      final String expression = _argument(texte, m.end).trim();
      final bool nulle =
          (estActionConditionnelleNulle(expression) &&
              !_propagationDuNul(expression)) ||
          variables.contains(expression);
      if (!nulle) {
        continue;
      }
      v.add(
        Violation(
          chemin,
          _ligneDe(texte, m.start),
          exclusBoutonsConditionnels.any(chemin.contains)
              ? 'bouton-grise-conditionnel-exclu'
              : 'bouton-grise-conditionnel',
          '$appelant ${m.group(0)} '
          '${expression.replaceAll(RegExp(r'\s+'), ' ')} (relais)',
        ),
      );
    }
  }
  return v;
}

/// Un argument de rappel nomme `onXxx` passe a un widget.
final RegExp _argumentRappel = RegExp(r'(?<![?]\s*)\b(on[A-Z]\w*)\s*:');

/// `rappel == null ? null : () => rappel(x)` : l'appelant adapte la forme du
/// rappel sans rien decider ; le widget relais recoit `null` seulement quand
/// rien n'est branche, et c'est lui qui decide de ne pas rendre le bouton.
bool _propagationDuNul(String e) {
  final RegExpMatch? m = RegExp(
    r'^(?:widget\.)?(\w+)\s*==\s*null\s*\?\s*null\s*:(.*)$',
    dotAll: true,
  ).firstMatch(e);
  return m != null && RegExp('\\b${m.group(1)}\\b').hasMatch(m.group(2)!);
}

/// Les widgets d'ecran (lib/features) qui remettent un de leurs champs de
/// rappel tel quel a un widget d'action (`onPress: onRejoindre`,
/// `onPress: widget.onEntrer`), directement ou par un autre relais. Nom du
/// widget vers ses champs relayes. Les composants de `lib/core/widgets` ne
/// sont pas des relais : ce sont les widgets d'action eux-memes, ou des
/// lignes et cartes sans action (contenu).
Map<String, Set<String>> relaisAction(Map<String, String> sources) {
  final Map<String, Set<String>> relais = <String, Set<String>>{};
  final RegExp champ = RegExp(r'^(?:widget\.)?(on[A-Z]\w*)$');
  bool change = true;
  while (change) {
    change = false;
    sources.forEach((String chemin, String texte) {
      if (!chemin.contains('lib/features/')) {
        return;
      }
      final List<(int, String)> classes = _classesDe(texte);
      for (final RegExpMatch m in _argumentRappel.allMatches(texte)) {
        final RegExpMatch? c = champ.firstMatch(_argument(texte, m.end).trim());
        if (c == null) {
          continue;
        }
        final String appelant = _appelantDe(texte, m.start);
        final bool versAction =
            const <String>{'onPress', 'onPressed', 'onTap'}.contains(
              m.group(1),
            ) &&
            _widgetAction.hasMatch(appelant);
        final bool versRelais =
            relais[appelant]?.contains(m.group(1)) ?? false;
        if (!versAction && !versRelais) {
          continue;
        }
        String? proprietaire;
        int debutClasse = 0;
        int finClasse = texte.length;
        for (final (int debut, String nom) in classes) {
          if (debut > m.start) {
            finClasse = debut;
            break;
          }
          proprietaire = nom;
          debutClasse = debut;
        }
        if (proprietaire == null) {
          continue;
        }
        // Un relais qui ne rend son bouton que si le rappel est branche
        // (`if (onX != null) ActionPrincipale(onPress: onX)`) ne grise rien :
        // nul, le bouton n'est pas rendu.
        if (RegExp(
          '\\b(?:widget\\.)?${c.group(1)}\\s*(?:[!=]=\\s*null|case\\b)',
        ).hasMatch(texte.substring(debutClasse, finClasse))) {
          continue;
        }
        if ((relais[proprietaire] ??= <String>{}).add(c.group(1)!)) {
          change = true;
        }
      }
    });
  }
  return relais;
}

/// Les classes d'un fichier, dans l'ordre : debut et nom du widget qu'elles
/// servent (l'etat `_XState extends State<X>` sert `X`).
List<(int, String)> _classesDe(String texte) => <(int, String)>[
  for (final RegExpMatch m in RegExp(
    r'\bclass\s+(\w+)(?:<[^>{]*>)?\s+extends\s+(?:\w+\.)?(\w+)(?:<\s*(\w+)\s*>)?',
  ).allMatches(texte))
    (
      m.start,
      (m.group(2) == 'State' || m.group(2) == 'ConsumerState') &&
              m.group(3) != null
          ? m.group(3)!
          : m.group(1)!,
    ),
];

List<Violation> _boutonsGrisesConditionnels() {
  final Map<String, String> sources = <String, String>{
    for (final File f in _sourcesLib())
      f.path.replaceAll(r'\', '/'): _sansCommentaires(f),
  };
  final Map<String, Set<String>> relais = relaisAction(sources);
  return <Violation>[
    for (final MapEntry<String, String> s in sources.entries)
      ...boutonsGrisesConditionnels(s.key, s.value, relais: relais),
  ];
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
