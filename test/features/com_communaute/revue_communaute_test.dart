// Contre-preuves de la revue COM-COMU-1 : chaque test echouait avant sa
// correction.
//
// - Cle d'idempotence : changer de categorie ou joindre une piece apres un
//   echec fait partir une nouvelle cle (un renvoi a l'identique garde la
//   sienne, COM-BR-02).
// - Vide sur « Toutes » : « Aucune publication pour le moment. », jamais
//   « dans cette categorie ».
// - Un signalement survit a l'ouverture d'une autre publication : ni double
//   signalement ni confirmation perdue.
// - A 1440, le panneau Aide/Regles ferme, le bandeau des regles revient
//   dans le flux.
// - La recherche n'interroge pas le port a chaque frappe et ne fait pas
//   clignoter le flux.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/feuille_signalement_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/com_communaute/regles_communaute.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import 'banc_communaute.dart';

const Size _bureau = Size(1440, 900);

/// Une Communaute qui note les cles d'idempotence et les lectures du flux.
class _PortEspion implements PortCommunaute {
  _PortEspion(this._memoire);

  final CommunauteMemoire _memoire;

  /// Les cles d'idempotence recues par `publier`, dans l'ordre.
  final List<String> cles = <String>[];

  /// Le nombre d'appels a `publications`.
  int lecturesFlux = 0;

  /// Vrai : l'envoi echoue (accuse perdu).
  bool echecEnvoi = true;

  @override
  Future<CapacitesCommunaute> capacites() => _memoire.capacites();

  @override
  Future<List<CategorieCommunaute>> categories() => _memoire.categories();

  @override
  Future<List<PublicationCommunaute>> publications({
    String? categorieId,
    String recherche = '',
  }) {
    lecturesFlux++;
    return _memoire.publications(
      categorieId: categorieId,
      recherche: recherche,
    );
  }

  @override
  Future<PublicationCommunaute> publication(String publicationId) =>
      _memoire.publication(publicationId);

  @override
  Future<List<ReponseCommunaute>> reponses(String publicationId) =>
      _memoire.reponses(publicationId);

  @override
  Future<PublicationCommunaute> publier(
    BrouillonPublication brouillon, {
    required String cleIdempotence,
  }) async {
    cles.add(cleIdempotence);
    if (echecEnvoi) throw StateError('accuse perdu');
    return _memoire.publier(brouillon, cleIdempotence: cleIdempotence);
  }

  @override
  Future<ReponseCommunaute> repondre({
    required String publicationId,
    required String texte,
    required String cleIdempotence,
  }) => _memoire.repondre(
    publicationId: publicationId,
    texte: texte,
    cleIdempotence: cleIdempotence,
  );
}

/// Remplit le composer et publie une premiere fois (echec).
Future<void> _premierEnvoiEnEchec(WidgetTester tester) async {
  await taper(tester, find.byKey(EntreeNouvellePublication.cle));
  await taper(
    tester,
    find.byKey(ComposerPublication.cleCategorie('pedagogie')),
  );
  await tester.enterText(find.byKey(ComposerPublication.cleTitre), 'Sujet');
  await tester.enterText(find.byKey(ComposerPublication.cleTexte), 'Texte');
  await taper(tester, find.byKey(ComposerPublication.clePublier));
  expect(find.byKey(ComposerPublication.cleErreur), findsOneWidget);
}

void main() {
  final c = t.com.communaute;

  group('cle d idempotence de la nouvelle publication', () {
    testWidgets('un renvoi a l identique rejoue la meme cle', (
      WidgetTester tester,
    ) async {
      final _PortEspion port = _PortEspion(memoireDemo());
      await monterCommunaute(tester, port: port);
      await _premierEnvoiEnEchec(tester);
      await taper(tester, find.byKey(ComposerPublication.clePublier));
      expect(port.cles, hasLength(2));
      expect(port.cles[1], port.cles[0]);
    });

    testWidgets('changer de categorie apres un echec : nouvelle cle', (
      WidgetTester tester,
    ) async {
      final _PortEspion port = _PortEspion(memoireDemo());
      await monterCommunaute(tester, port: port);
      await _premierEnvoiEnEchec(tester);
      final String autre = DonneesCommunauteDemo.categories
          .firstWhere((CategorieCommunaute k) => k.id != 'pedagogie')
          .id;
      await taper(tester, find.byKey(ComposerPublication.cleCategorie(autre)));
      port.echecEnvoi = false;
      await taper(tester, find.byKey(ComposerPublication.clePublier));
      expect(port.cles, hasLength(2));
      expect(port.cles[1], isNot(port.cles[0]));
    });

    testWidgets('joindre une piece apres un echec : nouvelle cle', (
      WidgetTester tester,
    ) async {
      final _PortEspion port = _PortEspion(memoireDemo());
      await monterCommunaute(tester, port: port);
      await _premierEnvoiEnEchec(tester);
      await taper(tester, find.byKey(EntreePieceJointe.cleJoindre));
      expect(find.byType(CartePieceJointe), findsOneWidget);
      port.echecEnvoi = false;
      await taper(tester, find.byKey(ComposerPublication.clePublier));
      expect(port.cles, hasLength(2));
      expect(port.cles[1], isNot(port.cles[0]));
    });
  });

  group('vide', () {
    testWidgets('sur « Toutes » : « Aucune publication pour le moment. » ; '
        'sur une categorie : « dans cette categorie »', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, port: memoireDemo(vide: true));
      expect(find.text(c.videToutes), findsOneWidget);
      expect(find.text(c.vide), findsNothing);

      await choisirCategorie(
        tester,
        DonneesCommunauteDemo.categories.first.libelle,
      );
      expect(find.text(c.vide), findsOneWidget);
      expect(find.text(c.videToutes), findsNothing);
    });
  });

  group('signalement', () {
    testWidgets('un signalement survit a l ouverture d une autre '
        'publication : ni menu repropose, ni confirmation perdue', (
      WidgetTester tester,
    ) async {
      final ModerationDemo moderation = ModerationDemo();
      await monterCommunaute(tester, taille: _bureau, moderation: moderation);
      await taper(
        tester,
        find.byKey(FluxPublications.cleCarte('pub-memorisation')),
      );
      await taper(tester, find.byKey(PublicationDetail.cleMenu));
      await taper(tester, find.text(c.publication.signaler));
      await taper(
        tester,
        find.byKey(
          FeuilleSignalementCommunaute.cleMotif(MotifSignalement.publicite),
        ),
      );
      await taper(tester, find.byKey(FeuilleSignalementCommunaute.cleEnvoyer));
      expect(find.byKey(PublicationDetail.cleSignalee), findsOneWidget);
      // Le texte exact de la spec, section 5.2.
      expect(
        find.text('Le contenu a été signalé à l\'équipe de modération.'),
        findsOneWidget,
      );

      await taper(tester, find.byKey(FluxPublications.cleCarte('pub-heure')));
      // Une autre publication : elle n'est pas signalee.
      expect(find.byKey(PublicationDetail.cleSignalee), findsNothing);
      expect(find.byKey(PublicationDetail.cleMenu), findsOneWidget);

      await taper(
        tester,
        find.byKey(FluxPublications.cleCarte('pub-memorisation')),
      );
      expect(find.byKey(PublicationDetail.cleSignalee), findsOneWidget);
      expect(find.byKey(PublicationDetail.cleMenu), findsNothing);
      expect(moderation.signalements, hasLength(1));
    });
  });

  group('bandeau anti-promotion', () {
    testWidgets('1440 : panneau Aide/Regles ferme, le bandeau revient dans '
        'le flux', (WidgetTester tester) async {
      await monterCommunaute(tester, taille: _bureau);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsOneWidget);
      expect(find.byKey(BandeauRegles.cle), findsNothing);

      await taper(tester, find.byKey(EspaceTravailAdaptatif.cleFermerContexte));
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(find.byKey(BandeauRegles.cle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(EspaceTravailAdaptatif.cleListe),
          matching: find.byKey(BandeauRegles.cle),
        ),
        findsOneWidget,
      );

      // Rouvert, il ne se double pas.
      await taper(tester, find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsOneWidget);
      expect(find.byKey(BandeauRegles.cle), findsNothing);
    });
  });

  group('recherche', () {
    testWidgets('chaque frappe filtre la liste deja lue : aucune lecture du '
        'port, aucun squelette', (WidgetTester tester) async {
      final _PortEspion port = _PortEspion(memoireDemo());
      await monterCommunaute(tester, port: port, taille: _bureau);
      final int avant = port.lecturesFlux;
      for (final String texte in <String>['c', 'ca', 'car', 'cartes']) {
        await tester.enterText(find.byKey(ClesRechercheCommunaute.champ), texte);
        await tester.pump();
        expect(find.byType(Skeleton), findsNothing, reason: texte);
      }
      await tester.pumpAndSettle();
      expect(port.lecturesFlux, avant);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'communaute-carte-',
              ),
        ),
        findsOneWidget,
      );
    });

    test('filtrerPublications : titre ou texte, sans la casse', () {
      final List<PublicationCommunaute> toutes =
          DonneesCommunauteDemo.publications();
      expect(filtrerPublications(toutes, ''), toutes);
      expect(filtrerPublications(toutes, '   '), toutes);
      final List<PublicationCommunaute> cartes = filtrerPublications(
        toutes,
        'CARTES',
      );
      expect(cartes, hasLength(1));
      expect(filtrerPublications(toutes, 'introuvable'), isEmpty);
    });
  });
}
