import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';

Widget _hote(Widget enfant, InterfaceMode mode) => TranslationProvider(
  child: MaterialApp(
    theme: AppTheme.pour(mode, Brightness.light),
    home: Scaffold(body: enfant),
  ),
);

void main() {
  group('Scenario 2 : PermanentNotice n a aucune prise', () {
    testWidgets(
      'le bandeau affiche exactement la meme ligne pour l eleve et pour l enseignant',
      (WidgetTester tester) async {
        // ELV-03 et ENS-03 rendent le MEME composant. C'est ce qui garantit
        // qu'ils ne peuvent pas afficher deux textes differents.
        await tester.pumpWidget(
          _hote(const PermanentNotice(), InterfaceMode.enfant),
        );
        final String cotEleve = tester
            .widgetList<Text>(find.byType(Text))
            .map((Text w) => w.data ?? '')
            .join();

        await tester.pumpWidget(
          _hote(const PermanentNotice(), InterfaceMode.standard),
        );
        final String cotEnseignant = tester
            .widgetList<Text>(find.byType(Text))
            .map((Text w) => w.data ?? '')
            .join();

        expect(cotEleve, cotEnseignant);
        expect(cotEleve, contains('enregistr'));
        expect(cotEleve, contains('contr'));
      },
    );

    testWidgets('le bandeau est toujours rendu, sans condition', (
      WidgetTester tester,
    ) async {
      // Le composant n'expose aucun parametre de visibilite : il n'existe
      // aucun appel possible qui le ferait disparaitre. Un bandeau qui
      // apparaitrait a l'entree d'un controleur detruirait l'invisibilite
      // que l'ADR-011 garantit.
      await tester.pumpWidget(
        _hote(const PermanentNotice(), InterfaceMode.standard),
      );
      expect(find.byType(PermanentNotice), findsOneWidget);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    });

    test('le constructeur n accepte aucun parametre', () {
      // Le controle porte sur la SOURCE, parce que c'est la que se joue la
      // regle : le jour ou quelqu'un ajoute `bool visible = true`, le code
      // continuerait de compiler partout et l'ADR-011 tomberait en silence.
      // tool/verifier_jetons.dart applique le meme controle en CI.
      final String source = File('lib/core/widgets/permanent_notice.dart')
          .readAsStringSync();

      final RegExpMatch? constructeur = RegExp(
        r'const\s+PermanentNotice\s*\(\s*([^)]*)\)',
      ).firstMatch(source);

      expect(
        constructeur,
        isNotNull,
        reason: 'le constructeur const PermanentNotice() a disparu',
      );
      expect(
        constructeur!.group(1)!.trim(),
        isEmpty,
        reason:
            'PermanentNotice a gagne un parametre : "${constructeur.group(1)}". '
            'Un parametre de visibilite finira par etre utilise et detruira '
            'l invisibilite du controle (ADR-011).',
      );
    });
  });
}
