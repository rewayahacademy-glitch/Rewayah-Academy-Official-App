import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

Matcher _manque(String code) => throwsA(
  isA<CapaciteIndisponible>().having(
    (CapaciteIndisponible e) => e.dependance,
    'dependance',
    code,
  ),
);

void main() {
  group('FinanceFoyerIndisponible', () {
    const FinanceFoyerIndisponible port = FinanceFoyerIndisponible();

    test('chaque methode echoue avec son code DB-FIN', () async {
      await expectLater(port.soldes(), _manque('DB-FIN-01'));
      await expectLater(port.mouvements(), _manque('DB-FIN-02'));
      await expectLater(port.mouvement('x'), _manque('DB-FIN-02'));
      await expectLater(
        port.offresRecharge(const <String>['x']),
        _manque('DB-FIN-03'),
      );
      await expectLater(
        port.devisRecharge(const <ChoixRecharge>[
          ChoixRecharge(profilId: 'x', offreId: 'o'),
        ]),
        _manque('DB-FIN-03'),
      );
      await expectLater(
        port.payer(referenceDevis: 'd', cleIdempotence: 'k'),
        _manque('DB-FIN-04'),
      );
      await expectLater(
        port.apercuAnnulation(const <String>['x']),
        _manque('DB-FIN-05'),
      );
      await expectLater(
        port.annulerAcces(
          referenceApercu: 'a',
          profilIds: const <String>['x'],
          cleIdempotence: 'k',
        ),
        _manque('DB-FIN-06'),
      );
    });
  });

  group('provider', () {
    test('par defaut, hors demonstration : l indisponible, pas la demo', () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final PortFinanceFoyer port = c.read(portFinanceFoyerProvider);
      expect(port, isA<FinanceFoyerIndisponible>());
      expect(port, isNot(isA<FinanceFoyerDemo>()));
    });

    test('en demonstration : la demo', () {
      final ProviderContainer c = ProviderContainer(
        overrides: surchargesDemoTuteur(environnement: 'developpement'),
      );
      addTearDown(c.dispose);
      expect(c.read(portFinanceFoyerProvider), isA<FinanceFoyerDemo>());
    });
  });

  group('FinanceFoyerDemo', () {
    const FinanceFoyerDemo demo = FinanceFoyerDemo();
    final List<String> ids = <String>[
      for (final EleveDuFoyer e in DonneesDemo.eleves) e.id,
    ];

    test('un solde fictif pour chaque eleve de demo', () async {
      final SoldesFoyer s = await demo.soldes();
      expect(s.complet, isTrue);
      for (final String id in ids) {
        final SoldeProfil p = s.profils.singleWhere(
          (SoldeProfil p) => p.profilId == id,
        );
        expect(p.montantMineur, isNotNull);
        expect(p.devise, 'XTS');
        expect(p.derniereRemise?.seanceId, isNotNull);
      }
    });

    test('mouvements, offres et apercu pour chaque eleve', () async {
      for (final String id in ids) {
        final List<MouvementSolde> m = await demo.mouvements(profilId: id);
        expect(m, isNotEmpty);
        expect(m.every((MouvementSolde x) => x.profilId == id), isTrue);
        expect(await demo.mouvement(m.first.id), isNotNull);
      }
      expect(await demo.offresRecharge(ids), hasLength(ids.length));
      final ApercuAnnulation a = await demo.apercuAnnulation(ids);
      expect(a.profils.every((ConsequencesAnnulation c) => c.eligible), isTrue);
    });

    test('devis, paiement et annulation restent indisponibles', () async {
      await expectLater(
        demo.devisRecharge(const <ChoixRecharge>[]),
        _manque('DB-FIN-03'),
      );
      await expectLater(
        demo.payer(referenceDevis: 'd', cleIdempotence: 'k'),
        _manque('DB-FIN-04'),
      );
      await expectLater(
        demo.annulerAcces(
          referenceApercu: 'a',
          profilIds: ids,
          cleIdempotence: 'k',
        ),
        _manque('DB-FIN-06'),
      );
    });
  });
}
