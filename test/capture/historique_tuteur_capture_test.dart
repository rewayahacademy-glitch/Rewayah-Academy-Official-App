// Captures de recette de l'Historique du tuteur (lot E, sous-paquet 2), sur
// le VRAI routeur : Seances, Observations, detail de seance, detail des
// observations, a 390x844 et 1440x900, clair et sombre ; deux etats ; et les
// planches maquette | rendu (V8 D2, V8 D4, ancienne capture Historique).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Les
// planches demandent en plus les maquettes recadrees :
//   CAPTURE_MAQUETTE_HISTORIQUE_D2, CAPTURE_MAQUETTE_HISTORIQUE_D4,
//   CAPTURE_MAQUETTE_HISTORIQUE_ANCIENNE.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures isolees.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/historique/support_historique.dart';
import '../fixtures/tuteur/faux_observation.dart';
import '../fixtures/tuteur/foyers.dart';
import 'outil_capture.dart';

String? _env(String nom) {
  final String? v = Platform.environment[nom];
  return v == null || v.trim().isEmpty ? null : v;
}

/// Trois seances observees par le titulaire pour A1 (comme la maquette D2) :
/// deux visites fermees, une visite fermee, une visite sans sortie.
List<Map<String, dynamic>> _visites() {
  String iso(DateTime d) => d.toUtc().toIso8601String();
  Map<String, dynamic> visite(
    String id,
    Seance s,
    int rang,
    int apresMin,
    int? secondes,
  ) => ligneVisite(
    id: id,
    seanceId: s.id,
    groupeId: classeA.groupeId,
    rang: rang,
    entree: iso(s.debut.add(Duration(minutes: apresMin))),
    sortie: secondes == null
        ? null
        : iso(s.debut.add(Duration(minutes: apresMin, seconds: secondes))),
    duree: secondes,
  );
  return <Map<String, dynamic>>[
    visite('v1', seancesFoyerA[0], 1, 12, 120),
    visite('v2', seancesFoyerA[0], 2, 35, 102),
    visite('v3', seancesFoyerA[1], 1, 10, 120),
    visite('v4', seancesFoyerA[2], 1, 20, null),
  ];
}

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  bool observations = true,
  List<Seance>? seances,
}) => monterHistorique(
  tester,
  depart: depart,
  taille: null,
  mode: mode,
  cadre: cadreCapture,
  seances: seances,
  observations: observations
      ? FauxHistoriqueObservations(lignes: _visites())
      : null,
);

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

void main() {
  group('Capture : Historique du tuteur', skip: sautSansCapture, () {
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

    final List<(String, String)> ecrans = <(String, String)>[
      ('historique_seances', Routes.tuteurSuivi),
      ('historique_observations', Routes.tuteurSuiviObservations),
      (
        'detail_seance',
        '${Routes.seancePour('s-retard')}?eleve=${FoyersFictifs.a1.id}',
      ),
      (
        'detail_observations',
        Routes.observationsSeancePour(
          's-presente',
          eleveId: FoyersFictifs.a1.id,
        ),
      ),
    ];

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, String chemin) in ecrans) {
        testWidgets('390x844 @3, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(tester, chemin, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'e_${nom}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, chemin, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'e_${nom}_1440x900@1_${mode.name}')}',
          );
        });
      }

      // Les seances defilent sur telephone : une vue plus haute montre la
      // liste entiere (preuve de composition, pas une taille reelle).
      testWidgets('390x1400 @2, seances pleine hauteur, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(
          tester,
          const Size(390, 1400),
          2,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await _monter(tester, Routes.tuteurSuivi, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'e_historique_seances_390x1400@2_pleine_hauteur_${mode.name}')}',
        );
      });
    }

    // Deux etats : le port de production (indisponible) et l'historique vide.
    testWidgets('390x844 @3, observations indisponibles (production)', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(
        tester,
        const Size(390, 844),
        3,
        zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
      );
      await _monter(
        tester,
        Routes.tuteurSuiviObservations,
        observations: false,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'e_historique_observations_indisponible_390x844@3_light')}',
      );
    });

    testWidgets('390x844 @3, aucune seance passee', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(
        tester,
        const Size(390, 844),
        3,
        zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
      );
      await _monter(tester, Routes.tuteurSuivi, seances: <Seance>[]);
      debugPrint(
        'PNG ${await capturer(tester, 'e_historique_vide_390x844@3_light')}',
      );
    });

    // Les planches maquette | rendu, a la taille en pixels de la maquette.
    final List<(String, String?, ThemeMode, String)> planches =
        <(String, String?, ThemeMode, String)>[
          (
            'e_planche_historique_observations_mobile_sombre',
            _env('CAPTURE_MAQUETTE_HISTORIQUE_D2'),
            ThemeMode.dark,
            Routes.tuteurSuiviObservations,
          ),
          (
            'e_planche_detail_observations_mobile_clair',
            _env('CAPTURE_MAQUETTE_HISTORIQUE_D4'),
            ThemeMode.light,
            Routes.observationsSeancePour(
              's-presente',
              eleveId: FoyersFictifs.a1.id,
            ),
          ),
          (
            'e_planche_historique_seances_ancienne_sombre',
            _env('CAPTURE_MAQUETTE_HISTORIQUE_ANCIENNE'),
            ThemeMode.dark,
            Routes.tuteurSuivi,
          ),
        ];
    for (final (String nom, String? maquette, ThemeMode mode, String chemin)
        in planches) {
      testWidgets('planche : $nom', skip: maquette == null, (
        WidgetTester tester,
      ) async {
        final (int l, int h) = await _taillePx(tester, maquette!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await _monter(tester, chemin, mode: mode);
        debugPrint('PNG ${await capturerEtComparer(tester, nom, maquette)}');
      });
    }
  });
}
