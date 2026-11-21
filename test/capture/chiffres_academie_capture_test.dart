// CHIFFRES-ACADEMIE : captures de « Les chiffres de l'academie » (fr et ar,
// clair et sombre, telephone et ordinateur). Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_chiffres_academie.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_chiffres/chiffres_academie_page.dart';

import 'outil_capture.dart';

class _Port implements PortChiffresAcademie {
  @override
  Future<ChiffresAcademie> lire() async => ChiffresAcademie(
    genereLe: DateTime(2026, 11, 21, 9, 42),
    candidatsRecus: 608,
    candidatsAujourdhui: 8,
    candidatsSeptJours: 125,
    candidatsSeptJoursAvant: 483,
    candidatsParJour: const <int>[239, 191, 57, 19, 21, 8, 8],
    pays: 35,
    hommes: 493,
    femmes: 115,
    repondants: 512,
    coranEntier: 376,
    juzMin: 11959,
    ijaza: 253,
    riwayat: 20,
    langues: 18,
    enseignants: 4,
    eleves: 28,
    elevesEnClasse: 5,
    familles: 24,
    classes: 4,
    languesCours: 6,
    seancesTenues: 21,
    seancesMinutes: 1590,
    seancesSeptJours: 3,
    seancesSeptJoursAvant: 2,
  );
}

void main() {
  group('Capture : les chiffres de l\'academie', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final (String nom, Size taille, double ratio)
            in <(String, Size, double)>[
              ('telephone', const Size(390, 2400), 2),
              ('ordinateur', const Size(1440, 1500), 1),
            ]) {
          testWidgets('${langue.name} ${mode.name} $nom', (
            WidgetTester tester,
          ) async {
            LocaleSettings.setLocaleSync(langue);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            fixerVueCapture(tester, taille, ratio);
            await tester.pumpWidget(
              hoteCapture(
                const ChiffresAcademiePage(),
                surcharges: [
                  portChiffresAcademieProvider.overrideWithValue(_Port()),
                ],
                themeMode: mode,
              ),
            );
            await stabiliser(tester);
            debugPrint(
              'PNG ${await capturer(tester, 'CHIFFRES-ACADEMIE/chiffres_${langue.name}_${mode.name}_$nom')}',
            );
            await tester.pumpWidget(const SizedBox.shrink());
          });
        }
      }
    }
  });
}
