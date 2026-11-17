// La garde des echeances de `tool/branchement_tolere.txt` (pilote,
// 11/11/2026) : une echeance depassee fait echouer `verifier_branchement`.

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verifier_branchement.dart';

void main() {
  test(
    'une echeance se lit en JJ/MM/AAAA ; une date impossible est refusee',
    () {
      expect(lireEcheance('08/11/2026'), DateTime(2026, 11, 8));
      expect(lireEcheance('31/02/2026'), isNull);
      expect(lireEcheance('2026-11-08'), isNull);
    },
  );

  test(
    'le jour meme compte encore ; le lendemain, l echeance est depassee',
    () {
      final DateTime echeance = DateTime(2026, 11, 8);
      expect(
        echeanceDepassee(echeance, DateTime(2026, 11, 7, 23, 59)),
        isFalse,
      );
      expect(
        echeanceDepassee(echeance, DateTime(2026, 11, 8, 23, 59)),
        isFalse,
      );
      expect(echeanceDepassee(echeance, DateTime(2026, 11, 9)), isTrue);
      expect(echeanceDepassee(echeance, DateTime(2027, 1, 1)), isTrue);
    },
  );
}
