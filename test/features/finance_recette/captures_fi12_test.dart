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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart'
    show sessionActive, surchargesRouteur;
import '../../support/harnais.dart'
    show
        FausseSourceSession,
        FauxServicePlanning,
        FauxServicePriere,
        FauxServiceReseau;

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
  surchargesDemoTuteur(environnement: 'staging', finances: jeu),
  <Override>[
    horlogeFoyerProvider.overrideWithValue(() => _maintenant),
    _reseau(horsLigne),
    // L'acces lu par la fiche et par Compte > Acces (FI-9a).
    if (jeu != null)
      portAccesFoyerProvider.overrideWithValue(AccesFoyerFinanceDemo(jeu)),
    ...ajouts,
  ],
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
  portAccesFoyerProvider.overrideWithValue(AccesFoyerFinanceDemo(jeu)),
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
// Montage et capture.

Widget _application(
  BuildContext context, {
  required ThemeMode mode,
  required double echelle,
  GoRouter? routeur,
  Widget? page,
}) {
  Widget habiller(BuildContext contexte, Widget? app) => MediaQuery(
    data: MediaQuery.of(contexte)
        .copyWith(textScaler: TextScaler.linear(echelle)),
    child: app!,
  );
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
  debugPrint('PNG ${await capturer(tester, fichier)}');
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
}
