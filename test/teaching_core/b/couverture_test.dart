import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/couverture_ressource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';

import 'faux/faux_ports_b.dart';

void main() {
  group('Couverture : un repli controle, jamais une grille identique', () {
    test('la meme ressource donne toujours la meme couverture', () {
      final LibraryResource r = ressource(id: 'abc-123');
      final CouvertureRessource a = CouvertureRessource.pour(r);
      final CouvertureRessource b = CouvertureRessource.pour(r);

      expect(a.indexTeinte, b.indexTeinte);
      expect(a.motif, b.motif);
      expect(a.monogramme, b.monogramme);
    });

    test('l empreinte est stable, bornee, et ne depend pas de hashCode', () {
      expect(
        CouvertureRessource.empreinte(''),
        CouvertureRessource.graineEmpreinte,
      );
      expect(
        CouvertureRessource.empreinte('support-1'),
        CouvertureRessource.empreinte('support-1'),
      );
      expect(
        CouvertureRessource.empreinte('support-1'),
        isNot(CouvertureRessource.empreinte('support-2')),
      );

      // Bornee a 32 bits, et surtout : chaque produit intermediaire reste sous
      // les 2^53 entiers exacts d'un nombre JavaScript. Sans cela, le meme
      // support aurait une couverture sur le web et une autre sur mobile.
      for (final String graine in <String>[
        'a',
        'support-tres-long-avec-beaucoup-de-caracteres-0123456789',
        'ص-arabe',
      ]) {
        final int h = CouvertureRessource.empreinte(graine);
        expect(h, greaterThanOrEqualTo(0));
        expect(h, lessThanOrEqualTo(0xffffffff));
      }
    });

    test('les couvertures se repartissent au lieu de se ressembler', () {
      final Set<String> combinaisons = <String>{};
      for (int i = 0; i < 60; i++) {
        final CouvertureRessource c = CouvertureRessource.pour(
          ressource(id: 'ressource-$i'),
        );
        combinaisons.add('${c.indexTeinte}/${c.motif}');
      }

      // 32 teintes ouvertes aux ressources non coraniques, quatre motifs :
      // on veut une repartition reellement employee, pas concentree sur
      // quelques cases.
      expect(combinaisons.length, greaterThanOrEqualTo(10));
    });

    test('le Coran garde sa teinte reservee, les autres ne la prennent pas', () {
      expect(
        CouvertureRessource.pour(
          ressource(id: 'coran', type: TypeRessource.quran),
        ).indexTeinte,
        0,
      );
      for (int i = 0; i < 40; i++) {
        expect(
          CouvertureRessource.pour(ressource(id: 'x$i')).indexTeinte,
          greaterThan(0),
        );
      }
    });

    test('le monogramme prend deux initiales, jamais la ponctuation', () {
      expect(
        CouvertureRessource.pour(
          ressource(id: 'r1', titreCourt: 'Meem sakinah'),
        ).monogramme,
        'MS',
      );
      expect(
        CouvertureRessource.pour(
          ressource(id: 'r1', titreCourt: '"Alphabet"'),
        ).monogramme,
        'A',
      );
    });

    test('un titre court vide se replie sur le titre long', () {
      expect(
        CouvertureRessource.pour(
          ressource(id: 'r1', titreCourt: '', titre: 'Le grand livre'),
        ).monogramme,
        'LG',
      );
    });

    test('une ressource sans aucun titre garde une vignette distincte', () {
      final CouvertureRessource a = CouvertureRessource.pour(
        ressource(id: 'ab12', titre: '', titreCourt: ''),
      );
      final CouvertureRessource b = CouvertureRessource.pour(
        ressource(id: 'cd34', titre: '', titreCourt: ''),
      );

      expect(a.monogramme, 'AB');
      expect(b.monogramme, 'CD');
      expect(a.monogramme, isNot(b.monogramme));
    });

    test('une couverture deposee est signalee comme telle', () {
      expect(
        CouvertureRessource.pour(ressource(id: 'r1')).calculee,
        isTrue,
      );
      expect(
        CouvertureRessource.pour(
          ressource(id: 'r1', couverture: 'supports/r1.png'),
        ).calculee,
        isFalse,
      );
    });
  });
}
