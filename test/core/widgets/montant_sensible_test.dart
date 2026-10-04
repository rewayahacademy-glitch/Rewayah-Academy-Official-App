// CPT-F : `MontantSensible` (SensitiveAmount, spec Finance operationnelle
// §7.1, §46 ; DR-06) et `BasculeMontants` (§7.2). R-FIN-01 : masque a
// l'entree ; R-FIN-02 : affiche apres « Afficher les montants » ; masque de
// longueur fixe quelle que soit la valeur ; lu « Montant masque ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/core/widgets/montant_argent.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

const Montant _dix = Montant(1000, 'USD');
const Montant _million = Montant(100000000, 'USD');
const Montant _gnf = Montant(250000, 'GNF');

Future<void> _monter(WidgetTester tester, Widget enfant) async {
  await tester.pumpWidget(
    hote(
      Material(
        child: Padding(padding: const EdgeInsets.all(16), child: enfant),
      ),
      surcharges: surchargesRouteur(FausseSourceSession()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('le masque a une longueur fixe par devise (DR-06)', () {
    expect(
      MontantSensible.masquePour('USD'),
      MontantSensible.masquePour('EUR').replaceAll('€', r'$'),
    );
    expect(MontantSensible.masquePour('USD'), contains(','));
    expect(MontantSensible.masquePour('GNF'), isNot(contains(',')));
    // Le masque ne contient aucun chiffre.
    expect(MontantSensible.masquePour('USD'), isNot(matches(RegExp(r'\d'))));
  });

  testWidgets('R-FIN-01 : a l entree, masque, meme longueur pour 10 et '
      '1 000 000 USD, lu « Montant masque »', (WidgetTester tester) async {
    await _monter(
      tester,
      const Column(
        children: <Widget>[
          MontantSensible(_dix),
          MontantSensible(_million),
          MontantSensible(_gnf, taille: TailleMontant.grand),
        ],
      ),
    );
    expect(find.text(formaterMontant(_dix)), findsNothing);
    expect(find.text(formaterMontant(_million)), findsNothing);
    expect(find.text(MontantSensible.masquePour('USD')), findsNWidgets(2));
    expect(find.text(MontantSensible.masquePour('GNF')), findsOneWidget);
    expect(find.byType(MontantArgent), findsNothing);
    expect(
      find.bySemanticsLabel(t.comptable.commun.montantMasque),
      findsNWidgets(3),
    );
  });

  testWidgets('R-FIN-02 : apres « Afficher les montants », les montants '
      'exacts apparaissent, puis se remasquent', (WidgetTester tester) async {
    await _monter(
      tester,
      const Column(
        children: <Widget>[
          BasculeMontants(avecEtat: true),
          MontantSensible(_dix),
          MontantSensible(_million),
        ],
      ),
    );
    expect(find.text(t.comptable.commun.montantsMasques), findsOneWidget);
    expect(
      find.bySemanticsLabel(t.comptable.commun.afficherMontants),
      findsOneWidget,
    );

    await tester.tap(find.byKey(BasculeMontants.cleBouton));
    await tester.pumpAndSettle();

    expect(find.text(formaterMontant(_dix)), findsOneWidget);
    expect(find.text(formaterMontant(_million)), findsOneWidget);
    expect(find.text(t.comptable.commun.montantsAffiches), findsOneWidget);
    expect(
      find.bySemanticsLabel(t.comptable.commun.masquerMontants),
      findsOneWidget,
    );
    expect(find.text(MontantSensible.masquePour('USD')), findsNothing);

    await tester.tap(find.byKey(BasculeMontants.cleBouton));
    await tester.pumpAndSettle();
    expect(find.text(MontantSensible.masquePour('USD')), findsNWidgets(2));
  });

  testWidgets('un seul etat pour toute la surface : la bascule agit sur '
      'tous les montants a la fois', (WidgetTester tester) async {
    await _monter(
      tester,
      Column(
        children: <Widget>[
          const MontantSensible(_dix),
          const MontantSensible(_gnf),
          Consumer(
            builder: (BuildContext _, WidgetRef ref, Widget? _) =>
                Text(ref.watch(visibiliteMontantsProvider) ? 'ON' : 'OFF'),
          ),
        ],
      ),
    );
    expect(find.text('OFF'), findsOneWidget);
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(Material).first),
    );
    conteneur.read(visibiliteMontantsProvider.notifier).afficher();
    await tester.pumpAndSettle();
    expect(find.text('ON'), findsOneWidget);
    expect(find.text(formaterMontant(_dix)), findsOneWidget);
    expect(find.text(formaterMontant(_gnf)), findsOneWidget);
    // La session reste la meme : rien ne se remasque tout seul.
    conteneur.read(sessionProvider);
    await tester.pumpAndSettle();
    expect(find.text('ON'), findsOneWidget);
  });
}
