// COM-RC, lot B (revue croisee COM-R du 05/10) : les corrections de la
// Communaute enseignants, rendues dans la VRAIE coquille de l'enseignant.
//
// - R-01 : une reponse passe par le garde anti-promotion avant l'envoi ; un
//   lien affilie poste en reponse est bloque, rien ne part ; la politique
//   est rappelee sous le composer de reponse.
// - R-13 : le menu « ... » est au bord de fin de la carte ; un seul etat
//   vide quand aucune publication n'existe.
// - R-14 : jamais une majuscule au milieu d'une phrase (« · »).
// - R-17 : un garde en panne retient la reponse et propose « Réessayer ».
// - R-18 : cle d'idempotence au signalement, « deja signale » rendu par le
//   port.
//
// Chaque test dit sa contre-preuve : ce qui echouait avant la correction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart'
    show dateDeLAppareil;
import 'package:rewayah_academy/features/com_communaute/feuille_signalement_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/port_garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/com_communaute/reponses.dart';
import 'package:rewayah_academy/features/com_studio/activite.dart'
    show dansPhrase;
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../support/garde_interface.dart';
import 'banc_communaute.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const String _ouverte = 'pub-memorisation';

List<Override> _avecGarde(PortGardePromotion garde) => <Override>[
  portGardePromotionProvider.overrideWithValue(garde),
];

Future<void> _ouvrir(WidgetTester tester, String id) =>
    taper(tester, find.byKey(FluxPublications.cleCarte(id)));

Future<void> _repondre(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(ComposerReponse.cleChamp), texte);
  await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
}

Finder _dansGarde(Finder cible) =>
    find.descendant(of: find.byKey(ComposerReponse.cleGarde), matching: cible);

ObjetLie _objetOuvert() => DonneesCommunauteDemo.publications()
    .firstWhere((PublicationCommunaute p) => p.id == _ouverte)
    .objet;

/// Une moderation dont le premier signalement ne recoit pas d'accuse, puis
/// qui accuse ; elle note chaque cle recue.
class _ModerationInstable implements PortModeration {
  int echecsRestants = 1;
  final List<String> cles = <String>[];

  @override
  Future<CapacitesModeration> capacites() async =>
      CapacitesModeration(peutSignaler: true);

  @override
  Future<ResultatSignalement> signaler({
    required ObjetLie objet,
    required MotifSignalement motif,
    required String cleIdempotence,
    String? precision,
  }) async {
    cles.add(cleIdempotence);
    if (echecsRestants > 0) {
      echecsRestants--;
      throw StateError('accuse non recu');
    }
    return ResultatSignalement.enregistre;
  }

  @override
  Future<Set<ObjetLie>> mesSignalements() async => <ObjetLie>{};

  @override
  Future<List<ElementModeration>> file() async => const <ElementModeration>[];

  @override
  Future<void> appliquer({
    required String signalementId,
    required ActionModeration action,
  }) async {}
}

void main() {
  final c = t.com.communaute;
  final g = c.garde;

  group('R-01 : une reponse passe par le garde anti-promotion', () {
    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('${taille.width.toInt()} : un lien affilie en reponse est '
          'bloque, rien ne part ; un texte corrige repart', (
        WidgetTester tester,
      ) async {
        // Contre-preuve : avant R-01, la reponse partait directement par
        // `PortCommunaute.repondre` (reponsesAcceptees valait 1) et le
        // composer de reponse ne montrait ni garde ni politique.
        final GardePromotionFixtures garde = DonneesCommunauteDemo.garde();
        final BancCommunaute banc = await monterCommunaute(
          tester,
          taille: taille,
          autres: _avecGarde(garde),
        );
        await _ouvrir(tester, _ouverte);
        // La politique est rappelee sous le composer, avant tout envoi.
        expect(_dansGarde(find.byKey(GardePromotion.cleAide)), findsOneWidget);
        expect(_dansGarde(find.text(c.regles.titre)), findsOneWidget);

        await _repondre(tester, DonneesCommunauteDemo.reponseAffilie);
        expect(garde.reponsesVerifiees, hasLength(1));
        expect(garde.reponsesVerifiees.single.publicationId, _ouverte);
        expect(banc.memoire.reponsesAcceptees, 0);
        expect(
          _dansGarde(find.byKey(GardePromotion.cleBlocage)),
          findsOneWidget,
        );
        // COM-RC tour 4 : aucun titre invente, le texte exact seulement.
        expect(find.text(g.titreBlocage), findsNothing);
        expect(find.text(g.bloqueAffilie), findsOneWidget);
        // Le texte reste dans le champ : rien n'est perdu, rien n'est parti.
        expect(
          find.descendant(
            of: find.byKey(ComposerReponse.cleChamp),
            matching: find.text(DonneesCommunauteDemo.reponseAffilie),
          ),
          findsOneWidget,
        );
        expect(find.text(c.reponses.enCours), findsNothing);
        verifierUnSeulBoutonPlein(tester);

        // Le lien retire : le verdict perime disparait, la reponse part.
        await _repondre(tester, 'Merci, je vais essayer cette méthode.');
        expect(find.byKey(GardePromotion.cleBlocage), findsNothing);
        expect(banc.memoire.reponsesAcceptees, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('garde sans contrat (port neutre) : la reponse part, le '
        'serveur reste seul juge', (WidgetTester tester) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _bureau,
      );
      await _ouvrir(tester, _ouverte);
      await _repondre(tester, DonneesCommunauteDemo.reponseAffilie);
      expect(find.byKey(GardePromotion.cleBlocage), findsNothing);
      expect(banc.memoire.reponsesAcceptees, 1);
    });

    testWidgets('R-17 : garde en panne, la reponse est retenue et '
        '« Réessayer » relance le garde', (WidgetTester tester) async {
      // Contre-preuve : avant R-01 et R-17, aucune verification n'avait lieu
      // et la reponse partait.
      final GardePromotionFixtures garde = DonneesCommunauteDemo.garde()
        ..echec = true;
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _bureau,
        autres: _avecGarde(garde),
      );
      await _ouvrir(tester, _ouverte);
      await _repondre(tester, DonneesCommunauteDemo.reponseAffilie);
      expect(banc.memoire.reponsesAcceptees, 0);
      expect(find.byKey(ComposerReponse.clePanne), findsOneWidget);
      expect(find.text(g.panne), findsOneWidget);

      garde.echec = false;
      await taper(tester, find.byKey(ComposerReponse.cleReessayerGarde));
      expect(find.byKey(ComposerReponse.clePanne), findsNothing);
      expect(_dansGarde(find.byKey(GardePromotion.cleBlocage)), findsOneWidget);
      expect(banc.memoire.reponsesAcceptees, 0);
    });

    for (final (Brightness luminosite, bool arabe) in <(Brightness, bool)>[
      (Brightness.light, false),
      (Brightness.dark, false),
      (Brightness.light, true),
    ]) {
      testWidgets(
        '320 x 844, texte x2 (${luminosite.name}${arabe ? ', arabe' : ''})'
        ' : le blocage d une reponse se lit sans debordement',
        (WidgetTester tester) async {
          await monterCommunaute(
            tester,
            taille: const Size(320, 844),
            echelleTexte: 2,
            luminosite: luminosite,
            arabe: arabe,
            // L'adresse de la publication : le detail s'ouvre directement.
            publicationId: _ouverte,
            autres: _avecGarde(DonneesCommunauteDemo.garde()),
          );
          expect(tester.takeException(), isNull);
          await tester.enterText(
            find.byKey(ComposerReponse.cleChamp),
            DonneesCommunauteDemo.reponseAffilie,
          );
          await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
          expect(
            _dansGarde(find.byKey(GardePromotion.cleBlocage)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('R-13 : menu en bord de carte, un seul etat vide', () {
    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('${taille.width.toInt()} : le menu « ... » est au bord de '
          'fin, pas colle au nom', (WidgetTester tester) async {
        // Contre-preuve : avant R-13, le menu suivait le nom (`fin:` de
        // `AvatarNom`, nom en `Flexible`) : plusieurs centaines de points le
        // separaient du bord a 1440.
        await monterCommunaute(tester, taille: taille);
        await _ouvrir(tester, _ouverte);
        final double finMenu = tester
            .getTopRight(find.byKey(PublicationDetail.cleMenu))
            .dx;
        final double finCarte = tester
            .getTopRight(find.byType(PublicationDetail))
            .dx;
        expect(finCarte - finMenu, lessThanOrEqualTo(1));
        // Meme regle pour une reponse.
        final Finder ligne = find.byKey(FilReponses.cleReponse('rep-youssef'));
        final double finMenuReponse = tester
            .getTopRight(
              find.descendant(of: ligne, matching: find.byType(MenuActions)),
            )
            .dx;
        expect(
          tester.getTopRight(ligne).dx - finMenuReponse,
          lessThanOrEqualTo(1),
        );
      });
    }

    testWidgets('1440, aucune publication : un seul etat vide, pas de '
        '« Choisissez une publication » a cote', (WidgetTester tester) async {
      // Contre-preuve : avant R-13, le centre ajoutait son propre etat vide
      // a cote de celui du flux.
      await monterCommunaute(
        tester,
        taille: _bureau,
        port: memoireDemo(vide: true),
      );
      expect(find.text(c.videTitre), findsOneWidget);
      expect(find.text(c.publication.choisirTitre), findsNothing);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is VueEtatCommunication && w.etat == EtatCommunication.vide,
        ),
        findsOneWidget,
      );
    });

    testWidgets('1440, des publications : le centre invite a en choisir une', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, taille: _bureau);
      expect(find.text(c.publication.choisirTitre), findsOneWidget);
    });
  });

  group('R-14 : jamais de majuscule au milieu d une phrase', () {
    test('la ligne de l auteur separe la fonction et le moment par « · »', () {
      final DateTime maintenant = DateTime.utc(2026, 10, 5, 12);
      final String ligne = ligneAuteurCommunaute(
        'Enseignante, Classe An-Nour',
        momentCommunaute(
          maintenant.subtract(const Duration(hours: 2)),
          maintenant,
        ),
      );
      // Contre-preuve : « Enseignante, Classe An-Nour, Il y a 2 h ».
      expect(ligne, 'Enseignante, Classe An-Nour · Il y a 2 h');
      expect(ligne, isNot(contains(', Il y a')));
    });

    test('une date dans une phrase commence par une minuscule', () {
      final String date = dateDeLAppareil(DateTime(2026, 10, 6));
      // Contre-preuve : « Échéance le Mardi 6 octobre ».
      expect(
        t.com.studio.aujourdhui.echeance(date: dansPhrase(date)),
        'Échéance le mardi 6 octobre',
      );
      expect(dansPhrase(''), '');
    });
  });

  group(
    'R-18 : signalement idempotent, « deja signale » rendu par le port',
    () {
      test('la meme cle ne cree jamais deux signalements ; un autre '
          'signalement du meme contenu rend « deja signale »', () async {
        final ModerationDemo moderation = ModerationDemo();
        final ObjetLie objet = _objetOuvert();
        expect(
          await moderation.signaler(
            objet: objet,
            motif: MotifSignalement.publicite,
            cleIdempotence: 'sig-1',
          ),
          ResultatSignalement.enregistre,
        );
        expect(
          await moderation.signaler(
            objet: objet,
            motif: MotifSignalement.publicite,
            cleIdempotence: 'sig-1',
          ),
          ResultatSignalement.enregistre,
        );
        expect(moderation.signalements, hasLength(1));
        expect(
          await moderation.signaler(
            objet: objet,
            motif: MotifSignalement.autre,
            cleIdempotence: 'sig-2',
          ),
          ResultatSignalement.dejaSignale,
        );
        expect(moderation.signalements, hasLength(1));
        expect(await moderation.mesSignalements(), contains(objet));
      });

      testWidgets('un signalement fait avant la visite se dit, le menu ne le '
          'repropose pas', (WidgetTester tester) async {
        // Contre-preuve : avant R-18, l'etat « signalee » ne vivait qu'en
        // memoire de page ; une nouvelle visite reproposait « Signaler ».
        await monterCommunaute(
          tester,
          taille: _bureau,
          moderation: ModerationDemo(dejaSignales: <ObjetLie>{_objetOuvert()}),
        );
        await _ouvrir(tester, _ouverte);
        expect(find.byKey(PublicationDetail.cleSignalee), findsOneWidget);
        expect(find.byKey(PublicationDetail.cleMenu), findsNothing);
      });

      testWidgets('un renvoi apres un echec rejoue la meme cle', (
        WidgetTester tester,
      ) async {
        final _ModerationInstable moderation = _ModerationInstable();
        await monterCommunaute(tester, taille: _bureau, moderation: moderation);
        await _ouvrir(tester, _ouverte);
        await taper(tester, find.byKey(PublicationDetail.cleMenu));
        await taper(tester, find.text(c.publication.signaler));
        await taper(
          tester,
          find.byKey(
            FeuilleSignalementCommunaute.cleMotif(MotifSignalement.publicite),
          ),
        );
        await taper(
          tester,
          find.byKey(FeuilleSignalementCommunaute.cleEnvoyer),
        );
        expect(
          find.byKey(FeuilleSignalementCommunaute.cleErreur),
          findsOneWidget,
        );
        await taper(
          tester,
          find.byKey(FeuilleSignalementCommunaute.cleEnvoyer),
        );
        expect(moderation.cles, hasLength(2));
        expect(moderation.cles.toSet(), hasLength(1));
        expect(find.byKey(PublicationDetail.cleSignalee), findsOneWidget);
      });
    },
  );
}
