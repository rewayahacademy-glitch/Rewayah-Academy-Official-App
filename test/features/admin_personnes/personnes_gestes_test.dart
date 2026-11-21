// PERSONNES-UNE-PAGE, etape (f) : la page unique porte les gestes de la page
// « Comptes ». L'apercu d'un compte offre ses gestes (sauf celui qui efface),
// chaque ligne garde son menu d'actions, et « Acces echus » est un filtre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/port_fondateurs.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_comptes/apercu_compte.dart';
import 'package:rewayah_academy/features/admin_comptes/gestes_compte.dart';
import 'package:rewayah_academy/features/admin_personnes/barre_filtres_personnes.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

class _Fondateurs implements PortFondateurs {
  final Set<String> fondateurs = <String>{};
  final List<(String, bool)> poses = <(String, bool)>[];

  @override
  Future<Set<String>> lire() async => <String>{...fondateurs};

  @override
  Future<bool> poser(String profilId, {required bool fondateur}) async {
    poses.add((profilId, fondateur));
    if (fondateur) {
      fondateurs.add(profilId);
    } else {
      fondateurs.remove(profilId);
    }
    return fondateur;
  }
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

CompteAdmin _compte(
  String id,
  String prenom,
  AppRole role, {
  AccountStatus etat = AccountStatus.active,
  bool demande = false,
  DateTime? accesJusquAu,
}) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-41$id',
  prenom: prenom,
  nom: 'Essai',
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(const Duration(days: 12)),
  accesJusquAu: accesJusquAu,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: role == AppRole.guardian ? 2 : 0,
  detailsServis: true,
  tranche: role == AppRole.student ? TrancheAge.enfant : null,
  admissionATraiter: demande,
);

final List<CompteAdmin> _comptes = <CompteAdmin>[
  _compte('1', 'Amina', AppRole.student),
  _compte(
    '2',
    'Bilal',
    AppRole.student,
    etat: AccountStatus.provisionalActive,
    accesJusquAu: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _compte('4', 'Driss', AppRole.guardian, demande: true),
  _compte('5', 'Esma', AppRole.admin),
];

late GoRouter _routeur;
late _Fondateurs _fondateurs;
late _Retraits _retraits;
Object? _extraDemande;

Future<void> _monter(
  WidgetTester tester, {
  required String adresse,
  Size taille = const Size(1440, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  _fondateurs = _Fondateurs();
  _retraits = _Retraits();
  _extraDemande = null;
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
              ouvrirDossier: (String _, String _) {},
            );
          },
        ),
        GoRoute(
          path: Routes.adminPersonnesAdmissions,
          builder: (BuildContext _, GoRouterState e) {
            _extraDemande = e.extra;
            return const Scaffold(body: Text('demandes'));
          },
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_Comptes(_comptes)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portFondateursProvider.overrideWithValue(_fondateurs),
        portRetraitsComptesProvider.overrideWithValue(_retraits),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

String get _adresse =>
    _routeur.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('equipe, ordinateur : l\'apercu offre « Marquer comme '
      'fondateur » ; le geste part au serveur et la page le dit', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=equipe&element=RA-26-415',
    );
    final Finder geste = find.descendant(
      of: find.byKey(PersonnesPage.cleApercu),
      matching: find.text(t.admin.comptes.actionMarquerFondateur),
    );
    expect(geste, findsOneWidget);
    await tester.tap(geste);
    await tester.pumpAndSettle();
    expect(_fondateurs.poses, <(String, bool)>[('5', true)]);
    expect(
      find.text(t.admin.comptes.fondateurMarque(nom: 'Esma Essai')),
      findsOneWidget,
    );
    // Le geste a change de sens : la coche est posee.
    expect(
      find.descendant(
        of: find.byKey(PersonnesPage.cleApercu),
        matching: find.text(t.admin.comptes.actionRetirerFondateur),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('familles, ordinateur : l\'apercu offre « Voir la demande » '
      '(le nom en `extra`, jamais dans l\'adresse) ; le geste qui efface '
      'n\'est pas dans l\'apercu', (WidgetTester tester) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=familles&element=RA-26-414',
    );
    final Finder apercu = find.byKey(PersonnesPage.cleApercu);
    expect(
      find.descendant(
        of: apercu,
        matching: find.text(t.admin.comptes.retrait.actionLigne),
      ),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: apercu,
        matching: find.text(t.admin.comptes.actionVoirDemande),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('demandes'), findsOneWidget);
    expect(_extraDemande, isNotNull);
    expect(_adresse, isNot(contains('Driss')));
    // Le retour rend la page, la personne choisie comprise.
    _routeur.pop();
    await tester.pumpAndSettle();
    expect(_adresse, contains('onglet=familles'));
    expect(_adresse, contains('element=RA-26-414'));
  });

  testWidgets('la ligne garde son menu d\'actions : « Supprimer ce compte » '
      'y est, avec sa confirmation ; le serveur recoit le compte, la page '
      'dit le bilan', (WidgetTester tester) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
    final Finder menus = find.byType(MenuActions);
    // Un menu par eleve (le menu « Outils » de l'en-tete n'en est pas un de
    // ligne : il porte une cle).
    final Finder deLigne = find.descendant(
      of: find.byKey(PersonnesPage.cleListe),
      matching: menus,
    );
    expect(deLigne, findsNWidgets(2));
    await tester.tap(deLigne.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.comptes.retrait.actionLigne).last);
    await tester.pumpAndSettle();
    // Rien n'est parti avant la confirmation.
    expect(_retraits.envois, isEmpty);
    await tester.tap(find.text(t.admin.comptes.retrait.confirmerUn).last);
    await tester.pumpAndSettle();
    expect(_retraits.envois, hasLength(1));
    expect(_retraits.envois.single, hasLength(1));
    expect(find.byKey(cleBilanSuppression), findsOneWidget);
    expect(find.text(t.admin.comptes.retrait.supprimes(n: 1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('telephone : la ligne ouvre l\'apercu en feuille, avec le '
      'geste du compte ; le menu de la ligne reste', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresse: '/admin/personnes?onglet=familles',
      taille: const Size(390, 844),
    );
    expect(
      find.descendant(
        of: find.byKey(PersonnesPage.cleListe),
        matching: find.byWidgetPredicate(
          (Widget w) => w is MenuActions && w.points,
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Driss Essai').first);
    await tester.pumpAndSettle();
    expect(find.byKey(cleApercuCompte), findsOneWidget);
    expect(find.byKey(cleGesteApercuCompte(0)), findsOneWidget);
    await tester.tap(find.byKey(cleGesteApercuCompte(0)));
    await tester.pumpAndSettle();
    expect(find.text('demandes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('« Acces echus » est un filtre : une puce, la liste et le '
      'compteur reduits', (WidgetTester tester) async {
    await _monter(tester, adresse: '/admin/personnes?onglet=eleves');
    String compteur() => tester
        .widget<Text>(find.byKey(BarreFiltresPersonnes.cleCompteur))
        .data!;
    expect(compteur(), '2 sur 2');
    await tester.tap(find.byKey(BarreFiltresPersonnes.cleFiltrer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.personnesPage.typeAcces).last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(t.admin.tableau.comptes).last);
    await tester.pumpAndSettle();
    expect(_adresse, contains('acces=echus'));
    expect(compteur(), '1 sur 2');
    expect(find.text('Bilal Essai'), findsWidgets);
    expect(find.text('Amina Essai'), findsNothing);
  });
}
