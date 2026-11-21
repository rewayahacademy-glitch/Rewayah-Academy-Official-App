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
    show LigneCandidature;
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart'
    show nomAffiche;
import 'package:rewayah_academy/features/admin_comptes/apercu_compte.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';
import 'package:rewayah_academy/features/com_messages/apercu_profil_candidat.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste, {this.echec = false});

  final List<CompteAdmin> _liste;
  final bool echec;

  @override
  Future<List<CompteAdmin>> comptes() async =>
      echec ? throw StateError('panne') : _liste;
}

class _Enseignants implements PortEnseignants {
  const _Enseignants(this._lignes);

  final List<LigneEnseignant> _lignes;

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async => PageEnseignants(
    lignes: _lignes,
    total: _lignes.length,
    page: 1,
    taillePage: 50,
  );
}

CompteAdmin _compte(String id, String prenom, AppRole role) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-41$id',
  prenom: prenom,
  nom: 'Essai',
  role: role,
  etat: AccountStatus.active,
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
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  _dossiers.clear();
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
    expect(find.byKey(ApercuProfilCandidat.cle), findsOneWidget);
    await tester.tap(find.byKey(ApercuProfilCandidat.cleDossier));
    await tester.pumpAndSettle();
    expect(_dossiers, <String>['/admin/personnes/candidatures/CAND-00001']);
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
