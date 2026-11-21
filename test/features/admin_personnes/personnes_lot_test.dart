// PERSONNES-UNE-PAGE, etape (f) point 2 : la page unique porte ce que les
// anciennes listes font. Onglet des enseignants : menu d'actions par ligne,
// selection et lot, tri. Comptes : selection groupee (suppression de plusieurs
// comptes), tri, « Ouvrir le dossier », « Verifier la ville ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart'
    show DetailCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu_direction.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart'
    show libelleGeste;
import 'package:rewayah_academy/features/admin_candidature/references_dossiers.dart';
import 'package:rewayah_academy/features/admin_candidatures/feuille_filtres.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart'
    show nomAffiche;
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/selection_lot.dart';
import 'package:rewayah_academy/features/admin_comptes/gestes_compte.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

class _Retraits implements PortRetraitsComptes {
  final List<List<String>> envois = <List<String>>[];

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) async {
    envois.add(ids);
    return <ResultatRetrait>[
      for (final String id in ids) ResultatRetrait(id: id, retire: true),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _References implements PortReferencesDossiers {
  @override
  Future<Map<String, String>> references(List<String> profils) async =>
      <String, String>{
        // La famille 4 a aussi un dossier d'enseignant ; l'enseignant 6 est
        // le dossier « Karim Essai » (en accueil).
        if (profils.contains('4')) '4': 'CAND-00009',
        if (profils.contains('6')) '6': 'CAND-00003',
      };
}

class _Lieux implements PortLieuDirection {
  final List<String> verifies = <String>[];

  @override
  Future<List<LieuEnseignantDirection>> lieux() async =>
      <LieuEnseignantDirection>[
        LieuEnseignantDirection(
          profilId: '6',
          ville: 'Essaiville',
          paysCode: 'MA',
          verifie: verifies.contains('6'),
        ),
      ];

  @override
  Future<void> verifier(String profilId) async => verifies.add(profilId);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final List<TriEnseignants> _trisEnseignants = <TriEnseignants>[];

class _Enseignants implements PortEnseignants {
  const _Enseignants(this._lignes);

  final List<LigneEnseignant> _lignes;

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async {
    _trisEnseignants.add(tri);
    final List<LigneEnseignant> lignes = <LigneEnseignant>[
      for (final LigneEnseignant l in _lignes)
        if (filtre.phase == null
            ? l.phase != PhaseEnseignant.parti
            : l.phase == filtre.phase)
          l,
    ];
    return PageEnseignants(
      lignes: page == 1 ? lignes : const <LigneEnseignant>[],
      total: lignes.length,
      page: page,
      taillePage: 50,
      compteurs: CompteursEnseignants(
        parPhase: <PhaseEnseignant, int>{
          for (final PhaseEnseignant p in PhaseEnseignant.values)
            p: _lignes.where((LigneEnseignant l) => l.phase == p).length,
        },
      ),
    );
  }
}

CompteAdmin _compte(String id, String prenom, AppRole role) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-41$id',
  prenom: prenom,
  nom: 'Essai',
  role: role,
  etat: AccountStatus.active,
  inscritLe: DateTime.now().subtract(Duration(days: 10 + int.parse(id))),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: role == AppRole.guardian ? 2 : 0,
  detailsServis: true,
  tranche: role == AppRole.student ? TrancheAge.enfant : null,
);

final List<CompteAdmin> _comptes = <CompteAdmin>[
  _compte('1', 'Amina', AppRole.student),
  _compte('2', 'Bilal', AppRole.student),
  _compte('3', 'Chaima', AppRole.student),
  _compte('4', 'Driss', AppRole.guardian),
  _compte('7', 'Zina', AppRole.guardian),
  _compte('5', 'Esma', AppRole.admin),
  _compte('6', 'Karim', AppRole.teacher),
];

final List<LigneEnseignant> _enseignants = <LigneEnseignant>[
  LigneEnseignant(
    dossier: ligneTest(id: 'c1', reference: 'CAND-00001', nom: 'Farid Essai'),
    phase: PhaseEnseignant.candidat,
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c3', reference: 'CAND-00003', nom: 'Karim Essai'),
    phase: PhaseEnseignant.accueil,
    gestes: const <String>['mettre_en_pause', 'refuser'],
    gestesGroupables: const <String>['mettre_en_pause'],
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c6', reference: 'CAND-00006', nom: 'Nora Essai'),
    phase: PhaseEnseignant.accueil,
    gestes: const <String>['mettre_en_pause'],
    gestesGroupables: const <String>['mettre_en_pause'],
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c7', reference: 'CAND-00007', nom: 'Omar Essai'),
    phase: PhaseEnseignant.accueil,
  ),
];

/// Une direction qui decide et agit en lot.
const CapacitesCandidatures _capacites = CapacitesCandidatures(
  peutLire: true,
  genreLecteurConnu: true,
  peutDecider: true,
  gestes: <String, bool>{
    'agirEnLot': true,
    'mettreEnPause': true,
    'leverPause': true,
    'refuser': true,
  },
);

late GoRouter _routeur;
late FauxCandidaturesDirection _port;
late _Retraits _retraits;
late _Lieux _lieux;
final List<String> _dossiers = <String>[];

Future<void> _monter(
  WidgetTester tester, {
  required String adresse,
  Size taille = const Size(1440, 900),
  CapacitesCandidatures capacites = _capacites,
  List<LigneCandidature>? lignes,
  List<CompteAdmin>? comptes,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  _dossiers.clear();
  _trisEnseignants.clear();
  _retraits = _Retraits();
  _lieux = _Lieux();
  final List<LigneCandidature> candidatures =
      lignes ??
      <LigneCandidature>[
        for (final LigneEnseignant l in _enseignants) l.dossier,
      ];
  await tester.pumpWidget(
    hoteRoutant(
      depart: adresse,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminPersonnes,
          builder: (BuildContext contexte, GoRouterState e) {
            _routeur = GoRouter.of(contexte);
            return PersonnesPage(
              requete: e.uri.queryParameters,
              ouvrirDossier: (String chemin, String _) => _dossiers.add(chemin),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'candidatures/:reference',
              builder: (BuildContext _, GoRouterState e) => Scaffold(
                body: Text('dossier ${e.pathParameters['reference']}'),
              ),
            ),
          ],
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_Comptes(comptes ?? _comptes)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portEnseignantsProvider.overrideWithValue(_Enseignants(_enseignants)),
        portRetraitsComptesProvider.overrideWithValue(_retraits),
        portReferencesDossiersProvider.overrideWithValue(_References()),
        portLieuDirectionProvider.overrideWithValue(_lieux),
        portCandidaturesDirectionProvider.overrideWithValue(
          _port = FauxCandidaturesDirection(
            capacitesRendues: capacites,
            lignes: candidatures,
            details: <DetailCandidature>[
              for (final LigneCandidature l in candidatures)
                detailTest(
                  id: l.id,
                  reference: l.reference,
                  nom: nomAffiche(l),
                ),
            ],
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

String get _adresse =>
    Uri.decodeFull(_routeur.routerDelegate.currentConfiguration.uri.toString());

/// La case de la ligne de [nom].
Finder _caseDe(String nom) => find.byWidgetPredicate(
  (Widget w) =>
      w is CaseACocher && w.libelle == t.commun.listes.cocherLigne(objet: nom),
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('onglet des enseignants', () {
    testWidgets('chaque candidat a son menu : « Ouvrir le dossier » ouvre le '
        'dossier avec la file de la vue ; la ligne entiere reste cliquable', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
      );
      for (final LigneEnseignant l in _enseignants) {
        expect(
          find.byKey(PersonnesPage.cleMenuLigne(l.dossier.reference)),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(PersonnesPage.cleMenuLigne('CAND-00001')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(t.admin.candidatures.liste.ouvrirDossier).last,
      );
      await tester.pumpAndSettle();
      expect(_dossiers.single, contains('CAND-00001'));
      expect(_dossiers.single, contains('vue=candidats'));
      // La ligne : elle choisit la personne (apercu), sans ouvrir de menu.
      await tester.tap(find.text('Nora Essai').first);
      await tester.pumpAndSettle();
      expect(_adresse, contains('element=CAND-00006'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('en accueil : le menu offre les gestes que le serveur permet '
        '(celui qui refuse en dernier) ; un geste lit le dossier', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=accueil',
      );
      await tester.tap(find.byKey(PersonnesPage.cleMenuLigne('CAND-00003')));
      await tester.pumpAndSettle();
      final double pause = tester
          .getTopLeft(
            find.text(libelleGeste(GesteCandidature.mettreEnPause)).last,
          )
          .dy;
      final double refuser = tester
          .getTopLeft(find.text(libelleGeste(GesteCandidature.refuser)).last)
          .dy;
      expect(pause, lessThan(refuser));
      await tester.tap(
        find.text(libelleGeste(GesteCandidature.mettreEnPause)).last,
      );
      await tester.pumpAndSettle();
      expect(_port.appelsLire, contains('c3'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('candidats : deux dossiers coches, la barre du lot propose '
        'ecrire, mettre en pause et refuser ; la feuille recoit les deux', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
      );
      expect(find.byKey(PersonnesPage.cleBarreLot), findsNothing);
      await tester.tap(_caseDe('Farid Essai'));
      await tester.pumpAndSettle();
      await tester.tap(_caseDe('Nora Essai'));
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreLot), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.lot.selectionnees(n: 2)),
        findsOneWidget,
      );
      // Une seule rangee : les deux gestes courants en boutons, le reste
      // dans « Autres actions », celui qui refuse en dernier.
      for (final GesteLot g in <GesteLot>[
        GesteLot.ecrire,
        GesteLot.mettreEnPause,
      ]) {
        expect(find.byKey(PersonnesPage.cleOperationLot(g)), findsOneWidget);
      }
      expect(
        find.byKey(PersonnesPage.cleOperationLot(GesteLot.refuser)),
        findsNothing,
      );
      final double bouton = tester
          .getSize(
            find.byKey(PersonnesPage.cleOperationLot(GesteLot.mettreEnPause)),
          )
          .height;
      expect(
        tester.getSize(find.byKey(PersonnesPage.cleBarreLot)).height,
        lessThanOrEqualTo(bouton + 2 * AppSpacing.lg),
      );
      // La liste reste lisible au-dessus de la barre : les quatre dossiers.
      final double hautBarre = tester
          .getTopLeft(find.byKey(PersonnesPage.cleBarreLot))
          .dy;
      for (final LigneEnseignant l in _enseignants) {
        expect(
          tester.getBottomLeft(find.text(nomAffiche(l.dossier)).first).dy,
          lessThan(hautBarre),
        );
      }
      // L'entree « Refuser » du menu est la derniere, marquee destructive.
      final EntreeAction derniere = tester
          .widget<MenuActions>(find.byKey(BarreLot.cleAutres))
          .actions
          .last;
      expect(derniere.libelle, libelleGesteLot(GesteLot.refuser));
      expect(derniere.destructif, isTrue);
      expect(
        tester
            .widget<MenuActions>(find.byKey(BarreLot.cleAutres))
            .actions
            .where((EntreeAction e) => e.destructif),
        hasLength(1),
      );
      await tester.tap(find.byKey(BarreLot.cleAutres));
      await tester.pumpAndSettle();
      expect(find.text(libelleGesteLot(GesteLot.leverPause)), findsOneWidget);
      final double lever = tester
          .getTopLeft(find.text(libelleGesteLot(GesteLot.leverPause)))
          .dy;
      final double refuser = tester
          .getTopLeft(find.text(libelleGesteLot(GesteLot.refuser)))
          .dy;
      expect(lever, lessThan(refuser));
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(PersonnesPage.cleOperationLot(GesteLot.mettreEnPause)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(FeuilleLot.cle), findsOneWidget);
      expect(_port.appelsApercuLot.single.ids.toSet(), <String>{'c1', 'c6'});
      // Rien n'est ecrit avant la validation.
      expect(_port.appelsLot, isEmpty);
    });

    testWidgets('candidats : la page entiere cochee, « Selectionner les N '
        'resultats » n\'est pas offert quand tout tient sur la page ; changer '
        'de filtre retire la selection et le dit', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
      );
      await tester.tap(_caseDe('Farid Essai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.candidatures.selection.page));
      await tester.pumpAndSettle();
      expect(
        find.text(t.admin.candidatures.lot.selectionnees(n: 4)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('candidatures-selection-tous')),
        findsNothing,
      );
      _routeur.go('/admin/personnes?onglet=enseignants&vue=candidats&q=Nora');
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreLot), findsNothing);
      expect(
        find.text(t.admin.candidatures.lot.selectionRetiree),
        findsOneWidget,
      );
    });

    testWidgets('en accueil : seules les lignes dont le serveur annonce un '
        'geste groupable ont une case ; la barre ne propose que ce geste', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=accueil',
      );
      expect(_caseDe('Karim Essai'), findsOneWidget);
      expect(_caseDe('Nora Essai'), findsOneWidget);
      expect(_caseDe('Omar Essai'), findsNothing);
      await tester.tap(_caseDe('Karim Essai'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(PersonnesPage.cleOperationLot(GesteLot.mettreEnPause)),
        findsOneWidget,
      );
      // Rien d'autre : pas de menu « Autres actions » sans autre geste.
      expect(find.byKey(BarreLot.cleAutres), findsNothing);
    });

    testWidgets('telephone : la barre du lot tient sur une rangee (le compte, '
        '« Actions », « Deselectionner ») et laisse la liste lisible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
        taille: const Size(390, 844),
      );
      await tester.tap(_caseDe('Farid Essai'));
      await tester.pumpAndSettle();
      final Finder barre = find.byKey(PersonnesPage.cleBarreLot);
      final Finder actions = find.byKey(BarreLot.cleAutres);
      expect(find.text(t.commun.listes.actions), findsOneWidget);
      // Aucun bouton de geste hors du menu.
      for (final GesteLot g in GesteLot.values) {
        expect(find.byKey(PersonnesPage.cleOperationLot(g)), findsNothing);
      }
      expect(
        tester.getSize(barre).height,
        lessThanOrEqualTo(tester.getSize(actions).height + 2 * AppSpacing.lg),
      );
      // La case cochee reste a l'ecran, au-dessus de la barre.
      expect(
        tester.getBottomLeft(_caseDe('Farid Essai')).dy,
        lessThan(tester.getTopLeft(barre).dy),
      );
      await tester.tap(actions);
      await tester.pumpAndSettle();
      for (final GesteLot g in <GesteLot>[
        GesteLot.ecrire,
        GesteLot.mettreEnPause,
        GesteLot.refuser,
      ]) {
        expect(find.text(libelleGesteLot(g)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ordinateur, 1440 x 900 : la barre du lot laisse au moins six '
        'lignes de la liste visibles', (WidgetTester tester) async {
      const List<String> prenoms = <String>[
        'Adam',
        'Bouchra',
        'Chakib',
        'Dounia',
        'Elias',
        'Fatine',
        'Ghali',
        'Hiba',
        'Ilyas',
        'Jihane',
      ];
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
        lignes: <LigneCandidature>[
          for (final (int i, String prenom) in prenoms.indexed)
            ligneTest(
              id: 'n$i',
              reference: 'CAND-0010$i',
              nom: '$prenom Essai',
            ),
        ],
      );
      await tester.tap(_caseDe('Adam Essai'));
      await tester.pumpAndSettle();
      final double hautBarre = tester
          .getTopLeft(find.byKey(PersonnesPage.cleBarreLot))
          .dy;
      int visibles = 0;
      for (final String prenom in prenoms) {
        final Finder nom = find.text('$prenom Essai');
        if (nom.evaluate().isNotEmpty &&
            tester.getBottomLeft(nom.first).dy < hautBarre) {
          visibles++;
        }
      }
      expect(visibles, greaterThanOrEqualTo(6));
    });

    testWidgets('sans le droit d\'agir en lot : aucune case, aucun faux '
        'controle', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
        capacites: capacitesQuiLit,
      );
      expect(find.byType(CaseACocher), findsNothing);
    });

    testWidgets('candidats : « Trier par » pose le tri dans l\'adresse, le '
        'serveur le recoit, une puce le dit et le retire', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=candidats',
      );
      await tester.tap(find.byKey(PersonnesPage.cleTri));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeuilleTri.cle(TriCandidatures.recente)));
      await tester.pumpAndSettle();
      expect(_adresse, contains('tri=recente'));
      expect(_port.appels.last.tri, TriCandidatures.recente);
      final String puce = t.admin.personnesPage.puce(
        type: t.admin.candidatures.tri.titre,
        valeur: t.admin.candidatures.tri.reception,
      );
      expect(find.widgetWithText(PuceFiltreActif, puce), findsOneWidget);
      // Le dossier ouvert suit la liste dans son ordre.
      await tester.tap(find.byKey(PersonnesPage.cleMenuLigne('CAND-00001')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(t.admin.candidatures.liste.ouvrirDossier).last,
      );
      await tester.pumpAndSettle();
      expect(_dossiers.single, contains('tri=recente'));
      await tester.tap(find.widgetWithText(PuceFiltreActif, puce));
      await tester.pumpAndSettle();
      expect(_adresse, isNot(contains('tri=')));
    });

    testWidgets('en accueil : « Trier par » envoie le tri au serveur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=accueil',
      );
      await tester.tap(find.byKey(PersonnesPage.cleTri));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.candidatures.tri.reception).last);
      await tester.pumpAndSettle();
      expect(_adresse, contains('tri=recente'));
      expect(_trisEnseignants.last, TriEnseignants.recente);
    });

    testWidgets('un enseignant qui a un compte : « Verifier la ville » est '
        'dans le menu de sa ligne ; le serveur la recoit, la page le dit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=accueil',
      );
      await tester.tap(find.byKey(PersonnesPage.cleMenuLigne('CAND-00003')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(t.lieu.verifier(deNom: deDevant('Karim Essai'))).last,
      );
      await tester.pumpAndSettle();
      // La suppression du compte n'est pas dans ce menu (elle reste dans
      // Eleves, Familles et Equipe).
      expect(find.text(t.admin.comptes.retrait.actionLigne), findsNothing);
      expect(_lieux.verifies, <String>['6']);
      expect(
        find.text(t.lieu.villeVerifiee(deNom: deDevant('Karim Essai'))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('comptes', () {
    testWidgets('eleves : deux comptes coches, « Supprimer » part une fois '
        'avec les deux, apres la confirmation ; la page dit le bilan', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
      await tester.tap(_caseDe('Amina Essai'));
      await tester.pumpAndSettle();
      await tester.tap(_caseDe('Chaima Essai'));
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreComptes), findsOneWidget);
      await tester.tap(find.byKey(PersonnesPage.cleSupprimerComptes));
      await tester.pumpAndSettle();
      expect(_retraits.envois, isEmpty);
      await tester.tap(
        find.text(t.admin.comptes.retrait.supprimerSelection(n: 2)).last,
      );
      await tester.pumpAndSettle();
      expect(_retraits.envois.single.toSet(), <String>{'1', '3'});
      expect(find.byKey(cleBilanSuppression), findsOneWidget);
      expect(find.byKey(PersonnesPage.cleBarreComptes), findsNothing);
    });

    testWidgets('150 eleves : la liste se lit par pages ; la case d\'en-tete '
        'retient la seule page affichee, la barre dit ce nombre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=eleves',
        comptes: <CompteAdmin>[
          for (int i = 100; i < 250; i++)
            CompteAdmin(
              profilId: 'e$i',
              identifiant: 'RA-26-9$i',
              prenom: 'Eleve$i',
              nom: 'Essai',
              role: AppRole.student,
              etat: AccountStatus.active,
              inscritLe: DateTime.now().subtract(const Duration(days: 12)),
              accesJusquAu: null,
              foyerId: null,
              piece: EtatPiece.aucune,
              contrats: 0,
              aEnseignant: false,
              enfantsDuFoyer: 0,
              detailsServis: true,
              tranche: TrancheAge.enfant,
            ),
        ],
      );
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is CaseACocher && w.libelle == t.commun.listes.cocherPage,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.admin.comptes.retrait.retenus(n: taillePagePersonnes)),
        findsOneWidget,
      );
      expect(
        find.text(
          t.admin.comptes.retrait.supprimerSelection(n: taillePagePersonnes),
        ),
        findsOneWidget,
      );
      // La page suivante garde la selection et dit ce qui est ailleurs.
      _routeur.go('/admin/personnes?onglet=eleves&page=2');
      await tester.pumpAndSettle();
      expect(
        find.text(
          t.admin.comptes.retrait.retenusPage(n: taillePagePersonnes, p: '0'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('trier garde la selection ; changer d\'onglet la vide', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
      await tester.tap(_caseDe('Amina Essai'));
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreComptes), findsOneWidget);
      _routeur.go('/admin/personnes?onglet=eleves&tri=nom');
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreComptes), findsOneWidget);
      _routeur.go('/admin/personnes?onglet=familles');
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreComptes), findsNothing);
      _routeur.go('/admin/personnes?onglet=eleves');
      await tester.pumpAndSettle();
      expect(find.byKey(PersonnesPage.cleBarreComptes), findsNothing);
      expect(find.byKey(PersonnesPage.cleSupprimerComptes), findsNothing);
    });

    testWidgets('equipe : un compte de la direction n\'a pas de case', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresse: '/admin/personnes?onglet=equipe');
      expect(find.byType(CaseACocher), findsNothing);
    });

    testWidgets('familles : « Trier par » suit le cycle de Comptes '
        '(croissant, inverse, plus de tri), dans l\'adresse et dans la liste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresse: '/admin/personnes?onglet=familles');
      double y(String nom) => tester.getTopLeft(find.text(nom).first).dy;
      Future<void> trier() async {
        await tester.tap(find.byKey(PersonnesPage.cleTri));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.admin.comptes.colonnePersonne).last);
        await tester.pumpAndSettle();
      }

      await trier();
      expect(_adresse, contains('tri=nom'));
      expect(y('Driss Essai'), lessThan(y('Zina Essai')));
      await trier();
      expect(_adresse, contains('tri=-nom'));
      expect(y('Zina Essai'), lessThan(y('Driss Essai')));
      expect(
        find.text(
          t.admin.personnesPage.puce(
            type: t.admin.candidatures.tri.titre,
            valeur: t.admin.personnesPage.triInverse(
              colonne: t.admin.comptes.colonnePersonne,
            ),
          ),
        ),
        findsOneWidget,
      );
      await trier();
      expect(_adresse, isNot(contains('tri=')));
    });

    testWidgets('familles : un compte qui a un dossier d\'enseignant offre '
        '« Ouvrir le dossier » ; fermer ramene a Personnes, meme personne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=familles&element=RA-26-414',
      );
      final Finder ouvrir = find.descendant(
        of: find.byKey(PersonnesPage.cleApercu),
        matching: find.text(t.admin.candidatures.liste.ouvrirDossier),
      );
      expect(ouvrir, findsOneWidget);
      await tester.tap(ouvrir);
      await tester.pumpAndSettle();
      expect(find.text('dossier CAND-00009'), findsOneWidget);
      _routeur.pop();
      await tester.pumpAndSettle();
      expect(_adresse, contains('onglet=familles'));
      expect(_adresse, contains('element=RA-26-414'));
    });
  });
}
