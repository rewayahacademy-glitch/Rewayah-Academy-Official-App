import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/reception_outils.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/tc_realtime/service_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/transport_memoire.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart';

import '../support/harnais.dart';
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

    void relayer() {
      final PaquetDonnees paquet = moteurEnseignant.donneesPubliees.last;
      expect(paquet.fiable, isFalse);
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
    relayer();
    await pumpEventQueue();
    expect(eleve.pointeurDistant.value, const Offset(0.3, 0.4));

    enseignant.diffuserPointeur!(null);
    await pumpEventQueue();
    relayer();
    await pumpEventQueue();
    expect(eleve.pointeurDistant.value, isNull);
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
}
