// S02 (LT-5) : le solde d'un profil dans la fiche eleve et la ligne de solde
// de l'Accueil, TOUCHES sur le vrai routeur et la coquille du tuteur, avec la
// demonstration ; puis l'etat de production (DB-FIN-01 indisponible) : rien
// sur l'Accueil, une phrase courte sans bouton financier dans la fiche.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/resume_solde.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/compte/mouvements_page.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

final List<Override> _demo = <Override>[
  portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
];

final String _ficheAicha = Routes.ficheElevePour(DonneesDemo.aichaId);

void main() {
  testWidgets('demonstration : le bloc de la fiche ouvre les mouvements du '
      'profil et revient', (WidgetTester tester) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: _ficheAicha,
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );

    final Finder bloc = find.byKey(FicheElevePage.soldeKey);
    expect(
      find.descendant(of: bloc, matching: find.byType(ResumeSolde)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bloc,
        matching: find.text(t.finance.soldeDe(prenom: 'Aïcha')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bloc,
        matching: find.text(formaterMontant(1200, FinanceFoyerDemo.devise)),
      ),
      findsOneWidget,
    );
    // La derniere remise liee a une seance, telle que rendue.
    expect(
      find.descendant(
        of: bloc,
        matching: find.textContaining(
          formaterMontant(100, FinanceFoyerDemo.devise),
        ),
      ),
      findsOneWidget,
    );

    // Complement Tuteur section 5 : « Recharger pour [Prenom] ».
    expect(
      find.text(t.finance.soldes.rechargerPour(prenom: 'Aïcha')),
      findsOneWidget,
    );

    await toucher(tester, find.byKey(FicheElevePage.voirMouvementsKey));
    final Uri ici = Uri.parse(lieu(routeur));
    expect(ici.path, Routes.tuteurCompteMouvements);
    expect(ici.queryParameters['profil'], DonneesDemo.aichaId);
    expect(ici.queryParameters['retour'], _ficheAicha);
    expect(find.byType(MouvementsComptePage), findsOneWidget);
    expect(find.textContaining('Yusuf ·'), findsNothing);

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), _ficheAicha);
    expect(find.byType(FicheElevePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demonstration : la ligne de l Accueil ouvre S01 et revient', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurAccueil,
      eleves: DonneesDemo.eleves,
      surcharges: _demo,
    );

    final Finder ligne = find.byKey(LigneSoldesAccueil.cle);
    expect(
      find.descendant(
        of: ligne,
        matching: find.text(
          t.finance.soldes.ligneAccueil(
            total: formaterMontant(2000, FinanceFoyerDemo.devise),
          ),
        ),
      ),
      findsOneWidget,
    );

    await toucher(tester, ligne);
    final Uri ici = Uri.parse(lieu(routeur));
    expect(ici.path, Routes.tuteurCompteSoldes);
    expect(ici.queryParameters['retour'], Routes.tuteurAccueil);
    expect(find.byType(SoldesComptePage), findsOneWidget);

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.tuteurAccueil);
    expect(find.byType(AccueilFamillePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production : l Accueil n affiche pas de ligne de solde', (
    WidgetTester tester,
  ) async {
    await monterCompte(
      tester,
      depart: Routes.tuteurAccueil,
      eleves: DonneesDemo.eleves,
    );
    expect(find.byType(AccueilFamillePage), findsOneWidget);
    expect(find.byKey(LigneSoldesAccueil.cle), findsNothing);
    expect(find.textContaining(t.finance.soldes.titre), findsNothing);
  });

  testWidgets('production : la fiche dit l indisponibilite, sans bouton', (
    WidgetTester tester,
  ) async {
    await monterCompte(tester, depart: _ficheAicha, eleves: DonneesDemo.eleves);
    final Finder bloc = find.byKey(FicheElevePage.soldeKey);
    await tester.ensureVisible(bloc);
    expect(
      find.descendant(
        of: bloc,
        matching: find.text(t.finance.soldes.indisponible),
      ),
      findsOneWidget,
    );
    expect(find.byKey(FicheElevePage.voirMouvementsKey), findsNothing);
    expect(find.byType(ResumeSolde), findsNothing);
    expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    expect(find.textContaining('0,00'), findsNothing);
    for (final String interdit in <String>['Recharger', 'Payer', 'Acheter']) {
      expect(find.textContaining(interdit), findsNothing, reason: interdit);
    }
  });
}
