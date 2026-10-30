// TRANSPARENCE (30/10/2026) : « Nos prix, en toute transparence ».
// La repartition vient du port (jamais ecrite dans l'ecran), en
// pourcentages seulement ; les cinq etats ; le lien depuis le Foyer ; deux
// captures (390 et 1366) quand CAPTURE_DIR est donne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politique_famille.dart';
import 'package:rewayah_academy/core/finance/politique_famille.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/nos_prix_page.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/harnais.dart';

class _Port implements PortPolitiqueFamille {
  _Port(this.lire_);

  final Future<PolitiqueFamille> Function() lire_;

  @override
  Future<PolitiqueFamille> lire() => lire_();
}

PolitiqueFamille _sans(PolitiqueFamille p) => PolitiqueFamille(
  version: p.version,
  dateEffet: p.dateEffet,
  tarifEnfant: p.tarifEnfant,
  tarifAdulte: p.tarifAdulte,
  essaiActif: p.essaiActif,
  essaisMax: p.essaisMax,
  remisesParRang: p.remisesParRang,
  railsActifs: p.railsActifs,
);

Future<void> _monter(
  WidgetTester tester,
  PortPolitiqueFamille port, {
  bool horsLigne = false,
}) async {
  await tester.pumpWidget(
    hote(
      NosPrixPage(onRetour: () {}),
      surcharges: <Override>[
        sansPersonneConnectee(),
        portPolitiqueFamilleProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final PolitiqueFamille demo = DonneesFinanceDemo.politiqueFamille;

  test('une part en pour mille se dit au dixieme', () {
    expect(partEnPourcent(470), '47 %');
    expect(partEnPourcent(11), '1,1 %');
    expect(partEnPourcent(1000), '100 %');
  });

  testWidgets('contenu : chaque poste rendu, sa part, le total de 100 %, la '
      'base de calcul et les trois paragraphes', (WidgetTester tester) async {
    await _monter(tester, _Port(() async => demo));
    final RepartitionPaiement r = demo.repartition!;
    for (final PartPoste p in r.postes) {
      expect(find.text(libellePoste(p.poste)), findsOneWidget);
    }
    expect(find.text('47 %'), findsOneWidget);
    expect(find.text('14,9 %'), findsOneWidget);
    expect(find.text(t.argent.transparence.total), findsOneWidget);
    expect(find.text('100 %'), findsOneWidget);
    expect(
      find.text(t.argent.transparence.estimation(enfants: 50, adultes: 50)),
      findsOneWidget,
    );
    expect(find.text(t.argent.transparence.magasinsPhrase), findsOneWidget);
    expect(find.text(t.argent.transparence.taxesPhrase), findsOneWidget);
    expect(find.text(t.argent.transparence.haussePhrase), findsOneWidget);
    expect(find.text(t.argent.transparence.montantsPhrase), findsOneWidget);
    // Aucun montant : ni dollar, ni prix, dans toute la page.
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.textContaining('USD'), findsNothing);
  });

  testWidgets('les parts suivent le port : une autre repartition, d autres '
      'chiffres, sans toucher a l ecran', (WidgetTester tester) async {
    final RepartitionPaiement r = demo.repartition!;
    final PolitiqueFamille autre = PolitiqueFamille(
      version: demo.version,
      dateEffet: demo.dateEffet,
      tarifEnfant: demo.tarifEnfant,
      tarifAdulte: demo.tarifAdulte,
      essaiActif: demo.essaiActif,
      essaisMax: demo.essaisMax,
      remisesParRang: demo.remisesParRang,
      railsActifs: demo.railsActifs,
      repartition: RepartitionPaiement(
        politiqueVersion: r.politiqueVersion,
        dateEffet: r.dateEffet,
        baseElevesEnfants: 30,
        baseElevesAdultes: 70,
        postes: const <PartPoste>[
          (poste: PosteRepartition.enseignant, pourMille: 500),
          (poste: PosteRepartition.benefice, pourMille: 500),
        ],
      ),
    );
    await _monter(tester, _Port(() async => autre));
    expect(find.text('50 %'), findsNWidgets(2));
    expect(find.text('47 %'), findsNothing);
    expect(
      find.text(t.argent.transparence.estimation(enfants: 30, adultes: 70)),
      findsOneWidget,
    );
  });

  testWidgets('chargement : un squelette', (WidgetTester tester) async {
    final Completer<PolitiqueFamille> attente = Completer<PolitiqueFamille>();
    await _monter(tester, _Port(() => attente.future));
    expect(find.byType(Skeleton), findsOneWidget);
    attente.complete(demo);
    await tester.pump();
  });

  testWidgets('vide : aucune repartition publiee', (WidgetTester tester) async {
    await _monter(tester, _Port(() async => _sans(demo)));
    expect(find.text(t.argent.transparence.videTitre), findsOneWidget);
    expect(find.byKey(NosPrixPage.repartitionCle), findsNothing);
  });

  testWidgets('indisponible : la page le dit, sans chiffre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const PolitiqueFamilleIndisponible());
    expect(find.text(t.argent.transparence.indisponibleTitre), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('erreur : Reessayer relit le port', (WidgetTester tester) async {
    int lectures = 0;
    await _monter(
      tester,
      _Port(() async {
        lectures++;
        throw StateError('403');
      }),
    );
    expect(find.text(t.argent.transparence.erreurTitre), findsOneWidget);
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.echecServeur);
    etat.onAction!();
    await tester.pump();
    await tester.pump();
    expect(lectures, 2);
  });

  testWidgets('hors ligne : l etat sans donnees', (WidgetTester tester) async {
    await _monter(
      tester,
      _Port(() async => throw StateError('reseau')),
      horsLigne: true,
    );
    expect(find.text(t.argent.transparence.sansDonnees), findsOneWidget);
  });

  testWidgets('le Foyer porte le lien quand on le lui donne', (
    WidgetTester tester,
  ) async {
    int ouvertures = 0;
    await tester.pumpWidget(
      hote(
        Scaffold(body: VueFinanciereFoyer(onNosPrix: () => ouvertures++)),
        surcharges: <Override>[
          sansPersonneConnectee(),
          portPaiementsFoyerProvider.overrideWithValue(
            const PaiementsFoyerFinanceDemo(JeuFoyerFinance.tousFinances),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text(t.argent.transparence.lien));
    expect(ouvertures, 1);
  });

  group('captures', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', const Size(390, 1900)),
      ('1366', const Size(1366, 1300)),
    ]) {
      testWidgets('capture $nom', (WidgetTester tester) async {
        masquerRubanDebug();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = taille;
        addTearDown(tester.view.reset);
        await _monter(tester, _Port(() async => demo));
        await tester.pumpAndSettle();
        await capturerVue(tester, 'nos-prix-$nom');
      });
    }
  });
}
