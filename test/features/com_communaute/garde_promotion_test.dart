// COM-COMU-2 : le garde anti-promotion (`CommunityPromotionGuard`), rendu
// dans la VRAIE coquille de l'enseignant et la VRAIE page de la Communaute.
//
// R-COM-05 : une fixture marque un contenu comme publicite : le composer
// affiche le motif et aucun faux succes. R-COM-06 : une fixture marque un
// lien comme affilie : le garde bloque avec le texte canonique. Et : la
// vente bloquee, les quatre etats de lien, jamais « Verifie », un contenu
// modifie repart, un garde sans contrat ne pretend rien, 390 / 768 / 1440,
// arabe (RTL), sombre et texte agrandi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/etat_lien.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/port_garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../support/garde_interface.dart';
import 'banc_communaute.dart';

const Size _telephone = Size(390, 844);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

List<Override> _avecGarde(PortGardePromotion garde) => <Override>[
  portGardePromotionProvider.overrideWithValue(garde),
];

/// Ouvre la nouvelle publication, choisit une categorie, ecrit [brouillon]
/// et touche « Publier ».
Future<void> _publier(
  WidgetTester tester, {
  required String titre,
  required String texte,
}) async {
  await taper(tester, find.byKey(EntreeNouvellePublication.cle));
  await taper(
    tester,
    find.byKey(
      ComposerPublication.cleCategorie(DonneesCommunauteDemo.pedagogie.id),
    ),
  );
  await tester.enterText(find.byKey(ComposerPublication.cleTitre), titre);
  await tester.enterText(find.byKey(ComposerPublication.cleTexte), texte);
  await taper(tester, find.byKey(ComposerPublication.clePublier));
}

Future<void> _publierMarque(WidgetTester tester, BrouillonMarqueDemo marque) =>
    _publier(tester, titre: marque.titre, texte: marque.texte);

/// Aucun texte « Verifie » nulle part a l'ecran (spec section 5.4).
void _jamaisVerifie() {
  expect(find.text('Vérifié'), findsNothing);
  expect(find.text('Lien vérifié'), findsNothing);
}

void main() {
  final g = t.com.communaute.garde;

  group('R-COM-06 : lien affilie bloque', () {
    for (final Size taille in <Size>[_telephone, _tablette, _bureau]) {
      testWidgets('${taille.width.toInt()} : le garde bloque avec le texte '
          'canonique, le motif et l etat du lien ; rien ne part', (
        WidgetTester tester,
      ) async {
        final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
        final BancCommunaute banc = await monterCommunaute(
          tester,
          taille: taille,
          autres: _avecGarde(garde),
        );
        await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);

        expect(garde.verifies, hasLength(1));
        expect(find.byKey(GardePromotion.cleBlocage), findsOneWidget);
        expect(find.byKey(GardePromotion.cleAvertissement), findsNothing);
        // Le texte exact de la spec, section 5.2 et section 22.
        expect(
          find.text(
            'Les liens affiliés ne sont pas autorisés dans la Communauté '
            'enseignants.',
          ),
          findsOneWidget,
        );
        expect(find.text(g.titreBlocage), findsOneWidget);
        expect(find.text('Motif : Lien affilié'), findsOneWidget);
        expect(find.text(g.consigneBlocage), findsOneWidget);
        expect(
          find.byKey(LigneEtatLien.cle(DonneesCommunauteDemo.lienAffilieDemo)),
          findsOneWidget,
        );
        expect(find.text('Lien commercial interdit'), findsOneWidget);
        // Le verdict est a l'ecran, pres de « Publier ».
        final Rect verdict = tester.getRect(
          find.byKey(GardePromotion.cleBlocage),
        );
        expect(verdict.top, lessThan(taille.height));
        expect(verdict.bottom, greaterThan(0));
        // Rien n'est parti, aucun succes.
        expect(banc.memoire.publicationsAcceptees, 0);
        expect(find.text(t.com.communaute.composer.confirmee), findsNothing);
        expect(find.byType(ComposerPublication), findsOneWidget);
        expect(find.byType(PublicationDetail), findsNothing);
        verifierUnSeulBoutonPlein(tester);
        _jamaisVerifie();
        expect(tester.takeException(), isNull);
        await demonter(tester);
      });
    }

    testWidgets('« Publier » a nouveau sans rien changer : toujours bloque', (
      WidgetTester tester,
    ) async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      final BancCommunaute banc = await monterCommunaute(
        tester,
        autres: _avecGarde(garde),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);
      await taper(tester, find.byKey(ComposerPublication.clePublier));
      expect(garde.verifies, hasLength(2));
      expect(find.byKey(GardePromotion.cleBlocage), findsOneWidget);
      expect(banc.memoire.publicationsAcceptees, 0);
      await demonter(tester);
    });

    testWidgets('le texte modifie apres un blocage : le verdict perime '
        'disparait aussitot, sans rien envoyer', (WidgetTester tester) async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      final BancCommunaute banc = await monterCommunaute(
        tester,
        autres: _avecGarde(garde),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);
      expect(find.byKey(ComposerPublication.cleVerdict), findsOneWidget);
      expect(find.text('Lien commercial interdit'), findsOneWidget);

      // La personne retire le lien, sans toucher « Publier » : la carte ne
      // doit plus contredire ce qui est ecrit.
      await tester.enterText(
        find.byKey(ComposerPublication.cleTexte),
        "J'utilise un lecteur audio pour faire réécouter les sourates.",
      );
      await tester.pump();

      expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
      expect(find.byKey(GardePromotion.cleBlocage), findsNothing);
      expect(find.text('Lien commercial interdit'), findsNothing);
      expect(
        find.byKey(LigneEtatLien.cle(DonneesCommunauteDemo.lienAffilieDemo)),
        findsNothing,
      );
      // Rien n'est reparti tout seul : seul « Publier » relance le garde.
      expect(garde.verifies, hasLength(1));
      expect(banc.memoire.publicationsAcceptees, 0);
      expect(find.byType(ComposerPublication), findsOneWidget);
      await demonter(tester);
    });

    testWidgets('une autre categorie apres un blocage : le verdict perime '
        'disparait aussi', (WidgetTester tester) async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      await monterCommunaute(tester, autres: _avecGarde(garde));
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);
      expect(find.byKey(ComposerPublication.cleVerdict), findsOneWidget);
      final String autre = DonneesCommunauteDemo.categories
          .firstWhere((c) => c.id != DonneesCommunauteDemo.pedagogie.id)
          .id;
      await taper(tester, find.byKey(ComposerPublication.cleCategorie(autre)));
      expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
      expect(garde.verifies, hasLength(1));
      await demonter(tester);
    });

    testWidgets('le lien retire, la publication repart : elle est confirmee '
        'et le verdict disparait', (WidgetTester tester) async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      final BancCommunaute banc = await monterCommunaute(
        tester,
        autres: _avecGarde(garde),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);
      expect(find.byKey(GardePromotion.cleBlocage), findsOneWidget);

      await tester.enterText(
        find.byKey(ComposerPublication.cleTexte),
        "J'utilise un lecteur audio pour faire réécouter les sourates.",
      );
      await taper(tester, find.byKey(ComposerPublication.clePublier));

      expect(garde.verifies, hasLength(2));
      expect(banc.memoire.publicationsAcceptees, 1);
      expect(find.byType(ComposerPublication), findsNothing);
      expect(find.byKey(GardePromotion.cleBlocage), findsNothing);
      expect(find.text(t.com.communaute.composer.confirmee), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await demonter(tester);
    });
  });

  group('R-COM-05 : publicite retenue', () {
    testWidgets('le composer affiche le motif et l avertissement exact ; '
        'aucun faux succes ; les etats de lien', (WidgetTester tester) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _bureau,
        autres: _avecGarde(DonneesCommunauteDemo.garde()),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonPublicite);

      expect(find.byKey(GardePromotion.cleAvertissement), findsOneWidget);
      expect(find.byKey(GardePromotion.cleBlocage), findsNothing);
      expect(
        find.text(
          'Cette publication semble contenir une promotion commerciale. '
          "Retirez le lien, le code ou l'offre avant de publier.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(GardePromotion.cleMotif), findsOneWidget);
      expect(find.text('Motif : Publicité'), findsOneWidget);
      expect(find.text(g.titreAvertissement), findsOneWidget);
      // Trois liens, trois etats, chacun avec son mot.
      for (final (String adresse, String etat) in <(String, String)>[
        (DonneesCommunauteDemo.lienNonQualifie, 'Lien non vérifié'),
        (DonneesCommunauteDemo.lienInterne, 'Lien interne Rewayah'),
        (DonneesCommunauteDemo.lienRessource, 'Ressource pédagogique externe'),
      ]) {
        final Finder ligne = find.byKey(LigneEtatLien.cle(adresse));
        expect(ligne, findsOneWidget, reason: adresse);
        expect(
          find.descendant(of: ligne, matching: find.text(etat)),
          findsOneWidget,
          reason: etat,
        );
        // La ligne se lit en une phrase : l'adresse, puis l'etat.
        expect(
          tester.getSemantics(ligne).label,
          t.com.communaute.lien.semantique(adresse: adresse, etat: etat),
        );
      }
      expect(banc.memoire.publicationsAcceptees, 0);
      expect(find.text(t.com.communaute.composer.confirmee), findsNothing);
      expect(find.byType(ComposerPublication), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      _jamaisVerifie();
      await demonter(tester);
    });
  });

  group('vente bloquee', () {
    testWidgets('le texte canonique de la vente, le motif, aucun lien', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _tablette,
        autres: _avecGarde(DonneesCommunauteDemo.garde()),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonVente);

      expect(find.byKey(GardePromotion.cleBlocage), findsOneWidget);
      expect(
        find.text(
          "La vente de produits ou de services n'est pas autorisée dans cet "
          'espace.',
        ),
        findsOneWidget,
      );
      expect(find.text('Motif : Vente non autorisée'), findsOneWidget);
      expect(find.text(g.liensTitre), findsNothing);
      expect(banc.memoire.publicationsAcceptees, 0);
      await demonter(tester);
    });
  });

  group('aide et garde sans verdict', () {
    testWidgets('le composer rappelle la politique : textes exacts de l aide '
        'et « Voir les regles »', (WidgetTester tester) async {
      await monterCommunaute(tester);
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      final Finder aide = find.byKey(GardePromotion.cleAide);
      expect(aide, findsOneWidget);
      expect(
        find.descendant(
          of: aide,
          matching: find.text('Partage pédagogique uniquement'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Aucune publicité. Aucun lien affilié. Aucune vente.'),
        findsOneWidget,
      );
      expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
      await taper(tester, find.byKey(GardePromotion.cleVoirRegles));
      expect(find.text('Aucune sollicitation commerciale'), findsOneWidget);
      await demonter(tester);
    });

    testWidgets('un contenu sans marque part sans verdict', (
      WidgetTester tester,
    ) async {
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      final BancCommunaute banc = await monterCommunaute(
        tester,
        autres: _avecGarde(garde),
      );
      await _publier(
        tester,
        titre: 'Réciter en binôme',
        texte: 'Je fais réciter les élèves deux par deux.',
      );
      expect(garde.verifies, hasLength(1));
      expect(banc.memoire.publicationsAcceptees, 1);
      expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await demonter(tester);
    });

    testWidgets('garde sans contrat (port neutre, COM-BR-07) : aucun verdict '
        'invente, aucun « Verifie » ; la publication part au serveur', (
      WidgetTester tester,
    ) async {
      // Le banc ne surcharge pas le garde : c'est celui de la production.
      final BancCommunaute banc = await monterCommunaute(tester);
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);
      expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
      expect(find.byKey(GardePromotion.cleBlocage), findsNothing);
      expect(banc.memoire.publicationsAcceptees, 1);
      _jamaisVerifie();
      await tester.pump(const Duration(seconds: 4));
      await demonter(tester);
    });

    testWidgets('garde en panne (revue COM-R, R-17) : la publication est '
        'retenue, « Réessayer » relance le garde', (WidgetTester tester) async {
      // Contre-preuve : avant R-17, toute erreur du garde laissait partir la
      // publication (`publicationsAcceptees` valait 1).
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde()
        ..echec = true;
      final BancCommunaute banc = await monterCommunaute(
        tester,
        autres: _avecGarde(garde),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonVente);
      expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
      expect(banc.memoire.publicationsAcceptees, 0);
      expect(find.text(g.panne), findsOneWidget);
      expect(find.byKey(ComposerPublication.cleReessayerGarde), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);

      // Le garde revient : « Réessayer » le relance, il bloque la vente.
      garde.echec = false;
      await taper(tester, find.byKey(ComposerPublication.cleReessayerGarde));
      expect(find.byKey(GardePromotion.cleBlocage), findsOneWidget);
      expect(find.text(g.panne), findsNothing);
      expect(banc.memoire.publicationsAcceptees, 0);
      await tester.pump(const Duration(seconds: 4));
      await demonter(tester);
    });
  });

  group('rendu', () {
    testWidgets('arabe (RTL) a 390 : le blocage se lit, l adresse reste de '
        'gauche a droite', (WidgetTester tester) async {
      await monterCommunaute(
        tester,
        arabe: true,
        autres: _avecGarde(DonneesCommunauteDemo.garde()),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonAffilie);
      final Finder blocage = find.byKey(GardePromotion.cleBlocage);
      expect(blocage, findsOneWidget);
      expect(Directionality.of(tester.element(blocage)), TextDirection.rtl);
      expect(find.text(t.com.communaute.garde.bloqueAffilie), findsOneWidget);
      expect(
        find.text(t.com.communaute.lien.commercialInterdit),
        findsOneWidget,
      );
      final Text adresse = tester.widget<Text>(
        find.text(DonneesCommunauteDemo.lienAffilieDemo),
      );
      expect(adresse.textDirection, TextDirection.ltr);
      expect(tester.takeException(), isNull);
      await demonter(tester);
    });

    testWidgets('sombre, texte x2, 390 : aucun debordement', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(
        tester,
        luminosite: Brightness.dark,
        echelleTexte: 2,
        autres: _avecGarde(DonneesCommunauteDemo.garde()),
      );
      await _publierMarque(tester, DonneesCommunauteDemo.brouillonPublicite);
      expect(find.byKey(GardePromotion.cleAvertissement), findsOneWidget);
      expect(tester.takeException(), isNull);
      await demonter(tester);
    });
  });

  group('demonstration', () {
    test('fixtures (spec section 26) : 2 publications bloquees, dont 1 lien '
        'affilie et 1 vente ; 1 publicite ; les 4 etats de lien', () {
      const List<BrouillonMarqueDemo> marques =
          DonneesCommunauteDemo.brouillonsMarques;
      final List<VerdictPromotion> verdicts = <VerdictPromotion>[
        for (final BrouillonMarqueDemo m in marques) m.verdict.verdict,
      ];
      expect(verdicts.where((VerdictPromotion v) => v.bloque), hasLength(2));
      expect(verdicts, contains(VerdictPromotion.lienAffilie));
      expect(verdicts, contains(VerdictPromotion.vente));
      expect(verdicts, contains(VerdictPromotion.avertissement));
      final Set<EtatLien> etats = <EtatLien>{
        for (final BrouillonMarqueDemo m in marques)
          for (final LienAnalyse l in m.verdict.liens) l.etat,
      };
      expect(etats, EtatLien.values.toSet());
      expect(DonneesCommunauteDemo.etatsLiens.values.toSet(), etats);
    });
  });
}
