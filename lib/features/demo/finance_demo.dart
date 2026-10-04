// La SEULE source des donnees de demonstration de la Finance (FI-1c, guide
// Finance V4 §1, §8 F1 « fixtures », F2 ; lecon 14).
//
// Ce fichier porte :
// - la politique commerciale de lancement (guide §1), versionnee : aucune
//   valeur commerciale n'existe ailleurs dans `lib/` (FI6) ;
// - le foyer de demonstration (Mariam, Ibrahim, Aicha) et les six jeux du
//   guide F2 (tous finances, un a regulariser, un en essai, aucun paiement,
//   un profil, cinq profils) ;
// - les doubles de demonstration des ports Finance, qui CALCULENT ici ce que
//   le serveur arretera apres BR-1 (mensualites par rang, synthese du foyer,
//   revenus de l'enseignant) : jamais dans un widget (FI6, FI-11c).
//
// Rien n'est envoye (K-28). Les ports reels restent neutres
// (`CapaciteIndisponible`) ; seule la demonstration les surcharge (K-09).
// Les valeurs des maquettes (30 $, 2024, « Remise famille -5 $ » sur Mariam)
// ne sont PAS recopiees : Mariam est au rang 1, sans remise (guide §1.3).
//
// L'affichage d'un montant de demonstration porte « (demonstration) »
// (REVUE_EA-R m4) : c'est le composant d'argent qui l'ecrit (FI-3a), jamais
// ces donnees.

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/capacites/port_recharge_foyer.dart';
import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/finance/finances_profil.dart';
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
  List<int> manques,
  bool adulte,
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
  final String classe;
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

  /// La politique commerciale de lancement (guide §1), publiee.
  static final PolitiqueCommerciale politiqueLancement = PolitiqueCommerciale(
    version: 'lancement-2026-10',
    statut: StatutPolitique.publiee,
    dateEffet: DateTime(2026, 10),
    tarifEnfant: usd(50),
    tarifAdulte: usd(60),
    essaisMax: 2,
    remisesParRang: <RemiseRang>[
      RemiseRang(aPartirDuRang: 3, remise: usd(-5)),
      RemiseRang(aPartirDuRang: 4, remise: usd(-7)),
    ],
    baseHoraire: usd(4),
    plafondHoraire: usd(7),
    capaciteEnfant: 5,
    capaciteAdulte: 6,
    capaciteDebutant: 4,
    minimumOuverture: 4,
    groupesObjectif: 3,
    groupesMax: 4,
    joursConservationPlace: 7,
    margeReferencePourMille: (objectif: 300, forte: 350, stretch: 400),
    railsActifs: const <RailPaiement>{RailPaiement.webStripe},
  );

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
  // Al-Huda, classe enfants, jamais As-Salam, classe adultes a 60 USD
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
  static List<LigneMensualite> lignesPourRang(
    int rang, {
    PolitiqueCommerciale? politique,
    bool adulte = false,
  }) {
    final PolitiqueCommerciale p = politique ?? politiqueLancement;
    final Montant? remise = p.remisePourRang(rang);
    return <LigneMensualite>[
      LigneMensualite(
        nature: NatureLigneMensualite.tarif,
        montant: adulte ? p.tarifAdulte : p.tarifEnfant,
      ),
      if (remise != null)
        LigneMensualite(
          nature: NatureLigneMensualite.remiseRang,
          montant: remise,
        ),
    ];
  }

  static Montant _somme(Iterable<Montant> montants) => Montant(
    montants.fold<int>(0, (int s, Montant m) => s + m.mineur),
    devise,
  );

  static FinancesProfil _finance(
    _ProfilDemo p, {
    required int rang,
    required EtatFinancier etat,
    required int solde,
    bool finance = true,
    int? essais,
    int? manque,
  }) {
    final List<LigneMensualite> lignes = essais != null
        ? const <LigneMensualite>[]
        : lignesPourRang(rang);
    final Montant mensualite = _somme(
      lignes.map((LigneMensualite l) => l.montant),
    );
    return FinancesProfil(
      profilId: p.id,
      prenom: p.prenom,
      cleAccent: p.cleAccent,
      estAdulte: false,
      classe: p.classe,
      age: p.age,
      etat: etat,
      solde: usd(solde),
      periode: finance ? PeriodeFinancee(debut: debutMois, fin: finMois) : null,
      prochainDebit: essais != null
          ? null
          : ProchainDebit(date: moisSuivant, montant: mensualite),
      mensualite: mensualite,
      lignesMensualite: lignes,
      essaisUtilises: essais,
      manque: manque == null ? null : usd(manque),
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
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: 12),
      // Ibrahim : solde nul, mois finance (FI2, FIN4-08).
      _finance(_ibrahim, rang: 2, etat: EtatFinancier.finance, solde: 0),
      _finance(_aicha, rang: 3, etat: EtatFinancier.finance, solde: 45),
    ],
    JeuFoyerFinance.unARegulariser => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: 12),
      // 42 sur 50 : aucun debit partiel, l'ecran dit le manque (FIN4-09).
      _finance(
        _ibrahim,
        rang: 2,
        etat: EtatFinancier.aRegulariser,
        solde: 42,
        finance: false,
        manque: 8,
      ),
      _finance(_aicha, rang: 3, etat: EtatFinancier.finance, solde: 45),
    ],
    // Aicha en essai ne compte pas comme payante (FIN4-15) : Mariam et
    // Ibrahim restent aux rangs 1 et 2, sans remise.
    JeuFoyerFinance.unEnEssai => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: 12),
      _finance(_ibrahim, rang: 2, etat: EtatFinancier.finance, solde: 0),
      _finance(
        _aicha,
        rang: 0,
        etat: EtatFinancier.essai,
        solde: 0,
        finance: false,
        essais: 1,
      ),
    ],
    JeuFoyerFinance.aucunPaiement => <FinancesProfil>[
      _finance(
        _mariam,
        rang: 1,
        etat: EtatFinancier.manque,
        solde: 0,
        finance: false,
        manque: 50,
      ),
      _finance(
        _ibrahim,
        rang: 2,
        etat: EtatFinancier.manque,
        solde: 0,
        finance: false,
        manque: 50,
      ),
    ],
    JeuFoyerFinance.unProfil => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: 12),
    ],
    JeuFoyerFinance.cinqProfils => <FinancesProfil>[
      _finance(_mariam, rang: 1, etat: EtatFinancier.finance, solde: 12),
      _finance(_ibrahim, rang: 2, etat: EtatFinancier.finance, solde: 0),
      _finance(_aicha, rang: 3, etat: EtatFinancier.finance, solde: 45),
      _finance(_youssef, rang: 4, etat: EtatFinancier.finance, solde: 20),
      _finance(_khadija, rang: 5, etat: EtatFinancier.finance, solde: 3),
    ],
  };

  /// Le nombre de paiements du mois dans le jeu [jeu].
  static int paiementsDuMois(JeuFoyerFinance jeu) => switch (jeu) {
    JeuFoyerFinance.aucunPaiement => 0,
    JeuFoyerFinance.unProfil => 1,
    _ => 2,
  };

  /// Les finances du foyer du jeu [jeu], synthese comprise. La synthese est
  /// une LECTURE (FI1) : additionnee ici, dans le double de demonstration.
  static FinancesFoyer finances(JeuFoyerFinance jeu) {
    final List<FinancesProfil> liste = profils(jeu);
    return FinancesFoyer(
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
        paiementsDuMois: paiementsDuMois(jeu),
      ),
    );
  }

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
  static List<AccesBeneficiaire> acces(JeuFoyerFinance jeu) =>
      <AccesBeneficiaire>[
        for (final FinancesProfil p in profils(jeu)) _acces(p),
      ];

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
      essaisMax: p.essaisUtilises == null ? null : politiqueLancement.essaisMax,
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
            NatureLigneMensualite.tarif ||
            NatureLigneMensualite.taxe => NatureMouvement.debitPeriode,
            NatureLigneMensualite.remiseRang ||
            NatureLigneMensualite.prorata => NatureMouvement.remise,
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
  static RecuPaiement? recu(JeuFoyerFinance jeu) {
    final List<AllocationProfil> allocations = <AllocationProfil>[
      for (final FinancesProfil p in profils(jeu))
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
  ) {
    final FinancesProfil? p = profils(jeu)
        .where((FinancesProfil f) => f.profilId == profilId)
        .firstOrNull;
    if (p == null) return const <MouvementProfil>[];
    final Montant recharge = _rechargeDe(p);
    return <MouvementProfil>[
      ..._mouvementsPeriode(p),
      if (recharge.mineur > 0)
        MouvementProfil(
          id: 'demo-fi-mvt-${p.profilId}-recharge',
          date: dateRecharge,
          nature: NatureMouvement.recharge,
          montant: recharge,
          recu: recu(jeu),
        ),
    ];
  }

  /// L'identifiant de la commande de demonstration dans l'etat [etat] : la
  /// demonstration parcourt les huit etats (revue FI-1a E-10).
  static String commandeDemo(EtatPaiement etat) => 'demo-fi-cmd-${etat.name}';

  /// Le suivi de la commande [commandeId] : Mariam +10, Ibrahim +40, total
  /// 50 (guide §1.6). Les nouveaux soldes ne sont rendus qu'a `termine`.
  static SuiviPaiement suivi(String commandeId) {
    final EtatPaiement etat = EtatPaiement.values.firstWhere(
      (EtatPaiement e) => commandeDemo(e) == commandeId,
      orElse: () => throw const CapaciteIndisponible('FI-BR-06'),
    );
    final bool termine = etat == EtatPaiement.termine;
    return SuiviPaiement(
      commandeId: commandeId,
      etat: etat,
      total: usd(50),
      reference: 'RWY-123',
      date: aujourdhui,
      allocations: <AllocationProfil>[
        AllocationProfil(
          profilId: mariamId,
          prenom: _mariam.prenom,
          montant: usd(10),
          nouveauSolde: termine ? usd(22) : null,
        ),
        AllocationProfil(
          profilId: ibrahimId,
          prenom: _ibrahim.prenom,
          montant: usd(40),
          nouveauSolde: termine ? usd(40) : null,
        ),
      ],
    );
  }

  /// Le taux horaire effectif d'une classe (guide §1.4), en unites
  /// mineures : base + (plafond - base) x eligibles / capacite, plafonne.
  /// Calcul du double de demonstration, jamais dans un widget (FI-11c).
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

  static RevenusClasse _classe(
    String id,
    String nom, {
    required int minutes,
    required int capacite,
    required int eligibles,
  }) {
    final Montant taux = tauxEffectif(
      siegesEligibles: eligibles,
      capacite: capacite,
    );
    return RevenusClasse(
      classeId: id,
      classe: nom,
      minutesAssurees: minutes,
      capacite: capacite,
      siegesEligibles: eligibles > capacite ? capacite : eligibles,
      tauxHoraireEffectif: taux,
      montantEstime: Montant(minutes * taux.mineur ~/ 60, devise),
    );
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
        manques: const <int>[],
        adulte: false,
      ),
      // Quatre sieges finances et Ibrahim, dont la periode n'est pas financee
      // : 42 sur 50, il manque 8 (jeu `unARegulariser`, FIN4-09).
      (
        id: 'demo-fi-classe-huda',
        nom: 'Al-Huda',
        minutes: 480,
        capacite: p.capaciteEnfant,
        eligibles: 4,
        manques: const <int>[8],
        adulte: false,
      ),
      (
        id: 'demo-fi-classe-salam',
        nom: 'As-Salam',
        minutes: 360,
        capacite: p.capaciteAdulte,
        eligibles: p.minimumOuverture,
        manques: const <int>[],
        adulte: true,
      ),
    ];
  }

  /// Les revenus estimes de l'enseignant de demonstration (jeux du guide §8
  /// F6 : classe pleine, classe a 80 %, classe au minimum). L'aide Internet
  /// est celle de la politique : aucune tant qu'elle n'en fixe pas le montant
  /// (§1.4), la demonstration n'en invente pas. [vide] : aucune heure
  /// assuree sur le mois.
  static RevenusEnseignant revenus({bool vide = false}) {
    final List<RevenusClasse> classes = <RevenusClasse>[
      if (!vide)
        for (final _ClasseDemo c in _classesDemo())
          _classe(
            c.id,
            c.nom,
            minutes: c.minutes,
            capacite: c.capacite,
            eligibles: c.eligibles,
          ),
    ];
    return RevenusEnseignant(
      debut: debutMois,
      fin: finMois,
      classes: classes,
      totalEstime: _somme(classes.map((RevenusClasse c) => c.montantEstime)),
      baseHoraire: politiqueLancement.baseHoraire,
      plafondHoraire: politiqueLancement.plafondHoraire,
      allocationInternet: politiqueLancement.allocationInternet,
    );
  }

  /// Le revenu academique du mois de reference : un tarif par siege eligible
  /// des classes de l'enseignant de demonstration, enfant ou adulte, hors
  /// taxe (FI13). Les remises de rang dependent des foyers, que ces sieges ne
  /// disent pas : la demonstration n'en invente pas.
  static Montant revenuDemo() {
    final PolitiqueCommerciale p = politiqueLancement;
    return _somme(<Montant>[
      for (final _ClasseDemo c in _classesDemo())
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
      for (final int manque in c.manques) usd(manque),
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
  static VueGlobaleFinance vueGlobale() {
    final FinancesFoyer finance = finances(JeuFoyerFinance.tousFinances);
    final Montant revenu = revenuDemo();
    final Montant paie = revenus().totalEstime;
    return VueGlobaleFinance(
      mois: debutMois,
      encaisse: revenu,
      revenuAcademique: revenu,
      paieEnseignants: paie,
      margeProjeteePourMille:
          (revenu.mineur - paie.mineur) * 1000 ~/ revenu.mineur,
      impayes: impayesDemo(),
      essaisEnCours: profils(JeuFoyerFinance.unEnEssai)
          .where((FinancesProfil p) => p.etat == EtatFinancier.essai)
          .length,
      soldesCrediteurs: finance.synthese.totalSoldes,
      alertes: <AlerteFinance>[
        AlerteFinance(
          id: 'demo-fi-alerte-ibrahim',
          nature: NatureAlerteFinance.aRegulariser,
          prenom: _ibrahim.prenom,
          classe: _ibrahim.classe,
          // Le seul siege a regulariser des classes : son manque est
          // l'impaye du mois, jamais un second chiffre.
          montant: impayesDemo(),
        ),
      ],
    );
  }
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
        montantMineur: DonneesFinanceDemo.usd(50).mineur,
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

  // Les soldes rediges d'EA-9 sont remplaces par `finances()` (FI-BR-03).
  @override
  Future<SoldesFoyer> soldes() =>
      Future<SoldesFoyer>.error(const CapaciteIndisponible('FI-BR-03'));
}

/// La recharge du foyer en demonstration : le suivi parcourt les huit etats
/// (FI-BR-06). La recharge par montants arrive avec son ecran (FI-7).
class RechargeFoyerFinanceDemo implements PortRechargeFoyer {
  /// Cree le double.
  const RechargeFoyerFinanceDemo();

  @override
  Future<SuiviPaiement> suivre(String commandeId) async =>
      DonneesFinanceDemo.suivi(commandeId);

  @override
  Future<RecapitulatifRecharge> verifierMontants(List<MontantRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() =>
      Future<List<BeneficiaireRecharge>>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      Future<RecapitulatifRecharge>.error(
        const CapaciteIndisponible('FI-BR-06'),
      );

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => Future<String>.error(const CapaciteIndisponible('FI-BR-06'));
}

/// L'acces du foyer en demonstration (FI-BR-08).
class AccesFoyerFinanceDemo implements PortAccesFoyer {
  /// Cree le double pour le jeu [jeu].
  const AccesFoyerFinanceDemo(this.jeu);

  /// Le jeu du foyer.
  final JeuFoyerFinance jeu;

  @override
  Future<List<AccesBeneficiaire>> acces() async =>
      DonneesFinanceDemo.acces(jeu);
}

/// Les politiques commerciales en demonstration (FI-BR-01, FI-BR-02).
class PolitiquesCommercialesDemo implements PortPolitiquesCommerciales {
  /// Cree le double.
  const PolitiquesCommercialesDemo();

  @override
  Future<PolitiqueCommerciale> active() async =>
      DonneesFinanceDemo.politiqueLancement;

  @override
  Future<List<PolitiqueCommerciale>> versions() async => <PolitiqueCommerciale>[
    DonneesFinanceDemo.politiqueLancement,
  ];
}

/// Les revenus de l'enseignant en demonstration (FI-BR-11).
class RevenusEnseignantDemo implements PortRevenusEnseignant {
  /// Cree le double ; [vide] rend un mois sans heure assuree.
  const RevenusEnseignantDemo({this.vide = false});

  /// Vrai pour un mois sans heure assuree.
  final bool vide;

  @override
  Future<RevenusEnseignant> moisEnCours() async =>
      DonneesFinanceDemo.revenus(vide: vide);
}

/// La vue globale de la direction en demonstration (FI-BR-12).
class FinanceDirectionDemo implements PortFinanceDirection {
  /// Cree le double.
  const FinanceDirectionDemo();

  @override
  Future<VueGlobaleFinance> vueGlobale() async =>
      DonneesFinanceDemo.vueGlobale();
}
