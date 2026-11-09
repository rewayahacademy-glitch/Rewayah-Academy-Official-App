// ACCUEIL-TUTEUR-UNE-PORTE (directeur, 09/11/2026) : la rangee des profils est
// le premier bloc de l'Accueil famille, a la meme place pour tout le monde.
// Sous le profil du TITULAIRE, et seulement quand la capacite « eleve autonome »
// est servie, un lien « Ouvrir mon espace eleve » mene a l'espace d'eleve ; un
// profil d'enfant n'en a pas. Le retour vers le foyer, dans l'espace adulte,
// ne change pas.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/session/atterrissage_adulte.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/retour_accueil_famille.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';

import '../../capture/outil_capture.dart'
    show
        cadreCapture,
        capturerVue,
        chargerPolicesDuDepot,
        masquerRubanDebug,
        sautSansCapture;
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import '../../router/support_routeur.dart';
import '../../support/demo/adulte_demo.dart';
import '../../support/harnais.dart';
import '../accueil_adulte/support_accueil_adulte_route.dart'
    show Valeur, accueilDemo, surchargesAccueilAdulte;

/// Le profil eleve du titulaire : l'identifiant de son propre compte.
const String _titulaireId = 'p-guardian';
const String _enfantId = 'enfant-1';

/// Le titulaire passe en tete du tri par prenom (« Aaron »), l'enfant en
/// second (« Zoe ») : le profil retenu par defaut est celui du titulaire.
const EleveDuFoyer _titulaire = EleveDuFoyer(
  id: _titulaireId,
  prenom: 'Aaron',
  identifiantImmuable: 'STUD-TIT-000001',
  mode: InterfaceMode.standard,
  camera: CameraPolicy.forbidden,
);

const EleveDuFoyer _enfant = EleveDuFoyer(
  id: _enfantId,
  prenom: 'Zoe',
  identifiantImmuable: 'STUD-ENF-000001',
  mode: InterfaceMode.enfant,
  camera: CameraPolicy.forbidden,
);

Future<GoRouter> _monter(
  WidgetTester tester, {
  bool autonome = true,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
  String depart = Routes.tuteurAccueil,
  UsageTitulaire usage = UsageTitulaire.famille,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = const <EleveDuFoyer>[_titulaire, _enfant]
    ..appareilsRendus = <AppareilAppaire>[];
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        ...surchargesAccueilAdulte(
          accueil: Valeur(accueilDemo()),
          historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
        ),
        portCapaciteEleveProvider.overrideWithValue(
          PortCapaciteEleveFactice(
            autonomes: autonome ? <String>{_titulaireId} : <String>{},
          ),
        ),
        usageTitulaireProvider.overrideWith((Ref _, String _) async => usage),
        portSeancesFamilleProvider.overrideWithValue(FauxSeancesFamille()),
        portClassesFoyerProvider.overrideWithValue(
          FauxClassesFoyer(classes: const <ClasseFoyer>[]),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext _, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: theme,
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext c, Widget? app) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: Directionality(textDirection: direction, child: app!),
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
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

Future<void> _choisir(WidgetTester tester, String prenom) async {
  await tester.tap(
    find.descendant(
      of: find.byType(SelecteurProfils),
      matching: find.textContaining(prenom),
    ),
  );
  await stabiliser(tester);
}

Finder get _lien => find.byKey(AccueilFamillePage.espaceEleveKey);

void main() {
  group('Sous le profil du titulaire, et nulle part ailleurs', () {
    testWidgets('titulaire choisi : le lien est sous la rangee, et mene a '
        'l espace d eleve ; le retour ramene au foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      expect(find.byType(AccueilFamillePage), findsOneWidget);
      expect(_lien, findsOneWidget);
      expect(find.text(t.tuteur.accueil.ouvrirEspaceEleve), findsOneWidget);
      // Sous la rangee des profils, jamais au-dessus.
      expect(
        tester.getTopLeft(_lien).dy,
        greaterThan(tester.getBottomLeft(find.byType(SelecteurProfils)).dy - 1),
      );

      await tester.tap(_lien);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);

      final Finder retour = find.byKey(retourAccueilFamilleKey);
      await tester.ensureVisible(retour);
      await stabiliser(tester);
      expect(retour, findsOneWidget);
      await tester.tap(retour);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('un profil d enfant choisi : aucun lien', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _choisir(tester, 'Zoe');
      expect(_lien, findsNothing);
      // Et il revient avec le profil du titulaire.
      await _choisir(tester, 'Aaron');
      expect(_lien, findsOneWidget);
    });

    testWidgets('sans la capacite, meme le profil du titulaire n a aucun '
        'lien', (WidgetTester tester) async {
      await _monter(tester, autonome: false);
      expect(find.byType(AccueilFamillePage), findsOneWidget);
      expect(_lien, findsNothing);
    });

    testWidgets('la rangee est le premier bloc, a la meme place pour tous : '
        'titulaire, enfant, sans capacite', (WidgetTester tester) async {
      await _monter(tester);
      final Offset titulaire = tester.getTopLeft(find.byType(SelecteurProfils));
      await _choisir(tester, 'Zoe');
      expect(tester.getTopLeft(find.byType(SelecteurProfils)), titulaire);
      await _monter(tester, autonome: false);
      expect(tester.getTopLeft(find.byType(SelecteurProfils)), titulaire);
      // Aucune ancienne carte « Votre espace eleve » au-dessus.
      expect(find.byType(AccueilFamillePage), findsOneWidget);
    });

    testWidgets('« Moi » : l espace d eleve, sans retour', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, usage: UsageTitulaire.moi);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byKey(retourAccueilFamilleKey), findsNothing);
    });

    for (final ({TextDirection sens, double echelle, double largeur}) cas
        in <({TextDirection sens, double echelle, double largeur})>[
          (sens: TextDirection.ltr, echelle: 2, largeur: 320),
          (sens: TextDirection.rtl, echelle: 1, largeur: 320),
          (sens: TextDirection.rtl, echelle: 2, largeur: 320),
        ]) {
      testWidgets('le lien tient dans l ecran : ${cas.sens.name}, texte a '
          '${(cas.echelle * 100).round()} %, ${cas.largeur.round()} px', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          taille: Size(cas.largeur, 780),
          echelle: cas.echelle,
          direction: cas.sens,
        );
        expect(tester.takeException(), isNull);
        final Rect r = tester.getRect(_lien);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(cas.largeur));
        expect(r.height, greaterThanOrEqualTo(48));
      });
    }
  });

  group('Captures R3 ACCUEIL-TUTEUR-UNE-PORTE', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final double largeur in <double>[320, 1440]) {
      for (final double echelle in <double>[1, 2]) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          for (final bool titulaire in <bool>[true, false]) {
            final String nom =
                '${largeur.round()}-x${echelle.round()}-${theme.name}-'
                '${titulaire ? 'titulaire' : 'enfant'}';
            testWidgets('capture $nom', (WidgetTester tester) async {
              await _monter(
                tester,
                taille: Size(largeur, largeur > 600 ? 900 : 1100),
                echelle: echelle,
                theme: theme,
              );
              if (!titulaire) await _choisir(tester, 'Zoe');
              expect(_lien, titulaire ? findsOneWidget : findsNothing);
              await capturerVue(tester, nom);
            });
          }
        }
      }
    }
  }, skip: sautSansCapture);
}
