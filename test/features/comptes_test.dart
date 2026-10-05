import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

/// Le defaut que cet ecran repare, mesure en production le 18 septembre 2026 :
/// trois enseignants inscrits attendaient depuis sept jours, contrats signes,
/// sans avoir depose leur piece d'identite. Aucun ecran de l'administration ne
/// les montrait, parce que `dossiers_en_attente()` comptait des **documents**
/// et non des personnes. Le tableau de bord affichait « 0 dossiers a valider »
/// sur une academie bloquee.
///
/// Ces tests portent donc sur un seul fait : **une personne sans piece est
/// visible, et dit ce qui manque.**
class _FauxServiceComptes implements ServiceComptes {
  _FauxServiceComptes(this._comptes, {this.echoue = false});

  final List<CompteAdmin> _comptes;
  final bool echoue;

  @override
  Future<List<CompteAdmin>> comptes() async {
    if (echoue) {
      throw StateError('lecture refusee');
    }
    return _comptes;
  }
}

CompteAdmin _compte({
  required String identifiant,
  required AccountStatus etat,
  AppRole? role = AppRole.teacher,
  EtatPiece piece = EtatPiece.aucune,
  String? prenom = 'Aicha',
  int joursDepuisInscription = 7,
  int contrats = 2,
  DateTime? accesJusquAu,
}) => CompteAdmin(
  profilId: identifiant,
  identifiant: identifiant,
  prenom: prenom,
  nom: prenom == null ? null : 'Sow',
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(Duration(days: joursDepuisInscription)),
  accesJusquAu: accesJusquAu,
  foyerId: null,
  piece: piece,
  contrats: contrats,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

void main() {
  Future<void> monter(
    WidgetTester tester,
    ServiceComptes service, {
    bool echusSeulement = false,
  }) async {
    // Une surface haute : la liste est paresseuse, et le tri place les lignes
    // sans decision en dernier, hors d'une surface de test courte.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        ComptesPage(echusSeulement: echusSeulement),
        surcharges: <Override>[
          serviceComptesProvider.overrideWithValue(service),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'un enseignant inscrit sans piece deposee est visible et dit son etat',
    (WidgetTester tester) async {
      await monter(
        tester,
        _FauxServiceComptes(<CompteAdmin>[
          _compte(
            identifiant: 'TEACHER-AS-000001',
            etat: AccountStatus.pendingKyc,
          ),
        ]),
      );

      expect(tester.takeException(), isNull);
      // La personne existe a l'ecran, ce qui n'etait le cas d'aucun ecran
      // avant ce lot. `textContaining` et non `text` : sous 1200,
      // `DataCollection` replie le tableau en cartes et joint les colonnes
      // secondaires par un point median, donc l'identifiant vit dans une
      // chaine composee.
      expect(find.textContaining('Aicha Sow'), findsWidgets);
      expect(find.textContaining('TEACHER-AS-000001'), findsWidgets);
      // Et l'ecran nomme ce qui manque, au lieu de laisser une case vide.
      expect(find.textContaining('Aucune pièce déposée'), findsWidgets);
    },
  );

  testWidgets('le bandeau dit combien de personnes attendent une decision', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'TEACHER-AS-000001',
          etat: AccountStatus.pendingKyc,
        ),
        _compte(
          identifiant: 'TEACHER-AS-000002',
          etat: AccountStatus.pendingKyc,
        ),
        _compte(
          identifiant: 'TEACHER-AD-000003',
          etat: AccountStatus.pendingKyc,
        ),
        _compte(
          identifiant: 'GUARDIAN-SR-000002',
          etat: AccountStatus.active,
          role: AppRole.guardian,
          piece: EtatPiece.aucune,
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('3 personnes attendent une décision.'), findsOneWidget);
  });

  // K-47 : la verification d'identite et la validation ne concernent que
  // l'enseignant. Un tuteur `pending_kyc` ne depose rien et n'attend aucune
  // decision : il ne doit ni gonfler le bandeau ni afficher un manque de piece.
  testWidgets(
    'un tuteur pending_kyc n attend aucune decision, un enseignant si',
    (WidgetTester tester) async {
      await monter(
        tester,
        // Le tuteur en tete : la liste est paresseuse et la surface de test
        // etroite, une troisieme ligne peut rester hors ecran.
        _FauxServiceComptes(<CompteAdmin>[
          _compte(
            identifiant: 'GUARDIAN-SR-000003',
            etat: AccountStatus.pendingKyc,
            role: AppRole.guardian,
            prenom: 'Mariam',
          ),
          _compte(
            identifiant: 'TEACHER-AS-000001',
            etat: AccountStatus.pendingKyc,
          ),
          _compte(
            identifiant: 'TEACHER-AS-000002',
            etat: AccountStatus.pendingKyc,
          ),
        ]),
      );

      expect(tester.takeException(), isNull);
      // Deux enseignants en attente, le tuteur n'est pas compte.
      expect(find.text('2 personnes attendent une décision.'), findsOneWidget);
      expect(find.text('3 personnes attendent une décision.'), findsNothing);
      // Le tuteur reste visible, avec « Sans objet » pour la piece.
      expect(find.textContaining('GUARDIAN-SR-000003'), findsWidgets);
      expect(find.textContaining('Sans objet'), findsOneWidget);
      // L'enseignant garde son manque de piece affiche.
      expect(find.textContaining('Aucune pièce déposée'), findsWidgets);

      // Contre-epreuve au niveau du modele.
      final CompteAdmin tuteur = _compte(
        identifiant: 'GUARDIAN-SR-000003',
        etat: AccountStatus.pendingKyc,
        role: AppRole.guardian,
      );
      final CompteAdmin enseignant = _compte(
        identifiant: 'TEACHER-AS-000001',
        etat: AccountStatus.pendingKyc,
      );
      expect(tuteur.attendUneDecision, isFalse);
      expect(enseignant.attendUneDecision, isTrue);
    },
  );

  testWidgets('un tuteur seul en attente ne fait apparaitre aucun bandeau', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'GUARDIAN-SR-000003',
          etat: AccountStatus.pendingKyc,
          role: AppRole.guardian,
          joursDepuisInscription: 3,
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    // Ni « Une personne attend… » ni « N personnes attendent… ». L'intro de
    // la page contient aussi « attendent une décision », d'ou l'ancrage.
    expect(
      find.textContaining(
        RegExp(r'^(Une personne attend|\d+ personnes attendent)'),
      ),
      findsNothing,
    );
    expect(find.textContaining('Sans objet'), findsOneWidget);
  });

  // AD-NETTOYAGE (mineur AD-RC) : la base rend les tuteurs `pending_kyc` en
  // tete. Le tri stable cote client remet devant ce qui attend une decision.
  testWidgets(
    'les enseignants en attente passent devant les lignes sans decision',
    (WidgetTester tester) async {
      await monter(
        tester,
        _FauxServiceComptes(<CompteAdmin>[
          _compte(
            identifiant: 'GUARDIAN-SR-000003',
            etat: AccountStatus.pendingKyc,
            role: AppRole.guardian,
            prenom: 'Mariam',
          ),
          _compte(
            identifiant: 'TEACHER-AS-000001',
            etat: AccountStatus.pendingKyc,
          ),
        ]),
      );

      expect(tester.takeException(), isNull);
      final double enseignant = tester
          .getTopLeft(find.textContaining('TEACHER-AS-000001').first)
          .dy;
      final double tuteur = tester
          .getTopLeft(find.textContaining('GUARDIAN-SR-000003').first)
          .dy;
      expect(enseignant, lessThan(tuteur));
    },
  );

  testWidgets('seul l enseignant sans piece voit « Aucune pièce déposée »', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'STUDENT-LI-000001',
          etat: AccountStatus.active,
          role: AppRole.student,
          prenom: 'Lina',
        ),
        _compte(
          identifiant: 'ADMIN-NA-000001',
          etat: AccountStatus.active,
          role: AppRole.admin,
          prenom: 'Nadir',
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sans objet'), findsNWidgets(2));
    expect(find.textContaining('Aucune pièce déposée'), findsNothing);
  });

  testWidgets('un compte en attente au role illisible est signale', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'UNKNOWN-XX-000001',
          etat: AccountStatus.pendingKyc,
          role: null,
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining("Le rôle d'un compte en attente n'a pas pu être lu"),
      findsOneWidget,
    );
    // Il n'est pas compte comme attendant une decision : la phrase le dit.
    expect(find.textContaining('attend une décision'), findsNothing);
  });

  testWidgets('une lecture en echec le dit et laisse reessayer', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(const <CompteAdmin>[], echoue: true),
    );

    expect(
      find.text(
        "Les comptes n'ont pas pu être lus. Réessayez dans un instant.",
      ),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });

  // La correction d'ergonomie du 18 septembre 2026 : rendre les quatre etats
  // et les six roles produisait onze pastilles qui repoussaient la liste sous
  // le pli. Seuls les etats **presents dans les donnees** sont proposes, et
  // l'axe des roles passe dans un menu deroulant.
  testWidgets('un etat absent des donnees n est pas propose comme filtre', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'GUARDIAN-SR-000002',
          etat: AccountStatus.active,
          role: AppRole.guardian,
          piece: EtatPiece.aucune,
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Actif'), findsWidgets);
    // Aucun compte suspendu ni provisoire : leurs pastilles n'existent pas.
    expect(find.text('Suspendu'), findsNothing);
    expect(find.text('Provisoire'), findsNothing);
    expect(find.text('En attente'), findsNothing);
    // Un seul role present : le menu ne sert a rien et n'est pas rendu. Un
    // controle qui n'offre qu'un choix n'est pas un choix. L'assertion porte
    // sur le type et non sur le texte : « Rôle » nomme aussi une colonne.
    expect(find.byType(MenuFiltre<AppRole>), findsNothing);
  });

  testWidgets('un filtre croise qui ne laisse rien passer le dit', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'TEACHER-AS-000001',
          etat: AccountStatus.pendingKyc,
        ),
        _compte(
          identifiant: 'GUARDIAN-SR-000002',
          etat: AccountStatus.active,
          role: AppRole.guardian,
          piece: EtatPiece.aucune,
        ),
      ]),
    );

    // « En attente » ne contient qu'un enseignant.
    await tester.tap(find.text('En attente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('TEACHER-AS-000001'), findsWidgets);

    // Croise avec le role tuteur, il ne reste rien. Le menu se cible par son
    // type : « Rôle » nomme aussi une colonne du tableau.
    await tester.tap(find.byType(MenuFiltre<AppRole>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuteur').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Aucun compte avec ce filtre'), findsOneWidget);
  });

  // DASH-ADM-ECHUS : la page s'ouvre filtree sur les acces echus, avec la
  // definition du compteur du Centre de commande.
  group('DASH-ADM-ECHUS : les acces echus', () {
    final DateTime hier = DateTime.now().subtract(const Duration(days: 1));
    final DateTime demain = DateTime.now().add(const Duration(days: 1));
    List<CompteAdmin> jeu() => <CompteAdmin>[
      _compte(
        identifiant: 'TUTOR-EC-000001',
        prenom: 'Echue',
        role: AppRole.guardian,
        etat: AccountStatus.provisionalActive,
        accesJusquAu: hier,
      ),
      _compte(
        identifiant: 'TUTOR-EC-000002',
        prenom: 'Encore',
        role: AppRole.guardian,
        etat: AccountStatus.provisionalActive,
        accesJusquAu: demain,
      ),
      _compte(
        identifiant: 'TUTOR-EC-000003',
        prenom: 'Active',
        role: AppRole.guardian,
        etat: AccountStatus.active,
        accesJusquAu: hier,
      ),
    ];

    test('meme definition que le compteur serveur', () {
      final DateTime maintenant = DateTime.now();
      expect(
        jeu()
            .where((CompteAdmin c) => c.accesEchu(maintenant))
            .map((CompteAdmin c) => c.prenom),
        <String>['Echue'],
      );
    });

    testWidgets('ouverte sur les echus : le seul compte echu', (
      WidgetTester tester,
    ) async {
      await monter(tester, _FauxServiceComptes(jeu()), echusSeulement: true);
      expect(find.textContaining('Echue'), findsWidgets);
      expect(find.textContaining('Encore'), findsNothing);
      expect(find.textContaining('Active Sow'), findsNothing);
    });

    testWidgets('le filtre se relache et se reprend d un tap', (
      WidgetTester tester,
    ) async {
      await monter(tester, _FauxServiceComptes(jeu()), echusSeulement: true);
      final Finder filtre = find.byKey(
        const ValueKey<String>('comptes-filtre-echus'),
      );
      expect(filtre, findsOneWidget);
      await tester.tap(filtre);
      await tester.pumpAndSettle();
      expect(find.textContaining('Encore'), findsWidgets);
      await tester.tap(filtre);
      await tester.pumpAndSettle();
      expect(find.textContaining('Encore'), findsNothing);
    });

    // Revue DASH-ADM-ECHUS, defaut 2 : « Tous 3 » et « Acces echus 2 »
    // etaient retenues ensemble pour deux lignes affichees.
    testWidgets('une seule pastille retenue, et « Tous » relache les echus', (
      WidgetTester tester,
    ) async {
      await monter(tester, _FauxServiceComptes(jeu()), echusSeulement: true);
      List<String> retenues() => tester
          .widgetList<FilterPill>(find.byType(FilterPill))
          .where((FilterPill p) => p.retenue)
          .map((FilterPill p) => p.libelle)
          .toList();
      expect(retenues(), <String>['Accès échus']);
      await tester.tap(find.widgetWithText(FilterPill, 'Tous'));
      await tester.pumpAndSettle();
      expect(retenues(), <String>['Tous']);
      expect(find.textContaining('Encore'), findsWidgets);
    });

    // Revue DASH-ADM-ECHUS, defaut 1 (majeur) : go_router cle la page sur le
    // chemin seul, le `State` survit au changement de requete.
    Widget routant(String depart) => hoteRoutant(
      depart: depart,
      routes: <RouteBase>[
        GoRoute(
          path: '/c',
          builder: (BuildContext _, GoRouterState etat) => ComptesPage(
            echusSeulement: etat.uri.queryParameters['filtre'] == 'echus',
          ),
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_FauxServiceComptes(jeu())),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    );

    testWidgets('le filtre suit l adresse sur un vrai GoRouter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(routant('/c?filtre=echus'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Encore'), findsNothing);
      final GoRouter routeur = GoRouter.of(
        tester.element(find.byType(ComptesPage)),
      );
      routeur.go('/c');
      await tester.pumpAndSettle();
      expect(find.textContaining('Encore'), findsWidgets);
      routeur.go('/c?filtre=echus');
      await tester.pumpAndSettle();
      expect(find.textContaining('Encore'), findsNothing);
    });

    // Revue DASH-ADM-ECHUS, defaut 4 : relacher la pastille laissait
    // `?filtre=echus` dans l'adresse.
    testWidgets('relacher ou reprendre la pastille ecrit l adresse', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(routant('/c?filtre=echus'));
      await tester.pumpAndSettle();
      final GoRouter routeur = GoRouter.of(
        tester.element(find.byType(ComptesPage)),
      );
      String adresse() =>
          routeur.routerDelegate.currentConfiguration.uri.toString();
      final Finder filtre = find.byKey(
        const ValueKey<String>('comptes-filtre-echus'),
      );
      await tester.tap(filtre);
      await tester.pumpAndSettle();
      expect(adresse(), '/c');
      expect(find.textContaining('Encore'), findsWidgets);
      await tester.tap(filtre);
      await tester.pumpAndSettle();
      expect(adresse(), '/c?filtre=echus');
      expect(find.textContaining('Encore'), findsNothing);
      await tester.tap(find.widgetWithText(FilterPill, 'Tous'));
      await tester.pumpAndSettle();
      expect(adresse(), '/c');
    });

    // Revue DASH-ADM-ECHUS, defaut 3 : le cablage reel de `?filtre=echus`
    // dans `routeurProvider` n'etait couvert par aucun test.
    testWidgets('le vrai routeur ouvre Comptes filtre sur les echus', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.adminPersonnesComptesEchus,
        source: FausseSourceSession(sessionActive(AppRole.admin)),
        taille: const Size(1440, 900),
        surcharges: <Override>[
          serviceComptesProvider.overrideWithValue(_FauxServiceComptes(jeu())),
        ],
      );
      expect(lieu(routeur), Routes.adminPersonnesComptesEchus);
      expect(find.byType(ComptesPage), findsOneWidget);
      expect(find.textContaining('Echue'), findsWidgets);
      expect(find.textContaining('Encore'), findsNothing);
      routeur.go(Routes.adminPersonnesComptes);
      await stabiliser(tester);
      expect(find.textContaining('Encore'), findsWidgets);
    });

    testWidgets('sans echu, pas de filtre a vide', (WidgetTester tester) async {
      await monter(
        tester,
        _FauxServiceComptes(<CompteAdmin>[jeu()[1], jeu()[2]]),
      );
      expect(
        find.byKey(const ValueKey<String>('comptes-filtre-echus')),
        findsNothing,
      );
    });
  });
}
