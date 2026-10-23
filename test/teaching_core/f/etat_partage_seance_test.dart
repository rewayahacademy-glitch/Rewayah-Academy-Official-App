import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_etat_partage/codec_etat_partage.dart';
import 'package:rewayah_academy/core/tc_etat_partage/etat_partage_memoire.dart';
import 'package:rewayah_academy/core/tc_etat_partage/port_etat_partage_persistant.dart';
import 'package:rewayah_academy/core/tc_etat_partage/service_etat_partage.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/tc_realtime/service_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/transport_memoire.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';

import 'faux/fausse_persistance.dart';
import 'support/fabriques.dart';

/// L'etat partage vu de la seance : arrivee tardive, reconnexion, ordre.
///
/// **L'exigence centrale du lot F se prouve ici** : un arrivant tardif ou une
/// reconnexion recupere l'etat COURANT sans dependre de l'historique des
/// messages realtime. Les tests qui le prouvent coupent volontairement le
/// reseau realtime -- si l'etat arrive quand meme, c'est qu'il ne venait pas de
/// la.
void main() {
  late BusMemoire bus;
  late TransportMemoire cotePrpf;
  late TransportMemoire coteEleve;
  late EtatPartageMemoire backend;
  late ServiceEtatPartage chezLePrpf;
  late ServiceEtatPartage chezLEleve;

  setUp(() {
    bus = BusMemoire();
    cotePrpf = TransportMemoire(bus: bus, capacites: capacitesEnseignant);
    coteEleve = TransportMemoire(bus: bus, capacites: capacitesEleve);
    // **Un seul magasin pour les deux cotes** : c'est ce que sera la table
    // `session_shared_content` demandee dans TC_CONTRACT_REQUEST_F.md.
    backend = EtatPartageMemoire();
    chezLePrpf = ServiceEtatPartage(
      realtime: ServiceRealtimePedagogique(cotePrpf),
      persistance: backend,
      etatsTransport: cotePrpf.etats(),
    );
    chezLEleve = ServiceEtatPartage(
      realtime: ServiceRealtimePedagogique(coteEleve),
      persistance: backend,
      etatsTransport: coteEleve.etats(),
    );
  });

  tearDown(() async {
    await chezLePrpf.liberer();
    await chezLEleve.liberer();
    await cotePrpf.liberer();
    await coteEleve.liberer();
  });

  Future<List<SharedContentState>> suivre(ServiceEtatPartage service) async {
    final List<SharedContentState> recus = <SharedContentState>[];
    final StreamSubscription<SharedContentState> abonnement = service
        .suivre(seanceF)
        .listen(recus.add);
    addTearDown(abonnement.cancel);
    await pumpEventQueue();
    return recus;
  }

  group('publier', () {
    test('ecrit le durable AVANT de diffuser', () async {
      await chezLePrpf.publier(etatPartage(revision: 0, page: 12));

      // L'ordre est porteur d'information : si la diffusion echouait, un
      // arrivant tardif aurait quand meme la bonne page. L'inverse produirait
      // deux verites.
      expect(backend.ecritures, 1);
      expect((await backend.lire(seanceF))!.contentPosition.page, 12);
      expect(cotePrpf.emis, hasLength(1));
      expect(cotePrpf.emis.single.canal, CanalFiabilite.fiable);
      expect(cotePrpf.emis.single.sujet, sujetProtocolePedagogique);
    });

    test('l emetteur voit son propre etat par le meme chemin', () async {
      final List<SharedContentState> chezMoi = await suivre(chezLePrpf);

      await chezLePrpf.publier(etatPartage(revision: 0, page: 12));
      await pumpEventQueue();

      // Le transport ne relivre pas ses propres paquets a l'emetteur : un seul
      // chemin de rendu, donc aucune divergence entre ce que l'enseignant croit
      // montrer et ce que la classe voit.
      expect(chezMoi, hasLength(1));
      expect(chezMoi.single.contentPosition.page, 12);
    });

    test('une revision obsolete est refusee, sans rien ecrire', () async {
      await chezLePrpf.publier(etatPartage(revision: 3));

      await expectLater(
        chezLePrpf.publier(etatPartage(revision: 3, page: 99)),
        throwsA(
          isA<EchecEtatPartage>().having(
            (EchecEtatPartage e) => e.motif,
            'motif',
            MotifEchecEtatPartage.revisionObsolete,
          ),
        ),
      );
      expect(backend.ecritures, 1);
      expect((await backend.lire(seanceF))!.contentPosition.page, 3);
    });

    test('la classe recoit la revision', () async {
      final List<SharedContentState> chezLui = await suivre(chezLEleve);

      await chezLePrpf.publier(etatPartage(revision: 0, page: 7));
      await pumpEventQueue();

      expect(chezLui, hasLength(1));
      expect(chezLui.single.revision, 0);
      expect(chezLui.single.contentPosition.page, 7);
    });
  });

  group('arrivee tardive', () {
    test(
      'un arrivant obtient l etat courant SANS aucun message realtime',
      () async {
        await chezLePrpf.publier(etatPartage(revision: 0, page: 3));
        await chezLePrpf.publier(etatPartage(revision: 1, page: 11));

        // Le reseau realtime est coupe : plus un seul paquet ne circulera.
        // Si l'eleve retrouve la page 11, c'est donc qu'elle ne venait pas de
        // l'historique des messages.
        bus.jeter = (PaquetRealtime p) => true;

        final List<SharedContentState> chezLui = await suivre(chezLEleve);
        await pumpEventQueue();

        expect(chezLui, hasLength(1));
        expect(chezLui.single.revision, 1);
        expect(chezLui.single.contentPosition.page, 11);
      },
    );

    test('etatCourant lit le backend quand rien n est en memoire', () async {
      await chezLePrpf.publier(etatPartage(revision: 4, page: 21));
      bus.jeter = (PaquetRealtime p) => true;

      final SharedContentState? lu = await chezLEleve.etatCourant(seanceF);

      expect(lu, isNotNull);
      expect(lu!.revision, 4);
    });

    test('aucune presentation en cours rend null, pas un etat vide', () async {
      expect(await chezLEleve.etatCourant(seanceF), isNull);
    });
  });

  group('reconnexion', () {
    test(
      'un retablissement restaure l etat manque pendant la coupure',
      () async {
        final List<SharedContentState> chezLui = await suivre(chezLEleve);
        await chezLePrpf.publier(etatPartage(revision: 0, page: 3));
        await pumpEventQueue();
        expect(chezLui, hasLength(1));

        // L'eleve perd le reseau : les revisions suivantes ne lui parviennent
        // pas.
        bus.jeter = (PaquetRealtime p) => true;
        await chezLePrpf.publier(etatPartage(revision: 1, page: 14));
        await chezLePrpf.publier(etatPartage(revision: 2, page: 15));
        await pumpEventQueue();
        expect(chezLui, hasLength(1), reason: 'toujours coupe');

        // Le lien revient. `retabli` est le seul declencheur de restauration --
        // le socle distingue deja cet etat de `connecte` pour cette raison.
        coteEleve.poserEtat(EtatTransport.retabli);
        await pumpEventQueue();

        expect(chezLui, hasLength(2));
        expect(chezLui.last.revision, 2);
        expect(chezLui.last.contentPosition.page, 15);
      },
    );

    test('un lien instable ne declenche AUCUNE restauration', () async {
      final PersistanceFigee figee = PersistanceFigee(etatPartage(revision: 0));
      final ServiceEtatPartage service = ServiceEtatPartage(
        realtime: ServiceRealtimePedagogique(coteEleve),
        persistance: figee,
        etatsTransport: coteEleve.etats(),
      );
      addTearDown(service.liberer);

      final StreamSubscription<SharedContentState> abonnement = service
          .suivre(seanceF)
          .listen((_) {});
      addTearDown(abonnement.cancel);
      await pumpEventQueue();
      final int apresDemarrage = figee.lectures;

      coteEleve
        ..poserEtat(EtatTransport.ouvert)
        ..poserEtat(EtatTransport.interrompu);
      await pumpEventQueue();

      // « La seance continue, rien ne se demonte » : traiter une degradation de
      // reseau comme une coupure relirait le backend a chaque sursaut.
      expect(figee.lectures, apresDemarrage);
    });
  });

  group('ordre des revisions', () {
    test(
      'une lecture de backend en retard n ecrase pas une revision recente',
      () async {
        // La replique rend la revision 2 alors que le temps reel a deja livre
        // la 7.
        final PersistanceFigee enRetard = PersistanceFigee(
          etatPartage(revision: 2, page: 5),
        );
        final ServiceEtatPartage service = ServiceEtatPartage(
          realtime: ServiceRealtimePedagogique(coteEleve),
          persistance: enRetard,
          etatsTransport: coteEleve.etats(),
        );
        addTearDown(service.liberer);

        final List<SharedContentState> recus = <SharedContentState>[];
        final StreamSubscription<SharedContentState> abonnement = service
            .suivre(seanceF)
            .listen(recus.add);
        addTearDown(abonnement.cancel);
        await pumpEventQueue();

        await ServiceRealtimePedagogique(cotePrpf).emettre(
          _revision(etatPartage(revision: 7, page: 44)),
          canal: CanalFiabilite.fiable,
        );
        await pumpEventQueue();

        coteEleve.poserEtat(EtatTransport.retabli);
        await pumpEventQueue();

        expect(await service.etatCourant(seanceF), isNotNull);
        expect((await service.etatCourant(seanceF))!.revision, 7);
        expect(recus.map((SharedContentState e) => e.revision), <int>[2, 7]);
      },
    );

    test('un paquet hors ordre ne fait jamais reculer la classe', () async {
      final List<SharedContentState> chezLui = await suivre(chezLEleve);
      final ServiceRealtimePedagogique emetteur = ServiceRealtimePedagogique(
        cotePrpf,
      );

      await emetteur.emettre(
        _revision(etatPartage(revision: 9, page: 40)),
        canal: CanalFiabilite.fiable,
      );
      await emetteur.emettre(
        _revision(etatPartage(revision: 8, page: 12)),
        canal: CanalFiabilite.fiable,
      );
      await pumpEventQueue();

      expect(chezLui, hasLength(1));
      expect(chezLui.single.revision, 9);
      expect(chezLui.single.contentPosition.page, 40);
    });

    test('un etat illisible garde l etat courant', () async {
      final List<SharedContentState> chezLui = await suivre(chezLEleve);
      final ServiceRealtimePedagogique emetteur = ServiceRealtimePedagogique(
        cotePrpf,
      );

      await emetteur.emettre(
        _revision(etatPartage(revision: 1, page: 6)),
        canal: CanalFiabilite.fiable,
      );
      await emetteur.emettre(
        MessagePedagogique(
          type: typeRevisionEtatPartage,
          sessionId: seanceF,
          emetteurProfilId: profilEnseignant,
          charge: const <String, dynamic>{
            'revision': 2,
            'display_mode': 'imax',
          },
          emisLeUtc: DateTime.utc(2026, 9, 20, 10),
        ),
        canal: CanalFiabilite.fiable,
      );
      await pumpEventQueue();

      expect(chezLui, hasLength(1));
      expect(chezLui.single.revision, 1);
    });
  });

  group('cause de revision', () {
    test('elle est deduite, jamais demandee a l appelant', () {
      final SharedContentState avant = etatPartage(revision: 0, page: 3);

      expect(causeDeRevision(null, avant), CauseRevision.support);
      expect(
        causeDeRevision(avant, etatPartage(revision: 1, page: 4)),
        CauseRevision.position,
      );
      expect(
        causeDeRevision(
          avant,
          etatPartage(revision: 1, mode: ModeAffichagePartage.focus),
        ),
        CauseRevision.mode,
      );
      expect(
        causeDeRevision(avant, etatPartage(revision: 1, resourceId: 'res-2')),
        CauseRevision.support,
      );
      expect(
        causeDeRevision(avant, etatPartage(revision: 1)),
        CauseRevision.restauration,
      );
    });

    test('elle voyage avec l etat, sans le remplacer', () async {
      await chezLePrpf.publier(etatPartage(revision: 0));

      final MessagePedagogique? envoye = messageDepuisOctets(
        cotePrpf.emis.single.charge,
      );

      expect(envoye, isNotNull);
      expect(envoye!.charge['cause'], CauseRevision.support.valeurSql);
      // L'etat reste COMPLET : un recepteur qui ignorerait la cause resterait
      // correct.
      expect(envoye.charge['revision'], 0);
      expect(envoye.charge['content_position'], isNotNull);
    });
  });

  test(
    'une panne de lecture remonte, elle ne se deguise pas en vide',
    () async {
      final ServiceEtatPartage service = ServiceEtatPartage(
        realtime: ServiceRealtimePedagogique(coteEleve),
        persistance: PersistanceEnPanne(),
        etatsTransport: coteEleve.etats(),
      );
      addTearDown(service.liberer);

      await expectLater(
        service.etatCourant(seanceF),
        throwsA(isA<EchecEtatPartage>()),
      );
    },
  );
}

/// Fabrique le message de revision tel que `ServiceEtatPartage` l'emet.
MessagePedagogique _revision(SharedContentState etat) => MessagePedagogique(
  type: typeRevisionEtatPartage,
  sessionId: etat.sessionId,
  emetteurProfilId: etat.updatedBy,
  charge: <String, dynamic>{
    ...etatVersJson(etat),
    'cause': CauseRevision.position.valeurSql,
  },
  emisLeUtc: etat.updatedAtUtc,
);
