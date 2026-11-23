// PERSONNES-UNE-PAGE, etape (b) : la page unique « Personnes ». Quatre onglets
// avec icone et nombre ; a partir de 1024 points, la liste et l'apercu cote a
// cote (toucher une ligne remplit l'apercu sans quitter la page, la personne
// choisie est dans l'adresse, les fleches passent au voisin) ; en dessous, la
// ligne ouvre l'apercu en feuille ou le dossier. Etats : vide, echec.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart'
    show EtatCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart'
    show DetailCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart'
    show CapacitesCandidatures, LigneCandidature;
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/navigation_dossier.dart'
    show ReglagePasserAuSuivant;
import 'package:rewayah_academy/features/admin_candidature/synthese_tete_dossier.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart'
    show nomAffiche;
import 'package:rewayah_academy/features/admin_comptes/apercu_compte.dart';
import 'package:rewayah_academy/features/admin_personnes/apercu_candidat.dart';
import 'package:rewayah_academy/features/admin_personnes/barre_filtres_personnes.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste, {this.echec = false});

  final List<CompteAdmin> _liste;
  final bool echec;

  @override
  Future<List<CompteAdmin>> comptes() async =>
      echec ? throw StateError('panne') : _liste;
}

/// Les filtres que la page a demandes au serveur, dans l'ordre.
final List<FiltreEnseignants> _filtresDemandes = <FiltreEnseignants>[];

class _Enseignants implements PortEnseignants {
  const _Enseignants(this._lignes, {this.taille = 50});

  final List<LigneEnseignant> _lignes;

  /// La taille des pages du serveur.
  final int taille;

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async {
    _filtresDemandes.add(filtre);
    // Comme le serveur : une phase a la fois, les partis sur demande.
    final List<LigneEnseignant> lignes = <LigneEnseignant>[
      for (final LigneEnseignant l in _lignes)
        if (filtre.phase == null
            ? l.phase != PhaseEnseignant.parti
            : l.phase == filtre.phase)
          l,
    ];
    final int debut = (page - 1) * taille;
    return PageEnseignants(
      lignes: debut >= lignes.length
          ? const <LigneEnseignant>[]
          : lignes.sublist(debut, (debut + taille).clamp(0, lignes.length)),
      total: lignes.length,
      page: page,
      taillePage: taille,
      compteurs: CompteursEnseignants(
        parPhase: <PhaseEnseignant, int>{
          for (final PhaseEnseignant p in PhaseEnseignant.values)
            p: _lignes.where((LigneEnseignant l) => l.phase == p).length,
        },
      ),
    );
  }
}

/// Un serveur qui rend, par phase, des lignes fixees (une meme personne
/// peut y etre dans deux phases).
class _ParPhase implements PortEnseignants {
  const _ParPhase(this._parPhase);

  final Map<PhaseEnseignant, List<LigneEnseignant>> _parPhase;

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async {
    final List<LigneEnseignant> lignes =
        _parPhase[filtre.phase] ?? const <LigneEnseignant>[];
    return PageEnseignants(
      lignes: lignes,
      total: lignes.length,
      page: 1,
      taillePage: 50,
    );
  }
}

class _Pieces implements ServiceValidation {
  const _Pieces(this._lignes);

  final List<DossierAValider> _lignes;

  @override
  Future<List<DossierAValider>> enAttente() async => _lignes;

  @override
  Future<String> apercu(String documentId) => throw UnimplementedError();

  @override
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  }) => throw UnimplementedError();
}

DossierAValider _piece(
  String id,
  String prenom, {
  AppRole role = AppRole.teacher,
  String? reference,
}) => DossierAValider(
  documentId: 'doc-$id',
  profilId: 'p-$id',
  type: null,
  cleObjet: null,
  deposeLe: DateTime.now().subtract(const Duration(days: 3)),
  prenom: prenom,
  nom: 'Essai',
  identifiantImmuable: 'RA-26-77$id',
  role: role,
  candidatureId: reference == null ? null : 'c-$id',
  candidatureReference: reference,
);

final List<DossierAValider> _pieces = <DossierAValider>[
  _piece('1', 'Hind', reference: 'CAND-00009'),
  _piece('2', 'Ilyes'),
  // Une famille : sa piece n'est pas dans l'onglet des enseignants.
  _piece('3', 'Jamila', role: AppRole.guardian),
];

CompteAdmin _compte(
  String id,
  String prenom,
  AppRole role, {
  AccountStatus etat = AccountStatus.active,
}) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-41$id',
  prenom: prenom,
  nom: 'Essai',
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(const Duration(days: 12)),
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
  _compte('5', 'Esma', AppRole.admin),
];

final List<LigneEnseignant> _enseignants = <LigneEnseignant>[
  LigneEnseignant(
    dossier: ligneTest(id: 'c1', reference: 'CAND-00001', nom: 'Farid Essai'),
    phase: PhaseEnseignant.candidat,
    quiAttend: 'direction',
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c2', reference: 'CAND-00002', nom: 'Ghita Essai'),
    phase: PhaseEnseignant.enPoste,
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c3', reference: 'CAND-00003', nom: 'Karim Essai'),
    phase: PhaseEnseignant.accueil,
    quiAttend: 'enseignant',
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c4', reference: 'CAND-00004', nom: 'Lina Essai'),
    phase: PhaseEnseignant.disponible,
  ),
  LigneEnseignant(
    dossier: ligneTest(id: 'c5', reference: 'CAND-00005', nom: 'Mounir Essai'),
    phase: PhaseEnseignant.parti,
  ),
];

/// Le port des candidatures du dernier montage.
late FauxCandidaturesDirection _port;

late GoRouter _routeur;
final List<String> _dossiers = <String>[];

Future<void> _monter(
  WidgetTester tester, {
  required String adresse,
  Size taille = const Size(1440, 900),
  List<CompteAdmin>? comptes,
  bool echec = false,
  CapacitesCandidatures capacites = capacitesQuiLit,
  List<LigneCandidature>? candidatures,
  List<LigneEnseignant>? enseignants,
  int taillePage = 50,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  _dossiers.clear();
  _filtresDemandes.clear();
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
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(
          _Comptes(comptes ?? _comptes, echec: echec),
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portEnseignantsProvider.overrideWithValue(
          _Enseignants(enseignants ?? _enseignants, taille: taillePage),
        ),
        serviceValidationProvider.overrideWithValue(_Pieces(_pieces)),
        portCandidaturesDirectionProvider.overrideWithValue(
          _port = FauxCandidaturesDirection(
            capacitesRendues: capacites,
            taillePage: taillePage,
            lignes:
                candidatures ??
                <LigneCandidature>[
                  for (final LigneEnseignant l in _enseignants) l.dossier,
                ],
            details: <DetailCandidature>[
              for (final LigneCandidature l
                  in candidatures ??
                      <LigneCandidature>[
                        for (final LigneEnseignant e in _enseignants) e.dossier,
                      ])
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
    _routeur.routerDelegate.currentConfiguration.uri.toString();

void main() {
  // Les vraies polices : les cinq vues tiennent en ligne a l'ordinateur (la
  // police de test, aux glyphes carres, les ferait passer en menu).
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('quatre onglets, chacun avec son icone et son nombre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
    expect(find.text('Élèves (3)'), findsOneWidget);
    expect(find.text('Familles (1)'), findsOneWidget);
    // Les partis ne comptent pas dans l'onglet.
    expect(find.text('Enseignants (4)'), findsOneWidget);
    expect(find.text('Direction et équipe (1)'), findsOneWidget);
    // Quatre dessins differents : jamais deux groupes de personnes voisins.
    final List<AppIcon> icones = <AppIcon>[
      for (final OngletPersonnes o in OngletPersonnes.values)
        PersonnesPage.iconeOnglet(o),
    ];
    expect(icones.map((AppIcon i) => i.repos.codePoint).toSet(), hasLength(4));
    expect(icones, isNot(contains(AppIcons.eleves)));
    expect(icones, isNot(contains(AppIcons.foyer)));
    for (final AppIcon i in icones) {
      expect(
        find.descendant(
          of: find.byKey(PersonnesPage.cleOnglets),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Icon && (w.icon == i.repos || w.icon == i.actif),
          ),
        ),
        findsWidgets,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinateur : toucher une famille remplit l\'apercu, sans '
      'quitter la page ; la personne choisie est dans l\'adresse (la ligne '
      'd\'un eleve, elle, ouvre sa fiche : FICHE-ELEVE-DIRECTION)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=familles');
    expect(find.text(t.admin.personnesPage.apercuVide), findsOneWidget);

    await tester.tap(find.text('Driss Essai').first);
    await tester.pumpAndSettle();

    expect(_adresse, contains('element=RA-26-414'));
    final Finder apercu = find.byKey(PersonnesPage.cleApercu);
    expect(
      find.descendant(
        of: apercu,
        matching: find.text(t.admin.comptes.colonneElevesRattaches),
      ),
      findsOneWidget,
    );
    // Aucune feuille : l'apercu est dans la page.
    expect(find.byKey(cleApercuCompte), findsNothing);
  });

  testWidgets('ordinateur : recharger sur une adresse qui nomme une personne '
      'rend le meme apercu ; les fleches passent au voisin', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=eleves&element=RA-26-411',
    );
    final Finder apercu = find.byKey(PersonnesPage.cleApercu);
    expect(
      find.descendant(of: apercu, matching: find.text('Amina Essai')),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_adresse, contains('element=RA-26-412'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_adresse, contains('element=RA-26-411'));
  });

  testWidgets('ordinateur : un enseignant choisi montre l\'apercu de son '
      'dossier, et « Ouvrir le dossier » empile le dossier complet', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=enseignants');
    await tester.tap(find.text('Farid Essai').first);
    await tester.pumpAndSettle();

    expect(_adresse, contains('element=CAND-00001'));
    // La synthese du dossier complet, en tete ; le pays ; aucun geste sans
    // le droit de decider.
    expect(find.byKey(SyntheseTeteDossier.cle), findsOneWidget);
    expect(find.text(t.recrutement.dossier3.tete.anciennete), findsOneWidget);
    expect(find.text(t.com.messages.apercu.pays), findsOneWidget);
    expect(find.byKey(ApercuCandidatPersonnes.cleGestePrincipal), findsNothing);
    expect(find.byKey(ApercuCandidatPersonnes.cleComplement), findsNothing);
    expect(find.byKey(ApercuCandidatPersonnes.cleEcrire), findsNothing);
    await tester.tap(find.byKey(ApercuCandidatPersonnes.cleDossier));
    await tester.pumpAndSettle();
    // Le dossier recoit la file de la vue : le suivant y suit la liste.
    expect(_dossiers, <String>[
      '/admin/personnes/candidatures/CAND-00001?vue=candidats&depuis=liste',
    ]);
  });

  testWidgets('ordinateur : avec le droit de decider, l\'apercu offre le '
      'prochain geste (seul bouton plein), « Demander un complement » et '
      '« Ecrire » ; le geste ouvre la feuille de la fiche', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=enseignants&element=CAND-00001',
      capacites: capacitesGestes,
    );
    expect(
      find.byKey(ApercuCandidatPersonnes.cleGestePrincipal),
      findsOneWidget,
    );
    expect(find.byKey(ApercuCandidatPersonnes.cleComplement), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);

    await tester.tap(find.byKey(ApercuCandidatPersonnes.cleComplement));
    await tester.pumpAndSettle();
    expect(find.byType(FeuilleGeste), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinateur : la barre precedent / suivant passe a la personne '
      'voisine ; au bout de la liste, la fleche disparait', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=enseignants&element=CAND-00001',
    );
    final Finder barre = find.byKey(PersonnesPage.cleVoisins);
    expect(
      find.descendant(of: barre, matching: find.text('1 sur 5')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(t.admin.personnesPage.precedente),
      findsNothing,
    );
    await tester.tap(find.bySemanticsLabel(t.admin.personnesPage.suivante));
    await tester.pumpAndSettle();
    expect(_adresse, contains('element=CAND-00002'));
    expect(
      find.descendant(of: barre, matching: find.text('2 sur 5')),
      findsOneWidget,
    );
    _routeur.go(
      '/admin/personnes?onglet=enseignants&vue=candidats&element=CAND-00005',
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(t.admin.personnesPage.suivante), findsNothing);
  });

  testWidgets('telephone : la ligne d\'un eleve ouvre l\'apercu en feuille, '
      'celle d\'un enseignant son dossier', (WidgetTester tester) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=eleves',
      taille: const Size(390, 844),
    );
    await tester.tap(find.text('Amina Essai').first);
    await tester.pumpAndSettle();
    expect(find.byKey(cleApercuCompte), findsOneWidget);
    expect(find.byKey(PersonnesPage.cleApercu), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    _routeur.go('/admin/personnes?onglet=enseignants');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghita Essai').first);
    await tester.pumpAndSettle();
    expect(_dossiers, <String>[
      '/admin/personnes/candidatures/CAND-00002?vue=candidats&depuis=liste',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('telephone : le nom de l\'onglet ouvert et son nombre sont '
      'ecrits en toutes lettres sous les onglets', (WidgetTester tester) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=familles',
      taille: const Size(390, 844),
    );
    final Text nom = tester.widget(find.byKey(PersonnesPage.cleNomOnglet));
    expect(nom.data, 'Familles (1)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinateur : pas de nom d\'onglet en double sous les onglets', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=familles');
    expect(find.byKey(PersonnesPage.cleNomOnglet), findsNothing);
  });

  testWidgets('changer d\'onglet change l\'adresse et oublie la personne '
      'choisie', (WidgetTester tester) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=eleves&element=RA-26-411',
    );
    await tester.tap(find.text('Familles (1)'));
    await tester.pumpAndSettle();
    expect(_adresse, '/admin/personnes?onglet=familles');
    expect(find.text('Driss Essai'), findsWidgets);
  });

  group('filtre unique et recherche (etape c)', () {
    Future<void> filtrerPar(
      WidgetTester tester,
      String type,
      String valeur,
    ) async {
      await tester.tap(find.byKey(BarreFiltresPersonnes.cleFiltrer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(type).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(valeur).last);
      await tester.pumpAndSettle();
    }

    String compteur(WidgetTester tester) => tester
        .widget<Text>(find.byKey(BarreFiltresPersonnes.cleCompteur))
        .data!;

    testWidgets('« Filtrer par », le type, la valeur : une puce, le compteur, '
        'le filtre dans l\'adresse ; la puce se retire', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=eleves',
        comptes: <CompteAdmin>[
          ..._comptes,
          _compte('9', 'Zahra', AppRole.student, etat: AccountStatus.disabled),
        ],
      );
      expect(compteur(tester), '4 sur 4');

      await filtrerPar(tester, 'État', 'État\u00a0: Suspendu');

      expect(_adresse, contains('etat=suspendu'));
      expect(compteur(tester), '1 sur 4');
      expect(find.text('Zahra Essai'), findsWidgets);
      expect(find.text('Amina Essai'), findsNothing);
      // L'onglet garde le nombre de la liste entiere.
      expect(find.text('Élèves (4)'), findsOneWidget);
      // La puce dit le type et la valeur, et se retire.
      final Finder puce = find.byType(PuceFiltreActif);
      expect(puce, findsOneWidget);
      await tester.tap(puce);
      await tester.pumpAndSettle();
      expect(_adresse, isNot(contains('etat=')));
      expect(compteur(tester), '4 sur 4');
      expect(tester.takeException(), isNull);
    });

    testWidgets('la recherche filtre la liste, vit dans l\'adresse, et « Tout '
        'effacer » retire filtre et recherche', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=eleves&etat=actif',
      );
      await tester.enterText(
        find.byKey(BarreFiltresPersonnes.cleRecherche),
        'bil',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(_adresse, contains('q=bil'));
      expect(_adresse, contains('etat=actif'));
      expect(compteur(tester), '1 sur 3');
      expect(find.text('Bilal Essai'), findsWidgets);
      expect(find.text('Amina Essai'), findsNothing);
      // La saisie n'a pas ete perdue par la relecture.
      expect(find.text('bil'), findsOneWidget);

      await tester.tap(find.byKey(FiltresActifs.cleToutEffacer));
      await tester.pumpAndSettle();
      expect(_adresse, isNot(contains('q=')));
      expect(_adresse, isNot(contains('etat=')));
      expect(compteur(tester), '3 sur 3');
      expect(find.text('bil'), findsNothing);
    });

    testWidgets(
      'aucun resultat : une phrase qui dit quoi faire, les onglets et '
      'la barre restent',
      (WidgetTester tester) async {
        await _monter(
          tester,
          adresse: '/admin/personnes?onglet=eleves&q=introuvable',
        );
        expect(find.text(t.admin.personnesPage.aucunResultat), findsOneWidget);
        expect(find.byKey(PersonnesPage.cleOnglets), findsOneWidget);
        expect(find.byKey(BarreFiltresPersonnes.cleFiltrer), findsOneWidget);
        expect(compteur(tester), '0 sur 3');
      },
    );

    testWidgets('enseignants actifs : la phase et la recherche sont demandees '
        'au serveur', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=actifs&phase=en_poste&q=ghi',
      );
      expect(
        _filtresDemandes.any(
          (FiltreEnseignants f) =>
              f.phase == PhaseEnseignant.enPoste && f.recherche == 'ghi',
        ),
        isTrue,
      );
      expect(find.byType(PuceFiltreActif), findsOneWidget);
    });

    testWidgets('une valeur inconnue dans l\'adresse ne pose aucun filtre ; '
        'changer d\'onglet oublie les filtres', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=eleves&etat=nimporte&age=enfant',
      );
      expect(find.byType(PuceFiltreActif), findsOneWidget);
      await tester.tap(find.text('Familles (1)'));
      await tester.pumpAndSettle();
      expect(_adresse, isNot(contains('age=')));
      expect(find.byType(PuceFiltreActif), findsNothing);
    });

    testWidgets('telephone : la barre tient, le filtre se pose', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=eleves',
        taille: const Size(390, 844),
      );
      await filtrerPar(tester, 'Âge', 'Âge\u00a0: Enfant');
      expect(_adresse, contains('age=enfant'));
      expect(compteur(tester), '3 sur 3');
      expect(tester.takeException(), isNull);
    });
  });

  group('les vues de l\'onglet des enseignants (etape d)', () {
    String compteur(WidgetTester tester) => tester
        .widget<Text>(find.byKey(BarreFiltresPersonnes.cleCompteur))
        .data!;

    testWidgets('cinq vues, chacune avec son nombre ; « Candidats » par '
        'defaut ; les autres onglets n\'ont pas ce selecteur', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresse: '/admin/personnes?onglet=enseignants');
      final Finder vues = find.byKey(PersonnesPage.cleVues);
      for (final String libelle in <String>[
        'Candidats (5)',
        'En accueil (1)',
        'Actifs (2)',
        'Partis (1)',
        'Pièces à vérifier (2)',
      ]) {
        expect(
          find.descendant(of: vues, matching: find.text(libelle)),
          findsOneWidget,
          reason: libelle,
        );
      }
      // La vue par defaut lit la file des candidatures.
      expect(_port.appels, isNotEmpty);
      expect(find.text('Farid Essai'), findsWidgets);
      expect(compteur(tester), '5 sur 5');

      _routeur.go('/admin/personnes?onglet=eleves');
      await tester.pumpAndSettle();
      expect(vues, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('changer de vue change l\'adresse, oublie les filtres et la '
        'personne ; chaque vue demande sa phase au serveur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse:
            '/admin/personnes?onglet=enseignants&vue=candidats&etat=enExamen'
            '&element=CAND-00001',
      );
      expect(find.byType(PuceFiltreActif), findsOneWidget);

      await tester.tap(find.text('En accueil (1)'));
      await tester.pumpAndSettle();
      expect(_adresse, '/admin/personnes?onglet=enseignants&vue=accueil');
      expect(find.byType(PuceFiltreActif), findsNothing);
      expect(find.text('Karim Essai'), findsWidgets);
      expect(find.text('Farid Essai'), findsNothing);
      expect(
        _filtresDemandes.any(
          (FiltreEnseignants f) => f.phase == PhaseEnseignant.accueil,
        ),
        isTrue,
      );
      // Une vue sans type de filtre n'a pas de bouton « Filtrer par ».
      expect(find.byKey(BarreFiltresPersonnes.cleFiltrer), findsNothing);
      expect(compteur(tester), '1 sur 1');

      await tester.tap(find.text('Partis (1)'));
      await tester.pumpAndSettle();
      expect(_adresse, '/admin/personnes?onglet=enseignants&vue=partis');
      expect(find.text('Mounir Essai'), findsWidgets);
      expect(
        _filtresDemandes.any(
          (FiltreEnseignants f) => f.phase == PhaseEnseignant.parti && f.partis,
        ),
        isTrue,
      );
    });

    testWidgets('« Actifs » rassemble ses phases, sans candidat ni accueil ; '
        'le dossier recoit la file de la phase de la personne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=actifs',
        taille: const Size(390, 844),
      );
      expect(find.text('Ghita Essai'), findsWidgets);
      expect(find.text('Lina Essai'), findsWidgets);
      expect(find.text('Farid Essai'), findsNothing);
      expect(find.text('Karim Essai'), findsNothing);
      expect(find.text('Mounir Essai'), findsNothing);
      expect(compteur(tester), '2 sur 2');

      await tester.tap(find.text('Lina Essai').first);
      await tester.pumpAndSettle();
      expect(_dossiers, <String>[
        '/admin/personnes/candidatures/CAND-00004'
            '?file=enseignants&vue=actifs&phase_file=disponible&depuis=liste',
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Pieces a verifier » : les pieces des enseignants ; la '
        'verification s\'ouvre dans le dossier de candidature quand il '
        'existe, sinon dans « Dossiers a valider »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=pieces',
      );
      expect(find.text('Hind Essai'), findsWidgets);
      expect(find.text('Ilyes Essai'), findsWidgets);
      expect(find.text('Jamila Essai'), findsNothing);
      expect(compteur(tester), '2 sur 2');

      await tester.tap(find.text('Hind Essai').first);
      await tester.pumpAndSettle();
      expect(_adresse, contains('element=RA-26-771'));
      await tester.tap(find.byKey(PersonnesPage.cleVerifierPiece));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ilyes Essai').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PersonnesPage.cleVerifierPiece));
      await tester.pumpAndSettle();
      expect(_dossiers, <String>[
        '/admin/personnes/candidatures/CAND-00009',
        Routes.adminPersonnesDossiers,
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('candidats : « Filtrer par », la famille, le type, la '
        'valeur ; le filtre part au serveur avec la cle de l\'ancienne liste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresse: '/admin/personnes?onglet=enseignants');
      await tester.tap(find.byKey(BarreFiltresPersonnes.cleFiltrer));
      await tester.pumpAndSettle();
      // Premier niveau : les familles, jamais les 26 types d'un coup.
      expect(
        find.text(t.admin.personnesPage.familleEnseignement),
        findsOneWidget,
      );
      expect(find.text(t.recrutement.file.ijaza), findsNothing);
      await tester.tap(find.text(t.admin.personnesPage.familleEnseignement));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.recrutement.file.langue).last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(t.recrutement.file.langue).at(1));
      await tester.pumpAndSettle();

      expect(_adresse, contains('langue='));
      expect(_adresse, contains('vue=candidats'));
      expect(find.byType(PuceFiltreActif), findsOneWidget);
      expect(_port.appels.last.filtre.langueExplication, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('candidats : une puce posee reduit la liste ET le compteur ; '
        'le compteur dit le total filtre du serveur, pas la longueur de la '
        'page ; la retirer rend tout', (WidgetTester tester) async {
      // Sept candidatures : quatre « a completer », trois « en examen » ; le
      // serveur rend des pages de deux.
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants',
        taillePage: 2,
        candidatures: <LigneCandidature>[
          for (int i = 1; i <= 7; i++)
            ligneTest(
              id: 'k$i',
              reference: 'CAND-0010$i',
              nom: 'Candidat$i Essai',
              etat: i <= 4
                  ? EtatCandidature.aCompleter
                  : EtatCandidature.enExamen,
              derniereActivite: DateTime(2026, 11, 20 - i),
            ),
        ],
      );
      // Sans filtre : sept, dont deux a l'ecran.
      expect(compteur(tester), '7 sur 7');
      expect(find.text('Candidat1 Essai'), findsWidgets);

      await tester.tap(find.byKey(BarreFiltresPersonnes.cleFiltrer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.personnesPage.familleEtape));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.candidatures.filtres.etat).last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining(t.admin.candidatures.etats.enExamen).last,
      );
      await tester.pumpAndSettle();

      // Le filtre est parti au serveur ; la liste et le compteur le suivent.
      expect(_adresse, contains('etat=enExamen'));
      expect(_port.appels.last.filtre.etat, EtatCandidature.enExamen);
      expect(find.byType(PuceFiltreActif), findsOneWidget);
      // Trois dossiers passent le filtre (total du serveur), deux sont sur
      // la page : le compteur dit trois, sur les sept de la vue.
      expect(compteur(tester), '3 sur 7');
      expect(find.text('Candidat5 Essai'), findsWidgets);
      expect(find.text('Candidat6 Essai'), findsWidgets);
      for (int i = 1; i <= 4; i++) {
        expect(find.text('Candidat$i Essai'), findsNothing);
      }
      // La vue garde son nombre entier.
      expect(find.text('Candidats (7)'), findsOneWidget);

      await tester.tap(find.byType(PuceFiltreActif));
      await tester.pumpAndSettle();
      expect(_adresse, isNot(contains('etat=')));
      expect(compteur(tester), '7 sur 7');
      expect(find.text('Candidat1 Essai'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    /// Les references des lignes affichees, dans l'ordre.
    List<String> references(WidgetTester tester) => <String>[
      for (final Element e in find.byType(Text).evaluate())
        if ((e.widget as Text).data case final String d
            when d.startsWith('Personne') && d.endsWith('Essai'))
          d,
    ];

    testWidgets('aucune personne deux fois : la page suivante des candidats '
        'remplace la precedente', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants',
        taille: const Size(390, 2400),
        taillePage: 3,
        candidatures: <LigneCandidature>[
          for (int i = 1; i <= 7; i++)
            ligneTest(
              id: 'k$i',
              reference: 'CAND-0010$i',
              nom: 'Personne$i Essai',
              derniereActivite: DateTime(2026, 11, 20 - i),
            ),
        ],
      );
      final List<String> premiere = references(tester);
      expect(premiere, hasLength(3));
      expect(premiere.toSet(), hasLength(3));

      _routeur.go('/admin/personnes?onglet=enseignants&vue=candidats&page=2');
      await tester.pumpAndSettle();
      final List<String> seconde = references(tester);
      expect(seconde, hasLength(3));
      expect(seconde.toSet(), hasLength(3));
      // Aucune ligne de la premiere page ne reste ni ne revient.
      expect(seconde.toSet().intersection(premiere.toSet()), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucune personne deux fois : « Actifs » lit chaque phase page '
        'apres page et les met bout a bout', (WidgetTester tester) async {
      const List<PhaseEnseignant> phases = <PhaseEnseignant>[
        PhaseEnseignant.enPoste,
        PhaseEnseignant.enPoste,
        PhaseEnseignant.enPoste,
        PhaseEnseignant.disponible,
        PhaseEnseignant.disponible,
        PhaseEnseignant.absent,
        PhaseEnseignant.candidat,
      ];
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=actifs',
        taille: const Size(390, 2400),
        // Le serveur rend des pages de deux : trois en poste = deux pages.
        taillePage: 2,
        enseignants: <LigneEnseignant>[
          for (final (int i, PhaseEnseignant p) in phases.indexed)
            LigneEnseignant(
              dossier: ligneTest(
                id: 'a$i',
                reference: 'CAND-0020$i',
                nom: 'Personne$i Essai',
              ),
              phase: p,
            ),
        ],
      );
      final List<String> lues = references(tester);
      // Les six actifs, chacun une fois ; le candidat n'y est pas.
      expect(lues, hasLength(6));
      expect(lues.toSet(), hasLength(6));
      expect(lues, isNot(contains('Personne6 Essai')));
      expect(compteur(tester), '6 sur 6');
      expect(tester.takeException(), isNull);
    });

    test('« Actifs » : une personne rendue par deux phases (elle a change '
        'de phase entre deux lectures) n\'est gardee qu\'une fois, la '
        'derniere lue', () async {
      LigneEnseignant ligne(String ref, PhaseEnseignant p) => LigneEnseignant(
        dossier: ligneTest(id: ref, reference: ref, nom: 'Personne $ref'),
        phase: p,
      );
      final ProviderContainer conteneur = ProviderContainer(
        overrides: [
          portEnseignantsProvider.overrideWithValue(
            _ParPhase(<PhaseEnseignant, List<LigneEnseignant>>{
              // Lue « en poste », puis « en pause » un instant plus tard.
              PhaseEnseignant.enPoste: <LigneEnseignant>[
                ligne('CAND-00301', PhaseEnseignant.enPoste),
                ligne('CAND-00302', PhaseEnseignant.enPoste),
              ],
              PhaseEnseignant.pause: <LigneEnseignant>[
                ligne('CAND-00301', PhaseEnseignant.pause),
              ],
            }),
          ),
        ],
      );
      addTearDown(conteneur.dispose);
      final PageEnseignants page = await conteneur.read(
        enseignantsActifsProvider((recherche: '', tri: TriEnseignants.activite))
            .future,
      );
      expect(
        page.lignes.map((LigneEnseignant l) => l.dossier.reference).toList(),
        <String>['CAND-00302', 'CAND-00301'],
      );
      expect(page.lignes.last.phase, PhaseEnseignant.pause);
      expect(page.total, 2);
    });

    testWidgets('telephone : les vues passent en menu deroulant, rien ne '
        'deborde', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&vue=accueil',
        taille: const Size(390, 844),
      );
      // La vue ouverte est ecrite ; les autres sont dans le menu.
      expect(find.text('En accueil (1)'), findsOneWidget);
      expect(find.text('Partis (1)'), findsNothing);
      await tester.tap(find.text('En accueil (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partis (1)').last);
      await tester.pumpAndSettle();
      expect(_adresse, '/admin/personnes?onglet=enseignants&vue=partis');
      expect(tester.takeException(), isNull);
    });

    testWidgets('apercu : apres une decision, la personne suivante s\'ouvre '
        'seule (reglage actif) ; « Rester » l\'empeche', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&element=CAND-00001',
        capacites: capacitesGestes,
      );
      Future<void> decider() async {
        await tester.tap(find.byKey(ApercuCandidatPersonnes.cleGestePrincipal));
        await tester.pumpAndSettle();
        expect(find.byType(FeuilleGeste), findsOneWidget);
        // Le geste que l'etat du dossier propose : confirmer le moyen de
        // versement (un choix, puis le bouton).
        await tester.tap(
          find.descendant(
            of: find.byType(FeuilleGeste),
            matching: find.text(t.admin.candidatures.moyens.virement),
          ),
        );
        await tester.pump();
        await tester.ensureVisible(find.byKey(FeuilleGeste.cleValider));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(FeuilleGeste.cleValider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
      }

      await decider();
      expect(_port.appelsGeste, hasLength(1));
      // La phrase le dit, la personne n'a pas encore change.
      expect(
        find.text(t.recrutement.suivant.decisionEnregistree),
        findsOneWidget,
      );
      expect(_adresse, contains('element=CAND-00001'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(_adresse, contains('element=CAND-00002'));

      // « Rester sur ce dossier » : la decision est gardee, pas de passage.
      await decider();
      expect(_port.appelsGeste, hasLength(2));
      await tester.tap(find.byKey(ApercuCandidatPersonnes.cleRester));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(_adresse, contains('element=CAND-00002'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('apercu : le reglage « Passer au suivant » est celui du '
        'dossier ; il n\'est propose que s\'il y a une personne suivante', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&element=CAND-00001',
      );
      expect(find.byType(ReglagePasserAuSuivant), findsOneWidget);
      _routeur.go(
        '/admin/personnes?onglet=enseignants&vue=candidats&element=CAND-00005',
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReglagePasserAuSuivant), findsNothing);
    });
  });

  testWidgets('vide : une phrase, pas une liste', (WidgetTester tester) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=familles',
      comptes: <CompteAdmin>[_compte('1', 'Amina', AppRole.student)],
    );
    expect(find.text(t.admin.comptes.videFamilles), findsOneWidget);
  });

  testWidgets('echec : une phrase vraie et « Réessayer »', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=eleves',
      echec: true,
    );
    expect(find.text(t.admin.comptes.erreur), findsOneWidget);
    expect(find.text(t.commun.etats.actions.reessayer), findsOneWidget);
  });
}
