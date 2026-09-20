import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/tc_realtime/service_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/transport_indisponible.dart';
import 'package:rewayah_academy/core/tc_realtime/transport_memoire.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart'
    show sujetContenuPresente;

import 'support/fabriques.dart';

/// La separation des canaux : le coeur du lot F.
///
/// Les deux canaux ne se melangent jamais. Un pointeur ne passe pas par le
/// canal fiable, une revision d'etat ne passe pas par l'ephemere, et perdre
/// tout l'ephemere ne coute rien au fiable.
void main() {
  late BusMemoire bus;
  late TransportMemoire cotePrpf;
  late TransportMemoire coteEleve;
  late TransportMemoire coteEleveDeux;
  late ServiceRealtimePedagogique protocolePrpf;
  late ServiceRealtimePedagogique protocoleEleve;
  late ServiceRealtimePedagogique protocoleEleveDeux;

  setUp(() {
    bus = BusMemoire();
    cotePrpf = TransportMemoire(bus: bus, capacites: capacitesEnseignant);
    coteEleve = TransportMemoire(bus: bus, capacites: capacitesEleve);
    coteEleveDeux = TransportMemoire(bus: bus, capacites: capacitesEleveDeux);
    protocolePrpf = ServiceRealtimePedagogique(cotePrpf);
    protocoleEleve = ServiceRealtimePedagogique(coteEleve);
    protocoleEleveDeux = ServiceRealtimePedagogique(coteEleveDeux);
  });

  tearDown(() async {
    await cotePrpf.liberer();
    await coteEleve.liberer();
    await coteEleveDeux.liberer();
  });

  /// Ouvre un collecteur sur un flux et laisse le generateur s'abonner.
  Future<List<MessagePedagogique>> collecter(
    Stream<MessagePedagogique> flux,
  ) async {
    final List<MessagePedagogique> recus = <MessagePedagogique>[];
    flux.listen(recus.add);
    await pumpEventQueue();
    return recus;
  }

  group('separation fiable / ephemere', () {
    test('un message fiable n apparait pas sur le canal ephemere', () async {
      final List<MessagePedagogique> fiables = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );
      final List<MessagePedagogique> ephemeres = await collecter(
        protocoleEleve.messagesEphemeres(seanceF),
      );

      await protocolePrpf.emettre(
        message(type: typeEleveActif),
        canal: CanalFiabilite.fiable,
      );
      await pumpEventQueue();

      expect(fiables, hasLength(1));
      expect(fiables.single.type, typeEleveActif);
      expect(ephemeres, isEmpty);
    });

    test('un pointeur ephemere n apparait pas sur le canal fiable', () async {
      final List<MessagePedagogique> fiables = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );
      final List<MessagePedagogique> ephemeres = await collecter(
        protocoleEleve.messagesEphemeres(seanceF),
      );

      await protocolePrpf.emettre(
        // Le type appartient a Agent D : le lot F le transporte sans le
        // connaitre, et c'est exactement ce qu'on veut prouver.
        message(type: 'tc.outils.pointeur'),
        canal: CanalFiabilite.ephemere,
      );
      await pumpEventQueue();

      expect(ephemeres, hasLength(1));
      expect(ephemeres.single.type, 'tc.outils.pointeur');
      expect(fiables, isEmpty);
    });

    test(
      'perdre TOUT le canal ephemere ne coute rien au canal fiable',
      () async {
        // Le reseau jette chaque paquet ephemere. Bloquer le canal fiable pour
        // un pointeur est nomme comme une faute dans la mission ; le perdre est
        // sans gravite.
        bus.jeter = (PaquetRealtime p) => p.canal == CanalFiabilite.ephemere;

        final List<MessagePedagogique> fiables = await collecter(
          protocoleEleve.messagesFiables(seanceF),
        );
        final List<MessagePedagogique> ephemeres = await collecter(
          protocoleEleve.messagesEphemeres(seanceF),
        );

        for (int i = 0; i < 30; i++) {
          await protocolePrpf.emettre(
            message(type: 'tc.outils.pointeur', minute: i),
            canal: CanalFiabilite.ephemere,
          );
        }
        await protocolePrpf.emettre(
          message(type: typeEleveActif),
          canal: CanalFiabilite.fiable,
        );
        await pumpEventQueue();

        expect(ephemeres, isEmpty);
        expect(fiables, hasLength(1));
      },
    );
  });

  group('accidents de reseau', () {
    test('un paquet duplique est ecarte sur le canal fiable', () async {
      final List<MessagePedagogique> recus = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );

      final PaquetRealtime paquet = PaquetRealtime(
        sujet: sujetProtocolePedagogique,
        charge: messageVersOctets(message(type: typeEleveActif)),
        canal: CanalFiabilite.fiable,
        emetteurIdentite: profilEnseignant,
      );
      coteEleve
        ..recevoir(paquet)
        ..recevoir(paquet)
        ..recevoir(paquet);
      await pumpEventQueue();

      expect(recus, hasLength(1));
    });

    test('un paquet duplique passe sur le canal ephemere', () async {
      final List<MessagePedagogique> recus = await collecter(
        protocoleEleve.messagesEphemeres(seanceF),
      );

      final PaquetRealtime paquet = PaquetRealtime(
        sujet: sujetProtocolePedagogique,
        charge: messageVersOctets(message(type: 'tc.outils.pointeur')),
        canal: CanalFiabilite.ephemere,
        emetteurIdentite: profilEnseignant,
      );
      coteEleve
        ..recevoir(paquet)
        ..recevoir(paquet);
      await pumpEventQueue();

      // Aucune deduplication : un doublon de pointeur coute moins cher qu'une
      // memoire tenue pour rien, et il est de toute facon idempotent a
      // l'affichage.
      expect(recus, hasLength(2));
    });

    test('un paquet illisible ne ferme pas le canal', () async {
      final List<MessagePedagogique> recus = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );

      coteEleve
        ..recevoir(
          PaquetRealtime(
            sujet: sujetProtocolePedagogique,
            charge: utf8.encode('{ ceci n est pas du json'),
            canal: CanalFiabilite.fiable,
          ),
        )
        ..recevoir(
          PaquetRealtime(
            sujet: sujetProtocolePedagogique,
            charge: messageVersOctets(message(type: typeEleveActif)),
            canal: CanalFiabilite.fiable,
          ),
        );
      await pumpEventQueue();

      // Un client plus recent ne doit pas faire tomber le canal d'un client
      // plus ancien pour tout le reste de la seance.
      expect(recus, hasLength(1));
      expect(recus.single.type, typeEleveActif);
    });

    test('un paquet d une autre seance est ignore', () async {
      final List<MessagePedagogique> recus = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );

      await protocolePrpf.emettre(
        message(type: typeEleveActif, sessionId: autreSeance),
        canal: CanalFiabilite.fiable,
      );
      await pumpEventQueue();

      expect(recus, isEmpty);
    });

    test('un paquet d un autre sujet est ignore', () async {
      final List<MessagePedagogique> recus = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );

      // `contenu-presente` est le protocole coranique du socle. Les deux
      // coexistent sur le meme canal de donnees sans se lire l'un l'autre.
      coteEleve.recevoir(
        PaquetRealtime(
          sujet: sujetContenuPresente,
          charge: messageVersOctets(message(type: typeEleveActif)),
          canal: CanalFiabilite.fiable,
        ),
      );
      await pumpEventQueue();

      expect(recus, isEmpty);
    });
  });

  group('rappel discret cible', () {
    test('seul le destinataire le recoit', () async {
      final List<MessagePedagogique> chezUn = await collecter(
        protocoleEleve.messagesFiables(seanceF),
      );
      final List<MessagePedagogique> chezDeux = await collecter(
        protocoleEleveDeux.messagesFiables(seanceF),
      );

      await protocolePrpf.emettreCible(
        messageRappelDiscret(
          sessionId: seanceF,
          emetteurProfilId: profilEnseignant,
          academyId: 'RA-AB0012',
          maintenantUtc: DateTime.utc(2026, 9, 20, 10),
        ),
        destinataireProfilId: profilEleveDeux,
        canal: CanalFiabilite.fiable,
      );
      await pumpEventQueue();

      expect(chezUn, isEmpty);
      expect(chezDeux, hasLength(1));
      expect(academyIdDeCharge(chezDeux.single), 'RA-AB0012');
    });

    test('la charge ne porte que l identifiant d academie', () {
      final MessagePedagogique rappel = messageRappelDiscret(
        sessionId: seanceF,
        emetteurProfilId: profilEnseignant,
        academyId: 'RA-AB0012',
        maintenantUtc: DateTime.utc(2026, 9, 20, 10),
      );

      // Pas de texte, pas de motif, pas de nom : le destinataire recoit un
      // signal, pas un message. Et jamais un nom de famille (decision D-08).
      expect(rappel.charge.keys, <String>['academy_id']);
    });

    test('un envoi sans droit leve, il n avale pas', () async {
      // Reussite silencieuse, echec explicite : un enseignant qui croirait
      // avoir rappele un eleve alors que rien n'est parti est exactement ce que
      // CONTRACTS section 12 interdit.
      await expectLater(
        protocoleEleve.emettreCible(
          message(type: typeRappelDiscret),
          destinataireProfilId: profilEnseignant,
          canal: CanalFiabilite.fiable,
        ),
        throwsA(
          isA<EchecTransport>().having(
            (EchecTransport e) => e.motif,
            'motif',
            MotifEchecTransport.droitRefuse,
          ),
        ),
      );
    });
  });

  group('projection des capacites', () {
    test('elles derivent du jeton signe, jamais d un role', () async {
      expect(
        await protocolePrpf.capacites(seanceF),
        const CapacitesPedagogiques(
          peutPiloterSupport: true,
          peutAnnoter: true,
          peutEmettreNudge: true,
          estObservateurSilencieux: false,
        ),
      );
      expect(
        await protocoleEleve.capacites(seanceF),
        const CapacitesPedagogiques(
          peutPiloterSupport: false,
          peutAnnoter: false,
          peutEmettreNudge: false,
          estObservateurSilencieux: false,
        ),
      );
    });

    test('un controleur invisible et muet est observateur silencieux', () async {
      final TransportMemoire coteControleur = TransportMemoire(
        bus: bus,
        capacites: capacitesControleur,
      );
      addTearDown(coteControleur.liberer);

      final CapacitesPedagogiques capacites =
          await ServiceRealtimePedagogique(coteControleur).capacites(seanceF);

      expect(capacites.estObservateurSilencieux, isTrue);
      expect(capacites.peutEmettreNudge, isFalse);
    });

    test('hors salle, aucun droit connu n est un droit', () async {
      final CapacitesPedagogiques capacites =
          await ServiceRealtimePedagogique(
            const TransportIndisponible(),
          ).capacites(seanceF);

      expect(capacites.peutPiloterSupport, isFalse);
      expect(capacites.peutAnnoter, isFalse);
      expect(capacites.peutEmettreNudge, isFalse);
      expect(capacites.estObservateurSilencieux, isTrue);
    });
  });

  test('un eleve actif remis a null remet la classe au collectif', () {
    final MessagePedagogique collectif = messageEleveActif(
      sessionId: seanceF,
      emetteurProfilId: profilEnseignant,
      maintenantUtc: DateTime.utc(2026, 9, 20, 10),
    );

    expect(collectif.type, typeEleveActif);
    expect(academyIdDeCharge(collectif), isNull);
  });
}
