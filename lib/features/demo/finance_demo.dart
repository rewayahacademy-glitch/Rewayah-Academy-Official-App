// La SEULE source des donnees de demonstration de la Finance (FI-1c, guide
// Finance V4 §1, §8 F1 « fixtures », F2 ; lecon 14).
//
// Ce fichier porte :
// - la politique commerciale de la demonstration (`politiqueLancement`,
//   tarifs v2.0.0 du 18/10/2026), versionnee : la SEULE definition des
//   valeurs commerciales de la demonstration. Tout le reste (mensualites,
//   remises, manques, soldes, revenus, paie, dates) en est derive, jamais
//   recopie ; aucune valeur commerciale n'existe ailleurs dans `lib/` (FI6) ;
// - le foyer de demonstration (Mariam, Ibrahim, Aicha) et les six jeux du
//   guide F2 (tous finances, un a regulariser, un en essai, aucun paiement,
//   un profil, cinq profils) ;
// - les finances du foyer du titulaire adulte de la demonstration EA
//   (`profilsFoyerTitulaire`, revue FI-VAGUE-R R1-06) ;
// - les doubles de demonstration des ports Finance, qui CALCULENT ici ce que
//   le serveur arretera apres BR-1 (mensualites par rang, synthese du foyer,
//   revenus de l'enseignant) : jamais dans un widget (FI6, FI-11c).
//
// Rien n'est envoye (K-28). Les ports reels restent neutres
// (`CapaciteIndisponible`) ; seule la demonstration les surcharge (K-09).
// Les valeurs des maquettes (30 $, 2024, « Remise famille -5 $ » sur Mariam)
// ne sont PAS recopiees : Mariam est au rang 1, sans remise (guide §1.3).
//
// « (demonstration) » sur chaque montant (REVUE_EA-R m4, 02_DECOUPAGE E-9) :
// AUCUN composant ne l'ecrit aujourd'hui (`MontantArgent`, `formaterMontant`
// rendent le montant nu) ; seul le ruban « Démonstration » de la coquille
// (`RepereDemonstration`) marque l'ecran, et il suffit (FI-Q5 (a), decide par
// delegation le 05/10 ; revue FI-VAGUE-R R1-13 et R7-02) : aucun montant ne
// porte de marque propre.

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/capacites/port_mes_finances.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/capacites/port_recharge_foyer.dart';
import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/finance/mouvements_profil.dart';
import '../../core/finance/politique_commerciale.dart';
import '../../core/finance/suivi_paiement.dart';

/// Les six jeux du foyer de demonstration (guide §8 F2).
enum JeuFoyerFinance {
  /// Mariam, Ibrahim et Aicha : les trois mois sont finances.
  tousFinances,

  /// Ibrahim a regulariser : il manque une partie de sa mensualite.
  unARegulariser,

  /// Aicha en essai (1/2), hors rangs payants (FIN4-15).
  unEnEssai,

  /// Aucun paiement encore : rien n'est finance.
  aucunPaiement,

  /// Un seul profil, Mariam.
  unProfil,

  /// Cinq profils : les remises de rang 3 et 4 et suivants.
  cinqProfils,
}

/// Les jeux des revenus de l'enseignant de demonstration (guide §8 F6).
enum JeuRevenusEnseignant {
  /// Classe pleine, classe a 80 %, classe d'adultes au minimum d'ouverture.
  nominal,

  /// Une place de la classe a 80 % tenue par un eleve en essai present a
  /// chaque seance du mois : il compte, la classe passe a 5 sieges eligibles
  /// sur tout le mois. Le port rend un nombre de sieges par Classe et par
  /// mois ; un essai sur une seule seance attend le detail par seance du
  /// serveur (FI-BR-11).
  essaiDansLaSeance,

  /// Un eleve finance absent dans la classe pleine : il compte, la classe
  /// reste pleine et le montant ne bouge pas.
  financeAbsent,

  /// Le nominal, plus une seance assuree en remplacement d'un collegue.
  remplacement,
}

/// L'etat d'une place pendant une seance (guide §1.4, definition des sieges
/// eligibles).
enum SiegeSeance {
  /// Eleve dont la periode est financee, present.
  financePresent,

  /// Eleve dont la periode est financee, absent : il compte.
  financeAbsent,

  /// Eleve en essai valide, present : il compte.
  essaiPresent,

  /// Eleve en essai, absent : il ne compte pas.
  essaiAbsent,

  /// Place non attribuee : elle ne compte pas.
  placeVide,
}

/// Une classe de l'enseignant de demonstration (revue FI-1c-R M2).
///
/// `eligibles` : les sieges dont la periode est financee (guide §1.4) ;
/// `manques` : un manque en dollars par siege attribue dont la nouvelle
/// periode n'est PAS financee (guide §1.7). Un tel siege n'est pas eligible
/// et ne fait pas de revenu ; son manque fait les impayes (revue
/// FI-1c-CORR-R m5).
typedef _ClasseDemo = ({
  String id,
  String nom,
  int minutes,
  int capacite,
  int eligibles,
  List<Montant> manques,
  bool adulte,
  TypeClasseRevenus type,
});

/// Un profil de demonstration, avant ses donnees financieres.
class _ProfilDemo {
  const _ProfilDemo(
    this.id,
    this.prenom,
    this.cleAccent,
    this.classe, {
    this.age,
  });

  final String id;
  final String prenom;
  final String cleAccent;
  final String? classe;
  final int? age;
}

/// Les donnees de demonstration de la Finance.
abstract final class DonneesFinanceDemo {
  /// La devise de lancement (guide §1.1).
  static const String devise = 'USD';

  /// [unites] dollars, en unites mineures.
  static Montant usd(int unites) => Montant(unites * 100, devise);

  /// Le jour de reference de la demonstration (mois d'octobre 2026).
  static final DateTime aujourdhui = DateTime(2026, 10, 4);

  /// Le premier jour du mois de reference.
  static final DateTime debutMois = DateTime(2026, 10);

  /// Le dernier jour du mois de reference.
  static final DateTime finMois = DateTime(2026, 10, 31);

  /// Le premier jour du mois suivant (prochain debit).
  static final DateTime moisSuivant = DateTime(2026, 11);

  /// La politique commerciale de la demonstration : la SEULE source des
  /// valeurs commerciales de la demonstration. Ce sont celles de la
  /// politique `v2.0.0` des tarifs du 18/10/2026
  /// (`docs/current/DECISION-TARIFS-2026-10-18.md`, migration
  /// `20261018120000_fac_e_01_tarifs_v2.sql`) : tout le reste de ce fichier
  /// (mensualites, remises, manques, soldes, paie, revenus, impayes, dates)
  /// en est derive, jamais recopie. Pour changer une valeur de demonstration,
  /// on change ICI.
  ///
  /// La date d'effet est celle du mois de reference de la demonstration
  /// (octobre 2026) : la demonstration ne rend qu'un mois, celui ou la
  /// politique s'applique (la production date la v2.0.0 du 1er novembre).
  static final PolitiqueCommerciale politiqueLancement = PolitiqueCommerciale(
    // Un numero de version comme la maquette 10 (« v2.0.0 »), jamais un
    // identifiant technique (revue FI-VAGUE-R R6-10).
    version: 'v2.0.0',
    statut: StatutPolitique.publiee,
    dateEffet: debutMois,
    tarifEnfant: usd(55),
    tarifAdulte: usd(65),
    // Pas d'essai gratuit depuis le 18/10/2026.
    essaisMax: 0,
    essaiActif: false,
    // Foyer, en pour mille du tarif de chaque membre payant : 8 % des le
    // deuxieme, 17 % des le troisieme.
    remisesParRang: const <RemiseRang>[
      RemiseRang(aPartirDuRang: 2, pourMille: 80),
      RemiseRang(aPartirDuRang: 3, pourMille: 170),
    ],
    // Anciens champs de base et de plafond horaires : la v2.0.0 les garde
    // (6 $ et 9 $), la paie se lit dans les taux par eleve present.
    baseHoraire: usd(6),
    plafondHoraire: usd(9),
    capaciteEnfant: 5,
    capaciteAdulte: 6,
    capaciteDebutant: 4,
    minimumOuverture: 3,
    classesObjectif: 3,
    classesMax: 4,
    joursConservationPlace: 14,
    margeReferencePourMille: (objectif: 450, forte: 500, stretch: 520),
    railsActifs: const <RailPaiement>{RailPaiement.webStripe},
    // Relances : 7, 3 et 1 jours avant le renouvellement. Aucun budget ni
    // allocation Internet : le guide n'en fixe pas, la demonstration n'en
    // invente pas.
    joursRelance: const <int>[7, 3, 1],
    // Paie de l'enseignant par eleve present et par heure (0,95 $ enfant,
    // 1,00 $ adulte), plafonds 1,30 $ et 1,50 $, seance due des 45 et 70
    // minutes.
    tauxEleveHeureEnfant: const Montant(95, devise),
    tauxEleveHeureAdulte: const Montant(100, devise),
    plafondEleveHeureEnfant: const Montant(130, devise),
    plafondEleveHeureAdulte: const Montant(150, devise),
    dureeDueEnfantMinutes: 45,
    dureeDueAdulteMinutes: 70,
    prepaiementTrimestrielPourMille: 50,
    prepaiementAnnuelPourMille: 100,
    parrainageCredit: usd(20),
    boursePourMille: 300,
    boursePlacesPourMille: 50,
    bourseDureeMois: 6,
    cumulMaxPourMille: 250,
    jourSuspension: 4,
  );

  /// Le brouillon de la version suivante (FI-11b) : les memes valeurs que la
  /// politique de la demonstration, une date d'effet plus tardive. Aucune
  /// valeur inventee ; la comparaison apparait des qu'un champ est modifie a
  /// l'ecran.
  static final PolitiqueCommerciale politiqueBrouillon = PolitiqueCommerciale(
    version: 'v2.1.0',
    statut: StatutPolitique.brouillon,
    dateEffet: DateTime(2027),
    tarifEnfant: politiqueLancement.tarifEnfant,
    tarifAdulte: politiqueLancement.tarifAdulte,
    essaisMax: politiqueLancement.essaisMax,
    essaiActif: politiqueLancement.essaiActif,
    remisesParRang: politiqueLancement.remisesParRang,
    baseHoraire: politiqueLancement.baseHoraire,
    plafondHoraire: politiqueLancement.plafondHoraire,
    capaciteEnfant: politiqueLancement.capaciteEnfant,
    capaciteAdulte: politiqueLancement.capaciteAdulte,
    capaciteDebutant: politiqueLancement.capaciteDebutant,
    minimumOuverture: politiqueLancement.minimumOuverture,
    classesObjectif: politiqueLancement.classesObjectif,
    classesMax: politiqueLancement.classesMax,
    joursConservationPlace: politiqueLancement.joursConservationPlace,
    margeReferencePourMille: politiqueLancement.margeReferencePourMille,
    railsActifs: politiqueLancement.railsActifs,
    allocationInternet: politiqueLancement.allocationInternet,
    joursRelance: politiqueLancement.joursRelance,
    budgets: politiqueLancement.budgets,
    tauxEleveHeureEnfant: politiqueLancement.tauxEleveHeureEnfant,
    tauxEleveHeureAdulte: politiqueLancement.tauxEleveHeureAdulte,
    plafondEleveHeureEnfant: politiqueLancement.plafondEleveHeureEnfant,
    plafondEleveHeureAdulte: politiqueLancement.plafondEleveHeureAdulte,
    dureeDueEnfantMinutes: politiqueLancement.dureeDueEnfantMinutes,
    dureeDueAdulteMinutes: politiqueLancement.dureeDueAdulteMinutes,
    prepaiementTrimestrielPourMille:
        politiqueLancement.prepaiementTrimestrielPourMille,
    prepaiementAnnuelPourMille: politiqueLancement.prepaiementAnnuelPourMille,
    parrainageCredit: politiqueLancement.parrainageCredit,
    boursePourMille: politiqueLancement.boursePourMille,
    boursePlacesPourMille: politiqueLancement.boursePlacesPourMille,
    bourseDureeMois: politiqueLancement.bourseDureeMois,
    cumulMaxPourMille: politiqueLancement.cumulMaxPourMille,
    jourSuspension: politiqueLancement.jourSuspension,
  );

  /// Ce qu'il manque a un profil a regulariser pour financer son mois, dans
  /// les jeux de la demonstration (l'exemple du guide §1.7 : « il manque
  /// 8 $ »). Un parametre de scenario, pas une valeur commerciale : le solde
  /// du profil en est derive (mensualite moins ce manque).
  static final Montant manqueDemo = usd(8);

  /// Le nombre d'essais du jeu `unEnEssai` : un etat herite de la v1, que la
  /// politique v2.0.0 ne propose plus (`essaisMax` 0). Parametre de scenario,
  /// pour que le compteur d'essai du jeu reste lisible.
  static const int essaisMaxJeuEssai = 2;

  /// Mariam, premier profil du foyer.
  static const String mariamId = 'demo-fi-mariam';

  /// Ibrahim, deuxieme profil.
  static const String ibrahimId = 'demo-fi-ibrahim';

  /// Aicha, troisieme profil.
  static const String aichaId = 'demo-fi-aicha';

  /// Youssef, quatrieme profil (jeu a cinq profils).
  static const String youssefId = 'demo-fi-youssef';

  /// Khadija, cinquieme profil (jeu a cinq profils).
  static const String khadijaId = 'demo-fi-khadija';

  static const _ProfilDemo _mariam = _ProfilDemo(
    mariamId,
    'Mariam',
    'accent-mariam',
    'An-Nour',
    age: 9,
  );
  static const _ProfilDemo _ibrahim = _ProfilDemo(
    ibrahimId,
    'Ibrahim',
    'accent-ibrahim',
    'Al-Huda',
    age: 11,
  );
  static const _ProfilDemo _aicha = _ProfilDemo(
    aichaId,
    'Aïcha',
    'accent-aicha',
    'An-Nour',
    age: 7,
  );
  // Youssef (12 ans) et Khadija (13 ans) sont des enfants : ils suivent
  // Al-Huda, classe enfants, jamais As-Salam, classe adultes
  // (revue FI-1c-CORR-R m6).
  static const _ProfilDemo _youssef = _ProfilDemo(
    youssefId,
    'Youssef',
    'accent-youssef',
    'Al-Huda',
    age: 12,
  );
  static const _ProfilDemo _khadija = _ProfilDemo(
    khadijaId,
    'Khadija',
    'accent-khadija',
    'Al-Huda',
    age: 13,
  );

  /// La mensualite d'un membre payant de rang [rang] (1 = premier), lue dans
  /// [politique] : le tarif, puis la remise de rang quand elle existe. Le
  /// calcul vit ICI, dans le double de demonstration, jamais dans un widget.
  /// Une remise en pour mille s'arrondit comme le serveur : a l'unite
  /// mineure la plus proche, vers le haut a la moitie.
  static List<LigneMensualite> lignesPourRang(
    int rang, {
    PolitiqueCommerciale? politique,
    bool adulte = false,
  }) {
    final PolitiqueCommerciale p = politique ?? politiqueLancement;
    final Montant tarif = adulte ? p.tarifAdulte : p.tarifEnfant;
    final RemiseRang? regle = p.remiseRangPour(rang);
    final Montant? remise = regle == null
        ? null
        : regle.remise ??
              Montant(
                -((tarif.mineur * regle.pourMille! + 500) ~/ 1000),
                tarif.devise,
              );
    return <LigneMensualite>[
      LigneMensualite(nature: NatureLigneMensualite.tarif, montant: tarif),
      if (remise != null)
        LigneMensualite(
          nature: NatureLigneMensualite.remiseRang,
          montant: remise,
          rang: rang,
        ),
    ];
  }

  /// La mensualite d'un membre payant de rang [rang] : la somme de ses
  /// lignes ([lignesPourRang]).
  static Montant mensualiteRang(
    int rang, {
    PolitiqueCommerciale? politique,
    bool adulte = false,
  }) => _somme(
    lignesPourRang(
      rang,
      politique: politique,
      adulte: adulte,
    ).map((LigneMensualite l) => l.montant),
  );

  static Montant _moins(Montant a, Montant b) =>
      Montant(a.mineur - b.mineur, devise);

  static Montant _somme(Iterable<Montant> montants) => Montant(
    montants.fold<int>(0, (int s, Montant m) => s + m.mineur),
    devise,
  );

  static FinancesProfil _finance(
    _ProfilDemo p, {
    required int rang,
    required EtatFinancier etat,
    required Montant solde,
    bool finance = true,
    int? essais,
    Montant? manque,
    bool adulte = false,
  }) {
    final List<LigneMensualite> lignes = essais != null
        ? const <LigneMensualite>[]
        : lignesPourRang(rang, adulte: adulte);
    final Montant mensualite = _somme(
      lignes.map((LigneMensualite l) => l.montant),
    );
    return FinancesProfil(
      profilId: p.id,
      prenom: p.prenom,
      cleAccent: p.cleAccent,
      estAdulte: adulte,
      classe: p.classe,
      age: p.age,
      etat: etat,
      solde: solde,
      periode: finance ? PeriodeFinancee(debut: debutMois, fin: finMois) : null,
      // Sans periode financee, le debit attendu est celui du mois de
      // reference, pas du suivant : c'est le mois que le manque doit
      // financer (« Il manque X pour financer octobre », guide §1.7).
      prochainDebit: essais != null
          ? null
          : ProchainDebit(
              date: finance ? moisSuivant : debutMois,
              montant: mensualite,
            ),
      mensualite: mensualite,
      lignesMensualite: lignes,
      essaisUtilises: essais,
      manque: manque,
      finConservation: etat == EtatFinancier.aRegulariser
          ? debutMois.add(
              Duration(days: politiqueLancement.joursConservationPlace),
            )
          : null,
    );
  }

  /// Les finances des profils du jeu [jeu], dans l'ordre du foyer.
  static List<FinancesProfil> profils(JeuFoyerFinance jeu) => switch (jeu) {
    JeuFoyerFinance.tousFinances => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: usd(12)),
      // Ibrahim : solde nul, mois finance (FI2, FIN4-08).
      _finance(_ibrahim, rang: 2, etat: EtatFinancier.finance, solde: usd(0)),
      _finance(_aicha, rang: 3, etat: EtatFinancier.finance, solde: usd(45)),
    ],
    JeuFoyerFinance.unARegulariser => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: usd(12)),
      // Mensualite moins le manque : aucun debit partiel, l'ecran dit le
      // manque (FIN4-09).
      _finance(
        _ibrahim,
        rang: 2,
        etat: EtatFinancier.aRegulariser,
        solde: _moins(mensualiteRang(2), manqueDemo),
        finance: false,
        manque: manqueDemo,
      ),
      _finance(_aicha, rang: 3, etat: EtatFinancier.finance, solde: usd(45)),
    ],
    // Aicha en essai ne compte pas comme payante (FIN4-15) : Mariam et
    // Ibrahim restent aux rangs 1 et 2, sans remise.
    JeuFoyerFinance.unEnEssai => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: usd(12)),
      _finance(_ibrahim, rang: 2, etat: EtatFinancier.finance, solde: usd(0)),
      _finance(
        _aicha,
        rang: 0,
        etat: EtatFinancier.essai,
        solde: usd(0),
        finance: false,
        essais: 1,
      ),
    ],
    JeuFoyerFinance.aucunPaiement => <FinancesProfil>[
      _finance(
        _mariam,
        rang: 1,
        etat: EtatFinancier.manque,
        solde: usd(0),
        finance: false,
        manque: mensualiteRang(1),
      ),
      _finance(
        _ibrahim,
        rang: 2,
        etat: EtatFinancier.manque,
        solde: usd(0),
        finance: false,
        manque: mensualiteRang(2),
      ),
    ],
    JeuFoyerFinance.unProfil => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: usd(12)),
    ],
    JeuFoyerFinance.cinqProfils => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: usd(12)),
      _finance(_ibrahim, rang: 2, etat: EtatFinancier.finance, solde: usd(0)),
      _finance(_aicha, rang: 3, etat: EtatFinancier.finance, solde: usd(45)),
      _finance(_youssef, rang: 4, etat: EtatFinancier.finance, solde: usd(18)),
      _finance(_khadija, rang: 5, etat: EtatFinancier.finance, solde: usd(3)),
    ],
  };

  /// Les finances de l'eleve adulte autonome (FI-9b, FI-BR-17) : son seul
  /// profil, seul membre payant (rang 1, sans remise) au tarif adulte, le
  /// mois de reference finance. [classe] `null` : la demonstration n'a pas
  /// sa Classe (rien d'invente). [aRegulariser] : le mois de reference
  /// n'est pas finance, il manque [manqueDemo] (l'exemple du guide §1.7).
  static FinancesProfil financesAdulte({
    required String profilId,
    required String prenom,
    String? classe,
    bool aRegulariser = false,
  }) => _finance(
    _ProfilDemo(profilId, prenom, 'accent-adulte', classe),
    rang: 1,
    etat: aRegulariser ? EtatFinancier.aRegulariser : EtatFinancier.finance,
    solde: aRegulariser
        ? _moins(mensualiteRang(1, adulte: true), manqueDemo)
        : usd(15),
    finance: !aRegulariser,
    manque: aRegulariser ? manqueDemo : null,
    adulte: true,
  );

  /// Les finances du foyer du titulaire adulte de la demonstration EA
  /// (revue FI-VAGUE-R R1-06, E-11) : le titulaire au rang 1, le second
  /// adulte rattache au rang 2 quand il l'est, tous deux au tarif adulte,
  /// puis les enfants aux rangs suivants. Tous ont leur mois de reference
  /// finance ; le dernier enfant a le solde le plus bas, sans jamais etre
  /// dit « a recharger » par un seuil (FI2). Aucune Classe ni age : la
  /// demonstration EA ne les rend pas dans ces donnees (rien d'invente).
  static List<FinancesProfil> profilsFoyerTitulaire({
    required ({String id, String prenom}) titulaire,
    ({String id, String prenom})? secondAdulte,
    List<({String id, String prenom})> enfants =
        const <({String id, String prenom})>[],
  }) {
    final List<int> soldesEnfants = <int>[3, 18];
    return <FinancesProfil>[
      _finance(
        _ProfilDemo(titulaire.id, titulaire.prenom, 'accent-titulaire', null),
        rang: 1,
        etat: EtatFinancier.finance,
        solde: usd(15),
        adulte: true,
      ),
      if (secondAdulte != null)
        _finance(
          _ProfilDemo(
            secondAdulte.id,
            secondAdulte.prenom,
            'accent-second-adulte',
            null,
          ),
          rang: 2,
          etat: EtatFinancier.finance,
          solde: usd(10),
          adulte: true,
        ),
      for (final (int i, ({String id, String prenom}) e) in enfants.indexed)
        _finance(
          _ProfilDemo(e.id, e.prenom, 'accent-${e.id}', null),
          rang: (secondAdulte == null ? 2 : 3) + i,
          etat: EtatFinancier.finance,
          solde: usd(soldesEnfants[i % soldesEnfants.length]),
        ),
    ];
  }

  /// Les finances d'un foyer de [liste], synthese comprise, lue (FI1) :
  /// additionnee ici, dans le double de demonstration.
  static FinancesFoyer foyerDe(
    List<FinancesProfil> liste, {
    required int paiementsDuMois,
  }) => FinancesFoyer(
    profils: liste,
    synthese: SyntheseFoyer(
      totalSoldes: _somme(liste.map((FinancesProfil p) => p.solde)),
      aPayerCeMois: _somme(
        liste
            .where((FinancesProfil p) => p.manque != null)
            .map((FinancesProfil p) => p.manque!),
      ),
      profilsFinances: liste
          .where((FinancesProfil p) => p.etat == EtatFinancier.finance)
          .length,
      profils: liste.length,
      paiementsDuMois: paiementsDuMois,
    ),
  );

  /// Le nombre de paiements du mois dans le jeu [jeu].
  static int paiementsDuMois(JeuFoyerFinance jeu) => switch (jeu) {
    JeuFoyerFinance.aucunPaiement => 0,
    JeuFoyerFinance.unProfil => 1,
    _ => 2,
  };

  /// Les finances du foyer du jeu [jeu], synthese comprise. La synthese est
  /// une LECTURE (FI1) : additionnee ici, dans le double de demonstration.
  static FinancesFoyer finances(JeuFoyerFinance jeu) =>
      foyerDe(profils(jeu), paiementsDuMois: paiementsDuMois(jeu));

  /// La fin du dernier acces d'un profil payant sans periode financee : la
  /// fin de sa derniere periode, ou celle de son essai (FIN4-13). Elle est
  /// passee, donc l'acces se lit « expire », jamais « sans echeance », qui
  /// est le cas ordinaire d'un compte valide (revue FI-1c-R M1).
  ///
  /// **Valeur de demonstration, pas une regle** (revue FI-1c-CORR-R m3) : le
  /// 30/09 a 23 h 59 est seulement la veille du mois de reference choisi par
  /// la demonstration. Aucune regle ne fixe la fin d'acces a la fin d'un mois
  /// civil : en production, l'echeance est celle que rend le serveur
  /// (`profiles.access_until`, FI-BR-08), quelle qu'elle soit.
  static final DateTime finDernierAcces = DateTime(2026, 9, 30, 23, 59);

  /// L'acces des profils du jeu [jeu], tel que l'enfant peut le lire :
  /// seances payantes ouvertes ou non, essais ; **jamais un montant ni une
  /// cause** (FI12). L'etat affiche vient de l'echeance, par la meme regle
  /// que les ecrans (`etatAccesAffiche`) : un profil payant non finance est
  /// « expire » ; seul l'essai en cours reste sans echeance.
  static List<AccesBeneficiaire> acces(
    JeuFoyerFinance jeu, {
    Map<String, EtatPlace> places = const <String, EtatPlace>{},
  }) => <AccesBeneficiaire>[
    for (final FinancesProfil p in profils(jeu)) _avecPlace(_acces(p), places),
  ];

  /// Le jour de demonstration ou une place est liberee : le lendemain de la
  /// fin de conservation (`joursConservationPlace` de la politique) du mois
  /// de reference.
  static final DateTime jourPlaceLiberee = debutMois.add(
    Duration(days: politiqueLancement.joursConservationPlace + 1),
  );

  /// Le jour de demonstration ou un acces suspendu est reactive.
  static final DateTime jourReactivation = DateTime(2026, 10, 3);

  /// L'etat de place de [a] selon [places] (FI-BR-08, guide §8 F5) : une
  /// place liberee ferme les seances payantes (l'enfant lit la copie
  /// neutre), une reactivation les rouvre. Le compte n'est jamais ferme.
  static AccesBeneficiaire _avecPlace(
    AccesBeneficiaire a,
    Map<String, EtatPlace> places,
  ) {
    final EtatPlace? place = places[a.eleveId];
    if (place == null) return a;
    return AccesBeneficiaire(
      eleveId: a.eleveId,
      prenom: a.prenom,
      finAcces: a.finAcces,
      etatAffiche: a.etatAffiche,
      seancesPayantesOuvertes: place == EtatPlace.reactivee,
      essaisUtilises: a.essaisUtilises,
      essaisMax: a.essaisMax,
      place: place,
      datePlace: place == EtatPlace.liberee
          ? jourPlaceLiberee
          : jourReactivation,
    );
  }

  // Revue FI-1c-CORR-R m2 : le guide §1.7 dit « Acces a regulariser » pour
  // un profil payant dont la nouvelle periode n'est pas financee. Cet etat
  // n'existe pas dans `EtatAccesAffiche`, et il ne peut pas y etre ajoute
  // cote frontend seul : `etatAccesAffiche` est un calcul pur sur la seule
  // echeance (`finAcces`), qui ne sait pas distinguer « a regulariser » d'une
  // fin d'acces ordinaire ; il faudrait un etat rendu par le serveur
  // (DB-FOY-05), et les ecrans qui enumerent `EtatAccesAffiche` (fiche eleve,
  // ligne du Foyer, page Acces du Compte) devraient changer. Question au
  // directeur, FI-BR-08 : le contrat d'acces rendra-t-il un etat « a
  // regulariser » distinct de l'echeance ? D'ici la, la demonstration garde
  // `expire`, et la cause utile reste dans la Finance du tuteur
  // (`EtatFinancier.aRegulariser`, manque, fin de conservation).
  //
  // Revue FI-1c-CORR-R m4 : l'essai reste « sans echeance ». Un essai se
  // compte en seances (2 au plus, FIN4-10, FIN4-13), jamais en jours : le
  // guide ne lui donne aucune date de fin. Le modele n'en porte pas non plus
  // (`FinancesProfil` n'a que `essaisUtilises`, et `AccesBeneficiaire.finAcces`
  // est `profiles.access_until`, une echeance serveur) : une date inventee
  // ici se lirait « actif jusqu'au ... » et ferait d'une regle de seances une
  // regle de calendrier. Le compteur `essaisUtilises / essaisMax` dit seul
  // ou en est l'essai.
  static AccesBeneficiaire _acces(FinancesProfil p) {
    final DateTime? fin = switch (p.etat) {
      EtatFinancier.essai => null,
      _ => p.periode?.fin ?? finDernierAcces,
    };
    return AccesBeneficiaire(
      eleveId: p.profilId,
      prenom: p.prenom,
      finAcces: fin,
      etatAffiche: etatAccesAffiche(
        finAcces: fin,
        maintenantUtc: aujourdhui.toUtc(),
      ),
      seancesPayantesOuvertes: p.periode != null,
      essaisUtilises: p.essaisUtilises,
      essaisMax: p.essaisUtilises == null ? null : essaisMaxJeuEssai,
    );
  }

  /// La date de la recharge de demonstration : avant le debit du mois de
  /// reference, qui la consomme.
  static final DateTime dateRecharge = DateTime(2026, 9, 25, 10, 30);

  /// La reference du paiement de demonstration qui a recharge le foyer.
  static const String referenceRecharge = 'RWY-DEMO-0925';

  /// Les mouvements de la periode du mois de reference d'un profil finance
  /// (FI-BR-05) : une ligne par ligne de mensualite RENDUE, signe inverse
  /// (le tarif debite, la remise ou l'avoir credites). Aucun sans periode :
  /// aucun debit partiel (FIN4-09), aucun debit en essai.
  static List<MouvementProfil> _mouvementsPeriode(FinancesProfil p) {
    if (p.periode == null) return const <MouvementProfil>[];
    return <MouvementProfil>[
      for (final (int i, LigneMensualite l) in p.lignesMensualite.indexed)
        MouvementProfil(
          id: 'demo-fi-mvt-${p.profilId}-$i',
          date: debutMois,
          nature: switch (l.nature) {
            NatureLigneMensualite.tarif => NatureMouvement.debitPeriode,
            NatureLigneMensualite.taxe => NatureMouvement.taxe,
            NatureLigneMensualite.remiseRang ||
            NatureLigneMensualite.prorata ||
            NatureLigneMensualite.bourse ||
            NatureLigneMensualite.remisePrepaiement => NatureMouvement.remise,
            NatureLigneMensualite.avoir => NatureMouvement.avoir,
          },
          montant: Montant(-l.montant.mineur, devise),
          periode: debutMois,
        ),
    ];
  }

  /// La recharge d'un profil : ce qu'il a fallu verser pour arriver a son
  /// solde apres les mouvements de la periode. Les memes chiffres que le
  /// solde et la mensualite, jamais ceux d'une maquette.
  static Montant _rechargeDe(FinancesProfil p) => Montant(
    p.solde.mineur -
        _mouvementsPeriode(p)
            .fold<int>(0, (int s, MouvementProfil m) => s + m.montant.mineur),
    devise,
  );

  /// Le recu du paiement de demonstration du jeu [jeu] : un seul paiement
  /// externe, reparti par profil (guide §1.6), `null` quand aucun profil
  /// n'a ete recharge (aucun paiement, essai seul).
  static RecuPaiement? recu(JeuFoyerFinance jeu) => _recuDe(profils(jeu));

  /// Le recu du paiement qui a recharge les profils de [liste] (R1-06).
  static RecuPaiement? recuDe(List<FinancesProfil> liste) => _recuDe(liste);

  /// Le recu du paiement qui a recharge [liste] : une allocation par profil
  /// recharge, `null` sans aucun.
  static RecuPaiement? _recuDe(List<FinancesProfil> liste) {
    final List<AllocationProfil> allocations = <AllocationProfil>[
      for (final FinancesProfil p in liste)
        if (_rechargeDe(p).mineur > 0)
          AllocationProfil(
            profilId: p.profilId,
            prenom: p.prenom,
            montant: _rechargeDe(p),
          ),
    ];
    if (allocations.isEmpty) return null;
    return RecuPaiement(
      reference: referenceRecharge,
      date: dateRecharge,
      rail: RailPaiement.webStripe,
      total: _somme(allocations.map((AllocationProfil a) => a.montant)),
      allocations: allocations,
    );
  }

  /// Les mouvements du profil [profilId] dans le jeu [jeu], le plus recent
  /// d'abord (FI-BR-05) : leur somme est son solde. Vide pour un profil
  /// inconnu, en essai ou sans aucun paiement.
  static List<MouvementProfil> mouvements(
    JeuFoyerFinance jeu,
    String profilId,
  ) => mouvementsDans(profils(jeu), profilId);

  /// Les mouvements du profil [profilId] parmi [liste], comme [mouvements].
  static List<MouvementProfil> mouvementsDans(
    List<FinancesProfil> liste,
    String profilId,
  ) {
    final FinancesProfil? p = liste
        .where((FinancesProfil f) => f.profilId == profilId)
        .firstOrNull;
    if (p == null) return const <MouvementProfil>[];
    return _mouvementsDe(p, _recuDe(liste));
  }

  /// Les [limite] derniers mouvements du foyer du jeu [jeu] (FI-5b) : ceux
  /// de [mouvements] pour chaque profil, du plus recent au plus ancien, a
  /// date egale dans l'ordre des profils puis l'ordre rendu. Le tri est celui
  /// de la source (ici la demonstration), jamais celui de l'ecran.
  static List<MouvementFoyer> derniersMouvements(
    JeuFoyerFinance jeu, {
    int limite = 3,
  }) => derniersMouvementsDans(profils(jeu), limite: limite);

  /// Les [limite] derniers mouvements des profils de [liste], comme
  /// [derniersMouvements].
  static List<MouvementFoyer> derniersMouvementsDans(
    List<FinancesProfil> liste, {
    int limite = 3,
  }) {
    final List<MouvementFoyer> tous = <MouvementFoyer>[
      for (final FinancesProfil p in liste)
        for (final MouvementProfil m in mouvementsDans(liste, p.profilId))
          MouvementFoyer(profilId: p.profilId, prenom: p.prenom, mouvement: m),
    ];
    // `List.sort` n'est pas stable : l'indice departage deux dates egales.
    final List<int> ordre = List<int>.generate(tous.length, (int i) => i)
      ..sort((int a, int b) {
        final int parDate = tous[b].mouvement.date.compareTo(
          tous[a].mouvement.date,
        );
        return parDate != 0 ? parDate : a.compareTo(b);
      });
    return <MouvementFoyer>[for (final int i in ordre.take(limite)) tous[i]];
  }

  /// Les mouvements de l'eleve adulte autonome [p] (FI-9b, FI-BR-17) : son
  /// recu ne repartit le paiement que sur lui.
  static List<MouvementProfil> mouvementsAdulte(FinancesProfil p) =>
      _mouvementsDe(p, _recuDe(<FinancesProfil>[p]));

  static List<MouvementProfil> _mouvementsDe(
    FinancesProfil p,
    RecuPaiement? recuPaiement,
  ) {
    final Montant recharge = _rechargeDe(p);
    return <MouvementProfil>[
      ..._mouvementsPeriode(p),
      if (recharge.mineur > 0)
        MouvementProfil(
          id: 'demo-fi-mvt-${p.profilId}-recharge',
          date: dateRecharge,
          nature: NatureMouvement.recharge,
          montant: recharge,
          recu: recuPaiement,
        ),
    ];
  }

  /// L'identifiant de la commande de demonstration dans l'etat [etat] : la
  /// demonstration parcourt les huit etats (revue FI-1a E-10).
  static String commandeDemo(EtatPaiement etat) => 'demo-fi-cmd-${etat.name}';

  /// Les montants du paiement de demonstration (guide §1.6) : Mariam +10,
  /// Ibrahim +40. Des montants de scenario ; le total et les nouveaux
  /// soldes en sont derives.
  static List<({String profilId, Montant montant})> get _versementsSuivi =>
      <({String profilId, Montant montant})>[
        (profilId: mariamId, montant: usd(10)),
        (profilId: ibrahimId, montant: usd(40)),
      ];

  /// Le suivi de la commande [commandeId] : les versements de
  /// [_versementsSuivi] et leur total (guide §1.6). Les nouveaux soldes
  /// (solde du jeu `tousFinances` plus le versement) ne sont rendus qu'a
  /// `termine`.
  static SuiviPaiement suivi(String commandeId) {
    final EtatPaiement etat = EtatPaiement.values.firstWhere(
      (EtatPaiement e) => commandeDemo(e) == commandeId,
      orElse: () => throw const CapaciteIndisponible('FI-BR-06'),
    );
    final bool termine = etat == EtatPaiement.termine;
    final List<FinancesProfil> foyer = profils(JeuFoyerFinance.tousFinances);
    return SuiviPaiement(
      commandeId: commandeId,
      etat: etat,
      total: _somme(_versementsSuivi.map((v) => v.montant)),
      reference: 'RWY-123',
      date: aujourdhui,
      moyen: RailPaiement.webStripe,
      motif: etat == EtatPaiement.echec ? motifEchecDemo : null,
      allocations: <AllocationProfil>[
        for (final v in _versementsSuivi)
          AllocationProfil(
            profilId: v.profilId,
            prenom: foyer.firstWhere((p) => p.profilId == v.profilId).prenom,
            montant: v.montant,
            nouveauSolde: termine
                ? _somme(<Montant>[
                    foyer.firstWhere((p) => p.profilId == v.profilId).solde,
                    v.montant,
                  ])
                : null,
          ),
      ],
    );
  }

  /// Le motif d'echec que la source de demonstration redige pour
  /// l'utilisateur (guide §5.4, « motif utilisateur lorsque disponible »).
  static const String motifEchecDemo =
      "La banque a refusé la carte. Aucun montant n'a été débité.";

  /// L'ordre des etats que parcourt une commande payee en demonstration
  /// (FI-8) : une lecture de plus, un etat de plus, jusqu'a `termine`.
  static const List<EtatPaiement> progressionDemo = <EtatPaiement>[
    EtatPaiement.attenteConfirmation,
    EtatPaiement.confirme,
    EtatPaiement.allocationEnCours,
    EtatPaiement.termine,
  ];

  /// L'identifiant de la commande payee sous la cle d'idempotence [cle] :
  /// la meme cle rend la meme commande (double confirmation, un seul
  /// credit, FI-8).
  static String commandePayee(String cle) => 'demo-fi-paye-$cle';

  /// La reference de la commande payee [commandeId], tiree de son
  /// identifiant : deux commandes n'ont jamais la meme (revue FI-8).
  /// Huit signes au plus, pour tenir a 320 px.
  static String referenceDe(String commandeId) {
    final String cle = commandeId
        .replaceFirst(commandePayee(''), '')
        .replaceAll('-', '')
        .toUpperCase();
    return 'RWY-${cle.length > 8 ? cle.substring(0, 8) : cle}';
  }

  /// Le suivi d'une commande payee en demonstration (FI-8) : les montants
  /// choisis [choix] du jeu [jeu], dans l'etat [etat]. Le nouveau solde de
  /// chaque profil (son solde plus SA part, une seule fois) n'est rendu
  /// qu'a `termine`. Calcul du double de demonstration, jamais a l'ecran.
  static SuiviPaiement suiviPaye(
    JeuFoyerFinance jeu,
    String commandeId,
    List<MontantRecharge> choix,
    EtatPaiement etat,
  ) {
    final bool termine = etat == EtatPaiement.termine;
    final Map<String, Montant> montantDe = <String, Montant>{
      for (final MontantRecharge c in choix) c.beneficiaireId: c.montant,
    };
    return SuiviPaiement(
      commandeId: commandeId,
      etat: etat,
      total: _somme(montantDe.values),
      reference: referenceDe(commandeId),
      date: aujourdhui,
      moyen: RailPaiement.webStripe,
      allocations: <AllocationProfil>[
        for (final FinancesProfil p in profils(jeu))
          if (montantDe[p.profilId] case final Montant m)
            AllocationProfil(
              profilId: p.profilId,
              prenom: p.prenom,
              montant: m,
              nouveauSolde: termine ? _somme(<Montant>[p.solde, m]) : null,
            ),
      ],
    );
  }

  /// Les montants de recharge proposes a chaque profil (FI-7, guide §5.3),
  /// en dollars : choisis plutot que saisis (K-57).
  static List<Montant> get paliersRecharge => <Montant>[
    for (final int u in const <int>[10, 20, 30, 40, 50]) usd(u),
  ];

  /// Le statut d'une attribution avant le paiement, tel que la source de
  /// demonstration le rend.
  static const String statutAvantPaiement = 'En attente du paiement';

  /// Les beneficiaires de la recharge du jeu [jeu] (FI-7) : les profils du
  /// foyer, leur solde, les montants proposes et, quand il manque de quoi
  /// financer le mois, ce manque suggere en premier montant (guide §5.3).
  static List<BeneficiaireRecharge> beneficiairesRecharge(
    JeuFoyerFinance jeu,
  ) => beneficiairesDe(profils(jeu));

  /// Les beneficiaires de la recharge de [liste], dans son ordre ; pour
  /// l'eleve adulte autonome, son seul profil (FI-9b, FI-BR-17).
  static List<BeneficiaireRecharge> beneficiairesDe(
    List<FinancesProfil> liste,
  ) => <BeneficiaireRecharge>[
    for (final FinancesProfil p in liste)
      BeneficiaireRecharge(
        id: p.profilId,
        prenom: p.prenom,
        solde: p.solde,
        montantSuggere: p.manque,
        // Croissants, comme le contrat du port le demande : le manque prend
        // sa place parmi les paliers, jamais d'office la premiere (revue
        // FI-7), sinon « Augmenter » ferait baisser le montant.
        montantsProposes: <Montant>[
          if (p.manque case final Montant m when !paliersRecharge.contains(m))
            m,
          ...paliersRecharge,
        ]..sort((Montant a, Montant b) => a.mineur.compareTo(b.mineur)),
      ),
  ];

  /// Le recapitulatif que la source de demonstration arrete pour ces montants
  /// (FI-7, FI-BR-06) : une ligne par profil choisi, dans l'ordre du foyer,
  /// et le total, additionne ICI, jamais dans l'ecran (FI6). Un profil
  /// inconnu, un montant nul ou non propose est refuse.
  static RecapitulatifRecharge recapitulatifMontants(
    JeuFoyerFinance jeu,
    List<MontantRecharge> choix,
  ) => recapitulatifDe(beneficiairesRecharge(jeu), choix);

  /// Le recapitulatif de ces montants pour les beneficiaires [liste].
  static RecapitulatifRecharge recapitulatifDe(
    List<BeneficiaireRecharge> liste,
    List<MontantRecharge> choix,
  ) {
    final Map<String, Montant> montantDe = <String, Montant>{
      for (final MontantRecharge c in choix) c.beneficiaireId: c.montant,
    };
    if (choix.isEmpty ||
        montantDe.length != choix.length ||
        montantDe.entries.any(
          (MapEntry<String, Montant> e) => !liste.any(
            (BeneficiaireRecharge b) =>
                b.id == e.key && b.montantsProposes.contains(e.value),
          ),
        )) {
      throw ArgumentError.value(choix, 'choix');
    }
    final List<LigneRecapitulatif> lignes = <LigneRecapitulatif>[
      for (final BeneficiaireRecharge b in liste)
        if (montantDe[b.id] case final Montant m)
          LigneRecapitulatif(
            beneficiaireId: b.id,
            prenom: b.prenom,
            montantPaye: formaterMontant(m),
            soldeAttribue: formaterMontant(m, signe: true),
            statut: statutAvantPaiement,
          ),
    ];
    return RecapitulatifRecharge(
      id: 'demo-fi-recapitulatif',
      lignes: lignes,
      total: formaterMontant(_somme(montantDe.values)),
    );
  }

  /// Le taux horaire effectif d'une classe (guide §1.4), en unites
  /// mineures : base + (plafond - base) x eligibles / capacite, plafonne.
  /// Calcul du double de demonstration, jamais dans un widget (FI-11c).
  ///
  /// Ce calcul est celui de l'ecran des revenus de l'enseignant, dont le
  /// texte decrit encore la base garantie et le plafond. La paie par eleve
  /// present de la v2.0.0 (`tauxEleveHeureEnfant`, `tauxEleveHeureAdulte`)
  /// est portee par la politique, mais cet ecran ne la montre pas encore :
  /// il demande un lot d'ecran dedie.
  static Montant tauxEffectif({
    required int siegesEligibles,
    required int capacite,
    PolitiqueCommerciale? politique,
  }) {
    final PolitiqueCommerciale p = politique ?? politiqueLancement;
    final int base = p.baseHoraire.mineur;
    final int plafond = p.plafondHoraire.mineur;
    final int eligibles = siegesEligibles > capacite
        ? capacite
        : siegesEligibles;
    final int taux = base + (plafond - base) * eligibles ~/ capacite;
    return Montant(taux > plafond ? plafond : taux, devise);
  }

  /// L'apercu d'un foyer de [enfants] membres payants sous [politique]
  /// (FI-11c) : la mensualite de chaque rang (`lignesPourRang`), puis le
  /// total. Calcul du double de demonstration, jamais dans un widget. Une
  /// remise au-dessus du tarif (mensualite negative) est une erreur
  /// d'argument : le formulaire la refuse avant (revue FI-11c).
  static ApercuFamille apercuFamille(
    PolitiqueCommerciale politique,
    int enfants,
  ) {
    final List<MensualiteApercu> lignes = <MensualiteApercu>[
      for (int rang = 1; rang <= enfants; rang++)
        _mensualiteApercu(rang, lignesPourRang(rang, politique: politique)),
    ];
    for (final MensualiteApercu l in lignes) {
      if (l.mensualite.mineur < 0) {
        throw ArgumentError('mensualite negative au rang ${l.rang}');
      }
    }
    return ApercuFamille(
      enfants: lignes,
      total: _somme(lignes.map((MensualiteApercu l) => l.mensualite)),
    );
  }

  static MensualiteApercu _mensualiteApercu(
    int rang,
    List<LigneMensualite> lignes,
  ) {
    Montant? remise;
    for (final LigneMensualite l in lignes) {
      if (l.nature == NatureLigneMensualite.remiseRang) remise = l.montant;
    }
    return MensualiteApercu(
      rang: rang,
      tarif: lignes.first.montant,
      remise: remise,
      mensualite: _somme(lignes.map((LigneMensualite l) => l.montant)),
    );
  }

  /// L'apercu du taux horaire d'une classe sous [politique] (FI-11c) : le
  /// taux de `tauxEffectif`, et la part d'occupation au-dessus de la base.
  /// Une capacite nulle n'a pas de taux, un plafond sous la base donnerait
  /// une part d'occupation negative : erreurs d'argument (le formulaire les
  /// refuse avant, revue FI-11c).
  static ApercuEnseignant apercuEnseignant(
    PolitiqueCommerciale politique, {
    required int capacite,
    required int eligibles,
  }) {
    if (capacite < 1 || eligibles < 0) {
      throw ArgumentError('capacite $capacite, eligibles $eligibles');
    }
    if (politique.plafondHoraire.mineur < politique.baseHoraire.mineur) {
      throw ArgumentError('plafond sous la base');
    }
    final Montant taux = tauxEffectif(
      siegesEligibles: eligibles,
      capacite: capacite,
      politique: politique,
    );
    return ApercuEnseignant(
      capacite: capacite,
      eligibles: eligibles > capacite ? capacite : eligibles,
      baseHoraire: politique.baseHoraire,
      occupation: Montant(
        taux.mineur - politique.baseHoraire.mineur,
        taux.devise,
      ),
      tauxHoraire: taux,
      plafondHoraire: politique.plafondHoraire,
    );
  }

  static RevenusClasse _classe(
    String id,
    String nom, {
    required TypeClasseRevenus type,
    required int minutes,
    required int capacite,
    required int eligibles,
    bool enRemplacement = false,
  }) {
    final Montant taux = tauxEffectif(
      siegesEligibles: eligibles,
      capacite: capacite,
    );
    return RevenusClasse(
      classeId: id,
      classe: nom,
      type: type,
      minutesAssurees: minutes,
      capacite: capacite,
      siegesEligibles: eligibles > capacite ? capacite : eligibles,
      tauxHoraireEffectif: taux,
      montantEstime: Montant(minutes * taux.mineur ~/ 60, devise),
      enRemplacement: enRemplacement,
    );
  }

  /// Les sieges eligibles d'une seance (guide §1.4) : un eleve finance
  /// compte, present ou absent ; un eleve en essai compte s'il est present ;
  /// une place vide ne compte pas ; jamais au-dela de la capacite.
  static int siegesEligibles(
    List<SiegeSeance> sieges, {
    required int capacite,
  }) {
    final int n = sieges
        .where(
          (SiegeSeance s) =>
              s == SiegeSeance.financePresent ||
              s == SiegeSeance.financeAbsent ||
              s == SiegeSeance.essaiPresent,
        )
        .length;
    return n > capacite ? capacite : n;
  }

  /// Les classes de l'enseignant de demonstration : une classe pleine, une
  /// classe a 80 % (plus un siege a regulariser), une classe d'adultes au
  /// minimum d'ouverture. Les MEMES sieges font ses revenus et le revenu,
  /// l'encaisse et les impayes de la vue globale (revues FI-1c-R M2 et
  /// FI-1c-CORR-R m5) : jamais deux populations qui ne se correspondent pas.
  static List<_ClasseDemo> _classesDemo() {
    final PolitiqueCommerciale p = politiqueLancement;
    return <_ClasseDemo>[
      (
        id: 'demo-fi-classe-nour',
        nom: 'An-Nour',
        minutes: 480,
        capacite: p.capaciteEnfant,
        eligibles: p.capaciteEnfant,
        manques: const <Montant>[],
        adulte: false,
        type: TypeClasseRevenus.enfants,
      ),
      // Quatre sieges finances et Ibrahim, dont la periode n'est pas financee
      // : il manque [manqueDemo] (jeu `unARegulariser`, FIN4-09).
      (
        id: 'demo-fi-classe-huda',
        nom: 'Al-Huda',
        minutes: 480,
        capacite: p.capaciteEnfant,
        eligibles: 4,
        manques: <Montant>[manqueDemo],
        adulte: false,
        type: TypeClasseRevenus.enfants,
      ),
      (
        id: 'demo-fi-classe-salam',
        nom: 'As-Salam',
        minutes: 360,
        capacite: p.capaciteAdulte,
        eligibles: p.minimumOuverture,
        manques: const <Montant>[],
        adulte: true,
        type: TypeClasseRevenus.adultes,
      ),
    ];
  }

  /// Les revenus estimes de l'enseignant de demonstration (jeux du guide §8
  /// F6, [JeuRevenusEnseignant]). L'aide Internet est celle de la politique :
  /// aucune tant qu'elle n'en fixe pas le montant (§1.4), la demonstration
  /// n'en invente pas. [vide] : aucune heure assuree sur le mois.
  ///
  /// Seul le jeu nominal porte les sieges de [vueGlobale] (revues FI-1c-R M2,
  /// FI-1c-CORR-R m5) ; les autres jeux sont des variantes de fixture, que la
  /// vue globale de la direction ne lit pas.
  static RevenusEnseignant revenus({
    bool vide = false,
    JeuRevenusEnseignant jeu = JeuRevenusEnseignant.nominal,
  }) {
    final PolitiqueCommerciale p = politiqueLancement;
    final List<RevenusClasse> classes = <RevenusClasse>[
      if (!vide) ...<RevenusClasse>[
        for (final _ClasseDemo c in _classesDemo())
          _classe(
            c.id,
            c.nom,
            type: c.type,
            minutes: c.minutes,
            capacite: c.capacite,
            eligibles: switch ((jeu, c.id)) {
              // Mariam absente a une seance : financee, elle compte, la
              // Classe reste pleine (guide §1.4).
              (JeuRevenusEnseignant.financeAbsent, 'demo-fi-classe-nour') =>
                siegesEligibles(<SiegeSeance>[
                  for (int i = 1; i < c.capacite; i++)
                    SiegeSeance.financePresent,
                  SiegeSeance.financeAbsent,
                ], capacite: c.capacite),
              // La place d'Ibrahim tenue, a chaque seance du mois, par un
              // eleve en essai present : il compte sur tout le mois.
              (JeuRevenusEnseignant.essaiDansLaSeance, 'demo-fi-classe-huda') =>
                siegesEligibles(<SiegeSeance>[
                  for (int i = 1; i < c.capacite; i++)
                    SiegeSeance.financePresent,
                  SiegeSeance.essaiPresent,
                ], capacite: c.capacite),
              _ => c.eligibles,
            },
          ),
        // Une seance d'une heure assuree pour un collegue, dans une Classe de
        // debutants qu'il tient : elle est remuneree a celui qui l'assure.
        if (jeu == JeuRevenusEnseignant.remplacement)
          _classe(
            'demo-fi-classe-fajr',
            'Al-Fajr',
            type: TypeClasseRevenus.debutants,
            minutes: 60,
            capacite: p.capaciteDebutant,
            eligibles: siegesEligibles(<SiegeSeance>[
              for (int i = 1; i < p.capaciteDebutant; i++)
                SiegeSeance.financePresent,
              SiegeSeance.placeVide,
            ], capacite: p.capaciteDebutant),
            enRemplacement: true,
          ),
      ],
    ];
    final Montant total = _somme(
      classes.map((RevenusClasse c) => c.montantEstime),
    );
    final int minutes = classes.fold<int>(
      0,
      (int s, RevenusClasse c) => s + c.minutesAssurees,
    );
    return RevenusEnseignant(
      debut: debutMois,
      fin: finMois,
      classes: classes,
      total: TotalRevenus(
        minutesAssurees: minutes,
        capacite: classes.fold<int>(
          0,
          (int s, RevenusClasse c) => s + c.capacite,
        ),
        siegesEligibles: classes.fold<int>(
          0,
          (int s, RevenusClasse c) => s + c.siegesEligibles,
        ),
        // Le total rapporte aux heures assurees, arrondi a l'unite mineure
        // inferieure : il ne depasse donc jamais le plus haut taux effectif.
        tauxHoraireMoyen: Montant(
          minutes == 0 ? 0 : total.mineur * 60 ~/ minutes,
          devise,
        ),
      ),
      totalEstime: total,
      baseHoraire: p.baseHoraire,
      plafondHoraire: p.plafondHoraire,
      allocationInternet: p.allocationInternet,
    );
  }

  /// Le revenu academique du mois de reference : un tarif par siege eligible
  /// des classes de l'enseignant de demonstration, enfant ou adulte, hors
  /// taxe (FI13). Les remises de rang dependent des foyers, que ces sieges ne
  /// disent pas : la demonstration n'en invente pas. [adulte] restreint aux
  /// classes d'adultes (`true`) ou d'enfants (`false`) : la repartition de
  /// la vue globale (revue FI-VAGUE-R R6-01).
  static Montant revenuDemo({bool? adulte}) {
    final PolitiqueCommerciale p = politiqueLancement;
    return _somme(<Montant>[
      for (final _ClasseDemo c in _classesDemo())
        if (adulte == null || c.adulte == adulte)
          Montant(
            (c.adulte ? p.tarifAdulte : p.tarifEnfant).mineur *
                (c.eligibles > c.capacite ? c.capacite : c.eligibles),
            devise,
          ),
    ]);
  }

  /// Les impayes du mois de reference : la somme des manques des sieges a
  /// regulariser des classes de l'enseignant de demonstration, soit la meme
  /// population que [revenuDemo] et [revenus] (revue FI-1c-CORR-R m5).
  static Montant impayesDemo() => _somme(<Montant>[
    for (final _ClasseDemo c in _classesDemo())
      for (final Montant manque in c.manques) manque,
  ]);

  /// Les noms des classes d'adultes de la demonstration : aucun profil
  /// mineur n'y est inscrit (revue FI-1c-CORR-R m6).
  static Set<String> classesAdultesDemo() => <String>{
    for (final _ClasseDemo c in _classesDemo())
      if (c.adulte) c.nom,
  };

  /// La vue globale de la direction pour le mois de reference. Revenu,
  /// encaisse, impayes et paie portent sur les memes sieges (revues
  /// FI-1c-R M2, FI-1c-CORR-R m5) ; la marge est celle de la paie des
  /// enseignants seule, jamais une marge nette, qui demande des charges que
  /// la demonstration ne connait pas (guide §1.5) : elle ne se compare
  /// jamais aux 30 % nets de la politique (revue FI-1c-CORR-R m1).
  ///
  /// L'encaisse est ce que les sieges finances ont debite pour le mois : le
  /// revenu de ces memes sieges. Le versement partiel d'un siege a
  /// regulariser n'est pas debite (FIN4-09) : il reste dans le solde du
  /// profil, la demonstration ne l'invente pas en encaissement.
  ///
  /// Toutes les sections lisent UNE population (contre-revue FI-DIR-1) :
  /// les sieges de [_classesDemo] et, pour les profils nommes, le foyer
  /// [jeuVueGlobale], dont chaque profil occupe l'un de ces sieges (Mariam
  /// et Aicha a An-Nour, Ibrahim a regulariser a Al-Huda). Un profil n'y est
  /// donc jamais a la fois en essai et dans un paiement.
  static VueGlobaleFinance vueGlobale() {
    final FinancesFoyer finance = finances(jeuVueGlobale);
    final Montant revenu = revenuDemo();
    final Montant paie = revenus().totalEstime;
    final int marge = (revenu.mineur - paie.mineur) * 1000 ~/ revenu.mineur;
    return VueGlobaleFinance(
      mois: debutMois,
      encaisse: revenu,
      revenuAcademique: revenu,
      paieEnseignants: paie,
      margeProjeteePourMille: marge,
      impayes: impayesDemo(),
      essaisEnCours: _essaisVueGlobale(),
      soldesCrediteurs: finance.synthese.totalSoldes,
      alertes: <AlerteFinance>[
        AlerteFinance(
          id: 'demo-fi-alerte-ibrahim',
          nature: NatureAlerteFinance.aRegulariser,
          cible: CibleAlerteFinance.comptes,
          prenom: _ibrahim.prenom,
          classe: _ibrahim.classe,
          // Le seul siege a regulariser des classes : son manque est
          // l'impaye du mois, jamais un second chiffre.
          montant: impayesDemo(),
        ),
      ],
      // La politique est entree en vigueur en octobre 2026 (date d'effet de
      // [politiqueLancement]) : les series n'ont qu'un mois, celui de la
      // vue, aucun historique invente avant le lancement.
      encaisseParMois: <MontantMensuel>[
        MontantMensuel(mois: debutMois, montant: revenu),
      ],
      paieParMois: <MontantMensuel>[
        MontantMensuel(mois: debutMois, montant: paie),
      ],
      margeParMois: <MargeMensuelle>[
        MargeMensuelle(mois: debutMois, pourMille: marge),
      ],
      revenuParType: <PartRevenu>[
        PartRevenu(
          type: TypeEleveRevenu.enfant,
          montant: revenuDemo(adulte: false),
        ),
        PartRevenu(
          type: TypeEleveRevenu.adulte,
          montant: revenuDemo(adulte: true),
        ),
      ],
      etatPaiements: etatPaiementsDemo(),
      topClasses: topClassesDemo(),
      // Les mouvements du foyer de demonstration ou Ibrahim est a
      // regulariser, comme l'alerte : le plus recent d'abord (FI-BR-05).
      dernieresOperations: derniersMouvements(jeuVueGlobale, limite: 5),
    );
  }

  /// L'etat des paiements du mois de reference (revue FI-VAGUE-R R6-02),
  /// sur les MEMES sieges que le revenu et les impayes : finances = sieges
  /// eligibles des classes, a regulariser = sieges qui ont un manque, en
  /// essai = les essais en cours de la vue, en confirmation = aucun paiement
  /// en attente dans la demonstration. Les parts sont calculees ICI, sur le
  /// total de ces profils (pour mille, arrondi inferieur), jamais a l'ecran.
  static List<CompteEtatPaiements> etatPaiementsDemo() {
    int finances = 0;
    int aRegulariser = 0;
    for (final _ClasseDemo c in _classesDemo()) {
      finances += c.eligibles > c.capacite ? c.capacite : c.eligibles;
      aRegulariser += c.manques.length;
    }
    final int essais = _essaisVueGlobale();
    const int enConfirmation = 0;
    final List<(EtatPaiementsProfils, int)> comptes =
        <(EtatPaiementsProfils, int)>[
          (EtatPaiementsProfils.finances, finances),
          (EtatPaiementsProfils.aRegulariser, aRegulariser),
          (EtatPaiementsProfils.enEssai, essais),
          (EtatPaiementsProfils.enConfirmation, enConfirmation),
        ];
    final List<int>? parts = partsPourMille(<int>[
      for (final (EtatPaiementsProfils _, int n) in comptes) n,
    ]);
    return <CompteEtatPaiements>[
      for (final (int i, (EtatPaiementsProfils, int) c) in comptes.indexed)
        CompteEtatPaiements(
          etat: c.$1,
          profils: c.$2,
          partPourMille: parts?[i],
        ),
    ];
  }

  /// Le foyer dont la vue globale lit les profils nommes (essais, soldes,
  /// dernieres operations) : celui ou Ibrahim est a regulariser, comme
  /// l'alerte et les impayes, et dont chaque profil occupe un siege de
  /// [_classesDemo]. Aucun profil n'y est en essai.
  static const JeuFoyerFinance jeuVueGlobale = JeuFoyerFinance.unARegulariser;

  /// Les essais en cours de la vue globale : ceux du foyer [jeuVueGlobale]
  /// (les sieges de [_classesDemo] sont tous finances ou a regulariser).
  static int _essaisVueGlobale() =>
      profils(jeuVueGlobale)
          .where((FinancesProfil p) => p.etat == EtatFinancier.essai)
          .length;

  /// Les parts en pour mille de [nombres] sur leur total, dont la somme
  /// fait exactement 1000 (methode du plus fort reste) : la part entiere
  /// de chacun, puis les milliemes restants aux plus forts restes, a reste
  /// egal dans l'ordre rendu. `null` quand le total est nul. Calcul de
  /// DEMONSTRATION : en production, les parts sont rendues par le serveur
  /// (FI-BR-12), jamais calculees cote Flutter.
  static List<int>? partsPourMille(List<int> nombres) {
    final int total = nombres.fold<int>(0, (int s, int n) => s + n);
    if (total == 0) return null;
    final List<int> parts = <int>[
      for (final int n in nombres) n * 1000 ~/ total,
    ];
    final List<int> restes = <int>[
      for (final int n in nombres) n * 1000 % total,
    ];
    int manquants = 1000 - parts.fold<int>(0, (int s, int n) => s + n);
    final List<int> ordre = List<int>.generate(nombres.length, (int i) => i)
      ..sort((int a, int b) {
        final int parReste = restes[b].compareTo(restes[a]);
        return parReste != 0 ? parReste : a.compareTo(b);
      });
    for (final int i in ordre) {
      if (manquants == 0) break;
      parts[i]++;
      manquants--;
    }
    return parts;
  }

  /// Les classes de la demonstration rangees par encaisse du mois, la
  /// premiere d'abord (revue FI-VAGUE-R R6-02) : le tarif de chaque siege
  /// finance, comme [revenuDemo], dont la somme est l'encaisse de la vue.
  static List<EncaissementClasse> topClassesDemo() {
    final PolitiqueCommerciale p = politiqueLancement;
    final List<EncaissementClasse> lignes = <EncaissementClasse>[
      for (final _ClasseDemo c in _classesDemo())
        EncaissementClasse(
          classe: c.nom,
          encaisse: Montant(
            (c.adulte ? p.tarifAdulte : p.tarifEnfant).mineur *
                (c.eligibles > c.capacite ? c.capacite : c.eligibles),
            devise,
          ),
        ),
    ];
    return lignes..sort(
      (EncaissementClasse a, EncaissementClasse b) =>
          b.encaisse.mineur.compareTo(a.encaisse.mineur),
    );
  }

  /// Vrai quand [mois] est le mois de reference de la demonstration : le
  /// seul qu'elle sait rendre, la politique etant entree en vigueur en
  /// octobre 2026 (aucun mois invente avant le lancement).
  static bool estMoisDeReference(DateTime? mois) =>
      mois == null ||
      (mois.year == debutMois.year && mois.month == debutMois.month);
}

/// Les paiements du foyer en demonstration (FI-BR-03, FI-BR-04).
class PaiementsFoyerFinanceDemo implements PortPaiementsFoyer {
  /// Cree le double pour le jeu [jeu].
  const PaiementsFoyerFinanceDemo(this.jeu);

  /// Le jeu du foyer.
  final JeuFoyerFinance jeu;

  @override
  Future<FinancesFoyer> finances() async => DonneesFinanceDemo.finances(jeu);

  @override
  Future<List<PaiementFoyer>> historique() async => <PaiementFoyer>[
    for (int i = 0; i < DonneesFinanceDemo.paiementsDuMois(jeu); i++)
      PaiementFoyer(
        id: 'demo-fi-paiement-$i',
        // Un mois au tarif enfant de la politique.
        montantMineur: DonneesFinanceDemo.politiqueLancement.tarifEnfant.mineur,
        devise: DonneesFinanceDemo.devise,
        statutServeur: 'completed',
        date: DonneesFinanceDemo.debutMois.add(Duration(days: i)),
        justificatifDisponible: i == 0,
      ),
  ];

  @override
  Future<PaiementFoyer?> detail(String id) async {
    for (final PaiementFoyer p in await historique()) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) async =>
      DonneesFinanceDemo.mouvements(jeu, profilId);

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) async =>
      DonneesFinanceDemo.derniersMouvements(jeu, limite: limite);

  // Les soldes rediges d'EA-9 sont remplaces par `finances()` (FI-BR-03).
  @override
  Future<SoldesFoyer> soldes() =>
      Future<SoldesFoyer>.error(const CapaciteIndisponible('FI-BR-03'));
}

/// Les paiements du foyer du titulaire adulte en demonstration (revue
/// FI-VAGUE-R R1-06) : ses finances, ses mouvements et l'historique d'un
/// seul paiement, celui du recu qui a recharge le foyer. Rien n'est envoye
/// (K-28).
class PaiementsFoyerProfilsDemo implements PortPaiementsFoyer {
  /// Cree le double pour les profils [profils].
  const PaiementsFoyerProfilsDemo(this.profils);

  /// Les finances des membres du foyer, dans l'ordre du foyer.
  final List<FinancesProfil> profils;

  RecuPaiement? get _recu => DonneesFinanceDemo.recuDe(profils);

  @override
  Future<FinancesFoyer> finances() async => DonneesFinanceDemo.foyerDe(
    profils,
    paiementsDuMois: _recu == null ? 0 : 1,
  );

  @override
  Future<List<PaiementFoyer>> historique() async => <PaiementFoyer>[
    if (_recu case final RecuPaiement r)
      PaiementFoyer(
        id: 'demo-fi-paiement-${r.reference}',
        montantMineur: r.total.mineur,
        devise: r.total.devise,
        statutServeur: 'completed',
        date: r.date,
        justificatifDisponible: true,
      ),
  ];

  @override
  Future<PaiementFoyer?> detail(String id) async {
    for (final PaiementFoyer p in await historique()) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) async =>
      DonneesFinanceDemo.mouvementsDans(profils, profilId);

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) async =>
      DonneesFinanceDemo.derniersMouvementsDans(profils, limite: limite);

  // Les soldes rediges d'EA-9 sont remplaces par `finances()` (FI-BR-03).
  @override
  Future<SoldesFoyer> soldes() =>
      Future<SoldesFoyer>.error(const CapaciteIndisponible('FI-BR-03'));
}

/// La recharge du foyer en demonstration (FI-7) : les profils du jeu et
/// leurs montants proposes, le recapitulatif arrete par la demonstration,
/// et le suivi qui parcourt les huit etats (FI-BR-06). Le paiement (FI-8)
/// rend une commande de demonstration, la meme pour la meme cle ; son suivi
/// avance d'un etat a chaque lecture, jusqu'a `termine`. Rien n'est envoye
/// (K-28).
///
/// Les commandes payees vivent dans des tables statiques : une portee de
/// demonstration reconstruite (bascule de theme) cree un autre double, sans
/// perdre la commande en cours ni payer une seconde fois.
class RechargeFoyerFinanceDemo implements PortRechargeFoyer {
  /// Cree le double pour le jeu [jeu].
  const RechargeFoyerFinanceDemo([this.jeu = JeuFoyerFinance.tousFinances]);

  /// Le jeu du foyer.
  final JeuFoyerFinance jeu;

  /// Les derniers montants verifies, par jeu : ce que le paiement reprend.
  static final Map<JeuFoyerFinance, List<MontantRecharge>> _verifies =
      <JeuFoyerFinance, List<MontantRecharge>>{};

  /// Les montants de chaque commande payee, figes au premier paiement.
  static final Map<String, List<MontantRecharge>> _payees =
      <String, List<MontantRecharge>>{};

  /// Le nombre de lectures de chaque commande payee.
  static final Map<String, int> _lectures = <String, int>{};

  @override
  Future<SuiviPaiement> suivre(String commandeId) async {
    final List<MontantRecharge>? choix = _payees[commandeId];
    if (choix == null) return DonneesFinanceDemo.suivi(commandeId);
    final int n = _lectures.update(
      commandeId,
      (int v) => v + 1,
      ifAbsent: () => 0,
    );
    const List<EtatPaiement> etapes = DonneesFinanceDemo.progressionDemo;
    return DonneesFinanceDemo.suiviPaye(
      jeu,
      commandeId,
      choix,
      etapes[n < etapes.length ? n : etapes.length - 1],
    );
  }

  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async {
    final RecapitulatifRecharge r = DonneesFinanceDemo.recapitulatifMontants(
      jeu,
      choix,
    );
    _verifies[jeu] = List<MontantRecharge>.unmodifiable(choix);
    return r;
  }

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async =>
      DonneesFinanceDemo.beneficiairesRecharge(jeu);

  // Le contrat par offres (EA-10) n'a pas de source dans la Finance V4.
  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  /// Idempotent par [cle] : une seconde confirmation sous la meme cle rend
  /// la meme commande et ne fige pas d'autres montants (un seul credit).
  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) async {
    final String commande = DonneesFinanceDemo.commandePayee(cle);
    if (_payees.containsKey(commande)) return commande;
    final List<MontantRecharge>? choix = _verifies[jeu];
    if (choix == null || choix.isEmpty) {
      throw ArgumentError.value(recapitulatifId, 'recapitulatifId');
    }
    _payees[commande] = choix;
    return commande;
  }
}

/// Mes finances en demonstration (FI-9b, FI-BR-17) : le seul profil de
/// l'eleve adulte autonome, jamais un autre membre.
class MesFinancesDemo implements PortMesFinances {
  /// Cree le double pour la finance [finance].
  const MesFinancesDemo(this.finance);

  /// La finance de l'adulte.
  final FinancesProfil finance;

  @override
  Future<FinancesProfil?> finances() async => finance;

  @override
  Future<List<MouvementProfil>> mouvements() async =>
      DonneesFinanceDemo.mouvementsAdulte(finance);
}

/// La recharge de l'eleve adulte autonome en demonstration (FI-9b,
/// FI-BR-17) : le MEME moteur que celle du foyer, avec son seul profil pour
/// beneficiaire. Le paiement n'a pas de prestataire : l'etat honnete
/// (`CapaciteIndisponible`).
class RechargeAdulteDemo implements PortRechargeFoyer {
  /// Cree le double pour la finance [finance].
  const RechargeAdulteDemo(this.finance);

  /// La finance de l'adulte.
  final FinancesProfil finance;

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async =>
      DonneesFinanceDemo.beneficiairesDe(<FinancesProfil>[finance]);

  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async => DonneesFinanceDemo.recapitulatifDe(
    DonneesFinanceDemo.beneficiairesDe(<FinancesProfil>[finance]),
    choix,
  );

  // Le contrat par offres (EA-10) n'a pas de source dans la Finance V4.
  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('FI-BR-17'),
      );

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => Future<String>.error(const CapaciteIndisponible('FI-BR-17'));

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Future<SuiviPaiement>.error(const CapaciteIndisponible('FI-BR-17'));
}

/// L'acces du foyer en demonstration (FI-BR-08), pour le titulaire.
class AccesFoyerFinanceDemo implements PortAccesFoyer {
  /// Cree le double pour le jeu [jeu] ; [places] : l'etat de place rendu
  /// par eleve (place liberee, acces reactive).
  const AccesFoyerFinanceDemo(
    this.jeu, {
    this.places = const <String, EtatPlace>{},
  });

  /// Le jeu du foyer.
  final JeuFoyerFinance jeu;

  /// L'etat de place par eleve.
  final Map<String, EtatPlace> places;

  @override
  Future<List<AccesBeneficiaire>> acces() async =>
      DonneesFinanceDemo.acces(jeu, places: places);
}

/// L'acces de l'eleve connecte en demonstration (FI-BR-08, revue
/// FI-VAGUE-R R4-02) : **sa seule ligne**, comme le serveur la rendra pour
/// sa session ; aucune autre ligne du foyer n'existe dans ce double.
class MonAccesFinanceDemo implements PortMonAcces {
  /// Cree le double pour l'eleve [eleveId] du jeu [jeu].
  const MonAccesFinanceDemo(this.jeu, this.eleveId, {this.place});

  /// Le jeu du foyer.
  final JeuFoyerFinance jeu;

  /// L'eleve connecte.
  final String eleveId;

  /// L'etat de place rendu pour lui.
  final EtatPlace? place;

  @override
  Future<AccesBeneficiaire?> monAcces() async {
    final EtatPlace? etat = place;
    for (final AccesBeneficiaire a in DonneesFinanceDemo.acces(
      jeu,
      places: etat == null
          ? const <String, EtatPlace>{}
          : <String, EtatPlace>{eleveId: etat},
    )) {
      if (a.eleveId == eleveId) return a;
    }
    return null;
  }
}

/// Les politiques commerciales en demonstration (FI-BR-01, FI-BR-02).
class PolitiquesCommercialesDemo implements PortPolitiquesCommerciales {
  /// Cree le double.
  const PolitiquesCommercialesDemo();

  @override
  Future<PolitiqueCommerciale> active() async =>
      DonneesFinanceDemo.politiqueLancement;

  /// Le brouillon d'abord, puis la version active (la plus recente
  /// d'abord).
  @override
  Future<List<PolitiqueCommerciale>> versions() async => <PolitiqueCommerciale>[
    DonneesFinanceDemo.politiqueBrouillon,
    DonneesFinanceDemo.politiqueLancement,
  ];

  /// La demonstration ne publie rien non plus (FI-BR-02) : le meme etat
  /// honnete qu'en production.
  @override
  Future<void> publier(PolitiqueCommerciale brouillon) =>
      Future<void>.error(const CapaciteIndisponible('FI-BR-02'));

  /// L'apercu se calcule ICI, a partir des regles du brouillon recu (FI-11c).
  @override
  Future<ApercuFamille> apercuFamille(
    PolitiqueCommerciale brouillon,
    int enfants,
  ) async => DonneesFinanceDemo.apercuFamille(brouillon, enfants);

  @override
  Future<ApercuEnseignant> apercuEnseignant(
    PolitiqueCommerciale brouillon, {
    required int capacite,
    required int eligibles,
  }) async => DonneesFinanceDemo.apercuEnseignant(
    brouillon,
    capacite: capacite,
    eligibles: eligibles,
  );
}

/// Les revenus de l'enseignant en demonstration (FI-BR-11).
class RevenusEnseignantDemo implements PortRevenusEnseignant {
  /// Cree le double ; [vide] rend un mois sans heure assuree.
  const RevenusEnseignantDemo({
    this.vide = false,
    this.jeu = JeuRevenusEnseignant.nominal,
  });

  /// Vrai pour un mois sans heure assuree.
  final bool vide;

  /// Le jeu du guide §8 F6.
  final JeuRevenusEnseignant jeu;

  @override
  Future<RevenusEnseignant> moisEnCours() async =>
      DonneesFinanceDemo.revenus(vide: vide, jeu: jeu);

  /// Le seul mois de la demonstration est le mois de reference ; un autre
  /// mois n'est pas invente (FI-BR-11).
  @override
  Future<RevenusEnseignant> duMois(DateTime mois) =>
      DonneesFinanceDemo.estMoisDeReference(mois)
      ? moisEnCours()
      : Future<RevenusEnseignant>.error(const CapaciteIndisponible('FI-BR-11'));

  @override
  Future<List<DateTime>> moisDisponibles() async => <DateTime>[
    DonneesFinanceDemo.debutMois,
  ];

  /// Le releve est arrete par l'academie, a partir de la paie reelle, hors
  /// lot (ADR-007) : la demonstration n'invente pas un mois arrete, elle dit
  /// le releve indisponible, comme la production (FI-BR-11).
  @override
  Future<List<LigneReleve>> releve() =>
      Future<List<LigneReleve>>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// La vue globale de la direction en demonstration (FI-BR-12).
class FinanceDirectionDemo implements PortFinanceDirection {
  /// Cree le double.
  const FinanceDirectionDemo();

  /// Le seul mois de la demonstration est le mois de reference ; un autre
  /// mois n'est pas invente (FI-BR-12).
  @override
  Future<VueGlobaleFinance> vueGlobale({DateTime? mois}) =>
      DonneesFinanceDemo.estMoisDeReference(mois)
      ? Future<VueGlobaleFinance>.value(DonneesFinanceDemo.vueGlobale())
      : Future<VueGlobaleFinance>.error(const CapaciteIndisponible('FI-BR-12'));

  @override
  Future<List<DateTime>> moisDisponibles() async => <DateTime>[
    DonneesFinanceDemo.debutMois,
  ];
}
