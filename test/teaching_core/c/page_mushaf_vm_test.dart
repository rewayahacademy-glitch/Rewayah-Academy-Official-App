import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/coran/vue_lecteur.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';

import 'goldens/corpus_reference.dart';

/// Les goldens du moteur Mushaf.
///
/// **Ils portent sur ce qui est verifiable, et rien d'autre.** Les donnees du
/// depot permettent de prouver quatre choses : quels versets une page porte,
/// ou tombe un changement de sourate, de quel cote une page se pose, et quelle
/// ouverture la contient. Elles ne permettent PAS de prouver la repartition des
/// mots sur quinze lignes, parce que `verset.ligne` est nulle : un golden qui
/// pretendrait le verifier verifierait une invention.
void main() {
  late CorpusReference reference;

  setUpAll(() => reference = CorpusReference.charger());

  PageMushafVM vueDe(
    int numero, {
    DisponibiliteLayout fidelite = DisponibiliteLayout.indisponible,
    LayoutPage? layout,
  }) => PageMushafVM.depuis(
    pageDemandee: numero,
    page: reference.page(numero),
    chargementEnCours: false,
    sourates: reference.sourates,
    fidelite: fidelite,
    layout: layout,
    nombrePages: reference.nombrePages,
  );

  group('composition de page', () {
    test('chaque page de reference porte exactement ses versets', () {
      for (final PageCorpus attendue in reference.pages) {
        final PageMushafVM vue = vueDe(attendue.numero);

        expect(
          vue.versets.map((VersetCoran v) => v.reference).toList(),
          attendue.versets.map((VersetCorpus v) => v.reference).toList(),
          reason: 'page ${attendue.numero}',
        );
      }
    });

    test('les sections suivent le golden, sourate par sourate', () {
      for (final CompositionAttendue attendue in reference.compositions) {
        final PageMushafVM vue = vueDe(attendue.page);
        final List<SectionAttendue> sections = attendue.sections;

        expect(
          vue.sections.length,
          sections.length,
          reason: 'page ${attendue.page}',
        );
        for (int i = 0; i < sections.length; i++) {
          final SectionSourate obtenue = vue.sections[i];
          final SectionAttendue voulue = sections[i];
          expect(obtenue.sourateNumero, voulue.sourate);
          expect(
            obtenue.commenceLaSourate,
            voulue.commenceLaSourate,
            reason: 'page ${attendue.page}, sourate ${voulue.sourate}',
          );
          expect(obtenue.versets.first.numero, voulue.premier);
          expect(obtenue.versets.last.numero, voulue.dernier);
        }
      }
    });

    test('un changement de sourate coupe la page en deux sections', () {
      // Page 4 du golden : fin d'Al-Baqara, puis ouverture d'Aal-Imraan.
      final PageMushafVM vue = vueDe(4);

      expect(vue.sections.length, 2);
      expect(vue.sections.first.commenceLaSourate, isFalse);
      expect(vue.sections.last.commenceLaSourate, isTrue);
      expect(vue.sections.last.versets.first.numero, 1);
    });

    test('aucun verset ne se retrouve sur deux pages', () {
      final Set<String> vus = <String>{};
      for (final PageCorpus page in reference.pages) {
        for (final VersetCorpus v in page.versets) {
          expect(
            vus.add(v.reference),
            isTrue,
            reason: '${v.reference} apparait deux fois',
          );
        }
      }
    });

    test('aucune page du corpus ne porte zero verset', () {
      // Le meme controle que le bloc final de la migration 0013.
      for (final PageCorpus page in reference.pages) {
        expect(page.vide, isFalse, reason: 'page ${page.numero}');
      }
    });
  });

  group('cote de page et ouverture', () {
    test('le cote de chaque page de reference suit le golden', () {
      for (final CompositionAttendue attendue in reference.compositions) {
        expect(
          vueDe(attendue.page).cote,
          attendue.cote,
          reason: 'page ${attendue.page}',
        );
      }
    });

    test('une ouverture pose l impair a droite et le pair a gauche', () {
      for (final CompositionAttendue attendue in reference.compositions) {
        final int droite = GeometrieMushaf.pageDeDroiteDe(attendue.page);
        final int? gauche = GeometrieMushaf.pageDeGaucheDe(
          attendue.page,
          nombrePages: reference.nombrePages,
        );

        expect(droite.isOdd, isTrue);
        expect(gauche, isNotNull);
        expect(gauche!.isEven, isTrue);
        expect(<int>{droite, gauche}, contains(attendue.page));
        expect(<int>{droite, gauche}, contains(attendue.ouvertureAvec));
      }
    });

    test('la planche double refuse deux pages du meme cote', () {
      final PageMushafVM droite = vueDe(1);
      final PageMushafVM autreDroite = vueDe(3);

      expect(
        () => PlancheMushafVM.doublePage(
          droite: droite,
          gauche: autreDroite,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('la planche double refuse deux pages qui ne se suivent pas', () {
      expect(
        () => PlancheMushafVM.doublePage(droite: vueDe(1), gauche: vueDe(4)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('la planche simple ne porte qu une page', () {
      final PlancheMushafVM planche = PlancheMushafVM.simple(vueDe(1));

      expect(planche.estDouble, isFalse);
      expect(planche.pages.length, 1);
    });

    test('la planche double se lit de droite a gauche', () {
      final PlancheMushafVM planche = PlancheMushafVM.doublePage(
        droite: vueDe(1),
        gauche: vueDe(2),
      );

      expect(planche.pages.first.numero, 1);
      expect(planche.pages.last.numero, 2);
    });
  });

  group('l edition reelle, 604 pages', () {
    test('la premiere page est a droite, la derniere a gauche', () {
      expect(GeometrieMushaf.coteDe(1), CoteDePage.droite);
      expect(GeometrieMushaf.coteDe(pagesMushafMedine), CoteDePage.gauche);
    });

    test('la derniere ouverture porte les pages 603 et 604', () {
      expect(GeometrieMushaf.pageDeDroiteDe(604), 603);
      expect(GeometrieMushaf.pageDeGaucheDe(603), 604);
    });

    test('une derniere page impaire n a rien en face', () {
      expect(GeometrieMushaf.pageDeGaucheDe(603, nombrePages: 603), isNull);
    });

    test('les bornes de navigation ferment aux deux bouts', () {
      final PageMushafVM premiere = PageMushafVM.depuis(
        pageDemandee: 1,
        page: const PageCorpus(numero: 1, versets: <VersetCorpus>[]),
        chargementEnCours: false,
        sourates: const <SourateVM>[],
        fidelite: DisponibiliteLayout.indisponible,
      );
      final PageMushafVM derniere = PageMushafVM.depuis(
        pageDemandee: pagesMushafMedine,
        page: const PageCorpus(
          numero: pagesMushafMedine,
          versets: <VersetCorpus>[],
        ),
        chargementEnCours: false,
        sourates: const <SourateVM>[],
        fidelite: DisponibiliteLayout.indisponible,
      );

      expect(premiere.pagePrecedente, isNull);
      expect(premiere.pageSuivante, 2);
      expect(derniere.pageSuivante, isNull);
      expect(derniere.pagePrecedente, pagesMushafMedine - 1);
    });

    test('une page hors bornes est ramenee dans l edition', () {
      final PageMushafVM trop = PageMushafVM.depuis(
        pageDemandee: 900,
        page: null,
        chargementEnCours: true,
        sourates: null,
        fidelite: DisponibiliteLayout.indisponible,
      );

      expect(trop.numero, pagesMushafMedine);
    });
  });

  group('fidelite de composition, honnetement declaree', () {
    test('sans source de layout, la page se declare approximee', () {
      final PageMushafVM vue = vueDe(1);

      expect(vue.fidelite, DisponibiliteLayout.indisponible);
      expect(vue.compositionApprochee, isTrue);
      expect(vue.lignes, isEmpty);
    });

    test('le nombre de lignes et le cadre viennent de l edition', () {
      final PageMushafVM vue = vueDe(1);

      expect(vue.nombreLignes, GeometrieMushaf.lignesParPage);
      expect(vue.ratioLargeurSurHauteur, GeometrieMushaf.ratioCadreTexte);
    });

    test(
      'une source qui se dit fidele sans rendre de ligne ne l est pas',
      () {
        // Le piege qu'on refuse : une source branchee, une page sans donnees,
        // et un moteur qui afficherait quand meme « composition de l edition ».
        final PageMushafVM vue = vueDe(
          1,
          fidelite: DisponibiliteLayout.fidele,
        );

        expect(vue.fidelite, DisponibiliteLayout.indisponible);
        expect(vue.compositionApprochee, isTrue);
      },
    );

    test('avec de vraies lignes, la page se declare fidele', () {
      final PageMushafVM vue = vueDe(
        1,
        fidelite: DisponibiliteLayout.fidele,
        layout: const LayoutPage(
          numeroPage: 1,
          nombreLignes: 2,
          ratioLargeurSurHauteur: 0.7,
          lignes: <SectionLigne>[
            SectionLigne(
              numero: 1,
              centree: true,
              segments: <SegmentVersetLigne>[
                SegmentVersetLigne(
                  sourate: 1,
                  ayah: 1,
                  texte: 'texte 1:1',
                  debuteLAyah: true,
                  termineLAyah: true,
                ),
              ],
            ),
            SectionLigne(
              numero: 2,
              segments: <SegmentVersetLigne>[
                SegmentVersetLigne(
                  sourate: 1,
                  ayah: 2,
                  texte: 'texte 1:2',
                  debuteLAyah: true,
                  termineLAyah: true,
                ),
              ],
            ),
          ],
        ),
      );

      expect(vue.fidelite, DisponibiliteLayout.fidele);
      expect(vue.compositionApprochee, isFalse);
      expect(vue.lignes.length, 2);
      expect(vue.nombreLignes, 2);
      expect(vue.ratioLargeurSurHauteur, 0.7);
    });
  });

  group('etats du lecteur, repris de VueLecteur', () {
    test('une page absente et une lecture en cours donnent chargement', () {
      final PageMushafVM vue = PageMushafVM.depuis(
        pageDemandee: 1,
        page: null,
        chargementEnCours: true,
        sourates: null,
        fidelite: DisponibiliteLayout.indisponible,
      );

      expect(vue.etat, EtatLecteur.chargement);
    });

    test('une lecture terminee sans page donne indisponible', () {
      final PageMushafVM vue = PageMushafVM.depuis(
        pageDemandee: 1,
        page: null,
        chargementEnCours: false,
        sourates: null,
        fidelite: DisponibiliteLayout.indisponible,
      );

      expect(vue.etat, EtatLecteur.indisponible);
    });

    test('une page vide dit corpus absent, pas indisponible', () {
      final PageMushafVM vue = PageMushafVM.depuis(
        pageDemandee: 1,
        page: const PageCorpus(numero: 1, versets: <VersetCorpus>[]),
        chargementEnCours: false,
        sourates: null,
        fidelite: DisponibiliteLayout.indisponible,
      );

      expect(vue.etat, EtatLecteur.corpusAbsent);
    });
  });

  group('decision de double page', () {
    test('le telephone ne montre jamais deux pages', () {
      expect(
        PlancheMushafVM.tientEnDoublePage(
          largeurDisponible: 3000,
          hauteurDisponible: 400,
          ecartEntrePages: 16,
          gabaritLarge: false,
        ),
        isFalse,
      );
    });

    test('une tablette etroite reste a une page', () {
      // Deux cadres a cette hauteur demanderaient 2 x 800 x 0,666 + 16.
      expect(
        PlancheMushafVM.tientEnDoublePage(
          largeurDisponible: 800,
          hauteurDisponible: 800,
          ecartEntrePages: 16,
          gabaritLarge: true,
        ),
        isFalse,
      );
    });

    test('un ecran large montre deux pages', () {
      expect(
        PlancheMushafVM.tientEnDoublePage(
          largeurDisponible: 1400,
          hauteurDisponible: 900,
          ecartEntrePages: 16,
          gabaritLarge: true,
        ),
        isTrue,
      );
    });

    test('une hauteur nulle ne declenche pas une double page', () {
      expect(
        PlancheMushafVM.tientEnDoublePage(
          largeurDisponible: 1400,
          hauteurDisponible: 0,
          ecartEntrePages: 16,
          gabaritLarge: true,
        ),
        isFalse,
      );
    });
  });
}
