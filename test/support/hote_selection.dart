// Hote commun des tests et captures de la selection du texte (directeur,
// 07/11/2026) : le vrai `SelectionRacine` dans le `builder` de `MaterialApp`,
// comme `RewayahApp`, sur le vrai theme.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/selection_racine.dart';

import '../capture/outil_capture.dart' show cadreCapture;

/// Monte [ecran] sous la sélection racine.
Widget hoteSelection(
  Widget ecran, {
  List<Override> surcharges = const <Override>[],
  ThemeMode themeMode = ThemeMode.light,
  bool brut = false,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: themeMode,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext _, Widget? app) =>
              SelectionRacine(child: app!),
          home: brut
              ? ecran
              : Scaffold(
                  body: SafeArea(child: SingleChildScrollView(child: ecran)),
                ),
        ),
      ),
    ),
  ),
);

/// Ce qu'une sélection de tout l'écran met dans le presse-papiers.
///
/// Sélectionne tout, copie, et rend le texte copié ; le vide si rien n'est
/// sélectionnable.
Future<String> toutCopier(WidgetTester tester) async {
  String copie = '';
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall appel) async {
      if (appel.method == 'Clipboard.setData') {
        copie = (appel.arguments as Map<Object?, Object?>)['text']! as String;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  await tester.pump();
  final SelectableRegionState region = tester.state<SelectableRegionState>(
    find.byType(SelectableRegion),
  );
  region.selectAll();
  await tester.pump();
  final List<ContextMenuButtonItem> boutons = region.contextMenuButtonItems
      .where((ContextMenuButtonItem b) => b.type == ContextMenuButtonType.copy)
      .toList();
  // Rien de selectionne : le menu n'offre pas « Copier ».
  if (boutons.isNotEmpty) boutons.single.onPressed?.call();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return copie;
}
