// MUSHAF-MODES : captures des modes « Lecture agrandie » et « Focus » avec la
// mise en page de Medine : 1440 et 390, clair et sombre, a 100 % et au zoom
// maximal, plus la variante sans la police (texte Tanzil simple, police arabe de
// l'application). Page 293. Saute sans CAPTURE_DIR. Sortie de preuve :
// docs/current/captures/MUSHAF-15L/modes/ (les `avant_*` sont ceux de
// claude/mushaf-15l-captures).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';

import '../support/mushaf_15l.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : MUSHAF-MODES', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    setUp(masquerRubanDebug);

    for (final (String nomMode, ModeRenduCoran mode)
        in <(String, ModeRenduCoran)>[
          ('agrandie', ModeRenduCoran.versetAgrandi),
          ('focus', ModeRenduCoran.focus),
        ]) {
      for (final (String nomTaille, Size taille) in <(String, Size)>[
        ('1440', const Size(1440, 900)),
        ('390', const Size(390, 844)),
      ]) {
        for (final (String nomZoom, double zoom) in <(String, double)>[
          ('100', 1),
          ('max', 4),
        ]) {
          for (final (String nomTheme, ThemeMode theme)
              in <(String, ThemeMode)>[
                ('clair', ThemeMode.light),
                ('sombre', ThemeMode.dark),
              ]) {
            for (final bool police in <bool>[true, false]) {
              // La variante sans police : clair, zoom maximal seulement.
              if (!police && (nomTheme != 'clair' || nomZoom != 'max')) {
                continue;
              }
              final String nom =
                  'apres_${nomMode}_${nomTaille}_${nomZoom}_$nomTheme'
                  '${police ? '' : '_sans_police'}';
              testWidgets(nom, (WidgetTester tester) async {
                await monterPageMadina15(
                  tester,
                  page: 293,
                  taille: taille,
                  mode: mode,
                  zoom: zoom,
                  theme: theme,
                  tanzilSimple: true,
                  policeMushaf: police,
                  ecranComplet: true,
                );
                expect(tester.takeException(), isNull);
                debugPrint('PNG ${await capturer(tester, nom)}');
              });
            }
          }
        }
      }
    }
  });
}
