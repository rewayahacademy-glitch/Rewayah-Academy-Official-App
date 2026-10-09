// CPT-CTR-1 : la lecture d'un montant saisi (entier en unites mineures, sans
// flottant) et les quatre zones de W06.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_contractuels.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/features/comptable/contractuels/contractuels_commun.dart';
import 'package:rewayah_academy/features/demo/comptable/contractuels_demo.dart';

void main() {
  group('lireMontantSaisi', () {
    test('un entier en dollars devient des centimes', () {
      expect(lireMontantSaisi('350', 'USD'), 35000);
    });
    test('la virgule et le point sont acceptes, avec ou sans espaces', () {
      expect(lireMontantSaisi('350,50', 'USD'), 35050);
      expect(lireMontantSaisi('350.5', 'USD'), 35050);
      expect(lireMontantSaisi(' 1 250,05 ', 'USD'), 125005);
      expect(lireMontantSaisi('1 250', 'USD'), 125000);
    });
    test('aucun flottant : un grand montant reste exact', () {
      expect(lireMontantSaisi('90071992547409,93', 'USD'), 9007199254740993);
    });
    test('une devise sans decimales refuse la fraction', () {
      expect(lireMontantSaisi('5000', 'GNF'), 5000);
      expect(lireMontantSaisi('5000,5', 'GNF'), isNull);
    });
    test(
      'refuse le vide, zero, le negatif, les lettres, trop de decimales',
      () {
        expect(lireMontantSaisi('', 'USD'), isNull);
        expect(lireMontantSaisi('0', 'USD'), isNull);
        expect(lireMontantSaisi('0,00', 'USD'), isNull);
        expect(lireMontantSaisi('-5', 'USD'), isNull);
        expect(lireMontantSaisi('abc', 'USD'), isNull);
        expect(lireMontantSaisi('12,345', 'USD'), isNull);
        expect(lireMontantSaisi('1,2,3', 'USD'), isNull);
      },
    );
  });

  group('OngletContractuels', () {
    test('une valeur inconnue ou absente ouvre Obligations', () {
      expect(OngletContractuels.depuis(null), OngletContractuels.obligations);
      expect(OngletContractuels.depuis('?'), OngletContractuels.obligations);
      expect(OngletContractuels.depuis('a-payer'), OngletContractuels.aPayer);
    });

    test('chaque etat appartient a la bonne zone', () async {
      final List<ObligationContractuel> toutes =
          await ObligationsContractuelsDemo().liste(
            FiltreObligationsContractuels.tout,
          );
      for (final ObligationContractuel o in toutes) {
        final Set<OngletContractuels> zones = OngletContractuels.values
            .where((OngletContractuels z) => z.contient(o))
            .toSet();
        switch (o.etat) {
          case EtatObligationContractuel.aApprouver:
            expect(zones, <OngletContractuels>{
              OngletContractuels.obligations,
              OngletContractuels.aApprouver,
            });
          case EtatObligationContractuel.approuvee:
            expect(zones, <OngletContractuels>{
              OngletContractuels.obligations,
              OngletContractuels.aPayer,
            });
          case EtatObligationContractuel.brouillon:
            expect(zones, <OngletContractuels>{OngletContractuels.obligations});
          case EtatObligationContractuel.payee:
          case EtatObligationContractuel.refusee:
          case EtatObligationContractuel.annulee:
            expect(zones, <OngletContractuels>{OngletContractuels.historique});
        }
      }
    });
  });
}
