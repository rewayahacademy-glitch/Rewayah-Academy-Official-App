// Q-03 : le quota d observation du tuteur est respecte, et un compte a
// rebours client trafique ne le prolonge pas.
//
// INVARIANT 7 de la Phase 6 (spec section 15 : « aucune visite tuteur ne
// depasse la politique serveur »), decision D-14, CONTRACTS sections 13 et 14.
//
// LA FORME DU TEST EST LA DEMONSTRATION. Le compte a rebours client est un
// objet a part, modifiable a volonte, et il n est **jamais passe** au serveur.
// Si un jour une signature de port le prenait en parametre, ce fichier ne
// compilerait plus -- ce qui est exactement le signal voulu.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';

import '../fixtures/fixtures_observation.dart';
import 'faux/faux_serveur_observation.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 19, 16);

ResultatEntreeObservation _entrer(
  FauxServeurObservation serveur,
  DateTime quand,
) => serveur.entrer(
  sessionId: 'seance-1',
  groupeId: 'grp-plein',
  observateurProfilId: 'tuteur-1',
  role: RoleObservateur.tuteur,
  maintenantUtc: quand,
  enfantConcerneId: 'RA-AB0012',
);

void main() {
  group('Q-03 : le budget d observation est borne par le serveur', () {
    test('les defauts normatifs sont ceux de la specification', () {
      expect(politiqueHeritee.observationActivee, isTrue);
      expect(politiqueHeritee.maxVisitsPerSession, 1);
      expect(
        politiqueHeritee.maxTotalObservationTime,
        const Duration(seconds: 120),
      );
      expect(politiqueHeritee.microAutorise, isFalse);
      expect(politiqueHeritee.cameraAutorisee, isFalse);
      expect(politiqueHeritee.publicationDataAutorisee, isFalse);
      // Entree AUTOMATIQUE : l enseignant n admet pas, il est prevenu.
      expect(politiqueHeritee.admissionEnseignantRequise, isFalse);
    });

    test('une seule visite, et la seconde est refusee', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiqueHeritee,
      );

      expect(_entrer(serveur, _t0).autorise, isTrue);
      serveur.sortir(maintenantUtc: _t0.add(const Duration(seconds: 40)));

      final ResultatEntreeObservation seconde = _entrer(
        serveur,
        _t0.add(const Duration(minutes: 5)),
      );
      expect(seconde.autorise, isFalse);
      expect(seconde.motifRefus, MotifRefusObservation.quotaVisitesAtteint);
      // Le temps non consomme n ouvre aucun droit : le quota de VISITES tombe
      // en premier, et c est bien ainsi qu il faut le dire a la famille.
      expect(seconde.budget?.restant, const Duration(seconds: 80));
    });

    test('un compte a rebours client trafique ne prolonge rien', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiquePersonnalisee,
      );
      final CompteARebourdClient affichage = CompteARebourdClient(
        politiquePersonnalisee.maxTotalObservationTime,
      );

      expect(_entrer(serveur, _t0).autorise, isTrue);
      // Le tuteur -- ou un client modifie -- se redonne une heure.
      affichage.trafiquer(const Duration(hours: 1));
      expect(affichage.restantAffiche, const Duration(hours: 1));

      // Il reste dans la salle quatre minutes, soit bien au-dela du plafond
      // par visite (180 s). Le serveur ne credite que ce que la politique
      // autorise, et il ferme lui-meme l intervalle.
      final GuardianSessionVisit? fermee = serveur.sortir(
        maintenantUtc: _t0.add(const Duration(minutes: 4)),
      );

      expect(fermee?.durationSeconds, const Duration(seconds: 180));
      expect(fermee?.finDeVisite, FinDeVisite.quotaAtteint);
      // Et surtout : le budget serveur ignore totalement l affichage client.
      expect(serveur.budget().tempsConsomme, const Duration(seconds: 180));
      expect(serveur.budget().restant, const Duration(seconds: 120));
    });

    test('le temps epuise refuse meme quand il reste des visites', () {
      // Trois visites autorisees, 120 s au total : la premiere visite
      // consomme tout. Le motif doit etre « temps epuise », pas « quota de
      // visites » -- ce n est pas la meme phrase a dire au tuteur.
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiqueQuotaTempsCourt,
      );

      expect(_entrer(serveur, _t0).autorise, isTrue);
      final GuardianSessionVisit? longue = serveur.sortir(
        maintenantUtc: _t0.add(const Duration(seconds: 210)),
      );
      expect(longue?.durationSeconds, const Duration(seconds: 120));
      expect(longue?.finDeVisite, FinDeVisite.quotaAtteint);

      final ResultatEntreeObservation seconde = _entrer(
        serveur,
        _t0.add(const Duration(minutes: 10)),
      );
      expect(seconde.autorise, isFalse);
      expect(seconde.motifRefus, MotifRefusObservation.tempsEpuise);
      expect(seconde.budget?.visitesUtilisees, 1);
      expect(seconde.budget?.visitesMax, 3);
      expect(seconde.budget?.restant, Duration.zero);
    });

    test('un plafond par visite ne contourne jamais le plafond total', () {
      // Politique piege : 180 s par visite contre 120 s au total.
      expect(
        plafondEffectifDeVisite(politiquePlafondIncoherent, Duration.zero),
        const Duration(seconds: 120),
      );
      expect(
        plafondEffectifDeVisite(
          politiquePlafondIncoherent,
          const Duration(seconds: 90),
        ),
        const Duration(seconds: 30),
      );
      expect(
        plafondEffectifDeVisite(
          politiquePlafondIncoherent,
          const Duration(seconds: 200),
        ),
        Duration.zero,
      );
    });

    test('une politique desactivee refuse avant tout autre motif', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiqueDesactivee,
      );
      final ResultatEntreeObservation r = _entrer(serveur, _t0);

      expect(r.autorise, isFalse);
      expect(r.motifRefus, MotifRefusObservation.policyDesactivee);
      expect(serveur.journal, isEmpty);
    });

    test('sans lien tuteur-enfant, aucune entree', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiqueHeritee,
        lienTuteurValide: false,
      );
      expect(
        _entrer(serveur, _t0).motifRefus,
        MotifRefusObservation.lienTuteurAbsent,
      );
    });

    test('hors fenetre, aucune entree, quel que soit le budget', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiqueHeritee,
        dansLaFenetre: false,
      );
      final ResultatEntreeObservation r = _entrer(serveur, _t0);
      expect(r.motifRefus, MotifRefusObservation.horsFenetre);
      expect(r.budget?.tempsConsomme, Duration.zero);
    });
  });

  group('Q-03 : la visite est auditable sans reconstruction', () {
    test('chaque intervalle porte duree, numero et policy_version', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiquePersonnalisee,
      );

      _entrer(serveur, _t0);
      serveur.sortir(maintenantUtc: _t0.add(const Duration(seconds: 45)));
      _entrer(serveur, _t0.add(const Duration(minutes: 10)));
      serveur.sortir(
        maintenantUtc: _t0.add(const Duration(minutes: 10, seconds: 30)),
      );

      expect(serveur.journal, hasLength(2));
      expect(serveur.journal[0].visitNumber, 1);
      expect(serveur.journal[1].visitNumber, 2);
      for (final GuardianSessionVisit v in serveur.journal) {
        expect(v.durationSeconds, isNotNull);
        expect(v.leftAtUtc, isNotNull);
        expect(v.enteredAtUtc.isUtc, isTrue);
        expect(v.policyVersion, politiquePersonnalisee.policyVersion);
        // Le tuteur observe UN enfant nomme, et lui seul.
        expect(v.enfantConcerneId, 'RA-AB0012');
      }
      expect(serveur.journal[0].durationSeconds, const Duration(seconds: 45));
      expect(serveur.journal[1].durationSeconds, const Duration(seconds: 30));
    });

    test('policyVersion est obligatoire et non vide', () {
      expect(
        // ignore: prefer_const_constructors
        () => GuardianObservationPolicy(
          policyVersion: '',
          source: SourcePolitique.academie,
          observationActivee: true,
          maxVisitsPerSession: 1,
          maxTotalObservationTime: const Duration(seconds: 120),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
