// FINANCE-ENSEIGNANT (06/11/2026) : l'adaptateur des coordonnees de versement
// et du fichier Wise (migration 20261110700000).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/coordonnees_versement_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final Map<String, Object?> lecture = <String, Object?>{
    'prestataire': 'wise',
    'deviseCible': 'USD',
    'devisesProposees': <Object?>['USD'],
    'champs': <Object?>[
      for (final String c in <String>[
        'titulaire',
        'numero_compte',
        'swift',
        'adresse_pays',
        'adresse_ville',
        'adresse_ligne',
      ])
        <String, Object?>{'champ': c, 'obligatoire': true, 'siPays': null},
      <String, Object?>{
        'champ': 'adresse_etat',
        'obligatoire': true,
        'siPays': <Object?>['US', 'CA'],
      },
      <String, Object?>{
        'champ': 'code_postal',
        'obligatoire': false,
        'siPays': null,
      },
      <String, Object?>{
        'champ': 'inconnu',
        'obligatoire': false,
        'siPays': null,
      },
    ],
    'paysProfil': 'Guinée',
    'enregistre': true,
    'complet': true,
    'valide': false,
    'compteAMonNom': false,
    'lienTitulaire': 'parent',
    'modifieLe': '2026-11-06T22:00:00Z',
    'coordonnees': <String, Object?>{
      'titulaire': 'Mamadou Diallo',
      'numeroCompte': '••••8901',
      'iban': null,
      'swift': '••••GNGN',
      'adressePays': 'GN',
      'adresseVille': 'Conakry',
      'adresseLigne': 'Quartier Kaloum',
      'codePostal': null,
    },
  };

  test(
    'lecture : champs dans l ordre du serveur, inconnu ignore, numeros masques',
    () async {
      final CoordonneesVersementSupabase port =
          CoordonneesVersementSupabase.avecAppel(
            (String f, Map<String, dynamic>? p) async => lecture,
          );
      final MesCoordonneesVersement m = await port.mesCoordonnees();
      expect(
        <ChampVersement>[for (final ChampDemande d in m.champs) d.champ],
        <ChampVersement>[
          ChampVersement.titulaire,
          ChampVersement.numeroCompte,
          ChampVersement.swift,
          ChampVersement.adressePays,
          ChampVersement.adresseVille,
          ChampVersement.adresseLigne,
          ChampVersement.adresseEtat,
          ChampVersement.codePostal,
        ],
      );
      expect(m.champs[6].demandePour('GN'), isFalse);
      expect(m.champs[6].demandePour('US'), isTrue);
      expect(m.champs[7].obligatoire, isFalse);
      expect(m.valeurs[ChampVersement.numeroCompte], '••••8901');
      expect(m.valeurs.containsKey(ChampVersement.iban), isFalse);
      expect(m.complet, isTrue);
      expect(m.valide, isFalse);
      expect(m.compteAMonNom, isFalse);
      expect(m.lienTitulaire, LienTitulaire.parent);
    },
  );

  test('refus 42501 (pas enseignant) : capacite indisponible', () async {
    final CoordonneesVersementSupabase port =
        CoordonneesVersementSupabase.avecAppel(
          (String f, Map<String, dynamic>? p) async =>
              throw const PostgrestException(message: 'refus', code: '42501'),
        );
    await expectLater(
      port.mesCoordonnees(),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test('enregistrer envoie chaque champ par son nom serveur', () async {
    late Map<String, dynamic> params;
    final CoordonneesVersementSupabase port =
        CoordonneesVersementSupabase.avecAppel((
          String f,
          Map<String, dynamic>? p,
        ) async {
          if (f == 'enregistrer_mes_coordonnees_versement') params = p!;
          return lecture;
        });
    await port.enregistrer(
      deviseCible: 'USD',
      valeurs: const <ChampVersement, String>{
        ChampVersement.titulaire: 'Mamadou Diallo',
        ChampVersement.numeroCompte: '0012345678901',
        ChampVersement.swift: 'ECOCGNGN',
      },
    );
    expect(params['p_devise_cible'], 'USD');
    expect(params['p_numero_compte'], '0012345678901');
    expect(params['p_swift'], 'ECOCGNGN');
    expect(params['p_iban'], isNull);
  });

  test('export : colonnes, lignes et manquants tels quels', () async {
    final CoordonneesVersementSupabase port =
        CoordonneesVersementSupabase.avecAppel(
          (String f, Map<String, dynamic>? p) async => <String, Object?>{
            'exportId': 'x1',
            'mois': '2026-10-01',
            'devise': 'USD',
            'colonnes': <Object?>['Name', 'Amount'],
            'lignes': <Object?>[
              <Object?>['Mamadou Diallo', '31.74'],
            ],
            'manquants': <Object?>[
              <String, Object?>{
                'enseignantId': 'e3',
                'nom': 'Ousmane Ba',
                'matricule': 'RA-26-1234',
                'montant': <String, Object?>{'mineur': 1000, 'devise': 'USD'},
                'raison': 'incompletes',
              },
            ],
            'total': <String, Object?>{'mineur': 3174, 'devise': 'USD'},
          },
        );
    final ExportWise e = await port.exporter(DateTime(2026, 10));
    expect(e.colonnes, <String>['Name', 'Amount']);
    expect(e.lignes.single, <String>['Mamadou Diallo', '31.74']);
    expect(e.manquants.single.aucune, isFalse);
    expect(fichierCsvWise(e), 'Name,Amount\r\nMamadou Diallo,31.74\r\n');
  });

  // HYGIENE-2 (08/11/2026) : injection de formule dans le tableur.
  test('CSV Wise : une cellule qui commence par = + - @ tab CR est '
      'neutralisee par une apostrophe, un montant reste tel quel', () {
    ExportWise export(List<String> ligne) => ExportWise(
      exportId: 'x1',
      mois: DateTime(2026, 10),
      colonnes: const <String>['Name', 'Amount'],
      lignes: <List<String>>[ligne],
      manquants: const <EnseignantSansCoordonnees>[],
      total: const Montant(1234, 'USD'),
    );
    expect(
      fichierCsvWise(export(<String>['=HYPERLINK("x")', '12.34'])),
      'Name,Amount\r\n"\'=HYPERLINK(""x"")",12.34\r\n',
    );
    for (final String debut in <String>['+', '-', '@', '\t', ' =', '  @']) {
      expect(
        fichierCsvWise(export(<String>['${debut}1+1', '12.34'])),
        "Name,Amount\r\n'${debut}1+1,12.34\r\n",
      );
    }
    expect(
      fichierCsvWise(export(<String>['\r1', '12.34'])),
      'Name,Amount\r\n"\'\r1",12.34\r\n',
    );
    expect(
      fichierCsvWise(export(<String>['Nom Test', '12.34'])),
      'Name,Amount\r\nNom Test,12.34\r\n',
    );
    expect(
      fichierCsvWise(export(<String>['Nom-Test', '12.34'])),
      'Name,Amount\r\nNom-Test,12.34\r\n',
    );
  });

  test('pays du compte indisponible : PaysVersementIndisponible', () async {
    final CoordonneesVersementSupabase port =
        CoordonneesVersementSupabase.avecAppel(
          (String f, Map<String, dynamic>? p) async =>
              throw const PostgrestException(
                message: 'pays_indisponible',
                code: 'P0001',
              ),
        );
    await expectLater(
      port.enregistrer(deviseCible: 'USD', valeurs: const {}),
      throwsA(isA<PaysVersementIndisponible>()),
    );
  });

  test('modele Wise absent : ModeleWiseAbsent', () async {
    final CoordonneesVersementSupabase port =
        CoordonneesVersementSupabase.avecAppel(
          (String f, Map<String, dynamic>? p) async =>
              throw const PostgrestException(
                message: 'modele_wise_absent',
                code: 'P0001',
              ),
        );
    await expectLater(
      port.exporter(DateTime(2026, 10)),
      throwsA(isA<ModeleWiseAbsent>()),
    );
  });
}
