// « Paie des enseignants » dans la Finance de la direction (directeur,
// 31/10/2026 : la direction voit la paie avec son compte). Le meme ecran et
// la meme source que les paiements a effectuer du Comptable, dans l'espace
// de la direction : onglet de la Finance, liens qui ne quittent jamais
// `/admin/finance`, et la route reste fermee au Comptable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/ligne_obligation.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../comptable/paiements/support_paiements.dart';

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

/// L'adresse de la page au sommet, apres un `push`.
String _sommet(GoRouter r) =>
    r.routerDelegate.currentConfiguration.last.matchedLocation;

Future<GoRouter> _direction(WidgetTester tester, {Size? taille}) =>
    monterRouteur(
      tester,
      Routes.adminFinancePaie,
      source: FausseSourceSession(sessionActive(AppRole.admin)),
      taille: taille ?? const Size(1440, 900),
      surcharges: surchargesDemo(EtatDemoPaiements()),
    );

void main() {
  testWidgets('la direction ouvre « Paie des enseignants », sixieme onglet '
      'de sa Finance', (WidgetTester tester) async {
    final GoRouter routeur = await _direction(tester);
    await tester.pumpAndSettle();
    expect(_chemin(routeur), Routes.adminFinancePaie);
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(PaiementsAEffectuerPage), findsOneWidget);
    final SousNavigationDomaine onglets = tester.widget<SousNavigationDomaine>(
      find.byType(SousNavigationDomaine),
    );
    expect(onglets.onglets, ongletsFinance());
    expect(onglets.indexActif, ongletsFinance().length - 1);
    expect(find.text(t.admin.finance.paieEnseignants), findsWidgets);
  });

  testWidgets('une ligne ouvre son detail dans l espace de la direction, '
      'jamais sous /comptable', (WidgetTester tester) async {
    final GoRouter routeur = await _direction(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sayyid Youssouf Diallo'));
    await tester.pumpAndSettle();
    expect(
      _sommet(routeur),
      startsWith('${Routes.adminFinancePaieObligation}/'),
    );
    expect(find.byType(DetailPaiementPage), findsOneWidget);
    expect(find.byType(AdminShell), findsOneWidget);
  });

  testWidgets('Relancer reste dans l espace de la direction (aucune page du '
      'Comptable)', (WidgetTester tester) async {
    final GoRouter routeur = await _direction(
      tester,
      taille: const Size(1440, 2400),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ActionObligation.cleDe(PaiementsDemo.obligationInfosManquantes),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _sommet(routeur),
      '${Routes.adminFinancePaieObligation}/'
      '${PaiementsDemo.obligationInfosManquantes}',
    );
    expect(_sommet(routeur), isNot(startsWith(Routes.comptable)));
    expect(find.text(t.comptable.paiements.actions.voirProfil), findsNothing);
  });

  testWidgets('un Comptable n ouvre pas la paie de la direction', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      Routes.adminFinancePaie,
      source: FausseSourceSession(sessionActive(AppRole.accountant)),
    );
    expect(_chemin(routeur), Routes.comptable);
  });
}
