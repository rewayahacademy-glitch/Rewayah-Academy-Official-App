// L4-06 : captures de la Pedagogie (Programmes) a 9 s (chargement prolonge
// explique) et a 21 s (lecture perdue, recuperable). Le temps est simule.
// Lancer avec CAPTURE_DIR (voir LISEZ-MOI.md).
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../support/monter_admin_demo.dart';
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  // La demonstration ouvre une base drift, qui demande path_provider (absent
  // en test) des que `runAsync` laisse tourner le vrai asynchrone.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall _) async => Directory.systemTemp.path,
        );
  });

  group('L4-06 pedagogie : chargement prolonge puis recuperable', () {
    testWidgets('1440 clair : 9 s puis 21 s', (tester) async {
      await monterAdminDemo(
        tester,
        route: Routes.adminPedagogieProgrammes,
        plus: [
          versionsProgrammeProvider.overrideWith(
            (Ref _) => Completer<List<VersionProgramme>>().future,
          ),
        ],
      );
      await tester.pump(const Duration(seconds: 9));
      await capturerVue(tester, 'L4-06_pedagogie_prolonge_1440_light');
      await tester.pump(const Duration(seconds: 12));
      await capturerVue(tester, 'L4-06_pedagogie_recuperable_1440_light');
    });
  }, skip: sautSansCapture);
}
