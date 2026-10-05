// CARTES-PERSO-1 : captures de preuve des cartes de la classe.
//
// L'emplacement seul (famille, enseignant, Interface guidee) a 320 px texte
// x2 en LTR et RTL, clair et sombre ; ses etats a 390 ; la feuille de
// l'enseignant ; les vrais ecrans de la demonstration (Espace Classe eleve,
// Espace Classe enseignant et sa feuille, Ma classe en Interface guidee, Ma
// classe de l'adulte) a 390 et 1440.
//
// Sautees sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../features/classe_tuteur/support_classe.dart';
import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

const String _id = 'classe-capture';

Widget _app({
  required Widget Function(BuildContext) ecran,
  List<Override> surcharges = const <Override>[],
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  InterfaceMode mode = InterfaceMode.standard,
  String? adresse,
}) {
  final GoRouter routeur = GoRouter(
    initialLocation: adresse ?? '/capture',
    routes: <RouteBase>[
      GoRoute(path: '/capture', builder: (BuildContext c, _) => ecran(c)),
      ...routesDemoClasse('dev'),
      ...routesDemoAdulte('dev'),
    ],
  );
  addTearDown(routeur.dispose);
  return ProviderScope(
    overrides: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ...surcharges,
    ],
    child: TranslationProvider(
      child: RepaintBoundary(
        key: cadreCapture,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(mode, luminosite),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext c, Widget? app) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: Directionality(textDirection: sens, child: app!),
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
}

Widget _page(Widget enfant) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: enfant,
  ),
);

List<Override> _demo({required bool peutModifier, List<CarteClasse>? cartes}) =>
    <Override>[
      portCartesClasseProvider.overrideWith(
        (Ref _) => PortCartesClasseDemo(
          peutModifier: peutModifier,
          cartes: cartes ?? cartesClasseDemo(DateTime(2026, 10, 8)),
        ),
      ),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    ];

/// Un etat du bloc, sous son propre conteneur, avec une legende de test.
Widget _etat(String legende, List<Override> surcharges) => ProviderScope(
  // La famille aussi : sous un conteneur imbrique, elle se resoudrait sinon
  // dans le conteneur racine.
  overrides: <Override>[
    ...surcharges,
    cartesClasseProvider(
      _id,
    ).overrideWith((Ref ref) => ref.watch(portCartesClasseProvider).lire(_id)),
  ],
  child: Builder(
    builder: (BuildContext c) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(legende, style: Theme.of(c).textTheme.labelLarge),
        Ecart.vSm,
        const BlocCartesClasse(groupeId: _id),
        Ecart.vSection,
      ],
    ),
  ),
);

class _PortFige implements PortCartesClasse {
  _PortFige(this.lecture);
  final Future<CartesClasseVM> Function() lecture;
  @override
  Future<CartesClasseVM> lire(String groupeId) => lecture();
  @override
  Future<CarteClasse> enregistrer(
    String groupeId,
    BrouillonCarte brouillon, {
    String? carteId,
  }) => throw StateError('capture');
  @override
  Future<void> retirer(String groupeId, String carteId) =>
      throw StateError('capture');
}

void main() {
  group('Capture : CARTES-PERSO-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final List<(String, bool, InterfaceMode)> profils =
        <(String, bool, InterfaceMode)>[
          ('famille', false, InterfaceMode.standard),
          ('enseignant', true, InterfaceMode.standard),
          ('guidee', false, InterfaceMode.enfant),
        ];
    for (final (String nom, bool peutModifier, InterfaceMode mode) in profils) {
      for (final (TextDirection sens, Brightness lum)
          in <(TextDirection, Brightness)>[
            (TextDirection.ltr, Brightness.light),
            (TextDirection.rtl, Brightness.dark),
          ]) {
        testWidgets('bloc $nom 320 x2 ${sens.name} ${lum.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 1500), 2);
          await tester.pumpWidget(
            _app(
              ecran: (_) => _page(const BlocCartesClasse(groupeId: _id)),
              surcharges: _demo(peutModifier: peutModifier),
              echelle: 2,
              sens: sens,
              luminosite: lum,
              mode: mode,
            ),
          );
          await stabiliser(tester);
          await capturer(
            tester,
            'bloc_${nom}_320x2_${sens.name}_'
            '${lum == Brightness.light ? 'clair' : 'sombre'}',
          );
        });
      }
    }

    testWidgets('etats 390', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 2000), 2);
      final Completer<CartesClasseVM> jamais = Completer<CartesClasseVM>();
      await tester.pumpWidget(
        _app(
          ecran: (_) => _page(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _etat('Production (avant BR-1)', <Override>[
                  portCartesClasseProvider.overrideWithValue(
                    const PortCartesClasseIndisponible(),
                  ),
                ]),
                _etat('Chargement', <Override>[
                  portCartesClasseProvider.overrideWithValue(
                    _PortFige(() => jamais.future),
                  ),
                ]),
                _etat('Erreur', <Override>[
                  portCartesClasseProvider.overrideWithValue(
                    _PortFige(
                      () => Future<CartesClasseVM>.error(StateError('x')),
                    ),
                  ),
                ]),
                _etat(
                  'Vide, famille',
                  _demo(peutModifier: false, cartes: <CarteClasse>[]),
                ),
                _etat(
                  'Vide, enseignant',
                  _demo(peutModifier: true, cartes: <CarteClasse>[]),
                ),
                _etat('Hors ligne, rien de lu', <Override>[
                  portCartesClasseProvider.overrideWithValue(
                    _PortFige(
                      () => Future<CartesClasseVM>.error(StateError('x')),
                    ),
                  ),
                  horsLigneProvider.overrideWith(
                    (Ref _) => Stream<bool>.value(true),
                  ),
                ]),
                _etat('Hors ligne, enseignant', <Override>[
                  ..._demo(peutModifier: true).take(1),
                  horsLigneProvider.overrideWith(
                    (Ref _) => Stream<bool>.value(true),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
      await stabiliser(tester);
      await capturer(tester, 'etats_390_clair');
      jamais.complete(const CartesClasseVM(cartes: <CarteClasse>[]));
    });

    for (final (TextDirection sens, Brightness lum)
        in <(TextDirection, Brightness)>[
          (TextDirection.ltr, Brightness.light),
          (TextDirection.rtl, Brightness.dark),
        ]) {
      testWidgets('feuille 320 x2 ${sens.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 3200), 2);
        await tester.pumpWidget(
          _app(
            ecran: (_) => _page(const FeuilleCarteClasse(groupeId: _id)),
            surcharges: _demo(peutModifier: true),
            echelle: 2,
            sens: sens,
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        await tester.tap(
          find.byKey(const ValueKey<String>('classe.cartes.modele.devoir')),
        );
        await tester.enterText(find.byKey(FeuilleCarteClasse.lienKey), 'www');
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await stabiliser(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
        await stabiliser(tester);
        await capturer(
          tester,
          'feuille_320x2_${sens.name}_'
          '${lum == Brightness.light ? 'clair' : 'sombre'}',
        );
      });
    }

    for (final (Size vue, Brightness lum) in <(Size, Brightness)>[
      (const Size(390, 2600), Brightness.light),
      (const Size(1440, 1400), Brightness.light),
    ]) {
      final String suffixe = '${vue.width.toInt()}_clair';
      testWidgets('page eleve $suffixe', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          _app(
            ecran: (_) => const SizedBox.shrink(),
            adresse: adresseDemoClasse(RoleEntree.eleve, EtatDemoClasse.aVenir),
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        expect(find.byType(BlocCartesClasse), findsOneWidget);
        await capturer(tester, 'page_eleve_$suffixe');
      });
    }

    for (final (Size vue, Brightness lum) in <(Size, Brightness)>[
      (const Size(390, 3000), Brightness.light),
      (const Size(1440, 1700), Brightness.dark),
    ]) {
      final String suffixe =
          '${vue.width.toInt()}_${lum == Brightness.light ? 'clair' : 'sombre'}';
      testWidgets('page enseignant $suffixe, puis sa feuille', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          _app(
            ecran: (_) => const SizedBox.shrink(),
            adresse: adresseDemoClasse(
              RoleEntree.enseignant,
              EtatDemoClasse.aVenir,
            ),
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        expect(find.byType(BlocCartesClasse), findsOneWidget);
        await capturer(tester, 'page_enseignant_$suffixe');
        await tester.ensureVisible(
          find.text(texteAffiche('Récitation modèle')),
        );
        await tester.tap(find.text(texteAffiche('Récitation modèle')));
        await stabiliser(tester);
        expect(find.byType(FeuilleCarteClasse), findsOneWidget);
        await capturer(tester, 'page_enseignant_feuille_$suffixe');
        // Revue CARTES-PERSO-1 : sur la vraie page de demonstration,
        // l'enregistrement aboutit (la feuille lit le conteneur de la page).
        await tester.enterText(
          find.byKey(FeuilleCarteClasse.titreKey),
          'Récitation de la sourate Quraysh',
        );
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await stabiliser(tester);
        expect(find.byType(FeuilleCarteClasse), findsNothing);
        expect(find.text(t.classe.cartes.enregistree), findsOneWidget);
        await tester.ensureVisible(find.text(t.classe.cartes.enregistree));
        await stabiliser(tester);
        await capturer(tester, 'page_enseignant_enregistree_$suffixe');
      });
    }

    testWidgets('Ma classe en Interface guidee 390 et 320 x2', (
      WidgetTester tester,
    ) async {
      for (final (Size vue, double echelle, String nom)
          in <(Size, double, String)>[
            (const Size(390, 3400), 1, 'page_guidee_390_clair'),
            (const Size(320, 6400), 2, 'page_guidee_320x2_clair'),
          ]) {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          _app(
            ecran: (_) => const EcranEleveDemo(
              etat: EtatDemoClasse.aVenir,
              titreDestination: 'Ma classe',
              tutoiement: true,
            ),
            mode: InterfaceMode.enfant,
            echelle: echelle,
          ),
        );
        await stabiliser(tester);
        expect(find.byType(BlocCartesClasse), findsOneWidget);
        await capturer(tester, nom);
      }
    });

    for (final (Size vue, Brightness lum) in <(Size, Brightness)>[
      (const Size(390, 3200), Brightness.dark),
      (const Size(1440, 1500), Brightness.light),
    ]) {
      final String suffixe =
          '${vue.width.toInt()}_${lum == Brightness.light ? 'clair' : 'sombre'}';
      testWidgets('Ma classe adulte $suffixe', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          _app(
            ecran: (_) => const SizedBox.shrink(),
            adresse: adresseDemoAdulte(EcranDemoAdulte.maClasse),
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        expect(find.byType(BlocCartesClasse), findsOneWidget);
        await capturer(tester, 'page_adulte_$suffixe');
      });
    }
    // Revue CARTES-PERSO-1 : la lecture du tuteur sur la VRAIE page
    // `ClasseTuteurPage`, montee par le vrai routeur (capacite fausse).
    for (final (Size vue, Brightness lum, double echelle, TextDirection sens)
        in <(Size, Brightness, double, TextDirection)>[
          (const Size(390, 2400), Brightness.light, 1, TextDirection.ltr),
          (const Size(1440, 1400), Brightness.dark, 1, TextDirection.ltr),
          (const Size(320, 5200), Brightness.light, 2, TextDirection.ltr),
          (const Size(320, 5200), Brightness.dark, 2, TextDirection.rtl),
        ]) {
      final String nom =
          'page_tuteur_${vue.width.toInt()}${echelle == 2 ? 'x2' : ''}_'
          '${sens.name}_${lum == Brightness.light ? 'clair' : 'sombre'}';
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        late GoRouter routeur;
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...surchargesClasse(),
              ...surchargesCartesClasseDemo(classeA, peutModifier: false),
            ],
            child: TranslationProvider(
              child: RepaintBoundary(
                key: cadreCapture,
                child: Consumer(
                  builder: (BuildContext _, WidgetRef ref, Widget? _) {
                    routeur = ref.read(routeurProvider);
                    return MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.pour(InterfaceMode.standard, lum),
                      locale: AppLocale.fr.flutterLocale,
                      supportedLocales: AppLocaleUtils.supportedLocales,
                      localizationsDelegates:
                          GlobalMaterialLocalizations.delegates,
                      builder: (BuildContext c, Widget? app) => MediaQuery(
                        data: MediaQuery.of(c)
                            .copyWith(textScaler: TextScaler.linear(echelle)),
                        child: Directionality(textDirection: sens, child: app!),
                      ),
                      routerConfig: routeur,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await stabiliser(tester);
        routeur.go(Routes.classePour(classeA, eleveId: eleveA1));
        await stabiliser(tester);
        expect(find.byType(ClasseTuteurPage), findsOneWidget);
        expect(find.byType(VueCarteClasse), findsNWidgets(3));
        await capturer(tester, nom);
      });
    }
  });
}
