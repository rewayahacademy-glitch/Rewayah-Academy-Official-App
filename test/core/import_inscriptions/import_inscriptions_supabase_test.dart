// IMM-ACCUEIL-FRONT : l'adaptateur des RPC d'import. Lecture stricte des
// reponses, options neutres non envoyees, erreurs du serveur traduites.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/import_inscriptions/analyse_inscriptions.dart';
import 'package:rewayah_academy/core/import_inscriptions/import_inscriptions_supabase.dart';
import 'package:rewayah_academy/core/import_inscriptions/port_import_inscriptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  late List<(String, Map<String, dynamic>?)> appels;
  late Object? reponse;
  Exception? erreur;

  ImportInscriptionsSupabase adaptateur() =>
      ImportInscriptionsSupabase.avecAppel((
        String nom, [
        Map<String, dynamic>? params,
      ]) async {
        appels.add((nom, params));
        if (erreur != null) throw erreur!;
        return reponse;
      });

  setUp(() {
    appels = <(String, Map<String, dynamic>?)>[];
    reponse = null;
    erreur = null;
  });

  test('capacites : bornes d\'age et double verification', () async {
    reponse = <String, dynamic>{
      'peutImporter': true,
      'doubleVerificationRequise': false,
      'ageMinimum': 6,
      'ageAdulte': 18,
    };
    final CapacitesImport c = await adaptateur().capacites();
    expect(appels.single.$1, 'capacites_import_inscriptions');
    expect(c.peutImporter, isTrue);
    expect(c.bornes.minimum, 6);
    expect(c.bornes.adulte, 18);

    reponse = <String, dynamic>{
      'peutImporter': false,
      'doubleVerificationRequise': true,
      'ageMinimum': null,
      'ageAdulte': null,
    };
    final CapacitesImport d = await adaptateur().capacites();
    expect(d.peutImporter, isFalse);
    expect(d.doubleVerificationRequise, isTrue);
    expect(d.bornes.minimum, isNull);
  });

  test('apercu : compteurs et motifs de rejet', () async {
    reponse = <String, dynamic>{
      'foyers': 2,
      'personnes': 5,
      'doublons': 1,
      'lignes_rejetees': 2,
      'motifs_rejet': <Map<String, dynamic>>[
        <String, dynamic>{
          'source': 'eleves',
          'row': 4,
          'reason': 'invalid_email',
        },
        <String, dynamic>{
          'source': 'enseignants',
          'row': 2,
          'reason': 'empty_row',
        },
      ],
      'ecriture_effectuee': false,
    };
    final ApercuServeur a = await adaptateur().apercu(
      elevesCsv: 'a\r\n',
      enseignantsCsv: 'b\r\n',
    );
    expect(appels.single.$1, 'previsualiser_import_inscriptions');
    expect(appels.single.$2, <String, dynamic>{
      'p_eleves_csv': 'a\r\n',
      'p_enseignants_csv': 'b\r\n',
    });
    expect(a.foyers, 2);
    expect(a.personnes, 5);
    expect(a.motifs.first.source, SourceImport.eleves);
    expect(a.motifs.first.ligne, 4);
    expect(a.motifs.first.code, CodeProbleme.emailInvalide);
    expect(a.motifs.last.source, SourceImport.enseignants);
    expect(a.motifs.last.code, CodeProbleme.ligneVide);
  });

  test('apercu : une reponse inattendue est une erreur, pas un zero', () async {
    reponse = <String, dynamic>{'foyers': 'deux'};
    await expectLater(
      adaptateur().apercu(elevesCsv: 'a', enseignantsCsv: 'b'),
      throwsFormatException,
    );
    reponse = 'rien';
    await expectLater(
      adaptateur().apercu(elevesCsv: 'a', enseignantsCsv: 'b'),
      throwsFormatException,
    );
  });

  test(
    'confirmer : seules les options qui changent quelque chose partent',
    () async {
      reponse = <String, dynamic>{
        'foyers_traites': 3,
        'foyers_crees': 2,
        'personnes_creees': 5,
        'personnes_deja_importees': 1,
        'journal_audit': true,
      };
      final ResultatImport r = await adaptateur().confirmer(
        elevesCsv: 'a',
        enseignantsCsv: 'b',
        options: const <OptionFoyer>[
          OptionFoyer(email: 'neutre@x.fr'),
          OptionFoyer(
            email: 'patiente@x.fr',
            aPatiente: true,
            motPatience: '  Merci.  ',
          ),
          OptionFoyer(email: 'mot@x.fr', motAccueil: 'Bienvenue.'),
          // Un mot de patience sans la case : ignore.
          OptionFoyer(
            email: 'sans-case@x.fr',
            motAccueil: 'Mot.',
            motPatience: 'x',
          ),
        ],
      );
      expect(appels.single.$1, 'confirmer_import_inscriptions');
      final List<dynamic> options =
          appels.single.$2!['p_options_foyers'] as List<dynamic>;
      expect(options, <Map<String, dynamic>>[
        <String, dynamic>{
          'email': 'patiente@x.fr',
          'a_patiente': true,
          'mot_patience': 'Merci.',
        },
        <String, dynamic>{
          'email': 'mot@x.fr',
          'a_patiente': false,
          'mot_accueil': 'Bienvenue.',
        },
        <String, dynamic>{
          'email': 'sans-case@x.fr',
          'a_patiente': false,
          'mot_accueil': 'Mot.',
        },
      ]);
      expect(r.foyersCrees, 2);
      expect(r.personnesCreees, 5);
      expect(r.personnesDejaImportees, 1);
      expect(r.foyersTraites, 3);
    },
  );

  test('erreurs : refus, contenu invalide, coupure', () async {
    erreur = const PostgrestException(message: 'Accès refusé', code: '42501');
    await expectLater(adaptateur().capacites(), throwsA(isA<ImportRefuse>()));
    erreur = const PostgrestException(message: 'CSV mal formé', code: '22023');
    await expectLater(
      adaptateur().apercu(elevesCsv: 'a', enseignantsCsv: 'b'),
      throwsA(
        isA<ImportInvalide>().having(
          (ImportInvalide e) => e.message,
          'message',
          'CSV mal formé',
        ),
      ),
    );
    erreur = Exception('Failed host lookup: x');
    await expectLater(
      adaptateur().confirmer(
        elevesCsv: 'a',
        enseignantsCsv: 'b',
        options: const <OptionFoyer>[],
      ),
      throwsA(isA<ImportHorsLigne>()),
    );
    // Autre erreur : relancee telle quelle, jamais avalee.
    erreur = const FormatException('autre');
    await expectLater(adaptateur().capacites(), throwsFormatException);
  });
}
