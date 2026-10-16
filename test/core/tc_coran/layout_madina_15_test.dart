// MUSHAF-15L : invariants des donnees de mise en page du Mushaf de Medine
// (604 pages, 15 lignes sauf les pages 1 et 2, 6 236 fins de verset, chaque
// sourate:aya present une fois).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_coran/donnees/layout_madina_15.g.dart';
import 'package:rewayah_academy/core/tc_coran/layout_madina_15.dart';
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';

/// Le nombre de versets de chaque sourate (Kufi, 6 236 au total).
const List<int> _versetsParSourate = <int>[
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

void main() {
  final LayoutMadina15 source = LayoutMadina15();
  final List<LayoutPage> pages = <LayoutPage>[
    for (int p = 1; p <= 604; p++) source.depuis(p)!,
  ];

  test(
    'le recueil des versets est celui du Kufi : 114 sourates, 6 236 versets',
    () {
      expect(_versetsParSourate, hasLength(114));
      expect(_versetsParSourate.fold<int>(0, (int a, int b) => a + b), 6236);
      expect(layoutMadina15NomsSourates, hasLength(114));
    },
  );

  test('604 pages, rien au-dela', () async {
    expect(layoutMadina15Pages, hasLength(604));
    expect(source.depuis(0), isNull);
    expect(source.depuis(605), isNull);
    expect(await source.disponibilite(), DisponibiliteLayout.fidele);
    expect((await source.layoutDe(293))!.numeroPage, 293);
  });

  test('15 lignes par page, sauf les pages 1 et 2 qui en ont 8', () {
    for (final LayoutPage p in pages) {
      final int attendu = p.numeroPage <= 2 ? 8 : 15;
      expect(p.lignes, hasLength(attendu), reason: 'page ${p.numeroPage}');
      expect(p.nombreLignes, attendu);
      expect(
        p.lignes.map((SectionLigne l) => l.numero),
        List<int>.generate(attendu, (int i) => i + 1),
      );
    }
  });

  test('8 820 lignes de texte, 114 cadres de sourate, 112 basmalas', () {
    final List<SectionLigne> toutes = <SectionLigne>[
      for (final LayoutPage p in pages) ...p.lignes,
    ];
    int de(TypeLigneMushaf t) =>
        toutes.where((SectionLigne l) => l.type == t).length;
    expect(de(TypeLigneMushaf.texte), 8820);
    expect(de(TypeLigneMushaf.enteteSourate), 114);
    expect(de(TypeLigneMushaf.basmala), 112);
  });

  test('6 236 fins de verset, chaque sourate:aya present une fois', () {
    final List<String> fins = <String>[];
    final List<String> debuts = <String>[];
    for (final LayoutPage p in pages) {
      for (final SectionLigne l in p.lignes) {
        for (final SegmentVersetLigne s in l.segments) {
          if (s.termineLAyah) fins.add('${s.sourate}:${s.ayah}');
          if (s.debuteLAyah) debuts.add('${s.sourate}:${s.ayah}');
        }
      }
    }
    final List<String> attendus = <String>[
      for (int s = 1; s <= 114; s++)
        for (int a = 1; a <= _versetsParSourate[s - 1]; a++) '$s:$a',
    ];
    expect(fins, attendus, reason: 'ordre du mushaf, une fois chacun');
    expect(debuts, attendus);
  });

  test('un cadre de sourate, puis sa basmala (sauf Al-Fatiha et At-Tawba)', () {
    for (final LayoutPage p in pages) {
      for (int i = 0; i < p.lignes.length; i++) {
        final SectionLigne l = p.lignes[i];
        if (l.type == TypeLigneMushaf.enteteSourate) {
          final int s = l.sourate!;
          if (s != 1 && s != 9) {
            expect(p.lignes[i + 1].type, TypeLigneMushaf.basmala);
            expect(p.lignes[i + 1].sourate, s);
          }
          final SectionLigne suivante =
              p.lignes[s == 1 || s == 9 ? i + 1 : i + 2];
          expect(suivante.type, TypeLigneMushaf.texte);
          expect(suivante.segments.first.sourate, s);
          expect(suivante.segments.first.ayah, 1);
          expect(suivante.segments.first.debuteLAyah, isTrue);
        }
        if (l.type != TypeLigneMushaf.texte) expect(l.centree, isTrue);
      }
    }
  });

  test(
    'juz, hizb et quarts : 30 juz, 60 hizb, 240 quarts, une fois chacun',
    () {
      int juz = 0;
      int hizb = 0;
      for (final LayoutPage p in pages) {
        expect(p.juz, inInclusiveRange(juz, juz + 1));
        expect(p.hizb, inInclusiveRange(hizb, hizb + 1));
        expect(p.rubDansHizb, inInclusiveRange(0, 3));
        juz = p.juz!;
        hizb = p.hizb!;
      }
      expect(juz, 30);
      expect(hizb, 60);
      expect(pages.first.juz, 1);
      expect(pages.first.hizb, 1);
      final List<int> quarts = <int>[
        for (final LayoutPage p in pages) ...p.quartsDebutes,
      ];
      expect(quarts, List<int>.generate(240, (int i) => i + 1));
    },
  );

  test('pages connues : Al-Fatiha, Al-Mujadila, la derniere', () {
    expect(pages[0].lignes.every((SectionLigne l) => l.centree), isTrue);
    expect(pages[1].lignes[0].sourate, 2);
    final LayoutPage mujadila = pages[543];
    expect(mujadila.lignes.first.segments.first.sourate, 58);
    final SectionLigne derniere = pages[603].lignes.last;
    expect(derniere.termineLaSourate, isTrue);
    expect(derniere.segments.last.sourate, 114);
    expect(derniere.segments.last.ayah, 6);
    // Une fin de sourate est signalee, et seulement elle.
    final int fins = <SectionLigne>[
      for (final LayoutPage p in pages) ...p.lignes,
    ].where((SectionLigne l) => l.termineLaSourate).length;
    expect(fins, 114);
  });

  test('le texte garde les signes de pause et ne contient que de l\'arabe', () {
    final String tout = <String>[
      for (final LayoutPage p in pages)
        for (final SectionLigne l in p.lignes)
          for (final SegmentVersetLigne s in l.segments) s.texte,
    ].join();
    expect(tout.contains('ۖ') || tout.contains('ۚ'), isTrue);
    expect(tout.contains('ٱ'), isTrue);
    expect(tout.contains("'"), isFalse);
    expect(tout.contains('¦'), isFalse);
    // Aucun chiffre de numerotation dans le texte : la rosace le porte.
    expect(RegExp('[٠-٩۰-۹]').hasMatch(tout), isFalse);
  });

  test('analyserPageMadina15 lit le format du generateur', () {
    final LayoutPage p = analyserPageMadina15(
      7,
      '3;5;2;9,10\nH;4\nB;4\nT;2;4:1:1:نص¦4:2:3:آخر',
    );
    expect(p.juz, 3);
    expect(p.hizb, 5);
    expect(p.rubDansHizb, 2);
    expect(p.quartsDebutes, <int>[9, 10]);
    expect(p.lignes[0].type, TypeLigneMushaf.enteteSourate);
    expect(p.lignes[2].termineLaSourate, isTrue);
    expect(p.lignes[2].segments, hasLength(2));
    expect(p.lignes[2].segments[0].termineLAyah, isFalse);
    expect(p.lignes[2].segments[1].termineLAyah, isTrue);
  });
}
