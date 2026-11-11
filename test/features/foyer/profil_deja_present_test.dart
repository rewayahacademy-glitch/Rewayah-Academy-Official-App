// PROFIL-DEJA (directeur, 11/11/2026) : le tuteur touche « Moi-meme » ou
// « Creer mon profil eleve » alors que son profil eleve existe deja. Il
// cherche en realite son espace eleve.
//
// - Capacite « eleve autonome » servie (lue, jamais le role) : « Ouvrir mon
//   espace eleve » est la seule action pleine (K-56) et mene a l'espace
//   d'eleve ; « Retour au foyer » est un lien discret sous elle.
// - Capacite non servie (acces pas encore ouvert) : « Retour au foyer » reste
//   la seule action, et une phrase dit pourquoi.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/session/atterrissage_adulte.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/creer_mon_profil_page.dart';

import '../../capture/outil_capture.dart'
    show
        cadreCapture,
        capturerVue,
        chargerPolicesDuDepot,
        masquerRubanDebug,
        sautSansCapture;
import '../../fixtures/tuteur/faux_capacites.dart';
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import '../../router/support_routeur.dart';
import '../../support/demo/adulte_demo.dart';
import '../../support/harnais.dart';
import '../accueil_adulte/support_accueil_adulte_route.dart'
    show Valeur, accueilDemo, surchargesAccueilAdulte;

/// Le profil eleve du titulaire : l'identifiant de son propre compte.
const String _titulaireId = 'p-guardian';

const EleveDuFoyer _titulaire = EleveDuFoyer(
  id: _titulaireId,
  prenom: 'Aaron',
  identifiantImmuable: 'STUD-TIT-000001',
  mode: InterfaceMode.standard,
  camera: CameraPolicy.forbidden,
);

Future<GoRouter> _monter(
  WidgetTester tester, {
  required bool autonome,
  Size taille = const Size(390, 844),
  ThemeMode theme = ThemeMode.light,
  AppLocale langue = AppLocale.fr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = const <EleveDuFoyer>[_titulaire]
    ..appareilsRendus = <AppareilAppaire>[];
  final FauxProfilEleveTitulaire profil = FauxProfilEleveTitulaire()
    ..present = true;
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
        portProfilEleveTitulaireProvider.overrideWithValue(profil),
        usageTitulaireProvider.overrideWith(
          (Ref _, String _) async => UsageTitulaire.famille,
        ),
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
                locale: langue.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurAjouterPourMoi);
  await stabiliser(tester);
  return routeur;
}

/// Les boutons pleins (niveau principal) presents a l'ecran.
Finder get _pleins => find.byWidgetPredicate(
  (Widget w) => w is ActionPrincipale && w.niveau == NiveauAction.principale,
);

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('Profil eleve deja present', () {
    testWidgets('capacite servie : « Ouvrir mon espace eleve », seul bouton '
        'plein, mene a l espace d eleve', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, autonome: true);
      expect(find.byKey(CreerMonProfilPage.dejaKey), findsOneWidget);
      expect(find.byKey(CreerMonProfilPage.creerKey), findsNothing);
      expect(find.text(t.tuteur.accueil.ouvrirEspaceEleve), findsOneWidget);
      expect(find.text(t.foyer.monProfil.dejaOuvertPhrase), findsOneWidget);
      expect(_pleins, findsOneWidget);
      expect(
        find.descendant(
          of: _pleins,
          matching: find.text(t.tuteur.accueil.ouvrirEspaceEleve),
        ),
        findsOneWidget,
      );
      // « Retour au foyer » est un lien discret, sous le bouton.
      final Finder lien = find.byKey(CreerMonProfilPage.retourLienKey);
      expect(lien, findsOneWidget);
      expect(tester.widget(lien), isA<LienFleche>());
      expect(
        tester.getTopLeft(lien).dy,
        greaterThan(
          tester
              .getBottomLeft(find.byKey(CreerMonProfilPage.ouvrirEspaceKey))
              .dy,
        ),
      );

      await tester.tap(find.byKey(CreerMonProfilPage.ouvrirEspaceKey));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
    });

    testWidgets('capacite servie : le lien « Retour au foyer » ramene au '
        'Foyer', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, autonome: true);
      final Finder lien = find.byKey(CreerMonProfilPage.retourLienKey);
      await tester.ensureVisible(lien);
      await tester.tap(lien);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurFoyer);
    });

    testWidgets('capacite non servie : « Retour au foyer » seul, et la '
        'phrase dit pourquoi', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, autonome: false);
      expect(find.byKey(CreerMonProfilPage.dejaKey), findsOneWidget);
      expect(find.byKey(CreerMonProfilPage.ouvrirEspaceKey), findsNothing);
      expect(find.byKey(CreerMonProfilPage.retourLienKey), findsNothing);
      expect(find.text(t.tuteur.accueil.ouvrirEspaceEleve), findsNothing);
      expect(find.text(t.foyer.monProfil.dejaAttentePhrase), findsOneWidget);
      expect(_pleins, findsOneWidget);
      expect(
        find.descendant(
          of: _pleins,
          matching: find.text(t.foyer.monProfil.retour),
        ),
        findsOneWidget,
      );

      await tester.tap(_pleins);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurFoyer);
    });

    testWidgets('arabe, 320 px : rien ne deborde', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        autonome: true,
        taille: const Size(320, 780),
        langue: AppLocale.ar,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(CreerMonProfilPage.ouvrirEspaceKey), findsOneWidget);
    });
  });

  group('Captures R3 PROFIL-DEJA', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final double largeur in <double>[320, 1440]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          for (final bool autonome in <bool>[true, false]) {
            final String nom =
                'profil-deja/${largeur.round()}-${theme.name}-'
                '${langue.languageCode}-'
                '${autonome ? 'espace-ouvert' : 'acces-en-attente'}';
            testWidgets('capture $nom', (WidgetTester tester) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              await _monter(
                tester,
                autonome: autonome,
                taille: Size(largeur, largeur > 600 ? 900 : 780),
                theme: theme,
                langue: langue,
              );
              expect(tester.takeException(), isNull);
              await capturerVue(tester, nom);
            });
          }
        }
      }
    }
  }, skip: sautSansCapture);
}
