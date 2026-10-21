// RECH-D1 : les moteurs « classes » et « supports », sur les ports que
// l'application lit deja (`PortGroupes`, `PortCatalogue`), et l'entree
// contextuelle de l'Espace Classe (spec RECH-03 §3, §4.1, §6.1, §8.2).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/recherche/domaines/classes_supports/moteur_classes_groupes.dart';
import 'package:rewayah_academy/features/recherche/domaines/classes_supports/moteur_supports_catalogue.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/entree_recherche.dart';

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';

const ContexteRecherche _famille = ContexteRecherche(
  espace: EspaceRecherche.famille,
);

LibraryResource _support(
  String id,
  String titre, {
  String categorie = 'Coran',
}) => LibraryResource(
  id: id,
  title: titre,
  shortTitle: titre,
  resourceType: TypeRessource.lecon,
  language: 'fr',
  category: categorie,
  accessPolicy: PolitiqueAcces.inscrits,
  offlinePolicy: PolitiqueOffline.surDemande,
);

class _GroupesEnPanne implements PortGroupes {
  @override
  Future<List<GroupSummaryVM>> mesGroupes() =>
      Future<List<GroupSummaryVM>>.error(StateError('reseau'));

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) =>
      Future<GroupSummaryVM?>.error(StateError('reseau'));
}

void main() {
  group('moteur des classes (PortGroupes)', () {
    final MoteurClassesGroupes moteur = MoteurClassesGroupes(
      GroupesDemonstrationLocale(),
    );

    test('trouve une classe par son nom, sans accent ni casse', () async {
      final ReponseDomaine r = await moteur.rechercher(
        requete: 'al-fatiha',
        contexte: _famille,
      );
      final ReponseOk ok = r as ReponseOk;
      expect(ok.elements.map((ResultatRecherche e) => e.titre), <String>[
        'Classe Al-Fatiha',
      ]);
      expect(ok.elements.single.cible.kind, KindCible.classe);
    });

    test('trouve par le cours et par le nom de l\'enseignant', () async {
      final ReponseOk parCours = await moteur.rechercher(
        requete: 'memorisation',
        contexte: _famille,
      ) as ReponseOk;
      expect(parCours.elements, isNotEmpty);
      final ReponseOk parEnseignant = await moteur.rechercher(
        requete: 'youssouf',
        contexte: _famille,
      ) as ReponseOk;
      expect(
        parEnseignant.elements.map((ResultatRecherche e) => e.titre),
        contains('Classe Al-Fatiha'),
      );
    });

    test('un champ non cherchable ne fait pas matcher (effectif, '
        'identifiant)', () async {
      for (final String requete in <String>['demo', 'groupe', 'seuil']) {
        final ReponseOk r = await moteur.rechercher(
          requete: requete,
          contexte: _famille,
        ) as ReponseOk;
        expect(r.elements, isEmpty, reason: requete);
      }
    });

    test(
      'rien ne montre un identifiant dans le titre ni le contexte',
      () async {
        final ReponseOk r = await moteur.rechercher(
          requete: 'classe',
          contexte: _famille,
        ) as ReponseOk;
        for (final ResultatRecherche e in r.elements) {
          expect(e.titre, isNot(contains('demo-')));
          expect(e.contexte ?? '', isNot(contains('demo-')));
        }
      },
    );

    test('une classe fermee n\'est jamais trouvee', () async {
      final MoteurClassesGroupes m = MoteurClassesGroupes(_GroupesFermes());
      final ReponseOk r = await m.rechercher(
        requete: 'fatiha',
        contexte: _famille,
      ) as ReponseOk;
      expect(r.elements, isEmpty);
    });

    test(
      'l\'administration n\'a pas ce domaine : absent, pas desactive',
      () async {
        const ContexteRecherche admin = ContexteRecherche(
          espace: EspaceRecherche.administration,
        );
        expect(await moteur.disponiblePour(admin), isFalse);
        expect(await moteur.disponiblePour(_famille), isTrue);
        final ReponseDomaine r = await moteur.rechercher(
          requete: 'fatiha',
          contexte: admin,
        );
        expect(r, isA<ReponseEchec>());
      },
    );

    test('pagination par curseur lie a la requete et a l\'espace', () async {
      final ReponseOk page1 = await moteur.rechercher(
        requete: 'classe',
        contexte: _famille,
        limite: 2,
      ) as ReponseOk;
      expect(page1.elements.length, 2);
      expect(page1.aPlus, isTrue);
      final ReponseOk page2 = await moteur.rechercher(
        requete: 'classe',
        contexte: _famille,
        limite: 2,
        curseur: page1.curseurSuivant,
      ) as ReponseOk;
      expect(
        page2.elements
            .map((ResultatRecherche e) => e.reference)
            .toSet()
            .intersection(
              page1.elements.map((ResultatRecherche e) => e.reference).toSet(),
            ),
        isEmpty,
      );
      final ReponseDomaine autre = await moteur.rechercher(
        requete: 'baqara',
        contexte: _famille,
        curseur: page1.curseurSuivant,
      );
      expect((autre as ReponseEchec).statut, StatutRecherche.curseurPerime);
      final ReponseDomaine falsifie = await moteur.rechercher(
        requete: 'classe',
        contexte: _famille,
        curseur: 'c1.0.9999',
      );
      expect((falsifie as ReponseEchec).statut, StatutRecherche.curseurPerime);
    });
  });

  group('moteur des supports (PortCatalogue)', () {
    final MoteurSupportsCatalogue moteur = MoteurSupportsCatalogue(
      CatalogueLocal(
        ressources: <LibraryResource>[
          _support('s1', 'Al-Fatiha, lecture'),
          _support('s2', 'Révision des lettres', categorie: 'Lecture'),
          _support('s3', 'Récitation guidée', categorie: 'Coran'),
        ],
      ),
    );

    test('trouve par le titre, sans accent', () async {
      final ReponseOk r = await moteur.rechercher(
        requete: 'revision',
        contexte: _famille,
      ) as ReponseOk;
      expect(r.elements.map((ResultatRecherche e) => e.titre), <String>[
        'Révision des lettres',
      ]);
      expect(r.elements.single.contexte, 'Lecture');
      expect(
        r.elements.single.cible,
        const CibleRecherche(kind: KindCible.support, reference: 's2'),
      );
    });

    test('aucun correspondant : vide confirme (ok et aucun element)', () async {
      final ReponseDomaine r = await moteur.rechercher(
        requete: 'zzzzzz',
        contexte: _famille,
      );
      expect(r, isA<ReponseOk>());
      expect((r as ReponseOk).elements, isEmpty);
    });

    test('aucun lien ni adresse de fichier dans le resultat', () async {
      final ReponseOk r = await moteur.rechercher(
        requete: 'lecture',
        contexte: _famille,
      ) as ReponseOk;
      for (final ResultatRecherche e in r.elements) {
        expect(e.titre, isNot(contains('http')));
        expect(e.extrait, isNull);
      }
    });

    test('un espace sans ce domaine : absent', () async {
      expect(
        await moteur.disponiblePour(
          const ContexteRecherche(espace: EspaceRecherche.administration),
        ),
        isFalse,
      );
    });
  });

  group('les deux moteurs sur la surface /recherche', () {
    Future<GoRouter> monter(WidgetTester tester, {PortGroupes? groupes}) =>
        monterRouteur(
          tester,
          Routes.recherche,
          source: FausseSourceSession(sessionActive(AppRole.guardian)),
          surcharges: <Override>[
            moteursRechercheProvider.overrideWithValue(<MoteurRechercheDomaine>[
              MoteurClassesGroupes(groupes ?? GroupesDemonstrationLocale()),
              MoteurSupportsCatalogue(
                CatalogueLocal(
                  ressources: <LibraryResource>[
                    _support('s1', 'Al-Fatiha, lecture'),
                  ],
                ),
              ),
            ]),
          ],
        );

    Future<void> chercher(WidgetTester tester, String texte) async {
      await tester.enterText(find.byKey(cleChampRecherche), texte);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('classes et supports ensemble, un seul geste', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      await chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Classes'), findsOneWidget);
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsOneWidget);
      expect(find.byType(SettingRow), findsNWidgets(2));
    });

    testWidgets('les classes en panne : les supports restent, la panne se dit '
        'domaine par domaine (jamais un vide)', (WidgetTester tester) async {
      await monter(tester, groupes: _GroupesEnPanne());
      await chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsOneWidget);
      expect(
        find.text('La recherche dans ce domaine est indisponible.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer ce domaine'), findsOneWidget);
      expect(find.text('Aucun résultat pour cette recherche.'), findsNothing);
    });
  });

  group('entree contextuelle', () {
    testWidgets('rendue seulement si le domaine des supports est servi, et '
        'ouvre la meme surface bornee aux supports', (
      WidgetTester tester,
    ) async {
      final List<String> ouvertures = <String>[];
      final GoRouter routeur = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => const Scaffold(
              body: EntreeRechercheSupports(espace: EspaceRecherche.famille),
            ),
          ),
          GoRoute(
            path: Routes.recherche,
            builder: (BuildContext _, GoRouterState etat) {
              ouvertures.add(etat.uri.toString());
              return const Scaffold(body: Text('recherche'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        _hoteRouteur(routeur, moteurs: moteursSupportsSeuls()),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Rechercher dans les supports'), findsOneWidget);
      await tester.tap(find.text('Rechercher dans les supports'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(ouvertures, <String>['/recherche?domaine=supports']);
    });

    testWidgets('aucun moteur raccorde : l\'entree n\'est pas rendue', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => const Scaffold(
              body: EntreeRechercheSupports(espace: EspaceRecherche.famille),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        _hoteRouteur(routeur, moteurs: const <MoteurRechercheDomaine>[]),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Rechercher dans les supports'), findsNothing);
    });
  });
}

List<MoteurRechercheDomaine> moteursSupportsSeuls() => <MoteurRechercheDomaine>[
  MoteurSupportsCatalogue(CatalogueLocal()),
];

Widget _hoteRouteur(
  GoRouter routeur, {
  required List<MoteurRechercheDomaine> moteurs,
}) => ProviderScope(
  overrides: <Override>[
    moteursRechercheProvider.overrideWithValue(moteurs),
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(sessionActive(AppRole.guardian)),
    ),
  ],
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      routerConfig: routeur,
    ),
  ),
);

class _GroupesFermes implements PortGroupes {
  @override
  Future<List<GroupSummaryVM>> mesGroupes() async {
    final List<GroupSummaryVM> tous = await GroupesDemonstrationLocale()
        .mesGroupes();
    return <GroupSummaryVM>[
      for (final GroupSummaryVM g in tous)
        GroupSummaryVM(
          groupeId: g.groupeId,
          libelle: g.libelle,
          couleurJeton: g.couleurJeton,
          enseignant: g.enseignant,
          nombreMembres: g.nombreMembres,
          seuilMax: g.seuilMax,
          typePublic: g.typePublic,
          actif: false,
          nomCours: g.nomCours,
          niveauHumain: g.niveauHumain,
        ),
    ];
  }

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) async => null;
}
