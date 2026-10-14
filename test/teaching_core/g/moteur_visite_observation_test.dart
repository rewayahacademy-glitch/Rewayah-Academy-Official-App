import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/moteur_visite_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';

import 'faux/faux_observation.dart';

const String _seance = 's1';

void main() {
  late FauxPortVisite visites;
  late FauxPortPolitique politique;
  late HorlogeReglable horloge;
  late StreamController<int> battement;
  late MoteurVisiteObservation moteur;

  setUp(() {
    visites = FauxPortVisite();
    politique = FauxPortPolitique();
    horloge = HorlogeReglable();
    battement = StreamController<int>.broadcast();
    moteur = MoteurVisiteObservation(
      visites,
      politique,
      horloge: horloge.lire,
      battement: battement.stream,
    );
  });

  tearDown(() async {
    await moteur.dispose();
    await politique.fermer();
    await battement.close();
  });

  /// Un battement, puis le temps de le laisser agir.
  Future<void> battre() async {
    battement.add(0);
    await souffler();
  }

  /// Une annonce de budget serveur, puis le temps de la laisser agir.
  Future<void> serveurAnnonce(BudgetObservation budget) async {
    politique.flux.add(budget);
    await souffler();
    // Une seconde passe : la fermeture enchaine plusieurs micro-taches, et
    // `sortir()` est la derniere d'entre elles.
    await souffler();
  }

  Future<void> entrer({RoleObservateur role = RoleObservateur.tuteur}) =>
      moteur.entrer(sessionId: _seance, role: role);

  group('Entree : le serveur decide, le client ne decide rien', () {
    test('une politique desactivee ferme la porte, et le dit', () async {
      visites.reponse = const ResultatEntreeObservation(
        autorise: false,
        motifRefus: MotifRefusObservation.policyDesactivee,
      );

      await entrer();

      expect(moteur.etat.phase, PhaseVisite.refusee);
      expect(moteur.etat.motifRefus, MotifRefusObservation.policyDesactivee);
      // Aucun abonnement de budget : il n'y a pas de visite a surveiller.
      expect(politique.abonnements, 0);
    });

    test('un quota de visites epuise refuse l\'entree', () async {
      visites.reponse = ResultatEntreeObservation(
        autorise: false,
        motifRefus: MotifRefusObservation.quotaVisitesAtteint,
        budget: unBudget(restant: Duration.zero, peutEntrer: false),
      );

      await entrer();

      expect(moteur.etat.phase, PhaseVisite.refusee);
      expect(moteur.etat.motifRefus, MotifRefusObservation.quotaVisitesAtteint);
    });

    test('un tuteur non lie a l\'enfant est refuse', () async {
      visites.reponse = const ResultatEntreeObservation(
        autorise: false,
        motifRefus: MotifRefusObservation.lienTuteurAbsent,
      );

      await entrer();

      expect(moteur.etat.phase, PhaseVisite.refusee);
      expect(moteur.etat.motifRefus, MotifRefusObservation.lienTuteurAbsent);
    });

    test('une capacite serveur absente ne devient jamais une entree', () async {
      // Le piege a eviter : traiter une panne comme une permission. Un client
      // qui entrerait « en attendant que le serveur reponde » observerait sans
      // quota, sans journal et sans politique.
      visites.echecEntree = const EchecObservation(
        MotifEchecObservation.capaciteAbsente,
      );

      await entrer();

      expect(moteur.etat.phase, PhaseVisite.indisponible);
      expect(moteur.etat.phase, isNot(PhaseVisite.enVisite));
      expect(moteur.etat.echec?.motif, MotifEchecObservation.capaciteAbsente);
    });

    test('le role demande est celui qu\'on lui passe', () async {
      await entrer(role: RoleObservateur.adminIncognito);

      expect(visites.rolesDemandes, <RoleObservateur>[
        RoleObservateur.adminIncognito,
      ]);
    });
  });

  group('Budget : un affichage, jamais une autorite', () {
    test('la visite 1 sur 1 expose son rang et son plafond', () async {
      await entrer();

      expect(moteur.etat.phase, PhaseVisite.enVisite);
      expect(moteur.etat.vueBudget?.rangVisite, 1);
      expect(moteur.etat.vueBudget?.visitesMax, 1);
      expect(moteur.etat.vueBudget?.secondesRestantes, 120);
    });

    test('le temps restant decroit avec l\'horloge', () async {
      await entrer();

      horloge.avancer(const Duration(seconds: 45));
      await battre();

      expect(moteur.etat.vueBudget?.secondesRestantes, 75);
      expect(moteur.etat.phase, PhaseVisite.enVisite);
    });

    test('une lecture de budget ratee n\'interrompt pas la visite, '
        'mais cesse d\'etre confirmee', () async {
      await entrer();

      politique.flux.addError(
        const EchecObservation(MotifEchecObservation.reseau),
      );
      await souffler();

      expect(moteur.etat.phase, PhaseVisite.enVisite);
      expect(moteur.etat.budgetIncertain, isTrue);
    });
  });

  group('Le client ne peut pas prolonger sa visite (spec 11.4)', () {
    test('reculer l\'horloge locale ne rend pas une seconde', () async {
      await entrer();

      // L'attaque la plus simple : reculer l'heure de la machine de dix
      // minutes pour que le decompte reparte de plus haut.
      horloge.reculer(const Duration(minutes: 10));
      await battre();

      final int restant = moteur.etat.vueBudget?.secondesRestantes ?? -1;
      expect(restant, 120, reason: 'jamais plus que ce que le serveur a dit');
      expect(
        moteur.etat.vueBudget!.restantAffiche,
        lessThanOrEqualTo(moteur.etat.vueBudget!.restantServeur),
      );
    });

    test('un battement supprime ne prolonge rien : le serveur ferme', () async {
      await entrer();

      // Ni battement, ni horloge qui avance : du point de vue du client, la
      // visite vient de commencer et il lui reste deux minutes.
      expect(moteur.etat.vueBudget?.secondesRestantes, 120);

      // Le serveur, lui, dit que le budget est consomme.
      await serveurAnnonce(unBudget(restant: Duration.zero, peutEntrer: false));

      expect(moteur.etat.phase, PhaseVisite.terminee);
      expect(moteur.etat.fin, FinDeVisite.quotaAtteint);
      expect(visites.sorties, <String>[_seance]);
    });

    test('meme une horloge reculee ne survit pas a la borne serveur', () async {
      await entrer();
      horloge.reculer(const Duration(hours: 1));
      await battre();

      await serveurAnnonce(unBudget(restant: Duration.zero, peutEntrer: false));

      expect(moteur.etat.phase, PhaseVisite.terminee);
      expect(moteur.etat.fin, FinDeVisite.quotaAtteint);
    });

    test(
      'le compte a rebours local termine la visite quand il tombe a zero',
      () async {
        // L'asymetrie voulue : le client peut abreger sa propre visite, il ne
        // peut pas l'allonger.
        await entrer();

        horloge.avancer(const Duration(seconds: 121));
        await battre();
        await souffler();

        expect(moteur.etat.phase, PhaseVisite.terminee);
        expect(moteur.etat.fin, FinDeVisite.quotaAtteint);
        expect(visites.sorties, <String>[_seance]);
      },
    );

    test('la visite ne se rouvre pas toute seule apres sa fin', () async {
      await entrer();
      await serveurAnnonce(unBudget(restant: Duration.zero, peutEntrer: false));

      // Un budget genereux arrive apres coup : il ne ressuscite rien.
      await serveurAnnonce(unBudget(restant: const Duration(seconds: 300)));

      expect(moteur.etat.phase, PhaseVisite.terminee);
      expect(visites.sorties.length, 1);
    });
  });

  group('Sortie', () {
    test(
      'une sortie volontaire ferme la visite et previent le serveur',
      () async {
        await entrer();

        await moteur.sortir();

        expect(moteur.etat.phase, PhaseVisite.terminee);
        expect(moteur.etat.fin, FinDeVisite.sortieVolontaire);
        expect(moteur.etat.sortieConfirmee, isTrue);
        expect(visites.sorties, <String>[_seance]);
      },
    );

    test(
      'une sortie que le serveur ne confirme pas est dite, jamais avalee',
      () async {
        // Le precedent nomme par le contrat : `ServiceVideo.annoncerSortie`
        // avale son echec. Acceptable pour une trace, inacceptable pour un
        // quota.
        visites.echecSortie = const EchecObservation(
          MotifEchecObservation.reseau,
        );
        await entrer();

        await moteur.sortir();

        expect(moteur.etat.phase, PhaseVisite.terminee);
        expect(moteur.etat.sortieConfirmee, isFalse);
        expect(moteur.etat.echec?.motif, MotifEchecObservation.reseau);
      },
    );

    test('fermer l\'ecran n\'annonce aucune sortie', () async {
      // Une page demontee n'est pas une sortie : c'est le serveur qui referme
      // l'intervalle a l'expiration du jeton.
      await entrer();

      await moteur.dispose();

      expect(visites.sorties, isEmpty);
    });
  });
}
