// FI-12 : captures de recette de toute la voie Finance (guide Finance V4
// §10 « Recette obligatoire par lot », §14 « Definition of done »).
//
// Chaque ecran Finance, depuis le VRAI routeur et les demonstrations
// (`surchargesDemoTuteur(finances: ...)`, `surchargesDemoAdmin`, la
// demonstration enseignant, `/demo/adulte`), dans ses etats principaux :
// contenu par jeu pertinent, vide, erreur, hors ligne et production
// indisponible (ports neutres). Grille : 390 et 1440, clair et sombre, puis
// 390 a texte 200 %.
//
// Les etats d'erreur et hors ligne remplacent un port de la demonstration
// par un double en echec (et `horsLigneProvider` a vrai pour le hors
// ligne) ; la production retire le port de demonstration. Aucun chiffre
// n'est calcule ici (FI6) : tout vient des doubles de demonstration.
//
// **Jamais execute sans `CAPTURE_DIR`** (`sautSansCapture`).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/capacites/port_mes_finances.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart'
    show RechargeFoyerPage;
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/chemins_tc_a.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart'
    show sessionActive, surchargesRouteur;
import '../../support/harnais.dart'
    show
        FausseSourceSession,
        FauxServicePlanning,
        FauxServicePriere,
        FauxServiceReseau;
import '../../teaching_core/a/support/hote_tc_a.dart'
    show surchargesDemonstration;

/// Le 4 octobre 2026 a midi, jour de reference de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 12);

/// Ou l'ecran est monte.
enum _Hote {
  /// Le vrai routeur (`routeurProvider`), puis `go(chemin)`.
  routeur,

  /// La route `/demo/adulte` (`routesDemoAdulte`).
  demoAdulte,

  /// La route `/demo/enseignant` (`routesDemoEnseignant`).
  demoEnseignant,

  /// La route `/demo/finance` (`routesDemoFinance`).
  demoFinance,

  /// L'ecran seul, sous `MaterialApp`.
  page,
}

/// Un cas : nom de fichier, hote, adresse ou page, surcharges.
typedef _Cas = ({
  String nom,
  _Hote hote,
  String chemin,
  List<Override> Function() surcharges,
  Widget Function()? page,
});

_Cas _route(String nom, String chemin, List<Override> Function() s) =>
    (nom: nom, hote: _Hote.routeur, chemin: chemin, surcharges: s, page: null);

_Cas _page(String nom, Widget Function() page, List<Override> Function() s) =>
    (nom: nom, hote: _Hote.page, chemin: '', surcharges: s, page: page);

/// Remplace dans [base] les fournisseurs que [ajouts] surcharge : Riverpod
/// refuse deux surcharges du meme fournisseur dans un conteneur.
List<Override> _remplacer(List<Override> base, List<Override> ajouts) {
  final Set<Object> cibles = <Object>{
    for (final Override o in ajouts) o.origin,
  };
  return <Override>[
    for (final Override o in base)
      if (!cibles.contains(o.origin)) o,
    ...ajouts,
  ];
}

Override _reseau(bool horsLigne) =>
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne));

// ---------------------------------------------------------------------------
// Doubles en echec ou fixes.

final Exception _echec = Exception('lecture refusee (capture FI-12)');

/// Les paiements du foyer, toutes lectures en echec.
class _PaiementsEnEchec extends PaiementsFoyerFinanceDemo {
  const _PaiementsEnEchec(super.jeu);

  @override
  Future<FinancesFoyer> finances() => Future<FinancesFoyer>.error(_echec);

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) =>
      Future<List<MouvementProfil>>.error(_echec);

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) =>
      Future<List<MouvementFoyer>>.error(_echec);
}

/// Les paiements du foyer, sans aucun profil rendu (le vide de la fiche).
class _PaiementsSansProfil extends PaiementsFoyerFinanceDemo {
  const _PaiementsSansProfil(super.jeu);

  @override
  Future<FinancesFoyer> finances() async => FinancesFoyer(
    synthese: DonneesFinanceDemo.finances(jeu).synthese,
    profils: const <FinancesProfil>[],
  );
}

/// La recharge, lectures en echec.
class _RechargeEnEchec extends RechargeFoyerFinanceDemo {
  const _RechargeEnEchec(super.jeu);

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() =>
      Future<List<BeneficiaireRecharge>>.error(_echec);

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Future<SuiviPaiement>.error(_echec);
}

/// La vue globale de la direction, en echec.
class _DirectionEnEchec implements PortFinanceDirection {
  const _DirectionEnEchec();

  @override
  Future<VueGlobaleFinance> vueGlobale() =>
      Future<VueGlobaleFinance>.error(_echec);
}

/// Un mois sans activite : les zeros restent (le vide de la vue globale).
class _DirectionSansActivite implements PortFinanceDirection {
  const _DirectionSansActivite();

  @override
  Future<VueGlobaleFinance> vueGlobale() async => VueGlobaleFinance(
    mois: DateTime(2026, 7),
    encaisse: const Montant(0, 'USD'),
    revenuAcademique: const Montant(0, 'USD'),
    paieEnseignants: const Montant(0, 'USD'),
    margeProjeteePourMille: null,
    impayes: const Montant(0, 'USD'),
    essaisEnCours: 0,
    soldesCrediteurs: const Montant(0, 'USD'),
  );
}

/// Les politiques commerciales, lectures en echec.
class _PolitiquesEnEchec extends PolitiquesCommercialesDemo {
  const _PolitiquesEnEchec();

  @override
  Future<PolitiqueCommerciale> active() =>
      Future<PolitiqueCommerciale>.error(_echec);

  @override
  Future<List<PolitiqueCommerciale>> versions() =>
      Future<List<PolitiqueCommerciale>>.error(_echec);
}

/// Les revenus de l'enseignant, en echec.
class _RevenusEnEchec implements PortRevenusEnseignant {
  const _RevenusEnEchec();

  @override
  Future<RevenusEnseignant> moisEnCours() =>
      Future<RevenusEnseignant>.error(_echec);
}

/// Les finances de l'adulte autonome, rendues par [lire].
class _MesFinancesFixes implements PortMesFinances {
  const _MesFinancesFixes(this.lire);

  final Future<FinancesProfil?> Function() lire;

  @override
  Future<FinancesProfil?> finances() => lire();

  @override
  Future<List<MouvementProfil>> mouvements() async {
    final FinancesProfil? p = await lire();
    return p == null
        ? const <MouvementProfil>[]
        : DonneesFinanceDemo.mouvementsAdulte(p);
  }
}

// ---------------------------------------------------------------------------
// Surcharges par role.

/// La demonstration tuteur sur le jeu [jeu] (nul : production, aucun port
/// Finance branche), avec [ajouts] par-dessus.
List<Override> _tuteur(
  JeuFoyerFinance? jeu, {
  List<Override> ajouts = const <Override>[],
  bool horsLigne = false,
}) => _remplacer(
  _remplacer(
    surchargesDemoTuteur(environnement: 'staging', finances: jeu),
    <Override>[
      horlogeFoyerProvider.overrideWithValue(() => _maintenant),
      _reseau(horsLigne),
      // L'acces lu par la fiche et par Compte > Acces (FI-9a).
      if (jeu != null)
        portAccesFoyerProvider.overrideWithValue(AccesFoyerFinanceDemo(jeu)),
    ],
  ),
  ajouts,
);

List<Override> _admin({
  List<Override> ajouts = const <Override>[],
  bool horsLigne = false,
}) => _remplacer(surchargesDemoAdmin(environnement: 'staging'), <Override>[
  _reseau(horsLigne),
  ...ajouts,
]);

List<Override> _enseignant(PortRevenusEnseignant? port) => <Override>[
  ...surchargesRouteur(FausseSourceSession(sessionActive(AppRole.teacher))),
  profilEnseignantProvider.overrideWith(
    (Ref _) async => DonneesEnseignantDemo.profil,
  ),
  if (port != null) portRevenusEnseignantProvider.overrideWithValue(port),
];

/// Le cours en direct de l'eleve [eleveId] (accueil de l'enfant).
Seance _coursEnDirect(String eleveId) => Seance(
  id: 's1',
  debut: _maintenant.subtract(const Duration(minutes: 10)),
  fin: _maintenant.add(const Duration(minutes: 50)),
  statut: StatutSeance.enCours,
  eleveId: eleveId,
  elevePrenom: 'Ibrahim',
  eleveIdentifiant: 'STUD-FI-000002',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
);

List<Override> _enfant(
  JeuFoyerFinance jeu, {
  bool horsLigne = false,
}) => <Override>[
  servicePlanningProvider.overrideWithValue(
    FauxServicePlanning()
      ..seancesRendues = <Seance>[_coursEnDirect(DonneesFinanceDemo.ibrahimId)],
  ),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
  // L'acces de l'enfant, borne a sa session (FI-BR-08, R4-02).
  portMonAccesProvider.overrideWithValue(
    MonAccesFinanceDemo(jeu, DonneesFinanceDemo.ibrahimId),
  ),
];

/// L'adulte autonome de la page seule.
final FinancesProfil _adulte = DonneesFinanceDemo.financesAdulte(
  profilId: 'adulte-autonome',
  prenom: 'Mamadou',
);

List<Override> _adultePage(PortMesFinances? port) => <Override>[
  _reseau(false),
  portPolitiquesCommercialesProvider.overrideWithValue(
    const PolitiquesCommercialesDemo(),
  ),
  if (port != null) portMesFinancesProvider.overrideWithValue(port),
];

Widget _mesFinances() => MesFinancesPage(
  onRetour: () {},
  onRecharger: (String _) {},
  onMouvements: () {},
);

// ---------------------------------------------------------------------------
// Les cas.

const JeuFoyerFinance _reg = JeuFoyerFinance.unARegulariser;
const JeuFoyerFinance _essai = JeuFoyerFinance.unEnEssai;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;
const String _aicha = DonneesFinanceDemo.aichaId;
const String _mariam = DonneesFinanceDemo.mariamId;

String _fiche(String id, String s) => Routes.ficheEleveSousPage(id, s);

String _resultat(EtatPaiement e) =>
    Routes.resultatRechargePour(DonneesFinanceDemo.commandeDemo(e));

final List<_Cas> _cas = <_Cas>[
  // Foyer du tuteur (FI-4, FI-5b).
  _route('foyer_a_regulariser', Routes.tuteurFoyer, () => _tuteur(_reg)),
  _route('foyer_essai', Routes.tuteurFoyer, () => _tuteur(_essai)),
  _route(
    'foyer_aucun_paiement',
    Routes.tuteurFoyer,
    () => _tuteur(JeuFoyerFinance.aucunPaiement),
  ),
  _route(
    'foyer_cinq_profils',
    Routes.tuteurFoyer,
    () => _tuteur(JeuFoyerFinance.cinqProfils),
  ),
  _route(
    'foyer_erreur',
    Routes.tuteurFoyer,
    () => _tuteur(
      _reg,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'foyer_hors_ligne',
    Routes.tuteurFoyer,
    () => _tuteur(
      _reg,
      horsLigne: true,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route('foyer_production', Routes.tuteurFoyer, () => _tuteur(null)),

  // Fiche > Finances (FI-6a).
  _route(
    'finances_a_regulariser',
    _fiche(_ibrahim, 'finances'),
    () => _tuteur(_reg),
  ),
  _route('finances_essai', _fiche(_aicha, 'finances'), () => _tuteur(_essai)),
  _route(
    'finances_vide',
    _fiche(_ibrahim, 'finances'),
    () => _tuteur(
      _reg,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsSansProfil(_reg),
        ),
      ],
    ),
  ),
  _route(
    'finances_erreur',
    _fiche(_ibrahim, 'finances'),
    () => _tuteur(
      _reg,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'finances_hors_ligne',
    _fiche(_ibrahim, 'finances'),
    () => _tuteur(
      _reg,
      horsLigne: true,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'finances_production',
    _fiche(DonneesDemo.aichaId, 'finances'),
    () => _tuteur(null),
  ),

  // Fiche > Mouvements (FI-6b).
  _route(
    'mouvements_a_regulariser',
    _fiche(_ibrahim, 'mouvements'),
    () => _tuteur(_reg),
  ),
  _route(
    'mouvements_vide',
    _fiche(_aicha, 'mouvements'),
    () => _tuteur(_essai),
  ),
  _route(
    'mouvements_erreur',
    _fiche(_ibrahim, 'mouvements'),
    () => _tuteur(
      _reg,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'mouvements_hors_ligne',
    _fiche(_ibrahim, 'mouvements'),
    () => _tuteur(
      _reg,
      horsLigne: true,
      ajouts: <Override>[
        portPaiementsFoyerProvider.overrideWithValue(
          const _PaiementsEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'mouvements_production',
    _fiche(DonneesDemo.aichaId, 'mouvements'),
    () => _tuteur(null),
  ),

  // Recharge (FI-7).
  _route(
    'recharge_etape1',
    Routes.rechargePour(<String>[_ibrahim]),
    () => _tuteur(_reg),
  ),
  _route(
    'recharge_etape2',
    Routes.rechargeReprise(<String, Montant>{
      _mariam: DonneesFinanceDemo.usd(10),
      _ibrahim: DonneesFinanceDemo.usd(40),
    }, verifier: true),
    () => _tuteur(_reg),
  ),
  _route(
    'recharge_erreur',
    Routes.tuteurFoyerRecharge,
    () => _tuteur(
      _reg,
      ajouts: <Override>[
        portRechargeFoyerProvider.overrideWithValue(
          const _RechargeEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'recharge_hors_ligne',
    Routes.tuteurFoyerRecharge,
    () => _tuteur(
      _reg,
      horsLigne: true,
      ajouts: <Override>[
        portRechargeFoyerProvider.overrideWithValue(
          const _RechargeEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'recharge_production',
    Routes.tuteurFoyerRecharge,
    () => _tuteur(null),
  ),

  // Resultat de la recharge (FI-8).
  _route(
    'resultat_termine',
    _resultat(EtatPaiement.termine),
    () => _tuteur(_reg),
  ),
  _route(
    'resultat_attente',
    _resultat(EtatPaiement.attenteConfirmation),
    () => _tuteur(_reg),
  ),
  _route('resultat_echec', _resultat(EtatPaiement.echec), () => _tuteur(_reg)),
  _route(
    'resultat_perime',
    _resultat(EtatPaiement.perime),
    () => _tuteur(_reg),
  ),
  _route(
    'resultat_vide',
    Routes.tuteurFoyerRechargeResultat,
    () => _tuteur(_reg),
  ),
  _route(
    'resultat_erreur',
    _resultat(EtatPaiement.termine),
    () => _tuteur(
      _reg,
      ajouts: <Override>[
        portRechargeFoyerProvider.overrideWithValue(
          const _RechargeEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'resultat_hors_ligne',
    _resultat(EtatPaiement.termine),
    () => _tuteur(
      _reg,
      horsLigne: true,
      ajouts: <Override>[
        portRechargeFoyerProvider.overrideWithValue(
          const _RechargeEnEchec(_reg),
        ),
      ],
    ),
  ),
  _route(
    'resultat_production',
    _resultat(EtatPaiement.termine),
    () => _tuteur(null),
  ),

  // Acces, essai et impaye (FI-9a) : tuteur, enfant.
  _route(
    'acces_fiche_a_regulariser',
    _fiche(_ibrahim, 'acces'),
    () => _tuteur(_reg),
  ),
  _route('acces_fiche_essai', _fiche(_aicha, 'acces'), () => _tuteur(_essai)),
  _route(
    'acces_compte_a_regulariser',
    Routes.compteTuteurSousPage('acces'),
    () => _tuteur(_reg),
  ),
  _route(
    'acces_compte_production',
    Routes.compteTuteurSousPage('acces'),
    () => _tuteur(null),
  ),
  _page(
    'acces_enfant_ferme',
    () => AccueilElevePage(horloge: () => _maintenant),
    () => _enfant(_reg),
  ),
  _page(
    'acces_enfant_ouvert',
    () => AccueilElevePage(horloge: () => _maintenant),
    () => _enfant(JeuFoyerFinance.tousFinances),
  ),
  _page(
    'acces_enfant_hors_ligne',
    () => AccueilElevePage(horloge: () => _maintenant),
    () => _enfant(_reg, horsLigne: true),
  ),

  // Mes finances de l'adulte autonome (FI-9b), dans /demo/adulte.
  for (final (String nom, EcranDemoAdulte ecran, bool coupe)
      in <(String, EcranDemoAdulte, bool)>[
        ('adulte_mon_espace', EcranDemoAdulte.monEspace, false),
        ('adulte_paiements', EcranDemoAdulte.paiements, false),
        ('adulte_mouvements', EcranDemoAdulte.mesMouvements, false),
        ('adulte_recharge', EcranDemoAdulte.maRecharge, false),
        ('adulte_hors_ligne', EcranDemoAdulte.paiements, true),
      ])
    (
      nom: nom,
      hote: _Hote.demoAdulte,
      chemin: adresseDemoAdulte(
        ecran,
        etat: EtatDemoAdulte.adulteSeul,
        reseauCoupe: coupe,
      ),
      surcharges: () => const <Override>[],
      page: null,
    ),
  // Adulte autonome a regulariser (variante ajoutee par FI-12 passe 2).
  for (final (String nom, EcranDemoAdulte ecran) in <(String, EcranDemoAdulte)>[
    ('adulte_a_regulariser_paiements', EcranDemoAdulte.paiements),
    ('adulte_a_regulariser_recharge', EcranDemoAdulte.maRecharge),
  ])
    (
      nom: nom,
      hote: _Hote.demoAdulte,
      chemin: adresseDemoAdulte(
        ecran,
        etat: EtatDemoAdulte.adulteSeul,
        financeARegulariser: true,
      ),
      surcharges: () => const <Override>[],
      page: null,
    ),
  _page(
    'adulte_erreur',
    _mesFinances,
    () => _adultePage(
      _MesFinancesFixes(() => Future<FinancesProfil?>.error(_echec)),
    ),
  ),
  _page(
    'adulte_vide',
    _mesFinances,
    () => _adultePage(const _MesFinancesFixes(Future<FinancesProfil?>.value)),
  ),
  _page('adulte_production', _mesFinances, () => _adultePage(null)),
  _page(
    'adulte_contenu_page',
    _mesFinances,
    () => _adultePage(
      _MesFinancesFixes(() => Future<FinancesProfil?>.value(_adulte)),
    ),
  ),

  // Revenus de l'enseignant (FI-10) : demonstration, puis vrai routeur.
  for (final (String nom, EtatDemoEnseignant etat)
      in <(String, EtatDemoEnseignant)>[
        ('revenus_contenu', EtatDemoEnseignant.nominal),
        ('revenus_vide', EtatDemoEnseignant.vide),
        ('revenus_hors_ligne', EtatDemoEnseignant.horsLigne),
      ])
    (
      nom: nom,
      hote: _Hote.demoEnseignant,
      chemin: adresseDemoEnseignant(EcranDemoEnseignant.revenus, etat: etat),
      surcharges: () => const <Override>[],
      page: null,
    ),
  _route(
    'revenus_erreur',
    Routes.enseignantRevenus,
    () => _enseignant(const _RevenusEnEchec()),
  ),
  _route(
    'revenus_production',
    Routes.enseignantRevenus,
    () => _enseignant(null),
  ),

  // Admin Finance : vue globale (FI-11a) et politiques (FI-11b, FI-11c).
  _route('admin_vue_globale', Routes.adminFinance, _admin),
  _route(
    'admin_vue_globale_vide',
    Routes.adminFinance,
    () => _admin(
      ajouts: <Override>[
        portFinanceDirectionProvider.overrideWithValue(
          const _DirectionSansActivite(),
        ),
      ],
    ),
  ),
  _route(
    'admin_vue_globale_erreur',
    Routes.adminFinance,
    () => _admin(
      ajouts: <Override>[
        portFinanceDirectionProvider.overrideWithValue(
          const _DirectionEnEchec(),
        ),
      ],
    ),
  ),
  _route(
    'admin_vue_globale_hors_ligne',
    Routes.adminFinance,
    () => _admin(
      horsLigne: true,
      ajouts: <Override>[
        portFinanceDirectionProvider.overrideWithValue(
          const _DirectionEnEchec(),
        ),
      ],
    ),
  ),
  _route(
    'admin_vue_globale_production',
    Routes.adminFinance,
    () => _admin(
      ajouts: <Override>[
        portFinanceDirectionProvider.overrideWithValue(
          const FinanceDirectionIndisponible(),
        ),
      ],
    ),
  ),
  _route('admin_politiques', Routes.adminFinancePolitiques, _admin),
  _route(
    'admin_politiques_erreur',
    Routes.adminFinancePolitiques,
    () => _admin(
      ajouts: <Override>[
        portPolitiquesCommercialesProvider.overrideWithValue(
          const _PolitiquesEnEchec(),
        ),
      ],
    ),
  ),
  _route(
    'admin_politiques_hors_ligne',
    Routes.adminFinancePolitiques,
    () => _admin(
      horsLigne: true,
      ajouts: <Override>[
        portPolitiquesCommercialesProvider.overrideWithValue(
          const _PolitiquesEnEchec(),
        ),
      ],
    ),
  ),
  _route(
    'admin_politiques_production',
    Routes.adminFinancePolitiques,
    () => _admin(
      ajouts: <Override>[
        portPolitiquesCommercialesProvider.overrideWithValue(
          const PolitiquesCommercialesIndisponibles(),
        ),
      ],
    ),
  ),
];

// ---------------------------------------------------------------------------
// Passe 2 (critique FI-12) : chargement, etats manquants, ecrans absents,
// tablette, 1440 x 900, droite-a-gauche, planches maquette | capture.

/// Une lecture qui n'aboutit jamais : l'ecran reste sur son squelette.
Future<T> _jamais<T>() => Completer<T>().future;

/// Les paiements du foyer, lectures en cours sans fin (chargement).
class _PaiementsEnCours extends PaiementsFoyerFinanceDemo {
  const _PaiementsEnCours(super.jeu);

  @override
  Future<FinancesFoyer> finances() => _jamais<FinancesFoyer>();

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) =>
      _jamais<List<MouvementProfil>>();

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) =>
      _jamais<List<MouvementFoyer>>();
}

/// La recharge, lectures en cours sans fin.
class _RechargeEnCours extends RechargeFoyerFinanceDemo {
  const _RechargeEnCours(super.jeu);

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() =>
      _jamais<List<BeneficiaireRecharge>>();

  @override
  Future<SuiviPaiement> suivre(String commandeId) => _jamais<SuiviPaiement>();
}

/// La vue globale, en cours sans fin.
class _DirectionEnCours implements PortFinanceDirection {
  const _DirectionEnCours();

  @override
  Future<VueGlobaleFinance> vueGlobale() => _jamais<VueGlobaleFinance>();
}

/// Les politiques, lectures en cours sans fin.
class _PolitiquesEnCours extends PolitiquesCommercialesDemo {
  const _PolitiquesEnCours();

  @override
  Future<PolitiqueCommerciale> active() => _jamais<PolitiqueCommerciale>();

  @override
  Future<List<PolitiqueCommerciale>> versions() =>
      _jamais<List<PolitiqueCommerciale>>();
}

/// L'acces du foyer en echec (Fiche > Acces).
class _AccesEnEchec implements PortAccesFoyer {
  const _AccesEnEchec();

  @override
  Future<List<AccesBeneficiaire>> acces() =>
      Future<List<AccesBeneficiaire>>.error(_echec);
}

/// Le profil, la finance et l'acces du foyer, tous en echec.
List<Override> _toutEnEchec() => <Override>[
  elevesDuFoyerProvider.overrideWith(
    (Ref _) => Future<List<EleveDuFoyer>>.error(_echec),
  ),
  portPaiementsFoyerProvider.overrideWithValue(const _PaiementsEnEchec(_reg)),
  portAccesFoyerProvider.overrideWithValue(const _AccesEnEchec()),
];

/// L'acces de l'eleve connecte ([sessionActive] : `p-student`), borne a sa
/// session (FI-BR-08).
class _AccesEleve implements PortMonAcces {
  const _AccesEleve({required this.ouvert});

  final bool ouvert;

  @override
  Future<AccesBeneficiaire?> monAcces() async => AccesBeneficiaire(
    eleveId: 'p-${AppRole.student.valeurSql}',
    prenom: 'Ibrahim',
    etatAffiche: EtatAccesAffiche.sansEcheance,
    seancesPayantesOuvertes: ouvert,
    essaisUtilises: ouvert ? null : 2,
    essaisMax: ouvert ? null : 2,
  );
}

/// L'enfant sur le VRAI routeur, session eleve en mode enfant, groupes de
/// la demonstration, acces [ouvert] ou non.
List<Override> _enfantRouteur({required bool ouvert}) => _remplacer(
  surchargesRouteur(
    FausseSourceSession(
      sessionActive(AppRole.student, mode: InterfaceMode.enfant),
    ),
  ),
  <Override>[
    ...surchargesDemonstration(maintenant: _maintenant),
    _reseau(false),
    portMonAccesProvider.overrideWithValue(_AccesEleve(ouvert: ouvert)),
  ],
);

/// Une variante de la grille : suffixe, taille, theme, echelle, sens.
typedef _Variante = ({
  String suffixe,
  Size taille,
  ThemeMode mode,
  double echelle,
  TextDirection? sens,
});

_Variante _v(
  String suffixe,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  TextDirection? sens,
}) => (
  suffixe: suffixe,
  taille: taille,
  mode: mode,
  echelle: echelle,
  sens: sens,
);

final _Variante _m = _v('390_light', const Size(390, 1400));
final _Variante _mSombre = _v(
  '390_dark',
  const Size(390, 1400),
  mode: ThemeMode.dark,
);
final _Variante _t = _v('768_light', const Size(768, 1024));
final _Variante _tSombre = _v(
  '768_dark',
  const Size(768, 1024),
  mode: ThemeMode.dark,
);
// Le guide §10 : 1440 x 900, le premier ecran tel qu'il s'ouvre.
final _Variante _b = _v('1440x900_light', const Size(1440, 900));
final _Variante _bSombre = _v(
  '1440x900_dark',
  const Size(1440, 900),
  mode: ThemeMode.dark,
);
final _Variante _rtl = _v(
  '390_light_rtl',
  const Size(390, 1400),
  sens: TextDirection.rtl,
);
final _Variante _x2 = _v('390_light_200pc', const Size(390, 2400), echelle: 2);

/// La grille d'un etat ajoute : 390 clair et sombre, 1440 x 900.
final List<_Variante> _etat = <_Variante>[_m, _mSombre, _b];

/// La grille des formats d'un ecran deja capture en 390 et 1440 x 1400.
final List<_Variante> _formats = <_Variante>[_t, _tSombre, _b, _bSombre, _rtl];

/// Un complement : le cas, sa grille, l'action avant la capture, la
/// verification faite sur l'ecran rendu.
typedef _Complement = ({
  _Cas cas,
  List<_Variante> grille,
  Future<void> Function(WidgetTester tester)? apres,
  void Function(WidgetTester tester)? verifier,
});

_Complement _c(
  _Cas cas,
  List<_Variante> grille, {
  Future<void> Function(WidgetTester tester)? apres,
  void Function(WidgetTester tester)? verifier,
}) => (cas: cas, grille: grille, apres: apres, verifier: verifier);

Finder _cleCommencant(String prefixe) => find.byWidgetPredicate(
  (Widget w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefixe),
);

Finder _icone(AppIcon icone) => find.byWidgetPredicate(
  (Widget w) => w is Icon && (w.icon == icone.repos || w.icon == icone.actif),
);

/// Amene [cible] dans la vue, sans exiger la fin des animations.
Future<void> _montrer(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible.first);
  await stabiliser(tester);
}

/// Saisit [valeur] dans le champ [id] des politiques.
Future<void> _saisir(WidgetTester tester, String id, String valeur) async {
  final Finder champ = find.descendant(
    of: find.byKey(PolitiquesCommercialesContenu.champKey(id)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(champ);
  await tester.enterText(champ, valeur);
  await tester.pump();
}

// Les refus de la revue (UX_REVIEW_08_FINANCE.md:315), verifies sur
// l'ecran rendu au moment de la capture.

/// Foyer : « Recharger plusieurs profils » une seule fois, aucun
/// « Gerer tous les enfants », aucun « Actions rapides », aucune croix.
void _refusFoyer(WidgetTester tester) {
  expect(find.byKey(SyntheseSoldesFoyer.rechargerKey), findsOneWidget);
  expect(find.text(t.foyer.finances.rechargerPlusieurs), findsOneWidget);
  expect(find.textContaining('Gérer tous'), findsNothing);
  expect(find.textContaining('Actions rapides'), findsNothing);
  expect(find.textContaining('+ Recharger'), findsNothing);
  // Mesure, sans jugement : le chevron des cartes (refuse par la revue,
  // ecart FI12-E01 du rapport).
  debugPrint(
    'CHEVRON ${find.descendant(of: find.byType(CarteMembre), matching: _icone(AppIcons.chevron)).evaluate().length}',
  );
}

/// Recharge : pas de « Recharger plusieurs profils », pas de
/// « Paiement securise et chiffre », pas de croix.
void _refusRecharge(WidgetTester tester) {
  expect(find.text(t.foyer.finances.rechargerPlusieurs), findsNothing);
  expect(find.textContaining('chiffré'), findsNothing);
  expect(_icone(AppIcons.fermer), findsNothing);
}

/// Fiche > Finances : le bandeau d'acces sans croix.
void _refusBandeau(WidgetTester tester) {
  expect(find.byKey(FinancesElevePage.bandeauKey), findsOneWidget);
  expect(_icone(AppIcons.fermer), findsNothing);
}

/// Politiques : ni menu « ... », ni selecteur de mois.
void _refusPolitiques(WidgetTester tester) {
  expect(find.byType(PopupMenuButton<Object?>), findsNothing);
  expect(
    find.byWidgetPredicate((Widget w) => w is PopupMenuButton),
    findsNothing,
  );
  expect(
    find.byWidgetPredicate((Widget w) => w is DropdownButton),
    findsNothing,
  );
  expect(find.byType(CalendarDatePicker), findsNothing);
}

/// Vue globale et Revenus : aucune fleche « vs mois precedent ».
void _refusVariation(WidgetTester tester) {
  expect(find.textContaining('précédent'), findsNothing);
  expect(find.textContaining('vs '), findsNothing);
}

/// Les montants ne s'affichent jamais a l'enfant : aucun « $ ».
void _enfantSansArgent(WidgetTester tester) {
  expect(find.textContaining(r'$'), findsNothing);
  expect(find.textContaining('régulariser'), findsNothing);
}

final List<_Complement> _complements = <_Complement>[
  // Chargement (squelette) : la lecture n'aboutit jamais.
  _c(
    _route(
      'foyer_chargement',
      Routes.tuteurFoyer,
      () => _tuteur(
        _reg,
        ajouts: <Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            const _PaiementsEnCours(_reg),
          ),
        ],
      ),
    ),
    _etat,
  ),
  _c(
    _route(
      'finances_chargement',
      _fiche(_ibrahim, 'finances'),
      () => _tuteur(
        _reg,
        ajouts: <Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            const _PaiementsEnCours(_reg),
          ),
        ],
      ),
    ),
    _etat,
  ),
  _c(
    _route(
      'mouvements_chargement',
      _fiche(_ibrahim, 'mouvements'),
      () => _tuteur(
        _reg,
        ajouts: <Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            const _PaiementsEnCours(_reg),
          ),
        ],
      ),
    ),
    _etat,
  ),
  _c(
    _route(
      'recharge_chargement',
      Routes.tuteurFoyerRecharge,
      () => _tuteur(
        _reg,
        ajouts: <Override>[
          portRechargeFoyerProvider.overrideWithValue(
            const _RechargeEnCours(_reg),
          ),
        ],
      ),
    ),
    _etat,
  ),
  _c(
    _route(
      'resultat_chargement',
      _resultat(EtatPaiement.termine),
      () => _tuteur(
        _reg,
        ajouts: <Override>[
          portRechargeFoyerProvider.overrideWithValue(
            const _RechargeEnCours(_reg),
          ),
        ],
      ),
    ),
    _etat,
  ),
  _c(
    _route(
      'admin_vue_globale_chargement',
      Routes.adminFinance,
      () => _admin(
        ajouts: <Override>[
          portFinanceDirectionProvider.overrideWithValue(
            const _DirectionEnCours(),
          ),
        ],
      ),
    ),
    _etat,
  ),
  _c(
    _route(
      'admin_politiques_chargement',
      Routes.adminFinancePolitiques,
      () => _admin(
        ajouts: <Override>[
          portPolitiquesCommercialesProvider.overrideWithValue(
            const _PolitiquesEnCours(),
          ),
        ],
      ),
    ),
    _etat,
  ),

  // Resultat : les quatre etats qui manquaient (8 sur 8 avec la passe 1).
  for (final (String nom, EtatPaiement e) in <(String, EtatPaiement)>[
    ('resultat_preparation', EtatPaiement.preparation),
    ('resultat_confirme', EtatPaiement.confirme),
    ('resultat_allocation', EtatPaiement.allocationEnCours),
    ('resultat_annule', EtatPaiement.annule),
  ])
    _c(_route(nom, _resultat(e), () => _tuteur(_reg)), <_Variante>[
      ..._etat,
      _x2,
    ]),

  // Compte > Paiements : tuteur, production, titulaire adulte, second
  // adulte (historique seul, jamais de solde ni de recharge).
  _c(
    _route(
      'compte_paiements_tuteur',
      Routes.compteTuteurSousPage('paiements'),
      () => _tuteur(_reg),
    ),
    <_Variante>[..._etat, _x2],
  ),
  _c(
    _route(
      'compte_paiements_production',
      Routes.compteTuteurSousPage('paiements'),
      () => _tuteur(null),
    ),
    _etat,
  ),
  _c((
    nom: 'compte_paiements_titulaire_adulte',
    hote: _Hote.demoAdulte,
    chemin: adresseDemoAdulte(EcranDemoAdulte.paiementsFoyer),
    surcharges: () => const <Override>[],
    page: null,
  ), _etat),
  _c(
    (
      nom: 'compte_paiements_second_adulte',
      hote: _Hote.demoAdulte,
      chemin: adresseDemoAdulte(
        EcranDemoAdulte.paiementsFoyer,
        vue: VueDemoAdulte.secondAdulte,
      ),
      surcharges: () => const <Override>[],
      page: null,
    ),
    <_Variante>[..._etat, _x2],
    verifier: (WidgetTester tester) {
      expect(find.byType(PaiementsComptePage), findsOneWidget);
      expect(find.byKey(PaiementsComptePage.rechargerKey), findsNothing);
      expect(find.text(t.adulte.paiements.recharger), findsNothing);
    },
  ),
  // §10 « interdit » : la recharge demandee par le second adulte n'existe
  // pas pour lui, l'adresse ne l'ouvre jamais.
  _c(
    (
      nom: 'interdit_recharge_second_adulte',
      hote: _Hote.demoAdulte,
      chemin: adresseDemoAdulte(
        EcranDemoAdulte.recharge,
        vue: VueDemoAdulte.secondAdulte,
      ),
      surcharges: () => const <Override>[],
      page: null,
    ),
    _etat,
    verifier: (WidgetTester tester) =>
        expect(find.byType(RechargeFoyerPage), findsNothing),
  ),
  // §10 « interdit » : le tuteur qui tape l'adresse de la Finance de la
  // direction reste dans son espace.
  _c(
    _route(
      'interdit_tuteur_admin_finance',
      Routes.adminFinance,
      () => _tuteur(_reg),
    ),
    _etat,
    verifier: (WidgetTester tester) =>
        expect(find.byType(VueGlobaleFinanceBloc), findsNothing),
  ),
  // §10 « incomplet » : recharge sans profil coche, le bouton dit pourquoi.
  _c(
    _route('incomplet_recharge_rien_coche', Routes.tuteurFoyerRecharge, () {
      return _tuteur(_reg);
    }),
    <_Variante>[..._etat, _x2],
    verifier: _refusRecharge,
  ),

  // Le recu ouvert depuis Mouvements.
  _c(
    _route(
      'mouvements_recu',
      _fiche(_ibrahim, 'mouvements'),
      () => _tuteur(_reg),
    ),
    <_Variante>[..._etat, _x2],
    apres: (WidgetTester tester) async {
      final Finder voir = _cleCommencant('ficheEleve.mouvements.recu.');
      await _montrer(tester, voir);
      await tester.tap(voir.first);
    },
  ),

  // Politiques : erreurs de coherence (§10 « incomplet »), comparaison
  // avec la version active, historique, Publier.
  _c(
    _route('admin_politiques_coherence', Routes.adminFinancePolitiques, _admin),
    _etat,
    apres: (WidgetTester tester) async {
      await _saisir(tester, 'plafondHoraire', '3');
      await _saisir(tester, 'remise-3', '51');
      await _montrer(
        tester,
        find.byKey(PolitiquesCommercialesContenu.champKey('plafondHoraire')),
      );
    },
    verifier: (WidgetTester tester) {
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(
                  PolitiquesCommercialesContenu.champKey('plafondHoraire'),
                ),
                matching: find.byType(TextField),
              ),
            )
            .decoration!
            .errorText,
        isNotNull,
      );
    },
  ),
  _c(
    _route(
      'admin_politiques_comparaison',
      Routes.adminFinancePolitiques,
      _admin,
    ),
    _etat,
    apres: (WidgetTester tester) async {
      await _saisir(tester, 'tarifAdulte', '65');
      await _montrer(tester, _cleCommencant('fi-pol-cmp-'));
    },
    verifier: (WidgetTester tester) =>
        expect(_cleCommencant('fi-pol-cmp-'), findsWidgets),
  ),
  _c(
    _route(
      'admin_politiques_historique',
      Routes.adminFinancePolitiques,
      _admin,
    ),
    _etat,
    apres: (WidgetTester tester) => _montrer(
      tester,
      find.byKey(PolitiquesCommercialesContenu.historiqueKey),
    ),
    verifier: (WidgetTester tester) {
      expect(_cleCommencant('fi-pol-histo-'), findsWidgets);
      _refusPolitiques(tester);
    },
  ),
  _c(
    _route('admin_politiques_publier', Routes.adminFinancePolitiques, _admin),
    _etat,
    apres: (WidgetTester tester) async {
      final Finder bouton = find.text(t.admin.finance.pol.publier);
      await _montrer(tester, bouton);
      await tester.tap(bouton.first);
      await stabiliser(tester);
      await _montrer(
        tester,
        find.byKey(PolitiquesCommercialesContenu.publicationKey),
      );
    },
  ),

  // Fiche > Acces : la page lit d'abord le profil (`PageFiche`), puis la
  // finance et l'acces en complement. Erreur et hors ligne : le profil ne se
  // lit pas ; « finance en echec » : le profil se lit, la finance et l'acces
  // non (ce que la page en dit).
  _c(
    _route(
      'acces_fiche_erreur',
      _fiche(_ibrahim, 'acces'),
      () => _tuteur(_reg, ajouts: _toutEnEchec()),
    ),
    _etat,
  ),
  _c(
    _route(
      'acces_fiche_hors_ligne',
      _fiche(_ibrahim, 'acces'),
      () => _tuteur(_reg, horsLigne: true, ajouts: _toutEnEchec()),
    ),
    _etat,
  ),
  _c(
    _route(
      'acces_fiche_finance_en_echec',
      _fiche(_ibrahim, 'acces'),
      () => _tuteur(
        _reg,
        ajouts: <Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            const _PaiementsEnEchec(_reg),
          ),
          portAccesFoyerProvider.overrideWithValue(const _AccesEnEchec()),
        ],
      ),
    ),
    _etat,
  ),

  // L'enfant dans Mes groupes, depuis le vrai routeur.
  _c(
    _route(
      'acces_enfant_groupes_ferme',
      CheminsTcA.mesGroupes,
      () => _enfantRouteur(ouvert: false),
    ),
    <_Variante>[..._etat, _x2, _rtl],
    verifier: _enfantSansArgent,
  ),
  _c(
    _route(
      'acces_enfant_groupes_ouvert',
      CheminsTcA.mesGroupes,
      () => _enfantRouteur(ouvert: true),
    ),
    _etat,
    verifier: _enfantSansArgent,
  ),

  // /demo/finance, la page de demonstration de la direction.
  for (final OngletFinance o in OngletFinance.values)
    _c(
      (
        nom: 'demo_finance_${o.name}',
        hote: _Hote.demoFinance,
        chemin: adresseDemoFinance(o),
        surcharges: () => const <Override>[],
        page: null,
      ),
      <_Variante>[..._etat, _t, _rtl],
    ),

  // Tablette 768, 1440 x 900 et droite-a-gauche des ecrans principaux.
  _c(
    _route('foyer_a_regulariser', Routes.tuteurFoyer, () => _tuteur(_reg)),
    _formats,
    verifier: _refusFoyer,
  ),
  _c(
    _route(
      'finances_a_regulariser',
      _fiche(_ibrahim, 'finances'),
      () => _tuteur(_reg),
    ),
    _formats,
    verifier: _refusBandeau,
  ),
  _c(
    _route(
      'mouvements_a_regulariser',
      _fiche(_ibrahim, 'mouvements'),
      () => _tuteur(_reg),
    ),
    <_Variante>[_t, _b, _rtl],
  ),
  _c(
    _route(
      'recharge_etape1',
      Routes.rechargePour(<String>[_ibrahim]),
      () => _tuteur(_reg),
    ),
    _formats,
    verifier: _refusRecharge,
  ),
  _c(
    _route(
      'recharge_etape2',
      Routes.rechargeReprise(<String, Montant>{
        _mariam: DonneesFinanceDemo.usd(10),
        _ibrahim: DonneesFinanceDemo.usd(40),
      }, verifier: true),
      () => _tuteur(_reg),
    ),
    <_Variante>[_t, _b, _rtl],
    verifier: _refusRecharge,
  ),
  _c(
    _route(
      'resultat_termine',
      _resultat(EtatPaiement.termine),
      () => _tuteur(_reg),
    ),
    <_Variante>[_t, _b, _rtl],
  ),
  _c(
    (
      nom: 'adulte_paiements',
      hote: _Hote.demoAdulte,
      chemin: adresseDemoAdulte(
        EcranDemoAdulte.paiements,
        etat: EtatDemoAdulte.adulteSeul,
      ),
      surcharges: () => const <Override>[],
      page: null,
    ),
    <_Variante>[_t, _b, _rtl],
  ),
  _c(
    (
      nom: 'revenus_contenu',
      hote: _Hote.demoEnseignant,
      chemin: adresseDemoEnseignant(EcranDemoEnseignant.revenus),
      surcharges: () => const <Override>[],
      page: null,
    ),
    <_Variante>[_t, _b, _rtl],
    verifier: _refusVariation,
  ),
  _c(
    _route('admin_vue_globale', Routes.adminFinance, _admin),
    _formats,
    verifier: _refusVariation,
  ),
  _c(
    _route('admin_politiques', Routes.adminFinancePolitiques, _admin),
    <_Variante>[_t, _b, _rtl],
    verifier: _refusPolitiques,
  ),
];

/// Les planches maquette | capture (guide §11.2) : la maquette du
/// directeur a gauche, la vraie page a droite, a la meme taille. Les
/// maquettes sont lues dans `MAQUETTES_DIR` (`17_finance/V/` du pilotage) ;
/// sans ce dossier, les planches sont sautees.
typedef _Planche = ({String maquette, _Cas cas, bool mobile, ThemeMode mode});

final List<_Planche> _planches = <_Planche>[
  (
    maquette: '01_mobile_sombre_paiement_confirme.png',
    cas: _route(
      'planche_01_resultat',
      _resultat(EtatPaiement.termine),
      () => _tuteur(_reg),
    ),
    mobile: true,
    mode: ThemeMode.dark,
  ),
  (
    maquette: '02_mobile_sombre_mariam_finances.png',
    cas: _route(
      'planche_02_finances',
      _fiche(_mariam, 'finances'),
      () => _tuteur(_reg),
    ),
    mobile: true,
    mode: ThemeMode.dark,
  ),
  (
    maquette: '03_mobile_sombre_foyer_soldes.png',
    cas: _route('planche_03_foyer', Routes.tuteurFoyer, () => _tuteur(_reg)),
    mobile: true,
    mode: ThemeMode.dark,
  ),
  (
    maquette: '04_mobile_sombre_recharge.png',
    cas: _route(
      'planche_04_recharge',
      Routes.rechargeReprise(<String, Montant>{
        _mariam: DonneesFinanceDemo.usd(10),
        _ibrahim: DonneesFinanceDemo.usd(40),
      }),
      () => _tuteur(_reg),
    ),
    mobile: true,
    mode: ThemeMode.dark,
  ),
  (
    maquette: '05_bureau_clair_foyer_soldes.png',
    cas: _route('planche_05_foyer', Routes.tuteurFoyer, () => _tuteur(_reg)),
    mobile: false,
    mode: ThemeMode.light,
  ),
  (
    maquette: '06_bureau_clair_mariam_finances.png',
    cas: _route(
      'planche_06_finances',
      _fiche(_mariam, 'finances'),
      () => _tuteur(_reg),
    ),
    mobile: false,
    mode: ThemeMode.light,
  ),
  (
    maquette: '07_bureau_clair_paiement_du_foyer.png',
    cas: _route(
      'planche_07_recharge',
      Routes.rechargeReprise(<String, Montant>{
        _mariam: DonneesFinanceDemo.usd(10),
        _ibrahim: DonneesFinanceDemo.usd(40),
      }),
      () => _tuteur(_reg),
    ),
    mobile: false,
    mode: ThemeMode.light,
  ),
  (
    maquette: '08_bureau_clair_enseignant_revenus.png',
    cas: (
      nom: 'planche_08_revenus',
      hote: _Hote.demoEnseignant,
      chemin: adresseDemoEnseignant(EcranDemoEnseignant.revenus),
      surcharges: () => const <Override>[],
      page: null,
    ),
    mobile: false,
    mode: ThemeMode.light,
  ),
  (
    maquette: '09_bureau_clair_finance_vue_globale.png',
    cas: _route('planche_09_vue_globale', Routes.adminFinance, _admin),
    mobile: false,
    mode: ThemeMode.light,
  ),
  (
    maquette: '10_bureau_clair_politiques_commerciales.png',
    cas: _route('planche_10_politiques', Routes.adminFinancePolitiques, _admin),
    mobile: false,
    mode: ThemeMode.light,
  ),
];

/// Le dossier des maquettes, ou `null`.
final String? _dossierMaquettes = () {
  final String? brut = Platform.environment['MAQUETTES_DIR'];
  return brut == null || brut.trim().isEmpty ? null : brut;
}();

// ---------------------------------------------------------------------------
// Montage et capture.

Widget _application(
  BuildContext context, {
  required ThemeMode mode,
  required double echelle,
  TextDirection? sens,
  GoRouter? routeur,
  Widget? page,
}) {
  Widget habiller(BuildContext contexte, Widget? app) {
    final Widget avecTexte = MediaQuery(
      data: MediaQuery.of(contexte)
          .copyWith(textScaler: TextScaler.linear(echelle)),
      child: app!,
    );
    // Le sens droite-a-gauche force, comme `captures_fi_test.dart`.
    return sens == null
        ? avecTexte
        : Directionality(textDirection: sens, child: avecTexte);
  }

  final ThemeData clair = AppTheme.pour(
    InterfaceMode.standard,
    Brightness.light,
  );
  final ThemeData sombre = AppTheme.pour(
    InterfaceMode.standard,
    Brightness.dark,
  );
  final Locale langue = TranslationProvider.of(context).flutterLocale;
  if (routeur != null) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: clair,
      darkTheme: sombre,
      themeMode: mode,
      locale: langue,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: routeur,
      builder: habiller,
    );
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: clair,
    darkTheme: sombre,
    themeMode: mode,
    locale: langue,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: habiller,
    home: page,
  );
}

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  _Cas cas,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  TextDirection? sens,
  Future<void> Function(WidgetTester tester)? apres,
  void Function(WidgetTester tester)? verifier,
  String? maquette,
}) async {
  fixerVueCapture(tester, taille, 1);
  GoRouter? routeur;
  final GoRouter? demo = switch (cas.hote) {
    _Hote.demoAdulte => GoRouter(
      initialLocation: cas.chemin,
      routes: routesDemoAdulte('staging'),
    ),
    _Hote.demoEnseignant => GoRouter(
      initialLocation: cas.chemin,
      routes: routesDemoEnseignant('staging'),
    ),
    _Hote.demoFinance => GoRouter(
      initialLocation: cas.chemin,
      routes: routesDemoFinance('staging'),
    ),
    _ => null,
  };
  if (demo != null) addTearDown(demo.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: cas.surcharges(),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              if (cas.hote == _Hote.routeur) {
                routeur = ref.read(routeurProvider);
              }
              return _application(
                context,
                mode: mode,
                echelle: echelle,
                sens: sens,
                routeur: routeur ?? demo,
                page: cas.page?.call(),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (cas.hote == _Hote.routeur) {
    routeur!.go(cas.chemin);
    await stabiliser(tester);
  }
  if (apres != null) {
    await apres(tester);
    await stabiliser(tester);
  }
  verifier?.call(tester);
  expect(tester.takeException(), isNull, reason: fichier);
  final String png = maquette == null
      ? await capturer(tester, fichier)
      : await capturerEtComparer(tester, fichier, maquette);
  debugPrint('PNG $png');
  // Demonte avant la fin : aucune minuterie ne reste en suspens.
  await tester.pumpWidget(const SizedBox());
}

void main() {
  group('Capture : FI-12 recette Finance', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Cas cas in _cas) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 1400)),
        ('1440', const Size(1440, 1400)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'fi12_${cas.nom}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(tester, fichier, cas, taille, mode: mode);
          });
        }
      }
      final String agrandi = 'fi12_${cas.nom}_390_light_200pc';
      testWidgets(agrandi, (WidgetTester tester) async {
        await _capturer(
          tester,
          agrandi,
          cas,
          const Size(390, 2400),
          echelle: 2,
        );
      });
    }
  });

  group('Capture : FI-12 passe 2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Complement c in _complements) {
      for (final _Variante v in c.grille) {
        final String fichier = 'fi12_${c.cas.nom}_${v.suffixe}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            c.cas,
            v.taille,
            mode: v.mode,
            echelle: v.echelle,
            sens: v.sens,
            apres: c.apres,
            verifier: c.verifier,
          );
        });
      }
    }
  });

  group(
    'Capture : FI-12 planches maquette | capture',
    skip: sautSansCapture == false && _dossierMaquettes != null
        ? false
        : 'CAPTURE_DIR ou MAQUETTES_DIR absent : planches sautees',
    () {
      setUpAll(chargerPolicesDuDepot);

      for (final _Planche p in _planches) {
        final String fichier = 'fi12_${p.cas.nom}';
        testWidgets(fichier, (WidgetTester tester) async {
          // Maquettes de 941 x 1672 (telephone) et 1672 x 941 (bureau) :
          // la largeur logique fixe la hauteur, sans deformation.
          final Size taille = p.mobile
              ? const Size(390, 390 * 1672 / 941)
              : const Size(1440, 1440 * 941 / 1672);
          await _capturer(
            tester,
            fichier,
            p.cas,
            taille,
            mode: p.mode,
            maquette: '$_dossierMaquettes/${p.maquette}',
          );
        });
      }
    },
  );
}
