import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_realtime/adaptateur_transport_livekit.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

import 'faux/faux_moteur_salle.dart';
import 'support/fabriques.dart';

/// L'adaptateur au-dessus du moteur existant : ce qu'il sait faire, et ce
/// qu'il ne sait pas.
///
/// **Ce fichier est la preuve que `TC_CONTRACT_REQUEST_F.md` n'est pas une
/// precaution.** Le socle expose une primitive de donnees -- `presenterContenu`,
/// un pointeur coranique, un sujet, fiable, en diffusion -- et rien d'autre.
/// Tant qu'Agent Z n'a pas ajoute la primitive demandee, tout envoi du
/// protocole pedagogique leve [MotifEchecTransport.primitiveEnvoiAbsente],
/// nomme explicitement, plutot que de reussir en silence.
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

  test('il se declare partiel, il ne se declare pas complet', () {
    expect(adaptateur.disponibilite, DisponibiliteTransport.partiel);
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
        // `instable` est un avertissement, pas une coupure : le traiter comme
        // une coupure declencherait une restauration a chaque sursaut reseau.
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

    test(
      'en salle et avec le droit, la primitive manque, et cela se DIT',
      () async {
        await expectLater(
          adaptateur.envoyer(
            sujet: 'tc-pedagogique',
            charge: const <int>[1],
            canal: CanalFiabilite.ephemere,
          ),
          throwsA(
            isA<EchecTransport>().having(
              (EchecTransport e) => e.motif,
              'motif',
              MotifEchecTransport.primitiveEnvoiAbsente,
            ),
          ),
        );
      },
    );

    test('aucun paquet ne part par la primitive coranique du socle', () async {
      try {
        await adaptateur.envoyer(
          sujet: 'tc-pedagogique',
          charge: const <int>[1],
          canal: CanalFiabilite.fiable,
        );
      } on EchecTransport {
        // Attendu : la primitive manque. Ce qui compte est ce qui suit.
      }

      // **Faire passer le protocole pedagogique par `presenterContenu` aurait
      // ete possible et aurait ete une faute** : le mode d'affichage, la plage
      // de travail, les plages masquees et les marqueurs n'y tiennent pas. La
      // classe suivrait les tours de page en perdant le reste en silence.
      expect(moteur.presentes, isEmpty);
    });
  });

  test('le flux de paquets ne livre rien, et ne leve pas', () async {
    // Un abonne doit pouvoir s'abonner sans se proteger : c'est
    // `disponibilite` qui dit l'etat des lieux, pas une exception au premier
    // evenement.
    final List<PaquetRealtime> recus = <PaquetRealtime>[];
    adaptateur.paquets().listen(recus.add, onError: (Object e) => fail('$e'));
    moteur.poser(EtatSalle.connecte);
    await pumpEventQueue();

    expect(recus, isEmpty);
  });
}
