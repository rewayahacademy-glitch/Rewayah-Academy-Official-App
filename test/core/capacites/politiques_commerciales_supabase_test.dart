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

  group('aller-retour', () {
    test('le brouillon repart au serveur dans la forme qu il a rendue', () {
      for (final Object? brut in _versions()) {
        expect(
          jsonDecode(jsonEncode(politiqueVersJson(politiqueJson(brut)))),
          equals(brut),
        );
      }
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
