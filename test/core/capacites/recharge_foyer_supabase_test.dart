// FI-BR-06 : l'adaptateur de la recharge payee chez Stripe. Les JSON de
// reference sont ceux que rendent reellement les RPC de la migration
// 20261018100000 sur une base rejouee (fixtures de
// `scenarios_fi_br06_recharge_stripe.sql`).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/recharge_foyer_supabase.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

const String _beneficiaires =
    '[{"id": "f6000000-0000-4000-8000-0000000000e2", "solde": {"devise": '
    '"USD", "mineur": 5000}, "prenom": "Bilal", "cleAvatar": null, '
    '"montantSuggere": {"devise": "USD", "mineur": 2000}, "montantsProposes": '
    '[{"devise": "USD", "mineur": 2000}, {"devise": "USD", "mineur": 5000}, '
    '{"devise": "USD", "mineur": 10000}, {"devise": "USD", "mineur": 15000}]}]';

// Tarifs du 18/10/2026 (FAC-E-01) : le mois regle, le trimestre et l'annee
// payes d'avance sont proposes avec leur formule.
const String _beneficiairesV2 =
    '[{"id": "fe000000-0000-4000-8000-0000000000e4", "solde": {"devise": '
    '"USD", "mineur": 0}, "prenom": "Aicha", "cleAvatar": null, '
    '"formules": [{"montant": {"devise": "USD", "mineur": 6500}, "formule": '
    '"mois"}, {"montant": {"devise": "USD", "mineur": 18500}, "formule": '
    '"trimestriel"}, {"montant": {"devise": "USD", "mineur": 70200}, '
    '"formule": "annuel"}], "montantSuggere": null, "montantsProposes": '
    '[{"devise": "USD", "mineur": 6500}, {"devise": "USD", "mineur": 18500}, '
    '{"devise": "USD", "mineur": 70200}]}]';

const String _recap =
    '{"id": "ba7d2b69-d814-485e-88a0-448ac82f5977", "total": {"devise": '
    '"USD", "mineur": 15000}, "lignes": [{"prenom": "Yasmine", "montant": '
    '{"devise": "USD", "mineur": 5000}, "cleAvatar": null, "beneficiaireId": '
    '"f6000000-0000-4000-8000-0000000000e1"}, {"prenom": "Bilal", "montant": '
    '{"devise": "USD", "mineur": 10000}, "cleAvatar": null, "beneficiaireId": '
    '"f6000000-0000-4000-8000-0000000000e2"}]}';

const String _termine =
    '{"date": "2026-10-18T03:53:29.902576+00:00", "etat": "completed", '
    '"motif": null, "moyen": "web_stripe", "total": {"devise": "USD", '
    '"mineur": 15000}, "reference": "RWY-DBC419E1", "commandeId": '
    '"fc8994b9-9870-4320-bbe2-c78ccb83e08a", "allocations": [{"prenom": '
    '"Yasmine", "montant": {"devise": "USD", "mineur": 5000}, "profilId": '
    '"f6000000-0000-4000-8000-0000000000e1", "nouveauSolde": {"devise": '
    '"USD", "mineur": 0}}, {"prenom": "Bilal", "montant": {"devise": "USD", '
    '"mineur": 10000}, "profilId": "f6000000-0000-4000-8000-0000000000e2", '
    '"nouveauSolde": {"devise": "USD", "mineur": 5000}}]}';

const String _echec =
    '{"date": "2026-10-18T03:53:29.924846+00:00", "etat": "failed", "motif": '
    '"paiement_refuse", "moyen": null, "total": {"devise": "USD", "mineur": '
    '5000}, "reference": "RWY-43446B1D", "commandeId": '
    '"c1e653ec-36f5-494d-947d-939f88589f1c", "allocations": [{"prenom": '
    '"Yasmine", "montant": {"devise": "USD", "mineur": 5000}, "profilId": '
    '"f6000000-0000-4000-8000-0000000000e1", "nouveauSolde": null}]}';

RechargeFoyerSupabase _port({
  Object? rpc,
  Object? fonction,
  List<(String, Map<String, dynamic>?)>? appels,
  List<Map<String, dynamic>>? corps,
  List<Uri>? pages,
}) => RechargeFoyerSupabase.avecAppels(
  (String f, Map<String, dynamic>? p) async {
    appels?.add((f, p));
    return rpc;
  },
  (Map<String, dynamic> c) async {
    corps?.add(c);
    if (fonction is Exception) throw fonction;
    return fonction;
  },
  adresseRetour: () =>
      'https://app.test/#/tuteur/foyer/recharge/result?commande=COMMANDE_ID',
  ouvrirPage: (Uri u) => pages?.add(u),
);

void main() {
  test(
    'beneficiaires : montants proposes et suggere, rendus tels quels',
    () async {
      final List<(String, Map<String, dynamic>?)> appels =
          <(String, Map<String, dynamic>?)>[];
      final List<BeneficiaireRecharge> b = await _port(
        rpc: jsonDecode(_beneficiaires),
        appels: appels,
      ).beneficiaires();
      expect(appels.single.$1, 'recharge_beneficiaires');
      expect(b.single.prenom, 'Bilal');
      expect(b.single.solde, const Montant(5000, 'USD'));
      expect(b.single.montantSuggere, const Montant(2000, 'USD'));
      expect(b.single.montantsProposes, hasLength(4));
    },
  );

  test('beneficiaires : le trimestre et l annee se lisent avec leur '
      'formule, le mois en montant', () async {
    final List<BeneficiaireRecharge> b = await _port(
      rpc: jsonDecode(_beneficiairesV2),
    ).beneficiaires();
    const Montant trimestre = Montant(18500, 'USD');
    const Montant annee = Montant(70200, 'USD');
    expect(b.single.montantsProposes, hasLength(3));
    expect(b.single.montantsRediges.keys, <Montant>[trimestre, annee]);
    expect(
      b.single.montantsRediges[trimestre],
      t.adulte.recharge.formules.trimestriel(
        montant: sansAncre(formaterMontant(trimestre)),
      ),
    );
    expect(
      b.single.montantsRediges[annee],
      t.adulte.recharge.formules.annuel(
        montant: sansAncre(formaterMontant(annee)),
      ),
    );
    final List<Object?> inconnue =
        jsonDecode(_beneficiairesV2) as List<Object?>;
    ((inconnue.single! as Map)['formules'] as List).add(<String, Object?>{
      'montant': <String, Object?>{'devise': 'USD', 'mineur': 1},
      'formule': 'semestriel',
    });
    expect(() => _port(rpc: inconnue).beneficiaires(), throwsFormatException);
  });

  test('recapitulatif : un montant par profil, le total arrete par le '
      'serveur', () async {
    final List<(String, Map<String, dynamic>?)> appels =
        <(String, Map<String, dynamic>?)>[];
    final RecapitulatifRecharge r =
        await _port(
          rpc: jsonDecode(_recap),
          appels: appels,
        ).verifierMontants(const <MontantRecharge>[
          MontantRecharge(beneficiaireId: 'e1', montant: Montant(5000, 'USD')),
        ]);
    expect(appels.single.$1, 'recharge_verifier_montants');
    expect(appels.single.$2, <String, dynamic>{
      'p_choix': <Map<String, Object>>[
        <String, Object>{'profilId': 'e1', 'mineur': 5000, 'devise': 'USD'},
      ],
    });
    expect(r.id, 'ba7d2b69-d814-485e-88a0-448ac82f5977');
    expect(r.total, formaterMontant(const Montant(15000, 'USD')));
    expect(r.lignes.map((LigneRecapitulatif l) => l.prenom), <String>[
      'Yasmine',
      'Bilal',
    ]);
    expect(r.lignes.first.statut, t.adulte.recharge.source.avantPaiement);
  });

  test('payer : la commande, la page Stripe ouverte, l adresse de retour '
      'envoyee', () async {
    final List<Map<String, dynamic>> corps = <Map<String, dynamic>>[];
    final List<Uri> pages = <Uri>[];
    final String commande = await _port(
      fonction: <String, dynamic>{
        'commandeId': 'fc8994b9-9870-4320-bbe2-c78ccb83e08a',
        'url': 'https://checkout.stripe.com/c/pay/cs_test_1',
      },
      corps: corps,
      pages: pages,
    ).payer(recapitulatifId: 'r1', cle: 'k1');
    expect(commande, 'fc8994b9-9870-4320-bbe2-c78ccb83e08a');
    expect(corps.single['recapitulatifId'], 'r1');
    expect(corps.single['cle'], 'k1');
    expect(
      corps.single['retour'],
      contains(RechargeFoyerSupabase.marqueCommande),
    );
    expect(pages.single.host, 'checkout.stripe.com');
  });

  test(
    'payer, commande deja decidee : aucune page, le resultat le dira',
    () async {
      final List<Uri> pages = <Uri>[];
      final String commande = await _port(
        fonction: <String, dynamic>{'commandeId': 'c1', 'url': null},
        pages: pages,
      ).payer(recapitulatifId: 'r1', cle: 'k1');
      expect(commande, 'c1');
      expect(pages, isEmpty);
    },
  );

  test('payer sans Stripe configure : capacite indisponible', () async {
    await expectLater(
      _port(fonction: const CapaciteIndisponible('FI-BR-06'))
          .payer(recapitulatifId: 'r1', cle: 'k1'),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test(
    'suivi termine : moyen, reference, repartition et nouveaux soldes',
    () async {
      final SuiviPaiement s = await _port(rpc: jsonDecode(_termine))
          .suivre('fc8994b9-9870-4320-bbe2-c78ccb83e08a');
      expect(s.etat, EtatPaiement.termine);
      expect(s.moyen, RailPaiement.webStripe);
      expect(s.reference, 'RWY-DBC419E1');
      expect(s.total, const Montant(15000, 'USD'));
      expect(s.allocations.last.nouveauSolde, const Montant(5000, 'USD'));
      expect(s.motif, isNull);
    },
  );

  test('suivi en echec : le motif redige, aucun nouveau solde', () async {
    final SuiviPaiement s = await _port(rpc: jsonDecode(_echec)).suivre('c');
    expect(s.etat, EtatPaiement.echec);
    expect(s.motif, t.adulte.recharge.source.motifs.paiementRefuse);
    expect(s.allocations.single.nouveauSolde, isNull);
    expect(s.moyen, isNull);
  });

  test('chaque etat de la base se lit, un etat inconnu est refuse', () {
    for (final (String sql, EtatPaiement etat) in <(String, EtatPaiement)>[
      ('preparing', EtatPaiement.preparation),
      ('awaiting_confirmation', EtatPaiement.attenteConfirmation),
      ('confirmed', EtatPaiement.confirme),
      ('allocation_in_progress', EtatPaiement.allocationEnCours),
      ('completed', EtatPaiement.termine),
      ('failed', EtatPaiement.echec),
      ('cancelled', EtatPaiement.annule),
      ('stale', EtatPaiement.perime),
    ]) {
      expect(
        suiviPaiementJson(jsonDecode(_echec.replaceFirst('"failed"', '"$sql"')))
            .etat,
        etat,
      );
    }
    expect(
      () => suiviPaiementJson(
        jsonDecode(_echec.replaceFirst('"failed"', '"autre"')),
      ),
      throwsFormatException,
    );
  });
}
