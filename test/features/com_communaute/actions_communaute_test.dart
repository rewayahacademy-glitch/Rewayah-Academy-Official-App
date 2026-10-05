// COM-COMU-1 : les actions de la Communaute enseignants, rendues dans la
// vraie coquille : nouvelle publication (un seul composer, sans prix,
// boutique ni « Promouvoir » ; jamais un faux succes), reponses (en attente,
// non confirmee, renvoyee), Enregistrer, Signaler (8 motifs du socle,
// confirmation apres accuse seulement), et R-COM-07 : aucun « Message
// prive » (spec section 4.2), aucun compteur de popularite (section 32).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/feuille_signalement_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/com_communaute/reponses.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../support/garde_interface.dart';
import 'banc_communaute.dart';

const Size _bureau = Size(1440, 900);

Future<void> _ouvrir(WidgetTester tester, String id) =>
    taper(tester, find.byKey(FluxPublications.cleCarte(id)));

void main() {
  final c = t.com.communaute;

  group('nouvelle publication (PostComposerEntry)', () {
    testWidgets('un seul composer : texte, categorie, piece jointe ; ni prix, '
        'ni boutique, ni promotion', (WidgetTester tester) async {
      await monterCommunaute(tester, taille: _bureau);
      expect(find.byKey(EntreeNouvellePublication.cle), findsOneWidget);
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));

      expect(find.byType(ComposerPublication), findsOneWidget);
      // L'entree a laisse la place au composer : un seul bouton plein.
      expect(find.byKey(EntreeNouvellePublication.cle), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      expect(find.byKey(ComposerPublication.cleTitre), findsOneWidget);
      expect(find.byKey(ComposerPublication.cleTexte), findsOneWidget);
      for (final CategorieCommunaute cat in DonneesCommunauteDemo.categories) {
        expect(
          find.byKey(ComposerPublication.cleCategorie(cat.id)),
          findsOneWidget,
        );
      }
      expect(find.byKey(EntreePieceJointe.cleJoindre), findsOneWidget);
      // Le rappel de la politique, dans le composer (spec section 5.2).
      expect(find.text(c.regles.titre), findsWidgets);
      // Spec section 5.3 : aucun de ces champs ou boutons.
      for (final String interdit in <String>[
        'Prix',
        'Produit',
        'Boutique',
        'Lien affilié',
        'Promouvoir',
        'Sponsoriser',
        'Contacter en privé',
        'Message privé',
      ]) {
        expect(find.text(interdit), findsNothing, reason: interdit);
      }
    });

    testWidgets('champs manquants : chaque manque se dit, rien ne part', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(tester);
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      await taper(tester, find.byKey(ComposerPublication.clePublier));
      expect(find.text(c.composer.categorieManquante), findsOneWidget);
      expect(find.text(c.composer.titreManquant), findsOneWidget);
      expect(find.text(c.composer.texteManquant), findsOneWidget);
      expect(banc.memoire.publicationsAcceptees, 0);
    });

    testWidgets('publication confirmee : elle s ouvre, le flux la montre, '
        '« Votre publication est en ligne. » apres l accuse seulement', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(tester);
      await choisirCategorie(tester, 'Ressources');
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      // La categorie est deduite du flux (K-57).
      await tester.enterText(
        find.byKey(ComposerPublication.cleTitre),
        'Un jeu de cartes pour Al-Fatiha',
      );
      await tester.enterText(
        find.byKey(ComposerPublication.cleTexte),
        'Voici les cartes que je prepare pour les plus jeunes.',
      );
      // Une piece jointe autorisee par la politique.
      await taper(tester, find.byKey(EntreePieceJointe.cleJoindre));
      expect(find.text('Fiche_seance.pdf'), findsOneWidget);
      await taper(tester, find.byKey(ComposerPublication.clePublier));

      expect(banc.memoire.publicationsAcceptees, 1);
      expect(find.byType(ComposerPublication), findsNothing);
      expect(find.byType(PublicationDetail), findsOneWidget);
      expect(find.text('Un jeu de cartes pour Al-Fatiha'), findsWidgets);
      expect(find.text(c.composer.confirmee), findsOneWidget);
      final List<PublicationCommunaute> ressources = await banc.port
          .publications(categorieId: DonneesCommunauteDemo.ressources.id);
      expect(ressources.first.titre, 'Un jeu de cartes pour Al-Fatiha');
      expect(ressources.first.piecesJointes, hasLength(1));
      // Le brouillon est efface apres l'accuse.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('R-COM-05 : un envoi non confirme le dit, jamais un faux '
        'succes ; le brouillon reste', (WidgetTester tester) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        port: memoireDemo(echecEnvoi: true),
      );
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      await taper(
        tester,
        find.byKey(ComposerPublication.cleCategorie('pedagogie')),
      );
      await tester.enterText(
        find.byKey(ComposerPublication.cleTitre),
        'Mon sujet',
      );
      await tester.enterText(
        find.byKey(ComposerPublication.cleTexte),
        'Mon texte',
      );
      await taper(tester, find.byKey(ComposerPublication.clePublier));

      expect(find.byKey(ComposerPublication.cleErreur), findsOneWidget);
      expect(find.text(c.composer.erreurEnvoi), findsOneWidget);
      expect(find.text(c.composer.confirmee), findsNothing);
      expect(find.byType(ComposerPublication), findsOneWidget);
      expect(banc.memoire.publicationsAcceptees, 0);

      // Fermer puis rouvrir : le brouillon de session est restaure.
      await taper(tester, find.byKey(ComposerPublication.cleFermer));
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      expect(find.text('Mon sujet'), findsOneWidget);
      expect(find.text('Mon texte'), findsOneWidget);
      expect(
        find.text(t.com.socle.composants.composer.brouillonRestaure),
        findsOneWidget,
      );
    });

    testWidgets('un fichier refuse par la politique bloque la publication', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        choix: const _ChoixTropLourd(),
      );
      await taper(tester, find.byKey(EntreeNouvellePublication.cle));
      await taper(
        tester,
        find.byKey(ComposerPublication.cleCategorie('pedagogie')),
      );
      await tester.enterText(find.byKey(ComposerPublication.cleTitre), 'Titre');
      await tester.enterText(find.byKey(ComposerPublication.cleTexte), 'Texte');
      await taper(tester, find.byKey(EntreePieceJointe.cleJoindre));
      expect(
        find.text(t.com.socle.composants.pieceJointe.tropVolumineuse),
        findsOneWidget,
      );
      await taper(tester, find.byKey(ComposerPublication.clePublier));
      expect(find.text(c.composer.pieceRefusee), findsOneWidget);
      expect(banc.memoire.publicationsAcceptees, 0);
    });

    testWidgets('lecture seule : ni « Nouvelle publication » ni reponse', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(
        tester,
        taille: _bureau,
        port: memoireDemo(capacites: CapacitesCommunaute.aucune),
      );
      expect(find.byKey(EntreeNouvellePublication.cle), findsNothing);
      await _ouvrir(tester, 'pub-memorisation');
      expect(find.byType(ComposerReponse), findsNothing);
    });
  });

  group('reponses (ReplyThread)', () {
    testWidgets('une reponse confirmee rejoint le fil, le compte suit', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _bureau,
      );
      await _ouvrir(tester, 'pub-memorisation');
      expect(find.text(c.reponses.titre(nombre: 2)), findsOneWidget);
      expect(find.byKey(FilReponses.cleReponse('rep-mariam')), findsOneWidget);

      // Un texte vide se dit sous le champ, le bouton n'est pas grise.
      await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
      expect(find.text(c.reponses.champVide), findsOneWidget);
      expect(banc.memoire.reponsesAcceptees, 0);

      await tester.enterText(
        find.byKey(ComposerReponse.cleChamp),
        'Merci, je vais essayer.',
      );
      await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
      expect(banc.memoire.reponsesAcceptees, 1);
      expect(find.text('Merci, je vais essayer.'), findsOneWidget);
      expect(find.text(c.reponses.titre(nombre: 3)), findsOneWidget);
      expect(find.text(c.reponses.nonConfirmee), findsNothing);
    });

    testWidgets('non confirmee : elle le dit, puis se renvoie avec la meme '
        'cle', (WidgetTester tester) async {
      final CommunauteMemoire memoire = memoireDemo(echecEnvoi: true);
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _bureau,
        port: memoire,
      );
      await _ouvrir(tester, 'pub-niveaux');
      expect(find.text(c.reponses.vide), findsOneWidget);
      await tester.enterText(find.byKey(ComposerReponse.cleChamp), 'Essai');
      await taper(tester, find.byKey(ComposerReponse.cleEnvoyer));
      expect(find.text(c.reponses.nonConfirmee), findsOneWidget);
      expect(banc.memoire.reponsesAcceptees, 0);

      memoire.echecEnvoi = false;
      await taper(tester, find.text(c.reponses.reessayer));
      expect(find.text(c.reponses.nonConfirmee), findsNothing);
      expect(banc.memoire.reponsesAcceptees, 1);
      expect(find.text('Essai'), findsOneWidget);
    });

    testWidgets('le brouillon d une reponse reste attache a sa publication', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      await monterCommunaute(
        tester,
        taille: _bureau,
        autres: <Override>[
          portBrouillonsProvider.overrideWithValue(brouillons),
        ],
      );
      await _ouvrir(tester, 'pub-memorisation');
      await tester.enterText(find.byKey(ComposerReponse.cleChamp), 'En cours');
      await _ouvrir(tester, 'pub-niveaux');
      expect(find.text('En cours'), findsNothing);
      await _ouvrir(tester, 'pub-memorisation');
      expect(find.text('En cours'), findsOneWidget);
      final Brouillon? garde = await brouillons.lire(
        const CleBrouillon(
          type: TypeObjetLie.publication,
          objetId: 'pub-memorisation',
        ),
      );
      expect(garde?.texte, 'En cours');
    });
  });

  group('Enregistrer (SavedForLater)', () {
    testWidgets('enregistrer garde une reference ; retirer la rend', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(
        tester,
        taille: _bureau,
      );
      await _ouvrir(tester, 'pub-cartes');
      expect(find.text(c.publication.enregistrer), findsOneWidget);
      await taper(tester, find.byKey(PublicationDetail.cleEnregistrer));
      expect(find.text(c.publication.enregistree), findsOneWidget);
      expect(find.text(c.publication.retirer), findsOneWidget);
      final List<ElementEnregistre> liste = await banc.enregistres.liste();
      expect(liste.single.objet.type, TypeObjetLie.publication);
      expect(liste.single.objet.id, 'pub-cartes');

      await taper(tester, find.byKey(PublicationDetail.cleEnregistrer));
      expect(find.text(c.publication.enregistree), findsNothing);
      expect(await banc.enregistres.liste(), isEmpty);
    });

    testWidgets('sans contrat (port neutre), l action n est pas rendue', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(
        tester,
        taille: _bureau,
        enregistres: const ElementsEnregistresIndisponibles(),
      );
      await _ouvrir(tester, 'pub-cartes');
      expect(find.byKey(PublicationDetail.cleEnregistrer), findsNothing);
      // La piece jointe se montre, sans adresse : nom, type, taille.
      expect(find.text('Cartes_repetition.pdf'), findsOneWidget);
      expect(find.textContaining('http'), findsNothing);
    });
  });

  group('Signaler (PortModeration, 8 motifs)', () {
    testWidgets('signaler une publication : motif requis, confirmation apres '
        'l accuse', (WidgetTester tester) async {
      final ModerationDemo moderation = ModerationDemo();
      await monterCommunaute(tester, taille: _bureau, moderation: moderation);
      await _ouvrir(tester, 'pub-memorisation');

      await taper(tester, find.byKey(PublicationDetail.cleMenu));
      await taper(tester, find.text(c.publication.signaler));
      expect(find.text(t.com.socle.signalement.titre), findsOneWidget);
      for (final MotifSignalement motif in MotifSignalement.values) {
        expect(
          find.byKey(FeuilleSignalementCommunaute.cleMotif(motif)),
          findsOneWidget,
        );
      }

      // Sans motif : la feuille le dit, rien ne part.
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(find.text(c.signalement.motifManquant), findsOneWidget);
      expect(moderation.signalements, isEmpty);

      await taper(
        tester,
        find.byKey(
          FeuilleSignalementCommunaute.cleMotif(MotifSignalement.publicite),
        ),
      );
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(moderation.signalements, hasLength(1));
      expect(moderation.signalements.single.$1.id, 'pub-memorisation');
      expect(moderation.signalements.single.$1.type, TypeObjetLie.publication);
      expect(moderation.signalements.single.$2, MotifSignalement.publicite);
      expect(find.byKey(PublicationDetail.cleSignalee), findsOneWidget);
      // Deja signalee : le menu ne repropose pas l'action.
      expect(find.byKey(PublicationDetail.cleMenu), findsNothing);
    });

    testWidgets('signaler une reponse porte l identifiant de la reponse', (
      WidgetTester tester,
    ) async {
      final ModerationDemo moderation = ModerationDemo();
      await monterCommunaute(tester, taille: _bureau, moderation: moderation);
      await _ouvrir(tester, 'pub-memorisation');
      final Finder ligne = find.byKey(FilReponses.cleReponse('rep-youssef'));
      await taper(
        tester,
        find.descendant(of: ligne, matching: find.byType(MenuActions)),
      );
      await taper(tester, find.text(c.reponses.signaler));
      await taper(
        tester,
        find.byKey(
          FeuilleSignalementCommunaute.cleMotif(MotifSignalement.harcelement),
        ),
      );
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(moderation.signalements.single.$1.id, 'rep-youssef');
      expect(find.text(c.reponses.signalee), findsOneWidget);
    });

    testWidgets('moderation indisponible : la feuille le dit, aucun faux '
        'succes', (WidgetTester tester) async {
      await monterCommunaute(
        tester,
        taille: _bureau,
        moderation: ModerationDemo(indisponible: true),
      );
      await _ouvrir(tester, 'pub-memorisation');
      await taper(tester, find.byKey(PublicationDetail.cleMenu));
      await taper(tester, find.text(c.publication.signaler));
      await taper(
        tester,
        find.byKey(
          FeuilleSignalementCommunaute.cleMotif(MotifSignalement.autre),
        ),
      );
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(
        find.byKey(FeuilleSignalementCommunaute.cleErreur),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.signalement.indisponible), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byKey(PublicationDetail.cleSignalee), findsNothing);
    });

    testWidgets('sans capacite de moderation (port neutre), aucun menu', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(
        tester,
        taille: _bureau,
        moderation: const ModerationIndisponible(),
      );
      await _ouvrir(tester, 'pub-memorisation');
      expect(find.byKey(PublicationDetail.cleMenu), findsNothing);
      expect(find.byType(MenuActions), findsNothing);
    });
  });

  group('R-COM-07 et section 32', () {
    testWidgets('aucun « Message prive », aucun profil a ouvrir, aucun '
        'compteur de popularite', (WidgetTester tester) async {
      for (final Size taille in <Size>[const Size(390, 844), _bureau]) {
        await monterCommunaute(tester, taille: taille);
        await _ouvrir(tester, 'pub-memorisation');
        // L'auteur se lit et ne se touche pas : aucun bouton ne porte son
        // nom.
        final Finder auteur = find.text('Samira Belkacem');
        expect(auteur, findsWidgets);
        expect(
          find.ancestor(
            of: auteur.first,
            matching: find.byType(ActionPrincipale),
          ),
          findsNothing,
        );
        await tester.tap(auteur.first, warnIfMissed: false);
        await tester.pumpAndSettle();
        for (final String interdit in <String>[
          'Message privé',
          'Envoyer un message',
          'Contacter',
          'Suivre',
          'Abonnés',
          "J'aime",
          'Classement',
        ]) {
          expect(find.textContaining(interdit), findsNothing, reason: interdit);
        }
        expect(find.byType(PublicationDetail), findsOneWidget);
      }
    });
  });
}

/// Un choix qui rend un fichier plus lourd que la politique (10 Mo).
class _ChoixTropLourd implements ChoixPieceCommunaute {
  const _ChoixTropLourd();

  @override
  Future<FichierChoisi?> choisir() async => const FichierChoisi(
    nom: 'Enregistrement.mp3',
    typeMime: 'audio/mpeg',
    typeLisible: 'Audio',
    tailleOctets: 50 * 1024 * 1024,
  );
}
