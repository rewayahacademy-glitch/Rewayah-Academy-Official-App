// RECH-REC : captures de l'ecran de recherche reel contre les sept maquettes
// IMG-RECH-01 a 07 (spec RECH-03 §11), avec les domaines D2 (RA exact) et D4
// (encaissements, fils et canaux) sur les doubles de demonstration.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Sortie de preuve : docs/current/captures/RECH-REC/.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/moteur_recherche_demo.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/moteur_personnes.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/resolution_ra_demo.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteur_fils.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteur_finances.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;

import '../router/support_routeur.dart' show sessionActive, surchargesRouteur;
import '../support/harnais.dart';
import 'outil_capture.dart';

Future<GoRouter> _monter(
  WidgetTester tester, {
  required Size taille,
  AppRole role = AppRole.guardian,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
  List<MoteurRechercheDomaine>? moteurs,
  bool horsLigne = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(role, mode: mode)),
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        moteursRechercheProvider.overrideWithValue(
          moteurs ?? moteursDemoRecherche(),
        ),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(mode, Brightness.light),
                darkTheme: AppTheme.pour(mode, Brightness.dark),
                themeMode: theme,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
                builder: (BuildContext contexte, Widget? child) =>
                    Directionality(
                      textDirection: direction,
                      child: MediaQuery(
                        data: MediaQuery.of(contexte)
                            .copyWith(textScaler: TextScaler.linear(echelle)),
                        child: RepereDemonstration(child: child),
                      ),
                    ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.recherche);
  await stabiliser(tester);
  return routeur;
}

Future<void> _saisir(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await stabiliser(tester);
}

List<MoteurRechercheDomaine> _avecPersonnes() => <MoteurRechercheDomaine>[
  ...moteursDemoRecherche(),
  const MoteurPersonnesFoyer(
    foyer: AccesFoyerDemo(),
    classes: ClassesFoyerDemo(),
    resolutionRa: ResolutionRaDemo(<String, ElevePourRa>{
      'RA-CD0034': ElevePourRa(
        eleveId: DonneesDemo.yusufId,
        prenom: 'Yusuf',
        classe: 'Arabe, niveau 2',
      ),
    }),
  ),
];

void main() {
  group('Capture : RECH-REC', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    Future<void> cas(
      WidgetTester tester,
      String nom, {
      required Size taille,
      required AppRole role,
      required String requete,
      InterfaceMode mode = InterfaceMode.standard,
      ThemeMode theme = ThemeMode.light,
      List<MoteurRechercheDomaine>? moteurs,
      bool horsLigne = false,
    }) async {
      await _monter(
        tester,
        taille: taille,
        role: role,
        mode: mode,
        theme: theme,
        moteurs: moteurs,
        horsLigne: horsLigne,
      );
      if (requete.isNotEmpty) await _saisir(tester, requete);
      expect(tester.takeException(), isNull);
      debugPrint('PNG ${await capturer(tester, nom)}');
    }

    testWidgets(
      '01 famille 390',
      (WidgetTester t) => cas(
        t,
        'rec_01_famille_390',
        taille: const Size(390, 844),
        role: AppRole.guardian,
        requete: 'fatiha',
        moteurs: _avecPersonnes(),
      ),
    );
    testWidgets(
      '01b famille RA exact 390',
      (WidgetTester t) => cas(
        t,
        'rec_01b_famille_ra_390',
        taille: const Size(390, 844),
        role: AppRole.guardian,
        requete: 'RA-CD0034',
        moteurs: _avecPersonnes(),
      ),
    );
    testWidgets(
      '02 guidee 390',
      (WidgetTester t) => cas(
        t,
        'rec_02_guidee_390',
        taille: const Size(390, 844),
        role: AppRole.student,
        mode: InterfaceMode.enfant,
        requete: 'fatiha',
      ),
    );
    testWidgets(
      '03 enseignant sombre 1440',
      (WidgetTester t) => cas(
        t,
        'rec_03_enseignant_1440_sombre',
        taille: const Size(1440, 900),
        role: AppRole.teacher,
        theme: ThemeMode.dark,
        requete: 'mariam',
      ),
    );
    testWidgets(
      '04 admin clair 1440',
      (WidgetTester t) => cas(
        t,
        'rec_04_admin_1440',
        taille: const Size(1440, 900),
        role: AppRole.admin,
        requete: 'fatiha',
      ),
    );
    testWidgets('04b admin fils et canaux 1440', (WidgetTester t) async {
      final StudioDemo studio = StudioDemo(
        maintenant: DateTime(2026, 10, 11, 18),
      );
      final String nom = (await studio.canaux()).first.nom.split(' ').first;
      await cas(
        t,
        'rec_04b_admin_fils_1440',
        taille: const Size(1440, 900),
        role: AppRole.admin,
        requete: nom,
        moteurs: <MoteurRechercheDomaine>[
          MoteurFils(
            messages: const MessagesMetierIndisponibles2(),
            studio: studio,
          ),
        ],
      );
    });
    testWidgets(
      '05 comptable clair 1440',
      (WidgetTester t) => cas(
        t,
        'rec_05_comptable_1440',
        taille: const Size(1440, 900),
        role: AppRole.accountant,
        requete: 'famille',
        moteurs: <MoteurRechercheDomaine>[
          MoteurEncaissements(EncaissementsDemo()),
        ],
      ),
    );
    testWidgets(
      '06 etat vide',
      (WidgetTester t) => cas(
        t,
        'rec_06_etat_vide',
        taille: const Size(390, 844),
        role: AppRole.guardian,
        requete: 'zzzzzz',
      ),
    );
    testWidgets(
      '06 etat hors ligne',
      (WidgetTester t) => cas(
        t,
        'rec_06_etat_hors_ligne',
        taille: const Size(390, 844),
        role: AppRole.guardian,
        requete: 'fatiha',
        horsLigne: true,
      ),
    );
    testWidgets('06 etat domaine en panne', (WidgetTester t) async {
      final List<MoteurRechercheDomaine> m = moteursDemoRecherche();
      (m[1] as MoteurRechercheDemo).comportement =
          ComportementDemo.indisponible;
      await cas(
        t,
        'rec_06_etat_domaine_en_panne',
        taille: const Size(390, 844),
        role: AppRole.guardian,
        requete: 'fatiha',
        moteurs: m,
      );
    });
  });
}

/// Des Messages sans fil : le Studio seul est capture.
class MessagesMetierIndisponibles2 extends MessagesMetierIndisponibles {
  const MessagesMetierIndisponibles2();

  @override
  Future<List<ResumeFil>> fils() async => const <ResumeFil>[];
}
