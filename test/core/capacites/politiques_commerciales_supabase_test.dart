// FAC-A-01 : l'adaptateur des politiques commerciales. Le JSON de reference
// est celui que rend reellement `politiques_commerciales_versions()` sur une
// base rejouee (migration 20261017170000) : decodage strict, aller-retour du
// brouillon dans la forme exacte que le serveur relit, apercus arretes par
// le serveur, fonction absente et refus.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/politiques_commerciales_supabase.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _versionsServeur =
    '[{"statut": "brouillon", "budgets": [], "version": "v1.1.0", '
    '"dateEffet": "2026-11-01", "essaisMax": 2, "classesMax": 4, '
    '"essaiActif": true, "baseHoraire": {"devise": "USD", "mineur": 400}, '
    '"railsActifs": ["webStripe"], "tarifAdulte": {"devise": "USD", '
    '"mineur": 6000}, "tarifEnfant": {"devise": "USD", "mineur": 5000}, '
    '"joursRelance": null, "capaciteAdulte": 6, "capaciteEnfant": 5, '
    '"plafondHoraire": {"devise": "USD", "mineur": 700}, "remisesParRang": '
    '[{"remise": {"devise": "USD", "mineur": -500}, "aPartirDuRang": 3}, '
    '{"remise": {"devise": "USD", "mineur": -700}, "aPartirDuRang": 4}], '
    '"classesObjectif": 3, "capaciteDebutant": 4, "minimumOuverture": 4, '
    '"allocationInternet": null, "joursConservationPlace": 7, '
    '"margeReferencePourMille": {"forte": 350, "stretch": 400, '
    '"objectif": 300}}, {"statut": "publiee", "budgets": [], "version": '
    '"v1.0.0", "dateEffet": "2026-10-01", "essaisMax": 2, "classesMax": 4, '
    '"essaiActif": true, "baseHoraire": {"devise": "USD", "mineur": 400}, '
    '"railsActifs": ["webStripe"], "tarifAdulte": {"devise": "USD", '
    '"mineur": 6000}, "tarifEnfant": {"devise": "USD", "mineur": 5000}, '
    '"joursRelance": null, "capaciteAdulte": 6, "capaciteEnfant": 5, '
    '"plafondHoraire": {"devise": "USD", "mineur": 700}, "remisesParRang": '
    '[{"remise": {"devise": "USD", "mineur": -500}, "aPartirDuRang": 3}, '
    '{"remise": {"devise": "USD", "mineur": -700}, "aPartirDuRang": 4}], '
    '"classesObjectif": 3, "capaciteDebutant": 4, "minimumOuverture": 4, '
    '"allocationInternet": null, "joursConservationPlace": 7, '
    '"margeReferencePourMille": {"forte": 350, "stretch": 400, '
    '"objectif": 300}}]';

const String _apercuFamilleServeur =
    '{"total": {"devise": "USD", "mineur": 14500}, "enfants": [{"rang": 1, '
    '"tarif": {"devise": "USD", "mineur": 5000}, "remise": null, '
    '"mensualite": {"devise": "USD", "mineur": 5000}}, {"rang": 2, "tarif": '
    '{"devise": "USD", "mineur": 5000}, "remise": null, "mensualite": '
    '{"devise": "USD", "mineur": 5000}}, {"rang": 3, "tarif": {"devise": '
    '"USD", "mineur": 5000}, "remise": {"devise": "USD", "mineur": -500}, '
    '"mensualite": {"devise": "USD", "mineur": 4500}}]}';

// La version v2.0.0 (tarifs du 18/10/2026, migration 20261018120000), telle
// que la rend `fac_politique_json` sur une base rejouee.
const String _v2Serveur =
    '{"statut": "publiee", "budgets": [], "version": "v2.0.0", '
    '"dateEffet": "2026-11-01", "essaisMax": 0, "classesMax": 4, '
    '"essaiActif": false, "baseHoraire": {"devise": "USD", "mineur": '
    '600}, "railsActifs": ["webStripe"], "tarifAdulte": {"devise": '
    '"USD", "mineur": 6500}, "tarifEnfant": {"devise": "USD", "mineur": '
    '5500}, "joursRelance": [7, 3, 1], "capaciteAdulte": 6, '
    '"capaciteEnfant": 5, "jourSuspension": 4, "plafondHoraire": '
    '{"devise": "USD", "mineur": 900}, "remisesParRang": [{"pourMille": '
    '80, "aPartirDuRang": 2}, {"pourMille": 170, "aPartirDuRang": 3}], '
    '"bourseDureeMois": 6, "boursePourMille": 300, "classesObjectif": '
    '3, "capaciteDebutant": 4, "minimumOuverture": 3, '
    '"parrainageCredit": {"devise": "USD", "mineur": 2000}, '
    '"cumulMaxPourMille": 250, "allocationInternet": null, '
    '"tauxEleveHeureAdulte": {"devise": "USD", "mineur": 100}, '
    '"tauxEleveHeureEnfant": {"devise": "USD", "mineur": 95}, '
    '"boursePlacesPourMille": 50, "dureeDueAdulteMinutes": 70, '
    '"dureeDueEnfantMinutes": 45, "joursConservationPlace": 14, '
    '"margeReferencePourMille": {"forte": 500, "stretch": 520, '
    '"objectif": 450}, "plafondEleveHeureAdulte": {"devise": "USD", '
    '"mineur": 150}, "plafondEleveHeureEnfant": {"devise": "USD", '
    '"mineur": 130}, "prepaiementAnnuelPourMille": 100, '
    '"prepaiementTrimestrielPourMille": 50}';

// Les cles de la v2, nulles dans une version qui ne les porte pas.
const List<String> _clesV2 = <String>[
  'tauxEleveHeureEnfant',
  'tauxEleveHeureAdulte',
  'plafondEleveHeureEnfant',
  'plafondEleveHeureAdulte',
  'dureeDueEnfantMinutes',
  'dureeDueAdulteMinutes',
  'prepaiementTrimestrielPourMille',
  'prepaiementAnnuelPourMille',
  'parrainageCredit',
  'boursePourMille',
  'boursePlacesPourMille',
  'bourseDureeMois',
  'cumulMaxPourMille',
  'jourSuspension',
];

List<Object?> _versions() => jsonDecode(_versionsServeur) as List<Object?>;

void main() {
  group('decodage', () {
    test('les versions du serveur : brouillon puis version publiee', () async {
      final List<(String, Map<String, dynamic>?)> appels =
          <(String, Map<String, dynamic>?)>[];
      final PolitiquesCommercialesSupabase port =
          PolitiquesCommercialesSupabase.avecAppel((f, p) async {
            appels.add((f, p));
            return _versions();
          });
      final List<PolitiqueCommerciale> v = await port.versions();
      expect(appels.single.$1, 'politiques_commerciales_versions');
      expect(v.map((PolitiqueCommerciale p) => p.version), <String>[
        'v1.1.0',
        'v1.0.0',
      ]);
      expect(v.first.statut, StatutPolitique.brouillon);
      final PolitiqueCommerciale lancement = v.last;
      expect(lancement.statut, StatutPolitique.publiee);
      expect(lancement.dateEffet, DateTime(2026, 10));
      expect(lancement.tarifEnfant, const Montant(5000, 'USD'));
      expect(lancement.tarifAdulte, const Montant(6000, 'USD'));
      expect(lancement.remisePourRang(2), isNull);
      expect(lancement.remisePourRang(3), const Montant(-500, 'USD'));
      expect(lancement.remisePourRang(6), const Montant(-700, 'USD'));
      expect(lancement.joursRelance, isNull);
      expect(lancement.allocationInternet, isNull);
      expect(lancement.railsActifs, <RailPaiement>{RailPaiement.webStripe});
      expect(lancement.margeReferencePourMille, (
        objectif: 300,
        forte: 350,
        stretch: 400,
      ));
    });

    test('une forme inattendue est refusee, jamais completee', () {
      final Map<String, dynamic> casse = Map<String, dynamic>.from(
        _versions().first! as Map,
      )..remove('essaisMax');
      expect(() => politiqueJson(casse), throwsFormatException);
      final Map<String, dynamic> rail = Map<String, dynamic>.from(
        _versions().first! as Map,
      )..['railsActifs'] = <Object?>['carte'];
      expect(() => politiqueJson(rail), throwsFormatException);
      final Map<String, dynamic> statut = Map<String, dynamic>.from(
        _versions().first! as Map,
      )..['statut'] = 'archivee';
      expect(() => politiqueJson(statut), throwsFormatException);
    });
  });

  group('tarifs du 18/10/2026', () {
    test('la v2 : remises en pour mille, paie par eleve present', () {
      final PolitiqueCommerciale p = politiqueJson(jsonDecode(_v2Serveur));
      expect(p.tarifEnfant, const Montant(5500, 'USD'));
      expect(p.tarifAdulte, const Montant(6500, 'USD'));
      expect(p.essaiActif, isFalse);
      expect(p.remiseRangPour(1), isNull);
      expect(p.remiseRangPour(2)!.pourMille, 80);
      expect(p.remiseRangPour(5)!.pourMille, 170);
      expect(p.remisePourRang(2), isNull, reason: 'pas un montant');
      expect(p.tauxEleveHeureEnfant, const Montant(95, 'USD'));
      expect(p.tauxEleveHeureAdulte, const Montant(100, 'USD'));
      expect(p.plafondEleveHeureEnfant, const Montant(130, 'USD'));
      expect(p.plafondEleveHeureAdulte, const Montant(150, 'USD'));
      expect(p.dureeDueEnfantMinutes, 45);
      expect(p.dureeDueAdulteMinutes, 70);
      expect(p.prepaiementTrimestrielPourMille, 50);
      expect(p.prepaiementAnnuelPourMille, 100);
      expect(p.parrainageCredit, const Montant(2000, 'USD'));
      expect(p.boursePourMille, 300);
      expect(p.boursePlacesPourMille, 50);
      expect(p.bourseDureeMois, 6);
      expect(p.cumulMaxPourMille, 250);
      expect(p.jourSuspension, 4);
      expect(p.joursRelance, <int>[7, 3, 1]);
    });

    test('une remise a la fois en montant et en pour mille est refusee', () {
      final Map<String, dynamic> j = Map<String, dynamic>.from(
        jsonDecode(_v2Serveur) as Map,
      );
      j['remisesParRang'] = <Object?>[
        <String, Object?>{
          'aPartirDuRang': 2,
          'pourMille': 80,
          'remise': <String, Object?>{'mineur': -500, 'devise': 'USD'},
        },
      ];
      expect(() => politiqueJson(j), throwsFormatException);
      j['remisesParRang'] = <Object?>[
        <String, Object?>{'aPartirDuRang': 2},
      ];
      expect(() => politiqueJson(j), throwsFormatException);
    });
  });

  group('aller-retour', () {
    test('le brouillon repart au serveur dans la forme qu il a rendue', () {
      for (final Object? brut in _versions()) {
        // Une version v1 : le serveur rend les cles de la v2, nulles.
        final Map<String, Object?> attendu = <String, Object?>{
          ...(brut! as Map<String, Object?>),
          for (final String cle in _clesV2) cle: null,
        };
        expect(
          jsonDecode(jsonEncode(politiqueVersJson(politiqueJson(brut)))),
          equals(attendu),
        );
      }
      final Object? v2 = jsonDecode(_v2Serveur);
      expect(
        jsonDecode(jsonEncode(politiqueVersJson(politiqueJson(v2)))),
        equals(v2),
      );
    });

    test('publier envoie le brouillon et relit la version inscrite', () async {
      final PolitiqueCommerciale brouillon = politiqueJson(_versions().first);
      Map<String, dynamic>? envoye;
      final PolitiquesCommercialesSupabase port =
          PolitiquesCommercialesSupabase.avecAppel((f, p) async {
            expect(f, 'publier_politique_commerciale');
            envoye = p;
            return <String, Object?>{
              ...(_versions().first! as Map<String, Object?>),
              'statut': 'publiee',
            };
          });
      await port.publier(brouillon);
      expect(envoye!['p_politique'], politiqueVersJson(brouillon));
    });
  });

  group('apercus', () {
    test('foyer : les mensualites arretees par le serveur', () async {
      final PolitiqueCommerciale brouillon = politiqueJson(_versions().first);
      final PolitiquesCommercialesSupabase port =
          PolitiquesCommercialesSupabase.avecAppel((f, p) async {
            expect(f, 'apercu_politique_famille');
            expect(p!['p_enfants'], 3);
            return jsonDecode(_apercuFamilleServeur);
          });
      final ApercuFamille a = await port.apercuFamille(brouillon, 3);
      expect(a.total, const Montant(14500, 'USD'));
      expect(a.enfants.map((MensualiteApercu m) => m.remise), <Montant?>[
        null,
        null,
        const Montant(-500, 'USD'),
      ]);
    });

    test('enseignant : le taux arrete par le serveur', () async {
      final PolitiqueCommerciale brouillon = politiqueJson(_versions().first);
      final PolitiquesCommercialesSupabase port =
          PolitiquesCommercialesSupabase.avecAppel((f, p) async {
            expect(f, 'apercu_politique_enseignant');
            expect(p!['p_capacite'], 5);
            expect(p['p_eligibles'], 3);
            Map<String, Object?> m(int v) => <String, Object?>{
              'mineur': v,
              'devise': 'USD',
            };
            return <String, Object?>{
              'capacite': 5,
              'eligibles': 3,
              'baseHoraire': m(400),
              'occupation': m(180),
              'tauxHoraire': m(580),
              'plafondHoraire': m(700),
            };
          });
      final ApercuEnseignant a = await port.apercuEnseignant(
        brouillon,
        capacite: 5,
        eligibles: 3,
      );
      expect(a.tauxHoraire, const Montant(580, 'USD'));
      expect(a.occupation, const Montant(180, 'USD'));
    });
  });

  group('erreurs', () {
    test('fonction absente du serveur : capacite indisponible', () async {
      final PolitiquesCommercialesSupabase port =
          PolitiquesCommercialesSupabase.avecAppel(
            (f, p) async =>
                throw const PostgrestException(message: 'x', code: 'PGRST202'),
          );
      await expectLater(port.active(), throwsA(isA<CapaciteIndisponible>()));
    });

    test('un refus du serveur remonte tel quel', () async {
      final PolitiquesCommercialesSupabase port =
          PolitiquesCommercialesSupabase.avecAppel(
            (f, p) async =>
                throw const PostgrestException(message: 'x', code: '42501'),
          );
      await expectLater(
        port.publier(politiqueJson(_versions().first)),
        throwsA(
          isA<PostgrestException>().having(
            (PostgrestException e) => e.code,
            'code',
            '42501',
          ),
        ),
      );
    });
  });
}
