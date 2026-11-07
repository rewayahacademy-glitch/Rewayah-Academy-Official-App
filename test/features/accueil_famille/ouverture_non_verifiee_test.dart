// Ouverture de la salle non verifiee (directeur, 06/11/2026 : « j'ai jamais
// compris cette phrase » ; tranche par le garde-cap le 07/11/2026) : avant
// l'heure, quand le bouton parait ; a l'heure, quoi faire, et « Recharger »
// en lien discret, jamais un second bouton plein.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final DateTime debut = DateTime.utc(2026, 11, 7, 18);
  final SeanceFamille sansFenetre = seanceFictive(
    debutUtc: debut,
    avecHorloge: false,
  );

  Future<int> monter(WidgetTester tester, DateTime appareil) async {
    int recharges = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocSeance(
              affichage: AffichageSeance.depuis(
                sansFenetre,
                maintenantServeurUtc: null,
                maintenantAppareilUtc: appareil,
              ),
              compact: true,
              onRecharger: () => recharges++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (find.byKey(BlocSeance.rechargerKey).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(BlocSeance.rechargerKey));
      await tester.pump();
    }
    return recharges;
  }

  testWidgets('avant l heure : quand le bouton parait, aucun « Recharger »', (
    WidgetTester tester,
  ) async {
    final int recharges = await monter(
      tester,
      debut.subtract(const Duration(hours: 1)),
    );
    expect(
      find.text(t.tuteur.accueil.horaireIncertainAvant(n: 20)),
      findsOneWidget,
    );
    expect(find.byKey(BlocSeance.rechargerKey), findsNothing);
    expect(recharges, 0);
  });

  testWidgets('a l heure : quoi faire, et « Recharger » en lien discret', (
    WidgetTester tester,
  ) async {
    final int recharges = await monter(
      tester,
      debut.add(const Duration(minutes: 3)),
    );
    expect(find.text(t.tuteur.accueil.horaireIncertainPendant), findsOneWidget);
    expect(find.byKey(BlocSeance.rechargerKey), findsOneWidget);
    expect(find.byType(ActionPrincipale), findsNothing);
    expect(find.text(t.tuteur.accueil.horaireIncertain), findsNothing);
    expect(recharges, 1);
  });
}
