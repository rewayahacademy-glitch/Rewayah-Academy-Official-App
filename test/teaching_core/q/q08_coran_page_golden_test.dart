// Q-08 : contrat golden de page et de double page du Coran.
//
// Spec section 15 : « la page Mushaf conserve ses reperes de layout ».
// Decisions D-09 (source canonique structuree, PDF derive) et D-23 (fidelite
// Mushaf : STOP obligatoire, pas d improvisation).
//
// CE GOLDEN EST UN GOLDEN DE DONNEES, PAS D IMAGE. Rendre une page de Mushaf
// demanderait une police glyphe-par-page que le depot n a pas ; un golden
// d image serait donc soit faux, soit une photographie de l approximation
// qu on veut justement interdire. Celui-ci fixe ce qu une page CONTIENT, ce
// qui est verifiable, stable, et suffisant pour qu Agent C ne se trompe pas
// de versets.
//
// Les valeurs viennent de `supabase/migrations/0013_corpus_coranique.sql`.
// Voir l en-tete de `fixtures/goldens_coran.dart` pour la provenance exacte.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';

import '../fixtures/goldens_coran.dart';

void main() {
  group('Q-08 : la page N contient exactement les versets attendus', () {
    test('page 1 : Al-Fatiha entiere, seule sur sa page', () {
      final List<SegmentPage> page = goldenPagesMushaf[1]!;

      expect(page, hasLength(1));
      expect(page.single.sourate, 1);
      expect(page.single.ayahDebut, 1);
      expect(page.single.ayahFin, 7);
      expect(versetsDePage(1), 7);
      // La sourate est complete : la page ne coupe rien.
      expect(page.single.nombreVersets, goldenVersetsParSourate[1]);
    });

    test('pages 2 et 3 : une longue sourate commence et se poursuit', () {
      expect(goldenPagesMushaf[2]!.single.ayahFin, 5);
      expect(goldenPagesMushaf[3]!.single.ayahDebut, 6);
      // Aucun trou, aucun recouvrement entre deux pages consecutives.
      expect(
        goldenPagesMushaf[3]!.single.ayahDebut,
        goldenPagesMushaf[2]!.single.ayahFin + 1,
      );
    });

    test('page 48 : un seul verset occupe toute la page', () {
      // 2:282, le verset de la dette, le plus long du Coran. Une interface
      // qui supposerait « une page = plusieurs versets » casse ici, et c est
      // exactement pourquoi cette page figure dans le golden.
      final List<SegmentPage> page = goldenPagesMushaf[48]!;
      expect(versetsDePage(48), 1);
      expect(page.single.sourate, 2);
      expect(page.single.ayahDebut, 282);
      expect(page.single.ayahFin, 282);
    });

    test('page 42 : la page d ayat al-Kursi', () {
      final SegmentPage p = goldenPagesMushaf[42]!.single;
      expect(p.sourate, 2);
      expect(p.ayahDebut <= 255 && 255 <= p.ayahFin, isTrue);
    });

    test('page 604 : trois sourates completes ferment le Mushaf', () {
      final List<SegmentPage> page = goldenPagesMushaf[604]!;
      expect(page, hasLength(3));
      expect(page.map((SegmentPage s) => s.sourate).toList(), <int>[
        112,
        113,
        114,
      ]);
      for (final SegmentPage s in page) {
        expect(s.ayahDebut, 1);
        expect(s.nombreVersets, goldenVersetsParSourate[s.sourate]);
      }
      expect(versetsDePage(604), 15);
    });

    test('pages 599 et 600 : une sourate traverse la coupure', () {
      // La sourate 100 commence page 599 au verset 1 et se termine page 600
      // au verset 11 : une page n est PAS une unite de sens, et un moteur
      // qui paginerait par sourate se tromperait des la premiere.
      final SegmentPage finDe599 = goldenPagesMushaf[599]!.last;
      final SegmentPage debutDe600 = goldenPagesMushaf[600]!.first;

      expect(finDe599.sourate, 100);
      expect(finDe599.ayahFin, 9);
      expect(debutDe600.sourate, 100);
      expect(debutDe600.ayahDebut, 10);
      expect(debutDe600.ayahDebut, finDe599.ayahFin + 1);
      expect(
        finDe599.nombreVersets + debutDe600.nombreVersets,
        goldenVersetsParSourate[100],
      );
    });

    test('toute page du golden est dans les bornes du Mushaf', () {
      for (final int page in goldenPagesMushaf.keys) {
        expect(page, inInclusiveRange(1, pagesMushafGolden));
        expect(versetsDePage(page), greaterThan(0));
      }
      // Les segments d une page sont ordonnes et contigus par sourate.
      goldenPagesMushaf.forEach((int page, List<SegmentPage> segments) {
        for (int i = 1; i < segments.length; i++) {
          expect(
            segments[i].sourate,
            greaterThan(segments[i - 1].sourate),
            reason: 'page $page : les sourates se suivent',
          );
        }
      });
    });

    test('le golden s accorde aux constantes de production', () {
      // Ne jamais coder un uuid de mushaf en dur : l id est genere par la
      // base et differe d un environnement a l autre. Le CODE, lui, est
      // stable, et il vit deja dans `service_coran.dart`.
      expect(editionMushafGolden, codeMushafReference);
      expect(pagesMushafGolden, pagesMushafMedine);
      expect(versetsMushafGolden, 6236);
    });
  });

  group('Q-08 : la double page est une convention DONNEE, pas une regle', () {
    test('la parite du recto change l appariement', () {
      // Le depot ne porte AUCUNE notion de recto / verso ni de spread. Un
      // moteur qui coderait la parite en dur se tromperait a la premiere
      // edition differente. Le test le prouve en changeant la convention.
      expect(doublePageDe(3, pageRecto: 1), <int>[2, 3]);
      expect(doublePageDe(3, pageRecto: 0), <int>[3, 4]);
    });

    test('les deux extremites du Mushaf rendent une page seule', () {
      // Avec la convention « page impaire = recto », la page 1 n a pas de
      // voisine a sa gauche ; avec la convention inverse, la 604 n en a pas
      // a sa droite. Les deux cas existent, et aucun n est une anomalie.
      expect(doublePageDe(1, pageRecto: 1), <int>[1]);
      expect(doublePageDe(604, pageRecto: 1), <int>[604]);
    });

    test('une double page ne perd ni ne duplique aucun verset', () {
      final List<int> spread = doublePageDe(600, pageRecto: 0);
      expect(spread, <int>[599, 600]);

      final int total = spread.fold<int>(
        0,
        (int n, int page) => n + versetsDePage(page),
      );
      expect(total, versetsDePage(599) + versetsDePage(600));

      // Aucun verset n apparait dans les deux pages d une meme double page.
      final Set<String> vus = <String>{};
      for (final int page in spread) {
        for (final SegmentPage s in goldenPagesMushaf[page]!) {
          for (int a = s.ayahDebut; a <= s.ayahFin; a++) {
            expect(
              vus.add('${s.sourate}:$a'),
              isTrue,
              reason: 'le verset ${s.sourate}:$a apparait deux fois',
            );
          }
        }
      }
      expect(vus, hasLength(total));
    });
  });

  group('Q-08 : la fidelite Mushaf n est pas disponible, et le dit', () {
    test(
      'sans ligne peuplee ni asset de layout, la reponse est indisponible',
      () {
        // Decision D-23 : Agent C ne fabrique pas une fausse page. Tant que
        // `verset.ligne` est NULL sur les 6236 lignes -- ce que 0013 assume
        // explicitement -- la disponibilite vaut `indisponible`.
        expect(
          disponibiliteLayout(
            lignesPeuplees: lignesVersetPeupleesDansLaBaseline,
            assetsLayoutFournis: assetsLayoutFournisDansLaBaseline,
          ),
          DisponibiliteLayoutGolden.indisponible,
        );
      },
    );

    test('une seule des deux sources donne un mode degrade, jamais fidele', () {
      expect(
        disponibiliteLayout(lignesPeuplees: true, assetsLayoutFournis: false),
        DisponibiliteLayoutGolden.degrade,
      );
      expect(
        disponibiliteLayout(lignesPeuplees: false, assetsLayoutFournis: true),
        DisponibiliteLayoutGolden.degrade,
      );
      expect(
        disponibiliteLayout(lignesPeuplees: true, assetsLayoutFournis: true),
        DisponibiliteLayoutGolden.fidele,
      );
    });

    test('la baseline ne permet donc jamais d annoncer une page fidele', () {
      expect(
        disponibiliteLayout(
          lignesPeuplees: lignesVersetPeupleesDansLaBaseline,
          assetsLayoutFournis: assetsLayoutFournisDansLaBaseline,
        ),
        isNot(DisponibiliteLayoutGolden.fidele),
      );
    });
  });
}
