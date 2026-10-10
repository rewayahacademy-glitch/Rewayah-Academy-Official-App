// FI-3b (guide Finance V4 §1.6, §1.7, §5.1-5.4, §11.4) : statuts, periode,
// bandeau d'attention, moyen de paiement, synthese du foyer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/badge_periode_financee.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/core/widgets/resume_soldes.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  double largeur = 390,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 1200);
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

const SyntheseFoyer _synthese = SyntheseFoyer(
  totalSoldes: Montant(14500, 'USD'),
  aPayerCeMois: Montant(800, 'USD'),
  profilsFinances: 2,
  profils: 3,
  paiementsDuMois: 2,
);

void main() {
  group('PastilleFinanciere : chaque etat se lit sans la couleur', () {
    test('sept etats, sept mots distincts', () {
      final Set<String> mots = <String>{
        for (final EtatFinancier e in EtatFinancier.values)
          PastilleFinanciere.libelleDe(e),
      };
      expect(mots, hasLength(EtatFinancier.values.length));
      expect(mots.every((String m) => m.trim().isNotEmpty), isTrue);
    });

    test(
      'finance = succes, a regulariser = avertissement, expire = alerte',
      () {
        expect(PastilleFinanciere.tonDe(EtatFinancier.finance), TonEtat.succes);
        expect(
          PastilleFinanciere.tonDe(EtatFinancier.aRegulariser),
          TonEtat.avertissement,
        );
        expect(PastilleFinanciere.tonDe(EtatFinancier.expire), TonEtat.alerte);
      },
    );

    testWidgets('un StatusPill qui porte le mot', (WidgetTester tester) async {
      await _monter(
        tester,
        const PastilleFinanciere(etat: EtatFinancier.aRegulariser),
      );
      expect(find.byType(StatusPill), findsOneWidget);
      expect(find.text(t.argent.etat.aRegulariser), findsOneWidget);
    });
  });

  group('BadgePeriodeFinancee', () {
    testWidgets('dit la date de fin, ou l absence de periode', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        Column(
          children: <Widget>[
            BadgePeriodeFinancee(
              periode: PeriodeFinancee(
                debut: DateTime(2026, 10),
                fin: DateTime(2026, 10, 31, 12),
              ),
            ),
            const BadgePeriodeFinancee(periode: null),
          ],
        ),
      );
      expect(find.textContaining('31'), findsOneWidget);
      expect(find.textContaining(t.commun.dates.mois[9]), findsOneWidget);
      expect(find.text(t.argent.periode.aucune), findsOneWidget);
    });
  });

  group('BandeauAttention : icone, titre et consequence', () {
    testWidgets('titre en en-tete, message, une seule action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _monter(
        tester,
        const BandeauAttention(
          titre: 'Acces a regulariser',
          message: 'Il manque 8 USD pour financer janvier.',
          action: Text('Recharger'),
        ),
      );
      expect(find.byType(Icon), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Acces a regulariser')),
        isSemantics(isHeader: true),
      );
      expect(
        find.text('Il manque 8 USD pour financer janvier.'),
        findsOneWidget,
      );
      expect(find.text('Recharger'), findsOneWidget);
      h.dispose();
    });
  });

  group('LigneMoyenPaiement', () {
    testWidgets('la carte entiere se presse et dit qu elle est retenue', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int presses = 0;
      await _monter(
        tester,
        LigneMoyenPaiement(
          rail: RailPaiement.webStripe,
          retenu: true,
          onPress: () => presses++,
        ),
      );
      // Un appui sur le texte de detail, loin du titre : toute la carte.
      await tester.tap(find.text(t.argent.moyen.webStripeDetail));
      expect(presses, 1);
      expect(find.byType(AppCard), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(LigneMoyenPaiement)),
        isSemantics(isSelected: true),
      );
      h.dispose();
    });

    testWidgets('aucun bouton App Store ou Play : ces rails ne rendent rien', (
      WidgetTester tester,
    ) async {
      for (final RailPaiement rail in <RailPaiement>[
        RailPaiement.iosStoreKit,
        RailPaiement.androidPlay,
      ]) {
        await _monter(tester, LigneMoyenPaiement(rail: rail, onPress: () {}));
        expect(find.byType(AppCard), findsNothing);
        expect(find.byType(Text), findsNothing);
        expect(LigneMoyenPaiement.estMontre(rail), isFalse);
      }
      expect(LigneMoyenPaiement.estMontre(RailPaiement.webStripe), isTrue);
    });
  });

  group('ResumeSoldes', () {
    testWidgets('les chiffres de la source, le total dit en lecture', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const ResumeSoldes(synthese: _synthese));
      expect(find.text(formaterMontant(_synthese.totalSoldes)), findsOneWidget);
      expect(
        find.text(formaterMontant(_synthese.aPayerCeMois)),
        findsOneWidget,
      );
      expect(find.text(t.argent.soldes.totalDetail), findsOneWidget);
      expect(
        find.text(t.argent.soldes.profilsFinancesValeur(n: 2, total: 3)),
        findsOneWidget,
      );
    });
  });

  for (final (double, double) cas in const <(double, double)>[
    (320, 1),
    (320, 2),
    (1440, 2),
  ]) {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
          '${sens.name} : aucun debordement', (WidgetTester tester) async {
        await _monter(
          tester,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: PastilleFinanciere(etat: EtatFinancier.aRegulariser),
              ),
              BadgePeriodeFinancee(
                periode: PeriodeFinancee(
                  debut: DateTime(2026, 10),
                  fin: DateTime(2026, 10, 31),
                ),
              ),
              const BandeauAttention(
                titre: 'Paiement en cours de confirmation',
                message: 'Ne payez pas une seconde fois.',
              ),
              LigneMoyenPaiement(rail: RailPaiement.webStripe, onPress: () {}),
              const ResumeSoldes(synthese: _synthese),
            ],
          ),
          largeur: cas.$1,
          echelle: cas.$2,
          sens: sens,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
