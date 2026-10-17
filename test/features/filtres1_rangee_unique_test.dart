// FILTRES-1 (decide par delegation le 05/10/2026) : sur chaque ecran a
// filtres de la branche commune, UNE seule rangee de puces, qui defile
// horizontalement quand elle ne tient pas ; puces de meme hauteur, contenu
// centre (K-54), aucun debordement, aucun mot coupe a 320 px texte x2, en
// LTR et en RTL.
//
// Chaque cas monte le VRAI ecran (ou, pour l'Historique du foyer, la vraie
// barre que ses deux ecrans posent) sur des doubles en memoire, jamais un
// service reel. Les jeux de donnees sont choisis pour que la rangee deborde a
// 320 px texte x2 : c'est la que l'ancien `Wrap` passait a la ligne.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/vue_catalogue.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/admin_journal/journal_page.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';
import 'package:rewayah_academy/features/admin_observations/observations_admin_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_progression/progression_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_qualite/qualite_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/demo/historique_controleur_demo.dart';
import 'package:rewayah_academy/features/suivi_foyer/composants_historique.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../support/sens_et_echelle.dart';
import '../teaching_core/b/faux/faux_ports_b.dart'
    show ressource, surchargesCatalogue;
import 'admin_observations/support_admin_observations.dart';

const double _largeur = 320;

/// Les puces de filtre a l'ecran : pastilles et menus. Le selecteur de
/// section (`MenuFiltre` en mode `selecteurDeSection`, ONGLETS-1) n'est pas un
/// filtre : il dit ou l'on est, sur sa propre ligne.
final Finder pucesFiltres1 = find.byWidgetPredicate(
  (Widget w) => w is FilterPill || (w is MenuFiltre && !w.selecteurDeSection),
);

Widget hoteFiltres1(
  Widget ecran,
  List<Override> surcharges,
  TextDirection sens,
) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: sensEtEchelle(direction: sens, echelle: 2),
      home: ecran,
    ),
  ),
);

/// Le Scrollable horizontal le plus proche de [puce], ou null.
ScrollableState? _defilementDe(WidgetTester tester, Finder puce) {
  ScrollableState? trouve;
  tester.element(puce).visitAncestorElements((Element e) {
    if (e is StatefulElement && e.state is ScrollableState) {
      final ScrollableState s = e.state as ScrollableState;
      if (axisDirectionToAxis(s.axisDirection) == Axis.horizontal) {
        trouve = s;
        return false;
      }
    }
    return true;
  });
  return trouve;
}

/// Les puces posees dans la rangee : celles qu'on peut toucher. Depuis
/// L4-07, la rangee en montre trois au plus, puis « Plus » ; les autres
/// restent dans l'arbre, ni peintes ni touchables, et se lisent dans la
/// feuille de « Plus ».
final Finder pucesPosees1 = pucesFiltres1.hitTestable();

/// La mesure commune a tous les ecrans.
Future<void> _verifierRangeeUnique(
  WidgetTester tester,
  TextDirection sens, {
  int auMoins = 2,
}) async {
  expect(tester.takeException(), isNull, reason: 'debordement au rendu');
  // Les puces du jeu de donnees, plus les variantes de « Plus ».
  expect(
    pucesFiltres1.evaluate().length,
    greaterThanOrEqualTo(auMoins),
    reason: 'puces de filtre',
  );
  final int n = pucesPosees1.evaluate().length;
  // L4-07 : trois puces au plus et « Plus » ; au moins une, meme a 320 px
  // texte x2 (« Plus » peut alors se trouver au bout de la rangee qui defile).
  expect(n, inInclusiveRange(1, 4), reason: 'puces posees');

  // 1. Une seule rangee : toutes les puces ont le meme haut et la meme
  //    hauteur (contenu de meme hauteur, K-54).
  final List<Rect> boites = <Rect>[
    for (int i = 0; i < n; i++) tester.getRect(pucesPosees1.at(i)),
  ];
  for (final Rect b in boites) {
    expect(
      b.top,
      moreOrLessEquals(boites.first.top, epsilon: 0.5),
      reason: 'une puce passe a la ligne : $boites',
    );
    expect(
      b.height,
      moreOrLessEquals(boites.first.height, epsilon: 0.5),
      reason: 'puces de hauteurs differentes : $boites',
    );
  }

  // 2. Contenu centre dans chaque puce, en largeur et en hauteur (K-54) :
  //    le bloc de ses textes (libelle, compteur), meme sur deux lignes, et
  //    la coche de la puce retenue (FILTERPILL-ETAT-1), qui passe au-dessus
  //    du libelle quand la place manque (JONCTION-LIGNES-1).
  for (int i = 0; i < n; i++) {
    final Rect bloc = find
        .descendant(
          of: pucesPosees1.at(i),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Text || w is Icon,
          ),
        )
        .evaluate()
        .map((Element e) => tester.getRect(find.byWidget(e.widget)))
        .reduce((Rect a, Rect b) => a.expandToInclude(b));
    expect(
      bloc.center.dy,
      moreOrLessEquals(boites[i].center.dy, epsilon: 1),
      reason: 'contenu non centre en hauteur dans sa puce',
    );
    if (pucesPosees1.at(i).evaluate().single.widget is FilterPill) {
      expect(
        bloc.center.dx,
        moreOrLessEquals(boites[i].center.dx, epsilon: 1),
        reason: 'contenu non centre en largeur dans sa puce',
      );
    }
  }

  // 3. Toutes dans le MEME defilement horizontal, borne a l'ecran.
  final Set<ScrollableState> defilements = <ScrollableState>{
    for (int i = 0; i < n; i++)
      if (_defilementDe(tester, pucesPosees1.at(i))
          case final ScrollableState s)
        s,
  };
  expect(defilements, hasLength(1), reason: 'une seule rangee qui defile');
  final ScrollableState rangee = defilements.single;
  final Rect vue = tester.getRect(find.byWidget(rangee.widget));
  expect(vue.left, greaterThanOrEqualTo(0));
  expect(vue.right, lessThanOrEqualTo(_largeur));

  // 3 bis. Le filtre retenu se voit entier des l'ouverture.
  for (int i = 0; i < n; i++) {
    final Widget w = pucesPosees1.at(i).evaluate().single.widget;
    if (w is FilterPill && w.retenue) {
      expect(boites[i].left, greaterThanOrEqualTo(vue.left - 0.5));
      expect(boites[i].right, lessThanOrEqualTo(vue.right + 0.5));
    }
  }

  // 4. Aucun mot coupe ni tronque dans les puces.
  verifierAucunMotCoupe(tester, pucesPosees1);

  // 5. Le debut de la rangee est au debut du sens de lecture ; la derniere
  //    puce s'atteint en defilant.
  rangee.position.jumpTo(rangee.position.minScrollExtent);
  await tester.pump();
  final Rect premiere = tester.getRect(pucesPosees1.first);
  if (sens == TextDirection.ltr) {
    expect(premiere.left, moreOrLessEquals(vue.left, epsilon: 0.5));
  } else {
    expect(premiere.right, moreOrLessEquals(vue.right, epsilon: 0.5));
  }
  await tester.ensureVisible(pucesPosees1.last);
  await tester.pumpAndSettle();
  final Rect derniere = tester.getRect(pucesPosees1.last);
  expect(derniere.left, greaterThanOrEqualTo(vue.left - 0.5));
  expect(derniere.right, lessThanOrEqualTo(vue.right + 0.5));
  expect(tester.takeException(), isNull);
}

/// Un cas d'ecran : son nom, et comment le monter.
typedef CasFiltres1 = ({
  String nom,
  Widget ecran,
  List<Override> surcharges,
  int auMoins,
});

CompteAdmin _compte(String id, AccountStatus etat, AppRole role) => CompteAdmin(
  profilId: id,
  identifiant: id,
  prenom: 'Aicha',
  nom: 'Sow',
  role: role,
  etat: etat,
  inscritLe: DateTime(2026, 9, 1),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 1,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    _compte('A1', AccountStatus.pendingKyc, AppRole.teacher),
    _compte('A2', AccountStatus.active, AppRole.guardian),
    _compte('A3', AccountStatus.provisionalActive, AppRole.admin),
    _compte('A4', AccountStatus.disabled, AppRole.teacher),
  ];
}

GroupeAdmin _groupe(String id, TypePublicGroupe type) => GroupeAdmin(
  id: id,
  libelle: 'Classe $id',
  type: type,
  seuilMax: 6,
  teacherId: 't1',
  teacherIdentifiant: 'TEACHER-1',
  teacherPrenom: 'Amina',
  teacherNom: 'Diallo',
  creneau: const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
  nombreMembres: 3,
  actif: true,
);

EleveProgression _eleve(String id, String cycle) => EleveProgression(
  studentId: id,
  identifiant: id,
  prenom: 'Mariam',
  nom: 'Diallo',
  groupeId: 'g1',
  groupeLibelle: 'An-Nour',
  niveauId: 'n-$cycle',
  niveauNomHumain: 'Niveau $cycle',
  niveauCycle: cycle,
  niveauDepuis: DateTime(2026, 9, 1),
  exceptionActiveId: null,
  exceptionActiveType: null,
);

EvaluationAdmin _evaluation(String id, StatutEvaluation statut) =>
    EvaluationAdmin(
      id: id,
      studentId: 's-$id',
      identifiant: 'S-$id',
      prenom: 'Mariam',
      nom: 'Diallo',
      niveauId: 'n1',
      niveauNomHumain: 'Fondations',
      type: TypeEvaluation.periodique,
      statut: statut,
      datePrevue: DateTime(2026, 10, 12),
      dateRealisee: null,
      resultat: null,
      notes: null,
    );

AnomalieQualite _anomalie(String id, StatutControleQualite statut) =>
    AnomalieQualite(
      type: TypeAnomalieQualite.rapportManquant,
      refId: id,
      studentId: 's1',
      studentPrenom: 'Mariam',
      studentNom: 'Diallo',
      teacherId: 't1',
      teacherPrenom: 'Amina',
      teacherNom: 'Diallo',
      depuis: DateTime(2026, 9, 20),
      controleStatut: statut,
      controleNote: null,
    );

VersionProgramme _version(int numero, StatutVersionProgramme statut) =>
    VersionProgramme(
      id: 'v$numero',
      statut: statut,
      numeroVersion: numero,
      creeParIdentifiant: 'ADMIN-1',
      creeParPrenom: 'Khadija',
      creeParNom: 'Ndiaye',
      publieeAt: null,
      nombreNiveaux: numero,
      createdAt: DateTime(2026, 9, numero),
    );

FauxServiceJournal _journal() =>
    FauxServiceJournal()
      ..filtres0 = const FiltresJournal(
        actions: <ValeurFiltre>[
          ValeurFiltre(valeur: 'kyc_read', libelle: 'kyc_read', nombre: 3),
        ],
        acteurs: <ValeurFiltre>[
          ValeurFiltre(valeur: 'u1', libelle: 'Khadija Ndiaye', nombre: 3),
        ],
        total: 3,
      );

Override _reseau() =>
    serviceReseauProvider.overrideWithValue(FauxServiceReseau());

List<CasFiltres1> casFiltres1() => <CasFiltres1>[
  (
    nom: 'Comptes (ADM-08)',
    ecran: const ComptesPage(),
    surcharges: <Override>[
      _reseau(),
      serviceComptesProvider.overrideWithValue(_Comptes()),
    ],
    auMoins: 5,
  ),
  (
    nom: 'Journal (ADM-04)',
    ecran: const JournalPage(),
    surcharges: <Override>[
      _reseau(),
      serviceJournalProvider.overrideWithValue(_journal()),
    ],
    auMoins: 5,
  ),
  (
    nom: 'Observations (admin)',
    ecran: ObservationsAdminPage(horloge: () => DateTime(2026, 10, 5, 12)),
    surcharges: <Override>[
      _reseau(),
      portHistoriqueObservationsAdminProvider.overrideWithValue(
        FauxHistoriqueObservationsAdmin(),
      ),
      annuaireObservationsProvider.overrideWithValue(FauxAnnuaire()),
    ],
    auMoins: 3,
  ),
  (
    nom: 'Classes (groupes)',
    ecran: const GroupesPage(),
    surcharges: <Override>[
      _reseau(),
      groupesProvider.overrideWith(
        (Ref _) async => <GroupeAdmin>[
          _groupe('g1', TypePublicGroupe.enfant),
          _groupe('g2', TypePublicGroupe.adulte),
        ],
      ),
    ],
    auMoins: 3,
  ),
  (
    nom: 'Progression',
    ecran: const ProgressionPage(),
    surcharges: <Override>[
      _reseau(),
      progressionProvider.overrideWith(
        (Ref _) async => <EleveProgression>[
          _eleve('e1', 'Éveil'),
          _eleve('e2', 'Fondations'),
          _eleve('e3', 'Approfondissement'),
          _eleve('e4', 'Perfectionnement'),
        ],
      ),
    ],
    auMoins: 5,
  ),
  (
    nom: 'Evaluations',
    ecran: const EvaluationsPage(),
    surcharges: <Override>[
      _reseau(),
      evaluationsProvider.overrideWith(
        (Ref _) async => <EvaluationAdmin>[
          for (final StatutEvaluation s in StatutEvaluation.values)
            _evaluation(s.name, s),
        ],
      ),
    ],
    auMoins: 5,
  ),
  (
    nom: 'Qualite',
    ecran: const QualitePage(),
    surcharges: <Override>[
      _reseau(),
      anomaliesQualiteProvider.overrideWith(
        (Ref _) async => <AnomalieQualite>[
          // Une ouverte, une traitee : le filtre par defaut (« Ouvertes »)
          // montre la liste (elle plantait avant FILTRES-1b).
          _anomalie('a1', StatutControleQualite.ouvert),
          _anomalie('a2', StatutControleQualite.traite),
        ],
      ),
    ],
    auMoins: 3,
  ),
  (
    nom: 'Programmes (versions)',
    ecran: const ProgrammesPage(),
    surcharges: <Override>[
      _reseau(),
      versionsProgrammeProvider.overrideWith(
        (Ref _) async => <VersionProgramme>[
          _version(4, StatutVersionProgramme.brouillon),
          _version(3, StatutVersionProgramme.publiee),
          _version(2, StatutVersionProgramme.archivee),
          _version(1, StatutVersionProgramme.archivee),
        ],
      ),
      niveauxProgrammeProvider.overrideWith(
        (Ref _, String _) async => const <NiveauProgramme>[],
      ),
    ],
    auMoins: 4,
  ),
  (
    nom: 'Historique du controleur',
    ecran: HistoriqueControleurPage(maintenant: DateTime(2026, 10, 5, 12)),
    surcharges: <Override>[
      _reseau(),
      portHistoriqueProvider.overrideWithValue(const HistoriqueDemo()),
    ],
    auMoins: 3,
  ),
  (
    nom: 'Historique du foyer (barre partagee seances et observations)',
    ecran: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarreFiltresHistorique<StatutHistorique>(
          filtres: const FiltresHistorique<StatutHistorique>(),
          classes: const <String, String>{'c1': 'An-Nour', 'c2': 'Al-Huda'},
          statuts: const <(StatutHistorique, int)>[
            (StatutHistorique.presence, 4),
            (StatutHistorique.retard, 1),
          ],
          onFiltres: (FiltresHistorique<StatutHistorique> _) {},
        ),
      ),
    ),
    surcharges: const <Override>[],
    auMoins: 3,
  ),
  (
    nom: 'Bibliotheque (types et disponibilite)',
    // La gouttiere de 16 que `PageShell` donne a la vraie page.
    ecran: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SurfaceBibliotheque(
          contexte: ContexteDecouverte.horsClasse,
          groupeId: null,
          onChoisir: (LibraryResource _, ContentPosition? _) {},
        ),
      ),
    ),
    surcharges: surchargesCatalogue(
      ressources: <LibraryResource>[ressource(id: 'r1', titre: 'Alphabet')],
    ),
    auMoins: 6,
  ),
];

void main() {
  // Les vraies polices : la largeur d'un mot, donc sa coupure, en depend.
  setUpAll(chargerPolicesDuDepot);

  final List<CasFiltres1> cas = casFiltres1();
  for (int i = 0; i < cas.length; i++) {
    final CasFiltres1 c = cas[i];
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${c.nom} : une rangee unique qui defile, 320 px texte x2, '
          '${sens.name}', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(_largeur, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Des doubles neufs a chaque test.
        final CasFiltres1 neuf = casFiltres1()[i];
        await tester.pumpWidget(
          hoteFiltres1(neuf.ecran, neuf.surcharges, sens),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await _verifierRangeeUnique(tester, sens, auMoins: c.auMoins);
      });
    }
  }
}
