// COM-F : les emplacements ajoutes a FilDiscussion ne changent pas l'ecran
// Echanges du controleur. Depuis la VRAIE route de demonstration et la vraie
// coquille : le fil ouvert n'a ni en-tete, ni piece jointe, ni vocal, sa
// colonne a toujours deux enfants (la liste et la saisie), et ses textes sont
// ceux du controleur.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

void main() {
  testWidgets('Echanges du controleur : fil identique, aucun emplacement', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: GoRouter(
              initialLocation: adresseDemoControleur(
                EcranDemoControleur.controle,
              ),
              routes: routesDemoControleur('dev'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> attendre() async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    await tester.tap(
      find.descendant(
        of: find.byKey(NavShell.railKey),
        matching: find.text(t.nav.controleur.echanges),
      ),
    );
    await attendre();
    await tester.tap(find.text('Classe Al-Badr · Jeudi 24 septembre'));
    await attendre();

    final FilDiscussion fil = tester.widget<FilDiscussion>(
      find.byType(FilDiscussion),
    );
    expect(fil.entete, isNull);
    expect(fil.emplacementPieceJointe, isNull);
    expect(fil.emplacementVocal, isNull);

    final Column racine = tester.widget<Column>(
      find
          .descendant(
            of: find.byType(FilDiscussion),
            matching: find.byType(Column),
          )
          .first,
    );
    expect(racine.children, hasLength(2));

    final e = t.controleur.echanges;
    expect(fil.textes.envoyer, e.envoyer);
    expect(fil.textes.echec, e.echec);
    expect(find.text(e.champVide), findsOneWidget);
    expect(find.text(t.com.socle.composants.composer.vocal), findsNothing);
  });
}
