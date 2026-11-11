// TITULAIRE-SANS-APPAREIL (directeur, 11/11/2026, relaye par le pilote) : sur
// l'Accueil famille, « Aucun appareil prêt » ne s'affiche JAMAIS pour le profil
// du titulaire (celui dont l'identifiant est celui de son compte) : ni bandeau
// d'alerte, ni lumiere rouge « acces bloque ». Un lien discret et facultatif,
// « Utiliser un autre appareil », mene a l'appairage existant. Le profil d'un
// enfant garde son alerte. Garde : ces tests echouent si l'alerte revient pour
// le titulaire.

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
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart' show NatureHalo;
import 'package:rewayah_academy/core/widgets/lumiere_autour.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/accueil_famille/bandeau_blocage.dart';

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
          FauxClassesFoyer(
            classes: <ClasseFoyer>[
              ClasseFoyer(eleveId: _titulaireId, classe: classeFictive()),
              ClasseFoyer(eleveId: _enfantId, classe: classeFictive()),
            ],
          ),
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

Finder get _lien => find.byKey(AccueilFamillePage.autreAppareilKey);

/// Aucune lumiere rouge (urgente) autour d'une tuile de l'Accueil.
void _aucuneLumiereRouge(WidgetTester tester) {
  for (final LumiereAutour l in tester.widgetList<LumiereAutour>(
    find.byType(LumiereAutour),
  )) {
    expect(l.nature, isNot(NatureHalo.urgent));
  }
}

void main() {
  group('Le titulaire sans appareil jumele : jamais d alerte', () {
    testWidgets('titulaire choisi : ni bandeau, ni alerte, ni lumiere rouge ; '
        'un lien discret mene a l appairage', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      expect(find.byType(AccueilFamillePage), findsOneWidget);
      expect(find.byType(BandeauBlocage), findsNothing);
      expect(find.byKey(BandeauBlocage.cleAlerte), findsNothing);
      expect(
        find.text(t.tuteur.accueil.blocageAppareilTitre(prenom: 'Aaron')),
        findsNothing,
      );
      _aucuneLumiereRouge(tester);
      expect(_lien, findsOneWidget);
      expect(find.text(t.tuteur.accueil.autreAppareil), findsOneWidget);
      await tester.tap(_lien);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.appairerPour(_titulaireId));
    });

    testWidgets('meme sans la capacite « eleve autonome » : l identifiant du '
        'profil decide, jamais le role', (WidgetTester tester) async {
      await _monter(tester, autonome: false);
      expect(find.byType(BandeauBlocage), findsNothing);
      expect(find.byKey(BandeauBlocage.cleAlerte), findsNothing);
      _aucuneLumiereRouge(tester);
      expect(_lien, findsOneWidget);
    });

    testWidgets('le profil d un enfant garde son alerte, sans le lien', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _choisir(tester, 'Zoe');
      expect(find.byType(BandeauBlocage), findsOneWidget);
      expect(
        find.text(t.tuteur.accueil.blocageAppareilTitre(prenom: 'Zoe')),
        findsOneWidget,
      );
      expect(_lien, findsNothing);
      // Et revenu au titulaire : l'alerte repart, le lien revient.
      await _choisir(tester, 'Aaron');
      expect(find.byType(BandeauBlocage), findsNothing);
      expect(_lien, findsOneWidget);
    });
  });

  // Captures R3 (avant / apres), 390 et 1440, titulaire puis enfant.
  group('captures R3 : titulaire sans appareil', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String taille, Size dim) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final (String th, ThemeMode theme) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        testWidgets('titulaire puis enfant, $taille $th', (
          WidgetTester tester,
        ) async {
          await _monter(tester, taille: dim, theme: theme);
          await capturerVue(tester, 'titulaire-$taille-$th-1-titulaire');
          await _choisir(tester, 'Zoe');
          await capturerVue(tester, 'titulaire-$taille-$th-2-enfant');
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
