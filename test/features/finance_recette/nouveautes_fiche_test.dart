// NOUVEAUTES (07/11/2026) : le badge sur la fiche eleve du tuteur (ligne
// « Couleur du profil » et bouton « Recharger »), lu « nouveau », parti au
// premier appui. Le robot local ne peut pas voir « Recharger » : sur la pile,
// les finances de l'eleve de test ne sont pas disponibles.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/nouveautes/nouveautes.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';

import '../../support/demo/finance_demo.dart';
import 'support_recette_fi.dart';

const String _ibrahim = DonneesFinanceDemo.ibrahimId;

class _FauxPort implements PortNouveautes {
  _FauxPort(this.cles);

  final Set<String> cles;
  final List<String> marquees = <String>[];

  @override
  Future<Set<String>> mes() async => <String>{...cles};

  @override
  Future<void> marquerVue(String cle) async {
    marquees.add(cle);
    cles.remove(cle);
  }
}

void main() {
  testWidgets('Recharger : badge, lu « ..., nouveau », parti au premier appui', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final _FauxPort port = _FauxPort(<String>{CleNouveaute.moyenPaiement});
    await monterTuteurFi(
      tester,
      depart: Routes.ficheEleveSousPage(_ibrahim, 'finances'),
      surcharges: <Override>[portNouveautesProvider.overrideWithValue(port)],
    );
    final Finder bouton = find.byKey(FinancesElevePage.rechargerKey);
    expect(bouton, findsOneWidget);
    expect(find.text(t.nouveautes.badge), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(', ${t.nouveautes.lu}\$')),
      findsOneWidget,
    );
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(port.marquees, <String>[CleNouveaute.moyenPaiement]);
    semantique.dispose();
  });

  testWidgets('Couleur du profil : badge, parti au premier appui', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final _FauxPort port = _FauxPort(<String>{CleNouveaute.couleurProfil});
    await monterTuteurFi(
      tester,
      depart: Routes.ficheElevePour(_ibrahim),
      surcharges: <Override>[portNouveautesProvider.overrideWithValue(port)],
    );
    expect(find.text(t.nouveautes.badge), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(
          '${t.ficheEleve.lignes.couleur}.*\\b${t.nouveautes.lu}\\b',
          dotAll: true,
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(t.ficheEleve.lignes.couleur));
    await tester.pumpAndSettle();
    expect(port.marquees, <String>[CleNouveaute.couleurProfil]);
    semantique.dispose();
  });
}
