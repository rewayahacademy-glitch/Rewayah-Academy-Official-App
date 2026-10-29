// CORAN-320-1 (decision deleguee du 05/10, choix a) : a 320 x 568 et
// 390 x 844, texte x2, la page Coran (route reelle `/eleve/coran`, vraie
// `MushafPage`) donne la majorite de la hauteur de l'ecran aux versets ;
// en-tete, mentions et pagination se resserrent (une ligne chacun, taille
// plafonnee au seuil du texte agrandi). Le rendu des versets, lui, ne change
// pas : ses parametres sont compares a ceux releves sur le code d'avant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/theme/app_contour.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, stabiliser;
import '../../support/aucun_mot_coupe.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';
import '../accueil_adulte/support_accueil_adulte_route.dart';

/// La part minimale de la hauteur de l'ecran (barre de navigation comprise)
/// donnee a la zone des versets : la majorite.
const double _seuilPartVersets = 0.5;

/// Les parametres du rendu des versets, releves sur le code d'AVANT
/// CORAN-320-1 (tete 6e2c91c4), par format. Toute difference veut dire que
/// le rendu des versets a change : c'est interdit par la decision du 05/10.
const Map<String, String> _parametresAvant = <String, String>{
  '320x568 x2': _signature320,
  '390x844 x2': _signature390,
  '1440x900 x1': _signature1440,
};

const String _signature320 =
    'cadre p1 l288.0 | texte p1 l288.0 x20.0 rtl | '
    'versets 1,2,3,4,5,6,7 t20.945454545454545 h2.169090909090909 '
    'f[UthmanTahaNaskh] r0.8055944055944055';
const String _signature390 =
    'cadre p1 l358.0 | texte p1 l358.0 x20.0 rtl | '
    'versets 1,2,3,4,5,6,7 t26.036363636363635 h2.137272727272727 '
    'f[UthmanTahaNaskh] r1.0013986013986014';
const String _signature1440 =
    'cadre p1 l552.0 | cadre p2 l552.0 | '
    'texte p1 l552.0 x10.0 rtl | texte p2 l552.0 x10.0 rtl | '
    'versets 1,2,3,4,5,6,7 t34.0 h2.0875 f[UthmanTahaNaskh] '
    'r1.3076923076923077 | '
    'versets 1,2,3,4,5 t34.0 h2.0875 f[UthmanTahaNaskh] r1.3076923076923077';

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  Future<void> monter(
    WidgetTester tester, {
    required Size taille,
    required double echelle,
    TextDirection sens = TextDirection.ltr,
  }) async {
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
            // Lot B2 : la barre de l adulte dit « Apprendre ».
            matching: find.text(t.nav.eleve.apprendre),
          )
          .last,
    );
    await stabiliser(tester);
    expect(find.byType(MushafPage), findsOneWidget);
  }

  /// La signature des parametres recus par le rendu des versets.
  String signature(WidgetTester tester) {
    final List<String> parties = <String>[];
    for (final CadrePageMushaf c in tester.widgetList<CadrePageMushaf>(
      find.byType(CadrePageMushaf),
    )) {
      parties.add('cadre p${c.vue.numero} l${c.largeur}');
    }
    for (final Element e in find.byType(TexteDePage).evaluate()) {
      final TexteDePage w = e.widget as TexteDePage;
      parties.add(
        'texte p${w.vue.numero} l${w.largeur} '
        'x${MediaQuery.textScalerOf(e).scale(10)} '
        '${Directionality.of(e).name}',
      );
    }
    for (final ParagrapheVersets p in tester.widgetList<ParagrapheVersets>(
      find.byType(ParagrapheVersets),
    )) {
      parties.add(
        'versets ${p.versets.map((v) => v.numero).join(',')} '
        't${p.style.fontSize} h${p.style.height} '
        'f[${p.style.fontFamily}] r${p.echelleRosace}',
      );
    }
    return parties.join(' | ');
  }

  group('CORAN-320-1 : la hauteur va aux versets a texte x2', () {
    for (final Size taille in <Size>[
      const Size(320, 568),
      const Size(390, 844),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${taille.width.toInt()}x${taille.height.toInt()} x2 '
            '${sens.name} : zone des versets >= 50 % de l ecran, chrome '
            'sur une ligne', (WidgetTester tester) async {
          await monter(tester, taille: taille, echelle: 2, sens: sens);

          final double versets = tester
              .getSize(find.byType(VuePageMushaf))
              .height;
          expect(
            versets / taille.height,
            greaterThanOrEqualTo(_seuilPartVersets),
            reason: 'versets $versets sur ${taille.height}',
          );
          // Les versets sont bien la, dans la zone.
          expect(find.byType(ParagrapheVersets), findsWidgets);

          // L'en-tete et les commandes tiennent chacun sur une rangee de
          // cible tactile (48) plus sa marge serree.
          expect(
            tester.getSize(find.byKey(MushafPage.enteteKey)).height,
            lessThanOrEqualTo(48 + 8),
          );
          expect(
            tester.getSize(find.byKey(MushafPage.commandesKey)).height,
            lessThanOrEqualTo(48),
          );
          // Taille plafonnee au seuil du texte agrandi, jamais sous la base.
          final Element titre = find
              .descendant(
                of: find.byKey(MushafPage.enteteKey),
                matching: find.byType(Text),
              )
              .evaluate()
              .first;
          expect(
            MediaQuery.textScalerOf(titre).scale(10),
            closeTo(10 * AppContour.seuilTexteAgrandi, 0.001),
          );
          // La mention du mushaf est repliee ; la pagination et l'acces
          // a « Aller a une page » restent la, ce dernier en icone nommee.
          expect(
            find.text(t.tc.coran.zoom.renvoiLectureAgrandie),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('nav-position')),
            findsOneWidget,
          );
          expect(find.byTooltip(t.tc.coran.navigation.ouvrir), findsOneWidget);
          // L'attribution Tanzil (licence) reste entiere, deux lignes au
          // plus.
          final Finder attribution = find.descendant(
            of: find.byKey(MushafPage.attributionKey),
            matching: find.byType(RichText),
          );
          final String texte = tester
              .widget<RichText>(attribution)
              .text
              .toPlainText();
          expect(texte, contains('Tanzil Project'));
          expect(texte, contains('tanzil.net'));
          expect(texte, contains(t.eleve.coran.edition));
          expect(
            tester.getSize(attribution).height,
            lessThanOrEqualTo(
              tester.getSize(find.byKey(MushafPage.enteteKey)).height,
            ),
          );
          verifierEcranSansMotCoupe(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('le bouton de l en-tete deplie le choix du rendu et la '
        'mention, et le choix change le rendu', (WidgetTester tester) async {
      await monter(tester, taille: const Size(320, 568), echelle: 2);
      expect(find.byType(SelecteurSection<ModeRenduCoran>), findsNothing);
      expect(find.byTooltip(t.tc.coran.modes.choisir), findsOneWidget);

      await tester.tap(find.byKey(MushafPage.optionsKey));
      await tester.pump();
      expect(find.byType(SelecteurSection<ModeRenduCoran>), findsOneWidget);
      expect(find.text(t.tc.coran.zoom.renvoiLectureAgrandie), findsOneWidget);
      verifierEcranSansMotCoupe(tester);

      // Replie de nouveau : la place revient aux versets.
      await tester.tap(find.byKey(MushafPage.optionsKey));
      await tester.pump();
      expect(find.byType(SelecteurSection<ModeRenduCoran>), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('CORAN-320-1 : contre-epreuve, le rendu des versets est inchange', () {
    for (final (String nom, Size taille, double echelle) cas
        in <(String, Size, double)>[
          ('320x568 x2', const Size(320, 568), 2),
          ('390x844 x2', const Size(390, 844), 2),
          ('1440x900 x1', const Size(1440, 900), 1),
        ]) {
      testWidgets('${cas.$1} : memes parametres qu avant', (
        WidgetTester tester,
      ) async {
        await monter(tester, taille: cas.$2, echelle: cas.$3);
        expect(signature(tester), _parametresAvant[cas.$1]);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('1440 x1 : en-tete, mention et lien « Aller a une page » '
        'gardent leur forme d avant', (WidgetTester tester) async {
      await monter(tester, taille: const Size(1440, 900), echelle: 1);
      expect(find.byKey(MushafPage.optionsKey), findsNothing);
      expect(find.byType(SelecteurSection<ModeRenduCoran>), findsOneWidget);
      expect(find.text(t.tc.coran.zoom.renvoiLectureAgrandie), findsOneWidget);
      expect(find.text(t.tc.coran.navigation.ouvrir), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
