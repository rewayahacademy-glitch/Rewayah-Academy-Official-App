// FAC-C-01 : l'adaptateur de la saisie des paiements. Les JSON de reference
// sont ceux que rendent reellement `eleves_pour_paiement()` et
// `enregistrer_paiement(...)` sur une base rejouee (migration
// 20261017172000, fixtures de `scenarios_fac_c_paiements.sql`) : decodage
// strict, parametres envoyes, refus et fonction absente.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/paiements_saisis_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _eleveServeur =
    '{"nom": "F1", "prenom": "Bilal", "foyerId": '
    '"fc000000-0000-4000-8000-0000000000f1", "profilId": '
    '"fc000000-0000-4000-8000-0000000000e2", "matricule": "FC-ELV-0002", '
    '"resteAPayer": {"devise": "USD", "mineur": 5000}}';

/// Un paiement partiel : 30 USD pour 50 dus, place expiree.
const String _partielServeur =
    '{"finance": {"age": null, "etat": "expire", "solde": {"devise": "USD", '
    '"mineur": 3000}, "classe": "An-Nour FC", "manque": {"devise": "USD", '
    '"mineur": 2000}, "prenom": "Bilal", "periode": null, "profilId": '
    '"fc000000-0000-4000-8000-0000000000e2", "cleAccent": '
    '"fc000000-0000-4000-8000-0000000000e2", "cleAvatar": null, "estAdulte": '
    'false, "mensualite": {"devise": "USD", "mineur": 5000}, "prochainDebit": '
    'null, "essaisUtilises": null, "finConservation": "2026-10-08", '
    '"lignesMensualite": [{"rang": null, "nature": "tarif", "montant": '
    '{"devise": "USD", "mineur": 5000}}]}, "nouveau": true, "paiement": "1"}';

/// Le complement : le mois est finance.
const String _completServeur =
    '{"finance": {"age": null, "etat": "finance", "solde": {"devise": "USD", '
    '"mineur": 0}, "classe": "An-Nour FC", "manque": null, "prenom": '
    '"Bilal", "periode": {"fin": "2026-10-31", "debut": "2026-10-01"}, '
    '"profilId": "fc000000-0000-4000-8000-0000000000e2", "cleAccent": '
    '"fc000000-0000-4000-8000-0000000000e2", "cleAvatar": null, "estAdulte": '
    'false, "mensualite": {"devise": "USD", "mineur": 5000}, "prochainDebit": '
    '{"date": "2026-11-01", "montant": {"devise": "USD", "mineur": 5000}}, '
    '"essaisUtilises": null, "finConservation": null, "lignesMensualite": '
    '[{"rang": null, "nature": "tarif", "montant": {"devise": "USD", '
    '"mineur": 5000}}]}, "nouveau": true, "paiement": "2"}';

void main() {
  test('la liste des eleves, decodee telle que le serveur la rend', () async {
    final List<(String, Map<String, dynamic>?)> appels =
        <(String, Map<String, dynamic>?)>[];
    final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel((
      String f,
      Map<String, dynamic>? p,
    ) async {
      appels.add((f, p));
      return jsonDecode('[$_eleveServeur]');
    });
    final List<ElevePourPaiement> eleves = await port.eleves();
    expect(appels.single.$1, 'eleves_pour_paiement');
    expect(eleves, hasLength(1));
    expect(eleves.single.profilId, 'fc000000-0000-4000-8000-0000000000e2');
    expect(eleves.single.prenom, 'Bilal');
    expect(eleves.single.nom, 'F1');
    expect(eleves.single.matricule, 'FC-ELV-0002');
    expect(eleves.single.resteAPayer, const Montant(5000, 'USD'));
  });

  test('enregistrer : les parametres exacts, et l etat rendu', () async {
    Map<String, dynamic>? envoye;
    final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel((
      String f,
      Map<String, dynamic>? p,
    ) async {
      expect(f, 'enregistrer_paiement');
      envoye = p;
      return jsonDecode(_partielServeur);
    });
    final PaiementEnregistre r = await port.enregistrer(
      profilId: 'fc000000-0000-4000-8000-0000000000e2',
      montant: const Montant(3000, 'USD'),
      cle: 'fc000000-0000-4000-8000-00000000c001',
      reference: 'Virement 1',
    );
    expect(envoye, <String, dynamic>{
      'p_profil': 'fc000000-0000-4000-8000-0000000000e2',
      'p_montant_mineur': 3000,
      'p_devise': 'USD',
      'p_reference': 'Virement 1',
      'p_cle': 'fc000000-0000-4000-8000-00000000c001',
    });
    expect(r.paiementId, '1');
    expect(r.nouveau, isTrue);
    expect(r.finance!.etat, EtatFinancier.expire);
    expect(r.finance!.manque, const Montant(2000, 'USD'));
  });

  test('le complement : mois finance, aucun manque', () async {
    final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async => jsonDecode(_completServeur),
    );
    final PaiementEnregistre r = await port.enregistrer(
      profilId: 'p',
      montant: const Montant(2000, 'USD'),
      cle: 'c',
    );
    expect(r.finance!.etat, EtatFinancier.finance);
    expect(r.finance!.manque, isNull);
  });

  for (final (String code, MotifRefusPaiement motif)
      in <(String, MotifRefusPaiement)>[
        ('42501', MotifRefusPaiement.droits),
        ('22023', MotifRefusPaiement.invalide),
        ('P0002', MotifRefusPaiement.invalide),
      ]) {
    test('refus $code : RefusPaiement(${motif.name})', () async {
      final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel(
        (String _, Map<String, dynamic>? _) async =>
            throw PostgrestException(message: 'refus', code: code),
      );
      await expectLater(
        port.enregistrer(
          profilId: 'p',
          montant: const Montant(1, 'USD'),
          cle: 'c',
        ),
        throwsA(
          isA<RefusPaiement>().having(
            (RefusPaiement r) => r.motif,
            'motif',
            motif,
          ),
        ),
      );
    });
  }

  test('une autre erreur remonte telle quelle : issue inconnue', () async {
    final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async =>
          throw const PostgrestException(message: 'panne', code: '57014'),
    );
    await expectLater(
      port.enregistrer(
        profilId: 'p',
        montant: const Montant(1, 'USD'),
        cle: 'c',
      ),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('fonction absente : CapaciteIndisponible', () async {
    final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async =>
          throw const PostgrestException(message: 'absente', code: 'PGRST202'),
    );
    await expectLater(port.eleves(), throwsA(isA<CapaciteIndisponible>()));
  });

  test('une forme inattendue est refusee', () {
    expect(
      () => elevePourPaiementJson(<String, dynamic>{'prenom': 'Bilal'}),
      throwsFormatException,
    );
  });

  test(
    'emettre les factures : le mois en AAAA-MM-01, le resultat lu',
    () async {
      final List<(String, Map<String, dynamic>?)> appels =
          <(String, Map<String, dynamic>?)>[];
      final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel((
        String f,
        Map<String, dynamic>? p,
      ) async {
        appels.add((f, p));
        return jsonDecode(
          '{"mois": "2026-10-01", "emises": 2, "financees": 1}',
        );
      });
      final FacturesEmises r = await port.emettreFactures(DateTime(2026, 10));
      expect(appels.single.$1, 'emettre_factures_mois');
      expect(appels.single.$2, <String, dynamic>{'p_mois': '2026-10-01'});
      expect(r.emises, 2);
      expect(r.financees, 1);
    },
  );

  for (final (String code, MotifRefusPaiement motif)
      in <(String, MotifRefusPaiement)>[
        ('42501', MotifRefusPaiement.droits),
        ('22023', MotifRefusPaiement.invalide),
        ('P0002', MotifRefusPaiement.sansPolitique),
      ]) {
    test('emettre, refus $code : RefusPaiement(${motif.name})', () async {
      final PaiementsSaisisSupabase port = PaiementsSaisisSupabase.avecAppel(
        (String _, Map<String, dynamic>? _) async =>
            throw PostgrestException(message: 'refus', code: code),
      );
      await expectLater(
        port.emettreFactures(DateTime(2026, 10)),
        throwsA(
          isA<RefusPaiement>().having(
            (RefusPaiement r) => r.motif,
            'motif',
            motif,
          ),
        ),
      );
    });
  }
}
