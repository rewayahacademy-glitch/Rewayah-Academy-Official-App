// AudioLabel (UX-027, lot A11Y-1, WCAG 2.2 AA 4.1.2) : le bouton parle se lit
// une fois, par son nom ; le texte dessine n'est pas relu.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/cle_audio.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/audio_label.dart';

import '../../support/harnais.dart';

void main() {
  testWidgets('le libelle parle se lit une seule fois', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: Center(child: AudioLabel(cle: ClesAudio.pinTitre)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.pin.titre), findsOneWidget);
    expect(
      tester.getSemantics(find.text(t.pin.titre)),
      isSemantics(
        label: t.pin.titre,
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    semantique.dispose();
  });
}
