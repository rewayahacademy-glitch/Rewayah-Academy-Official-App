// REMPLACEMENT-TEMPS-REEL (07/11/2026, DECISION-REMPLACEMENT §5) : pendant la
// fenetre de priorite, « Vous etes en tete, confirmation dans quelques
// secondes » et un compte a rebours vivant ; sinon, la phrase d'attente.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/remplacements/remplacements_page.dart';

import '../../support/hote_theme.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final r = t.enseignant.remplacements;

  testWidgets('en tete : la phrase et le compte a rebours', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        AttentePriorite(
          attente: AttenteRemplacement(
            fin: DateTime.now().add(const Duration(seconds: 8)),
            enTete: true,
          ),
        ),
      ),
    );
    expect(find.textContaining(r.enTete), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+ s')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pas en tete : la phrase d attente, jamais « en tete »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        AttentePriorite(
          attente: AttenteRemplacement(
            fin: DateTime.now().add(const Duration(seconds: 5)),
            enTete: false,
          ),
        ),
      ),
    );
    expect(find.textContaining(r.attente), findsOneWidget);
    expect(find.textContaining(r.enTete), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
