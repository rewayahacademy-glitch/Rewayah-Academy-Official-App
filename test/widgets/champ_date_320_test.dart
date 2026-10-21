// FORM-CORR-1 : le calendrier du champ date tient a 320 de large, texte x2
// (revue C1-FORM-R, M3 : jours 20 et 30 sur deux lignes, en-tete tronque).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;

void main() {
  // Les vraies polices : avec celle des tests (des carres), un chiffre est aussi
  // large que haut et le calendrier deborde a toute echelle.
  setUpAll(chargerPolicesDuDepot);

  testWidgets('a 320 x2, les jours a deux chiffres tiennent sur une ligne et '
      'l\'en-tete n\'est pas tronque', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 2800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: const Locale('fr'),
          supportedLocales: const <Locale>[Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext c, Widget? w) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: w!,
          ),
          home: Scaffold(
            body: ChampDate(
              libelle: 'Date prevue',
              valeur: null,
              onChoix: (_) {},
              aujourdhui: DateTime(2026, 10, 4),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('champ-date')));
    await tester.pumpAndSettle();
    // Une boite par ligne : un jour a deux chiffres sur deux lignes en aurait
    // deux.
    for (final String jour in <String>['20', '30']) {
      final RenderParagraph p = tester.renderObject(find.text(jour));
      expect(
        p.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 2),
        ),
        hasLength(1),
        reason: 'jour $jour sur une ligne',
      );
    }
    final RenderParagraph entete = tester.renderObject(
      find.descendant(
        of: find.text('dim. 4 oct.'),
        matching: find.byType(RichText),
      ),
    );
    expect(entete.didExceedMaxLines, isFalse);
    expect(find.textContaining('octobre 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
