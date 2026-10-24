// FI-DEV-1 (21/10/2026, lot gnf de CAND-Q15) : une seule table des decimales
// des devises (ISO 4217).
//
// Le serveur fait foi : `private.devise_decimales` porte la table et
// `public.x217_montant_ref` s'en sert pour la reference USD de la tresorerie.
// Le client en garde un miroir, `decimalesHorsDefaut`, pour formater et saisir
// hors ligne. Ce test lit la derniere migration qui definit la fonction (la
// donnee du depot, jamais une liste recopiee) et compare les deux tables :
// avant ce lot, le client donnait 0 decimale au GNF et le serveur 2, si bien
// que 1 823 200 GNF valaient 2,12 $ en tresorerie au lieu de 212,00 $.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';

/// L'espace insecable entre le nombre et la devise (U+00A0), comme
/// `format_montant.dart`.
const String _insecable = ' ';

/// L'espace fine insecable des milliers (U+202F), comme `format_montant.dart`.
const String _milliers = ' ';

/// Le nom de la derniere migration (ordre d'application : tri par nom) qui
/// definit `private.devise_decimales`, et le corps de cette definition.
({String fichier, String corps}) _derniereDefinition() {
  final List<File> migrations =
      Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  final RegExp entete = RegExp(
    r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+private\.devise_decimales\s*\(',
    caseSensitive: false,
  );
  final RegExp corps = RegExp(
    r'\bAS\s+(\$\w*\$)(.*?)\1',
    caseSensitive: false,
    dotAll: true,
  );
  for (final File f in migrations.reversed) {
    final String sql = f.readAsStringSync();
    final Iterable<RegExpMatch> definitions = entete.allMatches(sql);
    if (definitions.isEmpty) continue;
    final RegExpMatch? m = corps.firstMatch(
      sql.substring(definitions.last.end),
    );
    if (m == null) {
      fail('${f.path} : corps de private.devise_decimales introuvable');
    }
    return (fichier: f.uri.pathSegments.last, corps: m.group(2)!);
  }
  fail('aucune migration ne definit private.devise_decimales');
}

/// La table du serveur : chaque `WHEN p_devise IN (...) THEN n` du corps.
Map<String, int> _tableServeur(String corps) {
  final String sansCommentaires = corps.replaceAll(RegExp(r'--[^\n]*'), '');
  final RegExp quand = RegExp(
    r'WHEN\s+p_devise\s+IN\s*\(([^)]*)\)\s*THEN\s+(\d+)',
    caseSensitive: false,
  );
  final RegExp code = RegExp(r"'([A-Z]{3})'");
  final List<RegExpMatch> branches = quand
      .allMatches(sansCommentaires)
      .toList();
  // Toute branche doit avoir la forme lue : une autre forme (`= 'XXX'`,
  // `LIKE`...) echapperait a la comparaison.
  expect(
    RegExp(
      r'\bWHEN\b',
      caseSensitive: false,
    ).allMatches(sansCommentaires).length,
    branches.length,
    reason: 'chaque WHEN de private.devise_decimales doit etre un IN (...)',
  );
  expect(
    RegExp(
      r'\bELSE\s+2\s+END\b',
      caseSensitive: false,
    ).hasMatch(sansCommentaires),
    isTrue,
    reason: 'private.devise_decimales doit rendre 2 par defaut',
  );
  final Map<String, int> table = <String, int>{};
  for (final RegExpMatch b in branches) {
    final int decimales = int.parse(b.group(2)!);
    for (final RegExpMatch c in code.allMatches(b.group(1)!)) {
      final String devise = c.group(1)!;
      expect(
        table.containsKey(devise),
        isFalse,
        reason: '$devise apparait deux fois dans private.devise_decimales',
      );
      table[devise] = decimales;
    }
  }
  return table;
}

void main() {
  group('miroir de private.devise_decimales', () {
    late ({String fichier, String corps}) definition;
    late Map<String, int> serveur;

    setUpAll(() {
      definition = _derniereDefinition();
      serveur = _tableServeur(definition.corps);
    });

    test('la table est lue dans la derniere migration qui la definit', () {
      expect(
        definition.fichier.compareTo(
              '20261021210300_fi_devises_decimales_iso4217.sql',
            ) >=
            0,
        isTrue,
        reason: definition.fichier,
      );
      // Garde contre une comparaison vide : la lecture a trouve la table.
      expect(serveur['GNF'], 0);
      expect(serveur.length, greaterThanOrEqualTo(26));
    });

    test('decimalesHorsDefaut est exactement la table du serveur', () {
      expect(
        decimalesHorsDefaut,
        equals(serveur),
        reason:
            'lib/core/finance/format_montant.dart et '
            '${definition.fichier} divergent',
      );
    });

    test('decimalesDe suit la table et rend 2 par defaut', () {
      for (final MapEntry<String, int> e in serveur.entries) {
        expect(decimalesDe(e.key), e.value, reason: e.key);
      }
      expect(serveur.values, isNot(contains(2)));
      for (final String devise in const <String>[
        'USD',
        'EUR',
        'GBP',
        'CAD',
        'XTS',
      ]) {
        expect(serveur.containsKey(devise), isFalse, reason: devise);
        expect(decimalesDe(devise), 2, reason: devise);
      }
    });
  });

  group('table ISO 4217 complete (exposants 0, 3 et 4)', () {
    test('exposant 0 : aucune decimale', () {
      for (final String devise in const <String>[
        'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', //
        'RWF', 'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
      ]) {
        expect(decimalesDe(devise), 0, reason: devise);
        expect(
          formaterMontant(Montant(500, devise)),
          '500$_insecable$devise',
          reason: devise,
        );
      }
    });

    test('exposant 3 : trois decimales', () {
      for (final String devise in const <String>[
        'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND', //
      ]) {
        expect(decimalesDe(devise), 3, reason: devise);
        expect(
          formaterMontant(Montant(1500, devise)),
          '1,500$_insecable$devise',
          reason: devise,
        );
      }
    });

    test('exposant 4 : quatre decimales', () {
      for (final String devise in const <String>['CLF', 'UYW']) {
        expect(decimalesDe(devise), 4, reason: devise);
        expect(
          formaterMontant(Montant(12345, devise)),
          '1,2345$_insecable$devise',
          reason: devise,
        );
      }
    });

    test('exposant 2 par defaut (EUR, XTS)', () {
      expect(formaterMontant(const Montant(1250, 'EUR')), '12,50$_insecable€');
      expect(
        formaterMontant(const Montant(-5, 'XTS')),
        '${signeMoins}0,05${_insecable}XTS',
      );
    });

    test('les decimales seulement quand il y en a', () {
      expect(formaterMontant(const Montant(1000, 'KWD')), '1${_insecable}KWD');
      expect(
        formaterMontant(const Montant(1005, 'BHD')),
        '1,005${_insecable}BHD',
      );
      expect(
        formaterMontant(const Montant(10001, 'CLF')),
        '1,0001${_insecable}CLF',
      );
    });
  });

  group('le franc guineen', () {
    test('1 823 200 GNF : espace fine aux milliers, insecable avant le code, '
        'aucune virgule', () {
      final String texte = formaterMontant(const Montant(1823200, 'GNF'));
      expect(texte, '1${_milliers}823${_milliers}200${_insecable}GNF');
      expect(texte, isNot(contains(',')));
      expect(texte, isNot(contains(' ')));
    });

    test('la saisie en unites entieres ne multiplie pas par 100', () {
      expect(
        montantDepuisUnites(1823200, 'GNF'),
        const Montant(1823200, 'GNF'),
      );
      expect(unitesEntieresDe(const Montant(1823200, 'GNF')), 1823200);
    });
  });

  group('la saisie suit la table', () {
    test('KMF sans decimale, KWD a trois, CLF a quatre', () {
      expect(montantDepuisUnites(50, 'KMF'), const Montant(50, 'KMF'));
      expect(montantDepuisUnites(50, 'KWD'), const Montant(50000, 'KWD'));
      expect(montantDepuisUnites(2, 'CLF'), const Montant(20000, 'CLF'));
      expect(unitesEntieresDe(const Montant(50000, 'KWD')), 50);
      expect(unitesEntieresDe(const Montant(1500, 'KWD')), isNull);
    });
  });
}
