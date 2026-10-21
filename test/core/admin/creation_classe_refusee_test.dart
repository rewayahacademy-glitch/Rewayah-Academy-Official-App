// CAND-Q15, lot creer_groupe (21/10/2026) : un refus de `creer_groupe` par
// le serveur devient un motif ferme, puis une phrase par motif, en francais
// et en arabe ; jamais le texte SQL.
//
// Les messages du serveur ne sont pas recopies a la main : le test lit, dans
// `supabase/migrations/` (dans l'ordre ou la CI les applique), la derniere
// definition de `public.creer_groupe` et de
// `app_private.verifier_affectation_enseignant`, et en extrait chaque
// litteral de RAISE EXCEPTION. Un message change, ajoute ou retire cote
// serveur fait echouer le groupe « Messages lus dans les migrations » : il
// faut alors le classer ci-dessous (motif joignable, ou hors d'atteinte de
// l'ecran avec sa raison).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creation_classe_refusee.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_groupes/refus_creation_classe_libelles.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Les migrations, lues depuis la racine du paquet (dossier courant de
/// `flutter test`), comme `test/support/cahier_sourates.dart`.
const String _dossierMigrations = 'supabase/migrations';

/// La migration de ce lot : la definition lue ne peut pas etre plus ancienne.
const String _migrationDuLot =
    '20261021210200_creer_groupe_predicat_affectation.sql';

/// Les deux fonctions dont les refus atteignent la feuille Classes.
const String _creerGroupe = 'public.creer_groupe';
const String _predicat = 'app_private.verifier_affectation_enseignant';

/// Les messages que la feuille peut recevoir, tels que le serveur les leve
/// (`%` pour un parametre de format), avec leur motif. Aucun n'est inconnu.
const Map<String, MotifRefusCreationClasse> _joignables =
    <String, MotifRefusCreationClasse>{
      "creation de groupe reservee a l'administration":
          MotifRefusCreationClasse.reservee,
      "cet enseignant n'existe pas ou son compte n'est pas valide":
          MotifRefusCreationClasse.compteEnseignant,
      'enseignant indisponible ou genre inconnu':
          MotifRefusCreationClasse.enseignantNonEligible,
      'enseignant incompatible avec le public de la classe':
          MotifRefusCreationClasse.genreIncompatible,
      'plafond horaire enseignant dépassé': MotifRefusCreationClasse.plafond,
      'chevauchement avec une classe ou affectation active':
          MotifRefusCreationClasse.chevauchementClasse,
      'chevauchement avec une séance existante':
          MotifRefusCreationClasse.chevauchementSeance,
    };

/// Les messages que l'ecran ne peut pas provoquer, avec la raison : ils
/// donnent la phrase generique, jamais leur texte.
const Map<String, String> _horsEcran = <String, String>{
  'fuseau IANA inconnu : %': 'le fuseau part nul (p_timezone_iana null)',
  'type de public inconnu : %': 'le public vient de TypePublicGroupe',
  'classe ou enseignant absent':
      "la classe vient d'etre creee et l'enseignant existe",
  'classe indisponible': "la classe vient d'etre creee, non close",
  'enseignant non disponible: jour %, heure %, fuseau %, semaine %, '
          'instant %':
      'creer_groupe passe false : disponibilites non exigees',
};

/// Un message concret tire d'un modele : chaque `%` recoit une valeur.
String _exemple(String modele) => modele.replaceAll('%', '1');

/// Le corps de la derniere definition de [fonction] (nom qualifie) et le
/// fichier qui la porte, dans l'ordre des noms (celui de la CI).
({String fichier, String corps}) _derniereDefinition(String fonction) {
  final List<File> fichiers =
      Directory(_dossierMigrations)
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  final RegExp creation = RegExp(
    r'create\s+(?:or\s+replace\s+)?function\s+' +
        RegExp.escape(fonction) +
        r'\s*\(',
    caseSensitive: false,
  );
  final RegExp ouverture = RegExp(
    r'\bas\s+(\$[a-z_0-9]*\$)',
    caseSensitive: false,
  );
  ({String fichier, String corps})? derniere;
  for (final File f in fichiers) {
    final String sql = f.readAsStringSync();
    for (final RegExpMatch m in creation.allMatches(sql)) {
      final RegExpMatch o = ouverture.firstMatch(sql.substring(m.end))!;
      final String balise = o.group(1)!;
      final int debut = m.end + o.end;
      final int fin = sql.indexOf(balise, debut);
      expect(fin, greaterThan(debut), reason: '${f.path} : corps non ferme');
      derniere = (
        fichier: f.uri.pathSegments.last,
        corps: sql.substring(debut, fin),
      );
    }
  }
  expect(derniere, isNotNull, reason: '$fonction introuvable');
  return derniere!;
}

/// Les litteraux de RAISE EXCEPTION d'un corps PL/pgSQL, quotes doublees
/// rendues simples.
List<String> _messagesLeves(String corps) => <String>[
  for (final RegExpMatch m in RegExp(
    r"raise\s+exception\s+'((?:[^']|'')*)'",
    caseSensitive: false,
  ).allMatches(corps))
    m.group(1)!.replaceAll("''", "'"),
];

/// Les messages de [_joignables] et [_horsEcran], rendus concrets.
final List<String> _messagesServeur = <String>[
  for (final String m in <String>[..._joignables.keys, ..._horsEcran.keys])
    _exemple(m),
];

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Messages lus dans les migrations', () {
    late ({String fichier, String corps}) creer;
    late ({String fichier, String corps}) predicat;
    late List<String> leves;

    setUpAll(() {
      creer = _derniereDefinition(_creerGroupe);
      predicat = _derniereDefinition(_predicat);
      leves = <String>[
        ..._messagesLeves(creer.corps),
        ..._messagesLeves(predicat.corps),
      ];
    });

    test('les definitions lues sont celles de ce lot ou plus recentes', () {
      expect(creer.fichier.compareTo(_migrationDuLot), greaterThanOrEqualTo(0));
      expect(
        predicat.fichier.compareTo(_migrationDuLot),
        greaterThanOrEqualTo(0),
      );
    });

    test('creer_groupe appelle le predicat sans exiger les disponibilites '
        '(raison du dernier message hors ecran)', () {
      expect(
        creer.corps,
        matches(
          RegExp(
            RegExp.escape(_predicat) + r'\s*\([^)]*,\s*false\s*\)',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('chaque message leve est classe ici, et rien d\'autre', () {
      expect(leves, isNotEmpty);
      expect(
        leves.toSet(),
        <String>{..._joignables.keys, ..._horsEcran.keys},
        reason:
            'un message de $_creerGroupe ou de $_predicat a change : '
            'le classer dans _joignables ou _horsEcran',
      );
    });

    test('chaque message joignable leve par le serveur a son motif, jamais '
        'inconnu', () {
      for (final String leve in leves) {
        if (_horsEcran.containsKey(leve)) continue;
        final MotifRefusCreationClasse motif = motifRefusCreationClasse(
          code: 'P0001',
          message: _exemple(leve),
        );
        expect(motif, isNot(MotifRefusCreationClasse.inconnu), reason: leve);
        expect(motif, _joignables[leve], reason: leve);
      }
    });
  });

  group('Motif d\'un refus de creer_groupe (fonction pure)', () {
    for (final MapEntry<String, MotifRefusCreationClasse> e
        in _joignables.entries) {
      test('« ${e.key} » -> ${e.value.name}', () {
        expect(
          motifRefusCreationClasse(code: 'P0001', message: _exemple(e.key)),
          e.value,
        );
      });
    }

    for (final MapEntry<String, String> e in _horsEcran.entries) {
      test('« ${e.key} » -> inconnu (${e.value})', () {
        expect(
          motifRefusCreationClasse(code: 'P0001', message: _exemple(e.key)),
          MotifRefusCreationClasse.inconnu,
        );
      });
    }

    test('SQLSTATE 42501 (droit EXECUTE retire) : reservee, quel que soit '
        'le message', () {
      expect(
        motifRefusCreationClasse(
          code: '42501',
          message: 'permission denied for function creer_groupe',
        ),
        MotifRefusCreationClasse.reservee,
      );
    });

    test('casse et espaces autour du message ne changent rien', () {
      expect(
        motifRefusCreationClasse(
          code: null,
          message: '  PLAFOND HORAIRE ENSEIGNANT DÉPASSÉ ',
        ),
        MotifRefusCreationClasse.plafond,
      );
    });
  });

  group('Traduction a la frontiere Supabase', () {
    test('une PostgrestException devient CreationClasseRefusee, avec son '
        'motif, et rien du texte SQL', () async {
      Object? leve;
      try {
        await traduireRefusCreationClasse<String>(
          () async => throw const PostgrestException(
            message: 'chevauchement avec une séance existante',
            code: 'P0001',
          ),
        );
      } on Object catch (e) {
        leve = e;
      }
      expect(leve, isA<CreationClasseRefusee>());
      final CreationClasseRefusee refus = leve! as CreationClasseRefusee;
      expect(refus.motif, MotifRefusCreationClasse.chevauchementSeance);
      expect(refus.toString(), isNot(contains('séance existante')));
    });

    test('une autre erreur (reseau) passe telle quelle : ce n\'est pas un '
        'refus', () async {
      final Exception reseau = Exception('connexion coupee');
      await expectLater(
        traduireRefusCreationClasse<String>(() async => throw reseau),
        throwsA(same(reseau)),
      );
    });

    test('une reponse rendue passe telle quelle', () async {
      expect(
        await traduireRefusCreationClasse<String>(() async => 'id-classe'),
        'id-classe',
      );
    });
  });

  group('Une phrase par motif, en francais et en arabe', () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      test('${langue.languageCode} : phrases non vides, toutes differentes, '
          'sans texte SQL', () async {
        await LocaleSettings.setLocale(langue);
        final List<String> phrases = <String>[
          for (final MotifRefusCreationClasse m
              in MotifRefusCreationClasse.values)
            phraseRefusCreationClasse(m),
        ];
        expect(phrases.every((String p) => p.trim().isNotEmpty), isTrue);
        expect(phrases.toSet(), hasLength(phrases.length));
        for (final String p in phrases) {
          for (final String sql in _messagesServeur) {
            expect(p, isNot(contains(sql)));
          }
          expect(p, isNot(contains('\u2014')));
          expect(p.toLowerCase(), isNot(contains('admin')));
        }
      });
    }

    test('l\'arabe a ses propres phrases (aucun retour silencieux au '
        'francais)', () async {
      await LocaleSettings.setLocale(AppLocale.fr);
      final List<String> fr = <String>[
        for (final MotifRefusCreationClasse m
            in MotifRefusCreationClasse.values)
          phraseRefusCreationClasse(m),
      ];
      await LocaleSettings.setLocale(AppLocale.ar);
      for (final (int i, MotifRefusCreationClasse m)
          in MotifRefusCreationClasse.values.indexed) {
        expect(phraseRefusCreationClasse(m), isNot(fr[i]));
      }
      expect(
        t.admin.groupes.formulaire.raisonGenreInconnu,
        isNot(contains('Genre non renseigné')),
      );
      expect(
        t.admin.groupes.formulaire.manqueEnseignantGenreInconnu(nom: 'X'),
        contains('X'),
      );
    });
  });
}
