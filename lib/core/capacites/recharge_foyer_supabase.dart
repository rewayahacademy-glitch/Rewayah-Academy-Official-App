// Adaptateur FI-BR-06 : la recharge du foyer payee chez le prestataire
// (Stripe, rail `WEB_STRIPE`, guide Finance V4 §1.6), migration
// 20261018100000 et fonctions Edge `recharge-payer` et `stripe-webhook`.
//
// - Beneficiaires, recapitulatif et suivi : RPC du titulaire. Montants,
//   total et nouveaux soldes arrivent arretes par le serveur (FI6) ; ici, ils
//   se formatent, rien ne s'additionne.
// - Payer : la fonction `recharge-payer` cree la commande (meme cle, meme
//   commande) et rend l'adresse de la page Stripe, que l'application ouvre.
//   Le retour de Stripe ramene a la page de resultat, qui relit l'etat :
//   **jamais un succes au retour du navigateur** (FI9). Seul le webhook
//   signe credite.
// - Sans cle Stripe configuree sur le serveur (503) ou sans fonction
//   deployee (404) : `CapaciteIndisponible`, l'ecran dit « Paiement pas
//   encore disponible ».

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/format_montant.dart';
import '../finance/montant.dart';
import '../finance/politique_commerciale.dart';
import '../finance/suivi_paiement.dart';
import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import 'capacite_indisponible.dart';
import 'port_recharge_foyer.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'FI-BR-06';

/// L'appel de la fonction Edge `recharge-payer` : rend son corps JSON, ou
/// leve [CapaciteIndisponible] (503, 404) ou l'erreur d'origine.
typedef AppelPaiement = Future<Object?> Function(Map<String, dynamic> corps);

/// La recharge servie par Supabase et Stripe.
class RechargeFoyerSupabase implements PortRechargeFoyer {
  /// Cree l'adaptateur sur le client de l'application. [adresseRetour] rend
  /// l'adresse de la page de resultat, la marque [marqueCommande] a la place
  /// de la commande ; [ouvrirPage] ouvre la page du prestataire.
  RechargeFoyerSupabase(
    SupabaseClient client, {
    required String Function() adresseRetour,
    required void Function(Uri page) ouvrirPage,
  }) : this.avecAppels(
         appelRpcSupabase(client),
         _appelFonction(client),
         adresseRetour: adresseRetour,
         ouvrirPage: ouvrirPage,
       );

  /// Cree l'adaptateur sur des appels injectes (tests).
  RechargeFoyerSupabase.avecAppels(
    this._rpc,
    this._payer, {
    required this.adresseRetour,
    required this.ouvrirPage,
  });

  /// La marque que l'adresse de retour porte a la place de la commande.
  static const String marqueCommande = 'COMMANDE_ID';

  final AppelRpc _rpc;
  final AppelPaiement _payer;

  /// L'adresse de la page de resultat, [marqueCommande] a la place de la
  /// commande.
  final String Function() adresseRetour;

  /// Ouvre la page du prestataire.
  final void Function(Uri page) ouvrirPage;

  static AppelPaiement _appelFonction(SupabaseClient client) =>
      (Map<String, dynamic> corps) async {
        try {
          return (await client.functions.invoke(
            'recharge-payer',
            body: corps,
          )).data;
        } on FunctionException catch (e) {
          if (e.status == 503 || e.status == 404) {
            throw const CapaciteIndisponible(_dependance);
          }
          rethrow;
        }
      };

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async =>
      <BeneficiaireRecharge>[
        for (final Object? b in listeJson(
          await appelerFinance(_rpc, 'recharge_beneficiaires', _dependance),
          'beneficiaires',
        ))
          beneficiaireRechargeJson(b),
      ];

  // Le contrat par offres (EA-10) n'a pas de source dans la Finance V4.
  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible(_dependance),
      );

  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async => recapitulatifRechargeJson(
    await appelerFinance(
      _rpc,
      'recharge_verifier_montants',
      _dependance,
      <String, dynamic>{
        'p_choix': <Map<String, Object>>[
          for (final MontantRecharge c in choix)
            <String, Object>{
              'profilId': c.beneficiaireId,
              'mineur': c.montant.mineur,
              'devise': c.montant.devise,
            },
        ],
      },
    ),
  );

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) async {
    final Map<String, dynamic> j = objetJson(
      await _payer(<String, dynamic>{
        'recapitulatifId': recapitulatifId,
        'cle': cle,
        'retour': adresseRetour(),
      }),
      'paiement',
    );
    final String commande = texteJson(j, 'commandeId');
    final String? page = texteNullableJson(j, 'url');
    // La page du prestataire s'ouvre ; la page de resultat relira l'etat.
    if (page != null) ouvrirPage(Uri.parse(page));
    return commande;
  }

  @override
  Future<SuiviPaiement> suivre(String commandeId) async => suiviPaiementJson(
    await appelerFinance(
      _rpc,
      'recharge_suivre',
      _dependance,
      <String, dynamic>{'p_commande': commandeId},
    ),
  );
}

/// Un beneficiaire de `recharge_beneficiaires`.
BeneficiaireRecharge beneficiaireRechargeJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'beneficiaire');
  return BeneficiaireRecharge(
    id: texteJson(j, 'id'),
    prenom: texteJson(j, 'prenom'),
    cleAvatar: texteNullableJson(j, 'cleAvatar'),
    solde: montantNullableJson(j['solde'], 'solde'),
    montantsProposes: <Montant>[
      for (final Object? m in listeJson(j['montantsProposes'], 'montants'))
        montantJson(m, 'montantPropose'),
    ],
    montantSuggere: montantNullableJson(j['montantSuggere'], 'suggere'),
    montantsRediges: <Montant, String>{
      for (final Object? f in listeJson(
        j['formules'] ?? <Object?>[],
        'formules',
      ))
        if (_formuleRedigee(objetJson(f, 'formule')) case (
          final Montant m,
          final String texte,
        ))
          m: texte,
    },
  );
}

/// Le libelle d'un trimestre ou d'une annee payes d'avance (tarifs du
/// 18/10/2026), ou `null` : un mois ou un reste a payer se lisent en montant.
(Montant, String)? _formuleRedigee(Map<String, dynamic> f) {
  final Montant m = montantJson(f['montant'], 'montant');
  return switch (texteJson(f, 'formule')) {
    'trimestriel' => (
      m,
      t.adulte.recharge.formules.trimestriel(
        montant: sansAncre(formaterMontant(m)),
      ),
    ),
    'annuel' => (
      m,
      t.adulte.recharge.formules.annuel(montant: sansAncre(formaterMontant(m))),
    ),
    'mois' || 'libre' => null,
    final String autre => throw FormatException('formule inconnue: $autre'),
  };
}

/// Le recapitulatif de `recharge_verifier_montants`.
RecapitulatifRecharge recapitulatifRechargeJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'recapitulatif');
  return RecapitulatifRecharge(
    id: texteJson(j, 'id'),
    total: formaterMontant(montantJson(j['total'], 'total')),
    lignes: <LigneRecapitulatif>[
      for (final Object? l in listeJson(j['lignes'], 'lignes'))
        _ligne(objetJson(l, 'ligne')),
    ],
  );
}

LigneRecapitulatif _ligne(Map<String, dynamic> l) {
  final Montant m = montantJson(l['montant'], 'montant');
  return LigneRecapitulatif(
    beneficiaireId: texteJson(l, 'beneficiaireId'),
    prenom: texteJson(l, 'prenom'),
    cleAvatar: texteNullableJson(l, 'cleAvatar'),
    montantPaye: formaterMontant(m),
    soldeAttribue: formaterMontant(m, signe: true),
    statut: t.adulte.recharge.source.avantPaiement,
  );
}

EtatPaiement _etat(Object? v) => switch (v) {
  'preparing' => EtatPaiement.preparation,
  'awaiting_confirmation' => EtatPaiement.attenteConfirmation,
  'confirmed' => EtatPaiement.confirme,
  'allocation_in_progress' => EtatPaiement.allocationEnCours,
  'completed' => EtatPaiement.termine,
  'failed' => EtatPaiement.echec,
  'cancelled' => EtatPaiement.annule,
  'stale' => EtatPaiement.perime,
  _ => throw FormatException('etat de paiement inconnu: $v'),
};

String? _motif(Object? v) {
  final m = t.adulte.recharge.source.motifs;
  return switch (v) {
    null => null,
    'paiement_refuse' => m.paiementRefuse,
    'montant_incoherent' => m.montantIncoherent,
    'session_expiree' => m.sessionExpiree,
    _ => throw FormatException('motif inconnu: $v'),
  };
}

/// Le suivi de `recharge_suivre`.
SuiviPaiement suiviPaiementJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'suivi');
  final Object? moyen = j['moyen'];
  final Object? date = j['date'];
  return SuiviPaiement(
    commandeId: texteJson(j, 'commandeId'),
    etat: _etat(j['etat']),
    total: montantJson(j['total'], 'total'),
    reference: texteNullableJson(j, 'reference'),
    date: date == null ? null : instantJson(date, 'date'),
    moyen: switch (moyen) {
      null => null,
      'web_stripe' => RailPaiement.webStripe,
      _ => throw FormatException('moyen inconnu: $moyen'),
    },
    motif: _motif(j['motif']),
    allocations: <AllocationProfil>[
      for (final Object? a in listeJson(j['allocations'], 'allocations'))
        _allocation(objetJson(a, 'allocation')),
    ],
  );
}

AllocationProfil _allocation(Map<String, dynamic> a) => AllocationProfil(
  profilId: texteJson(a, 'profilId'),
  prenom: texteJson(a, 'prenom'),
  montant: montantJson(a['montant'], 'montant'),
  nouveauSolde: montantNullableJson(a['nouveauSolde'], 'nouveauSolde'),
);
