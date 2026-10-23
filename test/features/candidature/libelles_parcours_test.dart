// CAND-01 : chaque code que rend le serveur a ses textes, en francais ET en
// arabe (CAND-Q13 : le parcours du candidat est livre en arabe). slang retombe
// en silence sur le francais quand une cle arabe manque : seul ce test le dit.
// Un code sans texte ne s'affiche jamais tel quel.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/disponibilites_declarees.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/libelles_parcours.dart';
import 'package:rewayah_academy/features/candidature/modele_questions.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';

/// Les cles de feuille d'un arbre JSON ; une forme de pluriel compte pour la
/// cle qui la porte (l'arabe en a six, le francais deux).
Set<String> _cles(Object? noeud, [String prefixe = '']) {
  const Set<String> formes = <String>{
    'zero',
    'one',
    'two',
    'few',
    'many',
    'other',
  };
  if (noeud is Map<String, dynamic>) {
    if (noeud.isNotEmpty && noeud.keys.every(formes.contains)) {
      return <String>{prefixe};
    }
    return <String>{
      for (final MapEntry<String, dynamic> e in noeud.entries)
        ..._cles(e.value, prefixe.isEmpty ? e.key : '$prefixe.${e.key}'),
    };
  }
  return <String>{prefixe};
}

Object? _sousArbre(Map<String, dynamic> racine, List<String> chemin) {
  Object? noeud = racine;
  for (final String c in chemin) {
    noeud = (noeud! as Map<String, dynamic>)[c];
  }
  return noeud;
}

void main() {
  final Map<String, dynamic> fr = jsonDecode(
    File('assets/i18n/fr.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> ar = jsonDecode(
    File('assets/i18n/ar.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Questionnaire q = Questionnaire.depuisJson(questionnaireJsonDeTest());

  test('chaque cle francaise du parcours a sa traduction arabe', () {
    final List<List<String>> chemins = <List<String>>[
      <String>['recrutement', 'salles'],
      <String>['recrutement', 'paiement'],
      <String>['recrutement', 'portail'],
      <String>['recrutement', 'retrait'],
      <String>['recrutement', 'questionnaire'],
      <String>['recrutement', 'parcours'],
      <String>['accords', 'cadreNonPublie'],
    ];
    int verifiees = 0;
    final List<String> manquantes = <String>[];
    for (final List<String> chemin in chemins) {
      final Set<String> clesFr = _cles(
        _sousArbre(fr, chemin),
        chemin.join('.'),
      );
      final Set<String> clesAr = _cles(
        _sousArbre(ar, chemin),
        chemin.join('.'),
      );
      for (final String c in clesFr) {
        verifiees++;
        if (!clesAr.contains(c)) {
          manquantes.add(c);
        }
      }
    }
    expect(verifiees, greaterThan(300));
    expect(manquantes, isEmpty);
  });

  test('chaque champ du questionnaire a sa forme et ses textes', () {
    expect(questionnaireReconnu(q), isTrue);
    for (final ChampQuestionnaire c in q.champs) {
      expect(titreQuestion(c.code), isNotNull, reason: 'titre de ${c.code}');
      expect(
        explicationQuestion(c.code),
        isNotNull,
        reason: 'explication de ${c.code}',
      );
      expect(nomCourtQuestion(c.code), isNotNull, reason: 'nom de ${c.code}');
    }
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('textes en ${langue.name}', () {
      setUp(() => LocaleSettings.setLocale(langue));
      tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

      test('chaque option a un libelle, jamais le code', () {
        for (final ChampQuestionnaire c in q.champs) {
          final ModeleQuestion m = modelesQuestions[c.code]!;
          if (m.forme == FormeQuestion.choix ||
              m.forme == FormeQuestion.choixMultiple ||
              m.forme == FormeQuestion.riwayat) {
            for (final OptionQuestionnaire o in c.options) {
              final TextesOption? x = textesOption(c.code, o.code);
              expect(x, isNotNull, reason: '${c.code}.${o.code}');
              expect(x!.libelle, isNot(o.code), reason: '${c.code}.${o.code}');
            }
          }
        }
        // Oui et non du compte bancaire (reponse booleenne).
        expect(textesOption('compteBancaire', 'oui'), isNotNull);
        expect(textesOption('compteBancaire', 'non'), isNotNull);
      });

      test(
        'chaque carte de choix se decrit, puis dit ce qu elle entraine ou '
        'donne un exemple',
        () {
          // Directive du directeur du 22/10/2026 : des cartes decrites avec ce
          // que le choix entraine et un exemple, pour des personnes peu a
          // l'aise avec la technologie. Les listes longues (langues, pays,
          // riwayat) se cherchent, elles ne se decrivent pas une a une.
          const Set<FormeQuestion> cartes = <FormeQuestion>{
            FormeQuestion.choix,
            FormeQuestion.choixMultiple,
            FormeQuestion.ouiNon,
          };
          int verifiees = 0;
          for (final ChampQuestionnaire c in q.champs) {
            final FormeQuestion forme = modelesQuestions[c.code]!.forme;
            if (!cartes.contains(forme)) {
              continue;
            }
            final List<String> codes = forme == FormeQuestion.ouiNon
                ? <String>['oui', 'non']
                : <String>[for (final OptionQuestionnaire o in c.options) o.code];
            for (final String code in codes) {
              verifiees++;
              final TextesOption x = textesOption(c.code, code)!;
              final String quoi = '${c.code}.$code';
              expect(x.description, isNotNull, reason: 'description de $quoi');
              expect(
                x.explication != null || x.exemple != null,
                isTrue,
                reason: '$quoi ne dit ni ce qu elle entraine ni un exemple',
              );
            }
          }
          // 4 + 3 + 3 + 2 + 4 + 4 + 2 cartes dans salle-examen-1 : memorisation,
          // tajwid, ijaza, debutants, debut, tranches d'age, compte bancaire.
          expect(verifiees, 22);
        },
      );

      test('les cartes du fuseau et des moyens de paiement disent aussi '
          'ce qu elles entrainent', () {
        final r = t.recrutement.parcours;
        for (final String texte in <String>[
          r.fuseau.ouiExplication,
          r.fuseau.changerExplication,
          r.versement.operateurExplication,
        ]) {
          expect(texte, isNotEmpty);
        }
      });

      test('chaque langue du questionnaire a son nom', () {
        for (final ChampQuestionnaire c in <ChampQuestionnaire>[
          q.champ('langueMaternelle')!,
          q.champ('languesExplication')!,
        ]) {
          for (final OptionQuestionnaire o in c.options) {
            expect(nomDeLangue(o.code), isNotNull, reason: o.code);
            expect(nomDeLangue(o.code), isNot(o.code), reason: o.code);
          }
        }
      });

      test('chaque pays du questionnaire a son nom', () {
        for (final OptionQuestionnaire o in q.champ('paysResidence')!.options) {
          expect(nomDePaysConnu(o.code), isNotNull, reason: o.code);
        }
        expect(paysIso.length, q.champ('paysResidence')!.options.length);
      });

      test('chaque moment de la journee et chaque jour a son nom', () {
        for (final ({String code, int de, int a}) m in momentsDeLaJournee) {
          expect(titreMoment(m.code), isNotEmpty, reason: m.code);
        }
        // Les moments couvrent les 24 heures, sans trou ni doublon.
        final List<int> heures = <int>[
          for (final ({String code, int de, int a}) m in momentsDeLaJournee)
            for (int h = m.de; h <= m.a; h++) h,
        ];
        expect(heures, <int>[for (int h = 0; h < 24; h++) h]);
        for (int j = 1; j <= 7; j++) {
          expect(nomDeJour(j), isNotEmpty);
          expect(nomDeJour(j)[0], nomDeJour(j)[0].toUpperCase());
        }
      });

      test('les heures et les durees se disent dans la langue lue', () {
        expect(libelleHeure(18), isNot('18'));
        expect(libelleDuree(90), isNot(libelleDuree(60)));
        expect(
          libelleIntervalle(const IntervalleCours(1080, 1170)),
          allOf(contains('18'), contains('19')),
        );
        // Un cours qui passe minuit finit le lendemain.
        expect(libelleInstant(1470), libelleInstant(30));
      });

      test('le nombre de Classes, le public et les moyens ont leurs textes', () {
        final r = t.recrutement.parcours;
        for (final int n in <int>[1, 2, 3, 5, 11, 20]) {
          expect(r.classes.libelle(n: n), isNotEmpty, reason: '$n');
          expect(r.classes.seances(n: 3 * n), isNotEmpty, reason: '$n');
          expect(r.classes.exemplePlusieurs(n: n), isNotEmpty, reason: '$n');
          expect(r.recap.jours(n: n % 8), isNotEmpty, reason: '$n');
          expect(r.creneaux.heuresChoisies(n: n), isNotEmpty, reason: '$n');
        }
        for (final String texte in <String>[
          r.classes.explication,
          r.classes.exemple1,
          r.classes.exemple2,
          r.moyens.mobile,
          r.moyens.virement,
          r.moyens.explication,
          r.moyens.nonElimine,
          r.choisirJour,
          r.choisirHeure,
          r.langues.chercher,
          r.langues.autreDescription,
          t.recrutement.questionnaire.continuite,
          t.recrutement.questionnaire.plagesChevauchent,
        ]) {
          expect(texte, isNotEmpty);
        }
      });

      test('un code inconnu n a pas de texte : il ne s affiche pas', () {
        expect(textesOption('riwayat', 'inventee'), isNull);
        expect(nomDeLangue('xx'), isNull);
        expect(nomDePaysConnu('ZZ'), isNull);
        expect(titreQuestion('champInconnu'), isNull);
      });
    });
  }

  test('en arabe, la paie se dit « الراتب », jamais « أجر »', () {
    // Decision du directeur du 22/10/2026 : « أجر » evoque la recompense
    // d'Allah. Le seul texte qui contient ces lettres est un autre mot
    // (« سأجربه », « je l'essaierai »), dans un message d'exemple.
    final List<String> fautes = <String>[];
    void parcourir(Object? noeud, String chemin) {
      if (noeud is Map<String, dynamic>) {
        noeud.forEach((String k, dynamic v) => parcourir(v, '$chemin.$k'));
      } else if (noeud is String && noeud.contains('أجر')) {
        if (!noeud.contains('سأجربه')) {
          fautes.add('$chemin : $noeud');
        }
      }
    }

    parcourir(ar, '');
    expect(fautes, isEmpty);
    // Et les textes de la paie du parcours disent bien « الراتب ».
    final String conditions = jsonEncode(
      _sousArbre(ar, <String>['recrutement', 'questionnaire']),
    );
    expect(conditions, contains('شروط الراتب'));
    expect(conditions, contains('الراتب'));
  });

  test('aucun mot interdit par mots-rewayah dans le questionnaire', () {
    // `.claude/skills/mots-rewayah`, section 6 : les mots qu'on n'ecrit jamais.
    final RegExp interdits = RegExp(
      r'mode enfant|cours en cours|ajouter un enfant|essentiel|palier|'
      r'fondations|majlis|tilawah|hifz|échec|maîtrisé|gratuit|garanti|'
      r'certifié|\badmin\b|\bgroupe\b|—',
      caseSensitive: false,
    );
    final List<String> fautes = <String>[];
    void parcourir(Object? noeud, String chemin) {
      if (noeud is Map<String, dynamic>) {
        noeud.forEach((String k, dynamic v) => parcourir(v, '$chemin.$k'));
      } else if (noeud is String && interdits.hasMatch(noeud)) {
        fautes.add('$chemin : $noeud');
      }
    }

    parcourir(
      _sousArbre(fr, <String>['recrutement', 'parcours']),
      'recrutement.parcours',
    );
    parcourir(
      _sousArbre(fr, <String>['recrutement', 'questionnaire']),
      'recrutement.questionnaire',
    );
    parcourir(_sousArbre(fr, <String>['admin', 'regles']), 'admin.regles');
    expect(fautes, isEmpty);
  });

  test('« Classe » prend sa majuscule partout dans le parcours du candidat', () {
    // Les reponses du directeur du 22/10/2026 l'ecrivent ainsi (« Combien de
    // Classes voulez-vous tenir ? ») : une meme question ne dit pas « classe »
    // sur un ecran et « Classe » sur le suivant.
    final RegExp minuscule = RegExp(r'\bclasses?\b');
    final List<String> fautes = <String>[];
    void parcourir(Object? noeud, String chemin) {
      if (noeud is Map<String, dynamic>) {
        noeud.forEach((String k, dynamic v) => parcourir(v, '$chemin.$k'));
      } else if (noeud is String && minuscule.hasMatch(noeud)) {
        fautes.add('$chemin : $noeud');
      }
    }

    parcourir(
      _sousArbre(fr, <String>['recrutement', 'parcours']),
      'recrutement.parcours',
    );
    parcourir(
      _sousArbre(fr, <String>['recrutement', 'questionnaire']),
      'recrutement.questionnaire',
    );
    expect(fautes, isEmpty);
  });

  test('les tailles de Classe disent aussi le plafond des debutants', () {
    // 5 enfants, 6 adultes, 4 debutants au plus (programme-rewayah, section 9).
    for (final String tranche in <String>[
      'o_6_9',
      'o_10_13',
      'o_14_17',
      'adultes',
    ]) {
      for (final (String nom, Map<String, dynamic> arbre) in <(String, Map<String, dynamic>)>[
        ('fr', fr),
        ('ar', ar),
      ]) {
        final Object? explication = _sousArbre(arbre, <String>[
          'recrutement',
          'parcours',
          'q',
          'publics',
          'options',
          tranche,
          'explication',
        ]);
        expect(
          explication,
          contains('4'),
          reason: 'le plafond des debutants manque en $nom pour $tranche',
        );
      }
    }
  });

  test('aucun texte du parcours ne contient un montant ni un code interne', () {
    final String brut = jsonEncode(
      _sousArbre(fr, <String>['recrutement', 'questionnaire']),
    );
    // Aucun montant en dollars, aucun taux par heure.
    expect(brut, isNot(contains(r'$')));
    expect(brut, isNot(contains('1,99')));
    expect(brut, isNot(contains('1,57')));
    expect(brut, isNot(contains('CAND-')));
    expect(brut, isNot(contains('CAND-BR')));
  });
}
