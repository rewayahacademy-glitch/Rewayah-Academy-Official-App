// La demonstration d'Aujourd'hui du Comptable (CPT-BR-03 ; CPT-JOUR).
// **Propriete de la voie CPT (CPT-JOUR)** (`20_comptable/02_DECOUPAGE.md`,
// liste B). Les identites viennent de `socle_comptable_demo.dart` ; aucun
// appel serveur, aucune vraie coordonnee, aucun vrai paiement (K-09, K-28).
//
// Donnees tenues pour la spec §44 : 12 paiements prets, 2 infos
// manquantes, 1 modification recente de methode, 1 validation
// supplementaire, 1 payout echoue, 1 remboursement, 3 encaissements,
// 2 rapprochements, 1 Reserve strategique sous son objectif fixe (la
// politique de `direction_demo.dart`), 1 fournisseur indisponible. Les sommes sont **rendues par la
// source** : ici, ecrites a la main et coherentes entre elles (detenue =
// protegee + transit + libre), jamais additionnees par l'ecran.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_aujourdhui_comptable.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import 'direction_demo.dart';
import 'socle_comptable_demo.dart';

/// Les donnees d'Aujourd'hui en demonstration.
abstract final class DonneesAujourdhuiDemo {
  /// La synthese de tresorerie : la Tresorerie libre est ce qui reste apres
  /// les fonds proteges et le transit (§11). Memes chiffres que la
  /// Tresorerie (`tresorerie_demo.dart`, CPT-FUS).
  static final SyntheseTresorerie tresorerie = SyntheseTresorerie(
    detenue: SocleComptableDemo.usd(48650),
    protegee: SocleComptableDemo.usd(37900),
    enTransit: SocleComptableDemo.usd(1250),
    libre: SocleComptableDemo.usd(9500),
  );

  /// La Reserve strategique, sous son objectif fixe : la meme que la
  /// politique de la direction (`direction_demo.dart`) et le coffre de la
  /// Tresorerie (CPT-FUS).
  static final IndicateursReserve reserve = PolitiqueReserveDemo.sousObjectif;

  /// La file : « A traiter » et « Alertes » melangees, chaque element avec
  /// la route de son ecran canonique deja filtre (§5.1).
  static final List<ElementAttention> file = <ElementAttention>[
    ElementAttention(
      id: 'att-enseignants',
      type: TypeAlerteComptable.enseignantsAPayer,
      compteur: 12,
      montant: SocleComptableDemo.usd(4860),
      depuis: DateTime(2026, 10, 1),
      route: Routes.comptablePaiementsFiltres(
        filtre: 'prets',
        type: 'enseignant',
      ),
    ),
    ElementAttention(
      id: 'att-contractuels',
      type: TypeAlerteComptable.contractuelsAEcheance,
      compteur: 2,
      montant: SocleComptableDemo.usd(650),
      depuis: DateTime(2026, 10, 3),
      route: Routes.comptableContractuels,
    ),
    ElementAttention(
      id: 'att-infos',
      type: TypeAlerteComptable.infosManquantes,
      compteur: 2,
      depuis: DateTime(2026, 9, 28),
      route: Routes.comptablePaiementsFiltres(filtre: 'infos'),
    ),
    ElementAttention(
      id: 'att-payout-echoue',
      type: TypeAlerteComptable.payoutEchoue,
      compteur: 1,
      depuis: DateTime(2026, 10, 3),
      route: Routes.comptablePaiementObligationPour('obl-ens-07-2026-09'),
    ),
    ElementAttention(
      id: 'att-validation',
      type: TypeAlerteComptable.validationRequise,
      compteur: 1,
      depuis: DateTime(2026, 10, 2),
      route: Routes.comptablePaiementsFiltres(filtre: 'validation'),
    ),
    ElementAttention(
      id: 'att-famille-echoue',
      type: TypeAlerteComptable.paiementFamilleEchoue,
      compteur: 1,
      depuis: DateTime(2026, 10, 3),
      route: Routes.comptableEncaissementPour('enc-03'),
    ),
    ElementAttention(
      id: 'att-rapprochement',
      type: TypeAlerteComptable.transactionNonRapprochee,
      compteur: 2,
      depuis: DateTime(2026, 10, 2),
      route: Routes.comptableRapprochement,
    ),
    ElementAttention(
      id: 'att-remboursement',
      type: TypeAlerteComptable.remboursementEnAttente,
      compteur: 1,
      depuis: DateTime(2026, 9, 30),
      route: Routes.comptableEncaissements,
    ),
    const ElementAttention(
      id: 'att-reserve',
      type: TypeAlerteComptable.reserveSousObjectif,
      compteur: 1,
      route: Routes.comptableTresorerie,
    ),
    ElementAttention(
      id: 'att-methode',
      type: TypeAlerteComptable.methodeModifieeRecemment,
      compteur: 1,
      depuis: DateTime(2026, 10, 2),
      route: Routes.comptableBeneficiairePour(
        SocleComptableDemo.enseignants[3].id,
      ),
    ),
    ElementAttention(
      id: 'att-doublon',
      type: TypeAlerteComptable.doublonPotentiel,
      compteur: 1,
      depuis: DateTime(2026, 10, 3),
      route: Routes.comptableRapprochement,
    ),
  ];

  /// Les echeances proches : obligations et remboursements seulement
  /// (DR-25), aucun nom de fournisseur reel.
  static final List<EcheanceComptable> echeances = <EcheanceComptable>[
    EcheanceComptable(
      id: 'ech-paie-octobre',
      date: DateTime(2026, 10, 5),
      libelle: "Paie d'octobre, 12 enseignants",
      montant: SocleComptableDemo.usd(4860),
      route: Routes.comptablePaiementsFiltres(
        filtre: 'prets',
        type: 'enseignant',
      ),
    ),
    EcheanceComptable(
      id: 'ech-facture-024',
      date: DateTime(2026, 10, 6),
      libelle: 'Facture #024',
      beneficiaire: SocleComptableDemo.contractuels.first,
      montant: SocleComptableDemo.usd(350),
      route: Routes.comptableContractuelObligationPour(
        SocleComptableDemo.obligationFacture024,
      ),
    ),
    EcheanceComptable(
      id: 'ech-remboursement',
      date: DateTime(2026, 10, 8),
      libelle: "Remboursement d'une mensualité",
      montant: SocleComptableDemo.usd(45),
      route: Routes.comptableEncaissements,
    ),
    EcheanceComptable(
      id: 'ech-contrat-noor',
      date: DateTime(2026, 10, 10),
      libelle: 'Contrat mensuel',
      beneficiaire: SocleComptableDemo.contractuels[1],
      montant: SocleComptableDemo.usd(300),
      route: Routes.comptableContractuelObligationPour('obl-ctr-02-2026-10'),
    ),
  ];

  /// Les trois encaissements recents (§44).
  static final List<EncaissementRecent> encaissements = <EncaissementRecent>[
    EncaissementRecent(
      id: 'enc-01',
      date: DateTime(2026, 10, 4),
      famille: 'Famille Diallo',
      net: SocleComptableDemo.usd(120),
      etat: EtatEncaissement.confirme,
    ),
    EncaissementRecent(
      id: 'enc-02',
      date: DateTime(2026, 10, 3),
      famille: 'Famille Sow',
      net: SocleComptableDemo.usd(85),
      etat: EtatEncaissement.aRapprocher,
    ),
    EncaissementRecent(
      id: 'enc-03',
      date: DateTime(2026, 10, 3),
      famille: 'Famille Camara',
      net: SocleComptableDemo.usd(60),
      etat: EtatEncaissement.echoue,
    ),
  ];

  /// L'activite recente (§48) : ce que la source a journalise.
  static final List<EntreeJournal> activite = <EntreeJournal>[
    EntreeJournal(
      id: 'act-01',
      date: DateTime(2026, 10, 4),
      initiateur: 'Prestataire A',
      objet: 'Encaissement, Famille Diallo',
      ancienEtat: 'En attente',
      nouvelEtat: 'Confirmé',
      montant: SocleComptableDemo.usd(120),
      reference: 'ENC-1004-001',
    ),
    EntreeJournal(
      id: 'act-02',
      date: DateTime(2026, 10, 3),
      initiateur: SocleComptableDemo.leComptable.nom,
      objet: 'Paie de septembre, ${SocleComptableDemo.enseignants[6].nom}',
      ancienEtat: 'Soumis',
      nouvelEtat: 'Échoué',
      montant: SocleComptableDemo.usd(-380),
      reference: 'PAY-0926-007',
    ),
    EntreeJournal(
      id: 'act-03',
      date: DateTime(2026, 10, 2),
      initiateur: SocleComptableDemo.leComptable.nom,
      objet: 'Paie de septembre, ${SocleComptableDemo.enseignants[1].nom}',
      ancienEtat: 'En transit',
      nouvelEtat: 'Réussi',
      montant: SocleComptableDemo.usd(-410),
      reference: 'PAY-0926-002',
    ),
    EntreeJournal(
      id: 'act-04',
      date: DateTime(2026, 9, 30),
      initiateur: 'Règle de la direction',
      objet: 'Allocation à la Réserve stratégique',
      nouvelEtat: 'Exécutée',
      montant: SocleComptableDemo.usd(300),
    ),
  ];
}

/// Aujourd'hui en demonstration.
class AujourdhuiComptableDemo implements PortAujourdhuiComptable {
  /// Cree le double.
  const AujourdhuiComptableDemo();

  @override
  Future<AujourdhuiComptable> aujourdhui() async => AujourdhuiComptable(
    tresorerie: DonneesAujourdhuiDemo.tresorerie,
    reserve: DonneesAujourdhuiDemo.reserve,
    file: DonneesAujourdhuiDemo.file,
    echeances: DonneesAujourdhuiDemo.echeances,
    encaissementsRecents: DonneesAujourdhuiDemo.encaissements,
    activite: DonneesAujourdhuiDemo.activite,
    // Noms neutres, marques « (demonstration) » (DR-21) ; le second est
    // indisponible (§44). Le solde n'est rendu que pour le premier.
    prestataires: <PrestataireFinance>[
      for (final PrestataireFinance p in SocleComptableDemo.prestataires)
        PrestataireFinance(
          id: p.id,
          nom: t.comptable.commun.prestataireDemonstration(nom: p.nom),
          capacite: p.capacite,
          solde: p.capacite == CapacitePayout.prisEnCharge
              ? SocleComptableDemo.usd(6200)
              : p.solde,
        ),
    ],
  );

  @override
  Future<List<EntreeJournal>> journal(String objetId) async =>
      DonneesAujourdhuiDemo.activite;
}

/// Les surcharges de la demonstration d'Aujourd'hui.
List<Override> surchargesDemoAujourdhui() => <Override>[
  portAujourdhuiComptableProvider.overrideWithValue(
    const AujourdhuiComptableDemo(),
  ),
];
