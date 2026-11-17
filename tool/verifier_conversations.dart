// Verificateur des conversations (CONVERSATIONS-PARTOUT, directeur,
// 16/11/2026 : « avoir toujours une vision globale » ; un changement sur un
// ecran ne doit plus casser les autres, et aucune entree ne doit etre oubliee).
//
// Ce que le script fait :
//   1. il LISTE, par recherche dans lib/, chaque fichier qui utilise un
//      composant de conversation (voir [composants]) ; le releve est genere,
//      jamais ecrit de memoire ;
//   2. il echoue (code 1) si l'un de ces fichiers n'a pas sa ligne dans
//      docs/current/MESSAGERIE-MATRICE.md (une ligne de tableau dont la
//      premiere cellule est le chemin entre apostrophes inverses), ou si la
//      matrice nomme un fichier qui n'existe plus ou n'utilise plus aucun
//      composant : la matrice est toujours le releve de ce qui existe ;
//   3. il echoue si un ecran recompose un en-tete de conversation au lieu du
//      composant partage (voir [regles]), hors de la liste toleree
//      tool/conversations_tolerees.txt, qui ne fait que retrecir : une ligne
//      qui ne correspond plus a aucune violation doit etre retiree dans la
//      meme PR.
//
// Dart pur, aucune dependance (pubspec.yaml appartient au directeur).
//
// Lancement : dart run tool/verifier_conversations.dart
//             dart run tool/verifier_conversations.dart --lister

import 'dart:io';

const String fichierMatrice = 'docs/current/MESSAGERIE-MATRICE.md';
const String fichierTolere = 'tool/conversations_tolerees.txt';

/// Les composants qui affichent ou ouvrent une conversation. Toute utilisation
/// (hors commentaire) place le fichier dans la matrice.
const List<String> composants = <String>[
  'FilDiscussion',
  'FilContextuel',
  'FilEnPlace',
  'VoletConversation',
  'ouvrirFeuilleConversation',
  'EntreeMessagesContexte',
  'EntreeMessagesCandidature',
  'PageConversationPleinEcran',
  'BarreConversation',
  'BarreRetourConversation',
  'EnteteFilContexte',
  'LigneConversation',
  'ListeFils',
  'LigneFil',
  'EspaceMessagesMetier',
  'MessagesPage',
  'MessagesAdminPage',
];

/// Les dossiers du composant partage : seuls autorises a poser l'en-tete et le
/// fil eux-memes.
const List<String> dossiersPartages = <String>[
  'lib/core/widgets/',
  'lib/features/com_messages/',
];

/// Outils de developpement, absents de l'application de production.
const List<String> outilsDeveloppement = <String>[
  'lib/features/demo/',
  'lib/features/_dev/',
];

bool estPartage(String chemin) => dossiersPartages.any(chemin.startsWith);
bool estOutil(String chemin) => outilsDeveloppement.any(chemin.startsWith);

/// Une regle de recomposition : [id], ce qu'elle cherche, pourquoi.
class Regle {
  const Regle(this.id, this.motif, this.pourquoi, {this.avec});

  final String id;
  final RegExp motif;
  final String pourquoi;

  /// Le fichier doit AUSSI utiliser un composant de conversation.
  final bool? avec;
}

final List<Regle> regles = <Regle>[
  Regle(
    'entete-recompose',
    RegExp(
      r'\bTetePanneau\(|AppBottomSheet\.ouvrirLecture\(|'
      r'titre:\s*[\w.]*conversationAvec\(',
    ),
    'un titre de panneau ou de feuille empile au-dessus du fil ; l\'en-tete '
        'est la barre compacte du composant partage (BarreConversation)',
    avec: true,
  ),
  Regle(
    'barre-recomposee',
    RegExp(
      r'\bBarreConversation\(|\bEnteteFilContexte\.|\bEnteteFilContexte\(',
    ),
    'une barre ou un en-tete de conversation construit hors du composant '
        'partage',
  ),
  Regle(
    'fil-pose-a-la-main',
    RegExp(r'\bFilDiscussion\('),
    'le fil est pose directement, sans passer par FilContextuel ou FilEnPlace '
        '(donc sans la barre, les marges et les images du composant partage)',
  ),
];

/// Le texte de [source] sans ses commentaires `//` et `/* */`.
String sansCommentaires(String source) {
  final String bloc = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return bloc
      .split('\n')
      .map((String l) {
        final int i = l.indexOf('//');
        // Une adresse (`https://`) n'est pas un commentaire.
        if (i < 0 || (i > 0 && l[i - 1] == ':')) return l;
        return l.substring(0, i);
      })
      .join('\n');
}

/// Les fichiers de lib/ qui utilisent un composant de conversation, avec les
/// composants trouves.
Map<String, List<String>> releve(String racine) {
  final Map<String, List<String>> r = <String, List<String>>{};
  final Directory lib = Directory('$racine/lib');
  if (!lib.existsSync()) return r;
  final List<File> fichiers = <File>[
    for (final FileSystemEntity e in lib.listSync(recursive: true))
      if (e is File && e.path.endsWith('.dart') && !e.path.endsWith('.g.dart'))
        e,
  ]..sort((File a, File b) => a.path.compareTo(b.path));
  for (final File f in fichiers) {
    final String chemin = f.path
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp('^${RegExp.escape(racine)}/'), '');
    final String texte = sansCommentaires(f.readAsStringSync());
    final List<String> trouves = <String>[
      for (final String c in composants)
        if (RegExp('\\b${RegExp.escape(c)}\\b').hasMatch(texte)) c,
    ];
    if (trouves.isNotEmpty) r[chemin] = trouves;
  }
  return r;
}

/// Les chemins nommes par la matrice : premiere cellule d'une ligne de tableau.
Set<String> lireMatrice(String racine) {
  final File f = File('$racine/$fichierMatrice');
  if (!f.existsSync()) return <String>{};
  final RegExp ligne = RegExp(r'^\|\s*`(lib/[^`\s]+\.dart)`\s*\|');
  return <String>{
    for (final String l in f.readAsLinesSync())
      if (ligne.firstMatch(l) case final RegExpMatch m) m.group(1)!,
  };
}

/// Une ligne de tolerance : `chemin | regle | raison`.
Map<String, String> lireTolerees(String racine) {
  final File f = File('$racine/$fichierTolere');
  final Map<String, String> t = <String, String>{};
  if (!f.existsSync()) return t;
  for (final String l in f.readAsLinesSync()) {
    final String net = l.trim();
    if (net.isEmpty || net.startsWith('#')) continue;
    final List<String> p = net.split('|').map((String s) => s.trim()).toList();
    if (p.length >= 3 && p[2].isNotEmpty) t['${p[0]}|${p[1]}'] = p[2];
  }
  return t;
}

/// Toutes les violations ; liste vide : tout est en regle.
List<String> verifier({String racine = '.'}) {
  final List<String> erreurs = <String>[];
  final Map<String, List<String>> usages = releve(racine);
  final Set<String> matrice = lireMatrice(racine);
  final Map<String, String> tolerees = lireTolerees(racine);

  if (!File('$racine/$fichierMatrice').existsSync()) {
    erreurs.add('$fichierMatrice est absente : la matrice est obligatoire');
  }
  // 1. Chaque usage a sa ligne.
  for (final String f in usages.keys) {
    if (!matrice.contains(f)) {
      erreurs.add(
        '$f utilise ${usages[f]!.join(', ')} mais n\'est pas dans '
        '$fichierMatrice : ajouter sa ligne (roles, verifications, captures)',
      );
    }
  }
  // 2. Chaque ligne designe un fichier qui existe et qui utilise un composant.
  for (final String f in matrice) {
    if (!File('$racine/$f').existsSync()) {
      erreurs.add(
        '$fichierMatrice nomme $f, qui n\'existe plus : retirer la ligne',
      );
    } else if (!usages.containsKey(f)) {
      erreurs.add(
        '$fichierMatrice nomme $f, qui n\'utilise plus aucun composant de '
        'conversation : retirer la ligne',
      );
    }
  }
  // 3. Aucun ecran ne recompose l'en-tete du composant partage.
  final Set<String> vues = <String>{};
  for (final MapEntry<String, List<String>> e in usages.entries) {
    final String f = e.key;
    if (estPartage(f) || estOutil(f)) continue;
    final String texte = sansCommentaires(
      File('$racine/$f').readAsStringSync(),
    );
    for (final Regle r in regles) {
      if (!r.motif.hasMatch(texte)) continue;
      final String cle = '$f|${r.id}';
      vues.add(cle);
      if (!tolerees.containsKey(cle)) {
        erreurs.add('$f : ${r.id} : ${r.pourquoi}');
      }
    }
  }
  // 4. La liste toleree ne fait que retrecir.
  for (final String cle in tolerees.keys) {
    if (!vues.contains(cle)) {
      erreurs.add(
        '$fichierTolere : « $cle » ne correspond plus a aucune violation : '
        'retirer la ligne',
      );
    }
  }
  return erreurs;
}

void main(List<String> args) {
  if (args.contains('--lister')) {
    releve('.').forEach(
      (String f, List<String> c) => stdout.writeln('$f : ${c.join(', ')}'),
    );
    return;
  }
  final List<String> erreurs = verifier();
  if (erreurs.isEmpty) {
    final int n = releve('.').length;
    stdout.writeln(
      'Conversations : $n fichiers utilisent un composant, tous dans la '
      'matrice ; aucun en-tete recompose hors liste toleree.',
    );
    return;
  }
  for (final String e in erreurs) {
    stderr.writeln(e);
  }
  stderr.writeln('${erreurs.length} violation(s)');
  exit(1);
}
