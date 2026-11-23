// FICHE-ELEVE-DIRECTION (directeur, 22/11/2026) : la fiche d'un eleve, lue par
// la direction. Etats (contenu, chargement, introuvable, erreur, hors ligne),
// tailles (390, 1280, 1440), arabe, identite masquee ; la ligne d'un eleve
// ouvre la fiche (ordinateur) ou la propose depuis l'apercu (telephone), et la
// famille mene a chacun de ses eleves.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/fiche_eleve_direction.dart';
import 'package:rewayah_academy/core/admin/port_fondateurs.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_personnes/fiche_eleve_direction_page.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

/// Ce que le serveur rend : un enfant dans une classe, avec ses reponses.
const Map<String, dynamic> _json = <String, dynamic>{
  'identite': <String, dynamic>{
    'id': 'e1',
    'matricule': 'RA-26-4817',
    'prenom': 'Yasmine',
    'nom': 'Benali',
    'genre': 'female',
    'tranche': 'enfant',
    'langue_cours': 'francais',
    'langue_communication': 'fr',
    'etat_compte': 'active',
    'inscrit_le': '2026-11-10T09:00:00Z',
    'foyer_id': 'f1',
    'est_titulaire': false,
  },
  'tuteur': <String, dynamic>{
    'id': 't1',
    'matricule': 'RA-26-4001',
    'prenom': 'Amina',
    'nom': 'Benali',
    'courriel': 'amina@example.test',
    'telephone': '+33 6 00 00 00 00',
  },
  'admission': <String, dynamic>{
    'age': 9,
    'niveau': 'lecture_lente',
    'objectif': 'devenir_fluide',
    'langue': 'fr',
    'moments': <String>['soir'],
    'source': 'mosquee',
  },
  'classes': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'c1',
      'libelle': 'Classe des lettres',
      'fuseau': 'Asia/Riyadh',
      'depuis': '2026-11-12T09:00:00Z',
      'enseignant': <String, dynamic>{
        'id': 'p1',
        'prenom': 'Salma',
        'nom': 'Idrissi',
      },
      'creneaux': <Map<String, dynamic>>[
        <String, dynamic>{'jour': 3, 'heure': 20, 'duree': 45},
      ],
    },
  ],
  'presences': <String, dynamic>{
    'total': 3,
    'presents': 2,
    'retards': 1,
    'absents': 0,
    'excuses': 0,
    'dernieres': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 's1',
        'debut': '2026-11-18T17:00:00Z',
        'statut': 'ended',
        'etat': 'presente',
      },
    ],
  },
  'progression': <String, dynamic>{
    'etape': 'Les bases',
    'ordre': 1,
    'cycle': 'bases',
    'depuis': '2026-11-12T09:00:00Z',
    'rythme': 'dans_les_temps',
  },
};

class _Port implements PortFicheEleveDirection {
  _Port(this._reponse);

  final Future<FicheEleveDirection?> Function() _reponse;

  @override
  Future<FicheEleveDirection?> lire(String eleveId) => _reponse();

  @override
  Future<ResultatDemandePaiement> demanderPaiement(String eleveId) async =>
      ResultatDemandePaiement.demandee;
}

Future<void> _monter(
  WidgetTester tester,
  Future<FicheEleveDirection?> Function() reponse, {
  Size taille = const Size(1440, 900),
  bool horsLigne = false,
  double echelle = 1,
  TextDirection? direction,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.adminPersonnesElevePour('e1'),
      echelle: echelle,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminPersonnesEleve,
          builder: (BuildContext _, GoRouterState e) => FicheEleveDirectionPage(
            eleveId: e.pathParameters['eleveId'] ?? '',
          ),
        ),
        GoRoute(
          path: Routes.adminPersonnes,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('liste-personnes')),
        ),
      ],
      surcharges: <Override>[
        portFicheEleveDirectionProvider.overrideWithValue(_Port(reponse)),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<FicheEleveDirection?> _fiche() async =>
    FicheEleveDirection.depuisJson(_json);

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('lecture du serveur', () {
    test('lit chaque section, sans rien inventer', () {
      final FicheEleveDirection f = FicheEleveDirection.depuisJson(_json)!;
      expect(f.libelle, 'Yasmine Benali');
      expect(f.matricule, 'RA-26-4817');
      expect(f.tuteur?.matricule, 'RA-26-4001');
      expect(f.admission?.age, 9);
      expect(f.classes.single.creneaux.single.heure, 20);
      expect(f.classes.single.enseignant, 'Salma Idrissi');
      expect(f.presences.total, 3);
      expect(f.presences.dernieres, hasLength(1));
      expect(f.progression?.etape, 'Les bases');
    });

    test('un eleve inconnu, ou une forme illisible, rend null', () {
      expect(FicheEleveDirection.depuisJson(null), isNull);
      expect(FicheEleveDirection.depuisJson('x'), isNull);
      expect(FicheEleveDirection.depuisJson(<String, dynamic>{}), isNull);
    });

    test('sans classe ni tuteur ni admission : des listes vides, jamais de '
        'valeur supposee', () {
      final FicheEleveDirection f = FicheEleveDirection.depuisJson(
        <String, dynamic>{
          'identite': <String, dynamic>{
            'id': 'x',
            'matricule': 'RA-1',
            'etat_compte': 'active',
          },
          'tuteur': null,
          'admission': null,
          'classes': <Object>[],
          'presences': <String, dynamic>{'total': 0, 'dernieres': <Object>[]},
          'progression': null,
        },
      )!;
      expect(f.tuteur, isNull);
      expect(f.admission, isNull);
      expect(f.classes, isEmpty);
      expect(f.presences.total, 0);
      expect(f.progression, isNull);
    });
  });

  for (final Size taille in const <Size>[
    Size(390, 844),
    Size(1280, 800),
    Size(1440, 900),
  ]) {
    testWidgets('contenu a ${taille.width.toInt()} : les sept sections, '
        'sans debordement', (WidgetTester tester) async {
      await _monter(tester, _fiche, taille: taille);
      expect(find.byKey(FicheEleveDirectionPage.cleEntete), findsOneWidget);
      for (final String nom in <String>[
        'identite',
        'admission',
        'progression',
        'famille',
        'classe',
        'presences',
        'compte',
      ]) {
        expect(
          find.byKey(
            FicheEleveDirectionPage.cleSection(nom),
            skipOffstage: false,
          ),
          findsOneWidget,
          reason: nom,
        );
      }
      expect(
        find.text('Classe des lettres', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Salma Idrissi', skipOffstage: false), findsOneWidget);
      expect(find.text('Les bases', skipOffstage: false), findsOneWidget);
      // Rien de ce que la page affiche n'est invente : pas d'« undefined ».
      expect(tester.takeException(), isNull);
      // Jamais plus large que la colonne bornee : pas de colonne de telephone
      // etiree sur un grand ecran.
      final Size entete = tester.getSize(
        find.byKey(FicheEleveDirectionPage.cleEntete),
      );
      expect(
        entete.width,
        lessThanOrEqualTo(FicheEleveDirectionPage.largeurMax),
      );
      if (taille.width >= 1200) {
        // Deux colonnes : la famille est a cote de l'identite, pas dessous.
        final Offset identite = tester.getTopLeft(
          find.byKey(FicheEleveDirectionPage.cleSection('identite')),
        );
        final Offset famille = tester.getTopLeft(
          find.byKey(FicheEleveDirectionPage.cleSection('famille')),
        );
        expect(famille.dx, isNot(identite.dx));
        expect(famille.dy, identite.dy);
      }
    });
  }

  group('arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    testWidgets('arabe, texte x2 a 390 : aucun debordement', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _fiche,
        taille: const Size(390, 844),
        echelle: 2,
        direction: TextDirection.rtl,
      );
      expect(find.text(t.admin.ficheEleve.identite.titre), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('chargement : un squelette, puis le contenu', (
    WidgetTester tester,
  ) async {
    final Completer<FicheEleveDirection?> c = Completer<FicheEleveDirection?>();
    await tester.runAsync(() async {});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteRoutant(
        depart: Routes.adminPersonnesElevePour('e1'),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.adminPersonnesEleve,
            builder: (BuildContext _, GoRouterState _) =>
                const FicheEleveDirectionPage(eleveId: 'e1'),
          ),
        ],
        surcharges: <Override>[
          portFicheEleveDirectionProvider.overrideWithValue(
            _Port(() => c.future),
          ),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pump();
    expect(find.byKey(FicheEleveDirectionPage.cleEntete), findsNothing);
    c.complete(FicheEleveDirection.depuisJson(_json));
    await tester.pumpAndSettle();
    expect(find.byKey(FicheEleveDirectionPage.cleEntete), findsOneWidget);
  });

  testWidgets('introuvable : la phrase dit pourquoi et ramene a la liste', (
    WidgetTester tester,
  ) async {
    await _monter(tester, () async => null);
    expect(find.text(t.admin.ficheEleve.introuvable.titre), findsOneWidget);
    await tester.tap(find.text(t.admin.ficheEleve.introuvable.retour));
    await tester.pumpAndSettle();
    expect(find.text('liste-personnes'), findsOneWidget);
  });

  testWidgets('erreur : on peut reessayer', (WidgetTester tester) async {
    int appels = 0;
    await _monter(tester, () async {
      appels++;
      if (appels == 1) throw StateError('echec');
      return _fiche();
    });
    expect(find.byKey(FicheEleveDirectionPage.cleEntete), findsNothing);
    await tester.tap(find.text(t.commun.reessayer));
    await tester.pumpAndSettle();
    expect(find.byKey(FicheEleveDirectionPage.cleEntete), findsOneWidget);
  });

  testWidgets('hors ligne sans donnees : l\'etat dit ce qui manque', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      () async => throw StateError('hors ligne'),
      horsLigne: true,
    );
    expect(find.text(t.admin.ficheEleve.sansDonnees), findsOneWidget);
  });

  testWidgets('identite masquee : seul le matricule se lit', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> masque = <String, dynamic>{
      ..._json,
      'identite': <String, dynamic>{
        ...(_json['identite'] as Map<String, dynamic>),
        'prenom': null,
        'nom': null,
      },
      'tuteur': <String, dynamic>{'id': 't1', 'matricule': 'RA-26-4001'},
    };
    await _monter(tester, () async => FicheEleveDirection.depuisJson(masque));
    expect(find.text('Yasmine'), findsNothing);
    expect(find.text(t.admin.ficheEleve.identite.masquee), findsOneWidget);
    expect(find.text(t.admin.ficheEleve.famille.tuteurMasque), findsOneWidget);
  });

  testWidgets('sans classe, sans reponse, sans seance : des phrases vraies, '
      'aucune donnee inventee', (WidgetTester tester) async {
    final FicheEleveDirection vide = FicheEleveDirection.depuisJson(
      <String, dynamic>{
        'identite': <String, dynamic>{
          'id': 'e1',
          'matricule': 'RA-26-4817',
          'prenom': 'Karim',
          'nom': 'Adulte',
          'tranche': 'adulte',
          'etat_compte': 'pending_kyc',
        },
        'tuteur': null,
        'admission': null,
        'classes': <Object>[],
        'presences': <String, dynamic>{'total': 0, 'dernieres': <Object>[]},
        'progression': null,
      },
    )!;
    await _monter(tester, () async => vide);
    expect(find.text(t.admin.ficheEleve.classe.aucune), findsOneWidget);
    expect(find.text(t.admin.ficheEleve.admission.aucune), findsOneWidget);
    expect(find.text(t.admin.ficheEleve.presences.aucune), findsOneWidget);
    expect(find.text(t.admin.ficheEleve.famille.sansTuteur), findsOneWidget);
    expect(find.text(t.admin.ficheEleve.progression.aucune), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('depuis Personnes', () {
    CompteAdmin compte(String id, String prenom, AppRole role, String? foyer) =>
        CompteAdmin(
          profilId: id,
          identifiant: 'RA-26-41$id',
          prenom: prenom,
          nom: 'Essai',
          role: role,
          etat: AccountStatus.active,
          inscritLe: DateTime.now().subtract(const Duration(days: 12)),
          accesJusquAu: null,
          foyerId: foyer,
          piece: EtatPiece.aucune,
          contrats: 0,
          aEnseignant: false,
          enfantsDuFoyer: role == AppRole.guardian ? 2 : 0,
          detailsServis: true,
          tranche: role == AppRole.student ? TrancheAge.enfant : null,
        );
    final List<CompteAdmin> comptes = <CompteAdmin>[
      compte('1', 'Amina', AppRole.student, 'f1'),
      compte('2', 'Bilal', AppRole.student, 'f1'),
      compte('4', 'Driss', AppRole.guardian, 'f1'),
    ];

    Future<GoRouter> monter(
      WidgetTester tester,
      String adresse,
      Size taille,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = taille;
      addTearDown(tester.view.reset);
      late GoRouter routeur;
      await tester.pumpWidget(
        hoteRoutant(
          depart: adresse,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.adminPersonnes,
              builder: (BuildContext contexte, GoRouterState e) {
                routeur = GoRouter.of(contexte);
                return PersonnesPage(
                  requete: e.uri.queryParameters,
                  ouvrirDossier: (String _, String _) {},
                );
              },
            ),
            GoRoute(
              path: Routes.adminPersonnesEleve,
              builder: (BuildContext _, GoRouterState e) =>
                  Scaffold(body: Text('fiche-${e.pathParameters['eleveId']}')),
            ),
          ],
          surcharges: <Override>[
            serviceComptesProvider.overrideWithValue(_Comptes(comptes)),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            portFondateursProvider.overrideWithValue(_Fondateurs()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return routeur;
    }

    testWidgets('ordinateur : la ligne d\'un eleve ouvre sa fiche', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        '/admin/personnes?onglet=eleves',
        const Size(1440, 900),
      );
      await tester.tap(find.text('Amina Essai').first);
      await tester.pumpAndSettle();
      expect(find.text('fiche-1'), findsOneWidget);
    });

    testWidgets('telephone : l\'apercu propose « Ouvrir la fiche »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        '/admin/personnes?onglet=eleves',
        const Size(390, 844),
      );
      await tester.tap(find.text('Amina Essai').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.ficheEleve.ouvrir));
      await tester.pumpAndSettle();
      expect(find.text('fiche-1'), findsOneWidget);
    });

    testWidgets('famille : un geste par eleve du foyer', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        '/admin/personnes?onglet=familles',
        const Size(390, 844),
      );
      await tester.tap(find.text('Driss Essai').first);
      await tester.pumpAndSettle();
      expect(
        find.text(t.admin.ficheEleve.ouvrirDe(dePrenom: deDevant('Amina'))),
        findsOneWidget,
      );
      await tester.tap(
        find.text(t.admin.ficheEleve.ouvrirDe(dePrenom: deDevant('Bilal'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('fiche-2'), findsOneWidget);
    });
  });
}

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

class _Fondateurs implements PortFondateurs {
  @override
  Future<Set<String>> lire() async => <String>{};

  @override
  Future<bool> poser(String profilId, {required bool fondateur}) async =>
      fondateur;
}
