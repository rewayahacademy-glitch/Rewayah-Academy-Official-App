// Detail d'un paiement (LT-12) : sur le VRAI routeur et la coquille du
// tuteur, une ligne de la liste TOUCHEE mene au detail, le retour ramene a la
// liste (390 et 1440) ; un statut inconnu n'est jamais affiche brut ; en
// production (DB-CPT-03) l'adresse directe du detail dit l'indisponibilite.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

final List<Override> _faux = <Override>[
  portPaiementsFoyerProvider.overrideWithValue(FauxPaiements()),
];

String _ligne(PaiementFoyer p) =>
    t.compte.tuteur.pagePaiements.paiementDu(date: dateLongue(p.date));

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('${taille.width.toInt()} : liste -> ligne touchee -> detail '
        '-> retour', (WidgetTester tester) async {
      final GoRouter routeur = await monterCompte(
        tester,
        depart: Routes.tuteurComptePaiements,
        taille: taille,
        surcharges: _faux,
      );
      expect(find.byType(PaiementsComptePage), findsOneWidget);
      final PaiementFoyer regle = paiementsFictifs.first;

      await toucher(tester, find.text(_ligne(regle)));
      expect(Uri.parse(lieu(routeur)).path, Routes.paiementPour(regle.id));
      expect(find.byType(DetailPaiementPage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
      expect(find.text(formaterMontant(123450, 'EUR')), findsOneWidget);
      expect(find.text(dateLongue(regle.date)), findsOneWidget);
      expect(
        find.text(t.compte.tuteur.pagePaiements.statuts.regle),
        findsOneWidget,
      );
      // Aucun moyen de telecharger le justificatif : aucun bouton.
      expect(find.textContaining('Télécharger'), findsNothing);

      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurComptePaiements);
      expect(find.byType(PaiementsComptePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('un statut inconnu se dit en phrase neutre, jamais brut', (
    WidgetTester tester,
  ) async {
    await monterCompte(
      tester,
      depart: Routes.tuteurComptePaiements,
      surcharges: _faux,
    );
    await toucher(tester, find.text(_ligne(paiementsFictifs.last)));
    expect(find.byType(DetailPaiementPage), findsOneWidget);
    expect(
      find.text(t.compte.tuteur.pagePaiements.statuts.inconnu),
      findsOneWidget,
    );
    expect(find.textContaining('brut'), findsNothing);
    expect(find.textContaining('payment_status'), findsNothing);
  });

  testWidgets('identifiant inconnu : introuvable', (WidgetTester tester) async {
    await monterCompte(
      tester,
      depart: Routes.paiementPour('absent'),
      surcharges: _faux,
    );
    expect(
      find.text(t.compte.tuteur.pagePaiements.detail.introuvable),
      findsOneWidget,
    );
  });

  testWidgets('production : liste sans ligne, detail en adresse directe '
      'indisponible, sans Reessayer', (WidgetTester tester) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: Routes.tuteurComptePaiements,
    );
    expect(
      find.text(t.compte.tuteur.pagePaiements.indisponibleTitre),
      findsOneWidget,
    );
    expect(find.textContaining('Paiement du'), findsNothing);

    routeur.go(Routes.paiementPour('p1'));
    await stabiliser(tester);
    expect(find.byType(DetailPaiementPage), findsOneWidget);
    expect(
      find.text(t.compte.tuteur.pagePaiements.indisponibleTitre),
      findsOneWidget,
    );
    expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
    expect(find.textContaining('EUR'), findsNothing);
  });

  testWidgets('?retour= est filtre : un retour externe est ignore', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterCompte(
      tester,
      depart: '${Routes.paiementPour('p-regle')}?retour=//exemple.test',
      surcharges: _faux,
    );
    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.tuteurComptePaiements);
  });
}
