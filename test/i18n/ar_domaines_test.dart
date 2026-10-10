// AR-COMPLET-1, par tranches : les domaines traduits en arabe le restent.
//
// AR-SALLE-1 (`salle.*`) et AR-TC-1 (`tc.*`) : chaque cle du francais a sa
// traduction arabe, avec exactement les memes parametres ; chaque parametre
// ajoute par ces tranches est isole des deux cotes (U+2068 juste avant,
// U+2069 juste apres, bornes equilibrees), pour qu'un nom latin
// ne renverse pas la phrase. Une tranche suivante ajoute son domaine a
// [_domaines].

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// Les domaines entierement traduits, et leur nombre minimal de cles.
/// `presence` et `destructif` (verification TB, 10/10) : la colonne de
/// presence du controleur et la feuille ConfirmDestructive de la salle.
const Map<String, int> _domaines = <String, int>{
  'salle': 300,
  'tc': 450,
  'presence': 25,
  'destructif': 0,
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

/// Les textes gardes en latin (marque, format de fichier).
const Set<String> _latins = <String>{
  'salle.seance.rail.marque',
  'salle.seance.rail.sousMarque',
  'tc.bibliotheque.type.pdf',
};

final RegExp _parametre = RegExp(r'\{\w+\}');

List<String> _parametres(String texte) =>
    _parametre.allMatches(texte).map((Match m) => m[0]!).toList()..sort();

/// Ce qui ne va pas dans l'isolation des parametres de [texte] : un
/// parametre qui n'est pas IMMEDIATEMENT precede de U+2068 ET suivi de
/// U+2069, ou des U+2068 / U+2069 desequilibres (un U+2069 sans ouvrant, un
/// U+2068 jamais ferme : il s'etendrait jusqu'a la fin du paragraphe).
List<String> defautsIsolation(String texte) {
  final List<String> defauts = <String>[];
  for (final Match m in _parametre.allMatches(texte)) {
    final bool ouvert = m.start > 0 && texte[m.start - 1] == '\u2068';
    final bool ferme = m.end < texte.length && texte[m.end] == '\u2069';
    if (!ouvert || !ferme) defauts.add(m[0]!);
  }
  int profondeur = 0;
  for (final int unite in texte.codeUnits) {
    // U+2066 (LRI) ouvre aussi un isolat : une fraction lue de gauche a
    // droite (« 2/4 ») isole ses deux parametres dedans.
    if (unite >= 0x2066 && unite <= 0x2068) profondeur++;
    if (unite == 0x2069 && --profondeur < 0) {
      defauts.add('U+2069 sans U+2068');
      profondeur = 0;
    }
  }
  if (profondeur != 0) defauts.add('U+2068 non ferme');
  return defauts;
}

/// Les mots latins admis dans une valeur arabe : la marque, un format.
const Set<String> _motsLatinsAdmis = <String>{'Rewayah', 'Academy', 'PDF'};

/// Les codes de situation de demonstration (SAL-00, PED-01...), gardes en
/// latin (ecart voulu 3 de AR-SALLE-1).
final RegExp _codeSituation = RegExp(r'\b[A-Z]{2,4}-\d{2}\b');

/// Les mots latins de deux lettres ou plus restes dans [texte], hors
/// parametres, codes de situation et mots admis.
List<String> motsLatinsInattendus(String texte) => RegExp('[A-Za-zÀ-ÿ]{2,}')
    .allMatches(texte.replaceAll(_parametre, '').replaceAll(_codeSituation, ''))
    .map((Match m) => m[0]!)
    .where((String mot) => !_motsLatinsAdmis.contains(mot))
    .toList();

/// Rien que des parametres et de la ponctuation : rien a traduire.
bool _sansMots(String texte) => texte
    .replaceAll(_parametre, '')
    .replaceAll(RegExp('[\u2066\u2068\u2069 ·/%٪،,]'), '')
    .isEmpty;

void main() {
  test('les detecteurs voient une borne manquante et un mot francais', () {
    expect(defautsIsolation('\u2068{a}\u2069 et \u2068{b}\u2069'), isEmpty);
    expect(defautsIsolation('\u2068{a}'), isNotEmpty);
    expect(defautsIsolation('{a}\u2069'), isNotEmpty);
    expect(defautsIsolation('\u2068{a}\u2069\u2069'), isNotEmpty);
    expect(defautsIsolation('\u2068 {a}\u2069'), isNotEmpty);
    expect(
      defautsIsolation('\u2066\u2068{a}\u2069/\u2068{b}\u2069\u2069'),
      isEmpty,
    );
    expect(motsLatinsInattendus('عرض Présenter'), <String>['Présenter']);
    expect(motsLatinsInattendus('SAL-00 Rewayah \u2068{nom}\u2069'), isEmpty);
  });

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
        for (final MapEntry<String, String> e in ar.entries) {
          expect(defautsIsolation(e.value), isEmpty, reason: e.key);
        }
      });

      // Une fraction « {a} / {b} » se lit dans un seul sens, celui du
      // compteur d'eleves (« 2/4 ») : de gauche a droite, sous U+2066.
      test('fractions lues de gauche a droite (U+2066)', () {
        final RegExp fraction = RegExp('\u2068\\{\\w+\\}\u2069 ?/ ?\u2068\\{\\w+\\}\u2069');
        for (final MapEntry<String, String> e in ar.entries) {
          for (final Match m in fraction.allMatches(e.value)) {
            expect(
              m.start > 0 && e.value[m.start - 1] == '\u2066',
              isTrue,
              reason: e.key,
            );
          }
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

      test('aucun mot francais reste dans une valeur arabe', () {
        for (final MapEntry<String, String> e in ar.entries) {
          expect(motsLatinsInattendus(e.value), isEmpty, reason: e.key);
        }
      });
    });
  });

  test('slang rend l\'arabe a l\'execution', () async {
    final Traductions traductions = await AppLocale.ar.build();
    expect(traductions.salle.seance.bibliotheque.presenter, 'عرض على الفصل');
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
