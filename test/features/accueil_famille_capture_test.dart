// Captures de recette de l'Accueil du tuteur (lot C, sous-paquet 1), sur le
// VRAI routeur : 390x844 et 1440x900, clair et sombre, tablette 1024x768,
// etats derives, et planches maquette | rendu.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais). Planches :
// CAPTURE_MAQUETTE_ACCUEIL_MOBILE (V1, 390 logiques) et
// CAPTURE_MAQUETTE_ACCUEIL_BUREAU (V2 A, 1440 logiques). Donnees : fixtures
// isolees uniquement (`test/fixtures/tuteur/`), jamais un service reel.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../capture/outil_capture.dart';
import '../fixtures/tuteur/faux_classes_foyer.dart';
import '../fixtures/tuteur/faux_seances_famille.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';

final String? _maquetteMobile =
    Platform.environment['CAPTURE_MAQUETTE_ACCUEIL_MOBILE'];
final String? _maquetteBureau =
    Platform.environment['CAPTURE_MAQUETTE_ACCUEIL_BUREAU'];

const String _a1 = 'foyer-a-eleve-1';

/// La classe fictive A avec son parcours lisible (« cours · niveau » sous
/// l'enseignant, maquettes V1 et V2), en donnees fictives.
const ClasseFoyer _classeAvecParcours = ClasseFoyer(
  eleveId: _a1,
  classe: GroupSummaryVM(
    groupeId: 'classe-a',
    libelle: 'Classe fictive A',
    couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'g0'),
    enseignant: EnseignantVM(
      enseignantId: 'enseignant-x',
      titre: TitreEnseignant.sayyid,
      nomAffichage: 'Enseignant X',
    ),
    nombreMembres: 3,
    seuilMax: 6,
    typePublic: TypePublicGroupeVM.enfant,
    actif: true,
    nomCours: 'Cours fictif',
    niveauHumain: 'Niveau fictif',
  ),
);

class _FauxTravail implements PortTravailAVenir {
  const _FauxTravail();

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => const <SlotAction>[
    SlotAction(id: 'a', libelle: 'Action fictive 1'),
    SlotAction(id: 'b', libelle: 'Action fictive 2'),
    SlotAction(id: 'c', libelle: 'Action fictive 3'),
  ];
}

/// Le scenario de la maquette, en donnees fictives : salle ouverte, compte a
/// rebours, aucun appareil pret, trois actions, une derniere seance tenue.
List<SeanceFamille> _seancesNominales() => <SeanceFamille>[
  seanceFictive(
    seanceId: 's1',
    eleveId: _a1,
    debutUtc: instantServeurFige.add(const Duration(minutes: 13, seconds: 30)),
    duree: const Duration(minutes: 90),
    heureFoyer: heureRendue('Europe/Paris', 'Paris', '18:13'),
  ),
  seanceFictive(
    seanceId: 's0',
    eleveId: _a1,
    debutUtc: instantServeurFige.subtract(const Duration(days: 2)),
    duree: const Duration(minutes: 90),
    statut: StatutSeance.terminee,
    heureFoyer: heureRendue(
      'Europe/Paris',
      'Paris',
      '18:00',
      date: 'Samedi 19 septembre',
    ),
  ),
];

Future<void> _monter(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  List<EleveDuFoyer> foyer = FoyersFictifs.foyerA,
  List<SeanceFamille>? seances,
  List<ClasseFoyer>? classes,
  PortTravailAVenir? travail = const _FauxTravail(),
  bool horlogeAbsente = false,
}) async {
  late GoRouter routeur;
  final FauxSeancesFamille faux = FauxSeancesFamille(
    seances: seances ?? _seancesNominales(),
  );
  if (horlogeAbsente) {
    faux.maintenant = null;
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage()..elevesRendus = foyer,
        ),
        portSeancesFamilleProvider.overrideWithValue(faux),
        portClassesFoyerProvider.overrideWithValue(
          FauxClassesFoyer(
            classes: classes ?? const <ClasseFoyer>[_classeAvecParcours],
          ),
        ),
        portTravailAVenirProvider.overrideWithValue(travail),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
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
  routeur.go(Routes.tuteurAccueil);
  await stabiliser(tester);
}

Future<(int, int)> _taillePx(WidgetTester tester, String chemin) async {
  late int l;
  late int h;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      await File(chemin).readAsBytes(),
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    l = image.width;
    h = image.height;
    image.dispose();
  });
  return (l, h);
}

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

void main() {
  group('Capture : Accueil du tuteur', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('390x844 @3, nominal, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'accueil_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('390x1600 @2, page entiere, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 1600), 2, zoneSure: _zoneSure);
        await _monter(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'accueil_390x1600@2_page_entiere_${mode.name}')}',
        );
      });

      testWidgets('1440x900 @1, nominal, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'accueil_1440x900@1_${mode.name}')}',
        );
      });

      testWidgets('1024x768 @1, tablette, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1024, 768), 1);
        await _monter(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'accueil_1024x768@1_${mode.name}')}',
        );
      });
    }

    testWidgets('390x844 @3, foyer vide', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(tester, foyer: FoyersFictifs.foyerVide);
      debugPrint('PNG ${await capturer(tester, 'accueil_390x844@3_vide')}');
    });

    testWidgets('390x844 @3, eleve sans classe', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        seances: const <SeanceFamille>[],
        classes: const <ClasseFoyer>[],
      );
      debugPrint(
        'PNG ${await capturer(tester, 'accueil_390x844@3_sans_classe')}',
      );
    });

    testWidgets('390x1600 @2, production : horloge et classes absentes, '
        'travail non branche', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 1600), 2, zoneSure: _zoneSure);
      await _monter(
        tester,
        horlogeAbsente: true,
        classes: const <ClasseFoyer>[],
        travail: null,
        seances: <SeanceFamille>[
          seanceFictive(
            seanceId: 's1',
            eleveId: _a1,
            debutUtc: instantServeurFige.add(const Duration(hours: 3)),
            avecHorloge: false,
          ),
        ],
      );
      debugPrint(
        'PNG ${await capturer(tester, 'accueil_390x1600@2_horaire_incertain')}',
      );
    });

    testWidgets(
      'planche : Accueil mobile clair contre la maquette V1',
      skip: _maquetteMobile == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteMobile!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: _zoneSure,
        );
        await _monter(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'accueil_mobile_contre_maquette', _maquetteMobile!)}',
        );
      },
    );

    testWidgets(
      'planche : Accueil bureau clair contre la maquette V2 A',
      skip: _maquetteBureau == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteBureau!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 1440,
        );
        await _monter(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'accueil_bureau_contre_maquette', _maquetteBureau!)}',
        );
      },
    );
  });
}
