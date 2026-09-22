import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_realtime/adaptateur_transport_livekit.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

import 'faux/faux_moteur_salle.dart';
import 'support/fabriques.dart';

/// L'adaptateur au-dessus du moteur existant, complet depuis le lot 2.
///
/// Le socle expose la primitive generale de donnees (`publierDonnees`,
/// `donneesRecues`) ; l'adaptateur la traduit dans le vocabulaire du
/// protocole -- sujet, canal, destinataires -- **sans jamais passer par la
/// primitive coranique** `presenterContenu`, qui ne porterait ni le mode, ni
/// la plage, ni les marqueurs.
void main() {
  late FauxMoteurSalle moteur;
  late AdaptateurTransportLiveKit adaptateur;

  setUp(() {
    moteur = FauxMoteurSalle()..poser(EtatSalle.connecte);
    adaptateur = AdaptateurTransportLiveKit(
      moteur: moteur,
      acces: accesSalle('teacher'),
      profilLocalId: profilEnseignant,
    );
  });

  tearDown(() async {
    await adaptateur.liberer();
    await moteur.fermer();
  });

  test('il se declare complet : les deux canaux et le ciblage existent', () {
    expect(adaptateur.disponibilite, DisponibiliteTransport.complet);
  });

  test('les capacites sont recopiees du jeton signe', () {
    final CapacitesTransport capacites = adaptateur.capacites;

    expect(capacites.identiteLocale, profilEnseignant);
    expect(capacites.peutPublierDonnees, isTrue);
    expect(capacites.invisible, isFalse);
  });

  test('un eleve n a pas le droit de publier des donnees', () {
    final AdaptateurTransportLiveKit cote = AdaptateurTransportLiveKit(
      moteur: moteur,
      acces: accesSalle('student'),
      profilLocalId: profilEleve,
    );
    addTearDown(cote.liberer);

    expect(cote.capacites.peutPublierDonnees, isFalse);
  });

  group('traduction des etats de salle', () {
    test('instable reste ouvert : la seance continue', () async {
      final Future<List<EtatTransport>> recus = adaptateur
          .etats()
          .take(4)
          .toList();
      await pumpEventQueue();

      moteur
        ..poser(EtatSalle.instable)
        ..poser(EtatSalle.reconnexion)
        ..poser(EtatSalle.retabli)
        ..poser(EtatSalle.absent);

      expect(await recus, <EtatTransport>[
        EtatTransport.ouvert,
        EtatTransport.interrompu,
        EtatTransport.retabli,
        EtatTransport.absent,
      ]);
    });
  });

  group('envoi', () {
    test('le refus de droit passe avant tout le reste', () async {
      final AdaptateurTransportLiveKit cote = AdaptateurTransportLiveKit(
        moteur: moteur,
        acces: accesSalle('student'),
        profilLocalId: profilEleve,
      );
      addTearDown(cote.liberer);

      await expectLater(
        cote.envoyer(
          sujet: 'tc-pedagogique',
          charge: const <int>[1],
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
      expect(moteur.publies, isEmpty);
    });

    test('hors salle, l envoi est refuse comme tel', () async {
      moteur.poser(EtatSalle.absent);

      await expectLater(
        adaptateur.envoyer(
          sujet: 'tc-pedagogique',
          charge: const <int>[1],
          canal: CanalFiabilite.fiable,
        ),
        throwsA(
          isA<EchecTransport>().having(
            (EchecTransport e) => e.motif,
            'motif',
            MotifEchecTransport.horsSalle,
          ),
        ),
      );
    });

    test('le canal fiable part sous le sujet nu, en mode fiable', () async {
      await adaptateur.envoyer(
        sujet: 'tc-pedagogique',
        charge: const <int>[1, 2],
        canal: CanalFiabilite.fiable,
      );

      expect(moteur.publies, hasLength(1));
      expect(moteur.publies.single.sujet, 'tc-pedagogique');
      expect(moteur.publies.single.fiable, isTrue);
      expect(moteur.publies.single.charge, <int>[1, 2]);
    });

    test(
      'le canal ephemere porte le suffixe du socle, en mode non fiable',
      () async {
        await adaptateur.envoyer(
          sujet: 'tc-pedagogique',
          charge: const <int>[3],
          canal: CanalFiabilite.ephemere,
        );

        // **La convention est celle du socle**, pas une invention de
        // l'adaptateur : LiveKit ne dit pas a la reception par quel canal un
        // paquet est arrive, et `PaquetDonnees.fiable` se derive du suffixe.
        expect(
          moteur.publies.single.sujet,
          'tc-pedagogique$suffixeSujetEphemere',
        );
        expect(moteur.publies.single.fiable, isFalse);
      },
    );

    test('un envoi cible transmet ses destinataires', () async {
      await adaptateur.envoyer(
        sujet: 'tc-pedagogique',
        charge: const <int>[4],
        canal: CanalFiabilite.fiable,
        destinataires: const <String>[profilEleve],
      );

      expect(moteur.publies.single.destinataires, <String>[profilEleve]);
    });

    test('aucun paquet ne part par la primitive coranique du socle', () async {
      await adaptateur.envoyer(
        sujet: 'tc-pedagogique',
        charge: const <int>[1],
        canal: CanalFiabilite.fiable,
      );

      // Faire passer le protocole pedagogique par `presenterContenu` aurait
      // ete possible et aurait ete une faute : le mode d'affichage, la plage
      // de travail et les marqueurs n'y tiennent pas.
      expect(moteur.presentes, isEmpty);
    });

    test('un refus du moteur devient un echec de transport nomme', () async {
      moteur.refuserPublication = const EchecPublicationDonnees(
        MotifEchecPublication.transport,
        'ICE',
      );

      await expectLater(
        adaptateur.envoyer(
          sujet: 'tc-pedagogique',
          charge: const <int>[1],
          canal: CanalFiabilite.fiable,
        ),
        throwsA(
          isA<EchecTransport>().having(
            (EchecTransport e) => e.motif,
            'motif',
            MotifEchecTransport.reseau,
          ),
        ),
      );
    });
  });

  group('reception', () {
    test('un paquet fiable arrive sous son sujet et son canal', () async {
      final Future<PaquetRealtime> recu = adaptateur.paquets().first;
      await pumpEventQueue();

      moteur.recevoir(
        const PaquetDonnees(
          sujet: 'tc-pedagogique',
          charge: <int>[9],
          fiable: true,
          emetteurIdentite: profilEnseignant,
        ),
      );

      final PaquetRealtime paquet = await recu;
      expect(paquet.sujet, 'tc-pedagogique');
      expect(paquet.canal, CanalFiabilite.fiable);
      expect(paquet.charge, <int>[9]);
      expect(paquet.emetteurIdentite, profilEnseignant);
    });

    test('un paquet ephemere perd son suffixe et garde son canal', () async {
      final Future<PaquetRealtime> recu = adaptateur.paquets().first;
      await pumpEventQueue();

      moteur.recevoir(
        const PaquetDonnees(
          sujet: 'tc-pedagogique$suffixeSujetEphemere',
          charge: <int>[8],
          fiable: false,
        ),
      );

      final PaquetRealtime paquet = await recu;
      expect(paquet.sujet, 'tc-pedagogique');
      expect(paquet.canal, CanalFiabilite.ephemere);
    });
  });
}
