import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/reception_outils.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/tc_realtime/service_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/ecran_eveille.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/seance_vivante.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart';
import 'package:rewayah_academy/features/salle_seance/marque_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/relais_salle.dart';

import '../support/harnais.dart';
import '../support/transport_memoire.dart';
import '../teaching_core/f/support/fabriques.dart' show accesSalle;

// S1 (plan de nuit du pilote, 24/10/2026) : ce que l'enseignant ecrit sur la
// page arrive chez l'eleve. Deux preuves : deux clients sur un transport en
// memoire partage, puis la synchronisation de la salle au-dessus du moteur
// LiveKit simule (le paquet publie par l'un est recu par l'autre).

const String _seance = 's1';

const ContentPosition _page42 = ContentPosition.page(
  resourceId: 'mushaf-madina-15',
  resourceVersionId: '1',
  page: 42,
);

TraitVectoriel _trait(String id) => TraitVectoriel(
  id: id,
  ancrage: _page42,
  points: const <PointNormalise>[
    PointNormalise(0.1, 0.2),
    PointNormalise(0.4, 0.25),
  ],
  outil: OutilTrait.stylet,
);

/// Les traits que le depot de l'eleve tient pour la page 42.
Future<List<TraitVectoriel>> _traitsDe(AnnotationsMemoire depot) async {
  await pumpEventQueue();
  return <TraitVectoriel>[
    for (final AnnotationLayer couche in depot.couches)
      if (couche.resourceId == _page42.resourceId) ...couche.traits,
  ];
}

void main() {
  test('deux clients sur un meme transport : le trait pose arrive, et le '
      'trait retire s en va', () async {
    final BusMemoire bus = BusMemoire();
    final TransportMemoire enseignant = TransportMemoire(
      bus: bus,
      capacites: const CapacitesTransport(
        identiteLocale: 't1',
        peutPublier: true,
        peutPublierDonnees: true,
        invisible: false,
      ),
    );
    final TransportMemoire eleve = TransportMemoire(
      bus: bus,
      capacites: const CapacitesTransport(
        identiteLocale: 'e1',
        peutPublier: true,
        peutPublierDonnees: false,
        invisible: false,
      ),
    );
    final DiffusionOutils diffusion = DiffusionOutils(
      ServiceRealtimePedagogique(enseignant),
      sessionId: _seance,
      emetteurProfilId: 't1',
    );
    final AnnotationsMemoire depotEleve = AnnotationsMemoire('e1');
    final ReceptionOutils reception = ReceptionOutils(
      ServiceRealtimePedagogique(eleve),
      sessionId: _seance,
      profilLocalId: 'e1',
      depot: depotEleve,
    );
    addTearDown(reception.liberer);

    await diffusion.emettre(
      EvenementTraitTermine(
        coucheId: 'couche-enseignant',
        trait: _trait('trait-1'),
        portee: PorteeAnnotation.seance,
      ),
    );
    final List<TraitVectoriel> recus = await _traitsDe(depotEleve);
    expect(recus.map((TraitVectoriel t) => t.id), <String>['trait-1']);
    expect(recus.single.ancrage, _page42);
    expect(recus.single.points.length, 2);

    await diffusion.emettre(
      const EvenementTraitRetire(
        coucheId: 'couche-enseignant',
        traitId: 'trait-1',
      ),
    );
    expect(await _traitsDe(depotEleve), isEmpty);
  });

  test('un trait d une autre seance ne se pose pas', () async {
    final BusMemoire bus = BusMemoire();
    final TransportMemoire enseignant = TransportMemoire(
      bus: bus,
      capacites: const CapacitesTransport(
        identiteLocale: 't1',
        peutPublier: true,
        peutPublierDonnees: true,
        invisible: false,
      ),
    );
    final TransportMemoire eleve = TransportMemoire(
      bus: bus,
      capacites: const CapacitesTransport(
        identiteLocale: 'e1',
        peutPublier: true,
        peutPublierDonnees: false,
        invisible: false,
      ),
    );
    final AnnotationsMemoire depotEleve = AnnotationsMemoire('e1');
    final ReceptionOutils reception = ReceptionOutils(
      ServiceRealtimePedagogique(eleve),
      sessionId: _seance,
      profilLocalId: 'e1',
      depot: depotEleve,
    );
    addTearDown(reception.liberer);

    await DiffusionOutils(
      ServiceRealtimePedagogique(enseignant),
      sessionId: 'autre-seance',
      emetteurProfilId: 't1',
    ).emettre(
      EvenementTraitTermine(
        coucheId: 'c',
        trait: _trait('trait-x'),
        portee: PorteeAnnotation.seance,
      ),
    );
    expect(await _traitsDe(depotEleve), isEmpty);
  });

  test('la salle sur le moteur LiveKit simule : l ecriture de l enseignant '
      'part sur le canal de donnees et se pose chez l eleve', () async {
    final FauxMoteurSalle moteurEnseignant = FauxMoteurSalle();
    final FauxMoteurSalle moteurEleve = FauxMoteurSalle();
    await moteurEnseignant.rejoindre(accesSalle('teacher'));
    await moteurEleve.rejoindre(accesSalle('student'));

    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteurEnseignant,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    final SynchroSalle eleve = SynchroSalle(
      moteur: moteurEleve,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e1',
    );
    addTearDown(enseignant.liberer);
    addTearDown(eleve.liberer);

    // L'eleve n'emet pas (jeton sans `can_publish_data`).
    expect(eleve.diffuser, isNull);

    enseignant.diffuser!(
      EvenementTraitTermine(
        coucheId: 'c',
        trait: _trait('trait-2'),
        portee: PorteeAnnotation.seance,
      ),
    );
    await pumpEventQueue();

    // Le paquet est parti par la primitive de donnees, canal fiable…
    final PaquetDonnees paquet = moteurEnseignant.donneesPubliees.single;
    expect(paquet.fiable, isTrue);
    expect(moteurEnseignant.contenusPresentesDemandes, isEmpty);

    // … et la salle de l'eleve le recoit (LiveKit le livre tel quel).
    moteurEleve.recevoirDonnees(
      PaquetDonnees(
        sujet: paquet.sujet,
        charge: paquet.charge,
        fiable: paquet.fiable,
        emetteurIdentite: 't1',
      ),
    );
    final List<TraitVectoriel> recus = await _traitsDe(eleve.depot);
    expect(recus.map((TraitVectoriel t) => t.id), <String>['trait-2']);
  });

  test('le pointeur de l enseignant part sur le canal ephemere et se montre '
      'chez l eleve, puis s efface', () async {
    final FauxMoteurSalle moteurEnseignant = FauxMoteurSalle();
    final FauxMoteurSalle moteurEleve = FauxMoteurSalle();
    await moteurEnseignant.rejoindre(accesSalle('teacher'));
    await moteurEleve.rejoindre(accesSalle('student'));
    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteurEnseignant,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    final SynchroSalle eleve = SynchroSalle(
      moteur: moteurEleve,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e1',
    );
    addTearDown(enseignant.liberer);
    addTearDown(eleve.liberer);
    expect(eleve.diffuserPointeur, isNull);

    void relayer(PaquetDonnees paquet) {
      moteurEleve.recevoirDonnees(
        PaquetDonnees(
          sujet: paquet.sujet,
          charge: paquet.charge,
          fiable: paquet.fiable,
          emetteurIdentite: 't1',
        ),
      );
    }

    enseignant.diffuserPointeur!(const Offset(0.3, 0.4));
    await pumpEventQueue();
    // GESTES-POINTEUR : une position part sans retransmission, une seule
    // fois.
    expect(moteurEnseignant.donneesPubliees, hasLength(1));
    expect(moteurEnseignant.donneesPubliees.single.fiable, isFalse);
    relayer(moteurEnseignant.donneesPubliees.single);
    await pumpEventQueue();
    expect(eleve.pointeurDistant.value, const Offset(0.3, 0.4));

    // Le lever part sur les deux canaux : tout de suite, et a coup sur.
    enseignant.diffuserPointeur!(null);
    await pumpEventQueue();
    final List<PaquetDonnees> levers = moteurEnseignant.donneesPubliees
        .skip(1)
        .toList();
    expect(levers.map((PaquetDonnees p) => p.fiable), <bool>[false, true]);
    // Le paquet sans garantie se perd : le fiable suffit.
    relayer(levers.last);
    await pumpEventQueue();
    expect(eleve.pointeurDistant.value, isNull);
  });

  group('GESTES-POINTEUR : le pointeur recu', () {
    late FauxMoteurSalle moteurEleve;
    late SynchroSalle eleve;
    final DateTime t0 = DateTime.utc(2026, 11, 11, 10);

    setUp(() async {
      moteurEleve = FauxMoteurSalle();
      await moteurEleve.rejoindre(accesSalle('student'));
      eleve = SynchroSalle(
        moteur: moteurEleve,
        acces: accesSalle('student'),
        sessionId: _seance,
        profilLocalId: 'e1',
      );
    });
    tearDown(() => eleve.liberer());

    Future<void> recevoir({
      Offset? point,
      required int ms,
      bool fiable = false,
    }) async {
      moteurEleve.recevoirDonnees(
        PaquetDonnees(
          sujet: sujetProtocolePedagogique,
          charge: messageVersOctets(
            MessagePedagogique(
              type: typePointeurSalle,
              sessionId: _seance,
              emetteurProfilId: 't1',
              charge: point == null
                  ? const <String, dynamic>{}
                  : <String, dynamic>{'x': point.dx, 'y': point.dy},
              emisLeUtc: t0.add(Duration(milliseconds: ms)),
            ),
          ),
          fiable: fiable,
          emetteurIdentite: 't1',
        ),
      );
      await pumpEventQueue();
    }

    test('une position arrivee en retard, plus vieille que celle affichee, '
        'est ecartee', () async {
      await recevoir(point: const Offset(0.5, 0.5), ms: 100);
      await recevoir(point: const Offset(0.1, 0.1), ms: 60);
      expect(eleve.pointeurDistant.value, const Offset(0.5, 0.5));
    });

    test('une position emise avant le lever ne fait pas reapparaitre le '
        'pointeur', () async {
      await recevoir(point: const Offset(0.5, 0.5), ms: 100);
      await recevoir(point: null, ms: 200);
      expect(eleve.pointeurDistant.value, isNull);
      await recevoir(point: const Offset(0.6, 0.6), ms: 150);
      expect(eleve.pointeurDistant.value, isNull);
    });

    test('le second exemplaire du lever, arrive apres un nouveau geste, ne '
        'l efface pas', () async {
      await recevoir(point: const Offset(0.5, 0.5), ms: 100);
      await recevoir(point: null, ms: 200);
      await recevoir(point: const Offset(0.7, 0.7), ms: 300);
      await recevoir(point: null, ms: 201, fiable: true);
      expect(eleve.pointeurDistant.value, const Offset(0.7, 0.7));
    });

    test('sans nouvelle de l enseignant, le pointeur s efface seul : il ne '
        'reste jamais fige', () async {
      await recevoir(point: const Offset(0.2, 0.3), ms: 0);
      expect(eleve.pointeurDistant.value, const Offset(0.2, 0.3));
      // Un battement arrive : le pointeur reste.
      await Future<void>.delayed(AppMouvement.pointeurPerime ~/ 2);
      await recevoir(point: const Offset(0.2, 0.3), ms: 500);
      await Future<void>.delayed(AppMouvement.pointeurPerime ~/ 2);
      expect(eleve.pointeurDistant.value, const Offset(0.2, 0.3));
      // Plus rien : il s'efface.
      await Future<void>.delayed(AppMouvement.pointeurPerime);
      expect(eleve.pointeurDistant.value, isNull);
    });
  });

  test('S0.3 : le tableau ouvert par l enseignant s ouvre chez l eleve, '
      'puis se ferme', () async {
    final FauxMoteurSalle moteurEnseignant = FauxMoteurSalle();
    final FauxMoteurSalle moteurEleve = FauxMoteurSalle();
    await moteurEnseignant.rejoindre(accesSalle('teacher'));
    await moteurEleve.rejoindre(accesSalle('student'));
    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteurEnseignant,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    final SynchroSalle eleve = SynchroSalle(
      moteur: moteurEleve,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e1',
    );
    addTearDown(enseignant.liberer);
    addTearDown(eleve.liberer);

    Future<void> relayer() async {
      await pumpEventQueue();
      final PaquetDonnees paquet = moteurEnseignant.donneesPubliees.last;
      expect(paquet.fiable, isTrue);
      moteurEleve.recevoirDonnees(
        PaquetDonnees(
          sujet: paquet.sujet,
          charge: paquet.charge,
          fiable: paquet.fiable,
          emetteurIdentite: 't1',
        ),
      );
      await pumpEventQueue();
    }

    expect(eleve.tableauOuvert.value, isFalse);
    enseignant.diffuserTableau(ouvert: true);
    await relayer();
    expect(eleve.tableauOuvert.value, isTrue);
    enseignant.diffuserTableau(ouvert: false);
    await relayer();
    expect(eleve.tableauOuvert.value, isFalse);
  });

  test('salle en groupe : la parole donnee par l enseignant arrive chez '
      'l eleve, se rejoue a un arrivant, puis se reprend', () async {
    final FauxMoteurSalle moteurEnseignant = FauxMoteurSalle();
    final FauxMoteurSalle moteurEleve = FauxMoteurSalle();
    await moteurEnseignant.rejoindre(accesSalle('teacher'));
    await moteurEleve.rejoindre(accesSalle('student'));
    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteurEnseignant,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    final SynchroSalle eleve = SynchroSalle(
      moteur: moteurEleve,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e1',
    );
    addTearDown(enseignant.liberer);
    addTearDown(eleve.liberer);

    Future<void> relayer() async {
      await pumpEventQueue();
      final PaquetDonnees paquet = moteurEnseignant.donneesPubliees.last;
      expect(paquet.fiable, isTrue);
      moteurEleve.recevoirDonnees(
        PaquetDonnees(
          sujet: paquet.sujet,
          charge: paquet.charge,
          fiable: paquet.fiable,
          emetteurIdentite: 't1',
        ),
      );
      await pumpEventQueue();
    }

    const ParoleSalle yusuf = ParoleSalle(profilId: 'e2', prenom: 'Yusuf');
    expect(eleve.parole.value, isNull);
    enseignant.diffuserParole(yusuf);
    expect(enseignant.parole.value, yusuf);
    await relayer();
    expect(eleve.parole.value, yusuf);

    // Rejeu a un arrivant : la parole repart avec le reste.
    moteurEnseignant.donneesPubliees.clear();
    enseignant.rejouer();
    await relayer();
    expect(eleve.parole.value, yusuf);

    enseignant.diffuserParole(null);
    await relayer();
    expect(eleve.parole.value, isNull);

    // L'eleve ne donne pas la parole : son jeton n'a pas le canal.
    final int avant = moteurEleve.donneesPubliees.length;
    eleve.diffuserParole(yusuf);
    await pumpEventQueue();
    expect(moteurEleve.donneesPubliees.length, avant);
    expect(eleve.parole.value, isNull);
  });

  test('rappel discret, emetteur : par le port et la salle ouverte, un '
      'paquet fiable adresse au seul eleve vise ; le cooldown tient', () async {
    final FauxMoteurSalle moteur = FauxMoteurSalle();
    await moteur.rejoindre(accesSalle('teacher'));
    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteur,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    addTearDown(enseignant.liberer);
    Future<void> transport({
      required String sessionId,
      required String academyId,
    }) => enseignant.emettreRappel(academyId: academyId, profilCible: 'e2');
    RelaisRappelSalle.inscrire(transport);
    addTearDown(() => RelaisRappelSalle.retirer(transport));
    final RappelDiscretCadence port = RappelDiscretCadence(
      transport: transportRappelRelais,
    );

    await port.rappeler(sessionId: _seance, academyId: 'RA-26-0002');
    expect(moteur.donneesPubliees, hasLength(1));
    expect(moteur.donneesPubliees.single.fiable, isTrue);
    expect(moteur.destinatairesPublies.single, <String>['e2']);
    final MessagePedagogique envoye = messageDepuisOctets(
      moteur.donneesPubliees.single.charge,
    )!;
    expect(envoye.type, typeRappelDiscret);
    expect(academyIdDeCharge(envoye), 'RA-26-0002');

    // Le cooldown existant : un second appel immediat ne part pas.
    await expectLater(
      port.rappeler(sessionId: _seance, academyId: 'RA-26-0002'),
      throwsA(
        isA<EchecRappel>().having(
          (EchecRappel e) => e.motif,
          'motif',
          MotifEchecRappel.cooldown,
        ),
      ),
    );
    expect(moteur.donneesPubliees, hasLength(1));

    // Hors salle, le relais dit qu'il n'aboutit pas.
    RelaisRappelSalle.retirer(transport);
    await expectLater(
      port.rappeler(sessionId: _seance, academyId: 'RA-26-0003'),
      throwsA(isA<EchecRappel>()),
    );
  });

  test('rappel discret, recepteur : l eleve compte le rappel recu, ignore '
      'les autres paquets et le sien', () async {
    final FauxMoteurSalle moteur = FauxMoteurSalle();
    await moteur.rejoindre(accesSalle('student'));
    final SynchroSalle eleve = SynchroSalle(
      moteur: moteur,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e2',
    );
    addTearDown(eleve.liberer);
    void recevoir(MessagePedagogique message) => moteur.recevoirDonnees(
      PaquetDonnees(
        sujet: sujetProtocolePedagogique,
        charge: messageVersOctets(message),
        fiable: true,
        emetteurIdentite: 't1',
      ),
    );

    recevoir(
      messageEleveActif(
        sessionId: _seance,
        emetteurProfilId: 't1',
        academyId: 'RA-26-0002',
        maintenantUtc: DateTime.utc(2026, 10, 30, 20),
      ),
    );
    await pumpEventQueue();
    expect(eleve.rappelsRecus.value, 0);

    recevoir(
      messageRappelDiscret(
        sessionId: _seance,
        emetteurProfilId: 't1',
        academyId: 'RA-26-0002',
        maintenantUtc: DateTime.utc(2026, 10, 30, 20),
      ),
    );
    await pumpEventQueue();
    expect(eleve.rappelsRecus.value, 1);

    // L'eleve n'a pas le canal : il n'appelle personne.
    await expectLater(
      eleve.emettreRappel(academyId: 'RA-26-0001', profilCible: 'e1'),
      throwsA(isA<EchecRappel>()),
    );
  });

  test('rejeu : un eleve qui entre apres la page, le tableau et un trait '
      'les recoit de l appareil de l enseignant', () async {
    final FauxMoteurSalle moteurEnseignant = FauxMoteurSalle();
    final FauxMoteurSalle moteurEleve = FauxMoteurSalle();
    await moteurEnseignant.rejoindre(accesSalle('teacher'));
    await moteurEleve.rejoindre(accesSalle('student'));
    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteurEnseignant,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    addTearDown(enseignant.liberer);

    // Avant l'arrivee : la page 42 presentee, le tableau ouvert, un trait.
    final ContenuPresente page = ContenuPresente(
      page: 42,
      sourate: 2,
      verset: 253,
      presentePar: 't1',
      emisLe: DateTime.utc(2026, 10, 24, 20),
    );
    moteurEnseignant.publierContenu(page);
    enseignant.diffuserTableau(ouvert: true);
    final AnnotationLayer? couche = await enseignant.depot.couche(
      resourceId: _page42.resourceId,
      portee: PorteeAnnotation.temporaire,
    );
    await enseignant.depot.ajouterTrait(couche!.id, _trait('trait-avant'));
    await pumpEventQueue();
    moteurEnseignant.donneesPubliees.clear();
    moteurEnseignant.contenusPresentesDemandes.clear();

    ParticipantSalle participant(String id, {bool local = false}) =>
        ParticipantSalle(
          identite: id,
          nom: id,
          role: local ? 'teacher' : 'student',
          estLocal: local,
          micro: false,
          camera: false,
          parle: false,
          qualite: QualiteLien.inconnue,
        );

    // Une liste sans nouveau venu ne rejoue rien.
    moteurEnseignant.publier(<ParticipantSalle>[
      participant('t1', local: true),
    ]);
    await pumpEventQueue();
    expect(moteurEnseignant.donneesPubliees, isEmpty);

    // L'eleve arrive : page, tableau et trait repartent.
    moteurEnseignant.publier(<ParticipantSalle>[
      participant('t1', local: true),
      participant('e1'),
    ]);
    await pumpEventQueue();
    expect(moteurEnseignant.contenusPresentesDemandes, <ContenuPresente>[page]);

    final SynchroSalle eleve = SynchroSalle(
      moteur: moteurEleve,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e1',
    );
    addTearDown(eleve.liberer);
    for (final PaquetDonnees paquet in moteurEnseignant.donneesPubliees) {
      expect(paquet.fiable, isTrue);
      moteurEleve.recevoirDonnees(
        PaquetDonnees(
          sujet: paquet.sujet,
          charge: paquet.charge,
          fiable: paquet.fiable,
          emetteurIdentite: 't1',
        ),
      );
    }
    final List<TraitVectoriel> recus = await _traitsDe(eleve.depot);
    expect(recus.map((TraitVectoriel t) => t.id), <String>['trait-avant']);
    expect(eleve.tableauOuvert.value, isTrue);

    // Un second rejeu ne double pas le trait.
    enseignant.rejouer();
    await pumpEventQueue();
    final PaquetDonnees dernier = moteurEnseignant.donneesPubliees.last;
    moteurEleve.recevoirDonnees(
      PaquetDonnees(
        sujet: dernier.sujet,
        charge: dernier.charge,
        fiable: dernier.fiable,
        emetteurIdentite: 't1',
      ),
    );
    expect((await _traitsDe(eleve.depot)).length, 1);

    // L'eleve, lui, ne rejoue rien.
    final int avant = moteurEleve.donneesPubliees.length;
    eleve.rejouer();
    await pumpEventQueue();
    expect(moteurEleve.donneesPubliees.length, avant);
  });

  test('revue PR 54 : par le vrai nommage des sujets, le pointeur part '
      'sous « -l », revient ephemere et se montre chez l eleve ; une ecriture '
      'reste fiable', () async {
    // Le nommage du reseau, aller et retour.
    expect(sujetSurLeReseau('tc-pedagogique', fiable: true), 'tc-pedagogique');
    expect(
      sujetSurLeReseau('tc-pedagogique', fiable: false),
      'tc-pedagogique-l',
    );
    final PaquetDonnees eph = paquetDepuisLeReseau(
      sujetRecu: 'tc-pedagogique-l',
      charge: const <int>[1],
    );
    expect(eph.sujet, 'tc-pedagogique');
    expect(eph.fiable, isFalse);
    expect(
      paquetDepuisLeReseau(
        sujetRecu: sujetContenuPresente,
        charge: const <int>[],
      ).fiable,
      isTrue,
    );

    final FauxMoteurSalle moteurEnseignant = FauxMoteurSalle();
    final FauxMoteurSalle moteurEleve = FauxMoteurSalle();
    await moteurEnseignant.rejoindre(accesSalle('teacher'));
    await moteurEleve.rejoindre(accesSalle('student'));
    final SynchroSalle enseignant = SynchroSalle(
      moteur: moteurEnseignant,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
    );
    final SynchroSalle eleve = SynchroSalle(
      moteur: moteurEleve,
      acces: accesSalle('student'),
      sessionId: _seance,
      profilLocalId: 'e1',
    );
    addTearDown(enseignant.liberer);
    addTearDown(eleve.liberer);

    // Ce que LiveKit livre : le sujet tel que pose sur le reseau.
    Future<void> parLeReseau(PaquetDonnees publie) async {
      moteurEleve.recevoirDonnees(
        paquetDepuisLeReseau(
          sujetRecu: sujetSurLeReseau(publie.sujet, fiable: publie.fiable),
          charge: publie.charge,
          emetteurIdentite: 't1',
        ),
      );
      await pumpEventQueue();
    }

    enseignant.diffuserPointeur!(const Offset(0.3, 0.4));
    await pumpEventQueue();
    await parLeReseau(moteurEnseignant.donneesPubliees.last);
    expect(eleve.pointeurDistant.value, const Offset(0.3, 0.4));

    enseignant.diffuser!(
      EvenementTraitTermine(
        coucheId: 'c',
        trait: _trait('trait-reseau'),
        portee: PorteeAnnotation.seance,
      ),
    );
    await pumpEventQueue();
    await parLeReseau(moteurEnseignant.donneesPubliees.last);
    final List<TraitVectoriel> recus = await _traitsDe(eleve.depot);
    expect(recus.map((TraitVectoriel t) => t.id), <String>['trait-reseau']);
  });

  // FN-018 : une erreur d'un flux de la synchronisation ne passe plus en
  // silence ; elle est signalee, avec le nom du flux.
  test('FN-018 : une erreur du flux des participants est signalee', () async {
    final List<(String, Object)> signales = <(String, Object)>[];
    final _MoteurEnErreur moteur = _MoteurEnErreur();
    final SynchroSalle synchro = SynchroSalle(
      moteur: moteur,
      acces: accesSalle('teacher'),
      sessionId: _seance,
      profilLocalId: 't1',
      signalerErreur: (String flux, Object erreur) =>
          signales.add((flux, erreur)),
    );
    await pumpEventQueue();
    expect(signales, hasLength(1));
    expect(signales.single.$1, 'participants');
    expect(signales.single.$2, isA<StateError>());
    await synchro.liberer();
  });

  _synchroSession();
}

/// FN-018 : un moteur dont le flux des participants tombe en erreur.
class _MoteurEnErreur extends FauxMoteurSalle {
  @override
  Stream<List<ParticipantSalle>> get participants =>
      Stream<List<ParticipantSalle>>.error(StateError('flux coupe'));
}

// ---------------------------------------------------------------------------
// SYNCHRO-SESSION (13/11/2026, `docs/current/salle/HARMONIE-2026-11-13.md`
// section 7, journal D-045) : la synchronisation et la Dynamique chrono vivent
// avec l'appel, tenues par le controleur de session, et non avec la page.
// ---------------------------------------------------------------------------

AccesSalle _accesSession({required bool enseignant}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: enseignant ? 'teacher' : 'student',
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: enseignant,
    peutRecevoir: true,
    invisible: false,
    peutModerer: enseignant,
  ),
  expireLe: DateTime.utc(2030),
);

ParticipantSalle _qui(String id, String role, {bool local = false}) =>
    ParticipantSalle(
      identite: id,
      nom: id,
      role: role,
      estLocal: local,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    );

PaquetDonnees _parole(String seance, String? profil, String prenom) =>
    PaquetDonnees(
      sujet: sujetProtocolePedagogique,
      charge: messageVersOctets(
        MessagePedagogique(
          type: typeParoleSalle,
          sessionId: seance,
          emetteurProfilId: 't1',
          charge: profil == null
              ? const <String, dynamic>{}
              : <String, dynamic>{'profil': profil, 'prenom': prenom},
          emisLeUtc: DateTime.now().toUtc(),
        ),
      ),
      fiable: true,
      emetteurIdentite: 't1',
    );

PaquetDonnees _pauseDe(String emetteur) => PaquetDonnees(
  sujet: sujetPauseSalle,
  charge: utf8.encode(
    jsonEncode(
      chargePause(
        PauseSeance(
          statut: StatutPause.enCours,
          dureePrevueMinutes: 10,
          debutUtc: DateTime.now().toUtc(),
        ),
      ),
    ),
  ),
  fiable: true,
  emetteurIdentite: emetteur,
);

/// Une minuterie qu'on declenche a la main (la garde hors application).
class _Minuterie {
  final List<(Timer, void Function())> armees = <(Timer, void Function())>[];

  Timer creer(Duration _, void Function() rappel) {
    final Timer t = Timer(const Duration(days: 1), () {});
    armees.add((t, rappel));
    return t;
  }

  void declencher() {
    for (final (Timer t, void Function() rappel) in armees.toList()) {
      if (t.isActive) {
        t.cancel();
        rappel();
      }
    }
  }
}

class _SansNavigateur implements VerrouEcranNavigateur {
  const _SansNavigateur();

  @override
  bool get disponible => false;

  @override
  bool get visible => true;

  @override
  Stream<void> get changementsDeVisibilite => const Stream<void>.empty();

  @override
  Future<Object> demander() => throw UnsupportedError('sans navigateur');

  @override
  bool estRelache(Object verrou) => true;

  @override
  Future<void> relacher(Object verrou) async {}
}

/// Le controleur de l'application, avec une fabrique de [SeanceVivante]
/// branchee sur des doubles.
ControleurSessionPersistante _controleur(
  FauxMoteurSalle moteur, {
  required String profil,
  _Minuterie? minuterie,
  List<String>? creees,
}) => ControleurSessionPersistante(
  moteur,
  FauxServiceVideo(),
  observeLeCycleDeVie: false,
  ecranEveille: EcranEveille(const _SansNavigateur()),
  delaiHorsApplication: () => const Duration(seconds: 30),
  minuterie: minuterie?.creer,
  fabriqueCompagnon:
      ({
        required SessionEnCours cours,
        required AccesSalle acces,
        required VideoSessionProvider moteur,
      }) {
        creees?.add(cours.sessionId);
        return SeanceVivante(
          moteur: moteur,
          acces: acces,
          sessionId: cours.sessionId,
          profilLocalId: profil,
          tutoie: false,
          signal: () {},
          maintenant: () => DateTime.now().toUtc(),
        );
      },
);

SessionEnCours _cours(String id) =>
    SessionEnCours(sessionId: id, groupeId: 'g1', libelleGroupe: '');

void _synchroSession() {
  group('SYNCHRO-SESSION', () {
    for (final String chemin in <String>[
      'Quitter',
      'fin subie',
      'sortie hors application',
    ]) {
      test('quitter ($chemin) : plus rien ne vit', () async {
        final FauxMoteurAvecRecitant moteur = FauxMoteurAvecRecitant();
        final _Minuterie minuterie = _Minuterie();
        final ControleurSessionPersistante controleur = _controleur(
          moteur,
          profil: 'e1',
          minuterie: minuterie,
        );
        addTearDown(controleur.liberer);
        await moteur.rejoindre(_accesSession(enseignant: false));
        controleur.adopter(
          cours: _cours(_seance),
          acces: _accesSession(enseignant: false),
        );
        final SeanceVivante seance = seanceTenue(controleur, _seance)!;
        expect(moteur.ecouteParticipants, isTrue);
        expect(moteur.ecoutePaquets, isTrue);
        expect(moteur.ecouteContenus, isFalse, reason: 'eleve : aucun rejeu');
        expect(moteur.ecouteRecitant, isTrue);
        switch (chemin) {
          case 'Quitter':
            await controleur.quitter();
          case 'fin subie':
            moteur.poser(EtatSalle.echec);
            await pumpEventQueue();
          default:
            controleur
              ..didChangeAppLifecycleState(AppLifecycleState.inactive)
              ..didChangeAppLifecycleState(AppLifecycleState.hidden);
            minuterie.declencher();
            await pumpEventQueue();
            expect(
              controleur.etatCourant.sortieHorsApplication?.sessionId,
              _seance,
            );
        }
        await pumpEventQueue();
        expect(controleur.compagnon, isNull);
        expect(seance.libere, isTrue);
        expect(moteur.ecouteParticipants, isFalse);
        expect(moteur.ecoutePaquets, isFalse);
        expect(moteur.ecouteRecitant, isFalse);
        // Plus aucune alerte ne se pose : le pilote est libere.
        seance.dynamique.annoncer(
          AlerteChrono(id: 'apres', titre: 'apres'),
        );
        expect(seance.dynamique.alerte, isNull);
      });
    }

    test('l enseignant a reduit la salle (aucune page), un eleve entre : il '
        'recoit la page presentee et les traits', () async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      final ControleurSessionPersistante controleur = _controleur(
        moteur,
        profil: 't1',
      );
      addTearDown(controleur.liberer);
      await moteur.rejoindre(_accesSession(enseignant: true));
      controleur.adopter(
        cours: _cours(_seance),
        acces: _accesSession(enseignant: true),
      );
      final SeanceVivante seance = seanceTenue(controleur, _seance)!;
      moteur.publierContenu(
        ContenuPresente(
          page: 42,
          sourate: 2,
          verset: 255,
          presentePar: 't1',
          emisLe: DateTime.now(),
        ),
      );
      final AnnotationLayer couche = (await seance.synchro!.depot.couche(
        resourceId: _page42.resourceId,
        portee: PorteeAnnotation.temporaire,
      ))!;
      await seance.synchro!.depot.ajouterTrait(
        couche.id,
        _trait('trait-garde'),
      );
      moteur.publier(<ParticipantSalle>[_qui('t1', 'teacher', local: true)]);
      await pumpEventQueue();
      final int avant = moteur.contenusPresentesDemandes.length;
      final int paquetsAvant = moteur.donneesPubliees.length;
      moteur.publier(<ParticipantSalle>[
        _qui('t1', 'teacher', local: true),
        _qui('e2', 'student'),
      ]);
      await pumpEventQueue();
      expect(moteur.contenusPresentesDemandes.length, avant + 1);
      expect(moteur.contenusPresentesDemandes.last.page, 42);
      // Le trait repart aussi (rejeu du depot).
      expect(moteur.donneesPubliees.length, greaterThan(paquetsAvant));
      await controleur.quitter();
    });

    test('changer de seance : rien ne passe de l une a l autre', () async {
      final FauxMoteurAvecRecitant moteur = FauxMoteurAvecRecitant();
      final List<String> creees = <String>[];
      final ControleurSessionPersistante controleur = _controleur(
        moteur,
        profil: 'e1',
        creees: creees,
      );
      addTearDown(controleur.liberer);
      await moteur.rejoindre(_accesSession(enseignant: false));
      controleur.adopter(
        cours: _cours(_seance),
        acces: _accesSession(enseignant: false),
      );
      final SeanceVivante premiere = seanceTenue(controleur, _seance)!;
      // Une seconde adoption de la meme seance (droits rendus par le
      // serveur) garde la meme seance.
      controleur.adopter(
        cours: _cours(_seance),
        acces: _accesSession(enseignant: false),
      );
      expect(seanceTenue(controleur, _seance), same(premiere));
      expect(creees, <String>[_seance]);
      moteur
        ..publier(<ParticipantSalle>[
          _qui('t1', 'teacher'),
          _qui('e1', 'student', local: true),
        ])
        ..recevoirDonnees(_parole(_seance, 'e2', 'Aicha'))
        ..poserRecitant('e2');
      await pumpEventQueue();
      final AnnotationLayer couche = (await premiere.synchro!.depot.couche(
        resourceId: _page42.resourceId,
        portee: PorteeAnnotation.temporaire,
      ))!;
      await premiere.synchro!.depot.ajouterTrait(couche.id, _trait('trait-1'));
      expect(premiere.parole?.prenom, 'Aicha');
      expect(premiere.recitant, 'e2');
      expect(premiere.dynamique.alerte, isNotNull);
      moteur.poserRecitant(null);

      controleur.adopter(
        cours: _cours('s2'),
        acces: _accesSession(enseignant: false),
      );
      final SeanceVivante seconde = seanceTenue(controleur, 's2')!;
      expect(seanceTenue(controleur, _seance), isNull);
      expect(premiere.libere, isTrue);
      expect(seconde, isNot(same(premiere)));
      expect(creees, <String>[_seance, 's2']);
      expect(seconde.parole, isNull);
      expect(seconde.recitant, isNull);
      expect(seconde.synchro!.depot.couches, isEmpty);
      expect(seconde.dynamique.alerte, isNull);
      expect(seconde.dynamique.marques, isEmpty);
      expect(seconde.pauseRecue, isNull);
      // Un paquet de l'ancienne seance ne touche pas la nouvelle.
      moteur.recevoirDonnees(_parole(_seance, 'e3', 'Omar'));
      await pumpEventQueue();
      expect(seconde.parole, isNull);
      await controleur.quitter();
    });

    test('ligne 3.3 : la pause relayee n est lue que de qui conduit', () async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      final ControleurSessionPersistante controleur = _controleur(
        moteur,
        profil: 'e1',
      );
      addTearDown(controleur.liberer);
      await moteur.rejoindre(_accesSession(enseignant: false));
      controleur.adopter(
        cours: _cours(_seance),
        acces: _accesSession(enseignant: false),
      );
      final SeanceVivante seance = seanceTenue(controleur, _seance)!;
      moteur.publier(<ParticipantSalle>[
        _qui('t1', 'teacher'),
        _qui('e1', 'student', local: true),
        _qui('e2', 'student'),
      ]);
      await pumpEventQueue();
      moteur.recevoirDonnees(_pauseDe('e2'));
      await pumpEventQueue();
      expect(seance.pauseRecue, isNull, reason: 'un camarade ne la relaie pas');
      moteur.recevoirDonnees(_pauseDe('t1'));
      await pumpEventQueue();
      expect(seance.pauseRecue?.statut, StatutPause.enCours);
      await controleur.quitter();
    });

    test('ligne 3.1 : le recitant de la video est celui du moteur ; sans '
        'moteur qui le dise, le message de l enseignant', () async {
      final FauxMoteurAvecRecitant moteur = FauxMoteurAvecRecitant();
      final ControleurSessionPersistante controleur = _controleur(
        moteur,
        profil: 'e1',
      );
      addTearDown(controleur.liberer);
      await moteur.rejoindre(_accesSession(enseignant: false));
      controleur.adopter(
        cours: _cours(_seance),
        acces: _accesSession(enseignant: false),
      );
      final SeanceVivante seance = seanceTenue(controleur, _seance)!;
      moteur.recevoirDonnees(_parole(_seance, 'e2', 'Aicha'));
      await pumpEventQueue();
      // Le message est arrive, les metadonnees pas encore : pas de video.
      expect(seance.parole?.prenom, 'Aicha');
      expect(seance.recitant, isNull);
      moteur.poserRecitant('e2');
      await pumpEventQueue();
      expect(seance.recitant, 'e2');
      await controleur.quitter();

      final FauxMoteurSalle simple = FauxMoteurSalle();
      final ControleurSessionPersistante autre = _controleur(
        simple,
        profil: 'e1',
      );
      addTearDown(autre.liberer);
      await simple.rejoindre(_accesSession(enseignant: false));
      autre.adopter(
        cours: _cours(_seance),
        acces: _accesSession(enseignant: false),
      );
      simple.recevoirDonnees(_parole(_seance, 'e2', 'Aicha'));
      await pumpEventQueue();
      expect(seanceTenue(autre, _seance)!.recitant, 'e2');
      await autre.quitter();
    });
  });
}
