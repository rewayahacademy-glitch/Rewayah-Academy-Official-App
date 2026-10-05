// CPT-DIR-2, Q-9 = a (decide par delegation le 05/10) : quand le Comptable
// masque les montants, les pourcentages derives d'un montant sont masques de
// la meme maniere (meme point, longueur fixe, lecteur d'ecran « Montant
// masque »), et la jauge ne dit plus la part atteinte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/comptable/carte_reserve_strategique.dart';
import 'package:rewayah_academy/core/widgets/comptable/pourcentage_sensible.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';

import '../../../support/harnais.dart';

IndicateursReserve _indicateurs(int pourMille) => IndicateursReserve(
  mode: ModeObjectifReserve.montantFixe,
  objectif: const Montant(900000, 'USD'),
  actuel: const Montant(740000, 'USD'),
  manque: const Montant(160000, 'USD'),
  atteintPourMille: pourMille,
  etat: EtatReserve.sousObjectif,
);

class _Visibilite extends VisibiliteMontants {
  _Visibilite(this._initiale);

  final bool _initiale;

  @override
  bool build() => _initiale;
}

Future<void> _monter(
  WidgetTester tester, {
  required int pourMille,
  required bool affiches,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: CarteReserveStrategique(_indicateurs(pourMille)),
        ),
      ),
      surcharges: <Override>[
        visibiliteMontantsProvider.overrideWith(() => _Visibilite(affiches)),
      ],
    ),
  );
  await tester.pump();
}

double? _jauge(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value;

void main() {
  final c = t.comptable.commun;

  testWidgets('masques : « •• % atteint », jauge vide, rien du chiffre', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, pourMille: 822, affiches: false);

    expect(find.text(c.atteint(pourcent: 82)), findsNothing);
    expect(
      find.text(c.atteint(pourcent: PourcentageSensible.masque)),
      findsOneWidget,
    );
    // Le meme point que le masque des montants.
    expect(PourcentageSensible.masque, '${MontantSensible.point}' * 2);
    expect(_jauge(tester), 0);
    // Lecteur d'ecran : « Montant masque », comme pour un montant, jamais 82.
    expect(find.bySemanticsLabel(RegExp('82')), findsNothing);
    expect(
      find.bySemanticsLabel(c.montantMasque),
      findsAtLeastNWidgets(2 + 3), // jauge, pourcentage, trois montants
    );
    semantique.dispose();
  });

  testWidgets('masques : longueur fixe, 8 % et 100 % rendent pareil', (
    WidgetTester tester,
  ) async {
    await _monter(tester, pourMille: 80, affiches: false);
    expect(
      find.text(c.atteint(pourcent: PourcentageSensible.masque)),
      findsOneWidget,
    );
    await _monter(tester, pourMille: 1000, affiches: false);
    expect(
      find.text(c.atteint(pourcent: PourcentageSensible.masque)),
      findsOneWidget,
    );
  });

  testWidgets('affiches : « 82 % atteint », jauge remplie, lue en clair', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, pourMille: 822, affiches: true);

    expect(find.text(c.atteint(pourcent: 82)), findsOneWidget);
    expect(
      find.text(c.atteint(pourcent: PourcentageSensible.masque)),
      findsNothing,
    );
    expect(_jauge(tester), closeTo(0.822, 0.0001));
    expect(find.bySemanticsLabel(c.atteint(pourcent: 82)), findsWidgets);
    semantique.dispose();
  });

  testWidgets('la bascule des montants revele aussi le pourcentage', (
    WidgetTester tester,
  ) async {
    await _monter(tester, pourMille: 822, affiches: false);
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(CarteReserveStrategique)),
    );
    conteneur.read(visibiliteMontantsProvider.notifier).basculer();
    await tester.pump();
    expect(find.text(c.atteint(pourcent: 82)), findsOneWidget);
    expect(_jauge(tester), closeTo(0.822, 0.0001));
  });
}
