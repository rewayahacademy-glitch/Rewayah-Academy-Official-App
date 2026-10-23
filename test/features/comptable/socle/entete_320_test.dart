// CPT-RC (M3 de la revue CPT-R) : l'en-tete des pages de detail a 320 px,
// texte x2, en VRAIES polices, avec le disque retour ET la bascule des
// montants. Sur 8fb00a71, le titre n'etait pose sous le retour que si son mot
// le plus long ne tenait pas a cote : chaque mot tenant, titre et sous-titre
// etaient composes dans environ la moitie de la largeur, un mot par ligne
// (« A / traiter / et / alertes »), et le premier ecran ne montrait aucun
// contenu (captures `attention_320x640@2_texte2_light_masques`,
// `detailPaiement_320x640@2_texte2_light_masques`).
//
// Criteres : le titre dispose de toute la largeur de l'en-tete (retour et
// actions passent au-dessus), aucun mot coupe sur l'ecran, et un texte du
// contenu commence dans le premier ecran, au-dessus de la barre basse.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../capture/outil_capture.dart';
import '../../../support/aucun_mot_coupe.dart';
import '../../../support/harnais.dart';

const double _hauteurEcran = 640;

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  for (final EcranDemoComptable ecran in const <EcranDemoComptable>[
    EcranDemoComptable.attention,
    EcranDemoComptable.detailPaiement,
    EcranDemoComptable.obligationContractuel,
  ]) {
    testWidgets('${ecran.name} a 320 px, texte x2 : titre sur toute la '
        'largeur, contenu dans le premier ecran', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(320, _hauteurEcran), 2);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        hoteRoutant(
          depart: adresseDemoComptable(ecran),
          routes: routesDemoComptable('staging'),
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(BasculeMontants), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);

      // Le titre : son paragraphe recoit toute la largeur de l'en-tete.
      final Finder entete = find.byType(EntetePage).first;
      final Rect boiteEntete = tester.getRect(entete);
      final Finder titre = find
          .descendant(
            of: entete,
            matching: find.byWidgetPredicate(
              (Widget w) => w is Semantics && (w.properties.header ?? false),
            ),
          )
          .first;
      final RenderParagraph paragraphe = tester.renderObject<RenderParagraph>(
        find.descendant(of: titre, matching: find.byType(RichText)).first,
      );
      // JONCTION-LIGNES-1 : l'en-tete compact de SUPERPOS-1 (texte agrandi)
      // garde le titre, reduit a l'echelle HIER-1, a cote du retour quand
      // son plus long mot y tient, et pose le sous-titre sur toute la
      // largeur, sous la rangee : ce qui corrige le defaut M3 (titre et
      // sous-titre un mot par ligne). Le titre recoit alors au moins
      // [EntetePage.partMinTitre] de la largeur ; sinon, toute la largeur.
      final bool aCote = find
          .descendant(
            of: entete,
            matching: find.byKey(EnteteCompact.rangeeAuDessusKey),
          )
          .evaluate()
          .isEmpty;
      expect(
        paragraphe.constraints.maxWidth,
        greaterThanOrEqualTo(
          aCote
              ? boiteEntete.width * EntetePage.partMinTitre
              : boiteEntete.width - 1,
        ),
        reason:
            'Le titre est compose dans '
            '${paragraphe.constraints.maxWidth.toStringAsFixed(0)} px sur '
            '${boiteEntete.width.toStringAsFixed(0)}',
      );
      verifierEcranSansMotCoupe(tester);

      // Le premier ecran montre du contenu : un texte hors de l'en-tete
      // commence sous lui et au-dessus de la barre basse.
      final double basVisible = _basVisible(tester);
      final Iterable<Rect> textesContenu = find
          .byType(RichText)
          .evaluate()
          .where(
            (Element e) => find
                .descendant(of: entete, matching: find.byWidget(e.widget))
                .evaluate()
                .isEmpty,
          )
          .map((Element e) => tester.getRect(find.byWidget(e.widget).first))
          .where(
            (Rect r) =>
                r.top >= boiteEntete.bottom &&
                r.top < basVisible &&
                r.height > 0,
          );
      expect(
        textesContenu,
        isNotEmpty,
        reason:
            'Aucun contenu dans le premier ecran : en-tete jusqu a '
            '${boiteEntete.bottom.toStringAsFixed(0)}, ecran utile jusqu a '
            '${basVisible.toStringAsFixed(0)}',
      );
    });
  }
  for (final double texte in const <double>[1, 2]) {
    testWidgets(
      'W06 (obligation de contractuel) a 320 px, texte x$texte : '
      'la barre collante ${texte >= 1.5 ? 'compacte, la phrase d aide dans le corps qui defile' : 'garde sa phrase d aide'}',
      (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, _hauteurEcran), 2);
        tester.platformDispatcher.textScaleFactorTestValue = texte;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          hoteRoutant(
            depart: adresseDemoComptable(
              EcranDemoComptable.obligationContractuel,
            ),
            routes: routesDemoComptable('staging'),
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        final Finder aide = find.text(t.comptable.contractuels.payerAide);
        expect(aide, findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('action-obligation')),
          findsOneWidget,
        );
        final Finder dansLeCorps = find.ancestor(
          of: aide,
          matching: find.byType(Scrollable),
        );
        expect(dansLeCorps, texte >= 1.5 ? findsWidgets : findsNothing);
      },
    );
  }
}

/// Le bas de la zone utile : le haut de la barre basse de la coquille, ou le
/// bas de l'ecran quand elle est masquee.
double _basVisible(WidgetTester tester) {
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  if (barre.evaluate().isEmpty) return _hauteurEcran;
  return tester.getRect(barre).top;
}
