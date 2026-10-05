// ENS-PAYS-1 : les ecrans ou un enseignant se presente a un autre role,
// montes avec des donnees ou l'enseignant a declare son pays. Partages par le
// test fonctionnel et par les captures.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_attribution.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/admin_attribution/attribution_page.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart'
    as admin;
import 'package:rewayah_academy/features/classe_tuteur/catalogue_classes_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_seance_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import '../../capture/outil_capture.dart' show cadreCapture, stabiliser;
import '../../support/harnais.dart';
import '../../teaching_core/a/support/hote_tc_a.dart'
    show surchargesDemonstration;
import '../../teaching_core/e/faux/faux_classe.dart';
import '../../teaching_core/e/support/hote_classe.dart' show surchargesClasse;

/// Un ecran recense, et ce qu'il doit montrer.
class EcranPays {
  const EcranPays({
    required this.role,
    required this.nom,
    required this.construire,
    required this.pays,
    this.surcharges = const <Override>[],
    this.mode = InterfaceMode.standard,
    this.toucher,
    this.debordementDeBase = false,
    this.hauteur320 = 700,
  });

  /// La hauteur de la vue a 320 px. Les listes de l'administration sont
  /// paresseuses : a texte x2, l'en-tete remplit 700 px et aucune ligne
  /// n'est construite (meme surface haute que `comptes_test.dart`).
  final double hauteur320;

  /// Vrai quand l'ecran deborde deja a 320 px, texte x2, sur la branche de
  /// base (origin/corrections/form-l8-9 @ e0c881ce, mesure du 04/10 sans
  /// aucune ligne de pays) : ce defaut n'est pas celui de cette etape.
  final bool debordementDeBase;

  /// Le role qui regarde.
  final String role;

  /// Le nom court de l'ecran (fichiers de capture).
  final String nom;

  /// L'ecran.
  final Widget Function() construire;

  /// Les surcharges de donnees.
  final List<Override> surcharges;

  /// Le mode d'interface du role.
  final InterfaceMode mode;

  /// Les pays attendus a l'ecran (au moins un de chaque).
  final List<String> pays;

  /// Un texte a toucher apres l'ouverture (ouvrir une carte), ou nul.
  final String? toucher;
}

/// L'instant fige des ecrans qui en lisent un.
final DateTime maintenantPays = DateTime(2026, 10, 6, 17);

Seance _seanceEleve({String? pays}) {
  final DateTime debut = maintenantPays.add(const Duration(minutes: 25));
  return Seance(
    id: 's-pays',
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: StatutSeance.planifiee,
    eleveId: 'e1',
    elevePrenom: 'Khadija',
    eleveIdentifiant: 'STUD-KB-000003',
    enseignantId: 't1',
    enseignantPrenom: 'Aminata',
    enseignantIdentifiant: 'TEACH-AD-000001',
    enseignantPays: pays,
  );
}

/// L'accueil de l'eleve enfant, avec ou sans pays declare.
EcranPays accueilEleve({String? pays = 'Guinée'}) => EcranPays(
  role: 'eleve',
  nom: 'eleve_accueil',
  construire: () => AccueilElevePage(horloge: () => maintenantPays),
  mode: InterfaceMode.enfant,
  pays: <String>[?pays],
  surcharges: <Override>[
    servicePlanningProvider.overrideWithValue(
      FauxServicePlanning()
        ..seancesRendues = <Seance>[_seanceEleve(pays: pays)],
    ),
    servicePriereProvider.overrideWithValue(FauxServicePriere()),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  ],
);

class _Comptes implements ServiceComptes {
  const _Comptes(this.liste);
  final List<CompteAdmin> liste;
  @override
  Future<List<CompteAdmin>> comptes() async => liste;
}

class _Groupes implements ServiceGroupes {
  const _Groupes(this.liste);
  final List<GroupeAdmin> liste;
  @override
  Future<List<GroupeAdmin>> groupes() async => liste;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

CompteAdmin _compte(String id, String prenom, AppRole role, {String? pays}) =>
    CompteAdmin(
      profilId: id,
      identifiant: id,
      prenom: prenom,
      nom: 'Diallo',
      role: role,
      etat: AccountStatus.active,
      inscritLe: maintenantPays.subtract(const Duration(days: 30)),
      accesJusquAu: null,
      foyerId: null,
      piece: role == AppRole.teacher ? EtatPiece.validee : EtatPiece.aucune,
      contrats: 2,
      aEnseignant: false,
      enfantsDuFoyer: 0,
      paysEnseignant: pays,
    );

GroupeAdmin _groupe(String id, String libelle, String prenom, {String? pays}) =>
    GroupeAdmin(
      id: id,
      libelle: libelle,
      type: TypePublicGroupe.enfant,
      seuilMax: 6,
      teacherId: 't-$id',
      teacherIdentifiant: 'TEACH-$id',
      teacherPrenom: prenom,
      teacherNom: 'Diallo',
      creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
      nombreMembres: 3,
      actif: true,
      teacherPays: pays,
    );

/// Le recensement par role, avec les donnees ou le pays est declare (sauf
/// la ligne qui sert a verifier l'absence).
List<EcranPays> ecransPays() => <EcranPays>[
  EcranPays(
    role: 'tuteur',
    nom: 'tuteur_accueil',
    construire: () => const AccueilFamillePage(),
    surcharges: surchargesDemoTuteur(environnement: 'staging'),
    pays: const <String>['Maroc'],
  ),
  EcranPays(
    role: 'tuteur',
    nom: 'tuteur_classe',
    construire: () => ClasseTuteurPage(
      classeId: DonneesDemo.classes[DonneesDemo.aichaId]!.groupeId,
      eleveId: DonneesDemo.aichaId,
    ),
    surcharges: surchargesDemoTuteur(environnement: 'staging'),
    pays: <String>[DonneesDemo.classes[DonneesDemo.aichaId]!.enseignant.pays!],
  ),
  accueilEleve(),
  EcranPays(
    role: 'eleve_adulte',
    nom: 'adulte_ma_classe',
    construire: () => const CoquilleAdulteDemo(ecran: EcranDemoAdulte.maClasse),
    pays: const <String>['France'],
  ),
  EcranPays(
    role: 'mode_accessibilite',
    nom: 'ma_accueil',
    construire: () => const EcranAccessibiliteDemo(
      eleve: EleveDemoAccessibilite.mariam,
      destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
    ),
    mode: InterfaceMode.enfant,
    pays: const <String>['France'],
  ),
  EcranPays(
    role: 'controleur',
    nom: 'controleur_mission',
    construire: () =>
        const CoquilleControleurDemo(ecran: EcranDemoControleur.controle),
    pays: const <String>['France'],
    debordementDeBase: true,
  ),
  EcranPays(
    role: 'controleur',
    nom: 'controleur_historique',
    construire: () =>
        const CoquilleControleurDemo(ecran: EcranDemoControleur.historique),
    pays: const <String>['France'],
  ),
  EcranPays(
    role: 'admin',
    nom: 'admin_attribution',
    construire: () => const AttributionPage(),
    toucher: 'Yacine',
    surcharges: <Override>[
      serviceAttributionProvider.overrideWithValue(
        FauxServiceAttribution()
          ..foyers = <FoyerEnAttente>[
            FoyerEnAttente(
              eleveId: 'e1',
              prenom: 'Yacine',
              identifiantImmuable: 'STUD-YA-000001',
              foyerId: 'f1',
              mode: InterfaceMode.enfant,
              niveau: 'debutant',
              depuis: maintenantPays.subtract(const Duration(days: 12)),
              creneaux: const <Creneau>[
                Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
              ],
            ),
          ]
          ..enseignants['e1'] = <EnseignantCandidat>[
            const EnseignantCandidat(
              id: 't1',
              prenom: 'Omar',
              nom: 'Sow',
              identifiantImmuable: 'TEACH-OS-000001',
              elevesActifs: 1,
              plafond: 5,
              creneauxCommuns: <Creneau>[
                Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
              ],
              pays: 'Sénégal',
            ),
            const EnseignantCandidat(
              id: 't2',
              prenom: 'Awa',
              nom: 'Bah',
              identifiantImmuable: 'TEACH-AB-000002',
              elevesActifs: 3,
              plafond: 5,
              creneauxCommuns: <Creneau>[],
            ),
          ],
      ),
      serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
    ],
    pays: const <String>['Sénégal'],
  ),
  EcranPays(
    role: 'admin',
    nom: 'admin_groupes',
    construire: () => const admin.GroupesPage(),
    surcharges: <Override>[
      serviceGroupesProvider.overrideWithValue(
        _Groupes(<GroupeAdmin>[
          _groupe('g1', 'Classe Al-Badr', 'Ibrahim', pays: 'Guinée'),
          _groupe('g2', 'Classe An-Nour', 'Khadija'),
        ]),
      ),
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
    pays: const <String>['Guinée'],
    debordementDeBase: true,
    hauteur320: 2400,
  ),
  EcranPays(
    role: 'admin',
    nom: 'admin_comptes',
    construire: () => const ComptesPage(),
    surcharges: <Override>[
      serviceComptesProvider.overrideWithValue(
        _Comptes(<CompteAdmin>[
          _compte(
            'TEACH-ID-000001',
            'Ibrahim',
            AppRole.teacher,
            pays: 'Royaume-Uni',
          ),
          _compte('TEACH-KD-000002', 'Khadija', AppRole.teacher),
          _compte('GUAR-AD-000003', 'Aicha', AppRole.guardian),
        ]),
      ),
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    ],
    pays: const <String>['Royaume-Uni'],
    debordementDeBase: true,
    hauteur320: 2400,
  ),
  // Seconde passe (verification croisee du 04/10) : les cartes oubliees.
  EcranPays(
    role: 'tuteur',
    nom: 'tuteur_catalogue',
    construire: () => const CatalogueClassesPage(eleveId: DonneesDemo.yusufId),
    surcharges: surchargesDemoTuteur(environnement: 'staging'),
    pays: const <String>['Maroc', 'France'],
  ),
  classeLiveTuteur(),
  EcranPays(
    role: 'controleur',
    nom: 'controleur_classe_live',
    construire: () => ClasseLivePage(contexte: _contexteLive()),
    surcharges: _surchargesLive('controller'),
    pays: const <String>['Guinée'],
  ),
  EcranPays(
    role: 'eleve',
    nom: 'eleve_espace_groupe',
    construire: () =>
        const EspaceGroupePage(groupeId: GroupesDemonstration.alFatiha),
    surcharges: surchargesDemonstration(),
    pays: const <String>['Guinée'],
  ),
  EcranPays(
    role: 'eleve',
    nom: 'eleve_mes_groupes',
    construire: () => const MesGroupesPage(),
    surcharges: surchargesDemonstration(),
    pays: const <String>['Guinée'],
  ),
  EcranPays(
    role: 'eleve',
    nom: 'eleve_suivi',
    construire: () => SuiviElevePage(horloge: () => maintenantPays),
    surcharges: <Override>[
      serviceSuiviProvider.overrideWithValue(
        FauxServiceSuivi(
          seancesRendues: <Seance>[
            _seancePassee(DonneesDemo.yusufId, 'Yusuf', jours: 2),
          ],
          presencesRendues: null,
        ),
      ),
    ],
    pays: const <String>['Mali'],
    hauteur320: 2400,
  ),
  EcranPays(
    role: 'tuteur',
    nom: 'tuteur_suivi_foyer',
    construire: () => SuiviFoyerPage(horloge: () => maintenantPays),
    surcharges: _surchargesSuiviFoyer(),
    pays: const <String>['Mali'],
  ),
  EcranPays(
    role: 'tuteur',
    nom: 'tuteur_detail_seance',
    construire: () => const DetailSeancePage(seanceId: 's-passee-2'),
    surcharges: _surchargesSuiviFoyer(),
    pays: const <String>['Mali'],
  ),
];

/// Le contexte de la Classe Live : l'enseignant du groupe Al-Fatiha de la
/// demonstration, tel que `routes_tc_a.dart` le transmet depuis sa carte.
ContexteClasseLive _contexteLive({
  bool photo = true,
  String prenom = 'Youssouf',
}) => ContexteClasseLive(
  sessionId: 's-live',
  groupeId: GroupesDemonstration.alFatiha,
  libelleGroupe: 'Groupe Al-Fatiha',
  enseignant: EnseignantDeClasse(
    nomAffichage: prenom,
    titre: TitreEnseignant.sayyid,
    photoCleOuUrl: photo ? 'https://exemple.invalid/youssouf.jpg' : null,
    pays: 'Guinée',
  ),
);

/// La Classe Live vue par le tuteur observateur, avec ou sans photo de
/// l'enseignant (les deux branches de `EnteteClasse`), et un prenom vide
/// pour l'identite masquee.
EcranPays classeLiveTuteur({bool photo = true, String prenom = 'Youssouf'}) =>
    EcranPays(
      role: 'tuteur',
      nom: 'tuteur_classe_live',
      construire: () => ClasseLivePage(
        contexte: _contexteLive(photo: photo, prenom: prenom),
      ),
      surcharges: _surchargesLive('guardian'),
      pays: <String>[if (prenom.isNotEmpty) 'Guinée'],
    );

/// Les faux de la Classe Live pour un role du jeton qui n'a pas de salle de
/// seance (tuteur observateur, controleur) : l'en-tete `EnteteClasse` est
/// alors celui qui presente l'enseignant.
List<Override> _surchargesLive(String role) => <Override>[
  ...surchargesClasse(
    moteur: FauxMoteurClasse(),
    video: FauxServiceVideoClasse(acces0: accesDe(role)),
    preVol: FauxPreVolClasse(),
  ),
];

/// Une seance passee de l'eleve [eleveId], enseignant au pays declare.
Seance _seancePassee(String eleveId, String prenom, {required int jours}) {
  final DateTime debut = maintenantPays.subtract(Duration(days: jours));
  return Seance(
    id: 's-passee-$jours',
    debut: debut,
    fin: debut.add(const Duration(minutes: 45)),
    statut: StatutSeance.terminee,
    eleveId: eleveId,
    elevePrenom: prenom,
    eleveIdentifiant: 'DEMO-Y1',
    enseignantId: 'ens-mali',
    enseignantPrenom: 'Oumar',
    enseignantIdentifiant: 'TEACH-OM-000004',
    enseignantPays: 'Mali',
  );
}

/// Le foyer de demonstration, dont le suivi rend une seance passee de
/// Yusuf avec un enseignant au pays declare (la demonstration n'en rend
/// aucune).
List<Override> _surchargesSuiviFoyer() => <Override>[
  for (final Override o in surchargesDemoTuteur(environnement: 'staging'))
    // ignore: invalid_use_of_visible_for_testing_member
    if (o.origin != seancesDuSuiviProvider &&
        // ignore: invalid_use_of_visible_for_testing_member
        o.origin != presenceDuSuiviProvider)
      o,
  seancesDuSuiviProvider.overrideWith(
    (Ref _) async => <Seance>[
      _seancePassee(DonneesDemo.yusufId, 'Yusuf', jours: 2),
      _seancePassee(DonneesDemo.aichaId, 'Aïcha', jours: 3),
    ],
  ),
  presenceDuSuiviProvider.overrideWith(
    (Ref _) async => const <PresenceParticipant>[],
  ),
];

/// Fait defiler l'ecran jusqu'a la premiere ligne du pays, posee au tiers de
/// la vue : ni sous un en-tete colle, ni sous la barre de navigation (K-61,
/// verification croisee du 04/10). Sans ligne de pays, ne fait rien.
Future<void> montrerPays(WidgetTester tester) async {
  final Finder lignes = find.byKey(PaysEnseignant.ligneKey);
  if (lignes.evaluate().isEmpty) return;
  final BuildContext contexte = lignes.evaluate().first;
  if (Scrollable.maybeOf(contexte) != null) {
    await Scrollable.ensureVisible(contexte, alignment: 0.3);
    await stabiliser(tester);
  }
}

/// Vrai quand la premiere ligne du pays est entierement dans la vue et au
/// dessus de la barre de navigation basse, s'il y en a une.
Rect? rectangleVisibleDuPays(WidgetTester tester, Size vue) {
  final Finder lignes = find.byKey(PaysEnseignant.ligneKey);
  if (lignes.evaluate().isEmpty) return null;
  final Rect r = tester.getRect(lignes.first);
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  final double bas = barre.evaluate().isEmpty
      ? vue.height
      : tester.getRect(barre).top;
  return r.top >= 0 && r.bottom <= bas + 0.5 ? r : null;
}

/// L'hote d'un ecran recense : vrai theme clair ou sombre, echelle de texte,
/// sens de lecture, et un routeur (les ecrans du tuteur en lisent un).
Widget hotePays(
  EcranPays e, {
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) {
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState _) =>
            Directionality(textDirection: sens, child: e.construire()),
      ),
    ],
  );
  return ProviderScope(
    overrides: e.surcharges,
    child: TranslationProvider(
      child: RepaintBoundary(
        key: cadreCapture,
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(e.mode, Brightness.light),
            darkTheme: AppTheme.pour(e.mode, Brightness.dark),
            themeMode: theme,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
            builder: (BuildContext contexte, Widget? app) => MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
        ),
      ),
    ),
  );
}
