// Le socle de la demonstration Comptable (CPT-F, spec §44) : les personnes
// et les identifiants que **tous** les fichiers de demonstration des voies
// partagent, pour parler des memes enseignants, des memes contractuels, du
// meme Comptable et des memes prestataires neutres. Aucun appel serveur,
// aucune vraie coordonnee, aucun vrai paiement (K-09, K-28).
//
// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A) :
// chaque voie ecrit ses donnees dans SON fichier (`aujourdhui_demo.dart`,
// `paiements_demo.dart`...) a partir de ces identites ; une personne de plus
// = une ligne pour CPT-FUS.

import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';

/// Les constantes communes de la demonstration Comptable.
abstract final class SocleComptableDemo {
  /// La devise de lancement.
  static const String devise = 'USD';

  /// [unites] dollars, en unites mineures.
  static Montant usd(int unites) => Montant(unites * 100, devise);

  /// Zero dans la devise de lancement.
  static const Montant zero = Montant(0, devise);

  /// Le jour de reference de la demonstration (meme jour que la Finance).
  static final DateTime aujourdhui = DateTime(2026, 10, 4);

  /// Le Comptable connecte en demonstration : il est aussi beneficiaire
  /// (§20), donc « Payer » est absent pour lui-meme (R-FIN-15).
  static const IdentiteBeneficiaire leComptable = IdentiteBeneficiaire(
    id: 'cpt-01',
    nom: 'Amadou Barry',
    type: TypeBeneficiaire.contractuel,
    estMoi: true,
  );

  /// L'identifiant de session du Comptable de demonstration.
  static const String comptableId = 'cpt-01';

  /// Les quinze enseignants (§44), identifiants `ens-01` a `ens-15`.
  static const List<IdentiteBeneficiaire> enseignants = <IdentiteBeneficiaire>[
    IdentiteBeneficiaire(
      id: 'ens-01',
      nom: 'Sayyid Youssouf Diallo',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-02',
      nom: 'Sayyida Mariama Sow',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-03',
      nom: 'Sayyid Ibrahima Camara',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-04',
      nom: 'Sayyida Aissatou Bah',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-05',
      nom: 'Sayyid Ousmane Balde',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-06',
      nom: 'Sayyida Fatoumata Conde',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-07',
      nom: 'Sayyid Mamadou Keita',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-08',
      nom: 'Sayyida Hawa Toure',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-09',
      nom: 'Sayyid Abdoulaye Sylla',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-10',
      nom: 'Sayyida Kadiatou Doumbouya',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-11',
      nom: 'Sayyid Alpha Soumah',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-12',
      nom: 'Sayyida Oumou Cisse',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-13',
      nom: 'Sayyid Thierno Diakite',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-14',
      nom: 'Sayyida Djenabou Kante',
      type: TypeBeneficiaire.enseignant,
    ),
    IdentiteBeneficiaire(
      id: 'ens-15',
      nom: 'Sayyid Saidou Fofana',
      type: TypeBeneficiaire.enseignant,
      // Lie a l'operateur : son paiement est sensible (§21.4).
      lieALOperateur: true,
    ),
  ];

  /// Les cinq contractuels (§44), identifiants `ctr-01` a `ctr-05`. Le
  /// premier est l'exemple de la spec §22.4 (« Karim Studio - Facture #024 -
  /// 350 USD ») ; le dernier est un externe sans compte (§18).
  static const List<IdentiteBeneficiaire> contractuels = <IdentiteBeneficiaire>[
    IdentiteBeneficiaire(
      id: 'ctr-01',
      nom: 'Karim Studio',
      type: TypeBeneficiaire.contractuel,
    ),
    IdentiteBeneficiaire(
      id: 'ctr-02',
      nom: 'Atelier Noor',
      type: TypeBeneficiaire.contractuel,
    ),
    IdentiteBeneficiaire(
      id: 'ctr-03',
      nom: 'Imprimerie Al-Qalam',
      type: TypeBeneficiaire.contractuel,
    ),
    IdentiteBeneficiaire(
      id: 'ctr-04',
      nom: 'Maintenance Salam',
      type: TypeBeneficiaire.contractuel,
    ),
    IdentiteBeneficiaire(
      id: 'ctr-05',
      nom: 'Traduction Hikma',
      type: TypeBeneficiaire.contractuel,
    ),
  ];

  /// L'identifiant de l'obligation de l'exemple §22.4 (« Facture #024 »).
  static const String obligationFacture024 = 'obl-ctr-024';

  /// L'identifiant de l'obligation payable de l'exemple §13.3 (ens-01).
  static const String obligationDiallo = 'obl-ens-01-2026-10';

  /// Les Classes de la demonstration (filtre analytique, §14.5).
  static const List<String> classes = <String>[
    'Al-Fajr',
    'An-Nour',
    'Al-Fatiha',
    'Al-Huda',
  ];

  /// Les prestataires neutres (§42, DR-21) : jamais un vrai nom, jamais un
  /// logo. Le second est indisponible (§44 « fournisseur indisponible »).
  static const List<PrestataireFinance> prestataires = <PrestataireFinance>[
    PrestataireFinance(
      id: 'prest-a',
      nom: 'Prestataire A',
      capacite: CapacitePayout.prisEnCharge,
    ),
    PrestataireFinance(
      id: 'prest-b',
      nom: 'Prestataire B',
      capacite: CapacitePayout.temporairementIndisponible,
    ),
  ];

  /// Une destination masquee de demonstration (§16.3). Le suffixe est
  /// fictif ; aucune coordonnee reelle.
  static const DestinationMasquee destinationMobile = DestinationMasquee(
    type: 'Mobile money',
    operateur: 'Operateur A',
    suffixe: '4423',
    pays: 'GN',
    devise: 'GNF',
    verification: EtatProfilPaiement.verifie,
  );

  /// Une destination bancaire masquee de demonstration.
  static const DestinationMasquee destinationBanque = DestinationMasquee(
    type: 'Compte bancaire',
    suffixe: '8712',
    pays: 'SN',
    devise: 'XOF',
    verification: EtatProfilPaiement.verifie,
  );

  /// La synthese de tresorerie **sans chiffre** : ce que les pages « en
  /// preparation » et une demonstration vide rendent. Les vraies valeurs
  /// de la demonstration sont dans `tresorerie_demo.dart` (CPT-TRES-1).
  static const SyntheseTresorerie syntheseVide = SyntheseTresorerie(
    detenue: zero,
    libre: zero,
    protegee: zero,
    enTransit: zero,
  );

  /// La Reserve strategique **sans chiffre**, regle inactive. Les vraies
  /// politiques (cible fixe, couverture en mois, allocation automatique)
  /// sont dans `direction_demo.dart` (CPT-DIR-1).
  static const IndicateursReserve reserveVide = IndicateursReserve(
    mode: ModeObjectifReserve.montantFixe,
    objectif: zero,
    actuel: zero,
    manque: zero,
    atteintPourMille: 0,
    etat: EtatReserve.regleInactive,
  );
}
