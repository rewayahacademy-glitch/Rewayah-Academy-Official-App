// COM-RC tour 2, lot E (Communaute) : la recette apres COM-RC, rendue dans
// la VRAIE coquille de l'enseignant, avec les polices du depot (comme les
// captures).
//
// - R-01 (regression) : la publication garde la priorite de lecture. Le
//   composer de reponse et son garde defilent avec la page ; le premier
//   ecran montre la publication, sa categorie et « Enregistrer la
//   publication » (390), la publication se lit au premier ecran (320,
//   texte x2), et une reponse bloquee garde le champ entier visible, avec
//   « Enregistrer » a sa place dans la page (1440).
// - R-22 : le composer de reponse emploie la persistance des brouillons de
//   `FilDiscussion` (`PersistanceBrouillon`) : « Brouillon restaure » comme
//   dans les Messages.
// - Hors lot C : a 320 x 640, texte x2, le flux ne deborde plus (bandeau,
//   categories, recherche et entree du composer defilent avec lui).
// - Mineurs : (i) et (x) sur la meme rangee au composer (390) ; la
//   recherche de la Communaute n'est pas tronquee a 1440.
//
// Chaque test dit sa contre-preuve : ce qui echouait avant la correction.
// Les verifications du premier ecran se font SANS faire defiler.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/champ_recherche.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/port_garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/com_communaute/reponses.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import 'banc_communaute.dart';

const String _ouverte = 'pub-memorisation';

Future<void> _chargerPolicesDuDepot() async {
  final List<Object?> familles = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final Object? entree in familles) {
    final Map<String, Object?> famille = entree! as Map<String, Object?>;
    final FontLoader chargeur = FontLoader(famille['family']! as String);
    for (final Object? f in famille['fonts']! as List<Object?>) {
      chargeur.addFont(
        rootBundle.load((f! as Map<String, Object?>)['asset']! as String),
      );
    }
    await chargeur.load();
  }
}

PublicationCommunaute _publication() => DonneesCommunauteDemo.publications()
    .firstWhere((PublicationCommunaute p) => p.id == _ouverte);

/// La zone de l'ecran ou [cible] peut se voir : l'ecran, coupe par chaque
/// zone qui defile au-dessus d'elle.
Rect _zoneVisible(WidgetTester tester, Finder cible) {
  final Size ecran = tester.view.physicalSize / tester.view.devicePixelRatio;
  Rect zone = Offset.zero & ecran;
  cible.evaluate().single.visitAncestorElements((Element a) {
    if (a.widget is Scrollable) {
      final RenderBox boite = a.findRenderObject()! as RenderBox;
      zone = zone.intersect(boite.localToGlobal(Offset.zero) & boite.size);
    }
    return true;
  });
  return zone;
}

/// Vrai quand [cible] se voit en entier, sans defilement.
bool _visibleEntier(WidgetTester tester, Finder cible) {
  final Rect r = tester.getRect(cible);
  final Rect z = _zoneVisible(tester, cible);
  return r.top >= z.top - 0.5 &&
      r.bottom <= z.bottom + 0.5 &&
      r.left >= z.left - 0.5 &&
      r.right <= z.right + 0.5;
}

/// La hauteur de [cible] qui se voit, sans defilement.
double _hauteurVisible(WidgetTester tester, Finder cible) {
  final Rect r = tester.getRect(cible);
  final Rect z = _zoneVisible(tester, cible);
  final Rect vue = r.intersect(z);
  return vue.height < 0 ? 0 : vue.height;
}

Finder _texteDePublication() => find.descendant(
  of: find.byKey(PublicationDetail.cleDefilement),
  matching: find.text(_publication().texte),
);

Finder _categorie() => find.descendant(
  of: find.byKey(PublicationDetail.cleDefilement),
  matching: find.text(_publication().categorie.libelle),
);

void main() {
  setUpAll(_chargerPolicesDuDepot);

  group('R-01 : la publication garde la priorite de lecture', () {
    testWidgets('390 : texte, categorie et « Enregistrer la publication » au '
        'premier ecran, le composer defile avec la page', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 1aa1ffd6, le composer et le garde etaient fixes
      // sous la publication (45 % de la hauteur) ; la categorie et
      // « Enregistrer » sortaient de la vue.
      await monterCommunaute(
        tester,
        taille: const Size(390, 844),
        publicationId: _ouverte,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(PublicationDetail.cleTitre), findsOneWidget);
      expect(
        _visibleEntier(tester, find.byKey(PublicationDetail.cleTitre)),
        isTrue,
      );
      expect(_visibleEntier(tester, _texteDePublication()), isTrue);
      expect(_visibleEntier(tester, _categorie()), isTrue);
      expect(
        _visibleEntier(tester, find.byKey(PublicationDetail.cleEnregistrer)),
        isTrue,
        reason: '« Enregistrer la publication » se voit sans defiler',
      );
      // Le composer est dans la page, pas dans une zone fixe a lui.
      expect(
        find.ancestor(
          of: find.byKey(ComposerReponse.cleChamp),
          matching: find.byKey(PublicationDetail.cleDefilement),
        ),
        findsOneWidget,
      );
      // (i) est dans la rangee de l'auteur, pas sur une rangee a part.
      final Rect info = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
      );
      final Rect menu = tester.getRect(find.byKey(PublicationDetail.cleMenu));
      expect((info.center.dy - menu.center.dy).abs(), lessThan(24));
    });

    testWidgets('320 x 640, texte x2 : la publication se lit au premier '
        'ecran', (WidgetTester tester) async {
      // Contre-preuve : a 1aa1ffd6, ni le titre ni le texte de la
      // publication n'etaient visibles au premier ecran (tete de page, rangee
      // de (i), auteur, puis le composer fixe).
      await monterCommunaute(
        tester,
        taille: const Size(320, 640),
        echelleTexte: 2,
        publicationId: _ouverte,
      );
      expect(tester.takeException(), isNull);
      expect(
        _visibleEntier(tester, find.byKey(PublicationDetail.cleTitre)),
        isTrue,
        reason: 'le titre de la publication se voit sans defiler',
      );
      // Au moins deux lignes du texte (corps x2) se lisent sans defiler.
      expect(
        _hauteurVisible(tester, _texteDePublication()),
        greaterThanOrEqualTo(64),
      );
    });

    testWidgets('1440 : une reponse bloquee garde le champ entier visible, '
        '« Enregistrer » reste a sa place dans la page', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 1aa1ffd6, le composer avait son propre defilement
      // (45 % de la hauteur) : le haut du champ sortait de la vue et
      // « Enregistrer la publication » flottait au-dessus du champ.
      await monterCommunaute(
        tester,
        taille: const Size(1440, 900),
        publicationId: _ouverte,
        autres: <Override>[
          portGardePromotionProvider.overrideWithValue(
            DonneesCommunauteDemo.garde(),
          ),
        ],
      );
      await tester.enterText(
        find.byKey(ComposerReponse.cleChamp),
        DonneesCommunauteDemo.reponseAffilie,
      );
      await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
      expect(find.byKey(GardePromotion.cleBlocage), findsOneWidget);
      expect(
        _visibleEntier(tester, find.byKey(ComposerReponse.cleChamp)),
        isTrue,
        reason: 'le champ bloque se voit en entier',
      );
      expect(
        _visibleEntier(tester, find.byKey(GardePromotion.cleBlocage)),
        isTrue,
        reason: 'le verdict se voit en entier, sous le champ',
      );
      // « Enregistrer » et le champ defilent ensemble : la meme page.
      final ScrollableState pageEnregistrer = Scrollable.of(
        tester.element(find.byKey(PublicationDetail.cleEnregistrer)),
      );
      final ScrollableState pageGarde = Scrollable.of(
        tester.element(find.byKey(ComposerReponse.cleGarde)),
      );
      expect(identical(pageEnregistrer, pageGarde), isTrue);
      expect(
        tester.getRect(find.byKey(PublicationDetail.cleEnregistrer)).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(ComposerReponse.cleChamp)).top,
        ),
      );
    });
  });

  group('R-22 : la persistance des brouillons de FilDiscussion', () {
    testWidgets('le brouillon d une reponse se remet avec « Brouillon '
        'restaure », et reste jusqu a l accuse', (WidgetTester tester) async {
      // Contre-preuve : a 1aa1ffd6, ComposerReponse portait sa propre
      // persistance (onChanged, lecture a part) et ne disait jamais
      // « Brouillon restaure ».
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      const CleBrouillon cle = CleBrouillon(
        type: TypeObjetLie.publication,
        objetId: _ouverte,
      );
      await brouillons.enregistrer(cle, 'Je reprends ma reponse');
      final CommunauteMemoire memoire = memoireDemo(echecEnvoi: true);
      await monterCommunaute(
        tester,
        taille: const Size(1440, 900),
        port: memoire,
        publicationId: _ouverte,
        autres: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      expect(
        find.descendant(
          of: find.byKey(ComposerReponse.cleChamp),
          matching: find.text('Je reprends ma reponse'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ComposerReponse.cleBrouillonRestaure), findsOneWidget);

      // Une frappe : la phrase s'efface, le brouillon suit le champ.
      await tester.enterText(
        find.byKey(ComposerReponse.cleChamp),
        'Je reprends ma reponse, merci',
      );
      await tester.pump();
      expect(find.byKey(ComposerReponse.cleBrouillonRestaure), findsNothing);
      expect(
        (await brouillons.lire(cle))?.texte,
        'Je reprends ma reponse, merci',
      );

      // Envoi sans accuse : le champ se vide, le brouillon reste.
      await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
      expect(
        (await brouillons.lire(cle))?.texte,
        'Je reprends ma reponse, merci',
      );

      // Renvoi accuse : le brouillon est efface.
      memoire.echecEnvoi = false;
      await taper(tester, find.text(t.com.communaute.reponses.reessayer));
      expect(await brouillons.lire(cle), isNull);
    });
  });

  group('flux et composer', () {
    testWidgets('320 x 640, texte x2 : le flux ne deborde pas, ses tetes '
        'defilent avec lui', (WidgetTester tester) async {
      // Contre-preuve : a 1aa1ffd6, bandeau, categories, recherche et entree
      // du composer etaient fixes au-dessus et au-dessous de la liste : 37
      // de debordement.
      await monterCommunaute(
        tester,
        taille: const Size(320, 640),
        echelleTexte: 2,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.ancestor(
          of: find.byKey(SelecteurCategories.cle),
          matching: find.byKey(FluxPublications.cleDefilement),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byKey(EntreeNouvellePublication.cle),
          matching: find.byKey(FluxPublications.cleDefilement),
        ),
        findsOneWidget,
      );
      // L'entree du composer s'atteint en faisant defiler le flux.
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      expect(find.byType(ComposerPublication), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : (i) et (x) du composer sur la meme rangee', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 1aa1ffd6, (i) avait sa rangee a part, au-dessus de
      // « Nouvelle publication » et de (x).
      await monterCommunaute(tester, taille: const Size(390, 844));
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      final Rect info = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
      );
      final Rect fermer = tester.getRect(
        find.byKey(ComposerPublication.cleFermer),
      );
      expect((info.center.dy - fermer.center.dy).abs(), lessThan(1));
      expect(info.overlaps(fermer), isFalse);
    });

    testWidgets('1440 : le libelle de la recherche n est pas tronque', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 1aa1ffd6, « Rechercher une public... » a 1440.
      await monterCommunaute(tester, taille: const Size(1440, 900));
      final Iterable<RenderParagraph> paragraphes = tester
          .renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(ChampRecherche),
              matching: find.byType(RichText),
            ),
          );
      expect(paragraphes, isNotEmpty);
      for (final RenderParagraph p in paragraphes) {
        expect(
          p.didExceedMaxLines,
          isFalse,
          reason: '« ${p.text.toPlainText()} » est tronque',
        );
      }
    });
  });
}
