// Adaptateur FI-BR-06 : la recharge du foyer payee chez le prestataire
// (Stripe, rail `WEB_STRIPE`, guide Finance V4 §1.6), migration
// 20261018100000 et fonctions Edge `recharge-payer` et `stripe-webhook`.
//
// - Beneficiaires, recapitulatif et suivi : RPC du titulaire. Montants,
//   total et nouveaux soldes arrivent arretes par le serveur (FI6) ; ici, ils
//   se formatent, rien ne s'additionne.
// - Payer : la fonction `recharge-payer` cree la commande (meme cle, meme
//   commande). Depuis le 01/11/2026 (directeur : « le paiement doit se faire
//   sur l'app, pas de sortir ailleurs »), elle rend le secret client et la
//   cle publiable : le formulaire de Stripe se monte dans la page de
//   resultat ([SourceFormulairePaiement]). Repli : l'adresse de la page
//   Stripe, que l'application ouvre ; le retour ramene a la page de
//   resultat. Dans les deux cas, la page relit l'etat : **jamais un succes
//   au retour du navigateur** (FI9). Seul le webhook signe credite.
// - Sans cle Stripe configuree sur le serveur (503) ou sans fonction
//   deployee (404) : `CapaciteIndisponible`, l'ecran dit « Paiement pas
//   encore disponible ».

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/format_montant.dart';
import '../finance/formulaire_paiement.dart';
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
class RechargeFoyerSupabase
    implements PortRechargeFoyer, SourceFormulairePaiement, ChauffePaiement {
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

  /// Le formulaire integre de chaque commande ouverte dans cette session de
  /// l'application ; une application rechargee n'en garde aucun.
  final Map<String, FormulairePaiement> _formulaires =
      <String, FormulairePaiement>{};

  /// PAY-UX : la demande de paiement de chaque commande ouverte dans cette
  /// session (recapitulatif et cle), pour redemander un formulaire neuf.
  final Map<String, ({String recapitulatifId, String cle})> _demandes =
      <String, ({String recapitulatifId, String cle})>{};

  @override
  bool peutRouvrir(String commandeId) => _demandes.containsKey(commandeId);

  @override
  Future<FormulairePaiement?> rouvrirFormulaire(String commandeId) async {
    final ({String recapitulatifId, String cle})? d = _demandes[commandeId];
    if (d == null) return null;
    // La meme cle rend la meme commande ; le serveur ferme l'ancien
    // formulaire puis en ouvre un neuf (PAY-UX).
    await payer(recapitulatifId: d.recapitulatifId, cle: d.cle);
    return _formulaires[commandeId];
  }

  @override
  void chaufferPaiement() {
    // Rien n'est cree cote serveur (`chauffer: true`) ; un echec ne dit rien :
    // le toucher de « Payer » fera son appel normal.
    unawaited(
      Future<Object?>.sync(() => _payer(<String, dynamic>{'chauffer': true}))
          .then<void>((Object? _) {}, onError: (Object _) {}),
    );
  }

  @override
  FormulairePaiement? formulairePour(String commandeId) =>
      _formulaires[commandeId];

  @override
  void oublierFormulaire(String commandeId) => _formulaires.remove(commandeId);

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
          // PAY-UX : l'ancien formulaire n'a pas pu etre ferme ; aucune
          // nouvelle session n'est ouverte.
          if (e.status == 409) throw const PaiementPrecedentOuvert();
          // PAIEMENT-FAMILLE-PRIX : la dette ou les mois ont change.
          if (e.status == 422) throw const MontantChange();
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
              if (c.nbMois case final int n) 'nbMois': n,
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
        // PAY-UX : la langue des lignes de paiement.
        'langue': LocaleSettings.instance.currentLocale == AppLocale.ar
            ? 'ar'
            : 'fr',
      }),
      'paiement',
    );
    final String commande = texteJson(j, 'commandeId');
    _demandes[commande] = (recapitulatifId: recapitulatifId, cle: cle);
    final String? secretClient = texteNullableJson(j, 'secretClient');
    final String? clePublique = texteNullableJson(j, 'clePublique');
    if (secretClient != null && clePublique != null) {
      // Le formulaire se montera dans la page de resultat : on reste dans
      // l'application.
      _formulaires[commande] = FormulairePaiement(
        clePublique: clePublique,
        secretClient: secretClient,
        email: texteNullableJson(j, 'email'),
      );
      return commande;
    }
    _formulaires.remove(commande);
    final String? page = texteNullableJson(j, 'url');
    // Repli : la page du prestataire s'ouvre ; la page de resultat relira
    // l'etat.
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
  final List<OptionPaiement> options = <OptionPaiement>[
    for (final Object? o in listeJson(j['options'] ?? <Object?>[], 'options'))
      optionPaiementJson(o),
  ];
  return BeneficiaireRecharge(
    id: texteJson(j, 'id'),
    prenom: texteJson(j, 'prenom'),
    cleAvatar: texteNullableJson(j, 'cleAvatar'),
    solde: montantNullableJson(j['solde'], 'solde'),
    etat: j['etat'] == null ? null : etatRechargeJson(j['etat']),
    options: options,
    dette: j['dette'] == null ? null : detteRechargeJson(j['dette']),
    tarif: montantNullableJson(j['tarif'], 'tarif'),
    rang: j['rang'] is int ? j['rang'] as int : null,
    montantsProposes: <Montant>[
      for (final Object? m in listeJson(j['montantsProposes'], 'montants'))
        montantJson(m, 'montantPropose'),
    ],
    montantSuggere: montantNullableJson(j['montantSuggere'], 'suggere'),
    montantsRediges: options.isNotEmpty
        ? <Montant, String>{
            for (final OptionPaiement o in options) o.montant: libelleOption(o),
          }
        : <Montant, String>{
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

/// L'etat d'un profil rendu par le serveur.
EtatRecharge etatRechargeJson(Object? v) => switch (v) {
  'en_classe' => EtatRecharge.enClasse,
  'avant_premier_mois' => EtatRecharge.avantPremierMois,
  'aucun_creneau' => EtatRecharge.aucunCreneau,
  _ => throw FormatException('etat de recharge inconnu: $v'),
};

/// Une offre de `recharge_beneficiaires` (dette + N mois d'avance).
OptionPaiement optionPaiementJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'option');
  final String formule = texteJson(j, 'formule');
  if (!const <String>{
    'libre',
    'mois',
    'avance',
    'trimestriel',
    'annuel',
  }.contains(formule)) {
    throw FormatException('formule inconnue: $formule');
  }
  return OptionPaiement(
    nbMois: entierJson(j, 'nbMois'),
    formule: formule,
    montant: montantJson(j['montant'], 'montant'),
    dette: montantJson(j['dette'], 'dette'),
    avance: montantJson(j['avance'], 'avance'),
    moisCouverts: moisCouvertsJson(j['moisCouverts']),
    lignes: <LigneOption>[
      for (final Object? l in listeJson(j['lignes'] ?? <Object?>[], 'lignes'))
        _ligneOption(objetJson(l, 'ligne')),
    ],
    nonAppliquees: <RemiseNonAppliquee>[
      for (final Object? n in listeJson(
        j['nonAppliquees'] ?? <Object?>[],
        'nonAppliquees',
      ))
        _nonAppliquee(objetJson(n, 'nonAppliquee')),
    ],
  );
}

/// Les mois couverts rendus par le serveur, ou `null`.
MoisCouverts? moisCouvertsJson(Object? v) {
  if (v == null) return null;
  final Map<String, dynamic> j = objetJson(v, 'moisCouverts');
  return MoisCouverts(
    debut: dateJson(j['debut'], 'debut'),
    fin: dateJson(j['fin'], 'fin'),
    nbMois: entierJson(j, 'nbMois'),
  );
}

int? _entierNullable(Map<String, dynamic> j, String cle) =>
    j[cle] == null ? null : entierJson(j, cle);

LigneOption _ligneOption(Map<String, dynamic> l) => LigneOption(
  code: texteJson(l, 'code'),
  montant: montantNullableJson(l['montant'], 'montant'),
  pourMille: _entierNullable(l, 'pourMille'),
  rang: _entierNullable(l, 'rang'),
  nbMois: _entierNullable(l, 'nbMois'),
);

RemiseNonAppliquee _nonAppliquee(Map<String, dynamic> n) => RemiseNonAppliquee(
  type: texteJson(n, 'type'),
  code: texteJson(n, 'code'),
  montant: montantNullableJson(n['montant'], 'montant'),
  pourMille: _entierNullable(n, 'pourMille'),
);

/// La dette d'un profil, mois par mois.
DetteRecharge detteRechargeJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'dette');
  return DetteRecharge(
    total: montantJson(j['total'], 'total'),
    solde: montantJson(j['solde'], 'solde'),
    mois: <MoisDu>[
      for (final Object? m in listeJson(j['mois'] ?? <Object?>[], 'mois'))
        _moisDu(objetJson(m, 'moisDu')),
    ],
  );
}

MoisDu _moisDu(Map<String, dynamic> m) => MoisDu(
  mois: dateJson(m['mois'], 'mois'),
  montant: montantJson(m['montant'], 'montant'),
  apercu: booleenJson(m, 'apercu'),
  lignes: <LigneDue>[
    for (final Object? l in listeJson(m['lignes'] ?? <Object?>[], 'lignes'))
      _ligneDue(objetJson(l, 'ligneDue')),
  ],
  prorata: m['prorata'] == null
      ? null
      : _prorata(objetJson(m['prorata'], 'prorata')),
);

LigneDue _ligneDue(Map<String, dynamic> l) => LigneDue(
  nature: texteJson(l, 'nature'),
  montant: montantJson(l['montant'], 'montant'),
  rang: _entierNullable(l, 'rang'),
);

ProrataExplique _prorata(Map<String, dynamic> p) => ProrataExplique(
  entreeLe: dateJson(p['entreeLe'], 'entreeLe'),
  seancesRestantes: entierJson(p, 'seancesRestantes'),
  seancesDuMois: entierJson(p, 'seancesDuMois'),
);

/// Le libelle d'une offre au pas du « moins / plus » : le montant que le
/// serveur rend, dit en mots (la dette seule, la dette et N mois d'avance, N
/// mois d'avance). Aucun chiffre n'est calcule ici.
String libelleOption(OptionPaiement o) {
  final String montant = sansAncre(formaterMontant(o.montant));
  if (o.formule == 'mois' && o.moisCouverts == null) {
    return t.adulte.recharge.explication.libelleUnMois(montant: montant);
  }
  if (o.nbMois == 0) {
    return t.adulte.recharge.explication.libelleDette(montant: montant);
  }
  if (!o.dette.estNul) {
    return t.adulte.recharge.explication.libelleDetteEtMois(
      n: o.nbMois,
      montant: montant,
    );
  }
  return t.adulte.recharge.explication.libelleMois(
    n: o.nbMois,
    montant: montant,
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
    'mois' || 'libre' || 'avance' => null,
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
    moisCouverts: moisCouvertsJson(l['moisCouverts']),
    nbMois: _entierNullable(l, 'nbMois'),
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
