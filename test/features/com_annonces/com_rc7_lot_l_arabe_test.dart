// COM-RC tour 7, lot L : relecture arabe des libelles corriges au tour 5
// (LIBELLES_COM_RELECTURE.md, 26 lignes) et des trois libelles hors ligne du
// tour 6 (REVUE_COM-R §8.2, §9.2 : « relecture par un arabophone »).
//
// - aucune espace avant les deux-points en arabe (« أنت غير متصل : » se
//   lisait a la francaise), dans tout le fichier arabe ;
// - aucun mot francais, parametres conserves ;
// - terminologie : « الأكاديمية », « المستلمون », « صلاحيات النشر » ;
// - une virgule arabe qui suit un parametre (nom, adresse, titre) est
//   rattachee au texte arabe par une marque droite-a-gauche (U+200F) : sans
//   elle, « Samira، 0:12 » passait dans le texte latin.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// Les 26 lignes de LIBELLES_COM_RELECTURE.md et les trois libelles hors
/// ligne du tour 6.
const List<String> _relues = <String>[
  'com.communaute.garde.reponse.avertissement',
  'com.annonces.publieur.nature.toutes',
  'com.annonces.administration.matrice.detail',
  'com.annonces.demoPublication.toutes',
  'com.annonces.demoPublication.audiencesDirection',
  'com.studio.aujourdhui.acces.messagesDetail',
  'notifications.types.reponseFil',
  'com.messages.types.autre',
  'com.messages.panneau.objets',
  'com.messages.panneau.inaccessible',
  'com.communaute.demo.choisir',
  'com.annonces.publieur.etapes.audience',
  'com.annonces.publieur.contexte.audience',
  'com.annonces.publieur.contexte.publication',
  'com.annonces.publieur.manqueAudience',
  'com.annonces.publieur.aucuneCibleTitre',
  'com.annonces.publieur.aucuneCible',
  'com.annonces.administration.matrice.audiences',
  'com.annonces.administration.indicateurs.regles',
  'com.annonces.administration.matrice.titre',
  'com.annonces.administration.matrice.vide',
  'com.communaute.garde.panne',
  'com.annonces.administration.indicateurs.echec',
  'com.communaute.reponses.nonConfirmee',
  'com.annonces.publieur.horsLigne',
  'com.annonces.demo.roles.admin',
  'com.socle.composants.etats.horsLigneBloc',
  'com.annonces.administration.horsLigne',
  'com.annonces.administration.moderation.horsLigne',
];

Map<String, String> _aplatir(Map<String, dynamic> d, [String p = '']) {
  final Map<String, String> sortie = <String, String>{};
  d.forEach((String k, dynamic v) {
    final String cle = p.isEmpty ? k : '$p.$k';
    if (v is Map<String, dynamic>) {
      sortie.addAll(_aplatir(v, cle));
    } else if (v is String) {
      sortie[cle] = v;
    }
  });
  return sortie;
}

Map<String, String> _lire(String langue) => _aplatir(
  jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
      as Map<String, dynamic>,
);

Set<String> _parametres(String texte) => <String>{
  for (final RegExpMatch m in RegExp(r'\{(\w+)\}').allMatches(texte)) m[1]!,
};

void main() {
  final Map<String, String> fr = _lire('fr');
  final Map<String, String> ar = _lire('ar');

  group('Les 29 libelles relus', () {
    for (final String cle in _relues) {
      test(cle, () {
        final String? arabe = ar[cle];
        expect(arabe, isNotNull, reason: 'cle absente en arabe');
        expect(fr[cle], isNotNull, reason: 'cle absente en francais');
        final String sansParametres = arabe!.replaceAll(RegExp(r'\{\w+\}'), '');
        // Aucun mot francais (lettres latines) hors des parametres.
        expect(sansParametres, isNot(matches(RegExp('[A-Za-zÀ-ÿ]'))));
        // Ponctuation arabe : ni espace avant « : », ni virgule ou point-
        // virgule ou point d'interrogation latins.
        expect(arabe, isNot(contains(' :')));
        expect(arabe, isNot(matches(RegExp('[,;?]'))));
        // Les memes parametres qu'en francais.
        expect(_parametres(arabe), _parametres(fr[cle]!));
      });
    }

    test('terminologie : académie, destinataires, droits de publication', () {
      expect(ar['com.annonces.publieur.nature.toutes'], contains('الأكاديمية'));
      expect(
        ar['com.annonces.administration.matrice.detail'],
        contains('الأكاديمية'),
      );
      for (final String cle in <String>[
        'com.annonces.publieur.etapes.audience',
        'com.annonces.publieur.contexte.audience',
        'com.annonces.publieur.contexte.publication',
        'com.annonces.publieur.manqueAudience',
        'com.annonces.publieur.aucuneCibleTitre',
        'com.annonces.publieur.aucuneCible',
        'com.annonces.administration.matrice.audiences',
      ]) {
        expect(ar[cle], contains('مستلم'), reason: cle);
        expect(ar[cle], isNot(contains('جمهور')), reason: cle);
      }
      for (final String cle in <String>[
        'com.annonces.administration.indicateurs.regles',
        'com.annonces.administration.matrice.titre',
        'com.annonces.administration.matrice.vide',
      ]) {
        expect(ar[cle], contains('صلاحي'), reason: cle);
      }
      // « le code » d'une promotion : un code de reduction, pas un symbole.
      expect(
        ar['com.communaute.garde.reponse.avertissement'],
        contains('رمز الخصم'),
      );
    });
  });

  test('aucune espace avant les deux-points dans tout le fichier arabe', () {
    final List<String> fautes = <String>[
      for (final MapEntry<String, String> e in ar.entries)
        if (e.value.contains(' :')) '${e.key} : ${e.value}',
    ];
    expect(fautes, isEmpty);
  });

  test('« support » (de cours) se dit « مادة », jamais « دعامة »', () {
    final List<String> fautes = <String>[
      for (final MapEntry<String, String> e in ar.entries)
        if (e.value.contains('دعامة')) e.key,
    ];
    expect(fautes, isEmpty);
  });

  test('une virgule arabe apres un parametre est rattachee au texte arabe', () {
    final List<String> fautes = <String>[
      for (final MapEntry<String, String> e in ar.entries)
        if ((e.key.startsWith('com.') || e.key.startsWith('notifications.')) &&
            e.value.contains('}،'))
          '${e.key} : ${e.value}',
    ];
    expect(fautes, isEmpty);
  });

  // Apres revue du lot L.
  test('« الرد » sans chadda, partout (une seule graphie)', () {
    final List<String> fautes = <String>[
      for (final MapEntry<String, String> e in ar.entries)
        if (RegExp('رد[\u064B-\u0650\u0652]*\u0651').hasMatch(e.value))
          '${e.key} : ${e.value}',
    ];
    expect(fautes, isEmpty);
    // Le bloc des reponses de la Communaute, voisin direct du libelle relu.
    for (final String cle in <String>[
      'com.communaute.reponses.envoyer',
      'com.communaute.reponses.nonConfirmee',
      'com.communaute.reponses.reessayer',
      'com.communaute.reponses.signaler',
      'com.communaute.reponses.signalee',
      'com.communaute.reponses.aide',
      'com.communaute.reponses.champVide',
      'com.communaute.publication.choisir',
    ]) {
      expect(ar[cle], contains('رد'), reason: cle);
    }
  });

  test('« planifiée » se dit « مجدول », jamais « مبرمج »', () {
    final List<String> fautes = <String>[
      for (final MapEntry<String, String> e in ar.entries)
        if (e.value.contains('برمج')) '${e.key} : ${e.value}',
    ];
    expect(fautes, isEmpty);
    expect(ar['notifications.types.annoncePlanifiee'], contains('مجدول'));
    expect(ar['com.annonces.demo.f.adminPlanifiee'], contains('مجدول'));
    expect(
      ar['com.annonces.administration.planifiees.titre'],
      contains('المجدولة'),
    );
  });

  test('« trimestre » : « الفصل الدراسي », jamais « هذا الفصل » seul', () {
    final String annonce = ar['com.annonces.demo.f.annonceNourTexte']!;
    expect(annonce, contains('خلال هذا الفصل الدراسي'));
    expect(annonce, isNot(contains('عليها هذا الفصل.')));
  });

  test('la carte de seance et la Classe sont traduites, sans francais', () {
    for (final String prefixe in <String>['tc.groupe.', 'classe.']) {
      final List<String> cles = <String>[
        for (final String cle in fr.keys)
          if (cle.startsWith(prefixe) && !cle.startsWith('classe.entree.demo.'))
            cle,
      ];
      expect(cles, isNotEmpty);
      for (final String cle in cles) {
        final String? arabe = ar[cle];
        expect(arabe, isNotNull, reason: 'cle absente en arabe : $cle');
        final String sansParametres = arabe!.replaceAll(RegExp(r'\{\w+\}'), '');
        expect(
          sansParametres,
          isNot(matches(RegExp('[A-Za-zÀ-ÿ]'))),
          reason: cle,
        );
        if (RegExp(r'\.(zero|one|two|few|many)$').hasMatch(cle)) {
          // Une forme du pluriel arabe peut taire le nombre (« طالبان »,
          // regle de la ligne arabe) mais n'invente aucun parametre.
          expect(
            _parametres(arabe).difference(_parametres(fr[cle]!)),
            isEmpty,
            reason: cle,
          );
        } else {
          expect(_parametres(arabe), _parametres(fr[cle]!), reason: cle);
        }
      }
    }
  });

  group('Rendu de droite a gauche', () {
    setUpAll(() async {
      await LocaleSettings.setLocale(AppLocale.ar);
    });
    tearDownAll(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    Future<RenderParagraph> rendre(WidgetTester tester, String texte) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: Text(texte)),
        ),
      );
      return tester.renderObject<RenderParagraph>(find.text(texte));
    }

    TextBox boite(RenderParagraph p, String texte, String morceau) {
      final int debut = texte.indexOf(morceau);
      return p
          .getBoxesForSelection(
            TextSelection(
              baseOffset: debut,
              extentOffset: debut + morceau.length,
            ),
          )
          .first;
    }

    for (final (String, String Function()) cas in <(String, String Function())>[
      (
        'message vocal de Samira, 0:12',
        () =>
            t.com.vocal.lecteur.libelleAuteur(auteur: 'Samira', duree: '0:12'),
      ),
      (
        'auteur et date d une annonce',
        () => t.com.annonces.auteurDate(
          auteur: 'Mariam',
          date: '4',
          heure: '09:00',
        ),
      ),
      (
        'message de Samira dans un canal',
        () => t.com.studio.recherche.messageDe(
          auteur: 'Samira',
          canal: 'Organisation',
        ),
      ),
    ]) {
      testWidgets('${cas.$1} : la virgule est a gauche du nom latin', (
        WidgetTester tester,
      ) async {
        final String texte = cas.$2();
        expect(texte, contains('،'));
        final String latin = RegExp('[A-Za-z]+').firstMatch(texte)![0]!;
        final RenderParagraph p = await rendre(tester, texte);
        final TextBox nomLatin = boite(p, texte, latin);
        final TextBox virgule = boite(p, texte, '،');
        // De droite a gauche : le nom, puis la virgule, a sa gauche.
        expect(virgule.right, lessThanOrEqualTo(nomLatin.left + 0.5));
      });
    }
  });
}
