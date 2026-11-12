// ANTI-CRASH (garde-cap, 12/11/2026) : une erreur dans le `build` d'un widget
// donne la carte « Cet element n'a pas pu s'afficher » avec « Reessayer », a
// la place du seul element fautif ; le reste de l'ecran (coquille, barre,
// autres actions) reste utilisable. La carte s'affiche meme sans theme, sans
// `MediaQuery` ni `Directionality`. Les gestionnaires d'erreurs sont
// enchaines, jamais ecrases.
//
// La page introuvable du routeur (errorBuilder) est prouvee sur le vrai
// routeur par test/router/etats_transverses_test.dart.

import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterExceptionHandler;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/observabilite/garde_erreurs.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

/// Un element qui echoue tant que [echoue] est vrai.
class _Explosif extends StatelessWidget {
  const _Explosif(this.etat);

  final _Etat etat;

  @override
  Widget build(BuildContext context) {
    if (etat.echoue) throw StateError('donnee inattendue');
    return const Text('contenu affiche');
  }
}

class _Etat {
  bool echoue = true;
}

void main() {
  late ErrorWidgetBuilder builderAvant;
  late FlutterExceptionHandler? onErrorAvant;
  late ErrorCallback? plateformeAvant;

  setUp(() {
    builderAvant = ErrorWidget.builder;
    onErrorAvant = FlutterError.onError;
    plateformeAvant = PlatformDispatcher.instance.onError;
    reinitialiserGardeErreurs();
    LocaleSettings.setLocaleSync(AppLocale.fr);
  });

  tearDown(() {
    ErrorWidget.builder = builderAvant;
    FlutterError.onError = onErrorAvant;
    PlatformDispatcher.instance.onError = plateformeAvant;
    reinitialiserGardeErreurs();
    LocaleSettings.setLocaleSync(AppLocale.fr);
  });

  testWidgets('un element qui plante donne la carte, et le reste de l ecran '
      'reste utilisable ; « Reessayer » le reconstruit', (
    WidgetTester tester,
  ) async {
    final ErrorWidgetBuilder builderDuTest = ErrorWidget.builder;
    final FlutterExceptionHandler? onErrorDuTest = FlutterError.onError;
    try {
      installerGardeErreurs();
      final _Etat etat = _Etat();
      int autres = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                _Explosif(etat),
                ActionPrincipale(
                  libelle: 'Autre action',
                  onPress: () => autres++,
                ),
              ],
            ),
            bottomNavigationBar: const Text('barre de navigation'),
          ),
        ),
      );
      // L'erreur est bien remontee (supervision, journal) : le test la lit.
      expect(tester.takeException(), isA<StateError>());

      expect(find.byKey(CarteErreurElement.carteKey), findsOneWidget);
      expect(find.text(t.commun.erreurElement), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing, reason: 'jamais le gris');
      expect(find.text('barre de navigation'), findsOneWidget);

      await tester.tap(find.text('Autre action'));
      await tester.pump();
      expect(autres, 1, reason: 'le reste de l ecran repond');

      etat.echoue = false;
      await tester.tap(find.byKey(CarteErreurElement.reessayerKey));
      await tester.pump();
      expect(find.text('contenu affiche'), findsOneWidget);
      expect(find.byKey(CarteErreurElement.carteKey), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      // Le cadre de test exige ces deux portes remises avant la fin du
      // corps du test.
      ErrorWidget.builder = builderDuTest;
      FlutterError.onError = onErrorDuTest;
    }
  });

  testWidgets('sans theme, sans MediaQuery ni Directionality : la carte '
      's affiche quand meme, sans bouton', (WidgetTester tester) async {
    await tester.pumpWidget(
      CarteErreurElement(
        details: FlutterErrorDetails(exception: StateError('haut place')),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(t.commun.erreurElement), findsOneWidget);
    expect(find.byKey(CarteErreurElement.reessayerKey), findsNothing);
  });

  testWidgets('en arabe : la carte se lit de droite a gauche', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await tester.pumpWidget(
      CarteErreurElement(
        details: FlutterErrorDetails(exception: StateError('x')),
      ),
    );
    expect(find.text(t.commun.erreurElement), findsOneWidget);
    final Text texte = tester.widget<Text>(find.text(t.commun.erreurElement));
    expect(texte.data, isNot(contains('élément')));
    expect(
      Directionality.of(tester.element(find.text(t.commun.erreurElement))),
      TextDirection.rtl,
    );
  });

  test('les gestionnaires deja poses sont enchaines, jamais ecrases ; une '
      'erreur asynchrone n arrete pas l application', () {
    int flutter = 0;
    int plateforme = 0;
    FlutterError.onError = (FlutterErrorDetails _) => flutter++;
    PlatformDispatcher.instance.onError = (Object _, StackTrace _) {
      plateforme++;
      return false;
    };
    installerGardeErreurs();
    installerGardeErreurs(); // idempotent : pas de double enchainement

    FlutterError.onError!(FlutterErrorDetails(exception: StateError('build')));
    expect(flutter, 1);

    final bool traitee = PlatformDispatcher.instance.onError!(
      StateError('async'),
      StackTrace.current,
    );
    expect(plateforme, 1);
    expect(traitee, isTrue);
    expect(
      ErrorWidget.builder(FlutterErrorDetails(exception: 'x')),
      isA<CarteErreurElement>(),
    );
  });
}
