// BE-2b : l'ecran « Equipe » par le VRAI routeur (coque d'administration
// comprise), puis ses captures R3.
//
// CAPTURE_DIR=docs/current/captures/E2E/BE-2B-EQUIPE flutter test \
//   test/features/admin_equipe/capture_equipe_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/equipe/modeles_equipe.dart';
import 'package:rewayah_academy/core/equipe/port_equipe.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_equipe/equipe_page.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart' show FausseSourceSession;
import 'faux_equipe.dart';

Future<void> _monter(
  WidgetTester tester,
  FauxEquipe port,
  Size taille, {
  bool arabe = false,
}) async {
  await monterRouteur(
    tester,
    Routes.adminPersonnesEquipe,
    source: FausseSourceSession(sessionActive(AppRole.admin)),
    taille: taille,
    direction: arabe ? TextDirection.rtl : null,
    surcharges: <Override>[
      portEquipeProvider.overrideWithValue(port),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    ],
  );
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets(
    'par le vrai routeur : la page s\'ouvre dans la coque de la direction',
    (WidgetTester tester) async {
      await _monter(
        tester,
        FauxEquipe(attributionsRendues: <Attribution>[attributionKarim]),
        const Size(360, 800),
      );
      expect(find.byType(EquipePage), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      final double haut = tester.getTopLeft(find.text('Karim')).dy;
      // ignore: avoid_print
      print('MESURE BE-2b coque reelle 360x800 : premier nom a $haut points');
      expect(tester.takeException(), isNull);
    },
  );

  group('captures BE-2B', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size taille, AppLocale langue) in <(Size, AppLocale)>[
      (const Size(360, 800), AppLocale.fr),
      (const Size(360, 800), AppLocale.ar),
      (const Size(1440, 900), AppLocale.fr),
      (const Size(1440, 900), AppLocale.ar),
    ]) {
      final String nom =
          'equipe-${taille.width.toInt()}-${langue.languageCode}';
      testWidgets(nom, (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          FauxEquipe(
            attributionsRendues: <Attribution>[attributionKarim],
            missionsRendues: const <Mission>[missionLecture],
          ),
          taille,
          arabe: langue == AppLocale.ar,
        );
        await capturerVue(tester, nom);
      });
    }
  }, skip: sautSansCapture);
}
