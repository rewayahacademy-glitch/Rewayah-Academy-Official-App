import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/code_local.dart';

/// Les identifiants qui designent le code personnel de l'eleve.
const List<String> _vocabulaireDuCode = <String>[
  'CodeLocal',
  'empreintePin',
  'enregistrerEmpreintePin',
  'onCodeComplet',
];

/// Ce qui, dans ce depot, part au reseau.
final RegExp _appelReseau = RegExp(
  r'\.rpc[<(]|functions\.invoke|\.from\(|\.insert\(|\.update\(|\.uploadBinary\(',
);

List<File> _sources(String dossier) => Directory(dossier)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'))
    .where((File f) => !f.path.endsWith('.g.dart'))
    .toList();

void main() {
  group('CodeLocal : ce que l empreinte protege, et ce qu elle ne protege pas', () {
    test('un code scelle se reconnait', () {
      final String scelle = CodeLocal.sceller('1234');
      expect(CodeLocal.correspond('1234', scelle), isTrue);
    });

    test('un autre code ne passe pas', () {
      final String scelle = CodeLocal.sceller('1234');
      for (final String faux in <String>['1235', '4321', '0000', '']) {
        expect(CodeLocal.correspond(faux, scelle), isFalse, reason: faux);
      }
    });

    test('le meme code donne deux empreintes differentes', () {
      // Le sel evite qu on puisse deviner que deux enfants du meme appareil ont
      // choisi le meme code.
      expect(CodeLocal.sceller('1234'), isNot(CodeLocal.sceller('1234')));
    });

    test('une empreinte absente ou malformee ne laisse jamais passer', () {
      expect(CodeLocal.correspond('1234', null), isFalse);
      expect(CodeLocal.correspond('1234', ''), isFalse);
      expect(CodeLocal.correspond('1234', 'sansdeuxpoints'), isFalse);
      expect(CodeLocal.correspond('1234', ':vide'), isFalse);
    });

    test('le code en clair n apparait pas dans ce qui est conserve', () {
      final String scelle = CodeLocal.sceller('1234');
      expect(scelle.contains('1234'), isFalse);
    });

    test('la forme attendue est quatre chiffres', () {
      expect(CodeLocal.formeValide('1234'), isTrue);
      expect(CodeLocal.formeValide('123'), isFalse);
      expect(CodeLocal.formeValide('12345'), isFalse);
      expect(CodeLocal.formeValide('12a4'), isFalse);
    });
  });

  group('Scenario 9 : le code personnel ne quitte jamais l appareil', () {
    // Le controle porte sur la SOURCE, comme celui de PermanentNotice : c'est
    // la que se joue la regle. Le jour ou quelqu'un ajoute le code a un corps de
    // requete, le code continuerait de compiler partout et l'ADR-005 tomberait
    // en silence.
    test('aucune ligne d appel reseau ne mentionne le code personnel', () {
      final List<String> fautes = <String>[];

      for (final File fichier in _sources('lib')) {
        final List<String> lignes = fichier.readAsLinesSync();
        for (int i = 0; i < lignes.length; i++) {
          final String ligne = lignes[i];
          final int commentaire = ligne.indexOf('//');
          final String code = commentaire == -1
              ? ligne
              : ligne.substring(0, commentaire);
          if (!_appelReseau.hasMatch(code)) {
            continue;
          }
          for (final String mot in _vocabulaireDuCode) {
            if (code.contains(mot)) {
              fautes.add('${fichier.path}:${i + 1}  $mot  ${ligne.trim()}');
            }
          }
        }
      }

      expect(
        fautes,
        isEmpty,
        reason:
            'Le code personnel de l eleve figure dans un appel reseau :\n'
            '${fautes.join('\n')}',
      );
    });

    test('aucun service ne declare de parametre pour le code personnel', () {
      // Ce qui ne peut pas etre envoye ne peut pas etre forge : la barriere la
      // plus solide est l absence de parametre.
      for (final String chemin in <String>[
        'lib/core/appairage/service_enfant.dart',
        'lib/core/appairage/service_appairage.dart',
        'lib/core/dossier/service_dossier.dart',
      ]) {
        final String source = File(chemin).readAsStringSync();
        for (final String interdit in <String>[
          'String pin',
          'String code_personnel',
          'required String pin',
          'codePersonnel',
        ]) {
          expect(
            source.contains(interdit),
            isFalse,
            reason: '$chemin declare « $interdit »',
          );
        }
      }
    });

    test('le coffre recoit une empreinte, jamais un code', () {
      final String source = File(
        'lib/core/cache/secure/stockage_securise.dart',
      ).readAsStringSync();

      // La signature nomme ce qu elle recoit. Un parametre appele `code`
      // laisserait passer un code brut par inadvertance.
      expect(source.contains('enregistrerEmpreintePin('), isTrue);
      expect(
        RegExp(r'enregistrerEmpreintePin\([^)]*\bcode\b').hasMatch(source),
        isFalse,
      );
    });
  });
}
