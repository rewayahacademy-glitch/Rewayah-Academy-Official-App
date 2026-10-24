// CAND-Q15 conduite (relecture) : la documentation de [VersionsContrat] doit
// dire ce que fait le serveur pour la version du code de conduite.
//
// Depuis 20261021210400_pe_code_conduite_avant_activation.sql,
// `etat_dossier()` et la garde d'activation lisent la version requise de
// `teacher_conduct_code` dans `contract_required_versions`. Ces tests lisent
// les migrations, dans l'ordre ou elles s'appliquent, et le source de
// `versions_contrat.dart` : une constante qui ne suit pas la base, ou un
// commentaire qui dit encore « etat_dossier() ne filtre pas la version »
// sans l'exception du code, les fait echouer.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';

const String _source = 'lib/core/dossier/versions_contrat.dart';

/// Les migrations `.sql`, dans l'ordre du rejeu (nom de fichier croissant).
List<File> _migrations() {
  final List<File> fichiers =
      Directory('supabase/migrations')
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.sql'))
          .toList()
        ..sort(
          (File a, File b) =>
              a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last),
        );
  return fichiers;
}

String _nom(File f) => f.uri.pathSegments.last;

/// La version de `teacher_conduct_code` que laisse le rejeu des migrations.
///
/// INSERT ... DO NOTHING ne pose la ligne que si elle manque ; INSERT ...
/// DO UPDATE et UPDATE la remplacent.
String? _versionRequiseServeur() {
  final RegExp insertion = RegExp(
    r'INSERT\s+INTO\s+public\.contract_required_versions\s*\([^)]*\)\s*'
    r"VALUES\s*\(\s*'teacher_conduct_code'\s*,\s*'([^']+)'[^;]*?"
    r'ON\s+CONFLICT\s*\(\s*contract_kind\s*\)\s*DO\s+(NOTHING|UPDATE)',
    caseSensitive: false,
  );
  final RegExp miseAJour = RegExp(
    r'UPDATE\s+public\.contract_required_versions\s+SET\s+version\s*=\s*'
    r"'([^']+)'[^;]*?contract_kind\s*=\s*'teacher_conduct_code'",
    caseSensitive: false,
  );
  String? version;
  for (final File f in _migrations()) {
    final String sql = f.readAsStringSync();
    final List<(int, String, bool)> ecritures = <(int, String, bool)>[
      for (final RegExpMatch m in insertion.allMatches(sql))
        (m.start, m.group(1)!, m.group(2)!.toUpperCase() == 'UPDATE'),
      for (final RegExpMatch m in miseAJour.allMatches(sql))
        (m.start, m.group(1)!, true),
    ]..sort(((int, String, bool) a, (int, String, bool) b) => a.$1 - b.$1);
    for (final (int _, String v, bool remplace) in ecritures) {
      if (remplace || version == null) version = v;
    }
  }
  return version;
}

/// Le corps de chaque definition de `public.<fonction>()`, par migration,
/// dans l'ordre du rejeu.
List<(String, String)> _definitions(String fonction) {
  final RegExp creation = RegExp(
    r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+public\.' +
        RegExp.escape(fonction) +
        r'\(\)[\s\S]*?\bAS\s+(\$\w*\$)([\s\S]*?)\1',
    caseSensitive: false,
  );
  return <(String, String)>[
    for (final File f in _migrations())
      for (final RegExpMatch m in creation.allMatches(f.readAsStringSync()))
        (_nom(f), m.group(2)!),
  ];
}

/// Le commentaire `///` place juste au-dessus de la ligne qui contient
/// [declaration], mis sur une seule ligne.
String _doc(String declaration) {
  final List<String> lignes = File(_source).readAsLinesSync();
  final int i = lignes.indexWhere((String l) => l.contains(declaration));
  expect(i, isNonNegative, reason: '$declaration introuvable dans $_source');
  final List<String> doc = <String>[];
  for (int j = i - 1; j >= 0 && lignes[j].trimLeft().startsWith('///'); j--) {
    doc.insert(0, lignes[j].trimLeft().substring(3).trim());
  }
  return doc.join(' ');
}

void main() {
  group('VersionsContrat : le code de conduite suit la base', () {
    test('la constante du client est la version requise laissee par les '
        'migrations', () {
      expect(_versionRequiseServeur(), isNotNull);
      expect(VersionsContrat.codeConduite, _versionRequiseServeur());
      expect(
        VersionsContrat.pour(SorteContrat.codeConduiteEnseignant),
        VersionsContrat.codeConduite,
      );
    });

    test('le commentaire de la classe dit que etat_dossier() filtre la '
        'version du code de conduite, et la migration qui l a introduit', () {
      final List<(String, String)> defs = _definitions('etat_dossier');
      expect(defs, isNotEmpty);
      bool filtre((String, String) d) =>
          d.$2.contains('contract_required_versions') &&
          d.$2.contains('code_conduite_signe');
      // La derniere definition filtre toujours : sinon le commentaire est
      // faux dans l'autre sens et doit etre revu.
      expect(filtre(defs.last), isTrue, reason: defs.last.$1);
      final String depuis = defs.firstWhere(filtre).$1;

      final String doc = _doc('abstract final class VersionsContrat');
      expect(doc, contains(depuis));
      expect(doc, contains('`code_conduite_signe`'));
      expect(doc, contains('contract_required_versions'));
      // L'ancienne phrase disait « ne filtre pas la version » sans limite.
      expect(doc, contains('ne filtre pas la version du contrat'));
    });

    test('le commentaire de la constante dit qu une version montee en base '
        'bloque l activation des enseignants en attente', () {
      final List<(String, String)> gardes = _definitions(
        'guard_teacher_activation_signatures',
      );
      expect(gardes, isNotEmpty);
      // La garde en vigueur exige le code de conduite a la version requise.
      expect(gardes.last.$2, contains('teacher_conduct_code'));
      expect(gardes.last.$2, contains('contract_required_versions'));

      final String doc = _doc('static const String codeConduite');
      expect(doc, contains('contract_required_versions'));
      expect(
        doc,
        contains('`contract_not_signed_current:teacher_conduct_code`'),
      );
      expect(doc, contains('en attente'));
      expect(doc, contains('bloque son activation'));
      expect(doc, contains('portant la nouvelle constante'));
      expect(doc, contains(gardes.last.$1));
    });
  });
}
