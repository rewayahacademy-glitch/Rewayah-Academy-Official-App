// La demonstration des obligations de contractuels (CPT-BR-08). Posee vide
// par CPT-F, remplie par CPT-CTR-1 ; **propriete de la voie CPT-CTR**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §22.4 : « Karim Studio -
// Facture #024 - 350 USD » (`SocleComptableDemo.obligationFacture024`) est
// approuvee, donc « Payer ». Aucune ecriture reelle : les creations et les
// approbations vivent en memoire, le temps de la page (K-09, K-28).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_obligations_contractuels.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import 'socle_comptable_demo.dart';

/// Le prefixe des identifiants d'obligation payable (la cible de « Payer »).
const String _payablePrefixe = 'obl-pay-';

/// Les obligations de contractuels en demonstration.
class ObligationsContractuelsDemo implements PortObligationsContractuels {
  /// Cree le double. [peutCreer] faux rend la delegation « Hors delegation »
  /// (le Comptable n'est pas autorise a creer, §34).
  ObligationsContractuelsDemo({this.peutCreer = true})
    : _obligations = List<ObligationContractuel>.of(_depart());

  /// Vrai quand la demonstration autorise la creation.
  final bool peutCreer;

  final List<ObligationContractuel> _obligations;
  int _compteur = 0;

  static const String _direction = 'la direction';
  static final String _comptable = SocleComptableDemo.leComptable.nom;

  static IdentiteBeneficiaire _ctr(String id) => SocleComptableDemo.contractuels
      .firstWhere((IdentiteBeneficiaire c) => c.id == id);

  static Montant _usd(int unites) => SocleComptableDemo.usd(unites);

  static DateTime _jour(int decalage) =>
      SocleComptableDemo.aujourdhui.add(Duration(days: decalage));

  static List<ObligationContractuel> _depart() => <ObligationContractuel>[
    // §22.4 : approuvee, montant fige, « Payer 350 USD ».
    ObligationContractuel(
      id: SocleComptableDemo.obligationFacture024,
      type: TypeObligationContractuel.ponctuelle,
      beneficiaire: _ctr('ctr-01'),
      objet: 'Facture #024',
      montant: _usd(350),
      echeance: _jour(6),
      etat: EtatObligationContractuel.approuvee,
      auteur: _direction,
      justificatif: 'facture-024.pdf',
      centreCout: 'Communication',
      approbateur: _direction,
      obligationPayableId: '${_payablePrefixe}ctr-024',
      profilBeneficiaire: EtatProfilPaiement.verifie,
      lignes: <LigneCalcul>[
        LigneCalcul(
          id: 'lig-024-1',
          libelle: 'Facture #024',
          montant: _usd(350),
          source: 'Saisi à la création',
          auteur: _direction,
          validation: 'Approuvée par la direction',
          date: _jour(-3),
        ),
      ],
      permissions: const PermissionsFinance(
        actions: <ActionFinance>{ActionFinance.payer},
      ),
    ),
    // Auteur = le Comptable : l'approbation revient a une autre personne.
    ObligationContractuel(
      id: 'obl-ctr-025',
      type: TypeObligationContractuel.ponctuelle,
      beneficiaire: _ctr('ctr-02'),
      objet: 'Devis affiches de la rentrée',
      montant: _usd(180),
      echeance: _jour(12),
      etat: EtatObligationContractuel.aApprouver,
      auteur: _comptable,
      justificatif: 'devis-noor-affiches.pdf',
      centreCout: 'Communication',
      approbateur: _direction,
      profilBeneficiaire: EtatProfilPaiement.verifie,
      lignes: <LigneCalcul>[
        LigneCalcul(
          id: 'lig-025-1',
          libelle: 'Devis affiches de la rentrée',
          montant: _usd(180),
          source: 'Saisi à la création',
          auteur: _comptable,
          date: _jour(-1),
        ),
      ],
      permissions: const PermissionsFinance(
        blocages: <ActionFinance, RaisonBlocage>{
          ActionFinance.approuver: RaisonBlocage.autoPaiement,
        },
      ),
    ),
    // Recurrente, calculee : deux lignes, la seconde est un ajustement
    // independant avec sa source, son auteur et sa validation (§23). Sa
    // methode de paiement est en verification : « Payer » est absent.
    ObligationContractuel(
      id: 'obl-ctr-026',
      type: TypeObligationContractuel.recurrente,
      beneficiaire: _ctr('ctr-04'),
      objet: "Maintenance mensuelle d'octobre",
      montant: _usd(420),
      echeance: _jour(3),
      etat: EtatObligationContractuel.approuvee,
      auteur: _direction,
      centreCout: 'Infrastructure',
      approbateur: _direction,
      obligationPayableId: '${_payablePrefixe}ctr-026',
      profilBeneficiaire: EtatProfilPaiement.enVerification,
      lignes: <LigneCalcul>[
        LigneCalcul(
          id: 'lig-026-1',
          libelle: 'Forfait mensuel',
          montant: _usd(400),
          source: 'Contrat de maintenance',
          date: _jour(-4),
        ),
        LigneCalcul(
          id: 'lig-026-2',
          libelle: 'Intervention supplémentaire',
          montant: _usd(20),
          source: 'Demande de la direction',
          auteur: _direction,
          validation: 'Validée le 2 octobre',
          date: _jour(-2),
        ),
      ],
      permissions: const PermissionsFinance(
        blocages: <ActionFinance, RaisonBlocage>{
          ActionFinance.payer: RaisonBlocage.verificationRequise,
        },
      ),
    ),
    // Externe sans compte : invitation envoyee ; le Comptable peut approuver
    // (l'auteur est la direction).
    ObligationContractuel(
      id: 'obl-ctr-027',
      type: TypeObligationContractuel.ponctuelle,
      beneficiaire: _ctr('ctr-05'),
      objet: 'Traduction du support de Tajwid',
      montant: _usd(260),
      echeance: _jour(20),
      etat: EtatObligationContractuel.aApprouver,
      auteur: _direction,
      centreCout: 'Pédagogie',
      approbateur: _comptable,
      profilBeneficiaire: EtatProfilPaiement.invitationEnvoyee,
      lignes: <LigneCalcul>[
        LigneCalcul(
          id: 'lig-027-1',
          libelle: 'Traduction du support de Tajwid',
          montant: _usd(260),
          source: 'Saisi à la création',
          auteur: _direction,
          date: _jour(-2),
        ),
      ],
      permissions: const PermissionsFinance(
        actions: <ActionFinance>{ActionFinance.approuver},
      ),
    ),
    ObligationContractuel(
      id: 'obl-ctr-028',
      type: TypeObligationContractuel.ponctuelle,
      beneficiaire: _ctr('ctr-03'),
      objet: 'Réassort de fournitures',
      montant: _usd(45),
      echeance: _jour(15),
      etat: EtatObligationContractuel.brouillon,
      auteur: _comptable,
      centreCout: 'Administration',
      profilBeneficiaire: EtatProfilPaiement.verifie,
    ),
    // L'historique : payee, refusee.
    ObligationContractuel(
      id: 'obl-ctr-020',
      type: TypeObligationContractuel.ponctuelle,
      beneficiaire: _ctr('ctr-03'),
      objet: 'Impression des carnets',
      montant: _usd(90),
      echeance: _jour(-9),
      etat: EtatObligationContractuel.payee,
      auteur: _direction,
      centreCout: 'Pédagogie',
      approbateur: _direction,
      obligationPayableId: '${_payablePrefixe}ctr-020',
      profilBeneficiaire: EtatProfilPaiement.verifie,
    ),
    ObligationContractuel(
      id: 'obl-ctr-021',
      type: TypeObligationContractuel.ponctuelle,
      beneficiaire: _ctr('ctr-02'),
      objet: 'Devis banderole',
      montant: _usd(60),
      echeance: _jour(-5),
      etat: EtatObligationContractuel.refusee,
      auteur: _comptable,
      centreCout: 'Communication',
      approbateur: _direction,
      motifRefus: "Doublon du devis d'octobre.",
      profilBeneficiaire: EtatProfilPaiement.verifie,
    ),
    ObligationContractuel(
      id: 'obl-ctr-022',
      type: TypeObligationContractuel.recurrente,
      beneficiaire: _ctr('ctr-04'),
      objet: 'Maintenance mensuelle de septembre',
      montant: _usd(400),
      echeance: _jour(-24),
      etat: EtatObligationContractuel.payee,
      auteur: _direction,
      centreCout: 'Infrastructure',
      approbateur: _direction,
      obligationPayableId: '${_payablePrefixe}ctr-022',
      profilBeneficiaire: EtatProfilPaiement.verifie,
    ),
  ];

  @override
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  ) async => <ObligationContractuel>[
    for (final ObligationContractuel o in _obligations)
      if ((filtre.etat == null || o.etat == filtre.etat) &&
          (filtre.type == null || o.type == filtre.type))
        o,
  ];

  @override
  Future<ContexteCreationObligation> contexteCreation() async =>
      ContexteCreationObligation(
        permissions: peutCreer
            ? const PermissionsFinance(
                actions: <ActionFinance>{ActionFinance.creerObligation},
              )
            : const PermissionsFinance(
                blocages: <ActionFinance, RaisonBlocage>{
                  ActionFinance.creerObligation: RaisonBlocage.horsDelegation,
                },
              ),
        beneficiaires: SocleComptableDemo.contractuels,
        beneficiairePropose: 'ctr-01',
        centresCout: const <String>[
          'Administration',
          'Communication',
          'Infrastructure',
          'Pédagogie',
        ],
        centreCoutPropose: 'Administration',
        echeanceProposee: _jour(14),
      );

  @override
  Future<ObligationContractuel> detail(String obligationId) {
    for (final ObligationContractuel o in _obligations) {
      if (o.id == obligationId) {
        return Future<ObligationContractuel>.value(o);
      }
    }
    return Future<ObligationContractuel>.error(
      const CapaciteIndisponible('CPT-BR-08'),
    );
  }

  @override
  Future<ObligationContractuel> creer({
    required BrouillonObligationContractuel brouillon,
    required String cleIdempotence,
  }) async {
    _compteur++;
    final String? externe = brouillon.nouveauBeneficiaire;
    final IdentiteBeneficiaire beneficiaire = externe != null
        ? IdentiteBeneficiaire(
            id: 'ctr-nouveau-$_compteur',
            nom: externe,
            type: TypeBeneficiaire.contractuel,
          )
        : _ctr(brouillon.beneficiaireId);
    final ObligationContractuel creee = ObligationContractuel(
      id: 'obl-ctr-nouvelle-$_compteur',
      type: brouillon.type,
      beneficiaire: beneficiaire,
      objet: brouillon.objet,
      montant: brouillon.montant,
      echeance: brouillon.echeance,
      etat: EtatObligationContractuel.aApprouver,
      auteur: _comptable,
      justificatif: brouillon.justificatif,
      centreCout: brouillon.centreCout,
      approbateur: _direction,
      profilBeneficiaire: externe != null
          ? EtatProfilPaiement.invitationEnvoyee
          : EtatProfilPaiement.verifie,
      lignes: <LigneCalcul>[
        LigneCalcul(
          id: 'lig-nouvelle-$_compteur',
          libelle: brouillon.objet,
          montant: brouillon.montant,
          source: 'Saisi à la création',
          auteur: _comptable,
          date: SocleComptableDemo.aujourdhui,
        ),
      ],
      permissions: const PermissionsFinance(
        blocages: <ActionFinance, RaisonBlocage>{
          ActionFinance.approuver: RaisonBlocage.autoPaiement,
        },
      ),
    );
    _obligations.insert(0, creee);
    return creee;
  }

  @override
  Future<ObligationContractuel> approuver(String obligationId) async {
    final int i = _obligations.indexWhere(
      (ObligationContractuel o) => o.id == obligationId,
    );
    if (i < 0) {
      throw const CapaciteIndisponible('CPT-BR-08');
    }
    final ObligationContractuel o = _obligations[i];
    final ObligationContractuel approuvee = ObligationContractuel(
      id: o.id,
      type: o.type,
      beneficiaire: o.beneficiaire,
      objet: o.objet,
      montant: o.montant,
      echeance: o.echeance,
      etat: EtatObligationContractuel.approuvee,
      auteur: o.auteur,
      justificatif: o.justificatif,
      centreCout: o.centreCout,
      approbateur: _comptable,
      obligationPayableId: '$_payablePrefixe${o.id}',
      profilBeneficiaire: o.profilBeneficiaire,
      lignes: o.lignes,
      permissions: o.profilBeneficiaire == EtatProfilPaiement.verifie
          ? const PermissionsFinance(
              actions: <ActionFinance>{ActionFinance.payer},
            )
          : const PermissionsFinance(
              blocages: <ActionFinance, RaisonBlocage>{
                ActionFinance.payer: RaisonBlocage.infosManquantes,
              },
            ),
    );
    _obligations[i] = approuvee;
    return approuvee;
  }

  @override
  Future<ObligationContractuel> inviterBeneficiaire(String obligationId) =>
      detail(obligationId);

  @override
  Future<List<EntreeJournal>> journal(String obligationId) async {
    final ObligationContractuel o = await detail(obligationId);
    return <EntreeJournal>[
      if (o.etat == EtatObligationContractuel.approuvee ||
          o.etat == EtatObligationContractuel.payee)
        EntreeJournal(
          id: 'jr-$obligationId-2',
          date: _jour(-2),
          initiateur: o.approbateur ?? _direction,
          objet: o.objet,
          source: 'Approbation',
          ancienEtat: 'À approuver',
          nouvelEtat: 'Approuvée',
          montant: o.montant,
        ),
      EntreeJournal(
        id: 'jr-$obligationId-1',
        date: _jour(-3),
        initiateur: o.auteur,
        objet: o.objet,
        source: 'Création',
        nouvelEtat: o.etat == EtatObligationContractuel.brouillon
            ? 'Brouillon'
            : 'À approuver',
        montant: o.montant,
      ),
    ];
  }
}

/// Les surcharges de la demonstration des contractuels.
List<Override> surchargesDemoContractuels() => <Override>[
  portObligationsContractuelsProvider.overrideWithValue(
    ObligationsContractuelsDemo(),
  ),
];
