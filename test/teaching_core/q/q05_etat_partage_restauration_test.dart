// Q-05 : SharedContentState se restaure pour un late joiner sans historique
// realtime, et une revision ancienne n ecrase jamais une recente.
//
// CONTRACTS section 9, invariants 1 et 2. Spec ligne 1200 : « LiveKit n est
// jamais une base de donnees ».
//
// LE MONTAGE FAIT LA PREUVE. Le canal temps reel du double est **sans
// memoire** : il ne rejoue rien. Un late joiner qui s y abonne ne recoit rien.
// S il retrouve quand meme l etat courant, c est donc qu il l a lu ailleurs --
// et « ailleurs » est le seul magasin backend du montage.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/contrats/contrats_f_etat_partage.dart';
import '../fixtures/fixtures_etat_partage.dart';
import 'faux/faux_etat_partage.dart';
import 'support/lecture_sources.dart';

void main() {
  group('Q-05 : un late joiner retrouve l etat sans historique realtime', () {
    test('le canal ne rejoue rien, et c est bien le probleme a resoudre', () async {
      final FauxCanalPedagogique canal = FauxCanalPedagogique();
      addTearDown(canal.liberer);

      // L enseignant a deja tourne la page avant l arrivee de l eleve.
      canal.emettreFiable(etatPartage(revision: 7, position: pagePartagee(42)));

      final List<SharedContentState> recus = <SharedContentState>[];
      final StreamSubscription<SharedContentState> abonnement = canal
          .messagesFiables
          .listen(recus.add);
      addTearDown(abonnement.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(
        recus,
        isEmpty,
        reason:
            'un abonne arrive en retard ne recoit rien : c est la realite d un '
            'canal de donnees, pas un defaut du double',
      );
    });

    test('la restauration lit le backend et rend l etat courant', () async {
      final FauxBackendEtatPartage backend = FauxBackendEtatPartage();
      final FauxCanalPedagogique canal = FauxCanalPedagogique();
      addTearDown(canal.liberer);

      final SharedContentState durable = etatDurablePourLateJoiner();
      backend.publier(durable);

      final VueParticipantEtatPartage lateJoiner =
          VueParticipantEtatPartage();
      lateJoiner.restaurerDepuis(await backend.restaurer(seancePartagee));

      expect(lateJoiner.courant?.revision, 7);
      expect(lateJoiner.courant?.contentPosition.page, 42);
      expect(backend.lectures, greaterThan(0));
    });

    test('une seance sans etat publie restaure null, pas une page par defaut', () async {
      final FauxBackendEtatPartage backend = FauxBackendEtatPartage();
      expect(await backend.restaurer('seance-jamais-ouverte'), isNull);
    });
  });

  group('Q-05 : la revision strictement croissante absorbe le reseau', () {
    test('un paquet hors ordre et un duplique ne font reculer aucune page', () {
      final VueParticipantEtatPartage vue = VueParticipantEtatPartage();

      for (final SharedContentState paquet in suiteRevisionsSale()) {
        vue.appliquer(paquet);
      }

      // Six paquets livres, quatre revisions retenues, et dans l ordre.
      expect(vue.revisionsRetenues, <int>[1, 2, 3, 4]);
      expect(vue.courant?.revision, 4);
      expect(vue.courant?.contentPosition.page, 4);
    });

    test('le backend applique exactement la meme regle que l ecran', () {
      final FauxBackendEtatPartage backend = FauxBackendEtatPartage();
      for (final SharedContentState paquet in suiteRevisionsSale()) {
        backend.publier(paquet);
      }
      expect(backend.etatCourant(seancePartagee)?.revision, 4);

      // Republier une revision ancienne ne regresse pas le magasin : sans
      // cela, une reconnexion tardive d un enseignant ecraserait l etat
      // courant avec ce qu il avait en cache.
      backend.publier(etatPartage(revision: 2, position: pagePartagee(2)));
      expect(backend.etatCourant(seancePartagee)?.revision, 4);
    });

    test('un paquet d une autre seance n entre jamais dans celle-ci', () {
      final SharedContentState mien = etatPartage(
        revision: 3,
        position: pagePartagee(3),
      );
      final SharedContentState autre = etatPartage(
        revision: 99,
        position: pagePartagee(500),
        sessionId: 'seance-voisine',
      );

      expect(appliquerRevision(mien, autre).revision, 3);
      expect(appliquerRevision(mien, autre).contentPosition.page, 3);
    });

    test('la revision egale est ignoree comme l ancienne', () {
      final SharedContentState courant = etatPartage(
        revision: 5,
        position: pagePartagee(5),
      );
      final SharedContentState memeRevisionAutreContenu = etatPartage(
        revision: 5,
        position: pagePartagee(500),
      );
      expect(
        appliquerRevision(courant, memeRevisionAutreContenu).contentPosition
            .page,
        5,
      );
    });

    test('rien de sensible n entre dans l etat partage', () {
      // L etat partage traverse le reseau temps reel : il ne porte que des
      // identifiants et une position, jamais une identite.
      final SharedContentState etat = etatDurablePourLateJoiner();
      final String rendu = <String, Object?>{
        'sessionId': etat.sessionId,
        'resourceId': etat.resourceId,
        'resourceVersionId': etat.resourceVersionId,
        'updatedBy': etat.updatedBy,
        'displayMode': etat.displayMode.name,
      }.toString().toLowerCase();

      for (final String interdit in const <String>[
        'email',
        'phone',
        'telephone',
        'adresse',
        'tuteur',
        'household',
        'iban',
      ]) {
        expect(rendu.contains(interdit), isFalse, reason: interdit);
      }
    });

    test('le zoom local n appartient pas a la position partagee', () {
      // Decision D-21 : le zoom est local a chaque personne, il ne casse
      // jamais la position pedagogique partagee. C est une ABSENCE de champ
      // qu il faut verifier, donc une lecture de source : aucun test
      // d execution ne peut interroger un champ qui n existe pas.
      //
      // `student_reading_position` porte bien un `zoom_level` en base, et
      // c est justement pourquoi la confusion est possible.
      final String? source = lireSiPresent(
        'test/teaching_core/fixtures/contrats/content_position.dart',
      );
      expect(source, isNotNull);
      expect(motsTrouves(source!, const <String>['zoom']), isEmpty);
    });
  });
}
