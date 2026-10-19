// COUPE-MOTS-FOND-1 (6) : la ponctuation haute de TOUT `fr.i18n.json`.
//
// La typographie francaise lie « ? ! : ; » au mot qui precede, et « »
// a son contenu, par une espace insecable (U+00A0, la regle du depot) :
// sans elle, le signe part seul a la ligne (« Pourquoi ce changement / ? »).
// Deux fautes sont cherchees sur chaque valeur, cle par cle :
//   * une espace SECABLE devant le signe ou dans les guillemets
//     (`adulte.accueil.echec`, `adulte.historique.echec`,
//     `enseignant...erreurPartielle*` en portaient une) ;
//   * un signe COLLE au mot (« Erreur: », « «Bonjour» »), sans espace du
//     tout, hors heures (« 18:12 »), adresses (« https: »), renvois slang
//     (« @: ») et signes doubles (« ?! »).
// L'inventaire est chiffre : le nombre de valeurs lues et de signes
// mesures est verifie, pour que la garde ne passe jamais a vide.
//
// Sur le rendu, la meme regle est mesuree ecran par ecran par la garde du
// balayage (`ponctuationsIsolees`, `test/support/garde_coupe_mots_rendu.dart`).
//
// Contre-epreuve : une espace ordinaire remise devant le deux-points de
// `adulte.accueil.echec` fait echouer le test en nommant la cle.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toutes les valeurs texte de [noeud], avec leur cle complete.
Iterable<MapEntry<String, String>> valeursI18n(
  Object? noeud, [
  String prefixe = '',
]) sync* {
  if (noeud is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> e in noeud.entries) {
      yield* valeursI18n(
        e.value,
        prefixe.isEmpty ? e.key : '$prefixe.${e.key}',
      );
    }
  } else if (noeud is List<dynamic>) {
    for (final (int i, Object? v) in noeud.indexed) {
      yield* valeursI18n(v, '$prefixe.$i');
    }
  } else if (noeud is String) {
    yield MapEntry<String, String>(prefixe, noeud);
  }
}

/// Une espace secable devant un signe haut, ou apres un guillemet ouvrant.
final RegExp espaceSecableAvantSigne = RegExp(
  '[^\\S\u00A0\u2007\u202F][?!:;»]|«[^\\S\u00A0\u2007\u202F]',
);

/// Un signe haut colle au mot qui precede (sans aucune espace), ou un
/// guillemet ouvrant colle au mot qui suit.
final RegExp signeColle = RegExp(
  '[^\\s\u00A0\u2007\u202F\\d?!:;/@({\\[][?!;»:](?=\\s|\$)'
  '|«[^\\s\u00A0\u2007\u202F]',
);

/// Les fautes de typographie de [valeurs], « cle : valeur ».
List<String> fautesPonctuation(Iterable<MapEntry<String, String>> valeurs) =>
    <String>[
      for (final MapEntry<String, String> e in valeurs)
        if (!e.value.startsWith('@:') &&
            (espaceSecableAvantSigne.hasMatch(e.value) ||
                signeColle.hasMatch(e.value)))
          '${e.key} : ${e.value}',
    ];

void main() {
  final Map<String, dynamic> fr = jsonDecode(
    File('assets/i18n/fr.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final List<MapEntry<String, String>> valeurs = valeursI18n(fr).toList();

  test('inventaire : le fichier entier est lu, ses signes hauts comptes', () {
    final int signes = valeurs.fold<int>(
      0,
      (int n, MapEntry<String, String> e) =>
          n + RegExp('[?!:;«»]').allMatches(e.value).length,
    );
    final int porteurs = valeurs
        .where(
          (MapEntry<String, String> e) => e.value.contains(RegExp('[?!:;«»]')),
        )
        .length;
    // 6 942 valeurs, 700 portent un signe haut, 791 signes (10/10/2026).
    expect(valeurs.length, greaterThan(6000));
    expect(porteurs, greaterThan(600));
    expect(signes, greaterThan(700));
  });

  test('aucune espace secable ni signe colle dans tout fr.i18n.json', () {
    expect(fautesPonctuation(valeurs), isEmpty);
  });

  test('les cles nommees par la fiche lient leur deux-points', () {
    String valeur(String cle) =>
        valeurs.firstWhere((MapEntry<String, String> e) => e.key == cle).value;
    for (final String cle in <String>[
      'adulte.accueil.echec',
      'adulte.historique.echec',
      // tuteur.reglages.demandeMotif : retiree avec les anciens reglages
      // de l'enfant (menage du 17/10).
    ]) {
      expect(valeur(cle), isNot(contains(RegExp(r' [?!:;]'))), reason: cle);
    }
    final List<MapEntry<String, String>> partielles = valeurs
        .where(
          (MapEntry<String, String> e) =>
              e.key.startsWith('enseignant.') &&
              e.key.split('.').last.startsWith('erreurPartielle'),
        )
        .toList();
    expect(partielles, hasLength(greaterThanOrEqualTo(3)));
    expect(fautesPonctuation(partielles), isEmpty);
  });

  test('la garde voit une faute remise (contre-epreuve en memoire)', () {
    expect(
      fautesPonctuation(<MapEntry<String, String>>[
        const MapEntry<String, String>('a', 'Echec : reessayez'),
        const MapEntry<String, String>('b', 'Pourquoi ?'),
        const MapEntry<String, String>('c', 'Erreur: reessayez'),
        const MapEntry<String, String>('d', '« Bonjour »'),
      ]),
      <String>[
        'a : Echec : reessayez',
        'b : Pourquoi ?',
        'c : Erreur: reessayez',
        'd : « Bonjour »',
      ],
    );
    // Les heures, adresses et renvois ne sont pas des fautes.
    expect(
      fautesPonctuation(<MapEntry<String, String>>[
        const MapEntry<String, String>('e', 'A 18:12, ouvert'),
        const MapEntry<String, String>('f', 'https://rewayah.app'),
        const MapEntry<String, String>('g', '@:commun.ok'),
      ]),
      isEmpty,
    );
  });
}
