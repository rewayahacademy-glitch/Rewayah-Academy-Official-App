// L'hote commun des tests de la bibliotheque d'administration (CAP-29) : la
// vraie application en demonstration d'administration, ouverte sur une route.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

/// Laisse passer les futurs en memoire et les animations courtes.
Future<void> stabiliser(WidgetTester tester, {int fois = 8}) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Monte l'application en demonstration d'administration, ouverte sur [route].
/// [plus] vient apres la demonstration : il la surcharge (un port different).
Future<void> monterAdminDemo(
  WidgetTester tester, {
  required String route,
  List<Override> plus = const <Override>[],
  PortBibliothequeAdmin? bibliotheque,
  bool bibliothequeAbsente = false,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(
          environnement: 'staging',
          bibliotheque: bibliotheque,
          bibliothequeAbsente: bibliothequeAbsente,
        ),
        ...plus,
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) {
            Widget enfant = RepereDemonstration(child: child);
            if (echelle != 1) {
              enfant = MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: enfant,
              );
            }
            return direction == null
                ? enfant
                : Directionality(textDirection: direction, child: enfant);
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(route);
  await stabiliser(tester);
}
