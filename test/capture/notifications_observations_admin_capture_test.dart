// Captures de recette du lot E, sous-paquet 3 : Notifications du tuteur et
// consultation admin des observations, sur le VRAI routeur, a 390x844 et
// 1440x900, clair et sombre ; etats de production (indisponibles) ; planche
// maquette | rendu de l'ecran admin (V8 D3).
//
// Saute sans CAPTURE_DIR. La planche demande en plus la maquette recadree :
//   CAPTURE_MAQUETTE_ADMIN_D3.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : doubles isoles.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/admin_observations/support_admin_observations.dart';
import '../features/historique/support_historique.dart';
import 'outil_capture.dart';

String? _env(String nom) {
  final String? v = Platform.environment[nom];
  return v == null || v.trim().isEmpty ? null : v;
}

class _Notifications implements PortNotifications {
  _Notifications(this.rendues);

  final List<NotificationTuteur> rendues;

  @override
  Future<List<NotificationTuteur>> liste() async => rendues;

  @override
  Future<NotificationTuteur?> detail(String id) async => null;
}

List<NotificationTuteur> _notifications() {
  final DateTime maintenant = DateTime.now();
  DateTime jour(int n, int h, int m) =>
      DateTime(maintenant.year, maintenant.month, maintenant.day - n, h, m);
  return <NotificationTuteur>[
    NotificationTuteur(
      id: 'n1',
      titre: 'Séance de Mariam terminée : présence enregistrée',
      date: jour(0, 19, 5),
      destination: Routes.tuteurSuivi,
    ),
    NotificationTuteur(
      id: 'n2',
      titre: 'La classe An-Nour commence dans 1 heure',
      date: jour(1, 17, 0),
      destination: Routes.tuteurAccueil,
    ),
    NotificationTuteur(
      id: 'n3',
      titre: 'Message de l’académie : calendrier des vacances',
      date: jour(4, 9, 30),
    ),
  ];
}

Future<void> _notificationsMontees(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  PortNotifications? port,
}) => monterHistorique(
  tester,
  depart: Routes.tuteurNotifications,
  taille: null,
  mode: mode,
  cadre: cadreCapture,
  autres: <Override>[
    if (port != null) portNotificationsProvider.overrideWithValue(port),
  ],
);

Future<void> _adminMonte(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  bool production = false,
}) => monterAdmin(
  tester,
  Routes.adminSecuriteAuditObservations,
  taille: null,
  mode: mode,
  cadre: cadreCapture,
  port: production ? null : FauxHistoriqueObservationsAdmin(),
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
  group('Capture : Notifications et observations admin', skip: sautSansCapture, () {
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

    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final bool production in <bool>[true, false]) {
        final String etat = production ? 'indisponible' : 'simulation';
        testWidgets('390x844 @3, notifications $etat, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: zone);
          await _notificationsMontees(
            tester,
            mode: mode,
            port: production ? null : _Notifications(_notifications()),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'e_notifications_${etat}_390x844@3_${mode.name}')}',
          );
        });
        testWidgets('1440x900 @1, notifications $etat, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _notificationsMontees(
            tester,
            mode: mode,
            port: production ? null : _Notifications(_notifications()),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'e_notifications_${etat}_1440x900@1_${mode.name}')}',
          );
        });
        testWidgets('390x844 @3, observations admin $etat, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: zone);
          await _adminMonte(tester, mode: mode, production: production);
          debugPrint(
            'PNG ${await capturer(tester, 'e_observations_admin_${etat}_390x844@3_${mode.name}')}',
          );
        });
        testWidgets('1440x900 @1, observations admin $etat, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _adminMonte(tester, mode: mode, production: production);
          debugPrint(
            'PNG ${await capturer(tester, 'e_observations_admin_${etat}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }

    testWidgets('390x844 @3, notifications vides', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: zone);
      await _notificationsMontees(
        tester,
        port: _Notifications(const <NotificationTuteur>[]),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'e_notifications_vide_390x844@3_light')}',
      );
    });

    final String? maquetteD3 = _env('CAPTURE_MAQUETTE_ADMIN_D3');
    testWidgets(
      'planche : e_planche_observations_admin_bureau_clair',
      skip: maquetteD3 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, maquetteD3!);
        // D3 est dessinee environ 1,22 fois plus dense qu'un ecran reel
        // (rapport V8) : 1053 px de maquette pour ~1285 de bureau.
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 1285,
        );
        await _adminMonte(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'e_planche_observations_admin_bureau_clair', maquetteD3)}',
        );
      },
    );
  });
}
