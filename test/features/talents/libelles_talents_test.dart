// CAND-07 : les textes de « Vos autres talents », en francais et en arabe. Ce que
// le test prouve :
// - chacune des 25 competences du catalogue a son libelle, sa description et son
//   exemple (sauf « Autre domaine », qui n'a pas d'exemple), dans les deux
//   langues : le parcours est en francais ET en arabe (decision du 21/10) ;
// - chaque cle francaise de `recrutement.talents` et des lignes de la direction a
//   sa cle arabe (slang retombe en silence sur le francais : seul ce test le
//   montre) ;
// - aucun mot interdit (`mots-rewayah`) : ni « groupe », ni « admin », ni
//   « gratuit », ni « garanti », ni tiret long, ni emoji, ni montant, ni
//   pourcentage : « chaque mission aura ses conditions » ;
// - aucun code ne s'affiche : une famille, un niveau, une disponibilite se
//   disent par leur libelle.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/talents/libelles_talents.dart';

import '../../fixtures/candidature/faux_autres_competences.dart';

/// Toutes les valeurs texte de [noeud], avec leur chemin.
Iterable<MapEntry<String, String>> _valeurs(
  Object? noeud, [
  String prefixe = '',
]) sync* {
  if (noeud is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> e in noeud.entries) {
      yield* _valeurs(e.value, prefixe.isEmpty ? e.key : '$prefixe.${e.key}');
    }
  } else if (noeud is String) {
    yield MapEntry<String, String>(prefixe, noeud);
  }
}

Map<String, dynamic> _fichier(String langue) =>
    jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
        as Map<String, dynamic>;

/// Le sous-arbre `chemin` d'un fichier de traductions.
Object? _sous(Map<String, dynamic> racine, List<String> chemin) {
  Object? courant = racine;
  for (final String cle in chemin) {
    courant = (courant! as Map<String, dynamic>)[cle];
  }
  return courant;
}

final RegExp _arabe = RegExp(r'[؀-ۿ]');
final RegExp _emoji = RegExp(
  '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
  unicode: true,
);
final RegExp _tiretLong = RegExp('[—–]');

const List<List<String>> _blocs = <List<String>>[
  <String>['recrutement', 'talents'],
  <String>['admin', 'candidatures', 'detail', 'talents'],
  <String>['admin', 'candidatures', 'filtres', 'talents'],
];

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('les 25 competences du catalogue', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      test('${langue.languageCode} : libelle, description, exemple', () async {
        await LocaleSettings.setLocale(langue);
        for (final (String, String, int, String, String) c
            in catalogueInitialDeTest) {
          final TextesCompetence? textes = textesCompetenceConnue(c.$1);
          expect(textes, isNotNull, reason: 'texte absent : ${c.$1}');
          expect(textes!.libelle, isNotEmpty, reason: c.$1);
          expect(textes.description, isNotEmpty, reason: c.$1);
          if (c.$1 == 'autre') {
            // La competence au texte libre : le champ dit le reste.
            expect(textes.exemple, isNull);
          } else {
            expect(textes.exemple, isNotEmpty, reason: c.$1);
            // La carte ajoute « Par exemple » : le texte ne le redit pas.
            expect(textes.exemple, isNot(startsWith('Par exemple')));
          }
          if (langue == AppLocale.ar) {
            expect(_arabe.hasMatch(textes.libelle), isTrue, reason: c.$1);
            expect(_arabe.hasMatch(textes.description!), isTrue, reason: c.$1);
          }
        }
      });
    }

    test(
      'le libelle francais reprend celui de la direction, sauf « groupe »',
      () async {
        await LocaleSettings.setLocale(AppLocale.fr);
        for (final (String, String, int, String, String) c
            in catalogueInitialDeTest) {
          final String libelle = textesCompetenceConnue(c.$1)!.libelle;
          if (c.$1 == 'coordination_groupe') {
            // « Classe, jamais groupe » (mots-rewayah) : l'application dit
            // « communaute », le catalogue de la direction garde son mot.
            expect(libelle, isNot(contains('groupe')));
          } else if (c.$1 == 'autre') {
            expect(libelle, 'Autre domaine');
          } else {
            expect(libelle, c.$4, reason: c.$1);
          }
        }
      },
    );

    test('un code que l application ne connait pas prend le catalogue', () {
      const EntreeCatalogue e = EntreeCatalogue(
        code: 'moderation_forum',
        familleCode: 'administration',
        ordre: 6,
        libelle: 'Modération du forum',
        exemple: 'Relire les messages',
        actif: true,
      );
      final TextesCompetence t = textesCompetence(e);
      expect(t.libelle, 'Modération du forum');
      expect(t.exemple, 'Relire les messages');
      expect(textesCompetenceConnue('moderation_forum'), isNull);
    });

    test(
      'un code connu prend les mots de l application, pas ceux du catalogue',
      () async {
        await LocaleSettings.setLocale(AppLocale.ar);
        const EntreeCatalogue e = EntreeCatalogue(
          code: 'comptabilite',
          familleCode: 'finances_droit',
          ordre: 1,
          libelle: 'Comptabilité',
          actif: true,
        );
        expect(textesCompetence(e).libelle, isNot('Comptabilité'));
        expect(_arabe.hasMatch(textesCompetence(e).libelle), isTrue);
      },
    );
  });

  group('familles, niveaux, disponibilites : jamais un code', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      test(langue.languageCode, () async {
        await LocaleSettings.setLocale(langue);
        final Set<String> libelles = <String>{};
        for (final FamilleCompetence f in FamilleCompetence.values) {
          final String titre = titreFamille(f);
          expect(titre, isNotEmpty);
          expect(titre, isNot(f.valeurSql));
          libelles.add(titre);
        }
        expect(libelles, hasLength(6), reason: 'deux familles, un meme titre');
        for (final NiveauCompetence n in NiveauCompetence.values) {
          expect(libelleNiveau(n), isNot(n.valeurSql));
          expect(descriptionNiveau(n), isNotEmpty);
          expect(libelleNiveauDirection(n), isNotEmpty);
        }
        for (final DisponibiliteMission d in DisponibiliteMission.values) {
          expect(libelleDisponibilite(d), isNot(d.valeurSql));
          expect(descriptionDisponibilite(d), isNotEmpty);
        }
      });
    }

    test('les mots du directeur (22/10) : les trois niveaux', () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      expect(libelleNiveau(NiveauCompetence.debutant), 'Je débute');
      expect(
        libelleNiveau(NiveauCompetence.experience),
        "J'ai de l'expérience",
      );
      expect(libelleNiveau(NiveauCompetence.metier), "C'est mon métier");
    });

    test('les familles du directeur, dans l ordre du serveur', () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      expect(
        <String>[
          for (final FamilleCompetence f in FamilleCompetence.values)
            titreFamille(f),
        ],
        <String>[
          'Communication et image',
          'Administration et organisation',
          'Finances et droit',
          'Pédagogie',
          'Technique',
          'Autre domaine',
        ],
      );
    });

    test(
      'un domaine de filtre se dit par son nom, famille ou competence',
      () async {
        await LocaleSettings.setLocale(AppLocale.fr);
        expect(nomDomaineFiltre('finances_droit'), 'Finances et droit');
        expect(nomDomaineFiltre('comptabilite'), 'Comptabilité');
        expect(nomDomaineFiltre('autre'), 'Autre domaine');
        // Un code inconnu, sans catalogue : une phrase neutre, jamais le code.
        expect(
          nomDomaineFiltre('moderation_forum'),
          isNot(contains('moderation')),
        );
      },
    );
  });

  group('le fichier arabe suit le francais', () {
    for (final List<String> chemin in _blocs) {
      test(chemin.join('.'), () {
        final Set<String> fr = <String>{
          for (final MapEntry<String, String> e in _valeurs(
            _sous(_fichier('fr'), chemin),
          ))
            e.key,
        };
        final Set<String> ar = <String>{
          for (final MapEntry<String, String> e in _valeurs(
            _sous(_fichier('ar'), chemin),
          ))
            e.key,
        };
        // L'arabe a six formes de pluriel, le francais deux : on compare sans
        // les categories qui n'existent que d'un cote.
        bool pluriel(String c) =>
            c.endsWith('.zero') ||
            c.endsWith('.one') ||
            c.endsWith('.two') ||
            c.endsWith('.few') ||
            c.endsWith('.many') ||
            c.endsWith('.other');
        expect(
          fr.where((String c) => !pluriel(c)).toSet().difference(ar),
          isEmpty,
          reason: 'cles sans arabe',
        );
        expect(
          ar.where((String c) => !pluriel(c)).toSet().difference(fr),
          isEmpty,
          reason: 'cles arabes sans francais',
        );
        // Chaque texte arabe contient de l'arabe (jamais le francais recopie),
        // sauf un texte fait seulement de ses parametres.
        for (final MapEntry<String, String> e in _valeurs(
          _sous(_fichier('ar'), chemin),
        )) {
          final String sansParametres = e.value.replaceAll(
            RegExp(r'\{[^}]*\}'),
            '',
          );
          if (RegExp(r'[A-Za-z]').hasMatch(sansParametres)) {
            fail('du latin dans le texte arabe ${e.key} : ${e.value}');
          }
          if (RegExp(r'\p{L}', unicode: true).hasMatch(sansParametres)) {
            expect(_arabe.hasMatch(sansParametres), isTrue, reason: e.key);
          }
        }
      });
    }

    test('les six formes de pluriel du compteur de competences', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      final r = t.recrutement.talents.competences;
      // Sans le nombre : une forme par categorie (zero, one, two, few, many ;
      // `other` redit `many`).
      final Set<String> formes = <String>{
        for (final int n in <int>[0, 1, 2, 3, 11, 100])
          r.choisies(n: n).replaceAll(RegExp(r'[0-9\u2068\u2069]'), '').trim(),
      };
      expect(
        formes,
        hasLength(5),
        reason: 'zero, one, two, few, many ou other',
      );
    });
  });

  group('les mots du directeur', () {
    for (final String langue in <String>['fr', 'ar']) {
      test('$langue : aucun mot interdit, aucun montant', () {
        for (final List<String> chemin in _blocs) {
          for (final MapEntry<String, String> e in _valeurs(
            _sous(_fichier(langue), chemin),
          )) {
            final String v = e.value;
            final String ou = '${chemin.join('.')}.${e.key} : $v';
            expect(_tiretLong.hasMatch(v), isFalse, reason: 'tiret long : $ou');
            expect(_emoji.hasMatch(v), isFalse, reason: 'emoji : $ou');
            expect(v, isNot(contains(r'$')), reason: 'montant : $ou');
            expect(v, isNot(contains('€')), reason: 'montant : $ou');
            expect(v, isNot(contains('%')), reason: 'pourcentage : $ou');
            if (langue == 'fr') {
              expect(
                RegExp(
                  r'\b(groupes?|admin|gratuit|gratuite|garanti|garantie|certifi\w+|échec|ijaza)\b',
                  caseSensitive: false,
                ).hasMatch(v),
                isFalse,
                reason: ou,
              );
              // L'espace avant « : ; ? ! » est insecable (regle du depot).
              expect(RegExp(r'[ ][?!:;»]|« ').hasMatch(v), isFalse, reason: ou);
            }
          }
        }
      });
    }

    test('l introduction dit pourquoi, avant de demander (22/10)', () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      final String texte = t.recrutement.talents.intro.texte;
      expect(texte, contains("L'académie grandit."));
      expect(texte, contains('avant de publier une annonce'));
      expect(
        t.recrutement.talents.tuile.facultatif,
        "Facultatif. Cela ne change rien à votre candidature d'enseignant.",
      );
    });

    test('l accord est la phrase du directeur', () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      expect(
        t.recrutement.talents.disponibilite.accord,
        "J'accepte que l'académie me contacte pour une mission dans ces "
        'domaines.',
      );
    });

    test(
      'rien sur le salaire d une mission : chaque mission a ses conditions',
      () async {
        await LocaleSettings.setLocale(AppLocale.fr);
        final String toutes = <String>[
          for (final List<String> chemin in _blocs)
            for (final MapEntry<String, String> e in _valeurs(
              _sous(_fichier('fr'), chemin),
            ))
              e.value,
        ].join(' ').toLowerCase();
        for (final String mot in <String>[
          'salaire',
          'rémunération',
          'paie',
          'tarif',
          'euro',
          'dollar',
        ]) {
          expect(RegExp('\\b$mot\\b').hasMatch(toutes), isFalse, reason: mot);
        }
        expect(
          t.recrutement.talents.intro.missions.titre,
          'Chaque mission a ses conditions',
        );
      },
    );
  });
}
