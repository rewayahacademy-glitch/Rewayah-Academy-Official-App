// AR-COMPLET-1, par tranches : les domaines traduits en arabe le restent.
//
// AR-SALLE-1 (`salle.*`), AR-TC-1 (`tc.*`) et AR-ENS-1 (`enseignant.*`) :
// chaque cle du francais a sa traduction arabe, avec exactement les memes
// parametres ; chaque parametre ajoute par ces tranches est isole (U+2068 ...
// U+2069), pour qu'un nom latin ne renverse pas la phrase. Une tranche
// suivante ajoute son domaine a [_domaines].

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// Les domaines entierement traduits, et leur nombre minimal de cles.
const Map<String, int> _domaines = <String, int>{
  'salle': 300,
  'tc': 450,
  'enseignant': 400,
};

Map<String, String> _aplatir(
  Map<String, dynamic> carte, [
  String prefixe = '',
]) {
  final Map<String, String> sortie = <String, String>{};
  carte.forEach((String cle, dynamic valeur) {
    if (valeur is Map<String, dynamic>) {
      sortie.addAll(_aplatir(valeur, '$prefixe$cle.'));
    } else {
      sortie['$prefixe$cle'] = valeur as String;
    }
  });
  return sortie;
}

Map<String, String> _domaine(String langue, String domaine) => _aplatir(
  (jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
          as Map<String, dynamic>)[domaine]
      as Map<String, dynamic>,
  '$domaine.',
);

/// Les cles traduites avant ces tranches, sans isolation.
const Set<String> _anciennes = <String>{
  'salle.secours.indisponible',
  'enseignant.journee.rejoindreSalleLecteur',
  'enseignant.journee.remplirCahierLecteur',
  'enseignant.journee.cahierObligatoire',
  'enseignant.journee.voirCahier',
  'enseignant.journee.voirCahierLecteur',
  'enseignant.ficheGroupe.repriseEleve',
  'enseignant.ficheGroupe.dernierPoint',
};

/// Les textes gardes en latin (marque, format de fichier).
const Set<String> _latins = <String>{
  'salle.seance.rail.marque',
  'salle.seance.rail.sousMarque',
  'tc.bibliotheque.type.pdf',
};

final RegExp _parametre = RegExp(r'\{\w+\}');

List<String> _parametres(String texte) =>
    _parametre.allMatches(texte).map((Match m) => m[0]!).toList()..sort();

/// Rien que des parametres et de la ponctuation : rien a traduire.
bool _sansMots(String texte) => texte
    .replaceAll(_parametre, '')
    .replaceAll(RegExp('[\u2068\u2069 ·/%،,]'), '')
    .isEmpty;

void main() {
  _domaines.forEach((String domaine, int minimum) {
    group(domaine, () {
      final Map<String, String> fr = _domaine('fr', domaine);
      final Map<String, String> ar = _domaine('ar', domaine);

      test('chaque cle $domaine.* a sa traduction arabe', () {
        expect(fr.length, greaterThan(minimum));
        final List<String> manquantes = fr.keys
            .where((String cle) => !ar.containsKey(cle))
            .toList();
        expect(manquantes, isEmpty);
        expect(ar.keys.toSet().difference(fr.keys.toSet()), isEmpty);
      });

      test('memes parametres qu\'en francais', () {
        for (final String cle in fr.keys) {
          final String? texte = ar[cle];
          if (texte == null) continue;
          expect(_parametres(texte), _parametres(fr[cle]!), reason: cle);
        }
      });

      test('parametres isoles (U+2068 ... U+2069)', () {
        final RegExp nu = RegExp('(?<!\u2068)\\{\\w+\\}(?!\u2069)');
        for (final MapEntry<String, String> e in ar.entries) {
          if (_anciennes.contains(e.key)) continue;
          expect(nu.hasMatch(e.value), isFalse, reason: e.key);
        }
      });

      test('du texte arabe, jamais le francais recopie', () {
        final RegExp arabe = RegExp('[؀-ۿ]');
        for (final MapEntry<String, String> e in ar.entries) {
          if (_latins.contains(e.key) || _sansMots(e.value)) continue;
          expect(arabe.hasMatch(e.value), isTrue, reason: e.key);
          expect(e.value, isNot(fr[e.key]), reason: e.key);
        }
      });
    });
  });

  test('slang rend l\'arabe a l\'execution', () async {
    final Traductions traductions = await AppLocale.ar.build();
    expect(traductions.salle.seance.bibliotheque.presenter, 'عرض');
    expect(
      traductions.salle.seance.surface.page(titre: 'X', page: 1, pages: 2),
      '\u2068X\u2069، الصفحة \u20681\u2069 من \u20682\u2069',
    );
    expect(traductions.tc.bibliotheque.titre, 'المكتبة');
    expect(
      traductions.tc.bibliotheque.aucunResultat.message,
      isNot(t.tc.bibliotheque.aucunResultat.message),
    );
  });
}
