// FI-3a (guide Finance V4 §5.2-5.4, §7, §11.3) : le montant et les lignes
// d'argent, habits de `LigneCleValeur`.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';
import 'package:rewayah_academy/core/widgets/ligne_allocation.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/ligne_finance.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/core/widgets/montant_argent.dart';

import '../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  double largeur = 390,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: Directionality(
            textDirection: sens,
            child: Material(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: enfant,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const Widget _decomposition = Column(
  children: <Widget>[
    LigneFinance(libelle: 'Tarif enfant', montant: Montant(5000, 'USD')),
    LigneFinance(
      libelle: 'Remise familiale',
      detail: '3e membre',
      montant: Montant(-500, 'USD'),
    ),
    LigneFinance(
      libelle: 'Total a financer',
      montant: Montant(4500, 'USD'),
      total: true,
    ),
    LigneTransaction(
      libelle: 'Recharge',
      date: '1er octobre',
      montant: Montant(14500, 'USD'),
    ),
    LigneAllocation(
      prenom: 'Mariam',
      detail: 'Octobre',
      montant: Montant(5000, 'USD'),
      avatar: BandeauProfil(
        avatar: AvatarTile(prenom: 'Mariam', diametre: AppAvatar.moyen),
        diametre: AppAvatar.moyen,
        accent: AccentProfil.rose,
      ),
    ),
  ],
);

void main() {
  testWidgets('MontantArgent : texte du formateur, chiffres tabulaires', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const MontantArgent(Montant(-500, 'USD'), signe: true),
    );
    final Text texte = tester.widget<Text>(find.byType(Text));
    expect(texte.data, formaterMontant(const Montant(-500, 'USD')));
    expect(
      texte.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('les lignes ecrivent le montant du formateur, une transaction '
      'toujours signee', (WidgetTester tester) async {
    await _monter(tester, _decomposition);
    expect(
      find.text(formaterMontant(const Montant(-500, 'USD'))),
      findsOneWidget,
    );
    expect(
      find.text(formaterMontant(const Montant(14500, 'USD'), signe: true)),
      findsOneWidget,
    );
    expect(find.text('3e membre'), findsOneWidget);
    expect(find.text('1er octobre'), findsOneWidget);
    // Toutes les lignes sont des LigneCleValeur : aucune recopie.
    expect(find.byType(LigneCleValeur), findsNWidgets(5));
  });

  testWidgets('chaque ligne se lit en un seul noeud : la cle puis le montant', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await _monter(tester, _decomposition);
    final SemanticsNode noeud = tester.getSemantics(
      find.ancestor(
        of: find.text('Remise familiale'),
        matching: find.byType(MergeSemantics),
      ),
    );
    expect(noeud.label, contains('Remise familiale'));
    expect(noeud.label, contains('3e membre'));
    expect(noeud.label, contains(formaterMontant(const Montant(-500, 'USD'))));
    h.dispose();
  });

  testWidgets('le total est au rang d un titre de carte', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _decomposition);
    final BuildContext ctx = tester.element(find.byType(LigneFinance).last);
    final Text total = tester.widget<Text>(
      find.text(formaterMontant(const Montant(4500, 'USD'))),
    );
    expect(
      total.style!.fontSize,
      Theme.of(ctx).textTheme.titleMedium!.fontSize,
    );
  });

  testWidgets('l allocation pose l avatar du profil en tete', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _decomposition);
    final Rect avatar = tester.getRect(find.byType(BandeauProfil));
    final Rect prenom = tester.getRect(find.text('Mariam'));
    expect(avatar.left, lessThan(prenom.left));
  });

  for (final (double, double) cas in const <(double, double)>[
    (320, 1),
    (320, 2),
    (1440, 1),
    (1440, 2),
  ]) {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
          '${sens.name} : aucun debordement', (WidgetTester tester) async {
        await _monter(
          tester,
          _decomposition,
          largeur: cas.$1,
          echelle: cas.$2,
          sens: sens,
        );
        expect(tester.takeException(), isNull);
        // A 200 %, la cle et le montant s'empilent : le montant passe sous
        // son libelle, jamais coupe.
        final Rect cle = tester.getRect(find.text('Tarif enfant'));
        final Rect valeur = tester.getRect(
          find.text(formaterMontant(const Montant(5000, 'USD'))).first,
        );
        if (cas.$2 >= 2) {
          expect(valeur.top, greaterThanOrEqualTo(cle.bottom));
        } else {
          expect(valeur.top, lessThan(cle.bottom));
        }
      });
    }
  }
}
