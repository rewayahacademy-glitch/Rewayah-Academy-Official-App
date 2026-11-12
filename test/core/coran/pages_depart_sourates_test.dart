// SOMMAIRE-SOURATES (directeur, 11/11/2026 : « ne bricolez pas le Coran,
// prenez le standard »). Les pages de depart des sourates ne sont pas ecrites
// a la main : ce test les compare au corpus du depot, celui que la base a
// recu, et refuse tout ecart.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/pages_depart_sourates.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';

import '../../support/corpus_coran_depot.dart';

void main() {
  test('114 pages, de la page 1 a la page 604, jamais en arriere', () {
    expect(pagesDeDepartDesSourates, hasLength(114));
    expect(pagesDeDepartDesSourates.first, 1);
    expect(pagesDeDepartDesSourates.last, pagesMushafMedine);
    for (int i = 1; i < pagesDeDepartDesSourates.length; i++) {
      expect(
        pagesDeDepartDesSourates[i],
        greaterThanOrEqualTo(pagesDeDepartDesSourates[i - 1]),
        reason: 'la sourate ${i + 1} commence avant la sourate $i',
      );
    }
  });

  test('chaque page est celle du corpus du depot (migration 0013)', () {
    final Map<int, int> corpus = pagesDeDepartDuCorpus();
    expect(corpus, hasLength(114));
    for (int numero = 1; numero <= 114; numero++) {
      expect(
        pageDeDepartDeLaSourate(numero),
        corpus[numero],
        reason: 'page de depart de la sourate $numero',
      );
    }
  });

  test('hors de 1 a 114 : aucune page', () {
    expect(pageDeDepartDeLaSourate(0), isNull);
    expect(pageDeDepartDeLaSourate(115), isNull);
  });

  test('l edition est toujours celle dont ces pages sont tirees', () {
    // Si l'edition change, ces pages sont a retirer du corpus de la nouvelle.
    expect(codeMushafReference, 'madina-hafs-604');
    expect(pagesMushafMedine, 604);
  });
}
