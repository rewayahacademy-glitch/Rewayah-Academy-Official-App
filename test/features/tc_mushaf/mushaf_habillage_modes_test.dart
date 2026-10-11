// CORAN-320-1b (reserves de la relecture CORAN-320-1, decision deleguee du
// 05/10 elargie a l'habillage) : sur la route reelle `/eleve/coran`, la vraie
// `MushafPage` donne la majorite de la hauteur aux versets **dans ses trois
// rendus**, des 130 % de texte exactement ; l'etat vide du focus ne deborde
// plus ; le juz reste dans l'en-tete compact de la lecture agrandie et du
// focus. Le rendu des versets ne change pas : les parametres que recoivent
// `ColonneVersetsReflow` et `BlocVerset` sont compares a ceux releves sur le
// code d'avant (tete 5a52ff30).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_focus_classe.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, stabiliser;
import '../../support/aucun_mot_coupe.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';
import '../accueil_adulte/support_accueil_adulte_route.dart';

/// La part minimale de la hauteur de l'ecran (barre de navigation comprise)
/// donnee a la zone des versets : la majorite.
const double _seuilPartVersets = 0.5;

/// La cle du bouton d'options, ecrite en clair (CORAN-320-1).
const Key _options = ValueKey<String>('mushaf-options');

/// Le type du widget de la zone des versets, par rendu.
Type _zone(ModeRenduCoran mode) => switch (mode) {
  ModeRenduCoran.mushaf => VuePageMushaf,
  ModeRenduCoran.versetAgrandi => VueVersetAgrandi,
  ModeRenduCoran.focus => VueFocusClasse,
};

/// Les parametres du rendu des versets en lecture agrandie et en focus,
/// releves sur le code d'AVANT CORAN-320-1b (tete 5a52ff30), par rendu et
/// par format. Toute difference veut dire que le rendu des versets a change.
const Map<String, String> _parametresAvant = <String, String>{
  'versetAgrandi 320x568 x2': _signature320,
  'focus 320x568 x2': _signature320,
  'versetAgrandi 390x844 x2': _signature390,
  'focus 390x844 x2': _signature390,
  'versetAgrandi 1440x900 x1': _signature1440,
  'focus 1440x900 x1': _signature1440,
};

const String _signature320 =
    'colonne 1:1,1:2,1:3,1:4,1:5,1:6,1:7 z1.0 s1 x20.0 ltr | '
    'bloc 1:1 dtrue l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0 | '
    'bloc 1:2 dfalse l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0 | '
    'bloc 1:3 dfalse l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0 | '
    'bloc 1:4 dfalse l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0 | '
    'bloc 1:5 dfalse l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0 | '
    'bloc 1:6 dfalse l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0 | '
    'bloc 1:7 dfalse l288.0 t20.945454545454545 h2.169090909090909 r0.8055944055944055 z1.0/1.0';
const String _signature390 =
    'colonne 1:1,1:2,1:3,1:4,1:5,1:6,1:7 z1.0 s1 x20.0 ltr | '
    'bloc 1:1 dtrue l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0 | '
    'bloc 1:2 dfalse l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0 | '
    'bloc 1:3 dfalse l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0 | '
    'bloc 1:4 dfalse l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0 | '
    'bloc 1:5 dfalse l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0 | '
    'bloc 1:6 dfalse l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0 | '
    'bloc 1:7 dfalse l358.0 t26.036363636363635 h2.137272727272727 r1.0013986013986014 z1.0/1.0';
const String _signature1440 =
    'colonne 1:1,1:2,1:3,1:4,1:5,1:6,1:7 z1.0 s1 x10.0 ltr | '
    'bloc 1:1 dtrue l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0 | '
    'bloc 1:2 dfalse l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0 | '
    'bloc 1:3 dfalse l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0 | '
    'bloc 1:4 dfalse l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0 | '
    'bloc 1:5 dfalse l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0 | '
    'bloc 1:6 dfalse l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0 | '
    'bloc 1:7 dfalse l800.0 t34.0 h2.0875 r1.3076923076923077 z1.0/1.0';

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  /// Monte la route reelle et passe dans [mode]. Rend les erreurs de rendu
  /// (debordements) collectees pendant le montage.
  Future<List<String>> monter(
    WidgetTester tester, {
    required ModeRenduCoran mode,
    required Size taille,
    required double echelle,
    TextDirection sens = TextDirection.ltr,
  }) async {
    final List<String> erreurs = <String>[];
    final void Function(FlutterErrorDetails)? avant = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) =>
        erreurs.add(d.exceptionAsString().split('\n').first);
    try {
      await monterAccueilAdulteReel(
        tester,
        taille: taille,
        echelle: echelle,
        direction: sens,
        surcharges: <Override>[
          ...surchargesAccueilAdulte(accueil: Valeur(accueilDemo())),
          portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
          portLayoutMushafProvider.overrideWithValue(
            const LayoutLignesIndisponible(),
          ),
          portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
        ],
        depart: Routes.eleve,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavShell),
              matching: find.text(t.nav.eleve.coran),
            )
            .last,
      );
      await stabiliser(tester);
      expect(find.byType(MushafPage), findsOneWidget);
      ProviderScope.containerOf(tester.element(find.byType(MushafPage)))
          .read(lectureCoranProvider.notifier)
          .changerMode(mode);
      await stabiliser(tester);
    } finally {
      FlutterError.onError = avant;
    }
    return erreurs;
  }

  /// La part de la hauteur de l'ecran donnee a la zone des versets.
  double part(WidgetTester tester, ModeRenduCoran mode, Size taille) =>
      tester.getSize(find.byType(_zone(mode))).height / taille.height;

  /// La signature des parametres recus par le rendu des versets reflowable.
  String signature(WidgetTester tester) {
    final List<String> parties = <String>[];
    for (final Element e in find.byType(ColonneVersetsReflow).evaluate()) {
      final ColonneVersetsReflow c = e.widget as ColonneVersetsReflow;
      parties.add(
        'colonne ${c.versets.map((v) => v.reference).join(',')} '
        'z${c.zoom} s${c.sections.length} '
        'x${MediaQuery.textScalerOf(e).scale(10)} '
        '${Directionality.of(e).name}',
      );
    }
    for (final BlocVerset b in tester.widgetList<BlocVerset>(
      find.byType(BlocVerset),
    )) {
      final m = b.metrique;
      parties.add(
        'bloc ${b.verset.reference} d${b.debutDeSourate} '
        'l${m.largeurColonne} t${m.tailleTexte} h${m.interligne} '
        'r${m.echelleRosace} z${m.zoomDemande}/${m.zoomApplique}',
      );
    }
    return parties.join(' | ');
  }

  group('CORAN-320-1b : lecture agrandie et focus a texte x2', () {
    for (final ModeRenduCoran mode in <ModeRenduCoran>[
      ModeRenduCoran.versetAgrandi,
      ModeRenduCoran.focus,
    ]) {
      for (final Size taille in <Size>[
        const Size(320, 568),
        const Size(390, 844),
      ]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${mode.name} ${taille.width.toInt()}x'
              '${taille.height.toInt()} x2 ${sens.name} : zone des versets '
              '>= 50 %, pagination sur une rangee, juz dans l en-tete', (
            WidgetTester tester,
          ) async {
            final List<String> erreurs = await monter(
              tester,
              mode: mode,
              taille: taille,
              echelle: 2,
              sens: sens,
            );
            expect(erreurs, isEmpty);
            expect(
              part(tester, mode, taille),
              greaterThanOrEqualTo(_seuilPartVersets),
            );
            expect(find.byType(BlocVerset), findsWidgets);
            // Une rangee de cible tactile (48) : pagination et « Aller a une
            // page ». Le reglage de taille est replie avec le rendu.
            expect(
              tester.getSize(find.byKey(MushafPage.commandesKey)).height,
              lessThanOrEqualTo(48),
            );
            expect(
              tester.getSize(find.byKey(MushafPage.enteteKey)).height,
              lessThanOrEqualTo(48 + 8),
            );
            expect(find.text(t.eleve.coran.agrandir), findsNothing);
            // Le juz, que ces rendus n'ont nulle part ailleurs.
            expect(
              find.descendant(
                of: find.byKey(MushafPage.enteteKey),
                matching: find.textContaining(
                  t.eleve.coran.juz(juz: '1'),
                  findRichText: true,
                ),
              ),
              findsOneWidget,
            );
            verifierEcranSansMotCoupe(tester);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    testWidgets('le panneau « Mode de lecture » deplie le reglage de taille '
        'en lecture agrandie, et il agit', (WidgetTester tester) async {
      final List<String> erreurs = await monter(
        tester,
        mode: ModeRenduCoran.versetAgrandi,
        taille: const Size(320, 568),
        echelle: 2,
      );
      expect(erreurs, isEmpty);
      await tester.tap(find.byKey(_options));
      await tester.pump();
      // Le reglage est dans le panneau de l'en-tete, pas dans la pagination.
      expect(
        find.descendant(
          of: find.byKey(MushafPage.enteteKey),
          matching: find.text(t.eleve.coran.reduire),
        ),
        findsOneWidget,
      );
      expect(find.text(t.eleve.coran.reduire), findsOneWidget);
      expect(
        find.textContaining(t.tc.coran.zoom.valeur(pourcent: 100)),
        findsOneWidget,
      );
      await tester.tap(find.text(t.eleve.coran.agrandir));
      await tester.pump();
      expect(
        find.textContaining(t.tc.coran.zoom.valeur(pourcent: 120)),
        findsOneWidget,
      );
      // La mention du mushaf n'a rien a faire ici.
      expect(find.text(t.tc.coran.zoom.renvoiLectureAgrandie), findsNothing);
      verifierEcranSansMotCoupe(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group(
    'MUSHAF-MODES (d) : focus hors classe, la page ouverte est centree',
    () {
      for (final double echelle in <double>[1, 1.3, 2]) {
        testWidgets(
          '320x568 x$echelle : aucune phrase d aide, aucun debordement',
          (WidgetTester tester) async {
            final List<String> erreurs = await monter(
              tester,
              mode: ModeRenduCoran.focus,
              taille: const Size(320, 568),
              echelle: echelle,
            );
            expect(erreurs, isEmpty);
            expect(
              find.textContaining(t.tc.coran.focus.aucunePlage),
              findsNothing,
            );
            expect(find.byType(ColonneVersetsReflow), findsOneWidget);
            final Rect zone = tester.getRect(find.byType(VueFocusClasse));
            final Rect attribution = tester.getRect(
              find.byKey(MushafPage.attributionKey),
            );
            expect(zone.bottom, lessThanOrEqualTo(attribution.top + 0.5));
            expect(tester.takeException(), isNull);
          },
        );
      }
    },
  );

  testWidgets('lecture agrandie 320x568 x2 rtl : la valeur du reglage de '
      'taille est isolee (« 100 % », jamais « % 100 »)', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      mode: ModeRenduCoran.versetAgrandi,
      taille: const Size(320, 568),
      echelle: 2,
      sens: TextDirection.rtl,
    );
    await tester.tap(find.byKey(_options));
    await tester.pump();
    final Finder valeur = find.textContaining(
      t.tc.coran.zoom.valeur(pourcent: 100),
    );
    expect(valeur, findsOneWidget);
    final RenderParagraph p = tester.renderObject<RenderParagraph>(valeur);
    final String texte = p.text.toPlainText();
    double gauche(int i) => p
        .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
        .first
        .left;
    expect(
      gauche(texte.indexOf('1')),
      lessThan(gauche(texte.indexOf('%'))),
      reason: 'le nombre avant le signe, de gauche a droite',
    );
    verifierEcranSansMotCoupe(tester);
    expect(tester.takeException(), isNull);
  });

  group('CORAN-320-1b : a 130 % exactement, le chrome est deja compact', () {
    for (final ModeRenduCoran mode in ModeRenduCoran.values) {
      testWidgets('${mode.name} 320x568 x1,3 : zone des versets >= 50 %', (
        WidgetTester tester,
      ) async {
        final List<String> erreurs = await monter(
          tester,
          mode: mode,
          taille: const Size(320, 568),
          echelle: 1.3,
        );
        expect(erreurs, isEmpty);
        expect(find.byKey(_options), findsOneWidget);
        expect(
          part(tester, mode, const Size(320, 568)),
          greaterThanOrEqualTo(_seuilPartVersets),
        );
        verifierEcranSansMotCoupe(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('CORAN-320-1b : contre-epreuve, le rendu des versets est inchange', () {
    for (final ModeRenduCoran mode in <ModeRenduCoran>[
      ModeRenduCoran.versetAgrandi,
      ModeRenduCoran.focus,
    ]) {
      for (final (String nom, Size taille, double echelle) cas
          in <(String, Size, double)>[
            ('320x568 x2', const Size(320, 568), 2),
            ('390x844 x2', const Size(390, 844), 2),
            ('1440x900 x1', const Size(1440, 900), 1),
          ]) {
        testWidgets('${mode.name} ${cas.$1} : memes parametres qu avant', (
          WidgetTester tester,
        ) async {
          await monter(tester, mode: mode, taille: cas.$2, echelle: cas.$3);
          expect(signature(tester), _parametresAvant['${mode.name} ${cas.$1}']);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
