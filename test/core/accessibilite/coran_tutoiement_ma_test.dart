// MA-TUTOIEMENT-1 (decision A4 = a) : le lecteur du Coran du Mode
// Accessibilite vouvoie l'adulte. Depuis l'ecran de demonstration
// (`EcranAccessibiliteDemo`, destination Coran), on ouvre le VRAI lecteur
// (`LecteurCoranAccessibilite` et les vues de rendu `VuePageMushaf`,
// `VueVersetAgrandi`) sur une page illisible puis sur une page vide : la
// phrase d'invitation suit l'age (Mariam mineure : tutoyee ; Idriss adulte :
// vouvoye), dans les deux rendus. Le rendu du Coran ne change pas.
//
// Avant le correctif, le lecteur ne recevait pas le tutoiement et les vues
// disaient « ta page se rouvre ici » et « ce n'est pas toi » a l'adulte.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_eleve/coran_accessibilite.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';

/// Le corpus de reference, avec une page lue mais sans aucun verset.
class CorpusAvecPageVide extends FauxCorpusCoran {
  /// Cree le corpus.
  CorpusAvecPageVide(super.reference, {required this.pageVide});

  /// La page rendue vide (etat « corpus absent »).
  final int pageVide;

  @override
  Future<PageCorpus?> page(int numeroPage) async => numeroPage == pageVide
      ? PageCorpus(numero: numeroPage, versets: const <VersetCorpus>[])
      : super.page(numeroPage);
}

/// Les etats sans texte du lecteur.
enum EtatSansTexte {
  /// La lecture a echoue (la page n'est pas rendue).
  indisponible,

  /// La page est lue, vide.
  absent,
}

/// Une page du Mushaf absente du corpus de reference.
int pageHorsReference(CorpusReference reference) {
  final Set<int> connues = <int>{
    for (final PageCorpus p in reference.pages) p.numero,
  };
  return <int>[for (int n = 2; n < pagesMushafMedine; n++) n]
      .firstWhere((int n) => !connues.contains(n));
}

/// Les surcharges du lecteur ouvert sur une page sans texte.
List<Override> surchargesSansTexte(
  CorpusReference reference,
  EtatSansTexte etat,
) {
  final int page = pageHorsReference(reference);
  return <Override>[
    portCorpusCoranProvider.overrideWithValue(
      etat == EtatSansTexte.absent
          ? CorpusAvecPageVide(reference, pageVide: page)
          : FauxCorpusCoran(reference),
    ),
    portLayoutMushafProvider.overrideWithValue(
      const LayoutLignesIndisponible(),
    ),
    portNavigationCoranProvider.overrideWithValue(
      FauxNavigationCoran(
        personnelle: PositionLecture(page: page, sourate: 1, verset: 1),
      ),
    ),
  ];
}

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
    for (final EtatSansTexte etat in EtatSansTexte.values) {
      for (final bool grande in <bool>[false, true]) {
        final bool tu = DonneesAccessibiliteDemo.mineur(eleve);
        testWidgets('MA-TUTOIEMENT-1 : ${eleve.name}, ${etat.name}, grand '
            'texte = $grande : ${tu ? 'tutoiement' : 'vouvoiement'}', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final ProviderContainer racine = ProviderContainer();
          addTearDown(racine.dispose);
          racine
              .read(preferencesLocalesProvider.notifier)
              .lectureGrande(grande);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: racine,
              child: TranslationProvider(
                child: MaterialApp(
                  theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
                  locale: AppLocale.fr.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  home: EcranAccessibiliteDemo(
                    eleve: eleve,
                    destinationInitiale: EcranAccessibiliteDemo.indexCoran,
                    surchargesCoran: surchargesSansTexte(reference, etat),
                  ),
                ),
              ),
            ),
          );
          for (int i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.tap(
            find.byKey(const ValueKey<String>('coran-ma-principale')),
          );
          for (int i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }

          expect(find.byType(LecteurCoranAccessibilite), findsOneWidget);
          // Les VRAIES vues de rendu, selon la preference.
          expect(
            find.byType(VueVersetAgrandi),
            grande ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(VuePageMushaf),
            grande ? findsNothing : findsOneWidget,
          );
          final String titre = etat == EtatSansTexte.absent
              ? t.eleve.coran.absent
              : t.eleve.coran.indisponible;
          expect(find.text(titre), findsOneWidget);
          final String tutoie = etat == EtatSansTexte.absent
              ? t.eleve.coran.absentDetail
              : t.eleve.coran.indisponibleDetail;
          final String vouvoie = etat == EtatSansTexte.absent
              ? t.accessibilite.coran.absentDetailVous
              : t.accessibilite.coran.indisponibleDetailVous;
          expect(find.text(tutoie), tu ? findsOneWidget : findsNothing);
          expect(find.text(vouvoie), tu ? findsNothing : findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  // Le registre est un parametre de l'enrobage : seul, sans age connu, le
  // lecteur vouvoie (un age inconnu vouvoie, comme la salle).
  test('le lecteur seul vouvoie par defaut', () {
    expect(const LecteurCoranAccessibilite().tutoiement, isFalse);
  });
}
