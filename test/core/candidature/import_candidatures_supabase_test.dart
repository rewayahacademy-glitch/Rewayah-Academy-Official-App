// ADM-23 : l'adaptateur des RPC de l'import des formulaires
// (`apercu_import_formulaires`, `confirmer_import_formulaires`,
// `capacites_candidatures`).
//
// Ce que le test prouve : les parametres envoyes sont ceux de la signature
// versee (mappage nul sans correction, choix en `{groupe, retenue}`, cle
// d'idempotence) ; chaque refus du serveur, rendu dans la reponse, devient une
// erreur typee ; `42501`, `22023`, une fonction pas encore versee et une coupure
// du reseau se traduisent ; une forme inattendue est une erreur.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/import_candidatures_supabase.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

Map<String, dynamic> _compteurs() => <String, dynamic>{
  'lignesLues': 2,
  'nouvelles': 2,
  'corrigees': 0,
  'dejaConnues': 0,
  'ignorees': 0,
  'aCorriger': 0,
  'historique': 0,
  'personnes': 2,
};

Map<String, dynamic> _apercu() => <String, dynamic>{
  'ecritureEffectuee': false,
  'jeton': 'jeton-1',
  'entetes': <Map<String, dynamic>>[
    <String, dynamic>{'position': 1, 'champ': 'horodatage'},
  ],
  'compteurs': _compteurs(),
  'groupes': <Object?>[],
  'lignes': <Object?>[],
};

Map<String, dynamic> _rapport() => <String, dynamic>{
  'ecritureEffectuee': true,
  'lot': 'lot-1',
  'compteurs': _compteurs(),
  'choix': <Object?>[],
  'lignes': <Object?>[],
  'rejoue': false,
};

void main() {
  late List<(String, Map<String, dynamic>?)> appels;
  late Object? reponse;
  Exception? erreur;

  ImportCandidaturesSupabase adaptateur() =>
      ImportCandidaturesSupabase.avecAppel((
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

  test('capacites : peutImporter et doubleVerificationRequise', () async {
    reponse = <String, dynamic>{
      'peutImporter': false,
      'doubleVerificationRequise': true,
      'peutLire': true,
    };
    final CapacitesImportCandidatures c = await adaptateur().capacites();
    expect(appels.single.$1, 'capacites_candidatures');
    expect(c.peutImporter, isFalse);
    expect(c.doubleVerificationRequise, isTrue);
  });

  group('apercu', () {
    test('envoie le fichier, les noms, le fuseau, et pas de mappage', () async {
      reponse = _apercu();
      final ApercuImport a = await adaptateur().apercu(
        csv: 'Horodateur\r\n1\r\n',
        classeur: 'Classeur',
        onglet: 'Onglet',
      );
      expect(appels.single.$1, 'apercu_import_formulaires');
      expect(appels.single.$2, <String, dynamic>{
        'p_csv': 'Horodateur\r\n1\r\n',
        'p_classeur': 'Classeur',
        'p_onglet': 'Onglet',
        'p_mappage': null,
        'p_fuseau': 'UTC',
      });
      expect(a.jeton, 'jeton-1');
    });

    test('un mappage corrige part en position vers code', () async {
      reponse = _apercu();
      await adaptateur().apercu(
        csv: 'x',
        classeur: 'c',
        onglet: 'o',
        mappage: MappageColonnes.aucun
            .avec(3, ChampFormulaire.nom)
            .avec(5, null),
        fuseau: 'Asia/Riyadh',
      );
      expect(appels.single.$2!['p_mappage'], <String, String?>{
        '3': 'nom',
        '5': null,
      });
      expect(appels.single.$2!['p_fuseau'], 'Asia/Riyadh');
    });

    test(
      'chaque refus rendu dans la reponse devient une erreur typee',
      () async {
        Future<Object?> refus(Map<String, dynamic> corps) async {
          reponse = corps;
          try {
            await adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o');
          } on Object catch (e) {
            return e;
          }
          return null;
        }

        expect(
          await refus(<String, dynamic>{
            'erreur': 'double_verification_requise',
            'ecritureEffectuee': false,
          }),
          isA<DoubleVerificationRequise>(),
        );
        final Object? illisible = await refus(<String, dynamic>{
          'erreur': 'fichier_illisible',
          'cause': 'CSV mal formé',
          'ecritureEffectuee': false,
        });
        expect(illisible, isA<FichierIllisible>());
        expect((illisible! as FichierIllisible).cause, 'CSV mal formé');
        expect(
          await refus(<String, dynamic>{'erreur': 'fichier_vide'}),
          isA<FichierVide>(),
        );
        final Object? manquants = await refus(<String, dynamic>{
          'erreur': 'mappage_incomplet',
          'champs': <String>['nom', 'contact'],
          'entetes': <Map<String, dynamic>>[
            <String, dynamic>{'position': 1, 'champ': 'horodatage'},
            <String, dynamic>{'position': 2, 'champ': null},
          ],
        });
        expect(manquants, isA<MappageIncomplet>());
        expect((manquants! as MappageIncomplet).champs, <ChampManquant>[
          ChampManquant.nom,
          ChampManquant.contact,
        ]);
        expect((manquants as MappageIncomplet).colonnes.length, 2);
        final Object? ambigus = await refus(<String, dynamic>{
          'erreur': 'entetes_ambigus',
          'champs': <String>['nom'],
          'entetes': <Map<String, dynamic>>[
            <String, dynamic>{'position': 3, 'champ': 'nom'},
            <String, dynamic>{'position': 9, 'champ': null},
          ],
        });
        expect(ambigus, isA<EntetesAmbigus>());
        expect((ambigus! as EntetesAmbigus).champs, <ChampFormulaire>[
          ChampFormulaire.nom,
        ]);
        expect(
          await refus(<String, dynamic>{'erreur': 'code_futur'}),
          isA<ImportRefuseInconnu>(),
        );
      },
    );

    test('un champ manquant ou ambigu que le client ne connait pas est une erreur de lecture', () async {
      reponse = <String, dynamic>{
        'erreur': 'mappage_incomplet',
        'champs': <String>['inconnu'],
        'entetes': <Object?>[],
      };
      await expectLater(
        adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o'),
        throwsFormatException,
      );
    });

    test('une reponse qui n\'est pas un objet est une erreur', () async {
      reponse = <Object?>[];
      await expectLater(
        adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o'),
        throwsFormatException,
      );
    });
  });

  group('confirmer', () {
    test('envoie le jeton, les choix et la cle d\'idempotence', () async {
      reponse = _rapport();
      final RapportImport r = await adaptateur().confirmer(
        csv: 'x',
        classeur: 'c',
        onglet: 'o',
        jeton: 'jeton-1',
        choix: const <ChoixDoublon>[
          ChoixDoublon(groupe: 'g1', retenue: 'c|o|21/10/2026 09:40:00'),
          ChoixDoublon(groupe: 'g2', retenue: retenueDistinctes),
        ],
        cleIdempotence: 'import-cle-1234',
        mappage: MappageColonnes.aucun.avec(3, ChampFormulaire.nom),
      );
      expect(appels.single.$1, 'confirmer_import_formulaires');
      expect(appels.single.$2, <String, dynamic>{
        'p_csv': 'x',
        'p_classeur': 'c',
        'p_onglet': 'o',
        'p_jeton': 'jeton-1',
        'p_choix': <Map<String, String>>[
          <String, String>{
            'groupe': 'g1',
            'retenue': 'c|o|21/10/2026 09:40:00',
          },
          <String, String>{'groupe': 'g2', 'retenue': 'distinctes'},
        ],
        'p_cle_idempotence': 'import-cle-1234',
        'p_mappage': <String, String?>{'3': 'nom'},
        'p_fuseau': 'UTC',
      });
      expect(r.lot, 'lot-1');
      expect(r.rejoue, isFalse);
    });

    test(
      'jeton perime, cle reutilisee, choix invalide, double verification',
      () async {
        Future<Object?> refus(Map<String, dynamic> corps) async {
          reponse = corps;
          try {
            await adaptateur().confirmer(
              csv: 'x',
              classeur: 'c',
              onglet: 'o',
              jeton: 'j',
              choix: const <ChoixDoublon>[],
              cleIdempotence: 'import-cle-1234',
            );
          } on Object catch (e) {
            return e;
          }
          return null;
        }

        expect(
          await refus(<String, dynamic>{
            'erreur': 'jeton_perime',
            'ecritureEffectuee': false,
          }),
          isA<JetonPerime>(),
        );
        expect(
          await refus(<String, dynamic>{
            'erreur': 'cle_idempotence_reutilisee',
          }),
          isA<CleIdempotenceReutilisee>(),
        );
        final Object? invalide = await refus(<String, dynamic>{
          'erreur': 'choix_invalide',
          'groupes': <String>['g1', 'g9'],
          'ecritureEffectuee': false,
        });
        expect(invalide, isA<ChoixInvalide>());
        expect((invalide! as ChoixInvalide).groupes, <String>['g1', 'g9']);
        expect(
          await refus(<String, dynamic>{
            'erreur': 'double_verification_requise',
            'ecritureEffectuee': false,
          }),
          isA<DoubleVerificationRequise>(),
        );
      },
    );

    test('rejouer : le rapport rejoue le dit', () async {
      reponse = _rapport()..['rejoue'] = true;
      final RapportImport r = await adaptateur().confirmer(
        csv: 'x',
        classeur: 'c',
        onglet: 'o',
        jeton: 'j',
        choix: const <ChoixDoublon>[],
        cleIdempotence: 'import-cle-1234',
      );
      expect(r.rejoue, isTrue);
    });
  });

  group('erreurs de la base et du reseau', () {
    test('42501 : permission insuffisante, sans donnee', () async {
      erreur = const PostgrestException(message: 'refus', code: '42501');
      await expectLater(
        adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o'),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test(
      '22023 : arguments refuses, le message du serveur n\'est pas dit',
      () async {
        erreur = const PostgrestException(
          message: 'fichier, classeur et onglet attendus',
          code: '22023',
        );
        await expectLater(
          adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o'),
          throwsA(isA<ImportInvalide>()),
        );
      },
    );

    test('fonction pas encore versee : capacite indisponible', () async {
      for (final String code in <String>['PGRST202', '42883']) {
        erreur = PostgrestException(message: 'absente', code: code);
        await expectLater(
          adaptateur().capacites(),
          throwsA(isA<CapaciteIndisponible>()),
          reason: code,
        );
      }
      erreur = const PostgrestException(message: 'absente', code: 'PGRST202');
      try {
        await adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o');
        fail('attendu');
      } on CapaciteIndisponible catch (e) {
        expect(e.dependance, dependanceImportCandidatures);
        expect(dependanceImportCandidatures, 'CAND-BR-09');
      }
    });

    test('une coupure du reseau : hors ligne, jamais un faux succes', () async {
      erreur = Exception('SocketException: Failed host lookup');
      await expectLater(
        adaptateur().confirmer(
          csv: 'x',
          classeur: 'c',
          onglet: 'o',
          jeton: 'j',
          choix: const <ChoixDoublon>[],
          cleIdempotence: 'import-cle-1234',
        ),
        throwsA(isA<ImportHorsLigne>()),
      );
    });

    test('toute autre erreur remonte telle quelle', () async {
      erreur = const PostgrestException(message: 'autre', code: 'XX000');
      await expectLater(
        adaptateur().apercu(csv: 'x', classeur: 'c', onglet: 'o'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
