import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/identifiant_insecable.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_comptes/liste_comptes.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';
import '../support/rangee_plus.dart';

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
    Map<String, String> requete = const <String, String>{},
  }) async {
    // Une surface haute : la liste est paresseuse, et le tri place les lignes
    // sans decision en dernier, hors d'une surface de test courte.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        ComptesPage(echusSeulement: echusSeulement, requete: requete),
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
      expect(
        find.textContaining(identifiantInsecable('TEACHER-AS-000001')),
        findsWidgets,
      );
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
      // La vue Enseignants s'ouvre : deux enseignants attendent.
      expect(find.text('2 personnes attendent une décision.'), findsOneWidget);
      expect(find.textContaining('Aucune pièce déposée'), findsWidgets);
      // Le tuteur est dans Familles, sans phrase d'attente ni piece.
      await tester.tap(find.text('Familles (1)'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(identifiantInsecable('GUARDIAN-SR-000003')),
        findsWidgets,
      );
      expect(find.textContaining('attend'), findsNothing);
      expect(find.text("Pièce d'identité"), findsNothing);

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
    // LISTES-3 : aucun compte de la liste ne depose de piece, la colonne n'est
    // pas rendue (« Sans objet » repete n'apprend rien).
    expect(find.textContaining('Sans objet'), findsNothing);
    expect(find.text("Pièce d'identité"), findsNothing);
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
            identifiant: 'TEACHER-MS-000003',
            etat: AccountStatus.active,
            prenom: 'Mariam',
          ),
          _compte(
            identifiant: 'TEACHER-AS-000001',
            etat: AccountStatus.pendingKyc,
          ),
        ]),
      );

      expect(tester.takeException(), isNull);
      final double attend = tester
          .getTopLeft(
            find
                .textContaining(identifiantInsecable('TEACHER-AS-000001'))
                .first,
          )
          .dy;
      final double actif = tester
          .getTopLeft(
            find
                .textContaining(identifiantInsecable('TEACHER-MS-000003'))
                .first,
          )
          .dy;
      expect(attend, lessThan(actif));
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
    // LISTES-3 : ni eleve ni administrateur ne depose de piece, la colonne
    // n'est pas rendue du tout.
    expect(find.textContaining('Sans objet'), findsNothing);
    expect(find.textContaining('Aucune pièce déposée'), findsNothing);
    expect(find.text("Pièce d'identité"), findsNothing);
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
  // le pli. LISTES-3 : les roles presents sont en acces direct (une pastille
  // chacun), l'etat est un menu dont seules les valeurs **presentes dans les
  // donnees** sont proposees.
  // Decision « pastille-attente » du 05/10 (AD-NETTOYAGE-2, par delegation
  // du directeur) : l'etat « En attente » ne compte que les enseignants,
  // le meme chiffre que la tuile « Dossiers a valider ». Un tuteur et un
  // compte au role illisible en `pending_kyc` n'y entrent pas.
  Finder menuEtat() => find.byType(MenuFiltre<EtatAffiche>);

  /// Ouvre le menu d'etat. La rangee des filtres defile quand elle ne tient pas
  /// (ici 800 px de large) : on amene d'abord le menu dans la vue.
  Future<void> ouvrirEtat(WidgetTester tester) async {
    await tester.ensureVisible(menuEtat());
    await tester.pumpAndSettle();
    await ouvrirMenuFiltre(tester, menuEtat());
  }

  /// Les entrees du menu d'etat, avec leur compteur, une fois ouvert.
  List<EntreeFiltre<EtatAffiche>> entreesEtat(WidgetTester tester) =>
      tester.widget<MenuFiltre<EtatAffiche>>(menuEtat()).entrees;

  testWidgets('l etat « En attente » ne compte que les enseignants', (
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
          identifiant: 'TEACHER-OB-000004',
          etat: AccountStatus.active,
          prenom: 'Omar',
        ),
        _compte(
          identifiant: 'GUARDIAN-MS-000003',
          etat: AccountStatus.pendingKyc,
          role: AppRole.guardian,
        ),
        _compte(
          identifiant: 'UNKNOWN-XX-000001',
          etat: AccountStatus.pendingKyc,
          role: null,
          prenom: null,
        ),
      ]),
    );

    expect(tester.takeException(), isNull);
    final EntreeFiltre<EtatAffiche> attente = entreesEtat(tester).firstWhere(
      (EntreeFiltre<EtatAffiche> e) => e.valeur == EtatAffiche.attente,
    );
    expect(attente.compteur, 2);
    // La synthese dit le meme chiffre.
    expect(find.text('2 personnes attendent une décision.'), findsOneWidget);

    // Retenu, l'etat montre exactement ces deux enseignants.
    await ouvrirEtat(tester);
    await tester.tap(find.text('En attente').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(identifiantInsecable('TEACHER-AS-000001')),
      findsWidgets,
    );
    expect(
      find.textContaining(identifiantInsecable('TEACHER-AS-000002')),
      findsWidgets,
    );
    expect(
      find.textContaining(identifiantInsecable('TEACHER-OB-000004')),
      findsNothing,
    );
    expect(
      find.textContaining(identifiantInsecable('GUARDIAN-MS-000003')),
      findsNothing,
    );
    expect(find.textContaining('UNKNOWN-XX-000001'), findsNothing);
  });

  // Un toucher sur la phrase d'alerte applique le filtre qu'elle annonce.
  testWidgets('toucher la phrase d alerte filtre sur ceux qui attendent', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'TEACHER-LS-000001',
          etat: AccountStatus.active,
          prenom: 'Lina',
        ),
        _compte(
          identifiant: 'TEACHER-AS-000001',
          etat: AccountStatus.pendingKyc,
        ),
      ]),
    );
    expect(find.textContaining('Lina Sow'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey<String>('comptes-attente')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lina Sow'), findsNothing);
    expect(find.textContaining('Aicha Sow'), findsWidgets);
    expect(find.text('1 compte'), findsOneWidget);
  });

  // Revue croisee de LIB-DIR-1 (08/10) : chaque compte entre dans un seul
  // etat, et son badge dit le nom de cet etat. « Tous » est la somme des autres.
  testWidgets('« Tous » est la somme des etats, badges compris', (
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
          identifiant: 'GUARDIAN-MS-000003',
          etat: AccountStatus.pendingKyc,
          role: AppRole.guardian,
        ),
        _compte(
          identifiant: 'GUARDIAN-YB-000004',
          etat: AccountStatus.pendingKyc,
          role: AppRole.guardian,
        ),
        _compte(
          identifiant: 'GUARDIAN-LS-000001',
          etat: AccountStatus.active,
          role: AppRole.guardian,
        ),
      ]),
      requete: const <String, String>{'vue': 'familles'},
    );

    expect(tester.takeException(), isNull);
    final List<EntreeFiltre<EtatAffiche>> entrees = entreesEtat(tester);
    final EntreeFiltre<EtatAffiche> tous = entrees.firstWhere(
      (EntreeFiltre<EtatAffiche> e) => e.valeur == null,
    );
    final int somme = entrees
        .where((EntreeFiltre<EtatAffiche> e) => e.valeur != null)
        .fold<int>(
          0,
          (int n, EntreeFiltre<EtatAffiche> e) => n + (e.compteur ?? 0),
        );
    expect(tous.compteur, 3);
    expect(somme, 3);
    final EntreeFiltre<EtatAffiche> sansDecision = entrees.firstWhere(
      (EntreeFiltre<EtatAffiche> e) => e.valeur == EtatAffiche.sansDecision,
    );
    expect(sansDecision.libelle, 'Sans décision');
    expect(sansDecision.compteur, 2);

    // Retenu, « Sans décision » montre les deux tuteurs, avec ce badge.
    await ouvrirEtat(tester);
    await tester.tap(find.text('Sans décision').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(identifiantInsecable('GUARDIAN-MS-000003')),
      findsWidgets,
    );
    expect(
      find.textContaining(identifiantInsecable('GUARDIAN-YB-000004')),
      findsWidgets,
    );
    expect(
      find.textContaining(identifiantInsecable('GUARDIAN-LS-000001')),
      findsNothing,
    );
    // Le badge (ou la ligne resumee) de chaque tuteur dit le nom de l'etat.
    expect(
      find.textContaining('Sans décision', findRichText: true),
      findsAtLeastNWidgets(2),
    );
  });

  testWidgets('un tuteur seul en attente : aucun etat « En attente »', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      _FauxServiceComptes(<CompteAdmin>[
        _compte(
          identifiant: 'GUARDIAN-MS-000003',
          etat: AccountStatus.pendingKyc,
          role: AppRole.guardian,
        ),
        _compte(
          identifiant: 'GUARDIAN-LS-000001',
          etat: AccountStatus.active,
          role: AppRole.guardian,
        ),
      ]),
      requete: const <String, String>{'vue': 'familles'},
    );

    expect(tester.takeException(), isNull);
    expect(
      entreesEtat(tester).map((EntreeFiltre<EtatAffiche> e) => e.valeur),
      isNot(contains(EtatAffiche.attente)),
    );
  });

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
      requete: const <String, String>{'vue': 'familles'},
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Actif'), findsWidgets);
    // Un seul etat present : le menu n'offrirait aucun choix, il n'est pas
    // rendu. Un controle qui n'offre qu'un choix n'est pas un choix.
    expect(menuEtat(), findsNothing);
    expect(find.text('Suspendu'), findsNothing);
    expect(find.text('Provisoire'), findsNothing);
    expect(find.text('En attente'), findsNothing);
    // Aucune puce de role : les roles sont des vues.
    expect(
      find.byKey(const ValueKey<String>('comptes-role-teacher')),
      findsNothing,
    );
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
          identifiant: 'TEACHER-SR-000002',
          etat: AccountStatus.active,
          piece: EtatPiece.validee,
        ),
      ]),
    );

    // « En attente » ne contient qu'un enseignant.
    await ouvrirEtat(tester);
    await tester.tap(find.text('En attente').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(identifiantInsecable('TEACHER-AS-000001')),
      findsWidgets,
    );

    // Croise avec une recherche qui ne trouve personne, il ne reste rien.
    await tester.enterText(
      find.byKey(const ValueKey<String>('comptes-recherche')),
      'personne-inconnue',
    );
    await tester.pump(const Duration(seconds: 1));
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
        role: AppRole.student,
        etat: AccountStatus.provisionalActive,
        accesJusquAu: hier,
      ),
      _compte(
        identifiant: 'TUTOR-EC-000002',
        prenom: 'Encore',
        role: AppRole.student,
        etat: AccountStatus.provisionalActive,
        accesJusquAu: demain,
      ),
      _compte(
        identifiant: 'TUTOR-EC-000003',
        prenom: 'Active',
        role: AppRole.student,
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
      await toucherFiltre(tester, filtre);
      expect(find.textContaining('Encore'), findsWidgets);
      await toucherFiltre(tester, filtre);
      expect(find.textContaining('Encore'), findsNothing);
    });

    // Revue DASH-ADM-ECHUS, defaut 2 : « Tous » et « Acces echus » etaient
    // retenues ensemble pour deux lignes affichees. LISTES-3 : « Tous » est
    // celle des roles ; les echus se relachent d'un toucher sur leur puce, ou
    // par « Tout effacer ».
    testWidgets('« Tout effacer » relache les echus', (
      WidgetTester tester,
    ) async {
      await monter(tester, _FauxServiceComptes(jeu()), echusSeulement: true);
      expect(find.textContaining('Encore'), findsNothing);
      expect(find.byKey(FiltresActifs.cleToutEffacer), findsOneWidget);
      await tester.tap(find.byKey(FiltresActifs.cleToutEffacer));
      await tester.pumpAndSettle();
      expect(find.textContaining('Encore'), findsWidgets);
      expect(find.byKey(FiltresActifs.cleToutEffacer), findsNothing);
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
            requete: etat.uri.queryParameters,
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
      await toucherFiltre(tester, filtre);
      expect(adresse(), '/c?vue=eleves');
      expect(find.textContaining('Encore'), findsWidgets);
      await toucherFiltre(tester, filtre);
      expect(adresse(), '/c?vue=eleves&filtre=echus');
      expect(find.textContaining('Encore'), findsNothing);
      await tester.tap(find.byKey(FiltresActifs.cleToutEffacer));
      await tester.pumpAndSettle();
      expect(adresse(), '/c?vue=eleves');
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

    testWidgets('des acces echus chez les tuteurs ouvrent Familles', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        _FauxServiceComptes(<CompteAdmin>[
          _compte(
            identifiant: 'STUDENT-LI-000001',
            prenom: 'Lina',
            role: AppRole.student,
            etat: AccountStatus.active,
          ),
          _compte(
            identifiant: 'GUARDIAN-EC-000001',
            prenom: 'Echue',
            role: AppRole.guardian,
            etat: AccountStatus.provisionalActive,
            accesJusquAu: hier,
          ),
        ]),
        echusSeulement: true,
      );
      expect(find.textContaining('Echue'), findsWidgets);
      expect(find.textContaining('Lina'), findsNothing);
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
