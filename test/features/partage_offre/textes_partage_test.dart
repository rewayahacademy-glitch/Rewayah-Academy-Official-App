// CAND-06 : les textes de la tuile et de la page, lus dans les fichiers de
// traduction (francais et arabe), cle par cle. La carte a ses propres textes, en
// quatre langues (`textes_carte_test.dart`).
//
// Consigne du directeur du 22/10/2026, apres coup : « tu leur demandes de faire
// une action sans aucune contrepartie […] Il faut leur parler de l'interet que
// l'eleve va avoir. Pas Rewayah Academy », puis : « la fierte de participer a un
// geste noble et la simplicite », « peu de mots ». Aucun texte ne demande d'agir
// pour l'academie ; son nom n'est jamais le motif. Et les regles de
// `mots-rewayah` : « classe » et jamais « groupe », aucune promesse, aucun prix,
// pas de tiret long.

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

  test('aucun texte vide, ni en francais ni en arabe', () {
    for (final Map<String, String> textes in <Map<String, String>>[fr, ar]) {
      expect(<String>[
        for (final MapEntry<String, String> e in textes.entries)
          if (e.value.trim().isEmpty) e.key,
      ], isEmpty);
    }
  });

  test('les textes de la carte ne sont plus dans les fichiers de traduction : '
      'ils vivent dans le fichier de donnees de la carte', () {
    for (final Map<String, String> textes in <Map<String, String>>[fr, ar]) {
      expect(
        textes.keys.where(
          (String k) => k.startsWith('recrutement.partage.carte.'),
        ),
        isEmpty,
      );
      for (final String ancienne in <String>[
        'introduction',
        'introductionSuite',
        'motif',
      ]) {
        expect(
          textes.containsKey('recrutement.partage.$ancienne'),
          isFalse,
          reason: 'peu de mots : plus de $ancienne',
        );
      }
    }
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

    test('$langue : aucune demande faite pour l\'academie ni pour la faire '
        'connaitre ; l\'invitation vise la personne qui apprendra', () {
      final List<String> demandes = langue == 'fr'
          ? <String>[
              'faites connaître',
              'faites connaitre',
              'faire connaître',
              'aidez-nous',
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

  test('en francais, aucune lettre arabe dans la page ; en arabe, aucune '
      'phrase francaise', () {
    final RegExp arabe = RegExp('[\u0600-\u06FF]');
    expect(<String>[
      for (final MapEntry<String, String> e in fr.entries)
        if (arabe.hasMatch(e.value)) e.key,
    ], isEmpty);
    // Les invitations arabes sont des phrases arabes seules.
    for (final String cle in <String>[
      'recrutement.partage.titre',
      'recrutement.partage.titreFemme',
      'recrutement.partage.partager',
      'recrutement.partage.langueCarte',
    ]) {
      expect(RegExp('[A-Za-z]').hasMatch(ar[cle]!), isFalse, reason: cle);
    }
  });

  test('l\'invitation : les mots du directeur (22/10), au masculin et au '
      'feminin, en francais et en arabe', () {
    expect(
      fr['recrutement.partage.titre'],
      'Aidez une personne à apprendre la parole d\'Allah.',
    );
    expect(
      fr['recrutement.partage.titreFemme'],
      'Aidez une sœur à apprendre la parole d\'Allah.',
    );
    expect(ar['recrutement.partage.titre'], 'ساعد شخصًا على تعلّم كلام الله');
    expect(
      ar['recrutement.partage.titreFemme'],
      'ساعدي أختًا على تعلّم كلام الله',
    );
  });

  test('le bouton est a la premiere personne : « Je partage »', () {
    expect(fr['recrutement.partage.partager'], 'Je partage');
    expect(ar['recrutement.partage.partager'], 'أشارك');
    // Le lecteur d'ecran entend ce que le bouton partage.
    expect(
      fr['recrutement.partage.partagerLaCarte'],
      'Partager la carte de l\'offre',
    );
  });

  test('la mention facultative : le seul texte qui reste, tel que le '
      'directeur l\'a gardee', () {
    expect(
      fr['recrutement.partage.facultatif'],
      'Facultatif\u00a0: partager ne change rien à votre candidature.',
    );
    expect(
      ar['recrutement.partage.facultatif'],
      'اختياري: المشاركة لا تغيّر شيئًا في طلب ترشحك.',
    );
  });

  test('peu de mots : l\'invitation tient en une phrase courte', () {
    for (final String cle in <String>[
      'recrutement.partage.titre',
      'recrutement.partage.titreFemme',
    ]) {
      expect(fr[cle]!.split(' ').length, lessThanOrEqualTo(9), reason: cle);
      expect(ar[cle]!.split(' ').length, lessThanOrEqualTo(7), reason: cle);
    }
  });
}
