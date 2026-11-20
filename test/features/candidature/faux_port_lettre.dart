// LETTRE-CANDIDATS : un faux serveur de la lettre pour les tests. Le texte
// vient des fichiers du depot (`docs/current/CANDIDATURES/LETTRE-CANDIDATS/`),
// jamais de l'application : c'est le meme texte que le serveur rendra.
import 'dart:io';

import 'package:rewayah_academy/features/candidature/lettre/port_lettre.dart';

/// Les parties de la lettre dans [langue], lues dans le fichier du depot.
List<PartieLettre> partiesDuDepot(String langue) {
  final String brut = File(
    'docs/current/CANDIDATURES/LETTRE-CANDIDATS/LETTRE-$langue.md',
  ).readAsStringSync();
  final String depuis = brut.substring(brut.indexOf('## 1.'));
  final List<String> blocs = depuis.split(RegExp(r'^## ', multiLine: true))
    ..removeAt(0);
  return <PartieLettre>[
    for (int k = 0; k < blocs.length; k++)
      PartieLettre(
        code: 'p${k + 1}',
        titre: blocs[k]
            .split('\n')
            .first
            .replaceFirst(RegExp(r'^\d+\.\s*'), '')
            .trim(),
        corps: blocs[k].substring(blocs[k].indexOf('\n') + 1).trim(),
      ),
  ];
}

/// Un faux port : rend [reponse], ou la lettre du depot dans la langue
/// demandee quand [reponse] est nulle.
class FauxPortLettre implements PortLettre {
  /// Cree le faux port.
  FauxPortLettre({this.reponse, this.erreur});

  /// La reponse fixe, ou nulle pour la lettre ouverte.
  final LectureLettre? reponse;

  /// L'erreur a lever, le cas echeant.
  final Exception? erreur;

  /// Les langues demandees.
  final List<String> langues = <String>[];

  @override
  Future<LectureLettre> lire({required String langue}) async {
    langues.add(langue);
    if (erreur != null) throw erreur!;
    return reponse ??
        LectureLettre.ouverte(
          parties: partiesDuDepot(langue),
          version: '2026-11-20',
          langue: langue,
        );
  }
}
