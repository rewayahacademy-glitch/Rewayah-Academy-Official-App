// MA-1b : squelette des captures de la vague Mode Accessibilite, complete de
// MA-2 a MA-12 (recette) pour chaque ecran et ses cas (avant, pendant,
// apres ; mineur et adulte ; texte a 200 % ; animations reduites). Jamais
// sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Modele :
// `captures_en_test.dart`. Sortie en un sous-dossier par ecran.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/fiche_seance.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';
import '../../teaching_core/e/faux/faux_classe.dart';
import '../../teaching_core/e/support/hote_classe.dart';

const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 1900)),
  ('768', Size(768, 1500)),
  ('1440', Size(1440, 1100)),
];

/// MA-7 (revue) : le lecteur se juge a la hauteur reelle d'un ecran, pas
/// sur une planche allongee : les commandes doivent y etre visibles.
const List<(String, Size)> _ecransReels = <(String, Size)>[
  ('390', Size(390, 844)),
  ('768', Size(768, 1024)),
  ('1440', Size(1440, 900)),
];

const List<ThemeMode> _themes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// Monte [ecran] en Mode Accessibilite et ecrit son PNG ; [echelle] simule le
/// texte agrandi, [reduit] les animations reduites.
Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool reduit = false,
  bool rtl = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  if (rtl) {
    ecran = Directionality(textDirection: TextDirection.rtl, child: ecran);
  }
  await tester.pumpWidget(
    hoteCapture(
      reduit
          ? Builder(
              builder: (BuildContext context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: ecran,
              ),
            )
          : ecran,
      themeMode: mode,
      echelleTexte: echelle,
      interfaceMode: InterfaceMode.enfant,
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  // MA-12 : l'ecriture de droite a gauche (structure, texte reste francais).
  group('Capture MA-12 : RTL', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const Map<String, EcranAccessibiliteDemo> ecrans =
        <String, EcranAccessibiliteDemo>{
          'accueil_mariam': EcranAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.mariam,
          ),
          'ma_classe_idriss': EcranAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.idriss,
            destinationInitiale: EcranAccessibiliteDemo.indexMaClasse,
          ),
          'salle_mariam': EcranAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.mariam,
            moment: MomentDemoAccessibilite.fenetre,
            etapeInitiale: EtapeDemoAccessibilite.salle,
          ),
        };
    for (final MapEntry<String, EcranAccessibiliteDemo> e in ecrans.entries) {
      testWidgets('rtl_${e.key}', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ma12/ma12_rtl_${e.key}_390_light',
          e.value,
          const Size(390, 844),
          rtl: true,
        );
      });
    }
  });

  // -------------------------------------------------------------------
  // Socle (MA-1b) : la liste de la demonstration et l'ecran de Mariam.
  // -------------------------------------------------------------------
  group('Capture MA-1b : socle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('liste_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma1b/ma1b_liste_${l}_${mode.name}',
            const DemoAccessibilitePage(),
            taille,
            mode: mode,
          );
        });
        testWidgets('mariam_avant_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'ma1b/ma1b_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('mariam_avant_390_light_texte200_reduit', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ma1b/ma1b_mariam_avant_390_light_texte200_reduit',
        const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
        const Size(390, 2600),
        echelle: 2,
        reduit: true,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-2 : la navigation a 4 destinations (barre, rail, barre laterale).
  // -------------------------------------------------------------------
  group('Capture MA-2 : navigation', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in const <(String, Size)>[
      ('390', Size(390, 844)),
      ('768', Size(768, 1024)),
      ('1440', Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in _themes) {
        testWidgets('nav_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma2/ma2_nav_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('nav_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma2/ma2_nav_mariam_avant_390_light_texte200',
        const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
        const Size(390, 844),
        echelle: 2,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-3 : l'Accueil de l'eleve (Mariam avant, Idriss apres, 200 %).
  // -------------------------------------------------------------------
  group('Capture MA-3 : Accueil', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('accueil_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma3/ma3_accueil_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('accueil_idriss_apres_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma3/ma3_accueil_idriss_apres_390_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          moment: MomentDemoAccessibilite.apres,
          destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
        ),
        const Size(390, 1900),
      );
    });
    testWidgets('accueil_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma3/ma3_accueil_mariam_avant_390_light_texte200',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
        ),
        const Size(390, 3400),
        echelle: 2,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-4 : Ma classe avant la seance (Mariam ; texte a 200 %).
  // -------------------------------------------------------------------
  group('Capture MA-4 : Ma classe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('ma_classe_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma4/ma4_ma_classe_mariam_avant_${l}_${mode.name}',
            const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('ma_classe_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma4/ma4_ma_classe_mariam_avant_390_light_texte200',
        const EcranAccessibiliteDemo(eleve: EleveDemoAccessibilite.mariam),
        const Size(390, 4200),
        echelle: 2,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-5 : la preparation guidee et la salle (Mariam observee ; Idriss
  // adulte ; texte a 200 %).
  // -------------------------------------------------------------------
  group('Capture MA-5 : preparation et salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    const List<(String, Size)> tailles = <(String, Size)>[
      ('390', Size(390, 844)),
      ('768', Size(768, 1024)),
      ('1440', Size(1440, 900)),
    ];
    for (final (String l, Size taille) in tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('preparation_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'ma5/ma5_preparation_mariam_${l}_${mode.name}',
            const EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              moment: MomentDemoAccessibilite.fenetre,
              etapeInitiale: EtapeDemoAccessibilite.preparation,
            ),
            taille,
            mode: mode,
          );
        });
        testWidgets('salle_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma5/ma5_salle_mariam_${l}_${mode.name}',
            const EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              moment: MomentDemoAccessibilite.fenetre,
              etapeInitiale: EtapeDemoAccessibilite.salle,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('fenetre_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma5/ma5_fenetre_mariam_390_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          moment: MomentDemoAccessibilite.fenetre,
        ),
        const Size(390, 1900),
      );
    });
    testWidgets('salle_idriss_390_dark', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma5/ma5_salle_idriss_390_dark',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          moment: MomentDemoAccessibilite.fenetre,
          etapeInitiale: EtapeDemoAccessibilite.salle,
        ),
        const Size(390, 844),
        mode: ThemeMode.dark,
      );
    });
    testWidgets('salle_idriss_1440_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma5/ma5_salle_idriss_1440_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          moment: MomentDemoAccessibilite.fenetre,
          etapeInitiale: EtapeDemoAccessibilite.salle,
        ),
        const Size(1440, 900),
      );
    });
    for (final String etape in <String>['preparation', 'salle']) {
      testWidgets('${etape}_390_light_texte200', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ma5/ma5_${etape}_mariam_390_light_texte200',
          EcranAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.mariam,
            moment: MomentDemoAccessibilite.fenetre,
            etapeInitiale: etape == 'salle'
                ? EtapeDemoAccessibilite.salle
                : EtapeDemoAccessibilite.preparation,
          ),
          const Size(390, 844),
          echelle: 2,
        );
      });
    }
  });

  // -------------------------------------------------------------------
  // MA-6 : apres la seance (Mariam tutoyee ; Idriss vouvoye ; 200 %).
  // -------------------------------------------------------------------
  group('Capture MA-6 : apres la seance', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('apres_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma6/ma6_apres_mariam_${l}_${mode.name}',
            const EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.mariam,
              moment: MomentDemoAccessibilite.apres,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('apres_idriss_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma6/ma6_apres_idriss_390_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          moment: MomentDemoAccessibilite.apres,
        ),
        const Size(390, 1900),
      );
    });
    testWidgets('apres_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma6/ma6_apres_mariam_390_light_texte200',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          moment: MomentDemoAccessibilite.apres,
        ),
        const Size(390, 1900),
        echelle: 2,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-7 : le Coran autour du rendu (entree avec reprise ; lecteur ouvert
  // en verset agrandi par « Lecture en grand texte » ; 200 %). Corpus de
  // reference des tests, rendu du Coran intouche.
  // -------------------------------------------------------------------
  group('Capture MA-7 : Coran', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });
    List<Override> corpus() => <Override>[
      portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
      portLayoutMushafProvider.overrideWithValue(
        const LayoutLignesIndisponible(),
      ),
      portNavigationCoranProvider.overrideWithValue(
        FauxNavigationCoran(
          personnelle: PositionLecture(
            page: reference.pages.last.numero,
            sourate: 1,
            verset: 1,
          ),
        ),
      ),
    ];
    Widget ecran(EleveDemoAccessibilite eleve) => EcranAccessibiliteDemo(
      eleve: eleve,
      destinationInitiale: EcranAccessibiliteDemo.indexCoran,
      surchargesCoran: corpus(),
    );
    Future<void> ouvrir(WidgetTester tester, String fichier) async {
      ProviderScope.containerOf(
        tester.element(find.byType(EcranAccessibiliteDemo)),
      ).read(preferencesLocalesProvider.notifier).lectureGrande(true);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('coran-ma-principale')),
      );
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      debugPrint('PNG ${await capturer(tester, fichier)}');
    }

    for (final (String l, Size taille) in _ecransReels) {
      for (final ThemeMode mode in _themes) {
        testWidgets('coran_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'ma7/ma7_coran_mariam_${l}_${mode.name}',
            ecran(EleveDemoAccessibilite.mariam),
            taille,
            mode: mode,
          );
          await ouvrir(
            tester,
            'ma7/ma7_coran_lecteur_mariam_${l}_${mode.name}',
          );
        });
      }
    }
    testWidgets('coran_idriss_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma7/ma7_coran_idriss_390_light',
        ecran(EleveDemoAccessibilite.idriss),
        const Size(390, 1900),
      );
    });
    // Revue MA-7 (3) : la demonstration sans texte du Coran dit la vraie
    // cause, sans « Reessayer » (Idriss, adulte : vouvoiement).
    testWidgets('coran_demo_sans_texte_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma7/ma7_coran_demo_sans_texte_idriss_390_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.idriss,
          destinationInitiale: EcranAccessibiliteDemo.indexCoran,
        ),
        const Size(390, 844),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('coran-ma-principale')),
      );
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'ma7/ma7_coran_demo_sans_texte_lecteur_idriss_390_light')}',
      );
    });
    testWidgets('coran_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma7/ma7_coran_mariam_390_light_texte200',
        ecran(EleveDemoAccessibilite.mariam),
        const Size(390, 844),
        echelle: 2,
      );
      await ouvrir(tester, 'ma7/ma7_coran_lecteur_mariam_390_light_texte200');
    });
  });

  // -------------------------------------------------------------------
  // MA-8 : Mon espace (Mariam : demande au tuteur ; Idriss : bascule ;
  // texte a 200 %).
  // -------------------------------------------------------------------
  group('Capture MA-8 : Mon espace', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
      for (final ThemeMode mode in _themes) {
        testWidgets('mon_espace_${eleve.name}_390_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'ma8/ma8_mon_espace_${eleve.name}_390_${mode.name}',
            EcranAccessibiliteDemo(
              eleve: eleve,
              destinationInitiale: EcranAccessibiliteDemo.indexMonEspace,
            ),
            const Size(390, 3000),
            mode: mode,
          );
        });
      }
    }
    testWidgets('mon_espace_mariam_1440_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma8/ma8_mon_espace_mariam_1440_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexMonEspace,
        ),
        const Size(1440, 2200),
      );
    });
    testWidgets('mon_espace_mariam_768_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma8/ma8_mon_espace_mariam_768_light',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexMonEspace,
        ),
        const Size(768, 2400),
      );
    });
    testWidgets('mon_espace_mariam_1440_dark', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma8/ma8_mon_espace_mariam_1440_dark',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexMonEspace,
        ),
        const Size(1440, 2200),
        mode: ThemeMode.dark,
      );
    });
    testWidgets('mon_espace_390_light_texte200', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ma8/ma8_mon_espace_mariam_390_light_texte200',
        const EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexMonEspace,
        ),
        const Size(390, 6000),
        echelle: 2,
      );
    });
  });

  // -------------------------------------------------------------------
  // MA-9 : la page « Interface » du tuteur (vrai routeur, coquille
  // tuteur) et la fiche de seance de l'enseignant (libelle neutre, Q6).
  // -------------------------------------------------------------------
  group('Capture MA-9 : tuteur et enseignant', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1100)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in _themes) {
        testWidgets('interface_${l}_${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(_appTuteur(mode));
          await stabiliser(tester);
          _routeurMa9.go(
            Routes.ficheEleveSousPage(FoyersFictifs.a1.id, 'interface'),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ma9/ma9_interface_tuteur_${l}_${mode.name}')}',
          );
        });
        testWidgets('fiche_seance_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 420,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: FicheSeance(
                        eleve: TeacherStudentProjection(
                          firstName: 'Ilyas',
                          academyId: 'RA-CD0044',
                          liveStatus: EtatPresenceProjete.present,
                          interfaceGuidee: true,
                          level: 'Debutant',
                        ),
                        sessionId: 's1',
                      ),
                    ),
                  ),
                ),
              ),
              themeMode: mode,
              surcharges: surchargesClasse(
                moteur: FauxMoteurClasse(),
                video: FauxServiceVideoClasse(),
                preVol: FauxPreVolClasse(),
                rappel: FauxRappelDiscret(),
              ),
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ma9/ma9_fiche_seance_${l}_${mode.name}')}',
          );
        });
      }
    }
  });
}

late GoRouter _routeurMa9;

/// L'application du tuteur sur le vrai routeur (coquille comprise).
Widget _appTuteur(ThemeMode mode) => ProviderScope(
  overrides: <Override>[
    ...surchargesRouteur(
      FausseSourceSession(sessionActive(AppRole.guardian)),
      appairage: FauxServiceAppairage()..elevesRendus = FoyersFictifs.foyerA,
    ),
    horlogeFoyerProvider.overrideWithValue(() => DateTime(2026, 9, 24, 12)),
  ],
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          _routeurMa9 = ref.read(routeurProvider);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _routeurMa9,
          );
        },
      ),
    ),
  ),
);
