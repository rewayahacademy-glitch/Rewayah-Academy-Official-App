// PT-B-CORAN-ADULTE : le corpus de la demonstration recopie la migration
// 0013 MOT POUR MOT. Un texte du Coran ne se modifie jamais (licence Tanzil,
// et le bon sens avant elle) : chaque verset, chaque sourate, chaque juz et
// chaque page de `corpus_demo_coran_donnees.dart` est compare ici a la
// migration, la source que la base importe. Un ecart d'un seul caractere
// fait echouer ce test.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/features/demo/service_coran_demo.dart';

/// La migration, lue telle quelle.
final String _migration = File('supabase/migrations/0013_corpus_coranique.sql')
    .readAsStringSync();

/// Les lignes `(a, b, ...)` d'un bloc `insert` de la migration.
Iterable<RegExpMatch> _lignes(String motif) =>
    RegExp(motif, multiLine: true).allMatches(_migration);

String _sql(String brut) => brut.replaceAll("''", "'");

void main() {
  const ServiceCoran demo = ServiceCoranDemo();

  test('les 6236 versets : texte, sourate, numero et page identiques a la '
      'migration, dans l\'ordre du texte', () async {
    final List<RegExpMatch> attendus = _lignes(
      r"^  \((\d+), (\d+), '((?:[^']|'')*)', (\d+)\),?$",
    ).where((RegExpMatch m) => m.group(3)!.isNotEmpty).toList();
    // Les lignes de sourates ont aussi 4 champs dont un texte : on ne garde
    // que celles du bloc des versets.
    final int debutVersets = _migration.indexOf('insert into public.verset');
    final List<RegExpMatch> versets = attendus
        .where((RegExpMatch m) => m.start > debutVersets)
        .toList();
    expect(versets, hasLength(6236));

    final Map<int, List<VersetCoran>> parPage = <int, List<VersetCoran>>{};
    for (int page = 1; page <= pagesMushafMedine; page++) {
      final PageCoran? lue = await demo.page(page);
      parPage[page] = lue!.versets;
      expect(lue.versets, isNotEmpty, reason: 'page $page vide');
    }
    final List<VersetCoran> rendus = <VersetCoran>[
      for (int page = 1; page <= pagesMushafMedine; page++) ...parPage[page]!,
    ];
    expect(rendus, hasLength(6236));

    for (int i = 0; i < versets.length; i++) {
      final RegExpMatch m = versets[i];
      final VersetCoran v = rendus[i];
      final String reference = '${m.group(1)}:${m.group(2)}';
      expect(v.reference, reference);
      expect(v.texte, _sql(m.group(3)!), reason: reference);
      expect(v.pageNumero, int.parse(m.group(4)!), reason: reference);
      expect(
        await demo.pageDe(v.sourateNumero, v.numero),
        v.pageNumero,
        reason: reference,
      );
    }
  });

  test('les 114 sourates, identiques a la migration', () async {
    final List<RegExpMatch> attendues = _lignes(
      r"^  \((\d+), '((?:[^']|'')*)', '((?:[^']|'')*)', '(mecque|medine)', "
      r'(\d+)\),?$',
    ).toList();
    expect(attendues, hasLength(114));
    final List<Sourate> rendues = (await demo.sourates())!;
    expect(rendues, hasLength(114));
    for (int i = 0; i < 114; i++) {
      final RegExpMatch m = attendues[i];
      final Sourate s = rendues[i];
      expect(s.numero, int.parse(m.group(1)!));
      expect(s.nomArabe, _sql(m.group(2)!));
      expect(s.nomTranslittere, _sql(m.group(3)!));
      expect(s.lieuRevelation, m.group(4));
      expect(s.nombreVersets, int.parse(m.group(5)!));
    }
  });

  test('les 30 juz et le juz de chacune des 604 pages', () async {
    final String blocJuz = _migration.substring(
      _migration.indexOf('insert into public.juz'),
      _migration.indexOf('insert into public.page_mushaf'),
    );
    final List<RegExpMatch> juz = RegExp(
      r'^  \((\d+), (\d+), (\d+)\)',
      multiLine: true,
    ).allMatches(blocJuz).toList();
    expect(juz, hasLength(30));
    for (final RegExpMatch m in juz) {
      expect(await demo.debutDeJuz(int.parse(m.group(1)!)), (
        sourate: int.parse(m.group(2)!),
        verset: int.parse(m.group(3)!),
      ));
    }

    final String blocPages = _migration.substring(
      _migration.indexOf('insert into public.page_mushaf'),
      _migration.indexOf('insert into public.verset'),
    );
    final List<RegExpMatch> pages = RegExp(
      r'^  \((\d+), (\d+)\)',
      multiLine: true,
    ).allMatches(blocPages).toList();
    expect(pages, hasLength(pagesMushafMedine));
    for (final RegExpMatch m in pages) {
      final PageCoran? page = await demo.page(int.parse(m.group(1)!));
      expect(page!.juzNumero, int.parse(m.group(2)!));
    }
  });

  test('aucune position lue ni ecrite ; hors edition, aucune page', () async {
    expect(await demo.position('eleve'), isNull);
    expect(
      await demo.enregistrerPosition(
        'eleve',
        const PositionLecture(page: 3, sourate: 2, verset: 10),
      ),
      isFalse,
    );
    expect((await demo.page(605))!.versets, isEmpty);
    expect(await demo.pageDe(1, 8), isNull);
  });

  test('l\'adaptateur reel au-dessus du service : references, juz et noms de '
      'sourate se resolvent comme sur la base', () async {
    final CorpusDepuisServiceCoran corpus = CorpusDepuisServiceCoran(demo);
    final List<ResultatRechercheCoran> reference = await corpus.rechercher(
      '2:255',
    );
    expect(reference.single.page, 42);
    final List<ResultatRechercheCoran> juz = await corpus.rechercher('juz 30');
    expect(juz.single.page, 582);
    expect(await corpus.pageDeDebutDeSourate(18), 293);
  });
}
