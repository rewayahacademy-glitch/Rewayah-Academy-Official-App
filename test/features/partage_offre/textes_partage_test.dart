// CAND-06 : les textes de la tuile, de la page et de la carte, lus dans les
// fichiers de traduction (francais et arabe), cle par cle.
//
// Consigne du directeur du 22/10/2026, apres coup : « tu leur demandes de faire
// une action sans aucune contrepartie […] Il faut leur parler de l'interet que
// l'eleve va avoir. Pas Rewayah Academy. Il ne faut pas dire faites ca pour
// Rewayah Academy. » Aucun texte ne demande d'agir pour l'academie ; son nom
// n'est jamais le motif. Et les regles de `mots-rewayah` : « classe » et jamais
// « groupe », aucune promesse, aucun prix, pas de tiret long.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hote_partage.dart';

/// Les feuilles de `recrutement.partage` d'une langue : chemin -> texte.
Map<String, String> _feuilles(String langue) {
  final Map<String, dynamic> racine = jsonDecode(
    File('assets/i18n/$langue.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, String> sortie = <String, String>{};
  void parcourir(String chemin, Object? noeud) {
    if (noeud is Map<String, dynamic>) {
      noeud.forEach((String cle, Object? v) => parcourir('$chemin.$cle', v));
    } else if (noeud is String) {
      sortie[chemin] = noeud;
    }
  }

  parcourir(
    'recrutement.partage',
    (racine['recrutement'] as Map<String, dynamic>)['partage'],
  );
  return sortie;
}

void main() {
  final Map<String, String> fr = _feuilles('fr');
  final Map<String, String> ar = _feuilles('ar');

  test('francais et arabe portent les memes cles', () {
    expect(ar.keys.toSet(), fr.keys.toSet());
    expect(fr, isNotEmpty);
  });

  test('l\'arabe n\'a de texte vide que la traduction du hadith', () {
    expect(
      <String>[
        for (final MapEntry<String, String> e in ar.entries)
          if (e.value.isEmpty) e.key,
      ],
      <String>['recrutement.partage.carte.traduction'],
    );
    expect(<String>[
      for (final MapEntry<String, String> e in fr.entries)
        if (e.value.isEmpty) e.key,
    ], isEmpty);
  });

  for (final String langue in <String>['fr', 'ar']) {
    final Map<String, String> textes = langue == 'fr' ? fr : ar;

    test('$langue : aucun texte ne nomme l\'academie, son nom n\'est jamais '
        'le motif', () {
      for (final MapEntry<String, String> e in textes.entries) {
        for (final String mot in motsQuiNommentLAcademie) {
          expect(
            e.value.toLowerCase(),
            isNot(contains(mot.toLowerCase())),
            reason: '${e.key} : $mot',
          );
        }
      }
    });

    test('$langue : aucune demande faite pour l\'academie ni pour la '
        'faire connaitre', () {
      final List<String> demandes = langue == 'fr'
          ? <String>[
              'faites connaître',
              'faites connaitre',
              'faire connaître',
              'aidez',
              'soutenez',
              'pour nous',
              'nous aider',
              'rendez service',
              'diffusez',
              'parlez de nous',
            ]
          : <String>['عرّفوا', 'عرّف بنا', 'ساعدونا', 'ساعدنا', 'ادعمونا'];
      for (final MapEntry<String, String> e in textes.entries) {
        for (final String demande in demandes) {
          expect(
            e.value.toLowerCase(),
            isNot(contains(demande)),
            reason: '${e.key} : $demande',
          );
        }
      }
    });

    test('$langue : ni prix, ni promesse, ni mot interdit, ni tiret long', () {
      final RegExp montant = RegExp(
        r'[0-9٠-٩]+\s*(\$|€|usd|dollars?|euros?|دولار|يورو|%)',
        caseSensitive: false,
      );
      final List<String> interdits = langue == 'fr'
          ? <String>[
              'prix',
              'tarif',
              'gratuit',
              'garanti',
              'certifié',
              'rembours',
              'remise',
              'bourse',
              'essai',
              'groupe',
              'mode enfant',
              'échec',
              'essentiel',
              'admin ',
              'majlis',
            ]
          : <String>['سعر', 'أسعار', 'مجان', 'خصم', 'استرداد', 'ضمان'];
      for (final MapEntry<String, String> e in textes.entries) {
        final String texte = e.value.toLowerCase();
        expect(montant.hasMatch(texte), isFalse, reason: e.key);
        for (final String mot in interdits) {
          expect(texte, isNot(contains(mot)), reason: '${e.key} : $mot');
        }
        expect(texte, isNot(contains('—')), reason: '${e.key} : tiret long');
        expect(texte, isNot(contains('–')), reason: '${e.key} : tiret long');
      }
    });
  }

  test('le hadith est le meme dans les deux langues, et il est seul', () {
    const String hadith = 'الدال على الخير كفاعله';
    expect(fr['recrutement.partage.carte.hadith'], hadith);
    expect(ar['recrutement.partage.carte.hadith'], hadith);
    // Le hadith ne se repete dans aucun autre texte de l'arabe sous sa forme
    // de la carte (le motif le cite, entre guillemets, une fois).
    final int dansLeMotif = RegExp(hadith)
        .allMatches(ar['recrutement.partage.motif']!)
        .length;
    expect(dansLeMotif, 1);
    // En francais, le hadith n'est ecrit en arabe qu'une fois : sur la carte.
    final RegExp arabe = RegExp('[؀-ۿ]');
    expect(
      <String>[
        for (final MapEntry<String, String> e in fr.entries)
          if (arabe.hasMatch(e.value)) e.key,
      ],
      <String>['recrutement.partage.carte.hadith'],
    );
  });

  test('l\'arabe n\'est pas une langue de cours : la ligne des langues ne le '
      'cite pas', () {
    expect(
      fr['recrutement.partage.carte.langues']!.toLowerCase(),
      isNot(contains('arabe')),
    );
    expect(
      ar['recrutement.partage.carte.langues'],
      isNot(contains('بالعربية')),
    );
    expect(ar['recrutement.partage.carte.langues'], isNot(contains('العربية')));
  });

  test('la tuile et la page parlent de la personne qui apprendra', () {
    // Le titre et la phrase du directeur (22/10/2026), tels quels.
    expect(
      fr['recrutement.partage.titre'],
      'Un proche veut apprendre le\u00a0Coran\u00a0?',
    );
    expect(
      fr['recrutement.partage.introduction'],
      'Envoyez-lui l\'offre en un geste\u00a0: il apprendra en petite classe, '
      'en visio, avec le même enseignant chaque semaine.',
    );
    expect(
      fr['recrutement.partage.facultatif'],
      'Facultatif\u00a0: partager ne change rien à votre candidature.',
    );
    // Le titre de la carte dit ce que l'eleve y gagne.
    expect(
      fr['recrutement.partage.carte.titre'],
      'Apprendre le Coran en ligne, en petite\u00a0classe',
    );
    expect(fr['recrutement.partage.carte.decouvrir'], 'Découvrir l\'offre');
  });
}
