// CPT-DIR-1 : `FinanceDelegationPolicyPanel` (spec §21.2, §37 ; R-FIN-09).
//
// - pouvoirs, plafonds, secondes validations, delai « recent » ;
// - un plafond vide n'en fixe aucun, 10 USD et 1 000 000 USD pareil ;
// - les trois interdits absolus sont en lecture seule, jamais un interrupteur ;
// - echec, saisie illisible, 320 px texte x2, RTL, sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation/finance_delegation_policy_panel.dart';
import 'package:rewayah_academy/features/demo/comptable/direction_demo.dart';

import 'support_direction.dart';

final c = t.comptable.direction;
final d = c.delegationPanneau;

typedef _Appel = ({BrouillonDelegationFinance brouillon, String cle});

class _Hote {
  _Hote(this.politique, {this.echec});

  final PolitiqueDelegationFinance politique;
  Object? echec;
  final List<_Appel> appels = <_Appel>[];

  Widget panneau() => FinanceDelegationPolicyPanel(
    politique: politique,
    onEnregistrer: (BrouillonDelegationFinance b, String cle) async {
      appels.add((brouillon: b, cle: cle));
      final Object? e = echec;
      // ignore: only_throw_errors
      if (e != null) throw e;
    },
  );
}

Finder _champ(String libelle) => find.descendant(
  of: find.byWidgetPredicate(
    (Widget w) => w is Semantics && w.properties.label == libelle,
  ),
  matching: find.byType(TextField),
);

Future<void> _taper(WidgetTester tester, String libelle, String texte) async {
  await tester.ensureVisible(_champ(libelle));
  await tester.enterText(_champ(libelle), texte);
  await tester.pump();
}

Future<void> _basculer(WidgetTester tester, String titre) async {
  final Finder f = find
      .byWidgetPredicate(
        (Widget w) => w is Switch,
        description: 'interrupteur de $titre',
      )
      .at(_ordre.indexOf(titre));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pump();
}

/// L'ordre des interrupteurs dans le panneau.
final List<String> _ordre = <String>[
  d.paiementsStandards,
  d.remboursement,
  d.alimentationReserve,
  d.retraitReserve,
  d.premierPaiement,
  d.coordonnees,
];

Future<void> _appuyer(WidgetTester tester) async {
  final Finder bouton = find.descendant(
    of: find.byKey(FinanceDelegationPolicyPanel.enregistrerKey),
    matching: find.text(c.enregistrer),
  );
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  final PolitiqueDelegationFinance standard = DelegationFinanceDemo.standard;

  testWidgets('la delegation en vigueur est reprise, rien a enregistrer', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(standard);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNWidgets(6));
    expect(
      tester.widget<TextField>(_champ(d.plafondTransaction)).controller!.text,
      '500',
    );
    expect(
      tester.widget<TextField>(_champ(d.plafondLot)).controller!.text,
      '2000',
    );
    expect(
      tester.widget<TextField>(_champ(d.plafondPeriode)).controller!.text,
      '5000',
    );
    expect(
      tester.widget<TextField>(_champ(d.joursRecents)).controller!.text,
      '14',
    );
    expect(find.text(c.aucuneModification), findsOneWidget);
    expect(h.appels, isEmpty);
  });

  testWidgets('les trois interdits absolus sont en lecture seule', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(standard);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    for (final String titre in <String>[
      d.autoPayout,
      d.montantManuel,
      d.politiqueTarifaire,
    ]) {
      expect(find.text(titre), findsOneWidget, reason: titre);
    }
    // Six interrupteurs seulement : les interdits n'en ont pas.
    expect(find.byType(Switch), findsNWidgets(6));
    // Rien dans le brouillon ne porte les interdits : le port les rend vrais.
    await _basculer(tester, d.paiementsStandards);
    await _appuyer(tester);
    expect(h.appels, hasLength(1));
  });

  testWidgets('R-FIN-09 : un plafond vide n en fixe aucun ; 10 USD et '
      '1 000 000 USD s enregistrent pareil', (WidgetTester tester) async {
    taille(tester, const Size(900, 4000));
    for (final (String, int?) cas in <(String, int?)>[
      ('10', 1000),
      ('1000000', 100000000),
      ('', null),
    ]) {
      final _Hote h = _Hote(standard);
      await tester.pumpWidget(hoteDirection(h.panneau()));
      await tester.pumpAndSettle();
      await _taper(tester, d.plafondTransaction, cas.$1);
      await _taper(tester, d.plafondLot, '');
      await _taper(tester, d.plafondPeriode, '');
      await _appuyer(tester);
      final BrouillonDelegationFinance b = h.appels.single.brouillon;
      expect(
        b.plafondParTransaction,
        cas.$2 == null ? isNull : Montant(cas.$2!, 'USD'),
        reason: '"${cas.$1}"',
      );
      expect(b.plafondParLot, isNull);
      expect(b.plafondParPeriode, isNull);
    }
  });

  testWidgets('chaque pouvoir et chaque seconde validation se regle', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(standard);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();

    for (final String titre in _ordre) {
      await _basculer(tester, titre);
    }
    // Les coordonnees ne sont plus soumises : le delai disparait.
    expect(find.text(d.joursRecents), findsNothing);
    await _appuyer(tester);

    final BrouillonDelegationFinance b = h.appels.single.brouillon;
    expect(b.paiementsStandardsAutorises, isFalse);
    expect(b.remboursementStandardAutorise, isFalse);
    expect(b.alimentationReserveAutorisee, isFalse);
    expect(b.retraitReserveInterdit, isFalse);
    expect(b.premierPaiementSecondeValidation, isFalse);
    expect(b.coordonneesRecentesSecondeValidation, isFalse);
    expect(b.joursCoordonneesRecentes, isNull);
    // Les plafonds, eux, restent ceux de la version en vigueur.
    expect(b.plafondParTransaction, standard.plafondParTransaction);
  });

  testWidgets('delai « recent » : un entier positif, sinon l erreur le dit', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(standard);
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();
    await _taper(tester, d.joursRecents, '0');
    await _taper(tester, d.plafondLot, '0');
    await _appuyer(tester);
    expect(h.appels, isEmpty);
    expect(find.text(c.erreurNombre), findsOneWidget);
    expect(find.text(c.erreurMontant), findsOneWidget);
    expect(find.text(c.corrigezChamps), findsOneWidget);

    await _taper(tester, d.joursRecents, '30');
    await _taper(tester, d.plafondLot, '2500');
    await _appuyer(tester);
    final BrouillonDelegationFinance b = h.appels.single.brouillon;
    expect(b.joursCoordonneesRecentes, 30);
    expect(b.plafondParLot, const Montant(250000, 'USD'));
  });

  testWidgets('echec : la phrase reste, la meme cle est reprise', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(900, 4000));
    final _Hote h = _Hote(standard, echec: Exception('coupure'));
    await tester.pumpWidget(hoteDirection(h.panneau()));
    await tester.pumpAndSettle();
    await _taper(tester, d.plafondTransaction, '750');
    await _appuyer(tester);
    expect(find.text(c.erreurEnregistrement), findsOneWidget);
    await _appuyer(tester);
    expect(h.appels, hasLength(2));
    expect(h.appels[1].cle, h.appels[0].cle);
    expect(
      h.appels[1].brouillon.plafondParTransaction,
      const Montant(75000, 'USD'),
    );
  });

  for (final (String, double, TextDirection, Brightness) cas
      in <(String, double, TextDirection, Brightness)>[
        ('320 px, texte x2', 2, TextDirection.ltr, Brightness.light),
        ('RTL', 1, TextDirection.rtl, Brightness.light),
        ('sombre', 1, TextDirection.ltr, Brightness.dark),
      ]) {
    testWidgets('mise en page : ${cas.$1}, sans debordement', (
      WidgetTester tester,
    ) async {
      taille(tester, cas.$2 == 2 ? const Size(320, 900) : const Size(390, 900));
      final _Hote h = _Hote(standard);
      await tester.pumpWidget(
        hoteDirection(
          h.panneau(),
          echelle: cas.$2,
          sens: cas.$3,
          luminosite: cas.$4,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(d.pouvoirsTitre), findsOneWidget);
    });
  }
}
