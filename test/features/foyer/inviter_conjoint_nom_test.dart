// FORM-L6 : l'invitation du conjoint prerempli le nom de famille du titulaire
// (modifiable), depuis la VRAIE coquille adulte (Mon espace > Ma famille > la
// place). L'identite vient du port du Compte, ici la demonstration (Diallo).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

Future<void> _ouvrirInvitation(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoAdulte(
      EcranDemoAdulte.accueil,
      etat: EtatDemoAdulte.titulaireSansConjoint,
    ),
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.adulte.nav.monEspace).first);
  await tester.pumpAndSettle();
  final Finder famille = find.descendant(
    of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
    matching: find.text(t.adulte.famille.maFamille),
  );
  await tester.ensureVisible(famille);
  await tester.tap(famille);
  await tester.pumpAndSettle();
  final Finder place = find.descendant(
    of: find.byKey(lignePlaceAdulteKey),
    matching: find.text(t.adulte.famille.place.ajouterConjointe),
  );
  await tester.ensureVisible(place);
  await tester.tap(place);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FORM-L6 : le nom du conjoint est prerempli avec celui du '
      'titulaire, modifiable, et le recapitulatif dit ce qui part', (
    WidgetTester tester,
  ) async {
    await _ouvrirInvitation(tester);
    expect(find.byType(InviterConjointPage), findsOneWidget);

    TextField nom() =>
        tester.widget<TextField>(find.byKey(InviterConjointPage.nomKey));
    expect(nom().controller!.text, DonneesAdulteDemo.nomFamille);
    expect(find.text(t.adulte.invitation.nomAidePrerempli), findsOneWidget);

    // Modifiable, et la modification n'est plus reecrite.
    await tester.enterText(find.byKey(InviterConjointPage.nomKey), 'Ba');
    await tester.enterText(
      find.byKey(InviterConjointPage.prenomKey),
      'Mariama',
    );
    await tester.enterText(
      find.byKey(InviterConjointPage.courrielKey),
      'mariama@example.com',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(InviterConjointPage.verifierKey));
    await tester.tap(find.byKey(InviterConjointPage.verifierKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(InviterConjointPage.recapitulatifKey),
        matching: find.text('Ba'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('FORM-L6 : un nom vide volontairement reste vide', (
    WidgetTester tester,
  ) async {
    await _ouvrirInvitation(tester);
    await tester.enterText(find.byKey(InviterConjointPage.nomKey), '');
    await tester.enterText(
      find.byKey(InviterConjointPage.prenomKey),
      'Mariama',
    );
    await tester.enterText(
      find.byKey(InviterConjointPage.courrielKey),
      'mariama@example.com',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(InviterConjointPage.verifierKey));
    await tester.tap(find.byKey(InviterConjointPage.verifierKey));
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.invitation.nonRenseigne), findsOneWidget);
  });
}
