// Le montage du VRAI routeur du tuteur pour COM-ANN-1 : session de tuteur,
// foyer fictif A, Classe fictive A (`support_classe.dart`), plus les ports
// des notifications et des annonces donnes par le test. La langue suit
// `LocaleSettings` (arabe : de droite a gauche).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../router/support_routeur.dart';
import '../classe_tuteur/support_classe.dart';

export '../classe_tuteur/support_classe.dart' show classeA, eleveA1;

/// Monte le routeur du tuteur a [depart], a la taille [taille].
Future<GoRouter> monterTuteurAnnonces(
  WidgetTester tester, {
  required String depart,
  Size taille = const Size(390, 844),
  List<Override> autres = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[...surchargesClasse(), ...autres],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}
