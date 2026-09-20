import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/mode_entree_admin.dart';

void main() {
  group('Les defauts normatifs de la specification 11.1', () {
    const GuardianObservationPolicy defauts =
        GuardianObservationPolicy.defautsNormatifs(policyVersion: 'p1');

    test('observation activee, une visite, cent vingt secondes', () {
      expect(defauts.observationActivee, isTrue);
      expect(defauts.maxVisitsPerSession, 1);
      expect(defauts.maxTotalObservationTime, const Duration(seconds: 120));
    });

    test('micro, camera, publication data et admission : tous fermes', () {
      expect(defauts.microAutorise, isFalse);
      expect(defauts.cameraAutorisee, isFalse);
      expect(defauts.publicationDataAutorisee, isFalse);
      // L'entree est automatique apres validation serveur : l'enseignant n'a
      // rien a accepter, et rien a refuser.
      expect(defauts.admissionEnseignantRequise, isFalse);
    });

    test('une politique desactivee ferme la porte quoi qu\'il arrive', () {
      final GuardianObservationPolicy fermee = defauts.copieAvec(
        source: SourcePolitique.desactivee,
      );

      expect(fermee.observationPossible, isFalse);
    });

    test('une lecture serveur illisible se replie sur la fermeture', () {
      // Jamais un repli ouvrant : une source inconnue ne doit pas se lire
      // « heritee de l'Academie », ce qui ouvrirait une porte que
      // l'administration croyait fermee.
      final GuardianObservationPolicy lue =
          GuardianObservationPolicy.depuisJson(const <String, dynamic>{
            'policy_version': 'p9',
            'source': 'valeur_inventee',
          });

      expect(lue.source, SourcePolitique.desactivee);
      expect(lue.observationPossible, isFalse);
    });
  });

  group('Un plafond par visite ne contourne jamais le plafond total', () {
    test('sans plafond par visite, le restant total fait foi', () {
      const GuardianObservationPolicy sansPlafond =
          GuardianObservationPolicy.defautsNormatifs(policyVersion: 'p1');

      expect(
        sansPlafond.plafondDeVisite(const Duration(seconds: 40)),
        const Duration(seconds: 40),
      );
    });

    test('le plus petit des deux l\'emporte, dans les deux sens', () {
      const GuardianObservationPolicy avecPlafond = GuardianObservationPolicy(
        policyVersion: 'p1',
        source: SourcePolitique.groupe,
        observationActivee: true,
        maxVisitsPerSession: 3,
        maxTotalObservationTime: Duration(seconds: 300),
        maxParVisite: Duration(seconds: 120),
      );

      // Le plafond par visite borne quand il reste beaucoup.
      expect(
        avecPlafond.plafondDeVisite(const Duration(seconds: 300)),
        const Duration(seconds: 120),
      );
      // Le restant total borne quand il reste peu : sans cela, un plafond de
      // cent vingt secondes rendrait trois fois le budget restant.
      expect(
        avecPlafond.plafondDeVisite(const Duration(seconds: 40)),
        const Duration(seconds: 40),
      );
    });
  });

  group('Les deux modes de l\'administration (11.5)', () {
    test('observer discretement : invisible, muet, sans annonce', () {
      const ModeEntreeAdmin mode = ModeEntreeAdmin.observerDiscretement;
      final ProfilObservateur profil = ProfilObservateur.pour(mode.role);

      expect(mode.role, RoleObservateur.adminIncognito);
      expect(mode.visible, isFalse);
      expect(mode.annonceFaite, isFalse);
      expect(profil.incognito, isTrue);
      expect(profil.capacites, isEmpty);
    });

    test('rejoindre la classe : visible, micro et camera, annonce', () {
      const ModeEntreeAdmin mode = ModeEntreeAdmin.rejoindreLaClasse;
      final ProfilObservateur profil = ProfilObservateur.pour(mode.role);

      expect(mode.role, RoleObservateur.adminVisible);
      expect(mode.visible, isTrue);
      expect(mode.annonceFaite, isTrue);
      expect(profil.capacites, containsAll(<CapaciteObservation>[
        CapaciteObservation.micro,
        CapaciteObservation.camera,
        CapaciteObservation.visibilite,
      ]));
      // Le canal de donnees reste l'outil pedagogique de l'enseignant, meme
      // pour une intervention administrative.
      expect(
        profil.capacites.contains(CapaciteObservation.publicationData),
        isFalse,
      );
    });

    test('l\'incognito est invisible aux participants, pas a l\'audit', () {
      // Le role est journalise comme tous les autres : c'est
      // `GuardianSessionVisit` qui le porte, et il ne connait pas d'exception.
      for (final RoleObservateur role in RoleObservateur.values) {
        expect(role.valeurSql, isNotEmpty);
        expect(RoleObservateur.depuisSql(role.valeurSql), role);
      }
      expect(RoleObservateur.adminIncognito.incognito, isTrue);
      expect(RoleObservateur.controleur.incognito, isTrue);
      expect(RoleObservateur.tuteur.incognito, isFalse);
    });
  });

  group('Le tuteur, et lui seul, consomme un quota', () {
    test('le controle qualite et l\'administration ne sont pas rationnes', () {
      expect(RoleObservateur.tuteur.soumisAuQuota, isTrue);
      expect(RoleObservateur.controleur.soumisAuQuota, isFalse);
      expect(RoleObservateur.adminIncognito.soumisAuQuota, isFalse);
      expect(RoleObservateur.adminVisible.soumisAuQuota, isFalse);
    });
  });

  group('Un ecart entre le jeton et le produit se voit, il ne s\'applique pas',
      () {
    test('un jeton conforme ne produit aucun ecart', () {
      final ProfilObservateur tuteur = ProfilObservateur.pour(
        RoleObservateur.tuteur,
      );

      expect(
        tuteur.ecartsAvecJeton(
          peutPublier: false,
          peutPublierVideo: false,
          peutPublierDonnees: false,
          invisible: false,
        ),
        isEmpty,
      );
    });

    test('un micro accorde a un tuteur est signale, pas accepte', () {
      final ProfilObservateur tuteur = ProfilObservateur.pour(
        RoleObservateur.tuteur,
      );

      final Set<CapaciteObservation> ecarts = tuteur.ecartsAvecJeton(
        peutPublier: true,
        peutPublierVideo: false,
        peutPublierDonnees: false,
        invisible: false,
      );

      expect(ecarts, <CapaciteObservation>{CapaciteObservation.micro});
      // Le profil, lui, n'a pas bouge : c'est le serveur qu'il faudra
      // corriger, pas l'ecran qu'il faut ouvrir.
      expect(tuteur.capacites.contains(CapaciteObservation.micro), isFalse);
    });

    test('un controleur rendu visible est un ecart', () {
      final ProfilObservateur controleur = ProfilObservateur.pour(
        RoleObservateur.controleur,
      );

      expect(
        controleur.ecartsAvecJeton(
          peutPublier: false,
          peutPublierVideo: false,
          peutPublierDonnees: false,
          invisible: false,
        ),
        <CapaciteObservation>{CapaciteObservation.visibilite},
      );
    });
  });

  group('La visite journalisee porte ce qu\'il faut pour la relire', () {
    test('entree, sortie, duree, rang et version de politique', () {
      final GuardianSessionVisit lue =
          GuardianSessionVisit.depuisJson(const <String, dynamic>{
            'id': 'v1',
            'session_id': 's1',
            'groupe_id': 'g1',
            'observateur_profile_id': 'tuteur-1',
            'role': 'guardian_observer',
            'enfant_profile_id': 'enfant-1',
            'entered_at': '2026-09-20T10:00:00Z',
            'left_at': '2026-09-20T10:02:00Z',
            'duration_seconds': 120,
            'visit_number': 1,
            'policy_version': 'p1',
            'fin_de_visite': 'quota_atteint',
          });

      expect(lue.enteredAtUtc.isUtc, isTrue);
      expect(lue.leftAtUtc?.isUtc, isTrue);
      expect(lue.durationSeconds, const Duration(seconds: 120));
      expect(lue.visitNumber, 1);
      expect(lue.policyVersion, 'p1');
      expect(lue.finDeVisite, FinDeVisite.quotaAtteint);
      expect(lue.enCours, isFalse);
    });

    test('un intervalle ouvert n\'a ni sortie ni duree', () {
      final GuardianSessionVisit lue =
          GuardianSessionVisit.depuisJson(const <String, dynamic>{
            'id': 'v1',
            'session_id': 's1',
            'groupe_id': 'g1',
            'observateur_profile_id': 'tuteur-1',
            'role': 'guardian_observer',
            'entered_at': '2026-09-20T10:00:00Z',
            'visit_number': 1,
            'policy_version': 'p1',
          });

      expect(lue.enCours, isTrue);
      expect(lue.leftAtUtc, isNull);
      expect(lue.durationSeconds, isNull);
    });
  });
}
