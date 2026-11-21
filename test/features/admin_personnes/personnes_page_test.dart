// PERSONNES-UNE-PAGE, etape (b) : la page unique « Personnes ». Quatre onglets
// avec icone et nombre ; a partir de 1024 points, la liste et l'apercu cote a
// cote (toucher une ligne remplit l'apercu sans quitter la page, la personne
// choisie est dans l'adresse, les fleches passent au voisin) ; en dessous, la
// ligne ouvre l'apercu en feuille ou le dossier. Etats : vide, echec.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart'
    show DetailCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart'
    show CapacitesCandidatures, LigneCandidature;
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/synthese_tete_dossier.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart'
    show nomAffiche;
import 'package:rewayah_academy/features/admin_comptes/apercu_compte.dart';
import 'package:rewayah_academy/features/admin_personnes/apercu_candidat.dart';
import 'package:rewayah_academy/features/admin_personnes/barre_filtres_personnes.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

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
  const _Enseignants(this._lignes);

  final List<LigneEnseignant> _lignes;

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async {
    _filtresDemandes.add(filtre);
    return _page();
  }

  PageEnseignants _page() => PageEnseignants(
    lignes: _lignes,
    total: _lignes.length,
    page: 1,
    taillePage: 50,
  );
}

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
];

late GoRouter _routeur;
final List<String> _dossiers = <String>[];

Future<void> _monter(
  WidgetTester tester, {
  required String adresse,
  Size taille = const Size(1440, 900),
  List<CompteAdmin>? comptes,
  bool echec = false,
  CapacitesCandidatures capacites = capacitesQuiLit,
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
        portEnseignantsProvider.overrideWithValue(_Enseignants(_enseignants)),
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            capacitesRendues: capacites,
            lignes: <LigneCandidature>[
              for (final LigneEnseignant l in _enseignants) l.dossier,
            ],
            details: <DetailCandidature>[
              for (final LigneEnseignant l in _enseignants)
                detailTest(
                  id: l.dossier.id,
                  reference: l.dossier.reference,
                  nom: nomAffiche(l.dossier),
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
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('quatre onglets, chacun avec son icone et son nombre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
    expect(find.text('Élèves (3)'), findsOneWidget);
    expect(find.text('Familles (1)'), findsOneWidget);
    expect(find.text('Enseignants (2)'), findsOneWidget);
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

  testWidgets('ordinateur : toucher un eleve remplit l\'apercu, sans quitter '
      'la page ; la personne choisie est dans l\'adresse', (
    WidgetTester tester,
  ) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
    expect(find.text(t.admin.personnesPage.apercuVide), findsOneWidget);

    await tester.tap(find.text('Bilal Essai').first);
    await tester.pumpAndSettle();

    expect(_adresse, contains('element=RA-26-412'));
    final Finder apercu = find.byKey(PersonnesPage.cleApercu);
    expect(
      find.descendant(of: apercu, matching: find.text('Enfant')),
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
    expect(_dossiers, <String>['/admin/personnes/candidatures/CAND-00001']);
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
      find.descendant(of: barre, matching: find.text('1 sur 2')),
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
      find.descendant(of: barre, matching: find.text('2 sur 2')),
      findsOneWidget,
    );
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
    expect(_dossiers, <String>['/admin/personnes/candidatures/CAND-00002']);
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

    testWidgets('enseignants : la phase et la recherche sont demandees au '
        'serveur', (WidgetTester tester) async {
      await _monter(
        tester,
        adresse: '/admin/personnes?onglet=enseignants&phase=accueil&q=far',
      );
      expect(
        _filtresDemandes.any(
          (FiltreEnseignants f) =>
              f.phase == PhaseEnseignant.accueil && f.recherche == 'far',
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
