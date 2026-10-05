// COM-RC tour 4, lot G (contre-verification COM-R-2, section 6), dans la
// VRAIE coquille de l'enseignant :
//
// - R-01, reserves : sous une reponse, le verdict du garde porte le texte
//   exact de la spec (section 5.2 et 22), sans titre invente ; un refus du
//   serveur (`ContenuRefuse`) se dit comme un refus, avec son motif, jamais
//   comme un echec a « Renvoyer » ;
// - N-2 : Ctrl+Entree (Cmd+Entree) envoie depuis le composer de reponse ;
// - N-5 : a 1440, sans publication, un seul etat vide, au centre ;
// - R-23 : publication_detail, annonces_de_classe et la page de
//   publication de l'enseignant passent par `VueEtatCommunication
//   .depuisErreur`, plus aucune recopie.
//
// Chaque test dit sa contre-preuve : ce qui echouait a `022cc31e`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_communaute/communaute_page.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/etat_lien.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/port_garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/reponses.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../support/garde_interface.dart';
import 'banc_communaute.dart';

const Size _bureau = Size(1440, 900);
const String _ouverte = 'pub-memorisation';

/// Le refus que le serveur rend pour une reponse ou une publication.
const VerificationPromotion _refusVente = VerificationPromotion(
  verdict: VerdictPromotion.vente,
  motif: MotifSignalement.venteNonAutorisee,
  liens: <LienAnalyse>[
    LienAnalyse(
      adresse: 'https://boutique.exemple/cours',
      etat: EtatLien.commercialInterdit,
    ),
  ],
);

/// Une Communaute en memoire dont le serveur refuse les envois au nom de la
/// politique, apres [echecsAvant] envois sans accuse.
class _CommunauteQuiRefuse implements PortCommunaute {
  _CommunauteQuiRefuse({this.echecsAvant = 0});

  final CommunauteMemoire _memoire = memoireDemo();
  int echecsAvant;
  int refus = 0;

  @override
  Future<CapacitesCommunaute> capacites() => _memoire.capacites();

  @override
  Future<List<CategorieCommunaute>> categories() => _memoire.categories();

  @override
  Future<List<PublicationCommunaute>> publications({
    String? categorieId,
    String recherche = '',
  }) => _memoire.publications(categorieId: categorieId, recherche: recherche);

  @override
  Future<PublicationCommunaute> publication(String publicationId) =>
      _memoire.publication(publicationId);

  @override
  Future<List<ReponseCommunaute>> reponses(String publicationId) =>
      _memoire.reponses(publicationId);

  Never _refuser() {
    if (echecsAvant > 0) {
      echecsAvant--;
      throw StateError('accuse non recu');
    }
    refus++;
    throw const ContenuRefuse(_refusVente);
  }

  @override
  Future<PublicationCommunaute> publier(
    BrouillonPublication brouillon, {
    required String cleIdempotence,
  }) async => _refuser();

  @override
  Future<ReponseCommunaute> repondre({
    required String publicationId,
    required String texte,
    required String cleIdempotence,
  }) async => _refuser();
}

Future<void> _ouvrir(WidgetTester tester, String id) =>
    taper(tester, find.byKey(FluxPublications.cleCarte(id)));

Future<void> _repondre(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(ComposerReponse.cleChamp), texte);
  await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
}

Finder _dansGarde(Finder cible) =>
    find.descendant(of: find.byKey(ComposerReponse.cleGarde), matching: cible);

void main() {
  final c = t.com.communaute;
  final g = c.garde;

  group('R-01 : textes exacts de la spec sous une reponse', () {
    test('l avertissement d une reponse est celui du section 5.2, le seul '
        'nom adapte', () {
      // Contre-preuve : a 022cc31e, « ... avant d'envoyer. ».
      expect(
        g.reponse.avertissement,
        g.avertissement.replaceFirst('Cette publication', 'Cette réponse'),
      );
    });

    testWidgets('1440 : un lien affilie en reponse est bloque avec le texte '
        'exact, sans titre invente', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, le blocage portait le titre « Réponse
      // bloquée », absent de la spec.
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
      await monterCommunaute(
        tester,
        taille: _bureau,
        autres: <Override>[portGardePromotionProvider.overrideWithValue(garde)],
      );
      await _ouvrir(tester, _ouverte);
      await _repondre(tester, DonneesCommunauteDemo.reponseAffilie);
      expect(_dansGarde(find.byKey(GardePromotion.cleBlocage)), findsOneWidget);
      expect(find.text('Réponse bloquée'), findsNothing);
      expect(find.text(g.titreBlocage), findsNothing);
      // Le texte exact est l'en-tete du verdict, dit une seule fois.
      expect(_dansGarde(find.text(g.bloqueAffilie)), findsOneWidget);
      expect(
        tester
            .getSemantics(_dansGarde(find.text(g.bloqueAffilie)))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(_dansGarde(find.byKey(GardePromotion.cleMotif)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('R-01 : un refus du serveur est un refus, avec son motif', () {
    testWidgets('1440 : premier envoi refuse, la reponse revient dans le '
        'champ avec le refus et son motif ; aucun « Renvoyer »', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 022cc31e, tout echec de `repondre` donnait la
      // ligne « pas encore confirmee » et « Renvoyer la réponse ».
      final _CommunauteQuiRefuse port = _CommunauteQuiRefuse();
      await monterCommunaute(tester, taille: _bureau, port: port);
      await _ouvrir(tester, _ouverte);
      const String texte = 'Je vends mes cours particuliers, contactez-moi.';
      await _repondre(tester, texte);

      expect(port.refus, 1);
      expect(find.text(c.reponses.reessayer), findsNothing);
      expect(find.text(c.reponses.nonConfirmee), findsNothing);
      expect(_dansGarde(find.byKey(GardePromotion.cleBlocage)), findsOneWidget);
      expect(_dansGarde(find.text(g.bloqueVente)), findsOneWidget);
      expect(
        _dansGarde(
          find.text(g.motif(motif: MotifSignalement.venteNonAutorisee.libelle)),
        ),
        findsOneWidget,
      );
      // Rien n'est perdu : le texte est de nouveau dans le champ.
      expect(
        find.descendant(
          of: find.byKey(ComposerReponse.cleChamp),
          matching: find.text(texte),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : un renvoi refuse dit le refus et son motif sur la '
        'ligne, sans « Renvoyer »', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, le renvoi refuse redonnait « Renvoyer
      // la réponse », sans motif.
      final _CommunauteQuiRefuse port = _CommunauteQuiRefuse(echecsAvant: 1);
      await monterCommunaute(tester, taille: _bureau, port: port);
      await _ouvrir(tester, _ouverte);
      await _repondre(tester, 'Mes fiches sont en vente, écrivez-moi.');
      // Le premier envoi n'a pas d'accuse : un echec ordinaire.
      expect(find.text(c.reponses.nonConfirmee), findsOneWidget);
      await taper(tester, find.text(c.reponses.reessayer));

      expect(port.refus, 1);
      expect(find.text(c.reponses.refusee), findsOneWidget);
      expect(find.text(c.reponses.reessayer), findsNothing);
      expect(find.text(c.reponses.nonConfirmee), findsNothing);
      final Finder refus = find.byWidgetPredicate(
        (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              'communaute-reponse-refus-',
            ),
      );
      expect(refus, findsOneWidget);
      expect(
        find.descendant(of: refus, matching: find.text(g.bloqueVente)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: refus,
          matching: find.byKey(GardePromotion.cleMotif),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : une publication refusee par le serveur montre le '
        'verdict et son motif, pas « non publiee »', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 022cc31e, le composer disait l'echec generique
      // d'envoi (`composer.erreurEnvoi`).
      final _CommunauteQuiRefuse port = _CommunauteQuiRefuse();
      await monterCommunaute(tester, taille: _bureau, port: port);
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      await taper(
        tester,
        find.byKey(
          ComposerPublication.cleCategorie(DonneesCommunauteDemo.pedagogie.id),
        ),
      );
      await tester.enterText(
        find.byKey(ComposerPublication.cleTitre),
        'Cours particuliers',
      );
      await tester.enterText(
        find.byKey(ComposerPublication.cleTexte),
        'Je propose des cours payants.',
      );
      await taper(tester, find.byKey(ComposerPublication.clePublier));

      expect(port.refus, 1);
      expect(find.byKey(ComposerPublication.cleVerdict), findsOneWidget);
      expect(find.text(g.bloqueVente), findsOneWidget);
      expect(find.byKey(GardePromotion.cleMotif), findsOneWidget);
      expect(find.text(c.composer.erreurEnvoi), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('N-2 : Ctrl+Entree dans le composer de reponse', () {
    for (final (String nom, LogicalKeyboardKey modificateur) cas
        in <(String, LogicalKeyboardKey)>[
          ('Ctrl', LogicalKeyboardKey.controlLeft),
          ('Cmd', LogicalKeyboardKey.metaLeft),
        ]) {
      testWidgets('1440 : ${cas.$1}+Entree envoie, Entree seule non', (
        WidgetTester tester,
      ) async {
        // Contre-preuve : a 022cc31e, le raccourci n'existait pas dans ce
        // quatrieme composer : le garde n'etait jamais appele.
        final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
        final BancCommunaute banc = await monterCommunaute(
          tester,
          taille: _bureau,
          autres: <Override>[
            portGardePromotionProvider.overrideWithValue(garde),
          ],
        );
        await _ouvrir(tester, _ouverte);
        await taper(tester, find.byKey(ComposerReponse.cleChamp));
        await tester.enterText(
          find.byKey(ComposerReponse.cleChamp),
          'Merci pour ce partage.',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(garde.reponsesVerifiees, isEmpty);

        await tester.sendKeyDownEvent(cas.$2);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(cas.$2);
        await tester.pumpAndSettle();
        expect(garde.reponsesVerifiees, hasLength(1));
        expect(banc.memoire.reponsesAcceptees, 1);
        expect(tester.takeException(), isNull);
        await demonter(tester);
      });
    }
  });

  group('N-5 : a 1440, sans publication, un seul etat au centre', () {
    testWidgets('le centre dit le vide, le flux ne le repete pas', (
      WidgetTester tester,
    ) async {
      // Contre-preuve : a 022cc31e, la colonne centrale etait vide (un
      // `SizedBox.shrink`), sans titre ni etat.
      await monterCommunaute(
        tester,
        taille: _bureau,
        port: memoireDemo(vide: true),
      );
      final Finder centre = find.byKey(CommunautePage.cleAucuneSelection);
      expect(
        find.descendant(of: centre, matching: find.text(c.videTitre)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: centre, matching: find.text(c.videToutes)),
        findsOneWidget,
      );
      // Un seul etat vide a l'ecran, aucun « Choisissez une publication ».
      expect(find.text(c.videTitre), findsOneWidget);
      expect(find.text(c.publication.choisirTitre), findsNothing);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is VueEtatCommunication && w.etat == EtatCommunication.vide,
        ),
        findsOneWidget,
      );
      // Au premier ecran, sans defilement : le titre est dans la vue.
      final Rect titre = tester.getRect(
        find.descendant(of: centre, matching: find.text(c.videTitre)),
      );
      expect(titre.top, greaterThanOrEqualTo(0));
      expect(titre.bottom, lessThanOrEqualTo(_bureau.height));
      expect(tester.takeException(), isNull);
    });
  });

  group('R-23 : plus aucune recopie de la logique d erreur', () {
    test('les trois ecrans passent par VueEtatCommunication.depuisErreur', () {
      // Contre-preuve : a 022cc31e, chacun recomposait « hors ligne ou
      // echec » a la main (`EtatCommunication.horsLigne`).
      for (final String fichier in <String>[
        'lib/features/com_communaute/publication_detail.dart',
        'lib/features/com_annonces/annonces_de_classe.dart',
        'lib/features/com_annonces/publier_annonce_classe_page.dart',
      ]) {
        final String source = File(fichier).readAsStringSync();
        expect(
          source.contains('EtatCommunication.horsLigne'),
          isFalse,
          reason: fichier,
        );
        expect(
          source.contains('EtatCommunication.indisponible'),
          isFalse,
          reason: fichier,
        );
        expect(
          source.contains('VueEtatCommunication.depuisErreur('),
          isTrue,
          reason: fichier,
        );
      }
    });
  });
}
