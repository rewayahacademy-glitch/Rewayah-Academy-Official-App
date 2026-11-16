// PIECE-DANS-DOSSIER (16/11/2026) : le bandeau fermable (« J'ai compris »), le
// choix reste dans la memoire de l'appareil.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/bandeau_fermable.dart';

class _MemoireIllisible implements StockagePreferences {
  @override
  Future<String?> lire(String clef) => Future<String?>.error(StateError('x'));

  @override
  Future<void> ecrire(String clef, String valeur) =>
      Future<void>.error(StateError('x'));
}

Future<void> _monter(WidgetTester tester, StockagePreferences memoire) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [stockagePreferencesProvider.overrideWithValue(memoire)],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: const Scaffold(
              body: BandeauFermable(
                clef: 'bandeau.essai',
                titre: 'Titre',
                message: 'Message',
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('premiere ouverture : visible, avec « J\'ai compris »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, StockagePreferencesMemoire());
    await tester.pumpAndSettle();
    expect(find.byType(BandeauAttention), findsOneWidget);
    expect(find.text(t.accuse.compris), findsOneWidget);
  });

  testWidgets('fermer : il disparait, la memoire le garde, il ne revient pas', (
    WidgetTester tester,
  ) async {
    final StockagePreferencesMemoire memoire = StockagePreferencesMemoire();
    await _monter(tester, memoire);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BandeauFermable.cleFermer));
    await tester.pumpAndSettle();
    expect(find.byType(BandeauAttention), findsNothing);
    expect(await memoire.lire('bandeau.essai'), 'vu');
    // Une autre ouverture, meme appareil.
    await tester.pumpWidget(const SizedBox.shrink());
    await _monter(tester, memoire);
    await tester.pumpAndSettle();
    expect(find.byType(BandeauAttention), findsNothing);
  });

  testWidgets('memoire illisible : le bandeau reste visible', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _MemoireIllisible());
    await tester.pumpAndSettle();
    expect(find.byType(BandeauAttention), findsOneWidget);
    await tester.tap(find.byKey(BandeauFermable.cleFermer));
    await tester.pumpAndSettle();
    expect(find.byType(BandeauAttention), findsNothing);
  });
}
