// LISTES-3 : la page Comptes comme liste d'administration (recherche, roles en
// acces direct, filtres actifs, table dense triable et paginee, adresse).
//
// Donnees fictives en `@test.invalid` : aucune personne reelle.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/pied_de_liste.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_comptes/liste_comptes.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';
import '../support/rangee_plus.dart';

class _Service implements ServiceComptes {
  _Service(this._comptes, {this.attente});

  final List<CompteAdmin> _comptes;

  /// Une lecture qui ne rend jamais : l'etat de chargement.
  final Completer<List<CompteAdmin>>? attente;

  @override
  Future<List<CompteAdmin>> comptes() async =>
      attente == null ? _comptes : attente!.future;
}

CompteAdmin _c(
  String id, {
  String? prenom,
  String? nom,
  AppRole? role = AppRole.student,
  AccountStatus etat = AccountStatus.active,
  EtatPiece piece = EtatPiece.aucune,
  int jours = 10,
  int contrats = 1,
  bool aEnseignant = false,
  int enfants = 0,
  DateTime? accesJusquAu,
  String? pays,
}) => CompteAdmin(
  profilId: 'p-$id',
  identifiant: id,
  prenom: prenom,
  nom: nom,
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(Duration(days: jours)),
  accesJusquAu: accesJusquAu,
  foyerId: null,
  piece: piece,
  contrats: contrats,
  aEnseignant: aEnseignant,
  enfantsDuFoyer: enfants,
  paysEnseignant: pays,
);

/// Un petit annuaire fictif : deux eleves, deux tuteurs, deux enseignants.
List<CompteAdmin> _annuaire() => <CompteAdmin>[
  _c(
    'GUARDIAN-MS-000003',
    prenom: 'Mariam',
    nom: 'Sow',
    role: AppRole.guardian,
    etat: AccountStatus.pendingKyc,
    jours: 3,
    enfants: 2,
  ),
  _c(
    'TEACHER-AS-000001',
    prenom: 'Aicha',
    nom: 'Barry',
    role: AppRole.teacher,
    etat: AccountStatus.pendingKyc,
    jours: 7,
    contrats: 2,
    pays: 'SN',
  ),
  _c(
    'STUDENT-LD-000001',
    prenom: 'Lina',
    nom: 'Diallo',
    aEnseignant: true,
    jours: 30,
  ),
  _c('STUDENT-YK-000002', prenom: 'Yacine', nom: 'Kane', jours: 2),
  _c(
    'GUARDIAN-FD-000004',
    prenom: 'Fatou',
    nom: 'Diop',
    role: AppRole.guardian,
    jours: 60,
    enfants: 1,
  ),
  _c(
    'TEACHER-OB-000005',
    prenom: 'Omar',
    nom: 'Ba',
    role: AppRole.teacher,
    piece: EtatPiece.aVerifier,
    jours: 12,
    contrats: 2,
    pays: 'MA',
  ),
];

void main() {
  setUpAll(() async {
    // L'arabe est une bibliotheque differee : chargee une fois, hors d'un test.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('FiltreComptes : la logique de la liste lue', () {
    // Un instant apres la fabrication des jeux : les jours pleins sont ceux voulus.
    final DateTime maintenant = DateTime.now().add(const Duration(minutes: 1));

    test(
      'la recherche ignore accents, casse et tirets, sur nom et identifiant',
      () {
        final List<CompteAdmin> liste = <CompteAdmin>[
          _c('STUDENT-EB-000009', prenom: 'Élodie', nom: 'Ba'),
          ..._annuaire(),
        ];
        List<String> ids(String q) =>
            FiltreComptes(recherche: q)
                .appliquer(liste, maintenant)
                .map((CompteAdmin c) => c.identifiant)
                .toList();
        expect(ids('elodie'), <String>['STUDENT-EB-000009']);
        expect(ids('ÉLODIE'), <String>['STUDENT-EB-000009']);
        expect(ids('student-eb'), <String>['STUDENT-EB-000009']);
        expect(ids('personne-inconnue'), isEmpty);
      },
    );

    test(
      'sans tri : ce qui attend une decision d abord, puis l ordre de la base',
      () {
        final List<String> ids = const FiltreComptes()
            .appliquer(_annuaire(), maintenant)
            .map((CompteAdmin c) => c.identifiant)
            .toList();
        expect(ids.first, 'TEACHER-AS-000001');
        expect(ids.sublist(1), <String>[
          'GUARDIAN-MS-000003',
          'STUDENT-LD-000001',
          'STUDENT-YK-000002',
          'GUARDIAN-FD-000004',
          'TEACHER-OB-000005',
        ]);
      },
    );

    test('tri par etat : l\'ordre alphabetique des mots affiches (R-9)', () {
      String mot(EtatAffiche e) => switch (e) {
        EtatAffiche.attente => 'Zebre',
        EtatAffiche.actif => 'Abeille',
        _ => 'Mouton',
      };
      final List<String> etats =
          const FiltreComptes(tri: TriComptes(ChampTriComptes.etat, true))
              .appliquer(_annuaire(), maintenant, libelleEtat: mot)
              .map((CompteAdmin c) => mot(EtatAffiche.de(c)))
              .toList();
      expect(etats, <String>[...etats]..sort());
    });

    test('tri par nom, croissant puis decroissant ; stable a egalite', () {
      List<String> noms(TriComptes tri) =>
          FiltreComptes(tri: tri)
              .appliquer(_annuaire(), maintenant)
              .map((CompteAdmin c) => c.prenom!)
              .toList();
      expect(noms(const TriComptes(ChampTriComptes.nom, true)), <String>[
        'Aicha',
        'Fatou',
        'Lina',
        'Mariam',
        'Omar',
        'Yacine',
      ]);
      expect(
        noms(const TriComptes(ChampTriComptes.nom, false)).first,
        'Yacine',
      );
    });

    test('tri par anciennete : la valeur de la colonne, en jours', () {
      final List<int> jours =
          const FiltreComptes(tri: TriComptes(ChampTriComptes.inscrit, true))
              .appliquer(_annuaire(), maintenant)
              .map((CompteAdmin c) => c.joursDAttente(maintenant))
              .toList();
      expect(jours, <int>[2, 3, 7, 12, 30, 60]);
    });

    test('le tri d un en-tete : croissant, decroissant, puis plus de tri', () {
      TriComptes? t = TriComptes.suivant(null, ChampTriComptes.nom);
      expect(t!.croissant, isTrue);
      t = TriComptes.suivant(t, ChampTriComptes.nom);
      expect(t!.croissant, isFalse);
      expect(TriComptes.suivant(t, ChampTriComptes.nom), isNull);
      // Une autre colonne repart du croissant.
      expect(
        TriComptes.suivant(t, ChampTriComptes.etat)!.champ,
        ChampTriComptes.etat,
      );
    });

    test('« Tout effacer » garde le role et le tri', () {
      const FiltreComptes f = FiltreComptes(
        role: AppRole.teacher,
        etat: EtatAffiche.attente,
        echus: true,
        recherche: 'aicha',
        tri: TriComptes(ChampTriComptes.nom, true),
      );
      final FiltreComptes e = f.efface;
      expect(e.role, AppRole.teacher);
      expect(e.etat, isNull);
      expect(e.echus, isFalse);
      expect(e.recherche, isEmpty);
      expect(e.tri, isNotNull);
      expect(e.estVide, isFalse); // le role reste
      expect(const FiltreComptes().estVide, isTrue);
    });
  });

  group('La page : bureau 1440 x 900', () {
    Future<void> monter(
      WidgetTester tester,
      List<CompteAdmin> comptes, {
      Size taille = const Size(1440, 900),
      double echelle = 1,
      Map<String, String> requete = const <String, String>{},
      Completer<List<CompteAdmin>>? attente,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = taille;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          MediaQuery(
            data: MediaQueryData(
              size: taille,
              textScaler: TextScaler.linear(echelle),
            ),
            child: ComptesPage(requete: requete),
          ),
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(
              _Service(comptes, attente: attente),
            ),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      if (attente == null) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    testWidgets('plus de paragraphe avant les commandes', (tester) async {
      await monter(tester, _annuaire());
      expect(
        find.textContaining('Toutes les personnes inscrites'),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('les roles sont des puces visibles, jamais sous « Plus »', (
      tester,
    ) async {
      await monter(tester, _annuaire());
      for (final String cle in <String>[
        'comptes-role-tous',
        'comptes-role-student',
        'comptes-role-guardian',
        'comptes-role-teacher',
      ]) {
        final Finder puce = find.byKey(ValueKey<String>(cle));
        expect(puce, findsOneWidget, reason: cle);
        expect(puce.hitTestable(), findsOneWidget, reason: '$cle visible');
      }
      expect(
        tester
            .widget<FilterPill>(
              find.byKey(const ValueKey<String>('comptes-role-student')),
            )
            .compteur,
        2,
      );
      // Aucune puce « Plus » : la rangee ne replie pas.
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'rangee-filtres-plus-',
              ),
        ),
        findsNothing,
      );
      // Un role absent des donnees n'a pas de puce.
      expect(
        find.byKey(const ValueKey<String>('comptes-role-admin')),
        findsNothing,
      );
    });

    testWidgets('un toucher sur « Élèves » filtre, un second revient a tous', (
      tester,
    ) async {
      await monter(tester, _annuaire());
      expect(find.text('6 comptes'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('comptes-role-student')),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 comptes'), findsOneWidget);
      expect(find.text('Lina Diallo'), findsOneWidget);
      expect(find.text('Mariam Sow'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('comptes-role-student')),
      );
      await tester.pumpAndSettle();
      expect(find.text('6 comptes'), findsOneWidget);
    });

    testWidgets('la recherche trouve par nom et par identifiant, sans accent', (
      tester,
    ) async {
      await monter(tester, _annuaire());
      await tester.enterText(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        'LÎNA',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      // Majuscules et accents sont ignores : « LÎNA » trouve Lina.
      expect(find.text('1 compte'), findsOneWidget);
      expect(find.text('Lina Diallo'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        'lina',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('1 compte'), findsOneWidget);
      expect(find.text('Lina Diallo'), findsOneWidget);
      // Par identifiant.
      await tester.enterText(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        'teacher-ob',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Omar Ba'), findsOneWidget);
      // La recherche en cours est une puce, retirable, avec « Tout effacer ».
      expect(find.text('Recherche : teacher-ob'), findsOneWidget);
      expect(find.byKey(FiltresActifs.cleToutEffacer), findsOneWidget);
      await tester.tap(find.byKey(FiltresActifs.cleToutEffacer));
      await tester.pumpAndSettle();
      expect(find.text('6 comptes'), findsOneWidget);
      expect(find.byKey(FiltresActifs.cleToutEffacer), findsNothing);
    });

    testWidgets('l etat est un menu ; son choix devient une puce retirable', (
      tester,
    ) async {
      await monter(tester, _annuaire());
      await ouvrirMenuFiltre(tester, find.byType(MenuFiltre<EtatAffiche>));
      await tester.tap(find.text('Actif').last);
      await tester.pumpAndSettle();
      expect(find.text('4 comptes'), findsOneWidget);
      final Finder puce = find.byType(PuceFiltreActif);
      expect(puce, findsOneWidget);
      expect(tester.widget<PuceFiltreActif>(puce).libelle, 'État : Actif');
      await tester.tap(puce);
      await tester.pumpAndSettle();
      expect(find.text('6 comptes'), findsOneWidget);
      expect(find.byType(PuceFiltreActif), findsNothing);
    });

    testWidgets('les colonnes suivent le role : Élèves', (tester) async {
      await monter(tester, _annuaire());
      // Tous les roles : colonne « Rôle » et « Pièce d'identité » (il y a des
      // enseignants).
      expect(find.text('Rôle'), findsOneWidget);
      expect(find.text("Pièce d'identité"), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('comptes-role-student')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rôle'), findsNothing);
      expect(find.text("Pièce d'identité"), findsNothing);
      expect(find.textContaining('Sans objet'), findsNothing);
      // L'enseignant en cours, servi par comptes_admin() et jamais montre.
      expect(find.text('Enseignant'), findsOneWidget);
      expect(find.text('Oui'), findsOneWidget);
      expect(find.text('Aucun'), findsOneWidget);
    });

    testWidgets('les colonnes suivent le role : Tuteurs et Enseignants', (
      tester,
    ) async {
      await monter(tester, _annuaire());
      await tester.tap(
        find.byKey(const ValueKey<String>('comptes-role-guardian')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Élèves du foyer'), findsOneWidget);
      expect(find.text("Pièce d'identité"), findsNothing);
      expect(find.text('Enseignant'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('comptes-role-teacher')),
      );
      await tester.pumpAndSettle();
      expect(find.text("Pièce d'identité"), findsOneWidget);
      expect(find.text('Pays'), findsOneWidget);
      expect(find.text('Élèves du foyer'), findsNothing);
    });

    testWidgets(
      'tri par en-tete : croissant, decroissant, puis ordre d origine',
      (tester) async {
        await monter(
          tester,
          _annuaire(),
          requete: const <String, String>{'role': 'student'},
        );
        double haut(String texte) => tester.getTopLeft(find.text(texte)).dy;
        // Ordre d'origine : Lina avant Yacine.
        expect(haut('Lina Diallo'), lessThan(haut('Yacine Kane')));
        final Finder entete = find.text('Personne');
        await tester.tap(entete);
        await tester.pumpAndSettle();
        expect(haut('Lina Diallo'), lessThan(haut('Yacine Kane')));
        await tester.tap(entete);
        await tester.pumpAndSettle();
        expect(haut('Yacine Kane'), lessThan(haut('Lina Diallo')));
        await tester.tap(entete);
        await tester.pumpAndSettle();
        expect(haut('Lina Diallo'), lessThan(haut('Yacine Kane')));
        // L'anciennete : les plus recents d'abord quand on trie croissant.
        await tester.tap(find.text('Inscrit depuis'));
        await tester.pumpAndSettle();
        expect(haut('Yacine Kane'), lessThan(haut('Lina Diallo')));
      },
    );

    testWidgets('pas de selection multiple, pas de case a cocher', (
      tester,
    ) async {
      await monter(tester, _annuaire());
      expect(find.byType(CaseACocher), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets(
      'actions : seulement un dossier a verifier, jamais un menu vide',
      (tester) async {
        await monter(tester, _annuaire());
        // Une seule ligne porte une action : l'enseignant avec une piece a verifier.
        expect(find.byType(MenuActions), findsOneWidget);
        expect(find.bySemanticsLabel('Actions : Omar Ba'), findsOneWidget);
        await tester.tap(find.byType(MenuActions));
        await tester.pumpAndSettle();
        expect(find.text("Ouvrir le dossier d'identité"), findsOneWidget);
      },
    );

    testWidgets('sans dossier a verifier : aucune colonne d actions', (
      tester,
    ) async {
      await monter(tester, _annuaire().take(5).toList());
      expect(find.byType(MenuActions), findsNothing);
    });

    testWidgets('ouvrir le dossier navigue avec l identifiant du profil', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      Object? extra;
      await tester.pumpWidget(
        hoteRoutant(
          depart: '/c',
          routes: <RouteBase>[
            GoRoute(
              path: '/c',
              builder: (BuildContext _, GoRouterState etat) =>
                  ComptesPage(requete: etat.uri.queryParameters),
            ),
            GoRoute(
              path: Routes.adminPersonnesDossiers,
              builder: (BuildContext _, GoRouterState etat) {
                extra = etat.extra;
                return const Scaffold(body: Text('dossiers'));
              },
            ),
          ],
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(_Service(_annuaire())),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MenuActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Ouvrir le dossier d'identité"));
      await tester.pumpAndSettle();
      expect(find.text('dossiers'), findsOneWidget);
      expect(extra, 'p-TEACHER-OB-000005');
    });

    testWidgets('pagination cote client : 25 / 50 / 100 et fleches', (
      tester,
    ) async {
      final List<CompteAdmin> beaucoup = <CompteAdmin>[
        for (int i = 0; i < 120; i++)
          _c(
            'STUDENT-XX-${i.toString().padLeft(6, '0')}',
            prenom: 'Eleve',
            nom: 'N${i.toString().padLeft(3, '0')}',
            jours: i + 1,
          ),
      ];
      await monter(tester, beaucoup);
      expect(find.byKey(PiedDeListe.cle), findsOneWidget);
      expect(find.text('1-50 sur 120'), findsOneWidget);
      // Les fleches : la page suivante, puis la derniere.
      await tester.tap(find.bySemanticsLabel('Page suivante'));
      await tester.pumpAndSettle();
      expect(find.text('51-100 sur 120'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Page suivante'));
      await tester.pumpAndSettle();
      expect(find.text('101-120 sur 120'), findsOneWidget);
      expect(find.bySemanticsLabel('Page suivante'), findsNothing);
      // La taille de page revient a la premiere page.
      await tester.tap(find.byKey(PiedDeListe.cleTaille));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25 par page').last);
      await tester.pumpAndSettle();
      expect(find.text('1-25 sur 120'), findsOneWidget);
      // Un filtre qui raccourcit la liste revient a la premiere page.
      await tester.tap(find.bySemanticsLabel('Page suivante'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        'N11',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('1-10 sur 10'), findsOneWidget);
    });

    testWidgets('au plus 1000 lignes recues : avertissement visible', (
      tester,
    ) async {
      List<CompteAdmin> n(int k) => <CompteAdmin>[
        for (int i = 0; i < k; i++)
          _c(
            'STUDENT-XX-${i.toString().padLeft(6, '0')}',
            prenom: 'E',
            nom: '$i',
          ),
      ];
      await monter(tester, n(plafondComptesServeur - 1));
      expect(
        find.byKey(const ValueKey<String>('comptes-plafond')),
        findsNothing,
      );
      await monter(tester, n(plafondComptesServeur));
      expect(
        find.byKey(const ValueKey<String>('comptes-plafond')),
        findsOneWidget,
      );
      expect(find.textContaining('1000'), findsWidgets);
    });

    testWidgets(
      'la synthese annonce ceux qui attendent et les filtre d un toucher',
      (tester) async {
        await monter(tester, _annuaire());
        expect(
          find.textContaining('Une personne attend', findRichText: true),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey<String>('comptes-attente')));
        await tester.pumpAndSettle();
        expect(find.text('1 compte'), findsOneWidget);
        expect(find.text('Aicha Barry'), findsOneWidget);
      },
    );

    testWidgets('chargement : squelette ; liste vide filtree : le dit', (
      tester,
    ) async {
      final Completer<List<CompteAdmin>> attente =
          Completer<List<CompteAdmin>>();
      await monter(tester, const <CompteAdmin>[], attente: attente);
      expect(find.byType(DataCollection<CompteAdmin>), findsNothing);
      attente.complete(_annuaire());
      await tester.pumpAndSettle();
      expect(find.byType(DataCollection<CompteAdmin>), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        'zzz',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Aucun compte avec ce filtre'), findsOneWidget);
      // En francais, zero est un singulier.
      expect(find.text('0 compte'), findsOneWidget);
    });

    testWidgets('en-tete colle : il ne defile pas avec les lignes', (
      tester,
    ) async {
      final List<CompteAdmin> beaucoup = <CompteAdmin>[
        for (int i = 0; i < 80; i++)
          _c(
            'STUDENT-XX-${i.toString().padLeft(6, '0')}',
            prenom: 'E',
            nom: '$i',
          ),
      ];
      await monter(tester, beaucoup);
      final double avant = tester.getTopLeft(find.text('Personne')).dy;
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Personne')).dy, avant);
    });

    // Mesure sur la VRAIE coque (barre laterale, en-tete, sous-navigation) a
    // 1440 x 900 : les lignes entierement visibles, au-dessus du pied de liste.
    Future<int> lignesVisibles(
      WidgetTester tester,
      String route,
      List<CompteAdmin> comptes,
    ) async {
      await monterRouteur(
        tester,
        route,
        source: FausseSourceSession(sessionActive(AppRole.admin)),
        taille: const Size(1440, 900),
        surcharges: <Override>[
          serviceComptesProvider.overrideWithValue(_Service(comptes)),
        ],
      );
      final double pied = tester.getTopLeft(find.byKey(PiedDeListe.cle)).dy;
      final double entete = tester.getBottomLeft(find.text('Personne')).dy;
      return find.textContaining('‑XX‑').evaluate().where((Element e) {
        final Rect r = tester.getRect(find.byWidget(e.widget));
        return r.top >= entete && r.bottom <= pied;
      }).length;
    }

    testWidgets('sur la coque, 1440 x 900 : Eleves montre au moins 10 lignes', (
      tester,
    ) async {
      final List<CompteAdmin> beaucoup = <CompteAdmin>[
        for (int i = 0; i < 40; i++)
          _c(
            'STUDENT-XX-${i.toString().padLeft(6, '0')}',
            prenom: 'E',
            nom: 'N$i',
          ),
      ];
      final int n = await lignesVisibles(
        tester,
        '${Routes.adminPersonnesComptes}?role=student',
        beaucoup,
      );
      // Avant la refonte : 2 a 7 lignes selon la page (coque comprise). Les
      // polices de test sont plus hautes que les vraies : la capture avec les
      // vraies polices (LISTES/comptes) montre 10 lignes entieres.
      expect(n, greaterThanOrEqualTo(9));
    });

    testWidgets('sur la coque : tous les roles, colonne d actions comprise', (
      tester,
    ) async {
      // Un enseignant a verifier ajoute la colonne d'actions : les lignes
      // passent de 48 a 56 (cible du menu). Capture (vraies polices) : 8 lignes
      // entieres et un debut de neuvieme.
      final List<CompteAdmin> beaucoup = <CompteAdmin>[
        _c(
          'TEACHER-XX-000000',
          prenom: 'E',
          nom: 'T',
          role: AppRole.teacher,
          piece: EtatPiece.aVerifier,
        ),
        for (int i = 1; i < 40; i++)
          _c(
            'STUDENT-XX-${i.toString().padLeft(6, '0')}',
            prenom: 'E',
            nom: 'N$i',
          ),
      ];
      final int n = await lignesVisibles(
        tester,
        Routes.adminPersonnesComptes,
        beaucoup,
      );
      expect(n, greaterThanOrEqualTo(7));
    });
  });

  group('La page : adresse', () {
    Widget routant(String depart, List<CompteAdmin> comptes) => hoteRoutant(
      depart: depart,
      routes: <RouteBase>[
        GoRoute(
          path: '/c',
          builder: (BuildContext _, GoRouterState etat) => ComptesPage(
            echusSeulement: etat.uri.queryParameters['filtre'] == 'echus',
            requete: etat.uri.queryParameters,
          ),
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_Service(comptes)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    );

    Future<GoRouter> ouvrir(WidgetTester tester, String depart) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(routant(depart, _annuaire()));
      await tester.pumpAndSettle();
      return GoRouter.of(tester.element(find.byType(ComptesPage)));
    }

    String adresse(GoRouter r) =>
        r.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('l adresse ouvre la page filtree (role, recherche, tri)', (
      tester,
    ) async {
      await ouvrir(tester, '/c?role=student&q=lina&tri=-nom');
      expect(find.text('1 compte'), findsOneWidget);
      expect(find.text('Lina Diallo'), findsOneWidget);
      final TextField champ = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('comptes-recherche')),
      );
      expect(champ.controller!.text, 'lina');
    });

    testWidgets('une valeur inconnue dans l adresse est ignoree', (
      tester,
    ) async {
      await ouvrir(tester, '/c?role=martien&etat=zzz&tri=nimporte');
      expect(find.text('6 comptes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chaque geste ecrit l adresse ; « Tout effacer » la vide', (
      tester,
    ) async {
      final GoRouter routeur = await ouvrir(tester, '/c');
      await tester.tap(
        find.byKey(const ValueKey<String>('comptes-role-teacher')),
      );
      await tester.pumpAndSettle();
      expect(adresse(routeur), '/c?role=teacher');
      await tester.tap(find.text('Personne'));
      await tester.pumpAndSettle();
      expect(adresse(routeur), '/c?role=teacher&tri=nom');
      await tester.enterText(
        find.byKey(const ValueKey<String>('comptes-recherche')),
        'omar',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      // Le texte cherche (nom d'une personne) n'entre jamais dans l'adresse.
      expect(adresse(routeur), '/c?role=teacher&tri=nom');
      await tester.tap(find.byKey(FiltresActifs.cleToutEffacer));
      await tester.pumpAndSettle();
      expect(adresse(routeur), '/c?role=teacher&tri=nom');
    });

    testWidgets('revenir a l adresse nue remet la liste entiere', (
      tester,
    ) async {
      final GoRouter routeur = await ouvrir(tester, '/c?role=student&q=lina');
      expect(find.text('1 compte'), findsOneWidget);
      routeur.go('/c');
      await tester.pumpAndSettle();
      expect(find.text('6 comptes'), findsOneWidget);
      final TextField champ = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('comptes-recherche')),
      );
      expect(champ.controller!.text, isEmpty);
    });
  });

  group('La page : telephone, texte agrandi, arabe', () {
    for (final (String, Size, double) cas in <(String, Size, double)>[
      ('390', const Size(390, 844), 1),
      ('390 x2', const Size(390, 2400), 2),
      ('320 x2', const Size(320, 2400), 2),
    ]) {
      testWidgets('${cas.$1} : aucun debordement, cartes et pied', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = cas.$2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hote(
            MediaQuery(
              data: MediaQueryData(
                size: cas.$2,
                textScaler: TextScaler.linear(cas.$3),
              ),
              child: const ComptesPage(),
            ),
            surcharges: <Override>[
              serviceComptesProvider.overrideWithValue(_Service(_annuaire())),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(RangeeFiltres), findsOneWidget);
        expect(find.text('6 comptes'), findsOneWidget);
      });
    }

    testWidgets('arabe : aucun debordement', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: ComptesPage(),
          ),
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(_Service(_annuaire())),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(t.admin.comptes.compteur(n: 6)), findsOneWidget);
    });
  });
}
