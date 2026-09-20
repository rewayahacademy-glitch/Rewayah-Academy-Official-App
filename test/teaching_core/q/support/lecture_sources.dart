// Lecture des sources du depot depuis un test.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// POURQUOI LIRE DU TEXTE DANS UN TEST. Certains invariants du chantier ne
// portent pas sur une valeur mais sur la FORME du code : « ce type ne porte
// aucun champ de nom de famille », « aucun libelle ne dit mode enfant »,
// « aucun titre n'est Ustaz ». Un test d'execution ne les voit pas : il ne
// peut interroger que les champs qui existent, jamais ceux qu'on vient
// d'ajouter. Une lecture de source, elle, refuse l'ajout le jour meme.
//
// `dart:mirrors` n'existe pas cote Flutter, et une generation de code serait
// une dependance de plus : la lecture de fichier est la forme la plus simple
// qui marche.

import 'dart:io';

/// Le fichier [chemin], relatif a la racine du paquet.
///
/// `flutter test` place le repertoire courant a la racine du paquet : c'est
/// la meme hypothese que `tool/verifier_jetons.dart`, qui lit `lib/` de cette
/// facon depuis la CI.
File fichierDuDepot(String chemin) => File('${Directory.current.path}/$chemin');

/// Le contenu de [chemin], ou `null` si le fichier n'existe pas.
///
/// Rendre `null` plutot que lever laisse les tests distinguer deux situations
/// tres differentes : un fichier absent parce qu'un autre agent ne l'a pas
/// encore publie (normal en phase parallele), et un fichier present mais
/// fautif (un BLOCKER).
String? lireSiPresent(String chemin) {
  final File f = fichierDuDepot(chemin);
  if (!f.existsSync()) return null;
  return f.readAsStringSync();
}

/// Les occurrences de [interdits] trouvees dans [source], en minuscules.
///
/// La recherche ignore les lignes de commentaire : un commentaire qui NOMME
/// l'interdiction -- « ne porte ni lastName ni initiale » -- est exactement ce
/// qu'on veut encourager, pas ce qu'on veut punir.
List<String> motsTrouves(String source, List<String> interdits) {
  final List<String> trouves = <String>[];
  final List<String> lignes = source.split('\n');
  for (final String ligne in lignes) {
    final String nette = ligne.trim();
    if (nette.startsWith('//') || nette.startsWith('///')) continue;
    final String bas = nette.toLowerCase();
    for (final String mot in interdits) {
      if (bas.contains(mot) && !trouves.contains(mot)) {
        trouves.add(mot);
      }
    }
  }
  return trouves;
}

/// Les chemins de production ou un contrat pourrait etre publie.
///
/// Pendant la phase parallele ils n'existent pas dans le worktree d'Agent Q,
/// et c'est prevu. Apres l'integration ils existent, et les memes tests les
/// examinent sans qu'une ligne change.
abstract final class CheminsCanoniques {
  /// La projection pedagogique enseignant (Agent E).
  static const String projectionEnseignant =
      'lib/core/tc_classe/teacher_student_projection.dart';

  /// La couche d'annotation (Agent D).
  static const String coucheAnnotation =
      'lib/core/tc_outils/annotation_layer.dart';

  /// La version de ressource (Agent B).
  static const String versionRessource =
      'lib/core/tc_bibliotheque/resource_version.dart';

  /// La carte de groupe (Agent A).
  static const String carteGroupe = 'lib/core/tc_groupe/group_summary_vm.dart';
}

/// Les doubles de contrat tenus par Agent Q.
abstract final class CheminsDoubles {
  /// Le double de la projection enseignant.
  static const String projectionEnseignant =
      'test/teaching_core/fixtures/contrats/contrats_e_classe.dart';

  /// Le double des outils pedagogiques.
  static const String outils =
      'test/teaching_core/fixtures/contrats/contrats_d_outils.dart';

  /// Le double des contrats de Groupe.
  static const String groupe =
      'test/teaching_core/fixtures/contrats/contrats_a_groupe.dart';

  /// Le repertoire des fixtures.
  static const String repertoireFixtures = 'test/teaching_core/fixtures';
}

/// Tous les fichiers `.dart` sous [repertoire], recursivement.
List<File> fichiersDart(String repertoire) {
  final Directory d = Directory('${Directory.current.path}/$repertoire');
  if (!d.existsSync()) return <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();
}
