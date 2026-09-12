import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/config/ecran_configuration_absente.dart';
import 'package:rewayah_academy/core/config/env.dart';

/// Le filet qui remplace un `assert` disparu de la version compilee.
///
/// Ces tests ne verifient pas une mise en page : ils verifient qu'une
/// compilation sans cles se DENONCE au lieu de se taire. C'est le silence qui
/// avait coute la journee du 12 septembre 2026, pas l'absence de cles.
void main() {
  test('sans --dart-define, Env.configuree est faux', () {
    // La suite tourne sans `--dart-define-from-file`, donc les deux valeurs
    // sont vides. Si ce test passait au vert un jour, c'est que la
    // configuration serait entree en dur dans le depot.
    expect(Env.supabaseUrl, isEmpty);
    expect(Env.supabaseAnonKey, isEmpty);
    expect(Env.configuree, isFalse);
  });

  testWidgets("l'ecran de dernier recours nomme ce qui manque", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcranConfigurationAbsente());

    expect(find.text('Configuration absente'), findsOneWidget);
    expect(find.text(Env.aideConfiguration), findsOneWidget);
  });

  testWidgets('il donne la commande exacte qui repare', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcranConfigurationAbsente());

    // La commande est la seule chose que son lecteur ait besoin de faire :
    // l'omettre renverrait a la meme recherche a l'aveugle. On cherche la
    // ligne ENTIERE : le fragment `--dart-define-from-file` figure aussi
    // dans le message d'aide, qui vise `flutter run` et non la version web.
    expect(
      find.textContaining(
        'flutter build web --release '
        '--dart-define-from-file=dart_define.json',
      ),
      findsOneWidget,
    );
  });

  testWidgets("il ne depend d'aucun provider ni d'aucune traduction", (
    WidgetTester tester,
  ) async {
    // Pompe sans ProviderScope ni TranslationProvider : c'est la garantie
    // qui compte, puisqu'il s'affiche precisement quand rien d'autre ne peut
    // se construire.
    await tester.pumpWidget(const EcranConfigurationAbsente());

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
